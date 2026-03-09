import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum LogoVariant { filled, outlined, mono }

/// Custom Clock + Pulse logo for Samay Sarthi.
/// A clock face with heartbeat pulse running through it — "Every Second Counts".
class LifelineLogo extends StatelessWidget {
  final double size;
  final LogoVariant variant;

  const LifelineLogo({
    super.key,
    this.size = 80,
    this.variant = LogoVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(variant: variant),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final LogoVariant variant;

  _LogoPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.46;
    final radius = w * 0.38;

    final Color primary;
    final Color accent;
    final Color bg;

    switch (variant) {
      case LogoVariant.filled:
        primary = AppColors.lifelineGreen;
        accent = Colors.redAccent;
        bg = AppColors.lifelineGreen.withValues(alpha: 0.1);
      case LogoVariant.outlined:
        primary = AppColors.lifelineGreen;
        accent = Colors.redAccent;
        bg = Colors.transparent;
      case LogoVariant.mono:
        primary = Colors.white;
        accent = Colors.white70;
        bg = Colors.white12;
    }

    // Outer circle background
    if (bg != Colors.transparent) {
      canvas.drawCircle(
        Offset(cx, cy),
        radius + w * 0.08,
        Paint()..color = bg,
      );
    }

    // Clock circle
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04,
    );

    // Hour markers (12 small ticks)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMain = i % 3 == 0;
      final outerR = radius - w * 0.02;
      final innerR = radius - (isMain ? w * 0.08 : w * 0.05);

      canvas.drawLine(
        Offset(cx + outerR * math.cos(angle), cy + outerR * math.sin(angle)),
        Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle)),
        Paint()
          ..color = primary
          ..strokeWidth = isMain ? w * 0.03 : w * 0.015
          ..strokeCap = StrokeCap.round,
      );
    }

    // Hour hand (10 o'clock position — pointing to urgency)
    final hourAngle = (300 - 90) * math.pi / 180;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + radius * 0.5 * math.cos(hourAngle),
          cy + radius * 0.5 * math.sin(hourAngle)),
      Paint()
        ..color = primary
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Minute hand (12 o'clock — straight up, urgency)
    final minAngle = (0 - 90) * math.pi / 180;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + radius * 0.7 * math.cos(minAngle),
          cy + radius * 0.7 * math.sin(minAngle)),
      Paint()
        ..color = primary
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(Offset(cx, cy), w * 0.03, Paint()..color = primary);

    // Heartbeat pulse line across bottom
    final pulseY = h * 0.82;
    final pulseAmp = h * 0.08;
    final pulsePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pulse = Path();
    pulse.moveTo(w * 0.08, pulseY);
    pulse.lineTo(w * 0.28, pulseY);
    pulse.lineTo(w * 0.34, pulseY + pulseAmp * 0.5);
    pulse.lineTo(w * 0.42, pulseY - pulseAmp);
    pulse.lineTo(w * 0.50, pulseY + pulseAmp * 0.8);
    pulse.lineTo(w * 0.56, pulseY - pulseAmp * 0.4);
    pulse.lineTo(w * 0.62, pulseY);
    pulse.lineTo(w * 0.92, pulseY);
    canvas.drawPath(pulse, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      variant != oldDelegate.variant;
}
