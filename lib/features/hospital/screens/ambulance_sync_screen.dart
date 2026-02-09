import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/hospital_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/triage_service.dart';
import '../../../core/models/triage_data.dart';
import '../../../core/models/trip.dart';
import '../../../shared/widgets/map_placeholder.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/status_badge.dart';

class AmbulanceSyncScreen extends StatefulWidget {
  const AmbulanceSyncScreen({super.key});

  @override
  State<AmbulanceSyncScreen> createState() => _AmbulanceSyncScreenState();
}

class _AmbulanceSyncScreenState extends State<AmbulanceSyncScreen> {
  GoogleMapController? _mapController;

  // Live vitals from WebSocket
  final TriageService _triageService = TriageService();
  TriageData? _latestVitals;
  String? _vitalsTopic;
  String? _locationTopic;
  double? _ambulanceLat;
  double? _ambulanceLng;

  @override
  void initState() {
    super.initState();
    _initLiveData();
  }

  Future<void> _initLiveData() async {
    final hp = context.read<HospitalProvider>();
    final incomingTrip = hp.incomingTrips.isNotEmpty ? hp.incomingTrips.first : null;
    if (incomingTrip == null) return;

    final tripId = incomingTrip.id;

    // Fetch latest vitals via REST
    try {
      _latestVitals = await _triageService.getLatestVitals(tripId);
      if (mounted) setState(() {});
    } catch (_) {}

    // Subscribe to live vitals via WebSocket
    final ws = context.read<WebSocketService>();
    _vitalsTopic = '/topic/trip/$tripId/vitals';
    ws.subscribe(_vitalsTopic!, (data) {
      if (!mounted) return;
      setState(() {
        _latestVitals = TriageData.fromJson(data);
      });
    });

    // Subscribe to live location via WebSocket
    _locationTopic = '/topic/trip/$tripId/location';
    ws.subscribe(_locationTopic!, (data) {
      if (!mounted) return;
      setState(() {
        _ambulanceLat = (data['latitude'] as num?)?.toDouble();
        _ambulanceLng = (data['longitude'] as num?)?.toDouble();
      });
    });
  }

  @override
  void dispose() {
    final ws = context.read<WebSocketService>();
    if (_vitalsTopic != null) {
      try { ws.unsubscribe(_vitalsTopic!); } catch (_) {}
    }
    if (_locationTopic != null) {
      try { ws.unsubscribe(_locationTopic!); } catch (_) {}
    }
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(Trip? trip) {
    final markers = <Marker>{};
    if (!AppConfig.enableMaps) return markers;

    // Hospital's own location from HospitalProvider heartbeat
    final hp = context.read<HospitalProvider>();
    final hb = hp.heartbeat;
    if (hb != null && hb.latitude != 0) {
      markers.add(Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(hb.latitude, hb.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: hb.name.isNotEmpty ? hb.name : 'Hospital'),
      ));
    }

    // Live ambulance position from WebSocket, or pickup coords as fallback
    if (_ambulanceLat != null && _ambulanceLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: LatLng(_ambulanceLat!, _ambulanceLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: trip?.driverName ?? 'Ambulance'),
      ));
    } else if (trip != null) {
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: LatLng(trip.pickupLatitude, trip.pickupLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: trip.driverName ?? 'Ambulance'),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final hp = context.watch<HospitalProvider>();
    final incomingTrip = hp.incomingTrips.isNotEmpty ? hp.incomingTrips.first : null;
    final etaMin = incomingTrip?.etaSeconds != null
        ? (incomingTrip!.etaSeconds! / 60).ceil()
        : 6;
    final incidentLabel = incomingTrip?.incidentType.label ?? 'TRAUMA';
    final severityLevel = incomingTrip?.severity ?? 1;

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
                    'ETA: $etaMin MINS',
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
                  child: AppConfig.enableMaps
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _ambulanceLat != null
                                ? LatLng(_ambulanceLat!, _ambulanceLng!)
                                : (incomingTrip != null
                                    ? LatLng(incomingTrip.pickupLatitude, incomingTrip.pickupLongitude)
                                    : const LatLng(12.8456, 77.6603)),
                            zoom: 14.0,
                          ),
                          markers: _buildMarkers(incomingTrip),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          trafficEnabled: true,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        )
                      : MapPlaceholder.ambulanceSync(),
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
                          Text('LEVEL $severityLevel', style: AppTypography.heading3.copyWith(color: AppColors.emergencyRed)),
                          Text(incidentLabel, style: AppTypography.caption.copyWith(color: AppColors.emergencyRed)),
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
                        _VitalItem(label: 'HR', value: _latestVitals?.heartRate?.toString() ?? '—', color: AppColors.emergencyRed),
                        _VitalItem(label: 'BP', value: _latestVitals?.bloodPressure ?? '—', color: AppColors.warmOrange),
                        _VitalItem(label: 'SpO2', value: _latestVitals?.spo2 != null ? '${_latestVitals!.spo2}%' : '—', color: AppColors.medicalBlue),
                      ],
                    ),
                    if (_latestVitals?.gcsScore != null || _latestVitals?.temperature != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _VitalItem(label: 'GCS', value: _latestVitals?.gcsScore?.toString() ?? '—', color: AppColors.calmPurple),
                          _VitalItem(label: 'Temp', value: _latestVitals?.temperature?.toStringAsFixed(1) ?? '—', color: AppColors.warmOrange),
                          _VitalItem(label: 'RR', value: _latestVitals?.respiratoryRate?.toString() ?? '—', color: AppColors.lifelineGreen),
                        ],
                      ),
                    ],
                    if (_ambulanceLat != null && _ambulanceLng != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.medicalBlue.withValues(alpha: 0.08),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.my_location, size: 14, color: AppColors.medicalBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Live: ${_ambulanceLat!.toStringAsFixed(4)}, ${_ambulanceLng!.toStringAsFixed(4)}',
                              style: AppTypography.caption.copyWith(color: AppColors.medicalBlue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                onPressed: () async {
                  if (incomingTrip != null) {
                    // Confirm arrival then complete
                    await hp.confirmArrival(incomingTrip.id);
                    if (context.mounted) {
                      await hp.completeTrip(incomingTrip.id);
                    }
                  }
                  if (context.mounted) context.go('/hospital/capacity');
                },
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
