import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons.dart';
import '../../widgets/status_badge.dart';

class AmbulanceSyncScreen extends StatefulWidget {
  const AmbulanceSyncScreen({super.key});

  @override
  State<AmbulanceSyncScreen> createState() => _AmbulanceSyncScreenState();
}

class _AmbulanceSyncScreenState extends State<AmbulanceSyncScreen> {
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;
  late final Set<Polyline> _polylines;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('ambulance'),
        position: MapConfig.ambulanceA01,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Ambulance A-01'),
      ),
      Marker(
        markerId: const MarkerId('hospital'),
        position: MapConfig.centralHospital,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Central Hospital'),
      ),
    };
    _polylines = {
      const Polyline(
        polylineId: PolylineId('sync_route'),
        points: MapConfig.ambulanceSyncRoute,
        color: AppColors.lifelineGreen,
        width: 3,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/hospital/alert'),
                    child: Icon(Icons.arrow_back, color: onSurface),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.map, size: 20, color: AppColors.medicalBlue),
                  const SizedBox(width: 8),
                  Text(
                    'ETA: 6 MINS',
                    style: AppTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text('AMBULANCE SYNC', style: AppTypography.heading3.copyWith(color: onSurface)),
              ),
              const SizedBox(height: 16),

              // Map
              SizedBox(
                height: 160,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusLg,
                  child: GoogleMap(
                    initialCameraPosition: MapConfig.syncCamera,
                    markers: _markers,
                    polylines: _polylines,
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
              const SizedBox(height: 16),

              // Triage info
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceMd),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusMd,
                        border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('TRIAGE', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                          const SizedBox(height: 4),
                          Text('LEVEL 1', style: AppTypography.heading3.copyWith(color: AppColors.emergencyRed)),
                          Text('TRAUMA', style: AppTypography.caption.copyWith(color: AppColors.emergencyRed)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceMd),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: AppSpacing.borderRadiusMd,
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        children: [
                          Text('COMPLAINT', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                          const SizedBox(height: 4),
                          Text('GSW/', style: AppTypography.heading3.copyWith(color: onSurface)),
                          Text('Hemorrhage', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live vitals
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusLg,
                  boxShadow: AppSpacing.shadowMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 18, color: AppColors.emergencyRed),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE VITALS',
                          style: AppTypography.overline.copyWith(color: onSurface),
                        ),
                        const Spacer(),
                        const StatusBadge(status: BadgeStatus.active, label: 'LIVE'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _VitalItem(label: 'HR', value: '112', color: AppColors.emergencyRed),
                        _VitalItem(label: 'BP', value: '90/60', color: AppColors.warmOrange),
                        _VitalItem(label: 'SpO2', value: '94%', color: AppColors.medicalBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Readiness
              Row(
                children: [
                  Text('READINESS:', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                  const SizedBox(width: 12),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < 2 ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 22,
                        color: i < 2 ? AppColors.lifelineGreen : AppColors.lightGray,
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text('2/4', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                ],
              ),

              const Spacer(),

              PrimaryButton(
                label: 'ACKNOWLEDGE INTAKE',
                icon: Icons.check,
                onPressed: () => context.go('/hospital/capacity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _VitalItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.vitalM.copyWith(color: color, fontSize: 20),
        ),
      ],
    );
  }
}
