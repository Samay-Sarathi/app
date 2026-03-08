import 'dart:math';
import 'package:flutter/material.dart';

/// Reusable action button for map navigation panels.
///
/// Glass-styled — works inside the frosted NavBottomSheet.
/// Set [glowing] to true for an animated rotating border effect.
class MapActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool glowing;

  const MapActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.glowing = false,
  });

  @override
  State<MapActionButton> createState() => _MapActionButtonState();
}

class _MapActionButtonState extends State<MapActionButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    if (widget.glowing) _startGlow();
  }

  @override
  void didUpdateWidget(MapActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.glowing && _glowController == null) {
      _startGlow();
    } else if (!widget.glowing && _glowController != null) {
      _stopGlow();
    }
  }

  void _startGlow() {
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  void _stopGlow() {
    _glowController?.dispose();
    _glowController = null;
  }

  @override
  void dispose() {
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.glowing && _glowController != null) {
      return AnimatedBuilder(
        animation: _glowController!,
        builder: (context, _) => _buildButton(isDark, _glowController!.value),
      );
    }

    return _buildButton(isDark, 0);
  }

  Widget _buildButton(bool isDark, double animValue) {
    final color = widget.color;
    final bgAlpha = isDark ? 0.15 : 0.22;

    if (!widget.glowing) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.55),
              width: 1.2,
            ),
          ),
          child: _buildContent(color),
        ),
      );
    }

    // Glowing: animated rotating border + outer glow
    return GestureDetector(
      onTap: widget.onTap,
      child: CustomPaint(
        painter: _RotatingBorderPainter(
          color: color,
          progress: animValue,
          borderRadius: 16,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: bgAlpha + 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _buildContent(color),
        ),
      ),
    );
  }

  Widget _buildContent(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, color: color, size: 22),
        const SizedBox(height: 5),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// Draws a rounded-rect border with a bright sweep that rotates around it.
class _RotatingBorderPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double borderRadius;

  _RotatingBorderPainter({
    required this.color,
    required this.progress,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Dim base border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withValues(alpha: 0.25);
    canvas.drawRRect(rrect, basePaint);

    // Rotating sweep gradient border
    final sweepAngle = progress * 2 * pi;
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + pi,
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color,
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(rect);
    canvas.drawRRect(rrect, sweepPaint);

    // Outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + pi,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(rect);
    canvas.drawRRect(rrect, glowPaint);
  }

  @override
  bool shouldRepaint(_RotatingBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
