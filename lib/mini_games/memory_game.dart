import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with SingleTickerProviderStateMixin {
  final List<IconData> _icons = [
    Icons.star,
    Icons.favorite,
    Icons.bolt,
    Icons.diamond,
    Icons.cloud,
    Icons.music_note,
    Icons.cake,
    Icons.pets,
  ];

  late List<IconData> _gameIcons;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;
  int _previousIndex = -1;
  bool _isLocked = false;
  int _matchesFound = 0;
  int _moves = 0;
  int _timeLeft = 120;
  Timer? _gameTimer;
  int _score = 0;
  bool _gameCompleted = false;

  final Map<IconData, Color> _iconColors = {
    Icons.star: Color(0xFFFFD700),
    Icons.favorite: Color(0xFFFF6B8B),
    Icons.bolt: Color(0xFFFFC107),
    Icons.diamond: Color(0xFF4FC3F7),
    Icons.cloud: Color(0xFF90A4AE),
    Icons.music_note: Color(0xFF9C27B0),
    Icons.cake: Color(0xFFFF9800),
    Icons.pets: Color(0xFF7B61FF),
  };

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _gameIcons = List.from(_icons)..addAll(_icons);
    _gameIcons.shuffle();
    _isFlipped = List.generate(_gameIcons.length, (index) => false);
    _isMatched = List.generate(_gameIcons.length, (index) => false);
    _previousIndex = -1;
    _isLocked = false;
    _matchesFound = 0;
    _moves = 0;
    _timeLeft = 120;
    _score = 0;
    _gameCompleted = false;

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _gameTimer?.cancel();
        }
      });
    });

    setState(() {});
  }

  Future<void> _onCardTap(int index) async {
    if (_isFlipped[index] || _isMatched[index] || _isLocked || _gameCompleted) return;

    // переворот карточки
    setState(() {
      _isFlipped[index] = true;
      _moves++;
    });

    if (_previousIndex == -1) {
      // Первая карточка
      _previousIndex = index;
    } else {
      // Вторая карточка – блокируем
      _isLocked = true;

      if (_gameIcons[index] == _gameIcons[_previousIndex]) {
        // Совпадение
        _matchesFound++;
        _score += 100 + max(0, 120 - _timeLeft);

        setState(() {
          _isMatched[index] = true;
          _isMatched[_previousIndex] = true;
        });

        if (_matchesFound == _icons.length) {
          _gameCompleted = true;
          _gameTimer?.cancel();
          _score += _timeLeft * 10;
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context, _score ~/ 100);
          });
        }

        _previousIndex = -1;
        _isLocked = false;
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          setState(() {
            _isFlipped[index] = false;
            _isFlipped[_previousIndex] = false;
          });
        }

        _previousIndex = -1;
        _isLocked = false;
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, _score ~/ 100),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: _timeLeft < 30 ? Colors.red[300] : Colors.white),
                          const SizedBox(width: 8),
                          Text(_formatTime(_timeLeft), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _timeLeft < 30 ? Colors.red[300] : Colors.white)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC107)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
                      ),
                      child: Text("$_score", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [Text("$_moves", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const Text("Ходы", style: TextStyle(fontSize: 12, color: Colors.white70))]),
                    Column(children: [Text("$_matchesFound/${_icons.length}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const Text("Найдено", style: TextStyle(fontSize: 12, color: Colors.white70))]),
                    Column(children: [Text("${_icons.length - _matchesFound}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const Text("Осталось", style: TextStyle(fontSize: 12, color: Colors.white70))]),
                  ],
                ),
              ),


              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: _gameIcons.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_isFlipped[index] ? 3.14159 : 0),
                          transformAlignment: Alignment.center,
                          child: _buildCard(index, _isFlipped[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Game over message и time warning
              if (_gameCompleted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      const Text("🎉 Уровень пройден!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text("Счёт: $_score | Время: ${_formatTime(120 - _timeLeft)}", style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, _score ~/ 100),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Забрать награду", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              if (_timeLeft <= 30 && !_gameCompleted)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.red[300], size: 16),
                      const SizedBox(width: 8),
                      Text("Время заканчивается!", style: TextStyle(color: Colors.red[300], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startGame,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4776E6),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildCard(int index, bool isFlipped) {
    if (isFlipped) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_iconColors[_gameIcons[index]]!.withValues(alpha: 0.9), _iconColors[_gameIcons[index]]!.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _iconColors[_gameIcons[index]]!.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)],
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Center(child: Icon(_gameIcons[index], color: Colors.white, size: 32)),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0.9), Colors.grey[200]!.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        ),
        child: Center(child: Icon(Icons.question_mark, color: const Color(0xFF4776E6).withValues(alpha: 0.7), size: 32)),
      );
    }
  }
}