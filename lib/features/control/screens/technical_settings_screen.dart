import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/mqtt_service.dart';
import '../../../services/database_service.dart';

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
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    final mqtt = context.read<MqttService>();
    _brokerController = TextEditingController(text: mqtt.brokerIp);
    _portController = TextEditingController(text: mqtt.port.toString());
    _loadSessions();
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final db = context.read<DatabaseService>();
    final sessions = await db.getSessions(limit: 5);
    setState(() => _sessions = sessions);
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
                ? 'Conexión exitosa'
                : 'Error de conexión: ${mqtt.lastError}',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  Future<void> _deleteSession(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Sesión'),
        content: const Text('¿Estás seguro de que quieres eliminar esta sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = context.read<DatabaseService>();
      await db.deleteSession(id);
      _loadSessions();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPreset(String? preset) {
    if (preset == null) return 'Manual';
    switch (preset) {
      case 'topspin': return 'Topspin';
      case 'backspin': return 'Backspin';
      case 'random': return 'Aleatorio';
      case 'pro-drill': return 'Pro-Drill';
      case 'calibración': return 'Calibración';
      default: return preset;
    }
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
          'Configuración Técnica',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configurar MQTT y ver registros',
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
                'Configuración MQTT',
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
                  text: _isTesting ? 'Probando...' : 'Probar Conexión',
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: _isTesting ? null : _handleTestConnection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: _saved ? 'Guardado!' : 'Guardar Config',
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
          'Dirección del Broker',
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
            hintText: 'broker.hivemq.com',
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
        Text('Puerto', style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _portController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'monospace',
          ),
          decoration: const InputDecoration(
            hintText: '1883',
            isDense: true,
          ),
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
                      'Conexión',
                      mqtt.isConnected ? 'Activa' : 'Inactiva',
                      isBadge: true,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Mensajes Enviados',
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
                            ? 'Conectado a ${mqtt.brokerIp}:${mqtt.port}'
                            : 'Configura y conecta al broker MQTT',
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
            color: value == 'Activa' ? AppTheme.success : AppTheme.error,
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
                    'Sesiones de Entrenamiento',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppBadge(
                text: '${_sessions.length} registros',
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
                  const Text(
                    'No hay sesiones todavía',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Las sesiones aparecerán después de iniciar el lanzador',
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

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final shotConfig = session['shot_config'] as Map<String, dynamic>?;
    final preset = session['preset'] as String?;
    final ballCount = session['ball_count'] as int? ?? 0;
    final createdAt = session['created_at'] as String? ?? '';

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
                      _formatDate(createdAt),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    AppBadge(
                      text: _formatPreset(preset),
                      outlined: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Pelotas: ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$ballCount',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                    if (shotConfig != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Sup: ${shotConfig['topMotorSpeed']}%',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Inf: ${shotConfig['bottomMotorSpeed']}%',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteSession(session['id'] as int),
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
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
            'Información del Sistema',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildSystemRow('Versión de Firmware', '—'),
          _buildSystemRow('Modelo de Hardware', '—'),
          _buildSystemRow('Versión de App', '1.0.0'),
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
