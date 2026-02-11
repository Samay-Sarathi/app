import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required double height,
    Color color = AppColors.darkGray,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  static TextStyle _jetBrainsMono({
    required double size,
    required FontWeight weight,
    required double height,
    Color color = AppColors.darkGray,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }

  // Display
  static TextStyle displayXL = _inter(size: 64, weight: FontWeight.w800, height: 1.1);
  static TextStyle displayL = _inter(size: 48, weight: FontWeight.w700, height: 1.2);

  // Headings
  static TextStyle heading1 = _inter(size: 32, weight: FontWeight.w700, height: 1.3);
  static TextStyle heading2 = _inter(size: 24, weight: FontWeight.w600, height: 1.4);
  static TextStyle heading3 = _inter(size: 20, weight: FontWeight.w500, height: 1.4);

  // Body
  static TextStyle bodyL = _inter(size: 18, weight: FontWeight.w400, height: 1.55);
  static TextStyle body = _inter(size: 16, weight: FontWeight.w400, height: 1.45);
  static TextStyle bodyS = _inter(size: 14, weight: FontWeight.w400, height: 1.5);

  // Small
  static TextStyle caption = _inter(size: 12, weight: FontWeight.w500, height: 1.4);
  static TextStyle overline = _inter(size: 11, weight: FontWeight.w600, height: 1.2);
  static TextStyle label = _inter(size: 10, weight: FontWeight.w500, height: 1.3);

  // Button
  static TextStyle buttonL = _inter(size: 16, weight: FontWeight.w600, height: 1.2);
  static TextStyle buttonM = _inter(size: 14, weight: FontWeight.w600, height: 1.2);
  static TextStyle buttonS = _inter(size: 12, weight: FontWeight.w600, height: 1.2);

  // Vitals (monospace)
  static TextStyle vitalXL = _jetBrainsMono(size: 64, weight: FontWeight.w900, height: 1.1);
  static TextStyle vitalL = _jetBrainsMono(size: 48, weight: FontWeight.w800, height: 1.2);
  static TextStyle vitalM = _jetBrainsMono(size: 24, weight: FontWeight.w700, height: 1.3);
  static TextStyle vitalS = _jetBrainsMono(size: 16, weight: FontWeight.w600, height: 1.4);
}
