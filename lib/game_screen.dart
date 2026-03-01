import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mini_games/food_catch.dart';
import 'mini_games/rock_paper_scissors.dart';
import 'mini_games/memory_game.dart';
import 'mini_games/bricks_breaker.dart';
import 'constants.dart';
import 'auth_screen.dart';

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
  int coins = 100;
  int fedCount = 0;
  int playedCount = 0;
  int sleptCount = 0;
  bool isSleeping = false;
  bool isPlaying = false;
  bool isEating = false;

  Timer? timer;
  String? userId;
  double _getPetSize() {
    if (level < 3) {
      return 350.0;
    } else {
      return 200.0;
    }
  }
  late AnimationController _petScaleController;
  late Animation<double> _petScaleAnimation;
  late AnimationController _petShakeController;
  late Animation<double> _petShakeAnimation;
  late AnimationController _coinSpinController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _petScaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _petScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _petScaleController, curve: Curves.easeInOut),
    );

    _petShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _petShakeAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _petShakeController, curve: Curves.easeInOutSine),
    );

    _coinSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _updateAnimationState() {
    _petShakeController.stop();
    _petShakeController.reset();
    if (hunger < 20 || energy < 20 || mood < 20) {
      _petShakeController.repeat(reverse: true);
    }
    if (!_petScaleController.isAnimating) {
      _petScaleController.repeat(reverse: true);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirectToAuth();
      return;
    }
    userId = user.uid;
    await _loadDataFromFirebase();
    _startTimer();
    _updateAnimationState();
  }

  Future<void> _loadDataFromFirebase() async {
    if (userId == null) return;
    final doc = FirebaseFirestore.instance.collection('pets').doc(userId);
    final snapshot = await doc.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        hunger = data['hunger'] ?? hunger;
        energy = data['energy'] ?? energy;
        mood = data['mood'] ?? mood;
        xp = data['xp'] ?? xp;
        level = data['level'] ?? level;
        coins = data['coins'] ?? coins;
        fedCount = data['fedCount'] ?? fedCount;
        playedCount = data['playedCount'] ?? playedCount;
        sleptCount = data['sleptCount'] ?? sleptCount;
      });
    }
  }

  Future<void> _saveDataToFirebase() async {
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('pets').doc(userId).set({
      'hunger': hunger,
      'energy': energy,
      'mood': mood,
      'xp': xp,
      'level': level,
      'coins': coins,
      'fedCount': fedCount,
      'playedCount': playedCount,
      'sleptCount': sleptCount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _redirectToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _signOut() async {
    timer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (mounted) _redirectToAuth();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: isSleeping ? 2 : 3), (timer) {
      if (!mounted) return;
      setState(() {
        final double decayMultiplier = 1.0 - (level * 0.05).clamp(0, 0.5);
        if (isSleeping) {
          energy = (energy + 10).clamp(0, 100);
          if (level < 3 && energy >= 100) {
            level = 3;
            xp = 0;
            isSleeping = false;
            _showEvolutionDialog("Яйцо треснуло! 🎉\nПоявился милый малыш!");
          }
        } else if (isPlaying) {
          hunger = (hunger - (3 * decayMultiplier).round()).clamp(0, 100);
          energy = (energy - (4 * decayMultiplier).round()).clamp(0, 100);
          mood = (mood + 2).clamp(0, 100);
        } else {
          hunger = (hunger - (2 * decayMultiplier).round()).clamp(0, 100);
          energy = (energy - (1 * decayMultiplier).round()).clamp(0, 100);
          mood = (mood - (1 * decayMultiplier).round()).clamp(0, 100);
          xp += 1;
        }
        if (xp >= 100) {
          level++;
          xp -= 100;
          coins += 50;
          if (level == 10) {
            _showEvolutionDialog("Ваш питомец вырос! ✨");
          } else if (level > 3) {
            _showSnackBar("Уровень повышен! +50 монет!", Colors.green);
          }
        }
        _updateAnimationState();
        _saveDataToFirebase();
      });
    });
  }

  void _showEvolutionDialog(String text) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withValues(alpha: 0.9), secondaryColor.withValues(alpha: 0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 25, spreadRadius: 5)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 100, color: Colors.white),
                const SizedBox(height: 16),
                Text("Эволюция!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.5))])),
                const SizedBox(height: 12),
                Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("Ура!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _petScaleController.dispose();
    _petShakeController.dispose();
    _coinSpinController.dispose();
    super.dispose();
  }

  String getPetImage() {
    String stage = 'baby';
    if (level < 3) stage = 'egg';
    if (level >= 10) stage = 'adult';
    if (stage == 'egg') return 'assets/egg.png';

    String state = 'happy';
    if (isEating) state = 'eating';
    else if (isSleeping) state = 'sleeping';
    else if (isPlaying) state = 'playing';
    else if (hunger < 20) state = 'hungry';
    else if (energy < 20) state = 'sleepy';
    else if (mood < 20) state = 'sad';
    return 'assets/pet_$state.png';
  }

  String getBackground() {
    if (isSleeping) return 'assets/bg_bedroom.png';
    if (isPlaying) return 'assets/bg_playroom.png';
    return 'assets/bg_kitchen.png';
  }

  //Продуктовый магазин
  void _openFoodShop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [backgroundColor, cardColor], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 60, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("Меню", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              Text("Выберите блюдо для питомца", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: foodItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(color: hungerColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 24))),
                          ),
                          title: Text(item['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                          subtitle: Text(item['effect'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [coinColor, xpColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text("${item['price']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          onTap: () => _buyFood(item),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _buyFood(Map<String, dynamic> item) {
    if (level < 3) {
      _showSnackBar("Яйцо пока не может есть!", Colors.orange);
      return;
    }
    if (coins < (item['price'] as int)) {
      _showSnackBar("Недостаточно монет!", Colors.red);
      return;
    }
    setState(() {
      coins -= (item['price'] as int);
      hunger = (hunger + (item['hunger'] as int)).clamp(0, 100);
      xp = (xp + 5).clamp(0, 100);
      fedCount++;
      isEating = true;
      _updateAnimationState();
    });
    _coinSpinController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { isEating = false; _updateAnimationState(); });
    });
    _saveDataToFirebase();
    Navigator.pop(context);
    _showSnackBar("Питомец с удовольствием съел ${item['name']}! 😋", Colors.green);
  }

  void _openGameSelection() {
    if (level < 3) {
      _showSnackBar("Яйцо слишком маленькое для игр!", Colors.orange);
      return;
    }
    if (!(energy > 20 && !isSleeping)) {
      _showSnackBar("Питомец устал и не может играть!", Colors.red);
      return;
    }
    setState(() { isPlaying = true; isSleeping = false; _updateAnimationState(); });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [backgroundColor, cardColor], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 60, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("Игровая комната", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              Text("Выберите игру для питомца", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              // Первый ряд
              Row(
                children: [
                  _buildGameCard("Ловля еды", Icons.fastfood, hungerColor, () => _launchGame('food_catch')),
                  const SizedBox(width: 16),
                  _buildGameCard("Камень ножницы бумага", Icons.casino, moodColor, () => _launchGame('rock_paper_scissors')),
                ],
              ),
              const SizedBox(height: 16),
              // Второй ряд
              Row(
                children: [
                  _buildGameCard("Карточки", Icons.memory, energyColor, () => _launchGame('memory_game')),
                  const SizedBox(width: 16),
                  _buildGameCard("Кирпичики", Icons.games, accentColor, () => _launchGame('bricks_breaker')),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() { isPlaying = false; _updateAnimationState(); });
    });
  }

  Widget _buildGameCard(String title, IconData icon, Color color, VoidCallback onTap, {bool fullWidth = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: fullWidth ? 80 : 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              if (fullWidth) const SizedBox(height: 8),
              if (fullWidth) Text("Тренируем память", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  void _launchGame(String gameName) async {
    setState(() { isPlaying = true; playedCount++; _updateAnimationState(); });
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
      case 'bricks_breaker':
        gameWidget = const BricksBreakerGame();
        break;
      default:
        return;
    }

    final earnedCoins = await Navigator.push(context, MaterialPageRoute(builder: (context) => gameWidget));
    if (!mounted) return;
    if (earnedCoins != null && earnedCoins is int && earnedCoins > 0) {
      setState(() {
        mood = (mood + 20).clamp(0, 100);
        xp = (xp + 15).clamp(0, 100);
        coins += earnedCoins;
      });
      _showSnackBar("+$earnedCoins монет! 🎉", Colors.green);
    }
    setState(() { isPlaying = false; _updateAnimationState(); });
    _saveDataToFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(getBackground(), fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: primaryColor.withValues(alpha: 0.1)),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            AnimatedBuilder(
                              animation: _coinSpinController,
                              builder: (context, child) => Transform.rotate(angle: _coinSpinController.value * 6.28, child: child),
                              child: Icon(Icons.monetization_on, color: coinColor, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(coins.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text("Уровень $level", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.grey[700]),
                            onPressed: _signOut,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_petScaleController, _petShakeController]),
                      builder: (context, child) {
                        final isShaking = (hunger < 20 || energy < 20 || mood < 20) && !isSleeping && !isEating && !isPlaying;
                        return Transform.translate(
                          offset: Offset(0, isShaking ? _petShakeAnimation.value * 2 : 0),
                          child: Transform.scale(
                            scale: _petScaleAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 160,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)],
                                  ),
                                ),
                                Image.asset(
                                  getPetImage(),
                                  width: _getPetSize(),
                                  height: _getPetSize(),
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: _getPetSize(),
                                    height: _getPetSize(),
                                    decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: Icon(Icons.pets, size: _getPetSize() * 0.4, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Статистика
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatBar("Сытость", hunger, hungerColor, Icons.restaurant)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatBar("Энергия", energy, energyColor, Icons.bolt)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatBar("Настроение", mood, moodColor, Icons.mood)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: xp / 100, minHeight: 8, backgroundColor: Colors.grey[200], color: xpColor, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Опыт", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text("$xp/100", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
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
                      _buildActionButton(icon: Icons.restaurant, label: "Еда", color: accentColor, onPressed: _openFoodShop),
                      _buildActionButton(
                        icon: isSleeping ? Icons.wb_sunny : Icons.bedtime,
                        label: isSleeping ? "Разбудить" : "Спать",
                        color: energyColor,
                        onPressed: () {
                          setState(() {
                            isSleeping = !isSleeping;
                            isPlaying = false;
                            if (isSleeping) sleptCount++;
                            _updateAnimationState();
                          });
                          _startTimer();
                          _saveDataToFirebase();
                        },
                        isActive: isSleeping || energy < 90,
                      ),
                      _buildActionButton(
                        icon: Icons.sports_esports,
                        label: "Играть",
                        color: moodColor,
                        onPressed: _openGameSelection,
                        isActive: energy > 20 && !isSleeping,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String title, int value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const Spacer(),
            Text("$value%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value / 100, minHeight: 6, backgroundColor: color.withValues(alpha: 0.2), color: color),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed, bool isActive = true}) {
    return GestureDetector(
      onTap: isActive ? onPressed : null,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.5,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive ? [color, Color.lerp(color, Colors.white, 0.3)!] : [Colors.grey[300]!, Colors.grey[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: (isActive ? color : Colors.grey).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}