import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_helper.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  String _language = 'TR';
  String _userRole = '';
  String _userName = 'Demo Hasta';
  String _caregiverUsername = '';
  String _caregiverId = '';
  String _selectedPatientId = 'demo_patient';
  String _selectedPatientName = 'Demo Hasta';
  String _mood = '';
  bool _medTaken = false;
  int _todayGameCount = 0;

  String get language => _language;
  String get userRole => _userRole;
  String get userName => _userName;
  String get caregiverUsername => _caregiverUsername;
  String get caregiverId => _caregiverId;
  String get selectedPatientId => _selectedPatientId;
  String get selectedPatientName => _selectedPatientName;
  String get mood => _mood;
  bool get medTaken => _medTaken;
  int get todayGameCount => _todayGameCount;

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  Future<void> loginCaregiver(
      String username, {
        String caregiverId = '',
      }) async {
    _userRole = 'caregiver';
    _caregiverUsername = username;
    _caregiverId = caregiverId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caregiver_saved', true);
    await prefs.setString('caregiver_username', username);
    await prefs.setString('caregiver_id', caregiverId);

    notifyListeners();
  }

  Future<bool> loadSavedCaregiver() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getBool('caregiver_saved') ?? false;
    final username = prefs.getString('caregiver_username');
    final caregiverId = prefs.getString('caregiver_id');

    if (!saved || username == null || caregiverId == null || caregiverId.isEmpty) {
      return false;
    }

    _userRole = 'caregiver';
    _caregiverUsername = username;
    _caregiverId = caregiverId;

    notifyListeners();
    return true;
  }

  Future<void> setPatientDevice(String patientId, String patientName) async {
    _userRole = 'patient';
    _selectedPatientId = patientId;
    _userName = patientName;
    _selectedPatientName = patientName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('patient_device_saved', true);
    await prefs.setString('patient_id', patientId);
    await prefs.setString('patient_name', patientName);

    notifyListeners();
  }

  Future<bool> loadSavedPatientDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getBool('patient_device_saved') ?? false;
    final patientId = prefs.getString('patient_id');
    final patientName = prefs.getString('patient_name');

    if (!saved || patientId == null || patientName == null) {
      return false;
    }

    _userRole = 'patient';
    _selectedPatientId = patientId;
    _userName = patientName;
    _selectedPatientName = patientName;

    notifyListeners();
    return true;
  }

  void selectPatient(String patientId, String patientName) {
    _selectedPatientId = patientId;
    _selectedPatientName = patientName;
    notifyListeners();
  }

  Future<void> setMood(String mood) async {
    _mood = mood;

    await DBHelper.saveMood(mood, patientId: _selectedPatientId);

    await FirebaseService.saveMood(
      patientId: _selectedPatientId,
      mood: mood,
    );

    notifyListeners();
  }

  Future<void> takeMed() async {
    _medTaken = !_medTaken;
    await DBHelper.saveMedication(_medTaken, patientId: _selectedPatientId);
    notifyListeners();
  }

  Future<void> saveGameScore(String game, int score) async {
    await DBHelper.saveScore(game, score, patientId: _selectedPatientId);

    await FirebaseService.saveGameScore(
      patientId: _selectedPatientId,
      game: game,
      score: score,
    );

    _todayGameCount = await FirebaseService.getTodayGameCount(
      _selectedPatientId,
    );

    notifyListeners();
  }

  Future<void> loadTodayStats() async {
    _todayGameCount = await FirebaseService.getTodayGameCount(
      _selectedPatientId,
    );

    notifyListeners();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('patient_device_saved');
    await prefs.remove('patient_id');
    await prefs.remove('patient_name');

    await prefs.remove('caregiver_saved');
    await prefs.remove('caregiver_username');
    await prefs.remove('caregiver_id');

    try {
      await FirebaseService.logout();
    } catch (_) {}

    _userRole = '';
    _userName = 'Demo Hasta';
    _caregiverUsername = '';
    _caregiverId = '';
    _selectedPatientId = 'demo_patient';
    _selectedPatientName = 'Demo Hasta';
    _mood = '';
    _medTaken = false;
    _todayGameCount = 0;

    notifyListeners();
  }
}