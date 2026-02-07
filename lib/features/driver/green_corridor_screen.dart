import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/services/websocket_service.dart';
import '../../core/widgets/map_placeholder.dart';

class GreenCorridorScreen extends StatefulWidget {
  const GreenCorridorScreen({super.key});

  @override
  State<GreenCorridorScreen> createState() => _GreenCorridorScreenState();
}

class _GreenCorridorScreenState extends State<GreenCorridorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;
  late final Set<Polyline> _polylines;

  // Location streaming
  StreamSubscription<Position>? _locationSub;
  String? _subscribedTripTopic;
  double _currentSpeed = 0;
  double _distanceKm = 1.8; // default

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
    if (AppConfig.enableMaps) {
      _markers = {
        Marker(
          markerId: const MarkerId('hospital'),
          position: MapConfig.centralHospital,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Central Hospital'),
        ),
        Marker(
          markerId: const MarkerId('ambulance'),
          position: MapConfig.userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Ambulance'),
        ),
      };
      _polylines = {
        Polyline(
          polylineId: const PolylineId('corridor_route'),
          points: MapConfig.routeToHospital,
          color: AppColors.lifelineGreen,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    } else {
      _markers = {};
      _polylines = {};
    }
    _startLocationStreaming();
    _subscribeToTripStatus();
  }

  Future<void> _startLocationStreaming() async {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final ws = context.read<WebSocketService>();
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _currentSpeed = position.speed * 3.6);
      ws.send('/app/trip/${trip.id}/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
      });
    });
  }

  void _subscribeToTripStatus() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}';
    _subscribedTripTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      context.read<TripProvider>().refreshTrip();
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    if (_subscribedTripTopic != null) {
      try {
        context.read<WebSocketService>().unsubscribe(_subscribedTripTopic!);
      } catch (_) {}
    }
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final etaMin = trip?.etaSeconds != null
        ? (trip!.etaSeconds! / 60).ceil()
        : 8;

    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green corridor header
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lifelineGreen.withValues(alpha: _pulseAnimation.value * 0.2),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(
                        color: AppColors.lifelineGreen.withValues(alpha: _pulseAnimation.value),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.lifelineGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'GREEN CORRIDOR ACTIVE',
                          style: AppTypography.overline.copyWith(
                            color: AppColors.lifelineGreen,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Map area
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusLg,
                  child: AppConfig.enableMaps
                      ? GoogleMap(
                          initialCameraPosition: MapConfig.navigationCamera,
                          markers: _markers,
                          polylines: _polylines,
                          style: MapConfig.darkMapStyle,
                          liteModeEnabled: true,
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        )
                      : MapPlaceholder.corridor(),
                ),
              ),
              const SizedBox(height: 16),

              // ETA and distance
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARRIVING IN',
                          style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$etaMin MIN',
                          style: AppTypography.heading1.copyWith(color: AppColors.lifelineGreen),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'SPEED',
                          style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentSpeed > 0 ? '${_currentSpeed.round()}' : '—',
                          style: AppTypography.heading1.copyWith(color: AppColors.medicalBlue),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DISTANCE',
                          style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                        '${_distanceKm.toStringAsFixed(1)} KM',
                          style: AppTypography.heading1.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Direction
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.medicalBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.turn_right, color: AppColors.medicalBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Turn Right on Main Ave',
                        style: AppTypography.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Signal status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.traffic, color: AppColors.lifelineGreen, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Next Signal: ',
                      style: AppTypography.bodyS.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                    Text(
                      'GREEN',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.lifelineGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.lifelineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // End emergency
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Navigate to triage (trip stays active — hospital will complete it)
                    context.go('/driver/triage');
                  },
                  icon: const Icon(Icons.warning_amber, size: 20),
                  label: const Text('End Emergency Case', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmOrange,
                    side: const BorderSide(color: AppColors.warmOrange),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
