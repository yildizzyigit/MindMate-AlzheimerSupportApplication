import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:async';

class CardMatchScreen extends StatefulWidget {
  const CardMatchScreen({super.key});

  @override
  State<CardMatchScreen> createState() => _CardMatchScreenState();
}

class _CardMatchScreenState extends State<CardMatchScreen> {
  final List<String> _emojis = ['🌸', '⭐', '🎵', '🌈', '🍎', '🐶'];
  late List<String> _cards;
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _firstIndex;
  bool _canFlip = true;
  int _score = 0;
  int _moves = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _cards = [..._emojis, ..._emojis]..shuffle();
    _flipped = List.filled(12, false);
    _matched = List.filled(12, false);
    _firstIndex = null;
    _canFlip = true;
    _score = 0;
    _moves = 0;
    _gameOver = false;
  }

  void _onCardTap(int index) {
    if (!_canFlip || _flipped[index] || _matched[index]) return;

    setState(() {
      _flipped[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _moves++;
      _canFlip = false;

      if (_cards[_firstIndex!] == _cards[index]) {
        setState(() {
          _matched[_firstIndex!] = true;
          _matched[index] = true;
          _score += 10;
          _firstIndex = null;
          _canFlip = true;
        });

        if (_matched.every((m) => m)) {
          setState(() => _gameOver = true);
          context.read<AppProvider>().saveGameScore('card_match', _score);
          _showWinDialog();
        }
      } else {
        Timer(const Duration(milliseconds: 800), () {
          setState(() {
            _flipped[_firstIndex!] = false;
            _flipped[index] = false;
            _firstIndex = null;
            _canFlip = true;
          });
        });
      }
    }
  }

  void _showWinDialog() {
    final isTR = context.read<AppProvider>().language == 'TR';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTR ? '🎉 Tebrikler!' : '🎉 Congratulations!',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTR ? 'Skorun: $_score\nHamle: $_moves' : 'Score: $_score\nMoves: $_moves',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initGame());
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
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Kart Eşleştirme' : 'Card Matching'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Skor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF1D9E75),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ScoreBadge(
                  label: isTR ? 'Skor' : 'Score',
                  value: '$_score',
                ),
                _ScoreBadge(
                  label: isTR ? 'Hamle' : 'Moves',
                  value: '$_moves',
                ),
                _ScoreBadge(
                  label: isTR ? 'Eşleşen' : 'Matched',
                  value: '${_matched.where((m) => m).length ~/ 2}/6',
                ),
              ],
            ),
          ),
          // Kartlar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _matched[index]
                            ? const Color(0xFFE1F5EE)
                            : _flipped[index]
                            ? Colors.white
                            : const Color(0xFF1D9E75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _matched[index]
                              ? const Color(0xFF1D9E75)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _flipped[index] || _matched[index]
                              ? _cards[index]
                              : '❓',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Yeniden başlat
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => setState(() => _initGame()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isTR ? '🔄 Yeniden Başlat' : '🔄 Restart',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}