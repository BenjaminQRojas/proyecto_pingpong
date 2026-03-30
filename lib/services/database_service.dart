import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../core/models/ping_pong_shot.dart';

class DatabaseService {
  static const String _defaultHost = 'localhost';
  static const int _defaultPort = 5432;
  static const String _defaultDatabase = 'pingpong';
  static const String _defaultUser = 'postgres';
  static const String _defaultPassword = 'postgres';

  Connection? _connection;
  String _host = _defaultHost;
  int _port = _defaultPort;
  String _database = _defaultDatabase;
  String _user = _defaultUser;
  String _password = _defaultPassword;

  bool get isConnected => _connection != null;

  void configure({
    String? host,
    int? port,
    String? database,
    String? user,
    String? password,
  }) {
    _host = host ?? _defaultHost;
    _port = port ?? _defaultPort;
    _database = database ?? _defaultDatabase;
    _user = user ?? _defaultUser;
    _password = password ?? _defaultPassword;
  }

  Future<bool> connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: _host,
          port: _port,
          database: _database,
          username: _user,
          password: _password,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
      return true;
    } catch (e) {
      _connection = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Future<void> insertSession(PingPongShot shot, {String? playerName}) async {
    if (_connection == null) return;

    final shotJson = jsonEncode(shot.toJson());
    final timestamp = DateTime.now().toIso8601String();

    await _connection!.execute(
      Sql.named(
        'INSERT INTO sessions (created_at, player_name, shot_config) VALUES (@timestamp, @player, @config)',
      ),
      parameters: {
        'timestamp': timestamp,
        'player': playerName ?? 'Unknown',
        'config': shotJson,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50}) async {
    if (_connection == null) return [];

    final result = await _connection!.execute(
      Sql.named(
        'SELECT id, created_at, player_name, shot_config FROM sessions ORDER BY created_at DESC LIMIT @limit',
      ),
      parameters: {'limit': limit},
    );

    return result
        .map(
          (row) => {
            'id': row[0],
            'created_at': row[1],
            'player_name': row[2],
            'shot_config': row[3] is String
                ? jsonDecode(row[3] as String)
                : row[3],
          },
        )
        .toList();
  }
}
