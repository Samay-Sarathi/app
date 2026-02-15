import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/models/trip_status.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Status tab — live GPS speed, connectivity readiness, active trip card.
class DriverStatusTab extends StatefulWidget {
  const DriverStatusTab({super.key});

  @override
  State<DriverStatusTab> createState() => _DriverStatusTabState();
}

class _DriverStatusTabState extends State<DriverStatusTab> {
  StreamSubscription<Position>? _positionSub;
  double _speedMps = 0; // meters per second

  @override
  void initState() {
    super.initState();
    _startSpeedTracking();
    // Fetch driver stats from backend
    Future.microtask(() {
      context.read<TripProvider>().fetchDriverStats();
    });
  }

  Future<void> _startSpeedTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() => _speedMps = position.speed.clamp(0, double.infinity));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String _formattedSpeed(bool useKmh) {
    if (_speedMps <= 0.5) return '0'; // below threshold = stationary
    final converted = useKmh ? _speedMps * 3.6 : _speedMps * 2.23694;
    return converted.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();
    final settings = context.watch<SettingsProvider>();
    final connectivity = context.watch<ConnectivityService>();
    final trip = tripProvider.activeTrip;

    final readinessLabel = connectivity.isOnline ? 'Ready' : 'Offline';
    final readinessColor =
        connectivity.isOnline ? AppColors.lifelineGreen : AppColors.emergencyRed;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.local_shipping,
            roleColor: AppColors.medicalBlue,
            roleTitle: 'Driver',
            userName:
                auth.fullName.isNotEmpty ? auth.fullName : 'Ambulance Driver',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'SYSTEM ONLINE',
          ),
          const SizedBox(height: 16),

          // Active trip card
          if (trip != null && trip.status.isActive) ...[
            _ActiveTripCard(trip: trip),
            const SizedBox(height: 16),
          ],

          // Quick stats — live GPS speed + readiness
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${_formattedSpeed(settings.useKmh)}${settings.speedUnit}',
                  label: 'Speed',
                  color: AppColors.medicalBlue,
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: readinessLabel,
                  label: 'Readiness',
                  color: readinessColor,
                  icon: connectivity.isOnline
                      ? Icons.check_circle
                      : Icons.wifi_off,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Driver stats — API-driven
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${tripProvider.tripsToday}',
                  label: 'Trips Today',
                  color: AppColors.lifelineGreen,
                  icon: Icons.local_hospital,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${tripProvider.avgResponseTimeMinutes}m',
                  label: 'Avg Response',
                  color: AppColors.warmOrange,
                  icon: Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: '${tripProvider.distanceCoveredKm.toStringAsFixed(1)}km',
                  label: 'Distance',
                  color: AppColors.medicalBlue,
                  icon: Icons.route,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Emergency button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/driver/emergency-case'),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Start Emergency',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
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
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border(
            left: BorderSide(color: AppColors.emergencyRed, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active: ${trip.incidentType.label} — ${trip.status.label}',
            style: AppTypography.bodyS.copyWith(
                color: AppColors.emergencyRed, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                switch (trip.status) {
                  case TripStatus.triage:
                    context.go('/driver/hospital-select');
                    break;
                  case TripStatus.destinationLocked:
                  case TripStatus.enRoute:
                    context.go('/driver/navigation');
                    break;
                  case TripStatus.arrived:
                    context.go('/driver/triage');
                    break;
                  default:
                    break;
                }
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text('Resume Trip — ${trip.status.label}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emergencyRed,
                side: const BorderSide(color: AppColors.emergencyRed),
                shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusSm),
              ),
            ),
          ),
          // DEV_ONLY: Cancel trip button for testing
          if (AppConfig.devMode) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final tripProvider = context.read<TripProvider>();
                  // Capture messenger before async gap — widget may unmount after cancel
                  final messenger = ScaffoldMessenger.of(context);
                  final cancelled =
                      await tripProvider.cancelTrip(reason: 'DEV: Manual cancel');
                  if (cancelled) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('[DEV] Trip cancelled'),
                        backgroundColor: AppColors.warmOrange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('[DEV] Cancel Trip'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warmOrange,
                  side: const BorderSide(color: AppColors.warmOrange),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusSm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
