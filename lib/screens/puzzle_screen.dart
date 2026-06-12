import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'dart:math';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const int size = 3;
  static const double boardPadding = 8;
  static const double tileGap = 6;

  static const List<String> imagePaths = [
    'assets/images/puzzle1.jpg',
    'assets/images/puzzle2.jpg',
  ];

  late List<int> _tiles;
  late String _currentImagePath;

  int _moves = 0;
  bool _solved = false;
  bool _isMoving = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initPuzzle();
  }

  void _initPuzzle() {
    final random = Random();

    _currentImagePath = imagePaths[random.nextInt(imagePaths.length)];

    _tiles = List.generate(size * size, (i) {
      if (i == size * size - 1) return 0;
      return i + 1;
    });

    _shuffle();

    _moves = 0;
    _solved = false;
    _isMoving = false;
    _startTime = DateTime.now();
  }

  void _shuffle() {
    final random = Random();

    for (int i = 0; i < 250; i++) {
      final emptyIndex = _tiles.indexOf(0);
      final neighbors = _getNeighbors(emptyIndex);
      final randomNeighbor = neighbors[random.nextInt(neighbors.length)];
      _swap(emptyIndex, randomNeighbor);
    }

    if (_checkSolved()) {
      _shuffle();
    }
  }

  List<int> _getNeighbors(int index) {
    final neighbors = <int>[];
    final row = index ~/ size;
    final col = index % size;

    if (row > 0) neighbors.add(index - size);
    if (row < size - 1) neighbors.add(index + size);
    if (col > 0) neighbors.add(index - 1);
    if (col < size - 1) neighbors.add(index + 1);

    return neighbors;
  }

  void _swap(int a, int b) {
    final temp = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = temp;
  }

  void _tryMoveTile(int index) {
    if (_solved || _isMoving) return;

    final emptyIndex = _tiles.indexOf(0);
    final neighbors = _getNeighbors(emptyIndex);

    if (!neighbors.contains(index)) return;

    _isMoving = true;

    final willBeSolved = (() {
      final testTiles = List<int>.from(_tiles);
      final temp = testTiles[index];
      testTiles[index] = testTiles[emptyIndex];
      testTiles[emptyIndex] = temp;

      for (int i = 0; i < testTiles.length - 1; i++) {
        if (testTiles[i] != i + 1) return false;
      }

      return testTiles.last == 0;
    })();

    setState(() {
      _swap(index, emptyIndex);
      _moves++;
      _solved = willBeSolved;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        _isMoving = false;
      }
    });

    if (willBeSolved) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;

        final seconds = DateTime.now().difference(_startTime!).inSeconds;
        final score = max(0, 300 - _moves * 2 - seconds);

        context.read<AppProvider>().saveGameScore('puzzle', score);
        _showWinDialog(score);
      });
    }
  }

  void _onTileDragUpdate(int index, DragUpdateDetails details) {
    if (_solved || _isMoving) return;

    final emptyIndex = _tiles.indexOf(0);

    final tileRow = index ~/ size;
    final tileCol = index % size;
    final emptyRow = emptyIndex ~/ size;
    final emptyCol = emptyIndex % size;

    final isNeighbor =
        (tileRow == emptyRow && (tileCol - emptyCol).abs() == 1) ||
            (tileCol == emptyCol && (tileRow - emptyRow).abs() == 1);

    if (!isNeighbor) return;

    final dx = details.delta.dx;
    final dy = details.delta.dy;

    if (emptyCol == tileCol + 1 && dx > 0) {
      _tryMoveTile(index);
    } else if (emptyCol == tileCol - 1 && dx < 0) {
      _tryMoveTile(index);
    } else if (emptyRow == tileRow + 1 && dy > 0) {
      _tryMoveTile(index);
    } else if (emptyRow == tileRow - 1 && dy < 0) {
      _tryMoveTile(index);
    }
  }

  bool _checkSolved() {
    for (int i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }

    return _tiles.last == 0;
  }

  void _showWinDialog(int score) {
    final isTR = context.read<AppProvider>().language == 'TR';
    final seconds = DateTime.now().difference(_startTime!).inSeconds;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isTR ? 'Tebrikler!' : 'Congratulations!',
          textAlign: TextAlign.center,
        ),
        content: Text(
          isTR
              ? 'Hamleler: $_moves\nSüre: ${seconds}s\nSkor: $score'
              : 'Moves: $_moves\nTime: ${seconds}s\nScore: $score',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_initPuzzle);
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

  Widget _buildImageTile({
    required int value,
    required int index,
    required double tileSize,
  }) {
    final originalIndex = value - 1;
    final imageRow = originalIndex ~/ size;
    final imageCol = originalIndex % size;

    return GestureDetector(
      onTap: () => _tryMoveTile(index),
      onPanUpdate: (details) => _onTileDragUpdate(index, details),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pieceSize = constraints.maxWidth;
              final fullImageSize = pieceSize * size;

              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: fullImageSize,
                  maxWidth: fullImageSize,
                  minHeight: fullImageSize,
                  maxHeight: fullImageSize,
                  child: Transform.translate(
                    offset: Offset(
                      -imageCol * pieceSize,
                      -imageRow * pieceSize,
                    ),
                    child: Image.asset(
                      _currentImagePath,
                      width: fullImageSize,
                      height: fullImageSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTR = context.watch<AppProvider>().language == 'TR';
    final screenSize = MediaQuery.of(context).size;

    final boardSize = min(screenSize.width - 40, 420.0);
    final gridSize = boardSize - boardPadding * 2;
    final tileSize = (gridSize - tileGap * (size - 1)) / size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F77DD),
        foregroundColor: Colors.white,
        title: const Text('Puzzle'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_initPuzzle),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF7F77DD),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_moves',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isTR ? 'Hamle' : 'Moves',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        isTR ? 'Resmi tamamla' : 'Complete the image',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isTR ? 'Parçaları kaydır' : 'Slide the pieces',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isTR ? 'Önizleme' : 'Preview',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4699),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF7F77DD),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                _currentImagePath,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: boardSize,
                height: boardSize,
                padding: const EdgeInsets.all(boardPadding),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F77DD),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F77DD).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    crossAxisSpacing: tileGap,
                    mainAxisSpacing: tileGap,
                  ),
                  itemCount: size * size,
                  itemBuilder: (context, index) {
                    final value = _tiles[index];

                    if (value == 0) {
                      if (_solved) {
                        return _buildImageTile(
                          value: size * size,
                          index: index,
                          tileSize: tileSize,
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B63CC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }

                    return _buildImageTile(
                      value: value,
                      index: index,
                      tileSize: tileSize,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isTR
                  ? 'Parçayı boş kareye doğru kaydır'
                  : 'Swipe a piece toward the empty space',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}