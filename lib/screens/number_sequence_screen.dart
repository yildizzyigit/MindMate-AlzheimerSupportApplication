import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:async';
import 'dart:math';

class NumberSequenceScreen extends StatefulWidget {
  const NumberSequenceScreen({super.key});

  @override
  State<NumberSequenceScreen> createState() => _NumberSequenceScreenState();
}

class _NumberSequenceScreenState extends State<NumberSequenceScreen> {
  List<int> _sequence = [];
  List<int> _userInput = [];
  bool _showingSequence = false;
  bool _userTurn = false;
  int _level = 1;
  int _score = 0;
  int _highlightIndex = -1;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    final random = Random();
    _sequence = List.generate(_level + 2, (_) => random.nextInt(9) + 1);
    _userInput = [];
    _showingSequence = true;
    _userTurn = false;
    _highlightIndex = -1;
    _showSequence();
  }

  void _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _highlightIndex = i);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _highlightIndex = -1);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    setState(() {
      _showingSequence = false;
      _userTurn = true;
    });
  }

  void _onNumberTap(int number) {
    if (!_userTurn || _gameOver) return;
    setState(() => _userInput.add(number));

    final idx = _userInput.length - 1;
    if (_userInput[idx] != _sequence[idx]) {
      setState(() => _gameOver = true);
      context.read<AppProvider>().saveGameScore('number_sequence', _score);
      _showGameOverDialog();
      return;
    }

    if (_userInput.length == _sequence.length) {
      setState(() {
        _score += _level * 10;
        _level++;
        _userTurn = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _startNewRound();
      });
    }
  }

  void _showGameOverDialog() {
    final isTR = context.read<AppProvider>().language == 'TR';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTR ? '🎮 Oyun Bitti!' : '🎮 Game Over!',
            textAlign: TextAlign.center),
        content: Text(
          isTR
              ? 'Seviye: $_level\nSkorun: $_score'
              : 'Level: $_level\nScore: $_score',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _level = 1;
                _score = 0;
                _gameOver = false;
              });
              _startNewRound();
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
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF378ADD),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Sayı Dizisi' : 'Number Sequence'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF378ADD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Badge(label: isTR ? 'Seviye' : 'Level', value: '$_level'),
                _Badge(label: isTR ? 'Skor' : 'Score', value: '$_score'),
                _Badge(
                  label: isTR ? 'Durum' : 'Status',
                  value: _showingSequence
                      ? (isTR ? 'İzle' : 'Watch')
                      : (isTR ? 'Gir' : 'Input'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Dizi gösterimi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text(
                    _showingSequence
                        ? (isTR ? 'Diziyi ezberle!' : 'Memorize the sequence!')
                        : (isTR ? 'Şimdi sırayla gir:' : 'Now enter in order:'),
                    style: TextStyle(
                      fontSize: 14,
                      color: _showingSequence ? const Color(0xFF378ADD) : const Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_sequence.length, (i) {
                      final isHighlighted = i == _highlightIndex;
                      final isEntered = !_showingSequence && i < _userInput.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? const Color(0xFF378ADD)
                              : isEntered
                              ? const Color(0xFF1D9E75)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            isHighlighted
                                ? '${_sequence[i]}'
                                : isEntered
                                ? '${_userInput[i]}'
                                : '?',
                            style: TextStyle(
                              color: (isHighlighted || isEntered) ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Sayı tuşları
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  return GestureDetector(
                    onTap: () => _onNumberTap(number),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _userTurn ? const Color(0xFF378ADD) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _userTurn
                            ? [BoxShadow(color: const Color(0xFF378ADD).withOpacity(0.3), blurRadius: 8)]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: _userTurn ? Colors.white : Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}