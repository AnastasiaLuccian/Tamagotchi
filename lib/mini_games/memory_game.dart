import 'dart:async';
import 'package:flutter/material.dart';

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  final List<IconData> _icons = [
    Icons.apple, Icons.android, Icons.star, Icons.cake,
    Icons.audiotrack, Icons.anchor, Icons.ac_unit, Icons.favorite,
  ];

  late List<IconData> _gameIcons;
  List<bool> _isFlipped = [];
  int _previousIndex = -1;
  bool _isLocked = false;
  int _matchesFound = 0;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _gameIcons = List.from(_icons)..addAll(_icons);
    _gameIcons.shuffle();
    _isFlipped = List.generate(_gameIcons.length, (index) => false);
    _previousIndex = -1;
    _isLocked = false;
    _matchesFound = 0;
    _moves = 0;
    setState(() {});
  }

  void _onCardTap(int index) {
    if (_isFlipped[index] || _isLocked) return;

    setState(() {
      _isFlipped[index] = true;
      _moves++;
    });

    if (_previousIndex == -1) {
      _previousIndex = index;
    } else {
      _isLocked = true;
      if (_gameIcons[index] == _gameIcons[_previousIndex]) {
        _matchesFound++;
        _isLocked = false;
        _previousIndex = -1;
      } else {
        final int tempPreviousIndex = _previousIndex;
        Timer(const Duration(seconds: 1), () {
          setState(() {
            _isFlipped[index] = false;
            _isFlipped[tempPreviousIndex] = false;
            _isLocked = false;
          });
        });
        _previousIndex = -1;
      }
    }

    if (_matchesFound == _icons.length) {
      Timer(const Duration(seconds: 1), () {
        Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🌈 Мемори Игра",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        backgroundColor: const Color(0xFFF8BBD9),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE1BEE7),
              Color(0xFFB3E5FC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple[100]!,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "🎯 Ходы: $_moves",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                  Text(
                    "⭐ Найдено: $_matchesFound/${_icons.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _gameIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _isFlipped[index]
                            ? Colors.white
                            : const Color(0xFF80DEEA),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _isFlipped[index]
                                ? const Color(0xFFCE93D8)
                                : const Color(0xFF81C784),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: _isFlipped[index]
                          ? Center(
                        child: Icon(
                          _gameIcons[index],
                          size: 30,
                          color: const Color(0xFF7B1FA2),
                        ),
                      )
                          : const Center(
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startGame,
        backgroundColor: const Color(0xFFF48FB1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}