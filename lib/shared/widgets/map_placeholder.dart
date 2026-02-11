import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// A styled placeholder shown when Google Maps is disabled.
///
/// Displays a dark grid background with optional markers, route
/// indicators, and labels — giving visual context without loading
/// the native Maps SDK.
class MapPlaceholder extends StatelessWidget {
  final String title;
  final List<MockMarker> markers;
  final bool showRoute;
  final Widget? overlay;

  const MapPlaceholder({
    super.key,
    this.title = 'Map View',
    this.markers = const [],
    this.showRoute = false,
    this.overlay,
  });

  // ── Factory constructors for each screen ──

  /// Driver dashboard overview map.
  factory MapPlaceholder.overview() => const MapPlaceholder(
        title: 'Live City Grid',
        markers: [
          MockMarker('A-01', Alignment(-0.3, -0.2), AppColors.emergencyRed),
          MockMarker('A-02', Alignment(0.4, 0.1), AppColors.emergencyRed),
          MockMarker('A-03', Alignment(-0.1, 0.4), AppColors.warmOrange),
          MockMarker('Central Hospital', Alignment(0.3, -0.4), AppColors.lifelineGreen),
          MockMarker('City Hospital', Alignment(-0.5, 0.3), AppColors.lifelineGreen),
          MockMarker('You', Alignment(0.0, 0.0), AppColors.medicalBlue),
        ],
      );

  /// Hospital selection map.
  factory MapPlaceholder.hospitalSelect() => const MapPlaceholder(
        title: 'Hospital Proximity',
        markers: [
          MockMarker('Central Medical', Alignment(0.2, -0.3), AppColors.lifelineGreen),
          MockMarker('City Hospital', Alignment(-0.3, 0.2), AppColors.hospitalTeal),
          MockMarker('You', Alignment(0.0, 0.1), AppColors.medicalBlue),
        ],
      );

  /// Navigation / routing map.
  factory MapPlaceholder.navigation() => const MapPlaceholder(
        title: 'Route Active',
        showRoute: true,
        markers: [
          MockMarker('Central Hospital', Alignment(0.3, -0.4), AppColors.lifelineGreen),
          MockMarker('You', Alignment(-0.2, 0.3), AppColors.medicalBlue),
        ],
      );

  /// Green corridor map.
  factory MapPlaceholder.corridor() => const MapPlaceholder(
        title: 'Corridor Route',
        showRoute: true,
        markers: [
          MockMarker('Hospital', Alignment(0.3, -0.3), AppColors.lifelineGreen),
          MockMarker('Ambulance', Alignment(-0.2, 0.3), AppColors.medicalBlue),
        ],
      );

  /// Hospital ambulance sync map.
  factory MapPlaceholder.ambulanceSync() => const MapPlaceholder(
        title: 'Ambulance Tracking',
        showRoute: true,
        markers: [
          MockMarker('A-01', Alignment(-0.3, 0.2), AppColors.medicalBlue),
          MockMarker('Hospital', Alignment(0.3, -0.2), AppColors.lifelineGreen),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mapBackground,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: AppColors.lifelineGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusLg,
        child: Stack(
          children: [
            // Grid background
            CustomPaint(
              size: Size.infinite,
              painter: _MapGridPainter(),
            ),

            // Mock route line
            if (showRoute)
              CustomPaint(
                size: Size.infinite,
                painter: _RoutePainter(),
              ),

            // Mock markers
            for (final marker in markers)
              Align(
                alignment: marker.alignment,
                child: _MarkerDot(marker: marker),
              ),

            // Title badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mapBackground.withValues(alpha: 0.9),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.lifelineGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 12,
                      color: AppColors.lifelineGreen.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title.toUpperCase(),
                      style: AppTypography.overline.copyWith(
                        color: AppColors.lifelineGreen.withValues(alpha: 0.7),
                        letterSpacing: 1.5,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Demo mode badge
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warmOrange.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: AppColors.warmOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'DEMO MODE',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.warmOrange.withValues(alpha: 0.8),
                    fontSize: 8,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Optional overlay
            ?overlay,
          ],
        ),
      ),
    );
  }
}

// ── Data class for mock markers ──

class MockMarker {
  final String label;
  final Alignment alignment;
  final Color color;

  const MockMarker(this.label, this.alignment, this.color);
}

// ── Marker dot widget ──

class _MarkerDot extends StatelessWidget {
  final MockMarker marker;
  const _MarkerDot({required this.marker});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: marker.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: marker.color, width: 2),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: marker.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.mapBackground.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            marker.label,
            style: TextStyle(
              color: marker.color.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Grid painter ──

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lifelineGreen.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Accent cross at center
    final accentPaint = Paint()
      ..color = AppColors.lifelineGreen.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      accentPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Route line painter ──

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lifelineGreen.withValues(alpha: 0.5)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.7);
    path.cubicTo(
      size.width * 0.35, size.height * 0.5,
      size.width * 0.5, size.height * 0.4,
      size.width * 0.65, size.height * 0.25,
    );

    // Draw dashed
    const dashLength = 8.0;
    const gapLength = 5.0;
    double distance = 0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashLength).clamp(0, metric.length);
        final segment = metric.extractPath(start, end.toDouble());
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
