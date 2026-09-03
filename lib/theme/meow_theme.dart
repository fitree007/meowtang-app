import 'package:flutter/material.dart';

class MeowTheme {
  // Backgrounds & Surfaces
  static const Color navyBackground = Color(0xFF0B1728);
  static const Color navySurface = Color(0xFF132238);
  static const Color navyCard = Color(0xFF172B46);
  static const Color navyCardSelected = Color(0xFF1F3A5E);
  
  // MeowJot Signature Mustard Yellow
  static const Color mustardYellow = Color(0xFFF8C63E);
  static const Color mustardYellowLight = Color(0xFFFFD55E);
  static const Color mustardYellowDark = Color(0xFFDEAA25);

  // Vibrant Action Blue
  static const Color actionBlue = Color(0xFF007AFF);
  static const Color actionBlueLight = Color(0xFF389BFF);
  
  // Transaction Type Colors
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color expenseRedLight = Color(0xFFFCA5A5);
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color incomeGreenLight = Color(0xFF6EE7B7);
  static const Color transferBlue = Color(0xFF38BDF8);
  static const Color transferBlueLight = Color(0xFFBAE6FD);

  // Text Colors
  static const Color textLightPrimary = Color(0xFFFFFFFF);
  static const Color textLightSecondary = Color(0xFF94A3B8);
  static const Color textLightMuted = Color(0xFF64748B);
  
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF334155);

  // Borders & Dividers
  static const Color dividerColor = Color(0xFF1E293B);
  static const Color borderColor = Color(0xFF263952);

  // Gradients
  static const LinearGradient yellowGradient = LinearGradient(
    colors: [Color(0xFFFBD768), Color(0xFFF8C63E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF132238), Color(0xFF0B1728)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueButtonGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF007AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFBD768), Color(0xFFF8C63E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
