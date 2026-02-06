import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Centralized map configuration with demo coordinates (Mumbai area).
class MapConfig {
  MapConfig._();

  // ── Demo Coordinates ──

  static const LatLng userLocation = LatLng(19.0760, 72.8777);
  static const LatLng centralHospital = LatLng(19.0825, 72.8810);
  static const LatLng cityHospital = LatLng(19.0700, 72.8720);
  static const LatLng ambulanceA01 = LatLng(19.0790, 72.8750);
  static const LatLng ambulanceA02 = LatLng(19.0740, 72.8840);
  static const LatLng ambulanceA03 = LatLng(19.0710, 72.8760);

  // ── Route Polyline Points ──

  static const List<LatLng> routeToHospital = [
    LatLng(19.0760, 72.8777),
    LatLng(19.0770, 72.8785),
    LatLng(19.0785, 72.8790),
    LatLng(19.0800, 72.8800),
    LatLng(19.0815, 72.8805),
    LatLng(19.0825, 72.8810),
  ];

  static const List<LatLng> ambulanceSyncRoute = [
    LatLng(19.0790, 72.8750),
    LatLng(19.0800, 72.8765),
    LatLng(19.0810, 72.8780),
    LatLng(19.0820, 72.8800),
    LatLng(19.0825, 72.8810),
  ];

  // ── Camera Positions ──

  static const CameraPosition overviewCamera = CameraPosition(
    target: LatLng(19.0760, 72.8780),
    zoom: 14.5,
  );

  static const CameraPosition navigationCamera = CameraPosition(
    target: LatLng(19.0790, 72.8790),
    zoom: 15.0,
    tilt: 45,
    bearing: 30,
  );

  static const CameraPosition syncCamera = CameraPosition(
    target: LatLng(19.0800, 72.8780),
    zoom: 14.0,
  );

  // ── Dark Map Style (matches commandDark palette) ──

  static const String darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1A1A2E"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8899AA"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1A1A2E"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#2D3748"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#16213E"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1A1A2E"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#1E3A5F"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#16213E"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#1A2E1A"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0D1B2A"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#16213E"}]
  }
]
''';
}
