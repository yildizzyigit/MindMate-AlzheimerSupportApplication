import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'caregiver_screen.dart';
import 'language_screen.dart';

class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() =>
      _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  final TextEditingController _patientNameController = TextEditingController();

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _addPatient(bool isTR) async {
    final provider = context.read<AppProvider>();
    final name = _patientNameController.text.trim();

    if (name.isEmpty) return;

    final patientId = await FirebaseService.addPatient(
      caregiverId: provider.caregiverId,
      name: name,
    );

    await FirebaseService.seedDefaultMedications(patientId);

    _patientNameController.clear();

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _deletePatient(
      String patientId,
      String patientName,
      bool isTR,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTR ? 'Hastayı Sil' : 'Delete Patient'),
        content: Text(
          isTR ? '$patientName silinsin mi?' : 'Delete $patientName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isTR ? 'Vazgeç' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isTR ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseService.deletePatient(patientId);
  }

  void _showAddPatientDialog(bool isTR) {
    _patientNameController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTR ? 'Hasta Ekle' : 'Add Patient'),
        content: TextField(
          controller: _patientNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isTR ? 'Hasta adı' : 'Patient name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _patientNameController.clear();
              Navigator.of(dialogContext).pop();
            },
            child: Text(isTR ? 'Vazgeç' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addPatient(isTR),
            child: Text(isTR ? 'Ekle' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _openPatient(Map<String, dynamic> patient) {
    context.read<AppProvider>().selectPatient(
      patient['id'] as String,
      patient['name'] as String,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverScreen()),
    );
  }

  void _logout(BuildContext context) {
    context.read<AppProvider>().reset();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LanguageScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTR = provider.language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Hastalarım' : 'My Patients'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        onPressed: () => _showAddPatientDialog(isTR),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.watchPatients(provider.caregiverId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                isTR ? 'Hastalar yüklenemedi' : 'Could not load patients',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data!;

          if (patients.isEmpty) {
            return Center(
              child: Text(
                isTR ? 'Henüz hasta eklenmedi' : 'No patients added yet',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final patient = patients[index];
              final patientId = patient['id'] as String;
              final patientName = patient['name'] as String;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFAEEDA),
                    child: Text(
                      patientName.isEmpty ? '?' : patientName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFBA7517),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    isTR ? 'Hasta panelini aç' : 'Open patient panel',
                  ),
                  onTap: () => _openPatient(patient),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _deletePatient(
                      patientId,
                      patientName,
                      isTR,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}