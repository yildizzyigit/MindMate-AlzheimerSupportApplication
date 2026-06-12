import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:async';
import 'dart:math';

class WordRecallScreen extends StatefulWidget {
  const WordRecallScreen({super.key});

  @override
  State<WordRecallScreen> createState() => _WordRecallScreenState();
}

class _WordRecallScreenState extends State<WordRecallScreen> {
  final List<List<String>> _wordSetsTR = [
    ['Elma', 'Masa', 'Köpek', 'Araba', 'Kitap'],
    ['Çiçek', 'Pencere', 'Kedi', 'Kalem', 'Ekmek'],
    ['Güneş', 'Sandalye', 'Kuş', 'Telefon', 'Su'],
    ['Ay', 'Kapı', 'Balık', 'Saat', 'Ağaç'],
    ['Meyve', 'Bulut', 'Bebek', 'Çanta', 'Deniz'],
    ['Dağ', 'Kelebek', 'Şapka', 'Yıldız', 'Köy'],
    ['Balon', 'Portakal', 'Bisiklet', 'Gözlük', 'Yağmur'],
    ['Aslan', 'Çorap', 'Tren', 'Mum', 'Nehir'],
  ];

  final List<List<String>> _wordSetsEN = [
    ['Apple', 'Table', 'Dog', 'Car', 'Book'],
    ['Flower', 'Window', 'Cat', 'Pen', 'Bread'],
    ['Sun', 'Chair', 'Bird', 'Phone', 'Water'],
    ['Moon', 'Door', 'Fish', 'Clock', 'Tree'],
    ['Fruit', 'Cloud', 'Baby', 'Bag', 'Sea'],
    ['Mountain', 'Butterfly', 'Hat', 'Star', 'Village'],
    ['Balloon', 'Orange', 'Bicycle', 'Glasses', 'Rain'],
    ['Lion', 'Sock', 'Train', 'Candle', 'River'],
  ];

  List<String> _words = [];
  List<String> _options = [];
  List<String> _selectedWords = [];
  bool _showingWords = true;
  int _timeLeft = 10;
  int _score = 0;
  int _round = 0;
  bool _gameOver = false;
  bool _showResult = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    final isTR = context.read<AppProvider>().language == 'TR';
    final sets = isTR ? _wordSetsTR : _wordSetsEN;
    final random = Random();
    final setIndex = random.nextInt(sets.length);
    _words = sets[setIndex];

    // Seçenekler: doğru kelimeler + 3 tuzak
    final allWords = sets.expand((s) => s).toList();
    final distractors = allWords.where((w) => !_words.contains(w)).toList()..shuffle();
    _options = [..._words, ...distractors.take(3)]..shuffle();

    setState(() {
      _selectedWords = [];
      _showingWords = true;
      _showResult = false;
      _timeLeft = 10;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        t.cancel();
        setState(() => _showingWords = false);
      }
    });
  }

  void _onWordTap(String word) {
    if (_showingWords || _showResult) return;
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else {
        _selectedWords.add(word);
      }
    });
  }

  void _checkAnswers() {
    _timer?.cancel();
    int correct = _selectedWords.where((w) => _words.contains(w)).length;
    int wrong = _selectedWords.where((w) => !_words.contains(w)).length;
    int points = (correct * 10) - (wrong * 5);
    if (points < 0) points = 0;

    setState(() {
      _score += points;
      _showResult = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _round++;
      if (_round >= 3) {
        setState(() => _gameOver = true);
        context.read<AppProvider>().saveGameScore('word_recall', _score);
        _showGameOverDialog();
      } else {
        _startRound();
      }
    });
  }

  void _showGameOverDialog() {
    final isTR = context.read<AppProvider>().language == 'TR';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTR ? '🎉 Tebrikler!' : '🎉 Well Done!',
            textAlign: TextAlign.center),
        content: Text(
          isTR ? 'Toplam Skor: $_score' : 'Total Score: $_score',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _round = 0;
                _gameOver = false;
              });
              _startRound();
            },
            child: Text(isTR ? 'Tekrar Oyna' : 'Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(isTR ? 'Ana Sayfa' : 'Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F77DD),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Kelime Hatırlama' : 'Word Recall'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF7F77DD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Badge(label: isTR ? 'Tur' : 'Round', value: '${_round + 1}/3'),
                _Badge(label: isTR ? 'Skor' : 'Score', value: '$_score'),
                _Badge(
                  label: _showingWords ? (isTR ? 'Süre' : 'Time') : '',
                  value: _showingWords ? '$_timeLeft' : '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
              child: _showingWords
                  ? Column(
                children: [
                  Text(
                    isTR ? '🧠 Bu kelimeleri ezberle!' : '🧠 Memorize these words!',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F77DD)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _words.map((w) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDFE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7F77DD), width: 1.5),
                      ),
                      child: Text(w, style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4699))),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isTR ? '$_timeLeft saniye' : '$_timeLeft seconds',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              )
                  : Column(
                children: [
                  Text(
                    isTR
                        ? '📝 Gördüğün kelimeleri seç!'
                        : '📝 Select the words you saw!',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F77DD)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _options.map((w) {
                      final isSelected = _selectedWords.contains(w);
                      final isCorrect = _showResult && _words.contains(w);
                      final isWrong = _showResult && isSelected && !_words.contains(w);

                      return GestureDetector(
                        onTap: () => _onWordTap(w),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? const Color(0xFFE1F5EE)
                                : isWrong
                                ? const Color(0xFFFAECE7)
                                : isSelected
                                ? const Color(0xFFEEEDFE)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCorrect
                                  ? const Color(0xFF1D9E75)
                                  : isWrong
                                  ? const Color(0xFFD85A30)
                                  : isSelected
                                  ? const Color(0xFF7F77DD)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Text(w,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isCorrect
                                      ? const Color(0xFF1D9E75)
                                      : isWrong
                                      ? const Color(0xFFD85A30)
                                      : isSelected
                                      ? const Color(0xFF4A4699)
                                      : Colors.grey.shade600)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (!_showingWords && !_showResult)
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _checkAnswers,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F77DD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isTR ? '✓ Cevapları Kontrol Et' : '✓ Check Answers',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  const _Badge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}