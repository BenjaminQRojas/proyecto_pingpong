import 'dart:convert';
import 'dart:io'; // Importante para detectar la plataforma
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../core/models/ping_pong_shot.dart';

class MqttService extends ChangeNotifier {
  // Configuración base
  static const String _defaultBroker = 'broker.hivemq.com';
  static const int _defaultPort = 1883; // Puerto TCP estándar
  static const String _topicPrefix = 'infinitedecimal/pingpong';

  MqttServerClient? _client;
  String _brokerIp = _defaultBroker;
  int _port = _defaultPort;
  bool _isConnected = false;
  int _messagesSent = 0;
  String _lastError = '';

  // Getters
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
  
  // 1. Usar el puerto seguro 8883
  _client = MqttServerClient(_brokerIp, clientId);
  _client!.port = 8883; 
  _client!.secure = true; // ACTIVAR SEGURIDAD
  _client!.useWebSocket = false;
  
  // Esto es vital para que no falle al no encontrar certificados locales
  _client!.securityContext = SecurityContext.defaultContext;
  
  _client!.keepAlivePeriod = 20;
  _client!.autoReconnect = true;
  _client!.logging(on: true);

  // 2. Usar MQTT 3.1.1 explícitamente
  final connMessage = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .withProtocolName('MQTT')
      .withProtocolVersion(4) 
      .startClean();
      
  _client!.connectionMessage = connMessage;

  try {
    print('=== Intentando Conexión Segura (8883) ===');
    await _client!.connect();
  } catch (e) {
    print('Error en conexión segura: $e');
    _disconnectInternal();
    return false;
  }

  if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
    print('MQTT: ¡CONECTADO EN PUERTO 8883!');
    _isConnected = true;
    _setupSubscriptions();
    notifyListeners();
    return true;
  } else {
    _disconnectInternal();
    return false;
  }
}

  void _setupSubscriptions() {
    if (_client == null) return;

    print('MQTT: Suscribiendo a $_topicPrefix/#');
    
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
        
        // Aquí podrías agregar lógica para actualizar el estado de la UI
        // basado en lo que mande el ESP32
      }
    });
  }

  void _disconnectInternal() {
    _client?.disconnect();
    _client = null;
    _isConnected = false;
    notifyListeners();
  }

  void disconnect() => _disconnectInternal();

  Future<bool> sendShotCommand(PingPongShot shot, {bool start = false}) async {
    if (!_isConnected || _client == null) return false;

    try {
      final Map<String, dynamic> json = shot.toJson();
      if (start) {
        json['action'] = 'START';
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
      print('Error enviando comando: $e');
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
      print('Error en parada de emergencia: $e');
      return false;
    }
  }
}