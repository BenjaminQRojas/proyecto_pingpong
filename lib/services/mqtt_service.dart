import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../core/models/ping_pong_shot.dart';

class MqttService extends ChangeNotifier {
  static const String _defaultBroker = '192.168.1.100';
  static const int _defaultPort = 1883;

  MqttServerClient? _client;
  String _brokerIp = _defaultBroker;
  int _port = _defaultPort;
  bool _isConnected = false;
  int _messagesSent = 0;
  String _lastError = '';

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
    try {
      _lastError = '';
      _client?.disconnect();
      _client = null;

      final clientId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
      final serverClient = MqttServerClient(_brokerIp, clientId);
      serverClient.port = _port;
      serverClient.keepAlivePeriod = 60;
      serverClient.autoReconnect = true;
      serverClient.resubscribeOnAutoReconnect = true;

      serverClient.onDisconnected = () {
        _isConnected = false;
        notifyListeners();
      };

      serverClient.onConnected = () {
        _isConnected = true;
        _setupSubscriptions(serverClient);
        notifyListeners();
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      serverClient.connectionMessage = connMessage;

      await serverClient.connect();
      final status = serverClient.connectionStatus;

      if (status != null && status.state == MqttConnectionState.connected) {
        _client = serverClient;
        _isConnected = true;
        _setupSubscriptions(serverClient);
      } else {
        _isConnected = false;
        _lastError = status?.returnCode?.name ?? 'Connection failed';
      }

      notifyListeners();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setupSubscriptions(MqttServerClient client) {
    client.subscribe('pingpong/status', MqttQos.atLeastOnce);
    client.subscribe('pingpong/data', MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>>? messages) {
      if (messages == null) return;

      for (final message in messages) {
        final topic = message.topic;
        try {
          final payload = message.payload as MqttPublishMessage;
          final value = utf8.decode(payload.payload.message);

          if (kDebugMode) {
            print('MQTT Message on $topic: $value');
          }
        } catch (e) {
          if (kDebugMode) {
            print('MQTT Error parsing message: $e');
          }
        }
      }
    });
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<bool> sendShotCommand(PingPongShot shot) async {
    if (!_isConnected || _client == null) {
      _lastError = 'Not connected to broker';
      return false;
    }

    try {
      final payload = jsonEncode(shot.toJson());
      _client!.publishMessage(
        'pingpong/control',
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(payload).payload!,
      );
      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> emergencyStop() async {
    if (!_isConnected || _client == null) {
      _lastError = 'Not connected to broker';
      return false;
    }

    try {
      final payload = jsonEncode({'priority': 0, 'action': 'STOP'});
      _client!.publishMessage(
        'pingpong/emergency',
        MqttQos.exactlyOnce,
        MqttClientPayloadBuilder().addString(payload).payload!,
      );
      _messagesSent++;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
