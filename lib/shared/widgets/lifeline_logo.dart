import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum LogoVariant { filled, outlined, mono }

/// Custom Shield + Pulse logo for LifeLine.
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

    // Shield path — rounded top, pointed bottom
    final shieldPath = Path();
    final topRadius = w * 0.22;

    // Start at top-left after radius
    shieldPath.moveTo(0, topRadius);
    // Top-left corner
    shieldPath.quadraticBezierTo(0, 0, topRadius, 0);
    // Top edge
    shieldPath.lineTo(w - topRadius, 0);
    // Top-right corner
    shieldPath.quadraticBezierTo(w, 0, w, topRadius);
    // Right edge down to taper point
    shieldPath.lineTo(w, h * 0.52);
    // Right curve to bottom point
    shieldPath.quadraticBezierTo(w, h * 0.68, w * 0.5, h);
    // Left curve from bottom point
    shieldPath.quadraticBezierTo(0, h * 0.68, 0, h * 0.52);
    // Close back to start
    shieldPath.close();

    switch (variant) {
      case LogoVariant.filled:
        // Green filled shield
        final fillPaint = Paint()
          ..color = AppColors.lifelineGreen
          ..style = PaintingStyle.fill;
        canvas.drawPath(shieldPath, fillPaint);
        // White pulse line
        _drawPulse(canvas, size, Colors.white);
        break;

      case LogoVariant.outlined:
        // Green outlined shield
        final strokePaint = Paint()
          ..color = AppColors.lifelineGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045;
        canvas.drawPath(shieldPath, strokePaint);
        // Green pulse line
        _drawPulse(canvas, size, AppColors.lifelineGreen);
        break;

      case LogoVariant.mono:
        // White filled shield for dark backgrounds
        final fillPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawPath(shieldPath, fillPaint);
        // Dark pulse line
        _drawPulse(canvas, size, AppColors.commandDark);
        break;
    }
  }

  void _drawPulse(Canvas canvas, Size size, Color color) {
    final w = size.width;
    final h = size.height;
    final midY = h * 0.44;
    final amplitude = h * 0.15;
    final strokeW = w * 0.05;

    final pulsePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Flat line from left
    path.moveTo(w * 0.14, midY);
    path.lineTo(w * 0.30, midY);
    // Down dip
    path.lineTo(w * 0.36, midY + amplitude * 0.4);
    // Big spike up
    path.lineTo(w * 0.44, midY - amplitude);
    // Big spike down
    path.lineTo(w * 0.52, midY + amplitude * 0.7);
    // Recovery up
    path.lineTo(w * 0.58, midY - amplitude * 0.3);
    // Back to baseline
    path.lineTo(w * 0.64, midY);
    // Flat line to right
    path.lineTo(w * 0.86, midY);

    canvas.drawPath(path, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      variant != oldDelegate.variant;
}
