import '../services/firebase_service.dart';
import '../database/db_helper.dart';
import 'puzzle_screen.dart';
import 'clock_screen.dart';
import 'face_name_screen.dart';
import 'word_recall_screen.dart';
import 'number_sequence_screen.dart';
import 'card_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'language_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTR = provider.language == 'TR';
    final now = DateTime.now();
    final hour = now.hour;

    String greeting = isTR
        ? (hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi Öğleden Sonralar' : 'İyi Akşamlar')
        : (hour < 12 ? 'Good Morning' : hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF1D9E75),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$greeting, ${provider.userName}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final appProvider = context.read<AppProvider>();

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LanguageScreen()),
                                (route) => false,
                          );

                          Future.microtask(() async {
                            await appProvider.reset();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isTR ? 'Çıkış' : 'Exit',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📅 ${_getDateString(now, isTR)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    _getSeasonString(now.month, isTR),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Ruh hali
                    _MoodCard(isTR: isTR),
                    const SizedBox(height: 14),
                    // İlaç
                    _MedCard(isTR: isTR),
                    const SizedBox(height: 14),
                    // Aktiviteler
                    _GamesSection(isTR: isTR),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateString(DateTime now, bool isTR) {
    final days = isTR
        ? ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar']
        : ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = isTR
        ? ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık']
        : ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final day = days[now.weekday - 1];
    final month = months[now.month - 1];
    return '$day, ${now.day} $month ${now.year}';
  }

  String _getSeasonString(int month, bool isTR) {
    if ([3,4,5].contains(month)) return isTR ? '🌸 İlkbahar' : '🌸 Spring';
    if ([6,7,8].contains(month)) return isTR ? '☀️ Yaz' : '☀️ Summer';
    if ([9,10,11].contains(month)) return isTR ? '🍂 Sonbahar' : '🍂 Autumn';
    return isTR ? '❄️ Kış' : '❄️ Winter';
  }
}

class _MoodCard extends StatelessWidget {
  final bool isTR;
  const _MoodCard({required this.isTR});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTR ? 'Bugün nasıl hissediyorsun?' : 'How are you feeling today?',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MoodBtn(emoji: '😊', label: isTR ? 'Harika' : 'Great', moodKey: 'great',
                  activeColor: const Color(0xFF1D9E75), activeBg: const Color(0xFFE1F5EE)),
              const SizedBox(width: 10),
              _MoodBtn(emoji: '😐', label: isTR ? 'İyi' : 'Okay', moodKey: 'ok',
                  activeColor: const Color(0xFFBA7517), activeBg: const Color(0xFFFAEEDA)),
              const SizedBox(width: 10),
              _MoodBtn(emoji: '😔', label: isTR ? 'Üzgün' : 'Sad', moodKey: 'sad',
                  activeColor: const Color(0xFF993C1D), activeBg: const Color(0xFFFAECE7)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final String moodKey;
  final Color activeColor;
  final Color activeBg;

  const _MoodBtn({
    required this.emoji,
    required this.label,
    required this.moodKey,
    required this.activeColor,
    required this.activeBg,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isActive = provider.mood == moodKey;

    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AppProvider>().setMood(moodKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? activeColor : Colors.black12,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: isActive ? activeColor : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final bool isTR;
  const _MedCard({required this.isTR});

  Map<String, dynamic>? _findNextMedication(
      List<Map<String, dynamic>> medications,
      ) {
    if (medications.isEmpty) return null;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final medication in medications) {
      final time = medication['time'] as String? ?? '00:00';
      final parts = time.split(':');

      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final medicationMinutes = hour * 60 + minute;

      if (medicationMinutes >= currentMinutes) {
        return medication;
      }
    }

    return medications.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patientId = provider.selectedPatientId;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.watchMedications(patientId),
      builder: (context, medicationSnapshot) {
        return StreamBuilder<Map<String, bool>>(
          stream: FirebaseService.watchTodayMedicationTakenMap(patientId),
          builder: (context, takenSnapshot) {
            if (medicationSnapshot.hasError) {
              return _MedicineShell(
                child: Text(
                  isTR ? 'İlaçlar yüklenemedi' : 'Could not load medicines',
                  style: const TextStyle(
                    color: Color(0xFF633806),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            if (!medicationSnapshot.hasData || !takenSnapshot.hasData) {
              return const _MedicineShell(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final medications = medicationSnapshot.data!
                .where((medication) => medication['enabled'] == true)
                .toList();

            final takenMap = takenSnapshot.data!;
            final nextMedication = _findNextMedication(medications);

            if (medications.isEmpty) {
              return _MedicineShell(
                child: Row(
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isTR
                            ? 'Bugün için ilaç programı yok'
                            : 'No medicine scheduled for today',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF633806),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return _MedicineShell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTR ? 'Bugünkü İlaçlar' : 'Today’s Medicines',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF633806),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...medications.map((medication) {
                    final medicationId = medication['id'] as String;
                    final isTaken = takenMap[medicationId] == true;
                    final isNext = nextMedication != null &&
                        nextMedication['id'] == medicationId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isTaken
                            ? const Color(0xFFE1F5EE)
                            : isNext
                            ? Colors.white
                            : const Color(0xFFFFFAF0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isTaken
                              ? const Color(0xFF1D9E75)
                              : isNext
                              ? const Color(0xFFBA7517)
                              : const Color(0xFFF3D9A8),
                          width: isTaken || isNext ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isTaken
                                      ? const Color(0xFF1D9E75)
                                      : isNext
                                      ? const Color(0xFFBA7517)
                                      : const Color(0xFFFAEEDA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    medication['time'] as String,
                                    style: TextStyle(
                                      color: isTaken || isNext
                                          ? Colors.white
                                          : const Color(0xFF633806),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medication['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF633806),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      medication['dose'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF854F0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isTaken)
                                Text(
                                  isTR ? 'Alındı' : 'Taken',
                                  style: const TextStyle(
                                    color: Color(0xFF1D9E75),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                )
                              else if (isNext)
                                Text(
                                  isTR ? 'Sıradaki' : 'Next',
                                  style: const TextStyle(
                                    color: Color(0xFF633806),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isTaken
                                  ? null
                                  : () async {
                                await FirebaseService.markMedicationTaken(
                                  patientId: patientId,
                                  medicationId: medicationId,
                                  medicationName:
                                  medication['name'] as String,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBA7517),
                                disabledBackgroundColor:
                                const Color(0xFF1D9E75),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isTaken
                                    ? (isTR ? 'Bu ilaç alındı' : 'Taken')
                                    : (isTR ? 'Bu ilacı aldım' : 'I took this'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    isTR
                        ? 'Program bakıcı panelinden düzenlenir'
                        : 'Schedule is managed by the caregiver',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9B6A23),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MedicineShell extends StatelessWidget {
  final Widget child;

  const _MedicineShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFAC775),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _GamesSection extends StatelessWidget {
  final bool isTR;
  const _GamesSection({required this.isTR});

  @override
  Widget build(BuildContext context) {
    final games = [
      {'emoji': '🃏', 'name': isTR ? 'Kart Eşleştirme' : 'Card Matching', 'color': const Color(0xFFE1F5EE)},
      {'emoji': '🔢', 'name': isTR ? 'Sayı Dizisi' : 'Number Sequence', 'color': const Color(0xFFE6F1FB)},
      {'emoji': '😊', 'name': isTR ? 'Yüz & İsim' : 'Face & Name', 'color': const Color(0xFFFAEEDA)},
      {'emoji': '🕐', 'name': isTR ? 'Saat Çizme' : 'Clock Drawing', 'color': const Color(0xFFFAECE7)},
      {'emoji': '📝', 'name': isTR ? 'Kelime Hatırlama' : 'Word Recall', 'color': const Color(0xFFEEEDFE)},
      {'emoji': '🧩', 'name': isTR ? 'Puzzle' : 'Puzzle', 'color': const Color(0xFFE1F5EE)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTR ? 'Günlük Aktiviteler' : 'Daily Activities',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return GestureDetector(
              onTap: () {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CardMatchScreen()),
                  );
                } else if (index == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NumberSequenceScreen()),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaceNameScreen()),
                  );
                } else if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClockScreen()),
                  );
                } else if (index == 4) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WordRecallScreen()),
                  );
                } else if (index == 5) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PuzzleScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: game['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(game['emoji'] as String,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game['name'] as String,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}