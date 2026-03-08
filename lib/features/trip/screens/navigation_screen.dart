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

  // Smooth marker animation
  Timer? _markerAnimTimer;
  LatLng? _animStartLocation;
  LatLng? _animEndLocation;
  int _animStep = 0;
  static const int _animTotalSteps = 20;
  static const Duration _animStepDuration = Duration(milliseconds: 50);

  // Trip cancellation banner
  bool _showCancelBanner = false;
  int _cancelCountdown = 3;

  // Near hospital banner
  bool _showNearHospitalBanner = false;
  Timer? _nearHospitalBannerTimer;

  // Police officer locations (from WebSocket)
  final Map<String, _PoliceOfficerLocation> _policeLocations = {};
  String? _subscribedPoliceTopic;
  int _routeClearedCount = 0;
  bool _showRouteClearedBanner = false;
  Timer? _routeClearedBannerTimer;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _startCompass();
    _initNavigation();
    _subscribeToTripStatus();
    _subscribeToPoliceLocations();
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
        if (_isFollowingUser &&
            _mapController != null &&
            _currentLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 17.5,
                tilt: 55,
                bearing: heading,
              ),
            ),
          );
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
      setState(() {
        _routeLoading = false;
        _routeError = 'Location permission denied';
      });
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
    // tripProvider captured before await to avoid BuildContext async gap
    trip ??= await tripProvider.fetchActiveTrip();
    if (!mounted) return;
    if (trip == null || !trip.status.isActive) {
      setState(() {
        _routeLoading = false;
        _routeError = 'No active trip';
      });
      return;
    }

    final destination = _getHospitalLocation();
    if (destination == null) {
      setState(() {
        _routeLoading = false;
        _routeError = 'No hospital destination';
      });
      return;
    }

    final route = await _directionsService.getRoute(
      origin: _currentLocation!,
      destination: destination,
    );
    if (!mounted) return;

    if (route == null) {
      setState(() {
        _routeLoading = false;
        _routeError = 'Could not fetch route';
      });
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
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          northeast: route.boundsNortheast,
          southwest: route.boundsSouthwest,
        ),
        60,
      ),
    );
  }

  void _snapToUser() {
    if (_currentLocation == null || _mapController == null) return;
    setState(() => _isFollowingUser = true);
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 17.5,
          tilt: 55,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  // ── Location Streaming ──

  void _startLocationStreaming() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();

    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
          ),
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
          });

          if (isMoving) {
            _animateMarkerTo(newLocation);
            _updateCurrentStep(newLocation);
            _checkProximity(newLocation);
          }

          ws.send('/app/trip/${trip.id}/location', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': _currentHeading,
            'speed': position.speed,
            'accuracy': position.accuracy,
          });
        });
  }

  /// Smoothly interpolate the driver marker from current to new position.
  void _animateMarkerTo(LatLng destination) {
    _markerAnimTimer?.cancel();
    _animStartLocation = _currentLocation ?? destination;
    _animEndLocation = destination;
    _animStep = 0;

    _markerAnimTimer = Timer.periodic(_animStepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _animStep++;
      // Ease-out curve for natural deceleration
      final t = _animStep / _animTotalSteps;
      final eased = 1 - (1 - t) * (1 - t); // quadratic ease-out

      final lat = _animStartLocation!.latitude +
          (destination.latitude - _animStartLocation!.latitude) * eased;
      final lng = _animStartLocation!.longitude +
          (destination.longitude - _animStartLocation!.longitude) * eased;
      final interpolated = LatLng(lat, lng);

      setState(() => _currentLocation = interpolated);

      if (_isFollowingUser && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: interpolated,
              zoom: 17.5,
              tilt: 55,
              bearing: _currentHeading,
            ),
          ),
        );
      }

      if (_animStep >= _animTotalSteps) {
        timer.cancel();
        setState(() => _currentLocation = destination);
      }
    });
  }

  void _updateCurrentStep(LatLng pos) {
    if (_routeInfo == null) return;
    final steps = _routeInfo!.steps;
    if (_currentStepIndex >= steps.length) return;

    final distToEnd = NavigationHelpers.haversineDistance(
      pos,
      steps[_currentStepIndex].endLocation,
    );
    if (distToEnd < 30 && _currentStepIndex < steps.length - 1) {
      setState(() => _currentStepIndex++);
    }

    int remainingDist = 0;
    for (int i = _currentStepIndex; i < steps.length; i++) {
      remainingDist += steps[i].distanceMeters;
    }
    int remainingTime = 0;
    if (_routeInfo!.totalDistanceMeters > 0) {
      remainingTime =
          (remainingDist /
                  _routeInfo!.totalDistanceMeters *
                  _routeInfo!.totalDurationSeconds)
              .round();
    }
    setState(() {
      _remainingDistanceMeters = remainingDist;
      _remainingDurationSeconds = remainingTime;
    });
  }

  void _checkProximity(LatLng pos) {
    final hospitalLoc = _getHospitalLocation();
    if (hospitalLoc == null) return;
    final distance = NavigationHelpers.haversineDistance(pos, hospitalLoc);
    final near = distance <= _arrivalRadiusMeters;
    if (near != _isNearHospital) {
      setState(() => _isNearHospital = near);
      if (near) _showNearHospitalBannerWithAutoDismiss();
    }
  }

  void _showNearHospitalBannerWithAutoDismiss() {
    _nearHospitalBannerTimer?.cancel();
    setState(() => _showNearHospitalBanner = true);
    _nearHospitalBannerTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _showNearHospitalBanner = false);
    });
  }

  // ── Police Location Tracking ──

  void _subscribeToPoliceLocations() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}/police';
    _subscribedPoliceTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      if (type == 'POLICE_LOCATION') {
        final officerId = data['officerId'] as String? ?? '';
        final lat = (data['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0;
        final name = data['officerName'] as String? ?? 'Officer';
        final status = data['status'] as String? ?? 'ACKNOWLEDGED';
        if (lat != 0 && lng != 0) {
          setState(() {
            _policeLocations[officerId] = _PoliceOfficerLocation(
              officerId: officerId,
              name: name,
              position: LatLng(lat, lng),
              status: status,
            );
          });
        }
      }
    });
  }

  void _handleRouteClearedFromWS(Map<String, dynamic> data) {
    final officerName = data['officerName'] as String? ?? 'An officer';
    setState(() {
      _routeClearedCount++;
      _showRouteClearedBanner = true;
    });
    _routeClearedBannerTimer?.cancel();
    _routeClearedBannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showRouteClearedBanner = false);
    });
    debugPrint('Route cleared by $officerName');
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
      // Trip arrived (manual confirm went through from another device/session)
      if (status == 'ARRIVED') {
        context.go('/driver/arrival');
      }

      // Near hospital — show banner prompting driver to confirm arrival
      final type = data['type'] as String?;
      if (type == 'NEAR_HOSPITAL' && !_showNearHospitalBanner) {
        _showNearHospitalBannerWithAutoDismiss();
      }
      if (type == 'ROUTE_CLEARED') {
        _handleRouteClearedFromWS(data);
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
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.emergencyRed,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Hospital Rejected')),
          ],
        ),
        content: Text(
          reason ??
              'The hospital has rejected your request. Please select another hospital.',
        ),
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
    _nearHospitalBannerTimer?.cancel();
    _routeClearedBannerTimer?.cancel();
    _markerAnimTimer?.cancel();
    _compassSub?.cancel();
    _locationSub?.cancel();
    try {
      final ws = context.read<WebSocketService>();
      if (_subscribedTripTopic != null) ws.unsubscribe(_subscribedTripTopic!);
      if (_subscribedPoliceTopic != null) ws.unsubscribe(_subscribedPoliceTopic!);
    } catch (_) {}
    _mapController?.dispose();
    super.dispose();
  }

  // ── Helpers ──

  LatLng? _getHospitalLocation() {
    final tp = context.read<TripProvider>();
    final hs = tp.handshakeResult;
    final trip = tp.activeTrip;
    if (hs != null && hs.hospitalLatitude != 0)
      return LatLng(hs.hospitalLatitude, hs.hospitalLongitude);
    if (trip?.hospitalLatitude != null)
      return LatLng(trip!.hospitalLatitude!, trip.hospitalLongitude!);
    if (tp.selectedHospitalLat != null)
      return LatLng(tp.selectedHospitalLat!, tp.selectedHospitalLng!);
    return null;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final handshake = tripProvider.handshakeResult;
    final hospitalName =
        handshake?.hospitalName ?? trip?.hospitalName ?? 'Hospital';
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
      markers.add(
        Marker(
          markerId: const MarkerId('hospital'),
          position: hospitalLoc,
          icon:
              _hospitalIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: hospitalName),
        ),
      );
    }

    // Driver arrow — rotates with heading like Google Maps navigation
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentLocation!,
          icon:
              _userArrowIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: _currentHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Police officer markers — small and subtle
    for (final entry in _policeLocations.entries) {
      final officer = entry.value;
      markers.add(
        Marker(
          markerId: MarkerId('police_${officer.officerId}'),
          position: officer.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          alpha: 0.7,
          infoWindow: InfoWindow(
            title: officer.name,
            snippet: officer.status == 'CLEARED' ? 'Route Cleared' : 'On Duty',
          ),
          zIndexInt: 1,
        ),
      );
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
                zoom: 17.5,
                tilt: 55,
                bearing: _currentHeading,
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
            top: 0,
            left: 0,
            right: 0,
            child: TurnBanner(
              currentStep: currentStep,
              nextStep: nextStep,
              isLoading: _routeLoading,
              error: _routeError,
            ),
          ),

          // ── Recenter FAB ──
          Positioned(
            right: 16,
            bottom: 260,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _snapToUser,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 4,
              child: Icon(
                _isFollowingUser ? Icons.my_location : Icons.location_searching,
                color: _isFollowingUser
                    ? AppColors.navBlueSoft
                    : AppColors.mediumGray,
                size: 22,
              ),
            ),
          ),

          // ── Route Cleared Banner ──
          if (_showRouteClearedBanner && !_showCancelBanner)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.calmPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_routeClearedCount officer${_routeClearedCount > 1 ? 's' : ''} cleared the route',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Near Hospital Banner (above bottom sheet) ──
          if (_showNearHospitalBanner && !_showCancelBanner)
            Positioned(
              bottom: 220,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => context.go('/driver/arrival'),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.lifelineGreen,
                          AppColors.lifelineGreen.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital, color: AppColors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Approaching Hospital',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap to confirm arrival',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Arrive',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Trip Cancelled Overlay ──
          if (_showCancelBanner)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showCancelBanner ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 44,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Trip Cancelled',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Returning to dashboard in $_cancelCountdown...',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
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
            destinationIconColor: _corridorActive
                ? AppColors.lifelineGreen
                : AppColors.emergencyRed,
            actions: [
              Expanded(
                child: MapActionButton(
                  icon: Icons.qr_code_2,
                  label: 'QR Handoff',
                  color: AppColors.calmPurple,
                  onTap: () => showQrHandoffSheet(context, trip),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MapActionButton(
                  icon: _isNearHospital ? Icons.check_circle : Icons.flag,
                  label: _isNearHospital ? 'Confirm\nArrival' : 'End Trip',
                  color: _isNearHospital
                      ? AppColors.lifelineGreen
                      : AppColors.warmOrange,
                  glowing: _isNearHospital,
                  onTap: () => context.go('/driver/arrival'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Holds a police officer's live location for map display.
class _PoliceOfficerLocation {
  final String officerId;
  final String name;
  final LatLng position;
  final String status;

  const _PoliceOfficerLocation({
    required this.officerId,
    required this.name,
    required this.position,
    required this.status,
  });
}
