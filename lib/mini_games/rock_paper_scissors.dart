import 'dart:math';
import 'package:flutter/material.dart';

enum Choice { rock, paper, scissors }
enum Result { win, lose, draw }

class RockPaperScissorsGame extends StatefulWidget {
  const RockPaperScissorsGame({super.key});

  @override
  State<RockPaperScissorsGame> createState() => _RockPaperScissorsGameState();
}

class _RockPaperScissorsGameState extends State<RockPaperScissorsGame> {
  Choice? playerChoice;
  Choice? computerChoice;
  String message = "Выбери свой ход!";
  int playerScore = 0;
  int computerScore = 0;
  final Random random = Random();

  void _playGame(Choice player) {
    setState(() {
      playerChoice = player;
      computerChoice = Choice.values[random.nextInt(3)];
      _checkResult();
    });
  }

  void _checkResult() {
    if (playerChoice == computerChoice) {
      message = "Ничья!";
    } else if ((playerChoice == Choice.rock && computerChoice == Choice.scissors) ||
        (playerChoice == Choice.paper && computerChoice == Choice.rock) ||
        (playerChoice == Choice.scissors && computerChoice == Choice.paper)) {
      message = "Ты победил!";
      playerScore++;
    } else {
      message = "Ты проиграл!";
      computerScore++;
    }
  }

  Widget _buildChoiceButton(Choice choice) {
    return GestureDetector(
      onTap: () => _playGame(choice),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.purple[100]!,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFFE1BEE7), width: 3),
        ),
        child: Icon(
          _getChoiceIcon(choice),
          size: 40,
          color: const Color(0xFF7B1FA2),
        ),
      ),
    );
  }

  Widget _buildChoiceResult(Choice choice, bool isPlayer) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isPlayer ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(
        _getChoiceIcon(choice),
        size: 30,
        color: const Color(0xFF5D4037),
      ),
    );
  }

  IconData _getChoiceIcon(Choice choice) {
    switch (choice) {
      case Choice.rock:
        return Icons.lens;
      case Choice.paper:
        return Icons.description;
      case Choice.scissors:
        return Icons.content_cut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "✨ Камень, Ножницы, Бумага",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        backgroundColor: const Color(0xFF80DEEA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF5D4037)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8BBD9),
              Color(0xFFE1BEE7),
              Color(0xFFC8E6C9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple[100]!,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (playerChoice != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Твой выбор",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.purple[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChoiceResult(playerChoice!, true),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Компьютер",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.purple[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChoiceResult(computerChoice!, false),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChoiceButton(Choice.rock),
                  _buildChoiceButton(Choice.paper),
                  _buildChoiceButton(Choice.scissors),
                ],
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE1BEE7), width: 2),
                ),
                child: Text(
                  "🏆 Счёт: $playerScore - $computerScore",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink[100]!,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, playerScore > computerScore);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE93D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    "🎀 Вернуться",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}