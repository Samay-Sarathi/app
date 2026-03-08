import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A Mac-screensaver-inspired multilingual motivational message component.
///
/// Rotates through motivational quotes in multiple languages with a smooth
/// cross-fade + subtle scale animation. Designed for the empty center area
/// of the driver status tab.
class MotivationalGreeting extends StatefulWidget {
  const MotivationalGreeting({super.key});

  @override
  State<MotivationalGreeting> createState() => _MotivationalGreetingState();
}

class _MotivationalGreetingState extends State<MotivationalGreeting>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    _Msg('Drive Safe, Reach Safe', 'English'),
    _Msg('आपकी सुरक्षा, हमारी जिम्मेदारी', 'हिन्दी'),
    _Msg('ನಿಮ್ಮ ಸುರಕ್ಷತೆ ಮುಖ್ಯ', 'ಕನ್ನಡ'),
    _Msg('Every Second Saves a Life', 'English'),
    _Msg('हर सेकंड कीमती है', 'हिन्दी'),
    _Msg('ஒவ்வொரு நொடியும் முக்கியம்', 'தமிழ்'),
    _Msg('You Are Someone\'s Hero Today', 'English'),
    _Msg('జీవితాలను రక్షించండి', 'తెలుగు'),
    _Msg('সময়ই জীবন', 'বাংলা'),
    _Msg('ਸਮਾਂ ਹੀ ਜ਼ਿੰਦਗੀ ਹੈ', 'ਪੰਜਾਬੀ'),
  ];

  int _currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _startRotation();
  }

  void _startRotation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      // Fade out, then switch text, then fade in
      _controller.reverse().then((_) {
        if (!mounted) return;
        setState(() => _currentIndex = (_currentIndex + 1) % _messages.length);
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = _messages[_currentIndex];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative pulse icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lifelineGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: AppColors.lifelineGreen,
                size: 22,
              ),
            ),
            const SizedBox(height: 16),
            // Main message
            Text(
              msg.text,
              style: AppTypography.heading2.copyWith(
                color: onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Language label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                msg.language,
                style: AppTypography.caption.copyWith(
                  color: AppColors.mediumGray,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final String language;
  const _Msg(this.text, this.language);
}
