import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../core/models/ping_pong_shot.dart';

class MqttService {
  static const String _defaultBroker = 'localhost';
  static const int _defaultPort = 1883;
  static const String _controlTopic = 'pingpong/control';
  static const String _emergencyTopic = 'pingpong/emergency';

  MqttServerClient? _client;
  String _brokerIp = _defaultBroker;
  int _port = _defaultPort;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get brokerIp => _brokerIp;

  void configure({String? brokerIp, int? port}) {
    _brokerIp = brokerIp ?? _defaultBroker;
    _port = port ?? _defaultPort;
  }

  Future<bool> connect() async {
    try {
      _client = MqttServerClient('tcp://$_brokerIp:$_port', 'flutter_client');
      _client!.port = _port;
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect = true;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('flutter_client')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      _client!.connectionMessage = connMessage;

      await _client!.connect();
      _isConnected =
          _client!.connectionStatus?.state == MqttConnectionState.connected;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
  }

  Future<void> sendShotCommand(PingPongShot shot) async {
    if (!_isConnected || _client == null) return;

    final payload = jsonEncode(shot.toJson());
    _client!.publishMessage(
      _controlTopic,
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(payload).payload!,
    );
  }

  Future<void> emergencyStop() async {
    if (!_isConnected || _client == null) return;

    final payload = jsonEncode({'priority': 0, 'action': 'STOP'});
    _client!.publishMessage(
      _emergencyTopic,
      MqttQos.exactlyOnce,
      MqttClientPayloadBuilder().addString(payload).payload!,
    );
  }
}
