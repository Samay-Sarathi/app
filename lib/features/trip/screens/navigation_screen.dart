import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/trip_status.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/models/route_info.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../core/map/custom_markers.dart';
import '../../../shared/widgets/map/turn_banner.dart';
import '../../../shared/widgets/map/nav_bottom_sheet.dart';
import '../../../shared/widgets/map/map_action_button.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../widgets/qr_handoff_sheet.dart';

/// Unified navigation + green corridor screen.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<CompassEvent>? _compassSub;
  String? _subscribedTripTopic;

  // Navigation state
  final DirectionsService _directionsService = DirectionsService();
  RouteInfo? _routeInfo;
  int _currentStepIndex = 0;
  LatLng? _currentLocation;
  double _currentSpeed = 0;
  double _currentHeading = 0;
  bool _isFollowingUser = true;
  bool _routeLoading = true;
  String? _routeError;
  int _remainingDistanceMeters = 0;
  int _remainingDurationSeconds = 0;

  // Custom markers
  BitmapDescriptor? _hospitalIcon;
  BitmapDescriptor? _userArrowIcon;

  // Green corridor state
  bool _corridorActive = false;

  // Proximity arrival
  bool _isNearHospital = false;
  static const double _arrivalRadiusMeters = 500;

  // Trip cancellation banner
  bool _showCancelBanner = false;
  int _cancelCountdown = 3;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _startCompass();
    _initNavigation();
    _subscribeToTripStatus();
    _autoActivateCorridor();
  }

  // ── Compass for real-time heading ──

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      final heading = event.heading!;
      // Only update if heading changed meaningfully (>2°) to avoid jitter
      if ((heading - _currentHeading).abs() > 2) {
        setState(() => _currentHeading = heading);
        if (_isFollowingUser && _mapController != null && _currentLocation != null) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation!, zoom: 17.5, tilt: 55, bearing: heading),
          ));
        }
      }
    });
  }

  Future<void> _loadCustomMarkers() async {
    _hospitalIcon = await CustomMarkers.hospitalMarker();
    _userArrowIcon = await CustomMarkers.userArrowMarker();
    if (mounted) setState(() {});
  }

  // ── Auto-activate green corridor ──

  Future<void> _autoActivateCorridor() async {
    final tp = context.read<TripProvider>();
    if (tp.activeTrip?.status == TripStatus.enRoute) {
      setState(() => _corridorActive = true);
      return;
    }
    final success = await tp.startEnRoute();
    if (mounted && success) {
      setState(() => _corridorActive = true);
    }
  }

  // ── Initialization ──

  Future<void> _initNavigation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() { _routeLoading = false; _routeError = 'Location permission denied'; });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      ),
    );
    _currentLocation = LatLng(position.latitude, position.longitude);
    _currentHeading = position.heading;

    final tripProvider = context.read<TripProvider>();
    var trip = tripProvider.activeTrip;

    // If no trip in memory (app restarted mid-ride), fetch from backend
    trip ??= await tripProvider.fetchActiveTrip();
    if (!mounted) return;
    if (trip == null || !trip.status.isActive) {
      setState(() { _routeLoading = false; _routeError = 'No active trip'; });
      return;
    }

    final destination = _getHospitalLocation();
    if (destination == null) {
      setState(() { _routeLoading = false; _routeError = 'No hospital destination'; });
      return;
    }

    final route = await _directionsService.getRoute(origin: _currentLocation!, destination: destination);
    if (!mounted) return;

    if (route == null) {
      setState(() { _routeLoading = false; _routeError = 'Could not fetch route'; });
    } else {
      setState(() {
        _routeInfo = route;
        _remainingDistanceMeters = route.totalDistanceMeters;
        _remainingDurationSeconds = route.totalDurationSeconds;
        _routeLoading = false;
      });
      _fitRouteBounds(route);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _snapToUser();
    }
    _startLocationStreaming();
  }

  void _fitRouteBounds(RouteInfo route) {
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(northeast: route.boundsNortheast, southwest: route.boundsSouthwest), 60));
  }

  void _snapToUser() {
    if (_currentLocation == null || _mapController == null) return;
    setState(() => _isFollowingUser = true);
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _currentLocation!, zoom: 17.5, tilt: 55, bearing: _currentHeading)));
  }

  // ── Location Streaming ──

  void _startLocationStreaming() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10),
    ).listen((position) {
      if (!mounted) return;

      // Skip inaccurate readings (GPS noise)
      if (position.accuracy > 20) return;

      // Small threshold to filter GPS noise when truly stationary.
      final rawSpeedKmh = position.speed * 3.6;
      final isMoving = rawSpeedKmh > 4;
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentSpeed = isMoving ? rawSpeedKmh : 0;
        if (isMoving) _currentLocation = newLocation;
      });

      if (isMoving) {
        _updateCurrentStep(newLocation);
        _checkProximity(newLocation);
        if (_isFollowingUser && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: newLocation, zoom: 17.5, tilt: 55, bearing: _currentHeading)));
        }
      }

      ws.send('/app/trip/${trip.id}/location', {
        'latitude': position.latitude, 'longitude': position.longitude,
        'heading': _currentHeading, 'speed': position.speed, 'accuracy': position.accuracy,
      });
    });
  }

  void _updateCurrentStep(LatLng pos) {
    if (_routeInfo == null) return;
    final steps = _routeInfo!.steps;
    if (_currentStepIndex >= steps.length) return;

    final distToEnd = NavigationHelpers.haversineDistance(pos, steps[_currentStepIndex].endLocation);
    if (distToEnd < 30 && _currentStepIndex < steps.length - 1) {
      setState(() => _currentStepIndex++);
    }

    int remainingDist = 0;
    for (int i = _currentStepIndex; i < steps.length; i++) remainingDist += steps[i].distanceMeters;
    int remainingTime = 0;
    if (_routeInfo!.totalDistanceMeters > 0) {
      remainingTime = (remainingDist / _routeInfo!.totalDistanceMeters * _routeInfo!.totalDurationSeconds).round();
    }
    setState(() { _remainingDistanceMeters = remainingDist; _remainingDurationSeconds = remainingTime; });
  }

  void _checkProximity(LatLng pos) {
    final hospitalLoc = _getHospitalLocation();
    if (hospitalLoc == null) return;
    final distance = NavigationHelpers.haversineDistance(pos, hospitalLoc);
    final near = distance <= _arrivalRadiusMeters;
    if (near != _isNearHospital) {
      setState(() => _isNearHospital = near);
    }
  }

  // ── WebSocket Trip Status ──

  void _subscribeToTripStatus() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}';
    _subscribedTripTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final status = data['status'] as String?;
      if (status == 'EN_ROUTE' && !_corridorActive) {
        setState(() => _corridorActive = true);
      }
      // Trip cancelled — show banner and auto-navigate
      if (status == 'CANCELLED') {
        _showCancellationBanner();
      }
      // Hospital rejected — trip reverted to VITALS
      if (status == 'VITALS') {
        _handleHospitalRejection(data['reason'] as String?);
      }
      debugPrint('Trip status update via WS: $status');
      context.read<TripProvider>().refreshTrip();
    });
  }

  void _showCancellationBanner() {
    if (_showCancelBanner) return;
    setState(() {
      _showCancelBanner = true;
      _cancelCountdown = 3;
    });
    _tickCancelCountdown();
  }

  Future<void> _tickCancelCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted || !_showCancelBanner) return;
      setState(() => _cancelCountdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted) {
      context.read<TripProvider>().clearTrip();
      GoRouter.of(context).go('/driver/dashboard');
    }
  }

  void _handleHospitalRejection(String? reason) {
    final tp = context.read<TripProvider>();
    tp.clearHospitalLock();
    tp.fetchRecommendations();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed),
            const SizedBox(width: 10),
            const Expanded(child: Text('Hospital Rejected')),
          ],
        ),
        content: Text(reason ?? 'The hospital has rejected your request. Please select another hospital.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lifelineGreen,
              foregroundColor: AppColors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              GoRouter.of(context).go('/driver/hospital-select');
            },
            child: const Text('View Alternatives'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _locationSub?.cancel();
    if (_subscribedTripTopic != null) {
      try { context.read<WebSocketService>().unsubscribe(_subscribedTripTopic!); } catch (_) {}
    }
    _mapController?.dispose();
    super.dispose();
  }

  // ── Helpers ──

  LatLng? _getHospitalLocation() {
    final tp = context.read<TripProvider>();
    final hs = tp.handshakeResult;
    final trip = tp.activeTrip;
    if (hs != null && hs.hospitalLatitude != 0) return LatLng(hs.hospitalLatitude, hs.hospitalLongitude);
    if (trip?.hospitalLatitude != null) return LatLng(trip!.hospitalLatitude!, trip.hospitalLongitude!);
    if (tp.selectedHospitalLat != null) return LatLng(tp.selectedHospitalLat!, tp.selectedHospitalLng!);
    return null;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final handshake = tripProvider.handshakeResult;
    final hospitalName = handshake?.hospitalName ?? trip?.hospitalName ?? 'Hospital';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Current navigation step
    RouteStep? currentStep;
    RouteStep? nextStep;
    if (_routeInfo != null && _currentStepIndex < _routeInfo!.steps.length) {
      currentStep = _routeInfo!.steps[_currentStepIndex];
      if (_currentStepIndex + 1 < _routeInfo!.steps.length) {
        nextStep = _routeInfo!.steps[_currentStepIndex + 1];
      }
    }

    // Markers — use custom markers
    final markers = <Marker>{};
    final hospitalLoc = _getHospitalLocation();
    if (hospitalLoc != null) {
      markers.add(Marker(
        markerId: const MarkerId('hospital'),
        position: hospitalLoc,
        icon: _hospitalIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: hospitalName),
      ));
    }

    // Driver arrow — rotates with heading like Google Maps navigation
    if (_currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentLocation!,
        icon: _userArrowIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _currentHeading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
      ));
    }

    // Route polyline — enhanced with dark outline
    final polylines = _routeInfo != null
        ? MapHelpers.createRoutePolyline(_routeInfo!.polylinePoints)
        : <Polyline>{};

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen Google Map ──
          if (AppConfig.enableMaps)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(12.8456, 77.6603),
                zoom: 17.5, tilt: 55, bearing: _currentHeading,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                // Apply dark map style
                MapHelpers.applyMapStyle(controller, isDark);
              },
            )
          else
            Container(color: AppColors.commandDark),

          // ── Turn instruction banner ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: TurnBanner(
              currentStep: currentStep,
              nextStep: nextStep,
              isLoading: _routeLoading,
              error: _routeError,
            ),
          ),

          // ── Recenter FAB ──
          Positioned(
            right: 16, bottom: 260,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _snapToUser,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 4,
              child: Icon(
                _isFollowingUser ? Icons.my_location : Icons.location_searching,
                color: _isFollowingUser ? AppColors.navBlueSoft : AppColors.mediumGray,
                size: 22,
              ),
            ),
          ),

          // ── Trip Cancelled Banner ──
          if (_showCancelBanner)
            Positioned(
              top: 0, left: 0, right: 0, bottom: 0,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cancel, size: 48, color: AppColors.white),
                        const SizedBox(height: 12),
                        const Text(
                          'TRIP CANCELLED',
                          style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Redirecting in $_cancelCountdown...',
                          style: const TextStyle(color: AppColors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Draggable bottom sheet ──
          NavBottomSheet(
            remainingDurationSeconds: _remainingDurationSeconds,
            remainingDistanceMeters: _remainingDistanceMeters,
            currentSpeed: _currentSpeed,
            destinationName: hospitalName,
            destinationIcon: Icons.local_hospital,
            destinationIconColor: _corridorActive ? AppColors.lifelineGreen : AppColors.emergencyRed,
            actions: [
              Expanded(child: MapActionButton(
                icon: Icons.qr_code_2, label: 'QR Handoff', color: AppColors.calmPurple,
                onTap: () => showQrHandoffSheet(context, trip),
              )),
              const SizedBox(width: 10),
              Expanded(child: MapActionButton(
                icon: _isNearHospital ? Icons.check_circle : Icons.flag,
                label: _isNearHospital ? 'Arrive' : 'End Trip',
                color: _isNearHospital ? AppColors.lifelineGreen : AppColors.warmOrange,
                onTap: () => context.go('/driver/arrival'),
              )),
              if (AppConfig.devMode) ...[
                const SizedBox(width: 10),
                Expanded(child: MapActionButton(
                  icon: Icons.bug_report, label: '[DEV] Cancel', color: AppColors.warmOrange,
                  onTap: () async {
                    final tp = context.read<TripProvider>();
                    final nav = GoRouter.of(context);
                    await tp.cancelTrip(reason: 'DEV: Manual cancel');
                    if (context.mounted) nav.go('/driver/dashboard');
                  },
                )),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
