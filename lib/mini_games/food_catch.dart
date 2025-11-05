import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum FoodType { good, bad, energy }

class FoodItem {
  final String id;
  double x;
  double y;
  FoodType type;

  FoodItem({required this.x, required this.y, required this.type}) : id = const Uuid().v4();
}

class FoodCatchGame extends StatefulWidget {
  const FoodCatchGame({super.key});

  @override
  State<FoodCatchGame> createState() => _FoodCatchGameState();
}

class _FoodCatchGameState extends State<FoodCatchGame> {
  double catX = 0;
  List<FoodItem> fallingFood = [];
  int score = 0;
  Timer? gameTimer;
  final Random random = Random();
  double fallSpeed = 0.02;
  double catSpeedMultiplier = 1.0;
  Timer? boostTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        fallSpeed = 0.02 + (score ~/ 10) * 0.005;

        final double badFoodChance = 0.2 + (score ~/ 20) * 0.05;
        final double energyDrinkChance = 0.05;

        if (random.nextDouble() < 0.25) {
          final double randomType = random.nextDouble();
          FoodType newType;
          if (randomType < badFoodChance) {
            newType = FoodType.bad;
          } else if (randomType < badFoodChance + energyDrinkChance) {
            newType = FoodType.energy;
          } else {
            newType = FoodType.good;
          }

          fallingFood.add(FoodItem(
            x: random.nextDouble() * 2 - 1,
            y: -0.2,
            type: newType,
          ));
        }

        final List<String> toRemoveIds = [];
        for (var food in fallingFood) {
          food.y += fallSpeed;

          if ((food.y > 0.85) && (food.x - catX).abs() < 0.2) {
            if (food.type == FoodType.good) {
              score++;
            } else if (food.type == FoodType.bad) {
              score = (score - 3).clamp(0, 100);
            } else if (food.type == FoodType.energy) {
              _activateSpeedBoost();
            }
            toRemoveIds.add(food.id);
          }
          if (food.y > 1.2) {
            toRemoveIds.add(food.id);
          }
        }
        fallingFood.removeWhere((food) => toRemoveIds.contains(food.id));
      });
    });
  }

  void _activateSpeedBoost() {
    setState(() {
      catSpeedMultiplier = 2.0;
    });
    boostTimer?.cancel();
    boostTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        catSpeedMultiplier = 1.0;
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    boostTimer?.cancel();
    super.dispose();
  }

  void _moveCat(double globalX) {
    final screenWidth = MediaQuery.of(context).size.width;
    final relativeX = (globalX / screenWidth) * 2 - 1;
    setState(() {
      catX = (catX + (relativeX - catX) * 0.15 * catSpeedMultiplier).clamp(-1.0, 1.0);
    });
  }

  Widget _buildCloud() {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(Icons.cloud, color: Colors.blueGrey[100], size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => _moveCat(details.globalPosition.dx),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8BBD9),
                    Color(0xFFB3E5FC),
                    Color(0xFFC8E6C9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            Positioned(
              top: 100,
              left: 50,
              child: _buildCloud(),
            ),
            Positioned(
              top: 200,
              right: 70,
              child: _buildCloud(),
            ),
            Positioned(
              bottom: 150,
              left: 100,
              child: _buildCloud(),
            ),

            ...fallingFood.map((food) {
              return AnimatedPositioned(
                key: ValueKey(food.id),
                duration: const Duration(milliseconds: 100),
                left: (MediaQuery.of(context).size.width / 2) + food.x * 120,
                top: MediaQuery.of(context).size.height * food.y,
                child: _getFoodIcon(food.type),
              );
            }).toList(),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              bottom: 60,
              left: (MediaQuery.of(context).size.width / 2) + catX * 120,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCCBC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink[100]!,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.pets, size: 50, color: Color(0xFF795548)),
              ),
            ),

            Positioned(
              top: 60,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple[100]!,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE1BEE7), width: 2),
                ),
                child: Text(
                  "🍎 Очки: $score",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 60,
              right: 20,
              child: Container(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48FB1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context, score > 5);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.exit_to_app, size: 18),
                      SizedBox(width: 6),
                      Text("Выйти"),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget _getFoodIcon(FoodType type) {
  switch (type) {
    case FoodType.good:
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFC8E6C9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green[100]!,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.favorite, size: 28, color: Color(0xFF388E3C)),
      );
    case FoodType.bad:
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFCDD2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red[100]!,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.mood_bad, size: 28, color: Color(0xFFD32F2F)),
      );
    case FoodType.energy:
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow[100]!,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.bolt, size: 28, color: Color(0xFFF57C00)),
      );
  }
}