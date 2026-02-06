import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color lifelineGreen = Color(0xFF1AAE6F);
  static const Color emergencyRed = Color(0xFFE63946);
  static const Color medicalBlue = Color(0xFF3498DB);
  static const Color commandDark = Color(0xFF1A1A2E);

  // ── Secondary ──
  static const Color warmOrange = Color(0xFFF4A261);
  static const Color softYellow = Color(0xFFE9C46A);
  static const Color calmPurple = Color(0xFF9B59B6);
  static const Color hospitalTeal = Color(0xFF16A085);

  // ── Neutrals ──
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGray = Color(0xFFE9ECEF);
  static const Color mediumGray = Color(0xFF6C757D);
  static const Color darkGray = Color(0xFF2D3748);
  static const Color black = Color(0xFF000000);

  // ── Surface elevation (dark mode) ──
  static const Color surface0 = Color(0xFF1A1A2E); // scaffold
  static const Color surface1 = Color(0xFF16213E); // cards
  static const Color surface2 = Color(0xFF1B2A4A); // raised elements
  static const Color surface3 = Color(0xFF213555); // dialogs/modals

  // ── Muted tints (for subtle backgrounds without visual noise) ──
  static const Color greenTint = Color(0x0D1AAE6F); // 5% green
  static const Color redTint = Color(0x0DE63946);    // 5% red
  static const Color blueTint = Color(0x0D3498DB);   // 5% blue
  static const Color orangeTint = Color(0x0DF4A261); // 5% orange

  // ── Semantic - Light ──
  static const Color successLight = Color(0xFF1AAE6F);
  static const Color errorLight = Color(0xFFE63946);
  static const Color warningLight = Color(0xFFF4A261);
  static const Color infoLight = Color(0xFF3498DB);

  // ── Semantic - Dark ──
  static const Color successDark = Color(0xFF2ECC71);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color warningDark = Color(0xFFFFB347);
  static const Color infoDark = Color(0xFF5DADE2);

  // ── Status Badge backgrounds ──
  static const Color activeBackground = Color(0xFFD4EDDA);
  static const Color activeForeground = Color(0xFF155724);
  static const Color syncedBackground = Color(0xFFD1ECF1);
  static const Color syncedForeground = Color(0xFF0C5460);
  static const Color warningBackground = Color(0xFFFFF3CD);
  static const Color warningForeground = Color(0xFF856404);
  static const Color offlineBackground = Color(0xFFF8D7DA);
  static const Color offlineForeground = Color(0xFF721C24);
  static const Color pendingBackground = Color(0xFFE2E3E5);
  static const Color pendingForeground = Color(0xFF383D41);

  // ── Text opacity helpers ──
  /// Use for secondary / subdued text on dark backgrounds.
  static Color textMuted(Color base) => base.withValues(alpha: 0.55);
  /// Use for tertiary / hint text on dark backgrounds.
  static Color textHint(Color base) => base.withValues(alpha: 0.35);
}
