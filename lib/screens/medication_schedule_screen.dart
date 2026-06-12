import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key});

  @override
  State<MedicationScheduleScreen> createState() =>
      _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTR = provider.language == 'TR';
    final patientId = provider.selectedPatientId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'İlaç Programı' : 'Medication Schedule'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        onPressed: () => _showMedicationDialog(context, isTR, patientId),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.watchMedications(patientId),
        builder: (context, medicationSnapshot) {
          return StreamBuilder<Map<String, bool>>(
            stream: FirebaseService.watchTodayMedicationTakenMap(patientId),
            builder: (context, takenSnapshot) {
              if (medicationSnapshot.hasError || takenSnapshot.hasError) {
                return Center(
                  child: Text(
                    isTR
                        ? 'İlaçlar yüklenemedi'
                        : 'Could not load medications',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              if (!medicationSnapshot.hasData || !takenSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final medications = medicationSnapshot.data!;
              final takenMap = takenSnapshot.data!;

              if (medications.isEmpty) {
                return Center(
                  child: Text(
                    isTR ? 'Henüz ilaç eklenmedi' : 'No medicines added yet',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: medications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final medication = medications[index];
                  final medicationId = medication['id'] as String;
                  final enabled = medication['enabled'] == true;
                  final isTaken = takenMap[medicationId] == true;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTaken ? const Color(0xFFE1F5EE) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTaken
                            ? const Color(0xFF1D9E75)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isTaken
                                ? const Color(0xFF1D9E75)
                                : const Color(0xFFFAEEDA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              isTaken ? '✓' : '💊',
                              style: TextStyle(
                                fontSize: 24,
                                color: isTaken ? Colors.white : null,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication['name'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${medication['time']} · ${medication['dose']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTaken
                                    ? (isTR ? 'Bugün alındı' : 'Taken today')
                                    : (isTR
                                    ? 'Bugün bekliyor'
                                    : 'Pending today'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isTaken
                                      ? const Color(0xFF1D9E75)
                                      : const Color(0xFFBA7517),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _showMedicationDialog(
                            context,
                            isTR,
                            patientId,
                            medication: medication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDeleteMedication(
                            context,
                            isTR,
                            medicationId,
                            medication['name'] as String,
                          ),
                        ),
                        Switch(
                          value: enabled,
                          activeColor: const Color(0xFFBA7517),
                          onChanged: (value) async {
                            await FirebaseService.updateMedicationEnabled(
                              medicationId: medicationId,
                              enabled: value,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showMedicationDialog(
      BuildContext context,
      bool isTR,
      String patientId, {
        Map<String, dynamic>? medication,
      }) {
    final nameController = TextEditingController(
      text: medication?['name'] as String? ?? '',
    );
    final timeController = TextEditingController(
      text: medication?['time'] as String? ?? '09:00',
    );
    final doseController = TextEditingController(
      text: medication?['dose'] as String? ?? '1 tablet',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          medication == null
              ? (isTR ? 'İlaç Ekle' : 'Add Medicine')
              : (isTR ? 'İlacı Düzenle' : 'Edit Medicine'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isTR ? 'İlaç adı' : 'Medicine name',
              ),
            ),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: isTR ? 'Saat' : 'Time',
                hintText: '09:00',
              ),
            ),
            TextField(
              controller: doseController,
              decoration: InputDecoration(
                labelText: isTR ? 'Doz' : 'Dose',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTR ? 'Vazgeç' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final time = timeController.text.trim();
              final dose = doseController.text.trim();

              if (name.isEmpty || time.isEmpty || dose.isEmpty) return;

              if (medication == null) {
                await FirebaseService.addMedication(
                  patientId: patientId,
                  name: name,
                  time: time,
                  dose: dose,
                );
              } else {
                await FirebaseService.updateMedication(
                  medicationId: medication['id'] as String,
                  name: name,
                  time: time,
                  dose: dose,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(isTR ? 'Kaydet' : 'Save'),
          ),
        ],
      ),
    );
  }
  void _confirmDeleteMedication(
      BuildContext context,
      bool isTR,
      String medicationId,
      String medicationName,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTR ? 'İlacı Sil' : 'Delete Medicine'),
        content: Text(
          isTR ? '$medicationName silinsin mi?' : 'Delete $medicationName?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(isTR ? 'Vazgeç' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await FirebaseService.deleteMedication(medicationId);
            },
            child: Text(isTR ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );
  }
}