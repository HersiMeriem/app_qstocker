import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF9F9F9),

  // 🎨 Couleurs principales
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF548CB8), // Bleu doux
    brightness: Brightness.light,
  ),

  useMaterial3: true,

  // 🧩 Style des AppBar
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Color(0xFF1e4868),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Color(0xFF1e4868)),
  ),

  // ✏️ Style des inputs (formulaires)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(color: Colors.grey),
  ),

  // 📦 Style des boutons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF548CB8),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  // 🧾 Style des textes
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
);
