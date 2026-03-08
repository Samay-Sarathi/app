import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/trip.dart';
import '../../../core/map/custom_markers.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/map_placeholder.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../../../shared/widgets/status_badge.dart';

/// Police Map tab — live ambulance tracking with officer's own location.
class PoliceMapTab extends StatefulWidget {
  final List<Trip> trips;
  final int corridorCount;
  final Map<String, LatLng> ambulanceLocations;
  final LatLng? officerLocation;

  const PoliceMapTab({
    super.key,
    required this.trips,
    required this.corridorCount,
    this.ambulanceLocations = const {},
    this.officerLocation,
  });

  @override
  State<PoliceMapTab> createState() => _PoliceMapTabState();
}

class _PoliceMapTabState extends State<PoliceMapTab> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _ambulanceIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    _ambulanceIcon = await CustomMarkers.ambulanceMarker();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng _getMarkerPosition(Trip t) {
    // Use live WebSocket location if available, fallback to pickup location
    return widget.ambulanceLocations[t.id] ??
        LatLng(t.pickupLatitude, t.pickupLongitude);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLiveData = widget.ambulanceLocations.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.map,
            roleColor: AppColors.calmPurple,
            roleTitle: 'Jurisdiction Map',
            userName: '${widget.trips.length} ambulances tracked',
            badgeStatus: hasLiveData ? BadgeStatus.active : BadgeStatus.synced,
            badgeLabel: hasLiveData ? 'LIVE' : 'GPS ACTIVE',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: widget.officerLocation != null
                          ? CameraPosition(target: widget.officerLocation!, zoom: 14)
                          : widget.trips.isNotEmpty
                              ? CameraPosition(
                                  target: _getMarkerPosition(widget.trips.first),
                                  zoom: 13,
                                )
                              : const CameraPosition(target: LatLng(12.8456, 77.6603), zoom: 14.0),
                      markers: {
                        for (final t in widget.trips)
                          Marker(
                            markerId: MarkerId(t.id),
                            position: _getMarkerPosition(t),
                            icon: _ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                              t.severity >= 7 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(
                              title: t.driverName ?? 'Ambulance',
                              snippet: '${t.incidentType.label} — SEV ${t.severity}',
                            ),
                          ),
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      trafficEnabled: true,
                      onMapCreated: (c) {
                        _mapController = c;
                        MapHelpers.applyMapStyle(c, isDark);
                      },
                    )
                  : MapPlaceholder.overview(),
            ),
          ),
          const SizedBox(height: 12),
          // Active ambulances summary strip
          if (widget.trips.isNotEmpty) ...[
            Text('AMBULANCES ON MAP', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.trips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final t = widget.trips[index];
                  final sColor = t.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;
                  final hasLive = widget.ambulanceLocations.containsKey(t.id);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: sColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping, size: 16, color: sColor),
                        if (hasLive)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(color: AppColors.lifelineGreen, shape: BoxShape.circle),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.driverName ?? 'Ambulance', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: sColor)),
                            Text(
                              hasLive ? 'LIVE' : (t.etaSeconds != null ? 'ETA ${(t.etaSeconds! / 60).ceil()}m' : 'ETA —'),
                              style: AppTypography.overline.copyWith(
                                color: hasLive ? AppColors.lifelineGreen : AppColors.mediumGray,
                                fontSize: 9,
                                fontWeight: hasLive ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Corridor status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lifelineGreen.withValues(alpha: 0.08),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.traffic, color: AppColors.lifelineGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${widget.corridorCount} green corridors active',
                  style: AppTypography.caption.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
