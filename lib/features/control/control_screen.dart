import 'package:flutter/material.dart';
import '../../core/models/ping_pong_shot.dart';
import '../../services/mqtt_service.dart';
import '../../services/database_service.dart';
import 'widgets/motor_slider.dart';
import 'widgets/emergency_stop_button.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final MqttService _mqttService = MqttService();
  final DatabaseService _databaseService = DatabaseService();

  int _topMotorSpeed = 50;
  int _bottomMotorSpeed = 50;
  int _horizontalAngle = 90;
  double _interval = 1.0;
  bool _isConnected = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final mqttConnected = await _mqttService.connect();
    final dbConnected = await _databaseService.connect();
    setState(() => _isConnected = mqttConnected && dbConnected);
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    _databaseService.disconnect();
    super.dispose();
  }

  Future<void> _sendShot() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final shot = PingPongShot(
      topMotorSpeed: _topMotorSpeed,
      bottomMotorSpeed: _bottomMotorSpeed,
      horizontalAngle: _horizontalAngle,
      interval: _interval,
    );

    await _mqttService.sendShotCommand(shot);
    await _databaseService.insertSession(shot);

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comando enviado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _emergencyStop() async {
    await _mqttService.emergencyStop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EMERGENCY STOP ACTIVADO'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PingPong IoT Control'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            EmergencyStopButton(onPressed: _emergencyStop),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    MotorSlider(
                      label: 'Top Motor Speed',
                      value: _topMotorSpeed,
                      onChanged: (v) => setState(() => _topMotorSpeed = v),
                    ),
                    MotorSlider(
                      label: 'Bottom Motor Speed',
                      value: _bottomMotorSpeed,
                      onChanged: (v) => setState(() => _bottomMotorSpeed = v),
                    ),
                    MotorSlider(
                      label: 'Horizontal Angle',
                      value: _horizontalAngle,
                      min: 0,
                      max: 180,
                      onChanged: (v) => setState(() => _horizontalAngle = v),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Interval',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('${_interval.toStringAsFixed(1)}s'),
                          ],
                        ),
                        Slider(
                          value: _interval,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          onChanged: (v) => setState(() => _interval = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendShot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isSending ? 'ENVIANDO...' : 'LANZAR',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
