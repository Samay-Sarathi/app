import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared navigation utility functions used across all roles
/// (driver navigation, police tracking, hospital ambulance monitoring).
class NavigationHelpers {
  NavigationHelpers._();

  /// Returns the appropriate Material icon for a Google Directions API maneuver string.
  static IconData maneuverIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
        return Icons.u_turn_left;
      case 'uturn-right':
        return Icons.u_turn_right;
      case 'roundabout-left':
        return Icons.roundabout_left;
      case 'roundabout-right':
        return Icons.roundabout_right;
      case 'fork-left':
        return Icons.fork_left;
      case 'fork-right':
        return Icons.fork_right;
      case 'merge':
        return Icons.merge;
      case 'ramp-left':
        return Icons.turn_slight_left;
      case 'ramp-right':
        return Icons.turn_slight_right;
      case 'straight':
      default:
        return Icons.straight;
    }
  }

  /// Formats meters as human-readable distance (e.g., "1.2 km" or "450 m").
  static String formatDistance(int meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '$meters m';
  }

  /// Formats seconds as human-readable ETA (e.g., "12 min" or "1h 30m").
  static String formatEta(int seconds) {
    if (seconds < 60) return '<1 min';
    final min = (seconds / 60).ceil();
    if (min >= 60) return '${min ~/ 60}h ${min % 60}m';
    return '$min min';
  }

  /// Calculates haversine distance between two [LatLng] points in meters.
  static double haversineDistance(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) *
        sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
