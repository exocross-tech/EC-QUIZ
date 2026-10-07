import 'package:flutter/material.dart';

/// Colorful, vibrant palette inspired by party quiz games (Kahoot-style).
class AppColors {
  // Brand identity
  static const Color primary = Color(0xFF6C4AB6); // Vibrant Royal Violet
  static const Color primaryContainer = Color(0xFF8D72E1);
  static const Color secondary = Color(0xFFFF5722); // Warm Energetic Orange
  static const Color accent = Color(0xFF00C897); // Mint Emerald

  // Game palette (for questions & vibrant UI elements)
  static const Color gameRed = Color(0xFFE21B3C);
  static const Color gameBlue = Color(0xFF1368CE);
  static const Color gameYellow = Color(0xFFFFA602);
  static const Color gameGreen = Color(0xFF26890C);

  // Avatar presets palette
  static const List<Color> avatarColors = [
    Color(0xFFE21B3C), // Red
    Color(0xFF1368CE), // Blue
    Color(0xFFFFA602), // Yellow
    Color(0xFF26890C), // Green
    Color(0xFF8E24AA), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF3949AB), // Indigo
  ];

  // Neutrals (Light)
  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F1F24);
  static const Color lightTextSecondary = Color(0xFF6E6E77);

  // Neutrals (Dark)
  static const Color darkBackground = Color(0xFF12111A);
  static const Color darkSurface = Color(0xFF1E1B29);
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFFA09EB2);
}
