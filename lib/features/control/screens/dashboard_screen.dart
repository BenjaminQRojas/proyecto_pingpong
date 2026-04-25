import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/mqtt_service.dart';
import '../../../core/models/ping_pong_shot.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  int _frequency = 60;
  int _oscillation = 50;
  int _ballsLaunched = 0;
  String? _selectedPreset;
  Timer? _ballTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _presets = [
    {
      'id': 'topspin',
      'name': 'Topspin',
      'icon': Icons.trending_up,
      'color': AppTheme.primary,
    },
    {
      'id': 'backspin',
      'name': 'Backspin',
      'icon': Icons.trending_down,
      'color': AppTheme.primary,
    },
    {
      'id': 'random',
      'name': 'Random',
      'icon': Icons.shuffle,
      'color': AppTheme.secondary,
    },
    {
      'id': 'pro-drill',
      'name': 'Pro-Drill',
      'icon': Icons.gps_fixed,
      'color': AppTheme.secondary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ballTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleStartStop() {
    final mqtt = context.read<MqttService>();
    if (!mqtt.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to MQTT broker'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _ballsLaunched = 0;
        _startLaunching();
        _pulseController.repeat(reverse: true);
        _sendCommand(start: true);
      } else {
        _ballTimer?.cancel();
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  void _startLaunching() {
    _ballTimer?.cancel();
    _ballTimer = Timer.periodic(
      Duration(milliseconds: (60000 / _frequency).round()),
      (_) {
        setState(() => _ballsLaunched++);
        _sendCommand();
      },
    );
  }

  void _sendCommand({bool start = false}) {
    final mqtt = context.read<MqttService>();
    final shot = PingPongShot(
      topMotorSpeed: _frequency,
      bottomMotorSpeed: _oscillation,
      horizontalAngle: 90,
      interval: 60 / _frequency,
    );
    mqtt.sendShotCommand(shot, start: start);
  }

  void _emergencyStop() {
    final mqtt = context.read<MqttService>();
    mqtt.emergencyStop();
    setState(() {
      _isActive = false;
      _ballTimer?.cancel();
      _pulseController.stop();
      _pulseController.reset();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EMERGENCY STOP ACTIVADO'),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildConnectionStatus(),
              const SizedBox(height: 24),
              _buildMainButton(),
              const SizedBox(height: 24),
              _buildBallCounter(),
              const SizedBox(height: 24),
              _buildPrimaryControls(),
              const SizedBox(height: 24),
              _buildPresets(),
              const SizedBox(height: 16),
              _buildEmergencyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<MqttService>(
      builder: (context, mqtt, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Launcher Control',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'IoT Ping Pong System',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
            IconButton(
              onPressed: () async {
                if (!mqtt.isConnected) {
                  await mqtt.connect();
                } else {
                  mqtt.disconnect();
                }
              },
              icon: Icon(
                mqtt.isConnected ? Icons.wifi : Icons.wifi_off,
                color: mqtt.isConnected ? AppTheme.success : AppTheme.error,
                size: 28,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<MqttService>(
      builder: (context, mqtt, _) {
        return AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Device Status',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              AppBadge(
                text: mqtt.isConnected ? 'ESP32-Online' : 'Disconnected',
                color: mqtt.isConnected ? AppTheme.success : AppTheme.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    return Consumer<MqttService>(
      builder: (context, mqtt, _) {
        return Center(
          child: GestureDetector(
            onTap: mqtt.isConnected ? _handleStartStop : null,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isActive
                          ? [AppTheme.secondary, const Color(0xFFf97316)]
                          : [AppTheme.primary, AppTheme.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isActive ? AppTheme.secondary : AppTheme.primary)
                                .withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: _isActive ? 0 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isActive)
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 192,
                            height: 192,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.secondary,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isActive ? Icons.stop_circle : Icons.play_circle,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive ? 'STOP' : 'START',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBallCounter() {
    return AppCard(
      gradient: true,
      child: Column(
        children: [
          const Text(
            'Balls Launched',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ballsLaunched.toString().padLeft(3, '0'),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryControls() {
    return AppCard(
      child: Column(
        children: [
          AppSlider(
            label: 'Launch Frequency',
            value: _frequency,
            min: 10,
            max: 120,
            step: 5,
            suffix: ' BPM',
            onChanged: (v) {
              setState(() => _frequency = v);
              if (_isActive) _startLaunching();
            },
          ),
          const SizedBox(height: 24),
          AppSlider(
            label: 'Horizontal Oscillation',
            value: _oscillation,
            min: 0,
            max: 90,
            step: 5,
            suffix: '°',
            onChanged: (v) => setState(() => _oscillation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Presets',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: _presets.map((preset) {
            final isSelected = _selectedPreset == preset['id'];
            final color = preset['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedPreset = preset['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            preset['icon'] as IconData,
                            color: isSelected ? color : AppTheme.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset['name'] as String,
                            style: TextStyle(
                              color: isSelected ? color : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _emergencyStop,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text(
          'EMERGENCY STOP',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
