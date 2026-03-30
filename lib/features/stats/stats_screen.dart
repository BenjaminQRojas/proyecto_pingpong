import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../core/models/ping_pong_shot.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    _databaseService.configure();
    await _databaseService.connect();
    final sessions = await _databaseService.getSessions();
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Sesiones'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? const Center(child: Text('No hay sesiones registradas'))
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final shot = session['shot_config'] is Map
                    ? PingPongShot.fromJson(session['shot_config'])
                    : PingPongShot.fromJson(
                        Map<String, dynamic>.from(session['shot_config']),
                      );
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.sports_tennis),
                    title: Text('Jugador: ${session['player_name']}'),
                    subtitle: Text(
                      'Top: ${shot.topMotorSpeed} | Bottom: ${shot.bottomMotorSpeed}\n'
                      'Angulo: ${shot.horizontalAngle}° | Intervalo: ${shot.interval}s',
                    ),
                    trailing: Text(
                      '${session['created_at']}'.substring(0, 16),
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSessions,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
