import 'dart:async';
import 'package:flutter/material.dart';

class BricksBreakerGame extends StatefulWidget {
  const BricksBreakerGame({super.key});

  @override
  State<BricksBreakerGame> createState() => _BricksBreakerGameState();
}

class _BricksBreakerGameState extends State<BricksBreakerGame>
    with SingleTickerProviderStateMixin {
  static const int rows = 5;
  static const int cols = 6;
  late List<List<bool>> bricks;

  double ballX = 0.5;
  double ballY = 0.8;
  double ballDX = 0.012;
  double ballDY = -0.012;
  double paddleX = 0.5;
  bool gameRunning = true;
  int score = 0;
  Timer? gameTimer;

  final double paddleWidth = 0.2;
  final double ballRadius = 0.02;
  final double brickTop = 0.12;
  final double brickHeight = 0.06;
  final double brickSpacing = 0.005;

  late AnimationController _pulseController;
  bool showGameOver = false;
  bool showVictory = false;

  @override
  void initState() {
    super.initState();
    _resetGame();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  void _resetGame() {
    bricks = List.generate(rows, (_) => List.generate(cols, (_) => true));
    ballX = 0.5;
    ballY = 0.8;
    ballDX = 0.012;
    ballDY = -0.012;
    paddleX = 0.5;
    score = 0;
    gameRunning = true;
    showGameOver = false;
    showVictory = false;
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !gameRunning) return;
      setState(() {
        _updateBall();
      });
    });
  }

  void _updateBall() {
    ballX += ballDX;
    ballY += ballDY;

    // Стены
    if (ballX - ballRadius <= 0) {
      ballX = ballRadius;
      ballDX = ballDX.abs();
    } else if (ballX + ballRadius >= 1) {
      ballX = 1 - ballRadius;
      ballDX = -ballDX.abs();
    }

    if (ballY - ballRadius <= 0) {
      ballY = ballRadius;
      ballDY = ballDY.abs();
    }

    // Платформа
    if (ballY + ballRadius >= 0.95 && ballY - ballRadius <= 1.0) {
      double paddleLeft = paddleX - paddleWidth / 2;
      double paddleRight = paddleX + paddleWidth / 2;
      if (ballX >= paddleLeft && ballX <= paddleRight) {
        ballY = 0.95 - ballRadius;
        ballDY = -ballDY.abs();
        double hitPos = (ballX - paddleX) / (paddleWidth / 2);
        ballDX += hitPos * 0.002;
        ballDX = ballDX.clamp(-0.02, 0.02);
      }
    }

    // Кирпичи
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!bricks[r][c]) continue;
        double brickLeft = c / cols + brickSpacing;
        double brickRight = (c + 1) / cols - brickSpacing;
        double brickTopY = brickTop + r * (brickHeight + brickSpacing);
        double brickBottomY = brickTopY + brickHeight;

        if (ballX + ballRadius > brickLeft &&
            ballX - ballRadius < brickRight &&
            ballY + ballRadius > brickTopY &&
            ballY - ballRadius < brickBottomY) {
          bricks[r][c] = false;
          score += 10;

          double overlapLeft = (ballX + ballRadius) - brickLeft;
          double overlapRight = brickRight - (ballX - ballRadius);
          double overlapTop = (ballY + ballRadius) - brickTopY;
          double overlapBottom = brickBottomY - (ballY - ballRadius);

          double minOverlap = [
            overlapLeft,
            overlapRight,
            overlapTop,
            overlapBottom
          ].reduce((a, b) => a < b ? a : b);

          if (minOverlap == overlapLeft || minOverlap == overlapRight) {
            ballDX = -ballDX;
          } else {
            ballDY = -ballDY;
          }
          break;
        }
      }
    }

    // Проигрыш
    if (ballY + ballRadius > 1.0) {
      gameRunning = false;
      showGameOver = true;
      gameTimer?.cancel();
    }

    // Победа
    bool allBricksGone = bricks.every((row) => row.every((b) => !b));
    if (allBricksGone) {
      gameRunning = false;
      showVictory = true;
      gameTimer?.cancel();
    }
  }

  void _movePaddle(double dx) {
    setState(() {
      paddleX = (paddleX + dx).clamp(paddleWidth / 2, 1 - paddleWidth / 2);
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          double delta = details.delta.dx / screenSize.width;
          _movePaddle(delta);
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Игровое поле (CustomPaint)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BricksPainter(
                      bricks: bricks,
                      ballX: ballX,
                      ballY: ballY,
                      ballRadius: ballRadius,
                      paddleX: paddleX,
                      paddleWidth: paddleWidth,
                      brickTop: brickTop,
                      brickHeight: brickHeight,
                      brickSpacing: brickSpacing,
                      rows: rows,
                      cols: cols,
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context, score ~/ 10),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),

                Positioned(
                  top: 30,
                  left: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      "Очки: $score",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                if (showVictory || showGameOver)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1 + _pulseController.value * 0.0001,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 40,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      showVictory ? "🎉 ПОБЕДА!" : "😢 ПОРАЖЕНИЕ",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      "Счёт: $score",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context, score ~/ 10);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            "Забрать награду",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: _resetGame,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            "Играть снова",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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

class _BricksPainter extends CustomPainter {
  final List<List<bool>> bricks;
  final double ballX, ballY, ballRadius;
  final double paddleX, paddleWidth;
  final double brickTop, brickHeight, brickSpacing;
  final int rows, cols;

  _BricksPainter({
    required this.bricks,
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.paddleX,
    required this.paddleWidth,
    required this.brickTop,
    required this.brickHeight,
    required this.brickSpacing,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!bricks[r][c]) continue;
        double left = c / cols * size.width + brickSpacing * size.width;
        double right = (c + 1) / cols * size.width - brickSpacing * size.width;
        double top = brickTop * size.height +
            r * (brickHeight + brickSpacing) * size.height;
        double bottom = top + brickHeight * size.height;

        paint.color = HSLColor.fromAHSL(
          1.0,
          (240 + r * 10 + c * 5) % 360,
          0.8,
          0.5 + r * 0.05,
        ).toColor();
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
      }
    }

    paint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawRect(
      Rect.fromLTRB(
        (paddleX - paddleWidth / 2) * size.width,
        size.height * 0.95,
        (paddleX + paddleWidth / 2) * size.width,
        size.height * 0.97,
      ),
      paint,
    );

    paint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(ballX * size.width, ballY * size.height),
      ballRadius * size.width,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}