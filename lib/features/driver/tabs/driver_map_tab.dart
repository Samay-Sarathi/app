import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/map_placeholder.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Map tab — dedicated live map view.
class DriverMapTab extends StatefulWidget {
  const DriverMapTab({super.key});

  @override
  State<DriverMapTab> createState() => _DriverMapTabState();
}

class _DriverMapTabState extends State<DriverMapTab> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.map,
            roleColor: AppColors.medicalBlue,
            roleTitle: 'Live Map',
            userName: 'Area Overview',
            badgeStatus: BadgeStatus.synced,
            badgeLabel: 'GPS ACTIVE',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(12.8456, 77.6603),
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      trafficEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        MapHelpers.applyMapStyle(controller, isDark);
                      },
                    )
                  : MapPlaceholder.overview(),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.commandDark.withValues(alpha: 0.9),
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Active', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.7), fontSize: 9)),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warmOrange, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('Idle', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.7), fontSize: 9)),
                const SizedBox(width: 10),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.lifelineGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('Hospital', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.7), fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  value: '3',
                  title: 'Ambulances',
                  icon: Icons.local_shipping,
                  accentColor: AppColors.emergencyRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  value: '2',
                  title: 'Hospitals',
                  icon: Icons.local_hospital,
                  accentColor: AppColors.hospitalTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  value: '14',
                  title: 'Signals',
                  icon: Icons.traffic,
                  accentColor: AppColors.lifelineGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
