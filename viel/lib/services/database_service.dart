import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'veil_secure_enclave.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Metrics table for simple stats (balance, PRs, etc)
    await db.execute('''
      CREATE TABLE user_metrics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metric_name TEXT UNIQUE,
        metric_value TEXT,
        last_updated TEXT,
        source TEXT
      )
    ''');

    // Documents table for raw verified payloads (zkTLS receipts, Aadhaar XMLs)
    await db.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doc_type TEXT,
        raw_data TEXT,
        verified INTEGER,
        added_at TEXT
      )
    ''');
    
    // Seed some initial zero-state data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Seed initial metrics as 0 or empty so the app has something to read
    Batch batch = db.batch();
    batch.insert('user_metrics', {
      'metric_name': 'total_balance',
      'metric_value': '0.00',
      'last_updated': now,
      'source': 'manual'
    });
    batch.insert('user_metrics', {
      'metric_name': 'github_prs',
      'metric_value': '0',
      'last_updated': now,
      'source': 'manual'
    });
    await batch.commit(noResult: true);
  }

  // --- CRUD Operations for Metrics ---

  Future<void> updateMetric(String name, String value, String source) async {
    final db = await database;
    await db.insert(
      'user_metrics',
      {
        'metric_name': name,
        'metric_value': value,
        'last_updated': DateTime.now().toIso8601String(),
        'source': source,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMetric(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_metrics',
      where: 'metric_name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return maps.first['metric_value'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllMetrics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_metrics');
    
    Map<String, String> metrics = {};
    for (var map in maps) {
      metrics[map['metric_name'] as String] = map['metric_value'] as String;
    }
    return metrics;
  }
}
