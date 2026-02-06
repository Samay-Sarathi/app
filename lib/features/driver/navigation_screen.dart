import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/info_card.dart';

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
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/driver/green-corridor'),
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
              child: ClipRRect(
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
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: DarkInfoCard(value: '2:15', title: 'ETA (min)', accentColor: AppColors.lifelineGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DarkInfoCard(value: '92', title: 'Speed (kph)', accentColor: AppColors.medicalBlue),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
