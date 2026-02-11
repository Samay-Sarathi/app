import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Centralized map configuration with default coordinates (Electronic City, Bangalore).
class MapConfig {
  MapConfig._();

  // ── Default Coordinates (Electronic City Phase 1, Bengaluru) ──

  static const LatLng userLocation = LatLng(12.8456, 77.6603);
  static const LatLng centralHospital = LatLng(12.8500, 77.6700); // Narayana Health City area
  static const LatLng cityHospital = LatLng(12.8350, 77.6600);    // Sakra World Hospital area
  static const LatLng ambulanceA01 = LatLng(12.8480, 77.6620);
  static const LatLng ambulanceA02 = LatLng(12.8430, 77.6650);
  static const LatLng ambulanceA03 = LatLng(12.8400, 77.6580);

  // ── Route Polyline Points ──

  static const List<LatLng> routeToHospital = [
    LatLng(12.8456, 77.6603),
    LatLng(12.8465, 77.6620),
    LatLng(12.8475, 77.6645),
    LatLng(12.8485, 77.6665),
    LatLng(12.8495, 77.6685),
    LatLng(12.8500, 77.6700),
  ];

  static const List<LatLng> ambulanceSyncRoute = [
    LatLng(12.8480, 77.6620),
    LatLng(12.8485, 77.6640),
    LatLng(12.8490, 77.6660),
    LatLng(12.8495, 77.6680),
    LatLng(12.8500, 77.6700),
  ];

  // ── Camera Positions ──o

  static const CameraPosition overviewCamera = CameraPosition(
    target: LatLng(12.8456, 77.6603),
    zoom: 14.5,
  );

  static const CameraPosition navigationCamera = CameraPosition(
    target: LatLng(12.8480, 77.6650),
    zoom: 15.0,
    tilt: 45,
    bearing: 30,
  );

  static const CameraPosition syncCamera = CameraPosition(
    target: LatLng(12.8475, 77.6650),
    zoom: 14.0,
  );

  // ── Dark Map Style (exact Google Maps night mode) ──

  static const String darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';
}
