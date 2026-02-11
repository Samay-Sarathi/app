import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_info.dart';
import '../config/app_config.dart';
import '../utils/polyline_decoder.dart';

/// Fetches route directions from Google Directions API.
class DirectionsService {
  static const String _apiKey = AppConfig.googleMapsApiKey;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  final Dio _dio;

  DirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch driving route from [origin] to [destination].
  /// Returns null if no route found or API error.
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'key': _apiKey,
      });

      if (response.statusCode != 200) {
        debugPrint('[Directions] HTTP error: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String;

      if (status != 'OK') {
        debugPrint('[Directions] API status: $status');
        return null;
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      return _parseRoute(route);
    } catch (e) {
      debugPrint('[Directions] Error: $e');
      return null;
    }
  }

  RouteInfo _parseRoute(Map<String, dynamic> route) {
    // Decode overview polyline
    final overviewPolyline = route['overview_polyline']['points'] as String;
    final polylinePoints = PolylineDecoder.decode(overviewPolyline);

    // Bounds
    final bounds = route['bounds'] as Map<String, dynamic>;
    final ne = bounds['northeast'] as Map<String, dynamic>;
    final sw = bounds['southwest'] as Map<String, dynamic>;

    // Parse first leg
    final leg = (route['legs'] as List)[0] as Map<String, dynamic>;
    final totalDistance = leg['distance'] as Map<String, dynamic>;
    final totalDuration = leg['duration'] as Map<String, dynamic>;

    // Parse steps
    final stepsJson = leg['steps'] as List;
    final steps = stepsJson.map((s) => _parseStep(s as Map<String, dynamic>)).toList();

    return RouteInfo(
      polylinePoints: polylinePoints,
      steps: steps,
      totalDistanceMeters: totalDistance['value'] as int,
      totalDistanceText: totalDistance['text'] as String,
      totalDurationSeconds: totalDuration['value'] as int,
      totalDurationText: totalDuration['text'] as String,
      boundsNortheast: LatLng(
        (ne['lat'] as num).toDouble(),
        (ne['lng'] as num).toDouble(),
      ),
      boundsSouthwest: LatLng(
        (sw['lat'] as num).toDouble(),
        (sw['lng'] as num).toDouble(),
      ),
    );
  }

  RouteStep _parseStep(Map<String, dynamic> step) {
    final distance = step['distance'] as Map<String, dynamic>;
    final duration = step['duration'] as Map<String, dynamic>;
    final startLoc = step['start_location'] as Map<String, dynamic>;
    final endLoc = step['end_location'] as Map<String, dynamic>;

    // Decode step polyline
    final stepPolyline = step['polyline']?['points'] as String? ?? '';
    final points = stepPolyline.isNotEmpty ? PolylineDecoder.decode(stepPolyline) : <LatLng>[];

    // Strip HTML tags from instruction
    final rawInstruction = step['html_instructions'] as String? ?? '';
    final instruction = _stripHtml(rawInstruction);

    return RouteStep(
      instruction: instruction,
      maneuver: step['maneuver'] as String?,
      distanceMeters: distance['value'] as int,
      distanceText: distance['text'] as String,
      durationText: duration['text'] as String,
      startLocation: LatLng(
        (startLoc['lat'] as num).toDouble(),
        (startLoc['lng'] as num).toDouble(),
      ),
      endLocation: LatLng(
        (endLoc['lat'] as num).toDouble(),
        (endLoc['lng'] as num).toDouble(),
      ),
      polylinePoints: points,
    );
  }

  /// Strip HTML tags from Google Directions instructions.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
