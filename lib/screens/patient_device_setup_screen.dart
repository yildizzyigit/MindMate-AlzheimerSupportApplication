import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'patient_home_screen.dart';
import 'user_select_screen.dart';

class PatientDeviceSetupScreen extends StatefulWidget {
  const PatientDeviceSetupScreen({super.key});

  @override
  State<PatientDeviceSetupScreen> createState() =>
      _PatientDeviceSetupScreenState();
}

class _PatientDeviceSetupScreenState extends State<PatientDeviceSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<Map<String, dynamic>> _patients = [];
  String? _selectedPatientId;

  bool _obscurePassword = true;
  bool _loadingPatients = false;
  bool _caregiverVerified = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientsForCaregiver() async {
    final isTR = context.read<AppProvider>().language == 'TR';
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage(
        isTR
            ? 'Bakıcı kullanıcı adı ve şifresini girin'
            : 'Enter caregiver username and password',
      );
      return;
    }

    setState(() => _loadingPatients = true);

    try {
      final caregiverId = await FirebaseService.loginCaregiver(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (caregiverId == null) {
        setState(() => _loadingPatients = false);
        _showMessage(
          isTR
              ? 'Kullanıcı adı veya şifre hatalı'
              : 'Username or password is incorrect',
        );
        return;
      }

      final patients = await FirebaseService.getPatientsOnce(caregiverId);

      if (!mounted) return;

      setState(() {
        _patients = patients;
        _selectedPatientId =
        patients.isEmpty ? null : patients.first['id'] as String;
        _caregiverVerified = true;
        _loadingPatients = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loadingPatients = false);
      _showMessage(
        isTR
            ? 'Kullanıcı adı veya şifre hatalı'
            : 'Username or password is incorrect',
      );
    }
  }

  Future<void> _setupDevice() async {
    final isTR = context.read<AppProvider>().language == 'TR';

    if (!_caregiverVerified || _selectedPatientId == null) {
      _showMessage(
        isTR
            ? 'Önce bakıcının hastalarını getirin'
            : 'Load caregiver patients first',
      );
      return;
    }

    final selectedPatient = _patients.firstWhere(
          (patient) => patient['id'] == _selectedPatientId,
    );

    await context.read<AppProvider>().setPatientDevice(
      selectedPatient['id'] as String,
      selectedPatient['name'] as String,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserSelectScreen()),
            );
          },
        ),
        title: Text(isTR ? 'Hasta Cihazı Kur' : 'Set Up Patient Device'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Text('🙂', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isTR
                    ? 'Bu cihazı hastaya bağlayın'
                    : 'Link this device to a patient',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF085041),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTR
                    ? 'Bakıcı hesabını doğrulayın, sonra bu cihazın hangi hastaya ait olduğunu seçin.'
                    : 'Verify the caregiver account, then select which patient this device belongs to.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _usernameController,
                enabled: !_caregiverVerified,
                decoration: InputDecoration(
                  labelText:
                  isTR ? 'Bakıcı kullanıcı adı' : 'Caregiver username',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                enabled: !_caregiverVerified,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: isTR ? 'Bakıcı şifresi' : 'Caregiver password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                  _loadingPatients ? null : _loadPatientsForCaregiver,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D9E75),
                    side: const BorderSide(color: Color(0xFF1D9E75)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loadingPatients
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    isTR ? 'Hastaları Getir' : 'Load Patients',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_caregiverVerified)
                DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: InputDecoration(
                    labelText: isTR ? 'Hasta seç' : 'Select patient',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: _patients
                      .map(
                        (patient) => DropdownMenuItem(
                      value: patient['id'] as String,
                      child: Text(patient['name'] as String),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPatientId = value);
                  },
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _setupDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isTR ? 'Bu Cihazı Bağla' : 'Link This Device',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}