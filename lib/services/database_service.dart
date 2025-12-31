import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  static const int _databaseVersion = 5;

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
      debugPrint('Error retrieving secure database password: $e');
      debugPrint(stackTrace.toString());
      throw StateError(
        'Failed to initialize encrypted database: could not retrieve secure password.',
      );
    }

    // Check if database file exists
    final dbFile = File(path);
    final bool dbExists = await dbFile.exists();

    if (dbExists) {
      // Try to open with secure password first
      try {
        return await openDatabase(
          path,
          version: _databaseVersion,
          password: password,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      } on Exception catch (_) {
        // Failed to open with secure password, try migration from placeholder
        debugPrint(
          'Attempting database migration from placeholder password...',
        );
        return await _migrateFromPlaceholderPassword(path, password);
      }
    } else {
      // New database, use secure password
      return await openDatabase(
        path,
        version: _databaseVersion,
        password: password,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  /// Migrates database from placeholder password to secure password.
  ///
  /// Attempts to open database with old placeholder password and rekey to
  /// the new secure password. This is a one-time migration for existing users.
  Future<Database> _migrateFromPlaceholderPassword(
    String path,
    String newPassword,
  ) async {
    const String placeholderPassword = 'placeholder_password';

    try {
      // Try to open with old placeholder password
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        password: placeholderPassword,
        onUpgrade: _onUpgrade,
      );

      // Successfully opened with placeholder, now rekey to secure password
      debugPrint('Database opened with placeholder password, rekeying...');
      await db.execute("PRAGMA rekey = '${newPassword.replaceAll("'", "''")}'");
      debugPrint('Database successfully rekeyed to secure password.');

      return db;
    } on Exception catch (e, stackTrace) {
      // Migration failed, database is likely corrupted or uses unknown password
      debugPrint('Failed to migrate database: $e');
      debugPrint(stackTrace.toString());
      throw StateError(
        'Database migration failed. The database may be corrupted or use an unknown password.',
      );
    }
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
        isActive INTEGER NOT NULL DEFAULT 1,
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
        localOffsetMinutes INTEGER NOT NULL,
        weightValue REAL NOT NULL,
        unit TEXT NOT NULL,
        notes TEXT,
        saltIntake TEXT,
        exerciseLevel TEXT,
        stressLevel TEXT,
        sleepQuality TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        sourceMetadata TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_weightentry_profile_time 
      ON WeightEntry(profileId, takenAt DESC)
    ''');

    await _createSleepEntryTable(db);
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
        'ALTER TABLE Medication ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1',
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

    if (oldVersion < 3) {
      // Migration from v2 to v3: Update WeightEntry and SleepEntry schema
      await db.transaction((txn) async {
        // Migrate WeightEntry table
        await txn.execute('''
          CREATE TABLE WeightEntry_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profileId INTEGER NOT NULL,
            takenAt TEXT NOT NULL,
            localOffsetMinutes INTEGER NOT NULL,
            weightValue REAL NOT NULL,
            unit TEXT NOT NULL,
            notes TEXT,
            saltIntake TEXT,
            exerciseLevel TEXT,
            stressLevel TEXT,
            sleepQuality TEXT,
            source TEXT NOT NULL DEFAULT 'manual',
            sourceMetadata TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
          )
        ''');

        // Copy existing data, mapping old columns to new schema
        await txn.execute('''
          INSERT INTO WeightEntry_new 
            (id, profileId, takenAt, localOffsetMinutes, weightValue, unit, 
             saltIntake, exerciseLevel, sleepQuality, stressLevel, source, createdAt)
          SELECT 
            id, profileId, takenAt, 
            0, -- default localOffsetMinutes
            weight, 'kg', -- weight as weightValue, default unit kg
            saltNote, exerciseNote, sleepQuality, stressLevel,
            'manual', -- default source
            takenAt -- use takenAt as createdAt for existing entries
          FROM WeightEntry
        ''');

        await txn.execute('DROP TABLE WeightEntry');
        await txn.execute('ALTER TABLE WeightEntry_new RENAME TO WeightEntry');

        await txn.execute('''
          CREATE INDEX idx_weightentry_profile_time 
          ON WeightEntry(profileId, takenAt DESC)
        ''');

        // Migrate SleepEntry table
        await txn.execute('''
          CREATE TABLE SleepEntry_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profileId INTEGER NOT NULL,
            startedAt TEXT NOT NULL,
            endedAt TEXT,
            durationMinutes INTEGER NOT NULL,
            quality INTEGER,
            localOffsetMinutes INTEGER NOT NULL,
            source TEXT NOT NULL DEFAULT 'manual',
            sourceMetadata TEXT,
            notes TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
          )
        ''');

        // Copy existing data, mapping old columns to new schema
        await txn.execute('''
          INSERT INTO SleepEntry_new 
            (id, profileId, startedAt, endedAt, durationMinutes, quality,
             localOffsetMinutes, source, createdAt)
          SELECT 
            id, profileId,
            nightOf || 'T22:00:00.000Z', -- construct startedAt from nightOf
            NULL, -- no endedAt available
            totalSleepMinutes, -- map to durationMinutes
            CASE 
              WHEN sleepScore IS NOT NULL THEN MAX(1, MIN(5, CAST((sleepScore / 20.0) + 0.5 AS INTEGER)))
              ELSE NULL
            END, -- convert 0-100 score to 1-5 quality with clamping
            0, -- default localOffsetMinutes
            source, -- preserve existing source
            importedAt -- use importedAt as createdAt
          FROM SleepEntry
        ''');

        await txn.execute('DROP TABLE SleepEntry');
        await txn.execute('ALTER TABLE SleepEntry_new RENAME TO SleepEntry');

        await txn.execute('''
          CREATE INDEX idx_sleepentry_profile_time 
          ON SleepEntry(profileId, endedAt DESC)
        ''');

        await txn.execute('''
          CREATE INDEX idx_sleepentry_profile_started 
          ON SleepEntry(profileId, startedAt)
        ''');
      });
    }

    if (oldVersion < 4) {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE SleepEntry_v4 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profileId INTEGER NOT NULL,
            startedAt TEXT NOT NULL,
            endedAt TEXT,
            durationMinutes INTEGER NOT NULL,
            quality INTEGER,
            deepMinutes INTEGER,
            lightMinutes INTEGER,
            remMinutes INTEGER,
            awakeMinutes INTEGER,
            localOffsetMinutes INTEGER NOT NULL,
            source TEXT NOT NULL DEFAULT 'manual',
            sourceMetadata TEXT,
            notes TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
          )
        ''');

        await txn.execute('''
          INSERT INTO SleepEntry_v4 (
            id, profileId, startedAt, endedAt, durationMinutes, quality,
            deepMinutes, lightMinutes, remMinutes, awakeMinutes,
            localOffsetMinutes, source, sourceMetadata, notes, createdAt
          )
          SELECT 
            id, profileId, startedAt, endedAt, durationMinutes, quality,
            NULL, NULL, NULL, NULL,
            localOffsetMinutes, source, sourceMetadata, notes, createdAt
          FROM SleepEntry
        ''');

        await txn.execute('DROP TABLE SleepEntry');
        await txn.execute('ALTER TABLE SleepEntry_v4 RENAME TO SleepEntry');

        await txn.execute('''
          CREATE INDEX idx_sleepentry_profile_time 
          ON SleepEntry(profileId, endedAt DESC)
        ''');

        await txn.execute('''
          CREATE INDEX idx_sleepentry_profile_started 
          ON SleepEntry(profileId, startedAt)
        ''');
      });
    }

    if (oldVersion < 5) {
      // Migration from v4 to v5: Remove Reminder feature
      await db.execute('DROP TABLE IF EXISTS Reminder');
    }
  }

  Future<void> _createSleepEntryTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE SleepEntry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        startedAt TEXT NOT NULL,
        endedAt TEXT,
        durationMinutes INTEGER NOT NULL,
        quality INTEGER,
        deepMinutes INTEGER,
        lightMinutes INTEGER,
        remMinutes INTEGER,
        awakeMinutes INTEGER,
        localOffsetMinutes INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        sourceMetadata TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sleepentry_profile_time 
      ON SleepEntry(profileId, endedAt DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_sleepentry_profile_started 
      ON SleepEntry(profileId, startedAt)
    ''');
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
