import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF7B61FF);
const Color secondaryColor = Color(0xFF00D4AA);
const Color accentColor = Color(0xFFFF6B8B);
const Color backgroundColor = Color(0xFFF8F9FF);
const Color cardColor = Color(0xFFFFFFFF);
const Color hungerColor = Color(0xFFFF9E66);
const Color energyColor = Color(0xFF66C4FF);
const Color moodColor = Color(0xFF9D65FF);
const Color xpColor = Color(0xFFFFD166);
const Color coinColor = Color(0xFFFFC107);

final List<Map<String, dynamic>> foodItems = [
  {'emoji': '🥗', 'name': 'Салат', 'effect': '+10  к сытости питомца', 'price': 8, 'hunger': 10},
  {'emoji': '🍔', 'name': 'Бургер', 'effect': '+25 к сытости питомца', 'price': 15, 'hunger': 25},
  {'emoji': '🍣', 'name': 'Суши', 'effect': '+20  к сытости питомца', 'price': 20, 'hunger': 20},
  {'emoji': '🍎', 'name': 'Яблоко', 'effect': '+8  к сытости питомца', 'price': 5, 'hunger': 8},
];