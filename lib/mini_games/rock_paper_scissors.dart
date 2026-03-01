import 'dart:math';
import 'package:flutter/material.dart';

enum Choice { rock, paper, scissors }
enum GameResult { win, lose, draw }

class RockPaperScissorsGame extends StatefulWidget {
  const RockPaperScissorsGame({super.key});

  @override
  State<RockPaperScissorsGame> createState() => _RockPaperScissorsGameState();
}

class _RockPaperScissorsGameState extends State<RockPaperScissorsGame> with SingleTickerProviderStateMixin {
  Choice? playerChoice;
  Choice? computerChoice;
  GameResult? result;
  int playerScore = 0;
  int computerScore = 0;
  int round = 1;
  final Random random = Random();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final Map<Choice, Map<String, dynamic>> choiceData = {
    Choice.rock: {
      'icon': Icons.diamond,
      'color': Color(0xFF4FC3F7),
      'gradient': [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
      'name': 'Камень',
      'emoji': '🪨',
    },
    Choice.paper: {
      'icon': Icons.description,
      'color': Color(0xFF81C784),
      'gradient': [Color(0xFF81C784), Color(0xFF66BB6A)],
      'name': 'Бумага',
      'emoji': '📄',
    },
    Choice.scissors: {
      'icon': Icons.content_cut,
      'color': Color(0xFFFF8A65),
      'gradient': [Color(0xFFFF8A65), Color(0xFFFF7043)],
      'name': 'Ножницы',
      'emoji': '✂️',
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _playRound(Choice player) async {
    if (playerChoice != null) return;

    setState(() {
      playerChoice = player;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final computer = Choice.values[random.nextInt(3)];
    setState(() {
      computerChoice = computer;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final GameResult roundResult = _calculateResult(player, computer);
    setState(() {
      result = roundResult;
      if (roundResult == GameResult.win) playerScore++;
      if (roundResult == GameResult.lose) computerScore++;
      round++;
    });

    _animationController.forward(from: 0);

    await Future.delayed(const Duration(seconds: 1));

    if (round <= 5) {
      setState(() {
        playerChoice = null;
        computerChoice = null;
        result = null;
      });
    }
  }

  GameResult _calculateResult(Choice player, Choice computer) {
    if (player == computer) return GameResult.draw;

    if ((player == Choice.rock && computer == Choice.scissors) ||
        (player == Choice.paper && computer == Choice.rock) ||
        (player == Choice.scissors && computer == Choice.paper)) {
      return GameResult.win;
    }

    return GameResult.lose;
  }

  String _getResultText() {
    if (result == null) return "Выберите ваш ход!";
    switch (result!) {
      case GameResult.win:
        return "Победа! 🎉";
      case GameResult.lose:
        return "Поражение 😢";
      case GameResult.draw:
        return "Ничья! 🤝";
    }
  }

  Color _getResultColor() {
    if (result == null) return Colors.white;
    switch (result!) {
      case GameResult.win:
        return Colors.green[300]!;
      case GameResult.lose:
        return Colors.red[300]!;
      case GameResult.draw:
        return Colors.yellow[300]!;
    }
  }

  Widget _buildChoiceCard(Choice choice, bool isPlayer) {
    final data = choiceData[choice]!;
    final bool isSelected = (isPlayer && playerChoice == choice) || (!isPlayer && computerChoice == choice);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: data['color'].withValues(alpha: 0.8),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isSelected ? 0.8 : 0.3),
          width: isSelected ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data['emoji'],
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            data['name'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(Choice choice) {
    final data = choiceData[choice]!;

    return GestureDetector(
      onTap: playerChoice == null ? () => _playRound(choice) : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: data['gradient'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: data['color'].withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          data['icon'] as IconData,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, playerScore * 10),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Раунд $round/5",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$playerScore : $computerScore",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "ВЫ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (playerChoice != null)
                          _buildChoiceCard(playerChoice!, true)
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),

                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: result == null
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : _getResultColor().withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: result == null
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : _getResultColor(),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    result == null ? "VS" : _getResultText(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: result == null ? Colors.white : _getResultColor(),
                                    ),
                                  ),
                                  if (result != null)
                                    Text(
                                      "${choiceData[playerChoice]!['name']} vs ${choiceData[computerChoice]!['name']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    Column(
                      children: [
                        if (computerChoice != null)
                          _buildChoiceCard(computerChoice!, false)
                        else
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.computer,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          "КОМПЬЮТЕР",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChoiceButton(Choice.rock),
                    _buildChoiceButton(Choice.paper),
                    _buildChoiceButton(Choice.scissors),
                  ],
                ),
              ),

              if (round > 5)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        playerScore > computerScore
                            ? "🎉 Вы победили!"
                            : playerScore < computerScore
                            ? "😢 Вы проиграли"
                            : "🤝 Ничья!",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Итоговый счёт: $playerScore : $computerScore",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, playerScore * 10),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 10,
                        ),
                        child: const Text(
                          "Забрать награду",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}