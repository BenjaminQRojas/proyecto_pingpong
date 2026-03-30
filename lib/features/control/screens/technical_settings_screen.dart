import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

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
  String _brokerIp = '192.168.1.100';
  String _port = '1883';
  String _topicPrefix = 'pingpong/launcher';
  bool _saved = false;
  bool _connectionTested = false;
  bool _isConnected = true;

  final List<TrainingSession> _sessions = [
    TrainingSession(
      id: '1',
      date: '2026-03-24',
      duration: '45m',
      ballCount: 327,
      preset: 'Pro-Drill',
    ),
    TrainingSession(
      id: '2',
      date: '2026-03-23',
      duration: '32m',
      ballCount: 218,
      preset: 'Topspin',
    ),
    TrainingSession(
      id: '3',
      date: '2026-03-22',
      duration: '28m',
      ballCount: 189,
      preset: 'Random',
    ),
    TrainingSession(
      id: '4',
      date: '2026-03-21',
      duration: '51m',
      ballCount: 412,
      preset: 'Pro-Drill',
    ),
    TrainingSession(
      id: '5',
      date: '2026-03-20',
      duration: '38m',
      ballCount: 265,
      preset: 'Backspin',
    ),
  ];

  void _handleSave() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  void _handleTestConnection() {
    setState(() {
      _connectionTested = true;
      _isConnected = true;
    });
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
          _buildTextField(
            'Broker IP Address',
            _brokerIp,
            (v) => setState(() => _brokerIp = v),
            hint: '192.168.1.100',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Port',
            _port,
            (v) => setState(() => _port = v),
            hint: '1883',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Topic Prefix',
            _topicPrefix,
            (v) => setState(() => _topicPrefix = v),
            hint: 'pingpong/launcher',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Test Connection',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: _handleTestConnection,
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

  Widget _buildTextField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }

  Widget _buildConnectionInfo() {
    return AppCard(
      gradient: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Connection',
                  _isConnected ? 'Active' : 'Inactive',
                  isBadge: true,
                ),
              ),
              Expanded(child: _buildInfoItem('Latency', '12ms')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoItem('Messages Sent', '1,247')),
              Expanded(child: _buildInfoItem('Uptime', '3h 42m')),
            ],
          ),
        ],
      ),
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
          ..._sessions.map((session) => _buildSessionItem(session)),
          const SizedBox(height: 12),
          AppButton(
            text: 'Load More Sessions',
            outlined: true,
            fullWidth: true,
            onPressed: () {},
          ),
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
          _buildSystemRow('Firmware Version', 'v2.4.1'),
          _buildSystemRow('Hardware Model', 'ESP32-WROOM-32'),
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
