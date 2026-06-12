import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'mindmate.db');

    return openDatabase(
      path,
      version: 6,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS people (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              imagePath TEXT
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS medication_schedule (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              time TEXT,
              dose TEXT,
              enabled INTEGER
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE moods ADD COLUMN patientId TEXT DEFAULT 'demo_patient'",
          );
          await db.execute(
            "ALTER TABLE medications ADD COLUMN patientId TEXT DEFAULT 'demo_patient'",
          );
          await db.execute(
            "ALTER TABLE scores ADD COLUMN patientId TEXT DEFAULT 'demo_patient'",
          );
          await db.execute(
            "ALTER TABLE people ADD COLUMN patientId TEXT DEFAULT 'demo_patient'",
          );
          await db.execute(
            "ALTER TABLE medication_schedule ADD COLUMN patientId TEXT DEFAULT 'demo_patient'",
          );
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS patients (
              id TEXT PRIMARY KEY,
              name TEXT,
              caregiverUsername TEXT,
              createdAt TEXT
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS caregivers (
              username TEXT PRIMARY KEY,
              fullName TEXT,
              password TEXT,
              createdAt TEXT
            )
          ''');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE caregivers (
            username TEXT PRIMARY KEY,
            fullName TEXT,
            password TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT,
            caregiverUsername TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE moods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT,
            date TEXT,
            patientId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taken INTEGER,
            date TEXT,
            patientId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            game TEXT,
            score INTEGER,
            date TEXT,
            patientId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE people (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            imagePath TEXT,
            patientId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE medication_schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            time TEXT,
            dose TEXT,
            enabled INTEGER,
            patientId TEXT
          )
        ''');
      },
    );
  }

  static Future<bool> caregiverExists(String username) async {
    final db = await database;

    final result = await db.query(
      'caregivers',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<bool> registerCaregiver({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final db = await database;

    final exists = await caregiverExists(username);
    if (exists) return false;

    await db.insert('caregivers', {
      'username': username,
      'fullName': fullName,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return true;
  }

  static Future<bool> validateCaregiverLogin(
      String username,
      String password,
      ) async {
    final db = await database;

    final result = await db.query(
      'caregivers',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<void> seedDefaultPatient(String caregiverUsername) async {
    final db = await database;
    final demoPatientId = 'demo_patient_$caregiverUsername';

    final existing = await db.query(
      'patients',
      where: 'id = ? AND caregiverUsername = ?',
      whereArgs: [demoPatientId, caregiverUsername],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    await db.insert('patients', {
      'id': demoPatientId,
      'name': 'Demo Hasta',
      'caregiverUsername': caregiverUsername,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPatients(
      String caregiverUsername,
      ) async {
    await seedDefaultPatient(caregiverUsername);

    final db = await database;

    return db.query(
      'patients',
      where: 'caregiverUsername = ?',
      whereArgs: [caregiverUsername],
      orderBy: 'createdAt ASC',
    );
  }

  static Future<void> addPatient({
    required String id,
    required String name,
    required String caregiverUsername,
  }) async {
    final db = await database;

    await db.insert('patients', {
      'id': id,
      'name': name,
      'caregiverUsername': caregiverUsername,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> saveMood(
      String mood, {
        String patientId = 'demo_patient',
      }) async {
    final db = await database;

    await db.insert('moods', {
      'mood': mood,
      'date': DateTime.now().toIso8601String(),
      'patientId': patientId,
    });
  }

  static Future<void> saveMedication(
      bool taken, {
        String patientId = 'demo_patient',
      }) async {
    final db = await database;

    await db.insert('medications', {
      'taken': taken ? 1 : 0,
      'date': DateTime.now().toIso8601String(),
      'patientId': patientId,
    });
  }

  static Future<void> saveScore(
      String game,
      int score, {
        String patientId = 'demo_patient',
      }) async {
    final db = await database;

    await db.insert('scores', {
      'game': game,
      'score': score,
      'date': DateTime.now().toIso8601String(),
      'patientId': patientId,
    });
  }

  static Future<List<Map<String, dynamic>>> getScores({
    String patientId = 'demo_patient',
  }) async {
    final db = await database;

    return db.query(
      'scores',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
  }

  static Future<int> getTodayGameCount({
    String patientId = 'demo_patient',
  }) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scores WHERE date LIKE ? AND patientId = ?',
      ['$today%', patientId],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  static Future<void> addPerson(
      String name,
      String imagePath, {
        String patientId = 'demo_patient',
      }) async {
    final db = await database;

    await db.insert('people', {
      'name': name,
      'imagePath': imagePath,
      'patientId': patientId,
    });
  }

  static Future<List<Map<String, dynamic>>> getPeople({
    String patientId = 'demo_patient',
  }) async {
    final db = await database;

    return db.query(
      'people',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
  }

  static Future<void> deletePerson(int id) async {
    final db = await database;

    await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> seedDefaultMedications({
    String patientId = 'demo_patient',
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM medication_schedule WHERE patientId = ?',
      [patientId],
    );

    final count = (result.first['count'] as int?) ?? 0;
    if (count > 0) return;

    await db.insert('medication_schedule', {
      'name': 'Sabah İlacı',
      'time': '08:00',
      'dose': '1 tablet',
      'enabled': 1,
      'patientId': patientId,
    });

    await db.insert('medication_schedule', {
      'name': 'Öğle İlacı',
      'time': '13:00',
      'dose': '1 tablet',
      'enabled': 1,
      'patientId': patientId,
    });

    await db.insert('medication_schedule', {
      'name': 'Akşam İlacı',
      'time': '20:00',
      'dose': '1 tablet',
      'enabled': 1,
      'patientId': patientId,
    });
  }

  static Future<List<Map<String, dynamic>>> getMedicationSchedule({
    String patientId = 'demo_patient',
  }) async {
    final db = await database;

    return db.query(
      'medication_schedule',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'time ASC',
    );
  }

  static Future<Map<String, dynamic>?> getNextEnabledMedication({
    String patientId = 'demo_patient',
  }) async {
    await seedDefaultMedications(patientId: patientId);

    final db = await database;

    final medications = await db.query(
      'medication_schedule',
      where: 'enabled = ? AND patientId = ?',
      whereArgs: [1, patientId],
      orderBy: 'time ASC',
    );

    if (medications.isEmpty) return null;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final medication in medications) {
      final time = medication['time'] as String? ?? '00:00';
      final minutes = _timeToMinutes(time);

      if (minutes >= currentMinutes) {
        return medication;
      }
    }

    return medications.first;
  }

  static Future<void> addMedicationSchedule(
      String name,
      String time,
      String dose, {
        String patientId = 'demo_patient',
      }) async {
    final db = await database;

    await db.insert('medication_schedule', {
      'name': name,
      'time': time,
      'dose': dose,
      'enabled': 1,
      'patientId': patientId,
    });
  }

  static Future<void> updateMedicationSchedule(
      int id,
      String name,
      String time,
      String dose,
      ) async {
    final db = await database;

    await db.update(
      'medication_schedule',
      {
        'name': name,
        'time': time,
        'dose': dose,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateMedicationEnabled(int id, bool enabled) async {
    final db = await database;

    await db.update(
      'medication_schedule',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }
  static Future<void> deletePatient(String patientId) async {
    final db = await database;

    await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [patientId],
    );

    await db.delete(
      'medication_schedule',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );

    await db.delete(
      'people',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );

    await db.delete(
      'scores',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );

    await db.delete(
      'moods',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );

    await db.delete(
      'medications',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
  }
}