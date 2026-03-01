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
  double size;

  FoodItem({
    required this.x,
    required this.y,
    required this.type,
    this.size = 1.0,
  }) : id = const Uuid().v4();
}

class FoodCatchGame extends StatefulWidget {
  const FoodCatchGame({super.key});

  @override
  State<FoodCatchGame> createState() => _FoodCatchGameState();
}

class _FoodCatchGameState extends State<FoodCatchGame> with SingleTickerProviderStateMixin {
  double catX = 0;
  List<FoodItem> fallingFood = [];
  int score = 0;
  int lives = 3;
  Timer? gameTimer;
  final Random random = Random();
  double fallSpeed = 1.5;
  double catSpeed = 0.15;
  Timer? boostTimer;
  bool isBoosted = false;
  int combo = 0;
  int highestCombo = 0;

  late AnimationController _catAnimationController;
  late Animation<double> _catBounceAnimation;

  @override
  void initState() {
    super.initState();
    _catAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);

    _catBounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _catAnimationController, curve: Curves.easeInOut),
    );

    _startGame();
  }

  void _startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;

      setState(() {
        fallSpeed = min(1.5 + (score ~/ 20) * 0.3, 3.0);

        // Спавн реже, без зависимости от счёта
        if (random.nextDouble() < 0.02) {
          final double typeRand = random.nextDouble();
          FoodType newType;
          if (typeRand < 0.7) {
            newType = FoodType.good;
          } else if (typeRand < 0.9) {
            newType = FoodType.bad;
          } else {
            newType = FoodType.energy;
          }

          fallingFood.add(FoodItem(
            x: random.nextDouble() * 2 - 1,
            y: -0.2,
            type: newType,
            size: 0.8 + random.nextDouble() * 0.4,
          ));
        }

        final List<String> toRemoveIds = [];
        for (var food in fallingFood) {
          food.y += fallSpeed / 100;

          if (food.y > 0.85) {
            final double distance = (food.x - catX).abs();
            final double catchWidth = 0.25 * (isBoosted ? 1.5 : 1.0);

            if (distance < catchWidth) {
              _onCatch(food);
              toRemoveIds.add(food.id);
            } else if (food.y > 1.2) {
              if (food.type == FoodType.good) {
                lives--;
                combo = 0;
              }
              toRemoveIds.add(food.id);
            }
          }
        }

        fallingFood.removeWhere((food) => toRemoveIds.contains(food.id));

        if (lives <= 0) {
          gameTimer?.cancel();
        }
      });
    });
  }

  void _onCatch(FoodItem food) {
    switch (food.type) {
      case FoodType.good:
        score += 10;
        combo++;
        highestCombo = max(highestCombo, combo);
        _catAnimationController.forward(from: 0);
        break;
      case FoodType.bad:
        lives--;
        combo = 0;
        break;
      case FoodType.energy:
        _activateSpeedBoost();
        score += 5;
        break;
    }
  }

  void _activateSpeedBoost() {
    if (isBoosted) return;

    setState(() {
      isBoosted = true;
      catSpeed = 0.25;
    });

    boostTimer?.cancel();
    boostTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        isBoosted = false;
        catSpeed = 0.15;
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    boostTimer?.cancel();
    _catAnimationController.dispose();
    super.dispose();
  }

  void _moveCat(double globalX) {
    final screenWidth = MediaQuery.of(context).size.width;
    final relativeX = (globalX / screenWidth) * 2 - 1;
    setState(() {
      catX = (catX + (relativeX - catX) * catSpeed).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onPanUpdate: (details) => _moveCat(details.globalPosition.dx),
      child: Scaffold(
        body: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),

                Positioned(
                  top: 60,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Очки: $score", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text("Комбо: $combo", style: TextStyle(fontSize: 16, color: Colors.yellow[300])),
                            const SizedBox(width: 12),
                            Text("Рекорд: $highestCombo", style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Lives
                Positioned(
                  top: 60,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.favorite, color: index < lives ? Colors.red[300] : Colors.grey, size: 24),
                        );
                      }),
                    ),
                  ),
                ),

                ...fallingFood.map((food) {
                  return Positioned(
                    left: screenWidth / 2 + food.x * (screenWidth / 2.5),
                    top: food.y * screenHeight,
                    child: Transform.scale(
                      scale: food.size,
                      child: _FoodWidget(type: food.type),
                    ),
                  );
                }),


                Positioned(
                  bottom: 80,
                  left: screenWidth / 2 + catX * (screenWidth / 2.5) - 40,
                  child: AnimatedBuilder(
                    animation: _catBounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _catBounceAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isBoosted ? [Colors.yellow, Colors.orange] : [const Color(0xFFFF6B8B), const Color(0xFF9D65FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                          BoxShadow(color: (isBoosted ? Colors.yellow : const Color(0xFFFF6B8B)).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 2),
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 40),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 60,
                  left: screenWidth / 2 + catX * (screenWidth / 2.5) - 60,
                  child: Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.3)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                    ),
                  ),
                ),

                if (isBoosted)
                  Positioned(
                    top: 120,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.yellow.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text("УСКОРЕНИЕ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                        ],
                      ),
                    ),
                  ),


                if (lives <= 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)]),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("ИГРА ОКОНЧЕНА", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 24),
                              Text("Ваш счёт: $score", style: const TextStyle(fontSize: 24, color: Colors.white)),
                              Text("Рекорд комбо: $highestCombo", style: const TextStyle(fontSize: 18, color: Colors.white70)),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, score ~/ 10),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text("Забрать награду", style: TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        score = 0;
                                        lives = 3;
                                        combo = 0;
                                        fallingFood.clear();
                                        isBoosted = false;
                                        catSpeed = 0.15;
                                      });
                                      _startGame();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text("Играть снова", style: TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (lives > 0)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context, score ~/ 10),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodWidget extends StatelessWidget {
  final FoodType type;
  const _FoodWidget({required this.type});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late IconData icon;
    late List<Color> gradientColors;

    switch (type) {
      case FoodType.good:
        color = Colors.green;
        icon = Icons.fastfood;
        gradientColors = [Colors.green[300]!, Colors.green[700]!];
        break;
      case FoodType.bad:
        color = Colors.red;
        icon = Icons.warning;
        gradientColors = [Colors.red[300]!, Colors.red[700]!];
        break;
      case FoodType.energy:
        color = Colors.yellow;
        icon = Icons.bolt;
        gradientColors = [Colors.yellow[300]!, Colors.orange[700]!];
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.05)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);
    for (int i = 0; i < 50; i++) {
      final x = (i * 37) % size.width.toInt();
      final y = (i * 23) % size.height.toInt();
      final radius = 1 + (i % 3).toDouble();
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}