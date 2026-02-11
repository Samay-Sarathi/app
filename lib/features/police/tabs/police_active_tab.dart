import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/trip.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Police Active Trips tab.
class PoliceActiveTab extends StatelessWidget {
  final List<Trip> trips;
  final int corridorCount;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final ValueChanged<Trip> onTrackTrip;

  const PoliceActiveTab({
    super.key,
    required this.trips,
    required this.corridorCount,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onTrackTrip,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          DashboardHeader(
            roleIcon: Icons.shield,
            roleColor: AppColors.calmPurple,
            roleTitle: 'Traffic Police',
            userName: auth.isAuthenticated ? auth.fullName : 'Route Clearance Control',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'ON DUTY',
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: '${trips.length}',
                  label: 'Active Trips',
                  color: AppColors.emergencyRed,
                  icon: Icons.local_shipping,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: '$corridorCount',
                  label: 'Corridors',
                  color: AppColors.lifelineGreen,
                  icon: Icons.traffic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active trips header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE AMBULANCE TRIPS',
                style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${trips.length} Active', style: AppTypography.overline.copyWith(color: AppColors.emergencyRed)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Trip cards
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.emergencyRed.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(error!, style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: onRefresh,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.medicalBlue.withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.borderRadiusMd,
                                ),
                                child: Text('Retry', style: AppTypography.bodyS.copyWith(color: AppColors.medicalBlue, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : trips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 56, color: AppColors.lifelineGreen.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text('No active trips', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                                const SizedBox(height: 4),
                                Text('Routes are clear', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: trips.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final trip = trips[index];
                              return _ActiveTripCard(trip: trip, onTap: () => onTrackTrip(trip));
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _ActiveTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final sevColor = trip.severity >= 7
        ? AppColors.emergencyRed
        : (trip.severity >= 4 ? AppColors.warmOrange : AppColors.softYellow);
    final etaMin = trip.etaSeconds != null ? (trip.etaSeconds! / 60).ceil() : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [BoxShadow(color: sevColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [sevColor, sevColor.withValues(alpha: 0.7)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.local_shipping, size: 16, color: AppColors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(trip.driverName ?? 'Ambulance', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w700, color: AppColors.white))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: AppSpacing.borderRadiusFull),
                    child: Text('SEV ${trip.severity}', style: AppTypography.overline.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(children: [
                    Icon(Icons.medical_services, size: 15, color: sevColor),
                    const SizedBox(width: 8),
                    Text(trip.incidentType.label, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.info_outline, size: 15, color: AppColors.calmPurple),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Status: ${trip.status.name.toUpperCase().replaceAll('_', ' ')}', style: AppTypography.caption.copyWith(color: AppColors.mediumGray))),
                  ]),
                  if (trip.hospitalName != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.local_hospital, size: 15, color: AppColors.hospitalTeal),
                      const SizedBox(width: 8),
                      Text(trip.hospitalName!, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: AppSpacing.borderRadiusSm),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 15, color: AppColors.emergencyRed),
                        const SizedBox(width: 4),
                        Text(etaMin > 0 ? 'ETA ${etaMin}m' : 'ETA —', style: AppTypography.caption.copyWith(color: AppColors.emergencyRed, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.calmPurple.withValues(alpha: 0.1), borderRadius: AppSpacing.borderRadiusFull),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map, size: 13, color: AppColors.calmPurple),
                              const SizedBox(width: 4),
                              Text('Track on Map', style: AppTypography.caption.copyWith(color: AppColors.calmPurple, fontWeight: FontWeight.w700, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
