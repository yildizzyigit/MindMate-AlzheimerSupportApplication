import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:math';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  double _hourAngle = 0;
  double _minuteAngle = 0;
  int _score = 0;
  int _round = 0;
  int _targetHour = 3;
  int _targetMinute = 0;
  bool _checked = false;
  bool _correct = false;


  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  void _loadRound() {
    final random = Random();
    final hour = random.nextInt(12) + 1;
    final minuteOptions = [0, 15, 30, 45];
    final minute = minuteOptions[random.nextInt(4)];

    setState(() {
      _targetHour = hour;
      _targetMinute = minute;
      _hourAngle = 0;
      _minuteAngle = 0;
      _checked = false;
      _correct = false;
    });
  }

  String _targetTimeString() {
    final h = _targetHour.toString().padLeft(2, '0');
    final m = _targetMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _checkAnswer() {
    final targetMinuteAngle = (_targetMinute / 60) * 2 * pi;
    final targetHourAngle = ((_targetHour % 12) / 12) * 2 * pi +
        (_targetMinute / 60) * (2 * pi / 12);

    double hourDiff = (_hourAngle - targetHourAngle).abs();
    if (hourDiff > pi) hourDiff = 2 * pi - hourDiff;

    double minuteDiff = (_minuteAngle - targetMinuteAngle).abs();
    if (minuteDiff > pi) minuteDiff = 2 * pi - minuteDiff;

    final tolerance = pi / 4;
    final isCorrect = hourDiff < tolerance && minuteDiff < tolerance;

    setState(() {
      _checked = true;
      _correct = isCorrect;
      if (isCorrect) _score += 20;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _round++;
      if (_round >= 5) {
        context.read<AppProvider>().saveGameScore('clock', _score);
        _showResultDialog();
      } else {
        _loadRound();
      }
    });
  }

  void _showResultDialog() {
    final isTR = context.read<AppProvider>().language == 'TR';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTR ? '🕐 Oyun Bitti!' : '🕐 Game Over!',
            textAlign: TextAlign.center),
        content: Text(
          isTR ? 'Skorun: $_score' : 'Score: $_score',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _round = 0; _score = 0; });
              _loadRound();
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
    final size = MediaQuery.of(context).size;
    final clockSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD85A30),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Saat Çizme' : 'Clock Drawing'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFD85A30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('${_round + 1}/5',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(isTR ? 'Tur' : 'Round',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
                Column(children: [
                  Text('$_score',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(isTR ? 'Skor' : 'Score',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isTR ? 'Saati göster: ${_targetTimeString()}' : 'Show the time: ${_targetTimeString()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isTR ? 'Butonlarla kolları ayarla' : 'Use buttons to set the hands',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: clockSize,
              height: clockSize,
              child: CustomPaint(
                painter: _ClockPainter(
                  hourAngle: _hourAngle,
                  minuteAngle: _minuteAngle,
                  checked: _checked,
                  correct: _correct,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(isTR ? 'Akrep' : 'Hour',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _hourAngle -= pi / 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => setState(() => _hourAngle += pi / 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(isTR ? 'Yelkovan' : 'Minute',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _minuteAngle -= pi / 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD85A30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => setState(() => _minuteAngle += pi / 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD85A30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!_checked)
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: _checkAnswer,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD85A30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isTR ? '✓ Kontrol Et' : '✓ Check',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          if (_checked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                _correct
                    ? (isTR ? '✅ Doğru!' : '✅ Correct!')
                    : (isTR ? '❌ Yanlış, devam ediliyor...' : '❌ Wrong, continuing...'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _correct ? const Color(0xFF1D9E75) : const Color(0xFFD85A30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double hourAngle;
  final double minuteAngle;
  final bool checked;
  final bool correct;

  _ClockPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.checked,
    required this.correct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius, Paint()
      ..color = checked
          ? (correct ? const Color(0xFF1D9E75) : const Color(0xFFD85A30))
          : const Color(0xFFD85A30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);

    final tickPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi - pi / 2;
      canvas.drawLine(
        Offset(center.dx + radius * 0.78 * cos(angle), center.dy + radius * 0.78 * sin(angle)),
        Offset(center.dx + radius * 0.9 * cos(angle), center.dy + radius * 0.9 * sin(angle)),
        tickPaint,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final angle = (i / 12) * 2 * pi - pi / 2;
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(color: Colors.grey.shade700, fontSize: size.width * 0.07, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      final pos = Offset(
        center.dx + radius * 0.63 * cos(angle) - textPainter.width / 2,
        center.dy + radius * 0.63 * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, pos);
    }

    // Akrep
    canvas.drawLine(center,
        Offset(center.dx + radius * 0.5 * sin(hourAngle), center.dy - radius * 0.5 * cos(hourAngle)),
        Paint()..color = const Color(0xFF1a1a1a)..strokeWidth = 8..strokeCap = StrokeCap.round);

    // Yelkovan
    canvas.drawLine(center,
        Offset(center.dx + radius * 0.75 * sin(minuteAngle), center.dy - radius * 0.75 * cos(minuteAngle)),
        Paint()..color = const Color(0xFFD85A30)..strokeWidth = 5..strokeCap = StrokeCap.round);

    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF1a1a1a));
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFD85A30));
  }

  @override
  bool shouldRepaint(_ClockPainter old) => true;
}