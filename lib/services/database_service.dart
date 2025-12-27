import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/blood_pressure_reading.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'blood_pressure.db';
  static const String _tableName = 'readings';
  static const int _databaseVersion = 1;

  // Database password for encryption
  // WARNING: DEVELOPMENT/DEMO ONLY - REPLACE IN PRODUCTION
  // This placeholder password must be replaced before production deployment.
  // PRODUCTION: Implement secure password management:
  // 1. Add flutter_secure_storage dependency
  // 2. Generate unique password per installation
  // 3. Store password in secure storage
  // See SECURITY.md for complete implementation details
  static const String _password = 'REPLACE_IN_PRODUCTION';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: _password,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // Example: if (oldVersion < 2) { ... }
  }

  Future<int> insertReading(BloodPressureReading reading) async {
    final db = await database;
    return await db.insert(_tableName, reading.toMap());
  }

  Future<List<BloodPressureReading>> getAllReadings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return BloodPressureReading.fromMap(maps[i]);
    });
  }

  Future<BloodPressureReading?> getReading(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return BloodPressureReading.fromMap(maps.first);
  }

  Future<int> updateReading(BloodPressureReading reading) async {
    if (reading.id == null) {
      throw ArgumentError('Cannot update reading without an id');
    }

    final db = await database;
    return await db.update(
      _tableName,
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  Future<int> deleteReading(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
