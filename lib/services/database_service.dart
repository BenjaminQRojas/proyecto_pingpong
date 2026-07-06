import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/models/ping_pong_shot.dart';
import '../core/models/sensor_reading.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  bool get isOpen => _db != null;

  Future<void> init() async {
    if (_db != null) return;

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'pingpong.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE training_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            player_name TEXT NOT NULL DEFAULT 'Unknown',
            preset TEXT,
            duration_seconds INTEGER DEFAULT 0,
            ball_count INTEGER DEFAULT 0,
            top_motor_speed INTEGER,
            bottom_motor_speed INTEGER,
            horizontal_angle INTEGER,
            launch_interval REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE sensor_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER,
            timestamp TEXT NOT NULL,
            topic TEXT NOT NULL,
            balls_returned INTEGER,
            voltage REAL,
            payload_json TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_sessions_created ON training_sessions(created_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_sensors_session ON sensor_readings(session_id)',
        );
        await db.execute(
          'CREATE INDEX idx_sensors_timestamp ON sensor_readings(timestamp DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = await db.rawQuery('PRAGMA table_info(sensor_readings)');
          final columnNames = columns.map((c) => c['name'] as String).toList();

          if (!columnNames.contains('balls_returned')) {
            await db.execute('ALTER TABLE sensor_readings ADD COLUMN balls_returned INTEGER');
          }
          if (!columnNames.contains('voltage')) {
            await db.execute('ALTER TABLE sensor_readings ADD COLUMN voltage REAL');
          }
          if (!columnNames.contains('payload_json')) {
            await db.execute('ALTER TABLE sensor_readings ADD COLUMN payload_json TEXT');
          }
        }
      },
    );
  }

  Future<int> insertSession({
    required PingPongShot shot,
    String playerName = 'Unknown',
    String? preset,
    int durationSeconds = 0,
    int ballCount = 0,
  }) async {
    if (_db == null) await init();

    final shotMap = shot.toMap();
    final sessionData = {
      'created_at': DateTime.now().toIso8601String(),
      'player_name': playerName,
      'preset': preset,
      'duration_seconds': durationSeconds,
      'ball_count': ballCount,
      ...shotMap,
    };

    return await _db!.insert('training_sessions', sessionData);
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50}) async {
    if (_db == null) await init();

    final sessions = await _db!.query(
      'training_sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return sessions.map((session) {
      final shotConfig = {
        'topMotorSpeed': session['top_motor_speed'] ?? 0,
        'bottomMotorSpeed': session['bottom_motor_speed'] ?? 0,
        'horizontalAngle': session['horizontal_angle'] ?? 90,
        'interval': session['launch_interval'] ?? 1.0,
      };

      return {
        'id': session['id'],
        'created_at': session['created_at'],
        'player_name': session['player_name'],
        'preset': session['preset'],
        'duration_seconds': session['duration_seconds'],
        'ball_count': session['ball_count'],
        'shot_config': shotConfig,
      };
    }).toList();
  }

  Future<int> deleteSession(int id) async {
    if (_db == null) await init();

    await _db!.delete('sensor_readings', where: 'session_id = ?', whereArgs: [id]);

    return await _db!.delete('training_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertSensorReading(SensorReading reading) async {
    if (_db == null) await init();

    try {
      return await _db!.insert('sensor_readings', reading.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<SensorReading>> getSensorReadings({
    int? sessionId,
    int limit = 100,
  }) async {
    if (_db == null) await init();

    String? where;
    List<dynamic>? whereArgs;

    if (sessionId != null) {
      where = 'session_id = ?';
      whereArgs = [sessionId];
    }

    final rows = await _db!.query(
      'sensor_readings',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map((row) => SensorReading.fromMap(row)).toList();
  }

  Future<List<SensorReading>> getSensorReadingsBySession(int sessionId) async {
    return getSensorReadings(sessionId: sessionId, limit: 1000);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
