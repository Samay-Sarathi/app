import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/map/map_config.dart';

/// Map utility helpers for styling and polyline creation.
class MapHelpers {
  MapHelpers._();

  /// Applies dark map style when in dark mode.
  /// The JSON already exists in [MapConfig.darkMapStyle] but was never used.
  static Future<void> applyMapStyle(GoogleMapController controller, bool isDark) async {
    if (isDark) {
      await controller.setMapStyle(MapConfig.darkMapStyle);
    } else {
      await controller.setMapStyle(null);
    }
  }

  /// Creates a thicker route polyline with dark outline for visibility.
  static Set<Polyline> createRoutePolyline(List<LatLng> points, {String id = 'route'}) {
    if (points.isEmpty) return {};
    return {
      // Dark outline
      Polyline(
        polylineId: PolylineId('${id}_outline'),
        points: points,
        color: const Color(0xFF1A3A6B),
        width: 8,
      ),
      // Main blue route
      Polyline(
        polylineId: PolylineId(id),
        points: points,
        color: const Color(0xFF4285F4),
        width: 6,
      ),
    };
  }
}
