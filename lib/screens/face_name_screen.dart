import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../database/db_helper.dart';
import 'people_manager_screen.dart';
import 'dart:io';
import 'dart:math';

class FaceNameScreen extends StatefulWidget {
  const FaceNameScreen({super.key});

  @override
  State<FaceNameScreen> createState() => _FaceNameScreenState();
}

class _FaceNameScreenState extends State<FaceNameScreen> {
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _currentPeople = [];
  List<String> _options = [];
  int _phase = 0; // 0: memorize, 1: quiz
  int _quizIndex = 0;
  int _score = 0;
  int _correct = 0;
  bool _answered = false;
  String _selectedAnswer = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final patientId = context.read<AppProvider>().selectedPatientId;
    final people = await DBHelper.getPeople(patientId: patientId);

    setState(() {
      _people = people;
      _loading = false;
    });

    if (people.length >= 3) _startGame();
  }

  void _startGame() {
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_people)..shuffle(random);
    _currentPeople = shuffled.take(min(5, shuffled.length)).toList();
    setState(() {
      _phase = 0;
      _quizIndex = 0;
      _score = 0;
      _correct = 0;
      _answered = false;
      _selectedAnswer = '';
    });
  }

  void _startQuiz() {
    setState(() => _phase = 1);
    _loadQuestion();
  }

  void _loadQuestion() {
    final random = Random();
    final correct = _currentPeople[_quizIndex]['name'] as String;
    final allNames = _people.map((p) => p['name'] as String).toList();
    final wrong = allNames.where((n) => n != correct).toList()..shuffle(random);
    final options = [correct, ...wrong.take(3)]..shuffle(random);
    setState(() {
      _options = options;
      _answered = false;
      _selectedAnswer = '';
    });
  }

  void _onAnswer(String answer) {
    if (_answered) return;
    final correct = _currentPeople[_quizIndex]['name'] as String;
    final isCorrect = answer == correct;
    setState(() {
      _answered = true;
      _selectedAnswer = answer;
      if (isCorrect) {
        _score += 20;
        _correct++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_quizIndex < _currentPeople.length - 1) {
        setState(() => _quizIndex++);
        _loadQuestion();
      } else {
        context.read<AppProvider>().saveGameScore('face_name', _score);
        _showResultDialog();
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
        title: Text(isTR ? '🎉 Tebrikler!' : '🎉 Well Done!',
            textAlign: TextAlign.center),
        content: Text(
          isTR
              ? '$_correct/${_currentPeople.length} doğru\nSkor: $_score'
              : '$_correct/${_currentPeople.length} correct\nScore: $_score',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
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

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_people.length < 3) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBF0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFBA7517),
          foregroundColor: Colors.white,
          title: Text(isTR ? 'Yüz & İsim' : 'Face & Name'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👥', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  isTR
                      ? 'Bu oyun için en az 3 kişi gerekli.\nBakıcı panelinden kişi ekleyin.'
                      : 'At least 3 people needed.\nAdd people from the caregiver panel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeopleManagerScreen()),
                  ).then((_) => _loadPeople()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA7517),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isTR ? 'Kişi Ekle' : 'Add People',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA7517),
        foregroundColor: Colors.white,
        title: Text(isTR ? 'Yüz & İsim' : 'Face & Name'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _phase == 0 ? _buildMemorize(isTR) : _buildQuiz(isTR),
    );
  }

  Widget _buildMemorize(bool isTR) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFBA7517),
          child: Text(
            isTR ? 'Bu kişileri ve isimlerini ezberle!' : 'Memorize these faces and names!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _currentPeople.length,
            itemBuilder: (context, index) {
              final person = _currentPeople[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.file(
                        File(person['imagePath']),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 70, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      person['name'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _startQuiz,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFBA7517),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isTR ? 'Hazırım! Teste Başla →' : 'Ready! Start Quiz →',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuiz(bool isTR) {
    final person = _currentPeople[_quizIndex];
    final correct = person['name'] as String;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: const Color(0xFFBA7517),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                Text('${_quizIndex + 1}/${_currentPeople.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(isTR ? 'Soru' : 'Question',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              Column(children: [
                Text('$_score',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(isTR ? 'Skor' : 'Score',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              Column(children: [
                Text('$_correct',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(isTR ? 'Doğru' : 'Correct',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.file(
            File(person['imagePath']),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 120, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isTR ? 'Bu kişinin adı ne?' : 'What is this person\'s name?',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: _options.map((option) {
              Color bgColor = Colors.white;
              Color borderColor = Colors.grey.shade300;
              if (_answered) {
                if (option == correct) {
                  bgColor = const Color(0xFFE1F5EE);
                  borderColor = const Color(0xFF1D9E75);
                } else if (option == _selectedAnswer) {
                  bgColor = const Color(0xFFFAECE7);
                  borderColor = const Color(0xFFD85A30);
                }
              }
              return GestureDetector(
                onTap: () => _onAnswer(option),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Center(
                    child: Text(option,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}