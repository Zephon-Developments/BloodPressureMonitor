import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:blood_pressure_monitor/services/secure_password_manager.dart';

/// Database service providing encrypted local storage for health data.
///
/// Uses sqflite_sqlcipher for AES-256 encryption of sensitive blood pressure,
/// medication, weight, and sleep data. Handles schema creation, migrations,
/// and provides a single database instance throughout the app lifecycle.
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'blood_pressure.db';
  static const int _databaseVersion = 2;

  final Database? _testDatabase;

  /// Creates a DatabaseService with optional test database injection.
  ///
  /// Parameters:
  /// - [testDatabase]: Optional database instance for testing (bypasses encryption)
  DatabaseService({Database? testDatabase}) : _testDatabase = testDatabase;

  /// Gets the singleton database instance, initializing if necessary.
  ///
  /// The database is encrypted with AES-256 using sqflite_sqlcipher.
  Future<Database> get database async {
    if (_testDatabase != null) return _testDatabase!;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the encrypted database.
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _databaseName);

    // Get secure password from platform secure storage
    String password;
    try {
      password = await SecurePasswordManager.getOrCreatePassword();
    } on Exception catch (e, stackTrace) {
      // Log error details for diagnostics and fail initialization explicitly
      stderr.writeln('Error retrieving secure database password: $e');
      stderr.writeln(stackTrace);
      throw StateError(
        'Failed to initialize encrypted database: could not retrieve secure password.',
      );
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: password,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the database schema on first run.
  ///
  /// Defines all tables with proper foreign keys and indexes for performance.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        colorHex TEXT,
        avatarIcon TEXT,
        yearOfBirth INTEGER,
        preferredUnits TEXT NOT NULL DEFAULT 'mmHg',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Reading (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER NOT NULL,
        takenAt TEXT NOT NULL,
        localOffsetMinutes INTEGER NOT NULL,
        posture TEXT,
        arm TEXT,
        medsContext TEXT,
        irregularFlag INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        note TEXT,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_reading_profile_time 
      ON Reading(profileId, takenAt DESC)
    ''');

    await db.execute('''
      CREATE TABLE ReadingGroup (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        groupStartAt TEXT NOT NULL,
        windowMinutes INTEGER NOT NULL DEFAULT 30,
        avgSystolic REAL NOT NULL,
        avgDiastolic REAL NOT NULL,
        avgPulse REAL NOT NULL,
        memberReadingIds TEXT NOT NULL,
        sessionId TEXT,
        note TEXT,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_readinggroup_profile_time 
      ON ReadingGroup(profileId, groupStartAt DESC)
    ''');

    await db.execute('''
      CREATE TABLE Medication (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT,
        unit TEXT,
        frequency TEXT,
        scheduleMetadata TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE MedicationGroup (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        name TEXT NOT NULL,
        memberMedicationIds TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE MedicationIntake (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        profileId INTEGER NOT NULL,
        takenAt TEXT NOT NULL,
        localOffsetMinutes INTEGER NOT NULL,
        scheduledFor TEXT,
        groupId INTEGER,
        note TEXT,
        FOREIGN KEY (medicationId) REFERENCES Medication(id) ON DELETE CASCADE,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE,
        FOREIGN KEY (groupId) REFERENCES MedicationGroup(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_medicationintake_profile_time 
      ON MedicationIntake(profileId, takenAt DESC)
    ''');

    await db.execute('''
      CREATE TABLE WeightEntry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        takenAt TEXT NOT NULL,
        weight REAL NOT NULL,
        saltNote TEXT,
        exerciseNote TEXT,
        sleepQuality TEXT,
        stressLevel TEXT,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE SleepEntry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        nightOf TEXT NOT NULL,
        totalSleepMinutes INTEGER NOT NULL,
        timeInBedMinutes INTEGER NOT NULL,
        wakeCount INTEGER NOT NULL,
        sleepScore REAL,
        source TEXT NOT NULL,
        importedAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Reminder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        schedule TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Handles database migrations between versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from v1 to v2: Add medication management fields
      await db.execute(
        'ALTER TABLE Medication ADD COLUMN unit TEXT',
      );
      await db.execute(
        'ALTER TABLE Medication ADD COLUMN frequency TEXT',
      );
      await db.execute(
        'ALTER TABLE Medication ADD COLUMN scheduleMetadata TEXT',
      );
      await db.execute(
        'ALTER TABLE Medication ADD COLUMN createdAt TEXT NOT NULL DEFAULT ""',
      );

      await db.execute(
        'ALTER TABLE MedicationGroup ADD COLUMN createdAt TEXT NOT NULL DEFAULT ""',
      );

      await db.execute(
        'ALTER TABLE MedicationIntake ADD COLUMN localOffsetMinutes INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE MedicationIntake ADD COLUMN scheduledFor TEXT',
      );
    }
  }

  /// Closes the database connection.
  ///
  /// Should be called when the app is terminating to ensure proper cleanup.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
