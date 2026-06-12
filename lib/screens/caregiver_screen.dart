import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'language_screen.dart';
import 'medication_schedule_screen.dart';
import 'people_manager_screen.dart';
import 'reminder_settings_screen.dart';
import 'weekly_report_screen.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  int _gameCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    final patientId = context.read<AppProvider>().selectedPatientId;
    final count = await FirebaseService.getTodayGameCount(patientId);

    if (!mounted) return;

    setState(() => _gameCount = count);
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'great':
        return '😊';
      case 'ok':
        return '😐';
      case 'bad':
      case 'sad':
        return '😔';
      default:
        return '—';
    }
  }

  String _getDateString(DateTime now, bool isTR) {
    final days = isTR
        ? [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ]
        : [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final months = isTR
        ? [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ]
        : [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final day = days[now.weekday - 1];
    final month = months[now.month - 1];

    return '$day, ${now.day} $month ${now.year}';
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
    final now = DateTime.now();
    final dateText = _getDateString(now, isTR);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: const BoxDecoration(
                color: Color(0xFFBA7517),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTR ? 'Bakıcı Paneli' : 'Caregiver Panel',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.selectedPatientName} · $dateText',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTR ? 'Çıkış' : 'Exit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _StatCard(
                          value: '$_gameCount',
                          label: isTR ? 'Oyun\ntamamlandı' : 'Games\ndone',
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<Map<String, dynamic>?>(
                          stream: FirebaseService.watchTodayMood(
                            provider.selectedPatientId,
                          ),
                          builder: (context, snapshot) {
                            final mood =
                                snapshot.data?['mood'] as String? ?? '';

                            return _StatCard(
                              value: _moodEmoji(mood),
                              label: isTR ? 'Ruh\nhali' : 'Mood',
                              isEmoji: true,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<Map<String, bool>>(
                          stream: FirebaseService.watchTodayMedicationTakenMap(
                            provider.selectedPatientId,
                          ),
                          builder: (context, snapshot) {
                            final takenMap = snapshot.data ?? {};
                            final hasTakenMedicine =
                            takenMap.values.any((taken) => taken);

                            return _StatCard(
                              value: hasTakenMedicine ? '✅' : '❌',
                              label: isTR ? 'İlaç\nalındı' : 'Med\ntaken',
                              isEmoji: true,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isTR ? 'Yönetim' : 'Management',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuItem(
                      emoji: '📅',
                      title: isTR ? 'İlaç Programı' : 'Medication Schedule',
                      subtitle: isTR
                          ? 'Saatleri ve dozları düzenle'
                          : 'Edit times and doses',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicationScheduleScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      emoji: '📈',
                      title: isTR ? 'Haftalık Rapor' : 'Weekly Report',
                      subtitle: isTR
                          ? 'Aktivite ve hafıza trendleri'
                          : 'Activity and memory trends',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeeklyReportScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      emoji: '🔔',
                      title: isTR ? 'Bildirim Testi' : 'Notification Test',
                      subtitle:
                      isTR ? 'Cihaz bildirimlerini dene' : 'Test device notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReminderSettingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MenuItem(
                      emoji: '👤',
                      title: isTR ? 'Kişi Yönetimi' : 'People Management',
                      subtitle: isTR
                          ? 'Fotoğraf ve isim ekle'
                          : 'Add photos and names',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PeopleManagerScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isEmoji;

  const _StatCard({
    required this.value,
    required this.label,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isEmoji ? 28 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBA7517),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}