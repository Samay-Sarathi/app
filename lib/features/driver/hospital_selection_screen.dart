import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons.dart';

class HospitalSelectionScreen extends StatefulWidget {
  const HospitalSelectionScreen({super.key});

  @override
  State<HospitalSelectionScreen> createState() => _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> {
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('recommended_hospital'),
        position: MapConfig.centralHospital,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Central Medical Center', snippet: 'Recommended'),
      ),
      Marker(
        markerId: const MarkerId('other_hospital'),
        position: MapConfig.cityHospital,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'City Hospital'),
      ),
      Marker(
        markerId: const MarkerId('user'),
        position: MapConfig.userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    return Scaffold(
      body: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/driver/severity'),
                    child: Icon(Icons.arrow_back, color: onSurface),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.bar_chart, size: 20, color: AppColors.medicalBlue),
                  const SizedBox(width: 8),
                  Text(
                    '64 Available ER Beds',
                    style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface),
                  ),
                ],
              ),
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: MapConfig.overviewCamera,
              markers: _markers,
              liteModeEnabled: true,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          // Hospital info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Color(0x1A000000), offset: Offset(0, -4), blurRadius: 15),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Central Medical Center', style: AppTypography.heading3.copyWith(color: onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.lifelineGreen),
                          const SizedBox(width: 4),
                          Text(
                            'RECOMMENDED',
                            style: AppTypography.overline.copyWith(color: AppColors.lifelineGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(icon: Icons.timer, label: '4m Wait'),
                    const SizedBox(width: 16),
                    _InfoChip(icon: Icons.bed, label: '12 Beds'),
                    const Spacer(),
                    Text('2.4 km', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Select Hospital →',
                  onPressed: () => context.go('/driver/navigation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.mediumGray),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }
}
