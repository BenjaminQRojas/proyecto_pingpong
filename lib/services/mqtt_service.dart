import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';
import '../core/models/ping_pong_shot.dart';
import '../core/models/sensor_reading.dart';
import 'database_service.dart';

class MqttService extends ChangeNotifier {
  static String get _defaultBroker => AppConfig.mqttBroker;
  static int get _defaultPort => AppConfig.mqttPort;
  static String get _topicPrefix => AppConfig.mqttTopicPrefix;

  MqttServerClient? _client;
  String _brokerIp = _defaultBroker;
  int _port = _defaultPort;
  bool _isConnected = false;
  int _messagesSent = 0;
  String _lastError = '';
  final DatabaseService _db = DatabaseService();

  final List<SensorReading> _sensorReadings = [];
  List<SensorReading> get sensorReadings => List.unmodifiable(_sensorReadings);

  int _latestBallsReturned = 0;
  int get latestBallsReturned => _latestBallsReturned;

  bool get isConnected => _isConnected;
  String get brokerIp => _brokerIp;
  int get port => _port;
  int get messagesSent => _messagesSent;
  String get lastError => _lastError;

  void configure({String? brokerIp, int? port}) {
    _brokerIp = brokerIp ?? _defaultBroker;
    _port = port ?? _defaultPort;
    notifyListeners();
  }

  Future<bool> connect() async {
    _lastError = '';
    final String clientId = 'flutter_dev_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient(_brokerIp, clientId);
    _client!.port = _port;
    _client!.secure = _port == 8883;
    _client!.useWebSocket = false;

    if (_client!.secure) {
      _client!.securityContext = SecurityContext.defaultContext;
    }

    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;
    _client!.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withProtocolName('MQTT')
        .withProtocolVersion(4)
        .startClean();

    _client!.connectionMessage = connMessage;

    try {
      if (kDebugMode) {
        print('MQTT: Intentando conexión a $_brokerIp:$_port');
      }
      await _client!.connect();
    } catch (e) {
      _lastError = 'Error de conexión: $e';
      if (kDebugMode) {
        print('MQTT: $e');
      }
      if (_port != _defaultPort && !_client!.secure) {
        _disconnectInternal();
        return false;
      }
      if (kDebugMode) {
        print('MQTT: Intentando fallback sin TLS puerto $_defaultPort');
      }
      _disconnectInternal();
      return _connectFallback(clientId);
    }

    final status = _client?.connectionStatus;
    if (status != null && status.state == MqttConnectionState.connected) {
      if (kDebugMode) {
        print('MQTT: Conectado a $_brokerIp:$_port');
      }
      _isConnected = true;
      _setupSubscriptions();
      notifyListeners();
      return true;
    } else {
      _lastError = 'Estado de conexión: ${status?.returnCode}';
      _disconnectInternal();
      return false;
    }
  }

  Future<bool> _connectFallback(String clientId) async {
    _client = MqttServerClient(_brokerIp, clientId);
    _client!.port = _defaultPort;
    _client!.secure = false;
    _client!.useWebSocket = false;
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;
    _client!.logging(on: false);

    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withProtocolName('MQTT')
        .withProtocolVersion(4)
        .startClean();

    try {
      await _client!.connect();
    } catch (e) {
      _lastError = 'Error fallback: $e';
      _disconnectInternal();
      return false;
    }

    final status = _client?.connectionStatus;
    if (status != null && status.state == MqttConnectionState.connected) {
      if (kDebugMode) {
        print('MQTT: Conectado (fallback) a $_brokerIp:$_defaultPort');
      }
      _isConnected = true;
      _port = _defaultPort;
      _setupSubscriptions();
      notifyListeners();
      return true;
    } else {
      _lastError = 'Estado fallback: ${status?.returnCode}';
      _disconnectInternal();
      return false;
    }
  }

  void _setupSubscriptions() {
    if (_client == null) return;

    if (kDebugMode) {
      print('MQTT: Suscribiendo a $_topicPrefix/#');
    }

    _client!.subscribe('$_topicPrefix/status', MqttQos.atLeastOnce);
    _client!.subscribe('$_topicPrefix/data', MqttQos.atLeastOnce);

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>>? messages) {
      if (messages == null) return;

      for (final message in messages) {
        final topic = message.topic;
        final MqttPublishMessage recMess = message.payload as MqttPublishMessage;
        final String payload = utf8.decode(recMess.payload.message);

        if (kDebugMode) {
          print('MQTT RECV: [$topic] -> $payload');
        }

        _handleIncomingMessage(topic, payload);
      }
    });
  }

  void _handleIncomingMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      int? ballsReturned;
      double? voltage;

      if (data.containsKey('balls_returned')) {
        ballsReturned = (data['balls_returned'] as num).toInt();
      }
      if (data.containsKey('ball_count')) {
        ballsReturned = (data['ball_count'] as num).toInt();
      }
      if (data.containsKey('voltage')) {
        voltage = (data['voltage'] as num).toDouble();
      }

      final reading = SensorReading(
        timestamp: DateTime.now().toIso8601String(),
        topic: topic,
        ballsReturned: ballsReturned,
        voltage: voltage,
        payloadJson: payload,
      );

      _sensorReadings.add(reading);
      _db.insertSensorReading(reading);

      if (ballsReturned != null) {
        _latestBallsReturned = ballsReturned;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error procesando mensaje MQTT: $e');
      }
    }
  }

  void _disconnectInternal() {
    _client?.disconnect();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  void disconnect() => _disconnectInternal();

  Future<bool> sendShotCommand(PingPongShot shot, {bool start = false, bool stop = false}) async {
    if (!_isConnected || _client == null) return false;

    try {
      final Map<String, dynamic> json = shot.toJson();
      if (start) {
        json['action'] = 'START';
      } else if (stop) {
        json['action'] = 'STOP';
      }

      final payload = jsonEncode(json);
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        '$_topicPrefix/control',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error enviando comando: $e');
      }
      return false;
    }
  }

  Future<bool> sendServoCommand(int horizontal) async {
    if (!_isConnected || _client == null) return false;

    try {
      final payload = jsonEncode({
        'horizontal': horizontal,
      });
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        '$_topicPrefix/servo',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error enviando comando servo: $e');
      }
      return false;
    }
  }

  Future<bool> sendOscillationConfig({required bool enabled, int min = 30, int max = 150}) async {
    if (!_isConnected || _client == null) return false;

    try {
      final Map<String, dynamic> payload;
      if (enabled) {
        payload = {
          'oscillate': true,
          'min': min,
          'max': max,
        };
      } else {
        payload = {
          'oscillate': false,
        };
      }

      final json = jsonEncode(payload);
      final builder = MqttClientPayloadBuilder();
      builder.addString(json);

      _client!.publishMessage(
        '$_topicPrefix/servo',
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error enviando config oscilación: $e');
      }
      return false;
    }
  }

  Future<bool> emergencyStop() async {
    if (!_isConnected || _client == null) return false;

    try {
      final payload = jsonEncode({'priority': 0, 'action': 'STOP'});
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        '$_topicPrefix/emergency',
        MqttQos.exactlyOnce,
        builder.payload!,
      );

      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error en parada de emergencia: $e');
      }
      return false;
    }
  }
}
