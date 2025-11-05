import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'mini_games/food_catch.dart';
import 'mini_games/rock_paper_scissors.dart';
import 'mini_games/memory_game.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TamagoApp());
}

class TamagoApp extends StatelessWidget {
  const TamagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamago',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TamagoGame(),
    );
  }
}

class TamagoGame extends StatefulWidget {
  const TamagoGame({super.key});

  @override
  State<TamagoGame> createState() => _TamagoGameState();
}

class _TamagoGameState extends State<TamagoGame> with TickerProviderStateMixin {
  int hunger = 50;
  int energy = 50;
  int mood = 50;
  int xp = 0;
  int level = 1;
  int fedCount = 0;
  int playedCount = 0;
  int sleptCount = 0;
  bool isSleeping = false;
  bool isPlaying = false;
  bool isEating = false;
  Timer? timer;
  String? userId;


  late AnimationController _petScaleController;
  late Animation<double> _petScaleAnimation;
  late AnimationController _petShakeController;
  late Animation<double> _petShakeAnimation;

  static const Color hungerColor = Color(0xFFFFCC80);
  static const Color energyColor = Color(0xFF80DEEA);
  static const Color moodColor = Color(0xFFA5D6A7);
  static const Color xpColor = Color(0xFFFDD835);

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();

    _petScaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _petScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _petScaleController,
        curve: Curves.easeInOut,
      ),
    );

    _petShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _petShakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _petShakeController,
        curve: Curves.elasticIn,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_petShakeController.value > 0) {
          _petShakeController.reverse();
        } else {
          _petShakeController.forward();
        }
      } else if (status == AnimationStatus.dismissed) {
        _petShakeController.forward();
      }
    });
  }

  void _updateAnimationState() {
    if (isSleeping || isEating || isPlaying) {
      _petShakeController.stop();
      if (!_petScaleController.isAnimating) {
        _petScaleController.repeat(reverse: true);
      }
    } else if (hunger < 20 || energy < 20 || mood < 20) {
      _petScaleController.stop();
      if (!_petShakeController.isAnimating) {
        _petShakeController.repeat(reverse: true, period: const Duration(milliseconds: 600));
      }
    } else {
      _petShakeController.stop();
      if (!_petScaleController.isAnimating) {
        _petScaleController.repeat(reverse: true);
      }
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Проверяем или создаем уникальный userId
    userId = prefs.getString('userId');
    if (userId == null) {
      userId = const Uuid().v4(); // создаем новый uuid
      await prefs.setString('userId', userId!);
    }

    if (!mounted) return;
    setState(() {
      hunger = prefs.getInt('hunger') ?? 50;
      energy = prefs.getInt('energy') ?? 50;
      mood = prefs.getInt('mood') ?? 50;
      xp = prefs.getInt('xp') ?? 0;
      level = prefs.getInt('level') ?? 1;
      fedCount = prefs.getInt('fedCount') ?? 0;
      playedCount = prefs.getInt('playedCount') ?? 0;
      sleptCount = prefs.getInt('sleptCount') ?? 0;
    });

    _updateAnimationState();
    await _loadDataFromFirebase();
  }


  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hunger', hunger);
    await prefs.setInt('energy', energy);
    await prefs.setInt('mood', mood);
    await prefs.setInt('xp', xp);
    await prefs.setInt('level', level);
    await prefs.setInt('fedCount', fedCount);
    await prefs.setInt('playedCount', playedCount);
    await prefs.setInt('sleptCount', sleptCount);

    // Сохраняем и в Firebase
    await _saveDataToFirebase();
  }

  Future<void> _saveDataToFirebase() async {
    final userDoc = FirebaseFirestore.instance.collection('pets').doc(userId);
    await userDoc.set({
      'hunger': hunger,
      'energy': energy,
      'mood': mood,
      'xp': xp,
      'level': level,
      'fedCount': fedCount,
      'playedCount': playedCount,
      'sleptCount': sleptCount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadDataFromFirebase() async {
    final userDoc = FirebaseFirestore.instance.collection('pets').doc(userId);
    final snapshot = await userDoc.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        hunger = data['hunger'] ?? hunger;
        energy = data['energy'] ?? energy;
        mood = data['mood'] ?? mood;
        xp = data['xp'] ?? xp;
        level = data['level'] ?? level;
        fedCount = data['fedCount'] ?? fedCount;
        playedCount = data['playedCount'] ?? playedCount;
        sleptCount = data['sleptCount'] ?? sleptCount;
      });
    }
  }



  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: isSleeping ? 2 : 3), (timer) {
      if (!mounted) return;
      setState(() {
        final double decayMultiplier = 1.0 - (level * 0.05).clamp(0, 0.5);

        if (isSleeping) {
          energy = (energy + 10).clamp(0, 100);
        } else if (isPlaying) {
          hunger = (hunger - (3 * decayMultiplier).round()).clamp(0, 100);
          energy = (energy - (4 * decayMultiplier).round()).clamp(0, 100);
          mood = (mood + 2).clamp(0, 100);
        } else {
          hunger = (hunger - (2 * decayMultiplier).round()).clamp(0, 100);
          energy = (energy - (1 * decayMultiplier).round()).clamp(0, 100);
          mood = (mood - (1 * decayMultiplier).round()).clamp(0, 100);
        }
        if (xp >= 100) {
          level++;
          xp = xp - 100;
        }
        _updateAnimationState();

        _saveData();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _petScaleController.dispose();
    _petShakeController.dispose();
    _saveData();
    super.dispose();
  }

  String getPetImage() {
    if (isEating) return 'assets/pet_eating.png';
    if (isSleeping) return 'assets/pet_sleeping.png';
    if (isPlaying) return 'assets/pet_playing.png';
    if (hunger < 20) return 'assets/pet_hungry.png';
    if (energy < 20) return 'assets/pet_sleepy.png';
    if (mood < 20) return 'assets/pet_sad.png';
    return 'assets/pet_happy.png';
  }

  String getBackground() {
    if (isSleeping) return 'assets/bg_bedroom.png';
    if (isPlaying) return 'assets/bg_playroom.png';
    return 'assets/bg_kitchen.png';
  }

  void _openFoodShop() {
    if (getBackground() != 'assets/bg_kitchen.png') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Питомец может есть только на кухне!")),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Выберите еду",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFoodItem("🥕 Морковка", "+10 сытости", () {
                _feedPet(() {
                  hunger = (hunger + 10).clamp(0, 100);
                  xp = (xp + 5).clamp(0, 100);
                });
              }),
              _buildFoodItem("🍕 Пицца", "+25 сытости, -5 энергии", () {
                _feedPet(() {
                  hunger = (hunger + 25).clamp(0, 100);
                  energy = (energy - 5).clamp(0, 100);
                  xp = (xp + 10).clamp(0, 100);
                });
              }),
              _buildFoodItem("🍣 Суши", "+20 сытости, +5 настроения", () {
                _feedPet(() {
                  hunger = (hunger + 20).clamp(0, 100);
                  mood = (mood + 5).clamp(0, 100);
                  xp = (xp + 8).clamp(0, 100);
                });
              }),
              _buildFoodItem("🍫 Шоколад", "+15 сытости, +10 настроения, -5 энергии", () {
                _feedPet(() {
                  hunger = (hunger + 15).clamp(0, 100);
                  mood = (mood + 10).clamp(0, 100);
                  energy = (energy - 5).clamp(0, 100);
                  xp = (xp + 7).clamp(0, 100);
                });
              }),
            ],
          ),
        );
      },
    );
  }

  void _feedPet(VoidCallback applyFood) {
    Navigator.pop(context);
    setState(() {
      isEating = true;
      fedCount++;
      applyFood();
      _updateAnimationState();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isEating = false;
        _updateAnimationState();
      });
    });

    _saveData();
  }

  Widget _buildFoodItem(String title, String effect, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Text(
          title.split(" ")[0],
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(title.split(" ")[1], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(effect),
        onTap: onTap,
      ),
    );
  }

  void _openGameSelection() async {
    bool canPlay = hunger > 20 && energy > 20 && !isSleeping;
    if (!canPlay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Недостаточно энергии или питомец спит!")),
      );
      return;
    }

    setState(() {
      isPlaying = true;
      isSleeping = false;
      _updateAnimationState();
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Выберите игру",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildGameItem("Ловля еды", Icons.fastfood, () {
                Navigator.pop(context);
                _launchGame('food_catch');
              }),
              _buildGameItem("Камень, ножницы, бумага", Icons.casino, () {
                Navigator.pop(context);
                _launchGame('rock_paper_scissors');
              }),
              _buildGameItem("Мемори", Icons.memory, () {
                Navigator.pop(context);
                _launchGame('memory_game');
              }),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
          _updateAnimationState();
        });
      }
    });
  }

  Widget _buildGameItem(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: moodColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }

  void _launchGame(String gameName) async {
    setState(() {
      isPlaying = true;
      isSleeping = false;
      playedCount++;
      _updateAnimationState();
    });

    Widget gameWidget;
    switch (gameName) {
      case 'food_catch':
        gameWidget = const FoodCatchGame();
        break;
      case 'rock_paper_scissors':
        gameWidget = const RockPaperScissorsGame();
        break;
      case 'memory_game':
        gameWidget = const MemoryGame();
        break;
      default:
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameWidget),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        mood = (mood + 20).clamp(0, 100);
        xp = (xp + 15).clamp(0, 100);
      });
    }

    if (!mounted) return;
    setState(() {
      isPlaying = false;
      _updateAnimationState();
    });

    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    bool canPlay = hunger > 20 && energy > 20 && !isSleeping;
    bool canSleep = energy < 90 && !isPlaying;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            getBackground(),
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLevelAndXp(),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: Listenable.merge([_petScaleController, _petShakeController]),
                  builder: (context, child) {
                    final isShaking = (hunger < 20 || energy < 20 || mood < 20) && !isSleeping && !isEating && !isPlaying;
                    double verticalOffset = 0;
                    double rotation = 0;

                    if (isSleeping) {
                      verticalOffset = 5 * (1 - _petScaleAnimation.value);
                    } else if (isEating) {
                      verticalOffset = -8 * (1 - _petScaleAnimation.value);
                    } else if (isPlaying) {
                      rotation = 0.05 * (1 - _petScaleAnimation.value);
                    }

                    return Transform.translate(
                      offset: isShaking
                          ? Offset(_petShakeAnimation.value, 0)
                          : Offset(0, verticalOffset),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: isShaking ? 1.0 : _petScaleAnimation.value,
                          child: Image.asset(
                            getPetImage(),
                            width: 260,
                            height: 260,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionButtons(canPlay, canSleep),
                const SizedBox(height: 30),
                SizedBox(
                  width: 250,
                  child: _buildStatIndicators(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelAndXp() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Уровень: $level",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 5, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 5),
          buildIndicator("Опыт", xp, xpColor),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool canPlay, bool canSleep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          label: "Кормить",
          icon: Icons.fastfood,
          color: hungerColor,
          onPressed: _openFoodShop,
        ),
        const SizedBox(width: 15),
        _buildActionButton(
          label: isSleeping ? "Разбудить" : "Спать",
          icon: Icons.bedtime,
          color: energyColor,
          onPressed: canSleep || isSleeping
              ? () {
            setState(() {
              isSleeping = !isSleeping;
              isPlaying = false;
              if (isSleeping) sleptCount++;
              _updateAnimationState();
            });
            _startTimer();
            _saveData();
          }
              : null,
        ),
        const SizedBox(width: 15),
        _buildActionButton(
          label: "Играть",
          icon: Icons.sports_esports,
          color: moodColor,
          onPressed: canPlay ? _openGameSelection : null,
        ),
      ],
    );
  }

  Widget _buildStatIndicators() {
    return Column(
      children: [
        buildIndicator("Сытость", hunger, hungerColor),
        const SizedBox(height: 10),
        buildIndicator("Энергия", energy, energyColor),
        const SizedBox(height: 10),
        buildIndicator("Настроение", mood, moodColor),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final textColor = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildIndicator(String title, int value, Color color) {
    final barBackgroundColor = Colors.white.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "$title: $value",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 3, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 15,
                color: color,
                backgroundColor: barBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}