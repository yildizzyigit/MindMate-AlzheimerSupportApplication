import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../providers/app_provider.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  List<Map<String, dynamic>> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final patientId = context.read<AppProvider>().selectedPatientId;
    final scores = await FirebaseService.getGameScores(patientId);

    if (!mounted) return;

    setState(() {
      _scores = scores;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTR = provider.language == 'TR';
    final weekScores = _scores.where((score) {
      final dateText = score['date'] as String?;
      if (dateText == null) return false;
      final date = DateTime.tryParse(dateText);
      if (date == null) return false;
      return DateTime.now().difference(date).inDays < 7;
    }).toList();

    final totalGames = weekScores.length;
    final bestScore = weekScores.isEmpty
        ? 0
        : weekScores.map((score) => (score['score'] as int?) ?? 0).reduce(max);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Haftalık Rapor' : 'Weekly Report'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _ReportCard(
                value: '$totalGames',
                label: isTR ? 'Bu hafta oyun' : 'Games this week',
              ),
              const SizedBox(width: 10),
              _ReportCard(
                value: '$bestScore',
                label: isTR ? 'En iyi skor' : 'Best score',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StreamBuilder<Map<String, dynamic>?>(
                stream: FirebaseService.watchTodayMood(provider.selectedPatientId),
                builder: (context, snapshot) {
                  final mood = snapshot.data?['mood'] as String? ?? '';

                  return _ReportCard(
                    value: _moodEmoji(mood),
                    label: isTR ? 'Son ruh hali' : 'Latest mood',
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
                  final hasTakenMedicine = takenMap.values.any((taken) => taken);

                  return _ReportCard(
                    value: hasTakenMedicine ? '✅' : '❌',
                    label: isTR ? 'İlaç durumu' : 'Medicine status',
                    isEmoji: true,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            isTR ? 'Son Aktiviteler' : 'Recent Activities',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (weekScores.isEmpty)
            _EmptyState(
              text: isTR
                  ? 'Bu hafta henüz oyun tamamlanmadı.'
                  : 'No games completed this week yet.',
            )
          else
            ...weekScores.take(10).map((score) {
              final game = (score['game'] as String?) ?? 'game';
              final points = (score['score'] as int?) ?? 0;
              final date = DateTime.tryParse(
                (score['date'] as String?) ?? '',
              );

              return _ActivityRow(
                title: _gameName(game, isTR),
                subtitle: date == null
                    ? ''
                    : '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                value: '$points',
              );
            }),
        ],
      ),
    );
  }

  String _gameName(String game, bool isTR) {
    switch (game) {
      case 'puzzle':
        return 'Puzzle';
      case 'card_match':
        return isTR ? 'Kart Eşleştirme' : 'Card Matching';
      case 'number_sequence':
        return isTR ? 'Sayı Dizisi' : 'Number Sequence';
      case 'face_name':
        return isTR ? 'Yüz & İsim' : 'Face & Name';
      case 'clock':
        return isTR ? 'Saat Çizme' : 'Clock Drawing';
      case 'word_recall':
        return isTR ? 'Kelime Hatırlama' : 'Word Recall';
      default:
        return game;
    }
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
}

class _ReportCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isEmoji;

  const _ReportCard({
    required this.value,
    required this.label,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFFBA7517),
                fontSize: isEmoji ? 28 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF633806),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}