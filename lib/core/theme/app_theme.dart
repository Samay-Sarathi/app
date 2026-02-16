import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lifelineGreen,
        secondary: AppColors.medicalBlue,
        error: AppColors.emergencyRed,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onError: AppColors.white,
        onSurface: AppColors.darkGray,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.medicalBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emergencyRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lifelineGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGray,
          minimumSize: const Size(double.infinity, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: AppColors.mediumGray.withValues(alpha: 0.3)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.lifelineGreen;
          return AppColors.lightGray;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.mediumGray.withValues(alpha: 0.3);
        }),
      ),
      extensions: const [
        SkeletonizerConfigData(
          effect: ShimmerEffect(
            baseColor: AppColors.lightGray,
            highlightColor: AppColors.white,
            duration: Duration(milliseconds: 1500),
          ),
          enableSwitchAnimation: true,
          switchAnimationConfig: SwitchAnimationConfig(
            duration: Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
          ),
        ),
      ],
    );
  }

  // Off-white text for dark mode (not pure white — reduces eye strain, like X)
  static const _darkOnSurface = Color(0xFFE7E9EA);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface0,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.successDark,
        secondary: AppColors.infoDark,
        error: AppColors.errorDark,
        surface: AppColors.surface1,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onError: AppColors.white,
        onSurface: _darkOnSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface0,
        foregroundColor: _darkOnSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.08), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.08), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.infoDark, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkOnSurface,
          minimumSize: const Size(double.infinity, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface3,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        elevation: 0,
        backgroundColor: AppColors.surface2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.mediumGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.lifelineGreen;
          return AppColors.surface2;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return AppColors.white.withValues(alpha: 0.15);
        }),
      ),
      extensions: const [
        SkeletonizerConfigData(
          effect: ShimmerEffect(
            baseColor: AppColors.surface2,
            highlightColor: AppColors.surface3,
            duration: Duration(milliseconds: 1500),
          ),
          enableSwitchAnimation: true,
          switchAnimationConfig: SwitchAnimationConfig(
            duration: Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
          ),
        ),
      ],
    );
  }
}
