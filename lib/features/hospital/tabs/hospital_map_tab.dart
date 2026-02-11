import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/hospital_provider.dart';
import '../../../core/models/trip.dart';
import '../../../core/map/custom_markers.dart';
import '../../../shared/widgets/map_placeholder.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/hospital_shared_widgets.dart';

/// Hospital Map tab — live ambulance tracking with custom markers.
class HospitalMapTab extends StatefulWidget {
  const HospitalMapTab({super.key});

  @override
  State<HospitalMapTab> createState() => _HospitalMapTabState();
}

class _HospitalMapTabState extends State<HospitalMapTab> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _hospitalIcon;
  BitmapDescriptor? _ambulanceIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().fetchIncomingTrips();
    });
  }

  Future<void> _loadMarkers() async {
    _hospitalIcon = await CustomMarkers.hospitalMarker();
    _ambulanceIcon = await CustomMarkers.ambulanceMarker();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  LatLng _hospitalCenter(HospitalProvider hp) {
    final hb = hp.heartbeat;
    if (hb != null && hb.latitude != 0) return LatLng(hb.latitude, hb.longitude);
    return const LatLng(12.8456, 77.6603);
  }

  Set<Marker> _buildMarkers(List<Trip> trips) {
    final markers = <Marker>{};
    if (!AppConfig.enableMaps) return markers;

    final hp = context.read<HospitalProvider>();
    final hb = hp.heartbeat;
    if (hb != null && hb.latitude != 0) {
      markers.add(Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(hb.latitude, hb.longitude),
        icon: _hospitalIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: hb.name.isNotEmpty ? hb.name : 'Hospital'),
      ));
    }

    for (final trip in trips) {
      markers.add(Marker(
        markerId: MarkerId(trip.id),
        position: LatLng(trip.pickupLatitude, trip.pickupLongitude),
        icon: _ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(
          trip.severity >= 7 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: trip.driverName ?? 'Ambulance',
          snippet: '${trip.incidentType.label} — SEV ${trip.severity}',
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HospitalProvider>();
    final trips = hp.incomingTrips;
    final markers = _buildMarkers(trips);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.local_shipping,
            roleColor: AppColors.emergencyRed,
            roleTitle: 'Ambulance Tracking',
            userName: '${trips.length} incoming',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'LIVE',
          ),
          const SizedBox(height: 16),

          // Map — enlarged from 250px
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _hospitalCenter(hp),
                        zoom: 14.0,
                      ),
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
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
          const SizedBox(height: 16),

          // Ambulance list header
          Row(
            children: [
              Text('Incoming Ambulances', style: AppTypography.bodyL.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text('${trips.length}',
                    style: AppTypography.caption.copyWith(color: AppColors.emergencyRed, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ambulance cards
          Expanded(
            flex: 2,
            child: trips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: AppColors.lifelineGreen.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('No incoming ambulances', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: trips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      final etaMin = trip.etaSeconds != null ? (trip.etaSeconds! / 60).ceil() : 0;
                      return AmbulanceTrackerCard(
                        driverName: trip.driverName ?? 'Ambulance',
                        tripIdShort: trip.id.substring(0, trip.id.length.clamp(0, 8)),
                        incidentLabel: trip.incidentType.label,
                        severity: trip.severity,
                        hospitalName: trip.hospitalName,
                        statusLabel: trip.status.name.toUpperCase().replaceAll('_', ' '),
                        etaMinutes: etaMin,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
