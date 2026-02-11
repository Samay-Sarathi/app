import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Paints custom map markers using Canvas API — no PNG assets needed.
/// Returns [BitmapDescriptor] via pictureRecorder → toImage → fromBytes.
class CustomMarkers {
  CustomMarkers._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Red circle with white ambulance icon.
  static Future<BitmapDescriptor> ambulanceMarker() async {
    if (_cache.containsKey('ambulance')) return _cache['ambulance']!;
    final descriptor = await _paintCircleMarker(
      fillColor: const Color(0xFFE63946),
      iconPainter: (canvas, center, iconSize) {
        // Draw a simple ambulance cross
        final paint = Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(center.dx - iconSize * 0.35, center.dy),
          Offset(center.dx + iconSize * 0.35, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - iconSize * 0.35),
          Offset(center.dx, center.dy + iconSize * 0.35),
          paint,
        );
      },
    );
    _cache['ambulance'] = descriptor;
    return descriptor;
  }

  /// Green circle with white hospital cross.
  static Future<BitmapDescriptor> hospitalMarker() async {
    if (_cache.containsKey('hospital')) return _cache['hospital']!;
    final descriptor = await _paintCircleMarker(
      fillColor: const Color(0xFF16A085),
      iconPainter: (canvas, center, iconSize) {
        final paint = Paint()
          ..color = Colors.white
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(center.dx - iconSize * 0.3, center.dy),
          Offset(center.dx + iconSize * 0.3, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - iconSize * 0.3),
          Offset(center.dx, center.dy + iconSize * 0.3),
          paint,
        );
      },
    );
    _cache['hospital'] = descriptor;
    return descriptor;
  }

  /// Blue navigation arrow — Google Maps style.
  ///
  /// Solid blue filled arrow pointing up with white border,
  /// surrounded by a subtle accuracy glow ring. Designed to be
  /// used with `flat: true` and `rotation: heading` on the Marker.
  static Future<BitmapDescriptor> userArrowMarker() async {
    if (_cache.containsKey('userArrow')) return _cache['userArrow']!;
    const size = 100.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    // Outer accuracy glow ring
    canvas.drawCircle(
      center,
      size * 0.48,
      Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      size * 0.38,
      Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.08),
    );

    // Arrow shape — solid filled triangle pointing up
    final arrowPath = Path()
      ..moveTo(center.dx, center.dy - 22) // top point
      ..lineTo(center.dx + 16, center.dy + 14) // bottom right
      ..lineTo(center.dx, center.dy + 6) // inner notch
      ..lineTo(center.dx - 16, center.dy + 14) // bottom left
      ..close();

    // White border (drawn first, slightly larger)
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );

    // Blue filled arrow
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );

    // Small white dot at center for polish
    canvas.drawCircle(
      Offset(center.dx, center.dy + 1),
      2.5,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _cache['userArrow'] = descriptor;
    return descriptor;
  }

  /// Generic circle marker with custom fill color and icon painter.
  static Future<BitmapDescriptor> _paintCircleMarker({
    required Color fillColor,
    required void Function(Canvas canvas, Offset center, double iconSize) iconPainter,
    double size = 80.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2 - 6);
    final radius = size * 0.35;

    // Shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      radius + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main circle
    canvas.drawCircle(center, radius, Paint()..color = fillColor);

    // White border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Icon
    iconPainter(canvas, center, radius);

    // Bottom pointer triangle
    final pointerPath = Path()
      ..moveTo(center.dx - 8, center.dy + radius - 2)
      ..lineTo(center.dx, center.dy + radius + 12)
      ..lineTo(center.dx + 8, center.dy + radius - 2)
      ..close();
    canvas.drawPath(pointerPath, Paint()..color = fillColor);
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
