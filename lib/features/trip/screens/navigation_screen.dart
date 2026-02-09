import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/models/route_info.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../shared/widgets/map/turn_banner.dart';
import '../../../shared/widgets/map/nav_bottom_panel.dart';
import '../../../shared/widgets/map/map_action_button.dart';
import '../widgets/qr_handoff_sheet.dart';

/// Unified navigation + green corridor screen.
///
/// When the driver reaches this screen, the trip automatically transitions
/// to EN_ROUTE and the green corridor activates — notifying police and
/// hospitals along the route. No manual "Corridor" button needed.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSub;
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

  // Green corridor state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _corridorActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initNavigation();
    _subscribeToTripStatus();
    _autoActivateCorridor();
  }

  // ── Auto-activate green corridor ──

  Future<void> _autoActivateCorridor() async {
    final tp = context.read<TripProvider>();
    // Already EN_ROUTE — corridor is active
    if (tp.activeTrip?.status == 'EN_ROUTE') {
      setState(() => _corridorActive = true);
      return;
    }
    // Trigger EN_ROUTE transition
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    _currentLocation = LatLng(position.latitude, position.longitude);
    _currentHeading = position.heading;

    final tripProvider = context.read<TripProvider>();
    final trip = tripProvider.activeTrip;
    if (trip == null) {
      setState(() { _routeLoading = false; _routeError = 'No active trip'; });
      return;
    }

    // Hospital coordinates: handshake > trip > provider cache
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((position) {
      if (!mounted) return;
      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
        _currentSpeed = position.speed * 3.6;
        _currentHeading = position.heading;
      });
      _updateCurrentStep(newLocation);
      if (_isFollowingUser && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: newLocation, zoom: 17.5, tilt: 55, bearing: position.heading)));
      }
      ws.send('/app/trip/${trip.id}/location', {
        'latitude': position.latitude, 'longitude': position.longitude,
        'heading': position.heading, 'speed': position.speed, 'accuracy': position.accuracy,
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
      debugPrint('Trip status update via WS: $status');
      context.read<TripProvider>().refreshTrip();
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    if (_subscribedTripTopic != null) {
      try { context.read<WebSocketService>().unsubscribe(_subscribedTripTopic!); } catch (_) {}
    }
    _pulseController.dispose();
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

    // Current navigation step
    RouteStep? currentStep;
    RouteStep? nextStep;
    if (_routeInfo != null && _currentStepIndex < _routeInfo!.steps.length) {
      currentStep = _routeInfo!.steps[_currentStepIndex];
      if (_currentStepIndex + 1 < _routeInfo!.steps.length) {
        nextStep = _routeInfo!.steps[_currentStepIndex + 1];
      }
    }

    // Markers
    final markers = <Marker>{};
    final hospitalLoc = _getHospitalLocation();
    if (hospitalLoc != null) {
      markers.add(Marker(
        markerId: const MarkerId('hospital'),
        position: hospitalLoc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: hospitalName),
      ));
    }

    // Route polyline
    final polylines = <Polyline>{};
    if (_routeInfo != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routeInfo!.polylinePoints,
        color: const Color(0xFF4285F4),
        width: 5,
      ));
    }

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
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
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

          // ── Green corridor status chip ──
          if (_corridorActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + (currentStep != null ? 110 : 8),
              left: 0, right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.commandDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.lifelineGreen.withValues(alpha: _pulseAnimation.value),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.lifelineGreen.withValues(alpha: _pulseAnimation.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GREEN CORRIDOR ACTIVE',
                            style: AppTypography.overline.copyWith(
                              color: AppColors.lifelineGreen, fontSize: 11, letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Recenter FAB ──
          Positioned(
            right: 16, bottom: 260,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _snapToUser,
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(
                _isFollowingUser ? Icons.my_location : Icons.location_searching,
                color: _isFollowingUser ? const Color(0xFF4285F4) : AppColors.mediumGray,
                size: 22,
              ),
            ),
          ),

          // ── Bottom panel ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: NavBottomPanel(
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
                  icon: Icons.flag, label: 'End Trip', color: AppColors.warmOrange,
                  onTap: () => context.go('/driver/triage'),
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
          ),
        ],
      ),
    );
  }
}
