import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/mqtt_service.dart';

class TrainingSession {
  final String id;
  final String date;
  final String duration;
  final int ballCount;
  final String preset;

  TrainingSession({
    required this.id,
    required this.date,
    required this.duration,
    required this.ballCount,
    required this.preset,
  });
}

class TechnicalSettingsScreen extends StatefulWidget {
  const TechnicalSettingsScreen({super.key});

  @override
  State<TechnicalSettingsScreen> createState() =>
      _TechnicalSettingsScreenState();
}

class _TechnicalSettingsScreenState extends State<TechnicalSettingsScreen> {
  late TextEditingController _brokerController;
  late TextEditingController _portController;
  bool _saved = false;
  bool _isTesting = false;

  List<TrainingSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    final mqtt = context.read<MqttService>();
    _brokerController = TextEditingController(text: mqtt.brokerIp);
    _portController = TextEditingController(text: mqtt.port.toString());
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final mqtt = context.read<MqttService>();
    mqtt.configure(
      brokerIp: _brokerController.text,
      port: int.tryParse(_portController.text) ?? 1883,
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _handleTestConnection() async {
    setState(() => _isTesting = true);
    final mqtt = context.read<MqttService>();
    mqtt.configure(
      brokerIp: _brokerController.text,
      port: int.tryParse(_portController.text) ?? 1883,
    );
    final success = await mqtt.connect();
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected successfully!'
                : 'Connection failed: ${mqtt.lastError}',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
              _buildMqttConfig(),
              const SizedBox(height: 16),
              _buildConnectionInfo(),
              const SizedBox(height: 16),
              _buildTrainingSessions(),
              const SizedBox(height: 16),
              _buildSystemInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure MQTT and view logs',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMqttConfig() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'MQTT Configuration',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBrokerField(),
          const SizedBox(height: 12),
          _buildPortField(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: _isTesting ? 'Testing...' : 'Test Connection',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: _isTesting ? null : _handleTestConnection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: _saved ? 'Saved!' : 'Save Config',
                  icon: Icons.save,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Broker IP Address',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _brokerController,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            hintText: '192.168.1.100',
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPortField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Port', style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _portController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(hintText: '1883', isDense: true),
        ),
      ],
    );
  }

  Widget _buildConnectionInfo() {
    return Consumer<MqttService>(
      builder: (context, mqtt, _) {
        return AppCard(
          gradient: true,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Connection',
                      mqtt.isConnected ? 'Active' : 'Inactive',
                      isBadge: true,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Messages Sent',
                      mqtt.isConnected ? '${mqtt.messagesSent}' : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mqtt.isConnected
                            ? 'Connected to ${mqtt.brokerIp}:${mqtt.port}'
                            : 'Configure and connect to Mosquitto broker',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        if (isBadge)
          AppBadge(
            text: value,
            color: value == 'Active' ? AppTheme.success : AppTheme.error,
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }

  Widget _buildTrainingSessions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, color: AppTheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Training Sessions',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppBadge(
                text: '${_sessions.length} logs',
                color: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.history, color: AppTheme.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No training sessions yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sessions will appear after connecting the ESP32',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._sessions.map((session) => _buildSessionItem(session)),
        ],
      ),
    );
  }

  Widget _buildSessionItem(TrainingSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(session.date),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(text: session.preset, outlined: true),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Duration: ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      session.duration,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Balls: ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      session.ballCount.toString(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.delete_outline, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Information',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildSystemRow('Firmware Version', '—'),
          _buildSystemRow('Hardware Model', '—'),
          _buildSystemRow('App Version', '1.0.0'),
        ],
      ),
    );
  }

  Widget _buildSystemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
