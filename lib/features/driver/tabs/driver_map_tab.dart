import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/map_placeholder.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Map tab — dedicated live map view with GPS status footer.
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
    final isOnline = context.watch<ConnectivityService>().isOnline;

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
            badgeStatus: isOnline ? BadgeStatus.synced : BadgeStatus.offline,
            badgeLabel: isOnline ? 'GPS ACTIVE' : 'OFFLINE',
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
          // GPS status footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: isOnline
                      ? AppColors.lifelineGreen
                      : AppColors.emergencyRed,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'GPS Active — High Accuracy' : 'GPS — No Connection',
                  style: AppTypography.caption.copyWith(
                    color: isOnline
                        ? AppColors.lifelineGreen
                        : AppColors.emergencyRed,
                  ),
                ),
                const Spacer(),
                Icon(Icons.traffic, size: 14,
                    color: AppColors.mediumGray.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Traffic layer on',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
