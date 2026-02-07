import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/services/websocket_service.dart';
import '../../widgets/info_card.dart';
import '../../core/widgets/map_placeholder.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;
  late final Set<Polyline> _polylines;

  // Location streaming
  StreamSubscription<Position>? _locationSub;
  String? _subscribedTripTopic;
  double _currentSpeed = 0;

  @override
  void initState() {
    super.initState();
    if (AppConfig.enableMaps) {
      _markers = {
        Marker(
          markerId: const MarkerId('hospital'),
          position: MapConfig.centralHospital,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Central Hospital'),
        ),
        Marker(
          markerId: const MarkerId('user'),
          position: MapConfig.userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      };
      _polylines = {
        const Polyline(
          polylineId: PolylineId('route'),
          points: MapConfig.routeToHospital,
          color: AppColors.lifelineGreen,
          width: 5,
        ),
      };
    } else {
      _markers = {};
      _polylines = {};
    }
    _startLocationStreaming();
    _subscribeToTripStatus();
  }

  /// Start streaming GPS location via WebSocket.
  Future<void> _startLocationStreaming() async {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;

    // Check & request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied');
      return;
    }

    final ws = context.read<WebSocketService>();

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters — only send when moved
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _currentSpeed = position.speed * 3.6); // m/s → km/h

      // Send via WebSocket STOMP
      ws.send('/app/trip/${trip.id}/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
      });
    });
  }

  /// Subscribe to trip status changes via WebSocket.
  void _subscribeToTripStatus() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;

    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}';
    _subscribedTripTopic = topic;

    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final status = data['status'] as String?;
      if (status != null) {
        debugPrint('Trip status update via WS: $status');
        // Refresh trip state from provider
        context.read<TripProvider>().refreshTrip();
      }
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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _showQrCode(BuildContext context, dynamic trip) async {
    if (trip?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active trip found'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    final tripId = trip.id;
    final tripProvider = context.read<TripProvider>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch QR token from backend
    final qrTokenData = await tripProvider.getQrToken(tripId);
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading

    if (qrTokenData == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Failed to get QR token'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    final paramedicToken = qrTokenData['paramedicToken'] as String;
    final expiresAt = qrTokenData['expiresAt'] as String?;
    
    // Format expiry time if available
    String? expiryDisplay;
    if (expiresAt != null) {
      try {
        final expiry = DateTime.parse(expiresAt);
        final now = DateTime.now();
        final diff = expiry.difference(now);
        if (diff.inMinutes > 0) {
          expiryDisplay = '${diff.inMinutes} min';
        } else {
          expiryDisplay = 'Expired';
        }
      } catch (_) {
        expiryDisplay = null;
      }
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        decoration: const BoxDecoration(
          color: AppColors.commandDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Paramedic Handoff QR',
              style: AppTypography.heading3.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Have the paramedic scan this code to sync trip details',
              style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            if (expiryDisplay != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: expiryDisplay == 'Expired' 
                      ? AppColors.emergencyRed.withValues(alpha: 0.1)
                      : AppColors.warmOrange.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Expires in: $expiryDisplay',
                  style: AppTypography.caption.copyWith(
                    color: expiryDisplay == 'Expired' 
                        ? AppColors.emergencyRed
                        : AppColors.warmOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: QrImageView(
                data: paramedicToken,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: AppColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.commandDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.commandDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Trip ID display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number, size: 16, color: AppColors.lifelineGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Trip: ${tripId.toString().substring(0, tripId.toString().length.clamp(0, 8))}...',
                    style: AppTypography.vitalS.copyWith(color: AppColors.lifelineGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Close button
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Text(
                  'Close',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: AppColors.white),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final handshake = tripProvider.handshakeResult;
    final etaMin = trip?.etaSeconds != null
        ? (trip!.etaSeconds! / 60).ceil()
        : 0;
    final etaDisplay = etaMin > 0 ? '$etaMin:00' : '—';

    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: AppSpacing.spaceXs),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/driver/hospital-select'),
                    child: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  if (handshake != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        handshake.hospitalName,
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final success = await context.read<TripProvider>().startEnRoute();
                      if (success && context.mounted) {
                        context.go('/driver/green-corridor');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lifelineGreen,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 16, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Activate Corridor',
                            style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: AppConfig.enableMaps
                  ? ClipRRect(
                      borderRadius: AppSpacing.borderRadiusLg,
                      child: GoogleMap(
                        initialCameraPosition: MapConfig.navigationCamera,
                        markers: _markers,
                        polylines: _polylines,
                        style: MapConfig.darkMapStyle,
                        liteModeEnabled: false,
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
                    )
                  : MapPlaceholder.navigation(),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: DarkInfoCard(value: etaDisplay, title: 'ETA (min)', accentColor: AppColors.lifelineGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DarkInfoCard(value: _currentSpeed > 0 ? '${_currentSpeed.round()}' : '—', title: 'Speed (kph)', accentColor: AppColors.medicalBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Direction card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
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
                    'Turn Right in 500m',
                    style: AppTypography.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // QR Code button for paramedic handoff
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            child: GestureDetector(
              onTap: () => _showQrCode(context, trip),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.calmPurple.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(color: AppColors.calmPurple.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, color: AppColors.calmPurple, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Show QR Code for Paramedic',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.calmPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
