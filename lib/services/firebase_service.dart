import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String usernameToEmail(String username) {
    return '${username.trim().toLowerCase()}@mindmate.local';
  }

  static Future<bool> registerCaregiver({
    required String fullName,
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final email = usernameToEmail(cleanUsername);

    final usernameDoc =
    await _db.collection('usernames').doc(cleanUsername).get();

    if (usernameDoc.exists) {
      return false;
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    await _db.collection('caregivers').doc(uid).set({
      'uid': uid,
      'fullName': fullName.trim(),
      'username': cleanUsername,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('usernames').doc(cleanUsername).set({
      'uid': uid,
      'role': 'caregiver',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  static Future<String?> loginCaregiver({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final email = usernameToEmail(cleanUsername);

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user?.uid;
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<String> addPatient({
    required String caregiverId,
    required String name,
  }) async {
    final doc = _db.collection('patients').doc();

    await doc.set({
      'id': doc.id,
      'caregiverId': caregiverId,
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  static Stream<List<Map<String, dynamic>>> watchPatients(String caregiverId) {
    return _db
        .collection('patients')
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .map((snapshot) {
      final patients = snapshot.docs
          .map(
            (doc) => {
          'id': doc.id,
          ...doc.data(),
        },
      )
          .toList();

      patients.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      return patients;
    });
  }

  static Future<List<Map<String, dynamic>>> getPatientsOnce(
      String caregiverId,
      ) async {
    final snapshot = await _db
        .collection('patients')
        .where('caregiverId', isEqualTo: caregiverId)
        .get();

    final patients = snapshot.docs
        .map(
          (doc) => {
        'id': doc.id,
        ...doc.data(),
      },
    )
        .toList();

    patients.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );

    return patients;
  }

  static Future<void> deletePatient(String patientId) async {
    final batch = _db.batch();

    final patientRef = _db.collection('patients').doc(patientId);
    batch.delete(patientRef);

    final medications = await _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in medications.docs) {
      batch.delete(doc.reference);
    }

    final scores = await _db
        .collection('scores')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in scores.docs) {
      batch.delete(doc.reference);
    }

    final moods = await _db
        .collection('moods')
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in moods.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static Future<void> seedDefaultMedications(String patientId) async {
    final existing = await _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await addMedication(
      patientId: patientId,
      name: 'Sabah İlacı',
      time: '08:00',
      dose: '1 tablet',
    );

    await addMedication(
      patientId: patientId,
      name: 'Öğle İlacı',
      time: '13:00',
      dose: '1 tablet',
    );

    await addMedication(
      patientId: patientId,
      name: 'Akşam İlacı',
      time: '20:00',
      dose: '1 tablet',
    );
  }

  static Future<void> addMedication({
    required String patientId,
    required String name,
    required String time,
    required String dose,
  }) async {
    final doc = _db.collection('medications').doc();

    await doc.set({
      'id': doc.id,
      'patientId': patientId,
      'name': name.trim(),
      'time': time.trim(),
      'dose': dose.trim(),
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateMedication({
    required String medicationId,
    required String name,
    required String time,
    required String dose,
  }) async {
    await _db.collection('medications').doc(medicationId).update({
      'name': name.trim(),
      'time': time.trim(),
      'dose': dose.trim(),
    });
  }

  static Future<void> updateMedicationEnabled({
    required String medicationId,
    required bool enabled,
  }) async {
    await _db.collection('medications').doc(medicationId).update({
      'enabled': enabled,
    });
  }

  static Stream<List<Map<String, dynamic>>> watchMedications(String patientId) {
    return _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final medications = snapshot.docs
          .map(
            (doc) => {
          'id': doc.id,
          ...doc.data(),
        },
      )
          .toList();

      medications.sort(
            (a, b) => (a['time'] as String).compareTo(b['time'] as String),
      );

      return medications;
    });
  }

  static Future<Map<String, dynamic>?> getNextEnabledMedication(
      String patientId,
      ) async {


    final snapshot = await _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .where('enabled', isEqualTo: true)
        .get();

    final medications = snapshot.docs
        .map(
          (doc) => {
        'id': doc.id,
        ...doc.data(),
      },
    )
        .toList();

    if (medications.isEmpty) return null;

    medications.sort(
          (a, b) => (a['time'] as String).compareTo(b['time'] as String),
    );

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

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }
  static String todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<void> markMedicationTaken({
    required String patientId,
    required String medicationId,
    required String medicationName,
  }) async {
    final dateKey = todayKey();
    final docId = '${patientId}_${medicationId}_$dateKey';

    await _db.collection('medication_logs').doc(docId).set({
      'id': docId,
      'patientId': patientId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'date': dateKey,
      'taken': true,
      'takenAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, bool>> watchTodayMedicationTakenMap(
      String patientId,
      ) {
    final dateKey = todayKey();

    return _db
        .collection('medication_logs')
        .where('patientId', isEqualTo: patientId)
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) {
      final result = <String, bool>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        result[data['medicationId'] as String] = data['taken'] == true;
      }

      return result;
    });
  }
  static Future<void> deleteMedication(String medicationId) async {
    final logsSnapshot = await _db
        .collection('medication_logs')
        .where('medicationId', isEqualTo: medicationId)
        .get();

    final batch = _db.batch();

    for (final doc in logsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_db.collection('medications').doc(medicationId));

    await batch.commit();
  }
  static Future<void> saveGameScore({
    required String patientId,
    required String game,
    required int score,
  }) async {
    await _db.collection('game_scores').add({
      'patientId': patientId,
      'game': game,
      'score': score,
      'date': todayKey(),
      'createdAtLocal': DateTime.now().toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<int> getTodayGameCount(String patientId) async {
    final snapshot = await _db
        .collection('game_scores')
        .where('patientId', isEqualTo: patientId)
        .where('date', isEqualTo: todayKey())
        .get();

    return snapshot.docs.length;
  }

  static Future<List<Map<String, dynamic>>> getGameScores(
      String patientId,
      ) async {
    final snapshot = await _db
        .collection('game_scores')
        .where('patientId', isEqualTo: patientId)
        .get();

    final scores = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'patientId': data['patientId'],
        'game': data['game'],
        'score': data['score'],
        'date': data['createdAtLocal'] ?? data['date'],
      };
    }).toList();

    scores.sort((a, b) {
      final aDate = DateTime.tryParse((a['date'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b['date'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return scores;
  }
  static Future<void> saveMood({
    required String patientId,
    required String mood,
  }) async {
    final dateKey = todayKey();
    final docId = '${patientId}_$dateKey';

    await _db.collection('mood_logs').doc(docId).set({
      'id': docId,
      'patientId': patientId,
      'mood': mood,
      'date': dateKey,
      'createdAtLocal': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, dynamic>?> watchTodayMood(String patientId) {
    final dateKey = todayKey();
    final docId = '${patientId}_$dateKey';

    return _db.collection('mood_logs').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }
  static Future<List<Map<String, dynamic>>> getMedicationsOnce(
      String patientId,
      ) async {
    final snapshot = await _db
        .collection('medications')
        .where('patientId', isEqualTo: patientId)
        .get();

    final medications = snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'name': data['name'],
        'time': data['time'],
        'dose': data['dose'],
        'enabled': data['enabled'],
        'patientId': data['patientId'],
      };
    }).toList();

    medications.sort((a, b) {
      final aTime = (a['time'] as String?) ?? '';
      final bTime = (b['time'] as String?) ?? '';
      return aTime.compareTo(bTime);
    });

    return medications;
  }
}