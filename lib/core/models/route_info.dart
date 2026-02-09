import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single turn-by-turn navigation step from the Directions API.
class RouteStep {
  /// Human-readable instruction (HTML stripped).
  final String instruction;

  /// Maneuver type: "turn-left", "turn-right", "straight", "roundabout-right", etc.
  final String? maneuver;

  /// Distance of this step in meters.
  final int distanceMeters;

  /// Human-readable distance ("500 m", "1.2 km").
  final String distanceText;

  /// Human-readable duration ("2 mins").
  final String durationText;

  /// Start location of this step.
  final LatLng startLocation;

  /// End location of this step.
  final LatLng endLocation;

  /// Decoded polyline points for this step.
  final List<LatLng> polylinePoints;

  const RouteStep({
    required this.instruction,
    this.maneuver,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationText,
    required this.startLocation,
    required this.endLocation,
    required this.polylinePoints,
  });
}

/// Full route info parsed from Google Directions API.
class RouteInfo {
  /// All decoded polyline points for the full route.
  final List<LatLng> polylinePoints;

  /// Turn-by-turn steps.
  final List<RouteStep> steps;

  /// Total distance in meters.
  final int totalDistanceMeters;

  /// Human-readable total distance.
  final String totalDistanceText;

  /// Total duration in seconds.
  final int totalDurationSeconds;

  /// Human-readable total duration.
  final String totalDurationText;

  /// Northeast corner of the route bounds.
  final LatLng boundsNortheast;

  /// Southwest corner of the route bounds.
  final LatLng boundsSouthwest;

  const RouteInfo({
    required this.polylinePoints,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDistanceText,
    required this.totalDurationSeconds,
    required this.totalDurationText,
    required this.boundsNortheast,
    required this.boundsSouthwest,
  });

  /// ETA in minutes.
  int get etaMinutes => (totalDurationSeconds / 60).ceil();

  /// Distance in km.
  double get distanceKm => totalDistanceMeters / 1000.0;
}
