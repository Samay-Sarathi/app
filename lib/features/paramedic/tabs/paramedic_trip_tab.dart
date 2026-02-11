import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/map/custom_markers.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/map/map_helpers.dart';
import '../../../shared/widgets/status_badge.dart';

/// Paramedic Trip tab — active trip card + live map.
class ParamedicTripTab extends StatelessWidget {
  const ParamedicTripTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          DashboardHeader(
            roleIcon: Icons.medical_services,
            roleColor: AppColors.hospitalTeal,
            roleTitle: 'Paramedic',
            userName: auth.fullName.isNotEmpty ? auth.fullName : 'Ready',
            badgeStatus: trip != null ? BadgeStatus.active : BadgeStatus.pending,
            badgeLabel: trip != null ? 'ON TRIP' : 'STANDBY',
          ),
          const SizedBox(height: 24),

          if (trip != null && trip.status.isActive) ...[
            // Active trip card
            _ActiveTripCard(trip: trip),
            const SizedBox(height: 16),

            // Live map
            Expanded(
              child: ClipRRect(
                borderRadius: AppSpacing.borderRadiusLg,
                child: _LiveTripMap(trip: trip),
              ),
            ),
          ] else ...[
            // No trip — prompt to scan
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.hospitalTeal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.hospitalTeal),
                    ),
                    const SizedBox(height: 20),
                    Text('No Active Trip', style: AppTypography.heading3.copyWith(color: onSurface)),
                    const SizedBox(height: 8),
                    Text(
                      'Scan a QR code from the driver\'s phone\nto link to an active trip.',
                      style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/paramedic/qr-scan'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.hospitalTeal,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final dynamic trip;
  const _ActiveTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final sevColor = trip.severity >= 7
        ? AppColors.emergencyRed
        : (trip.severity >= 4 ? AppColors.warmOrange : AppColors.softYellow);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border(left: BorderSide(color: sevColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, size: 16, color: sevColor),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.incidentType.label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: onSurface))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: AppSpacing.borderRadiusFull),
                child: Text('SEV ${trip.severity}', style: AppTypography.overline.copyWith(color: sevColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.mediumGray),
            const SizedBox(width: 6),
            Text('Status: ${trip.status.label}', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
          ]),
          if (trip.hospitalName != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.local_hospital, size: 14, color: AppColors.hospitalTeal),
              const SizedBox(width: 6),
              Text(trip.hospitalName!, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
            ]),
          ],
          if (trip.driverName != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.local_shipping, size: 14, color: AppColors.medicalBlue),
              const SizedBox(width: 6),
              Text('Driver: ${trip.driverName}', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _LiveTripMap extends StatefulWidget {
  final dynamic trip;
  const _LiveTripMap({required this.trip});

  @override
  State<_LiveTripMap> createState() => _LiveTripMapState();
}

class _LiveTripMapState extends State<_LiveTripMap> {
  GoogleMapController? _mapController;
  LatLng? _ambulanceLocation;
  String? _subscribedTopic;
  BitmapDescriptor? _ambulanceIcon;
  BitmapDescriptor? _hospitalIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _subscribeToLocation();
  }

  Future<void> _loadMarkers() async {
    _ambulanceIcon = await CustomMarkers.ambulanceMarker();
    _hospitalIcon = await CustomMarkers.hospitalMarker();
    if (mounted) setState(() {});
  }

  void _subscribeToLocation() {
    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${widget.trip.id}/location';
    _subscribedTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() => _ambulanceLocation = LatLng(lat, lng));
        _mapController?.animateCamera(CameraUpdate.newLatLng(_ambulanceLocation!));
      }
    });
  }

  @override
  void dispose() {
    if (_subscribedTopic != null) {
      try { context.read<WebSocketService>().unsubscribe(_subscribedTopic!); } catch (_) {}
    }
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableMaps) {
      return Container(color: AppColors.commandDark);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markers = <Marker>{};
    if (_ambulanceLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: _ambulanceLocation!,
        icon: _ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Ambulance'),
      ));
    }
    if (widget.trip.hospitalLatitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(widget.trip.hospitalLatitude!, widget.trip.hospitalLongitude!),
        icon: _hospitalIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.trip.hospitalName ?? 'Hospital'),
      ));
    }

    final initialTarget = _ambulanceLocation ??
        (widget.trip.hospitalLatitude != null
            ? LatLng(widget.trip.hospitalLatitude!, widget.trip.hospitalLongitude!)
            : LatLng(widget.trip.pickupLatitude, widget.trip.pickupLongitude));

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: true,
      onMapCreated: (c) {
        _mapController = c;
        MapHelpers.applyMapStyle(c, isDark);
      },
    );
  }
}
