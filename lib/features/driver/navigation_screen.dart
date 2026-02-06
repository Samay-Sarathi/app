import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _showQrCode(BuildContext context, dynamic trip) {
    final tripId = trip?.id ?? 'N/A';
    final qrData = 'lifeline://trip/$tripId';

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
            const SizedBox(height: 24),
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: QrImageView(
                data: qrData,
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
                        liteModeEnabled: true,
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
                  child: DarkInfoCard(value: '—', title: 'Speed (kph)', accentColor: AppColors.medicalBlue),
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
