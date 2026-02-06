import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/map_placeholder.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/status_badge.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _ActiveTripsTab(),
            _MapTab(),
            _AlertsTab(),
            _SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.shield, label: 'Active'),
          LifelineNavItem(icon: Icons.map, label: 'Map'),
          LifelineNavItem(icon: Icons.notifications, label: 'Alerts'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Tab 0: Active Ambulance Trips ──
class _ActiveTripsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, size: 24, color: AppColors.calmPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Traffic Police',
                    style: AppTypography.heading2.copyWith(color: onSurface),
                  ),
                ],
              ),
              const StatusBadge(status: BadgeStatus.active, label: 'ON DUTY'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            auth.isAuthenticated
                ? 'Welcome, ${auth.fullName}'
                : 'Route Clearance Control',
            style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '2',
                  label: 'Active Trips',
                  color: AppColors.emergencyRed,
                  icon: Icons.local_shipping,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '5',
                  label: 'Signals Managed',
                  color: AppColors.lifelineGreen,
                  icon: Icons.traffic,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '12',
                  label: 'Cleared Today',
                  color: AppColors.medicalBlue,
                  icon: Icons.check_circle,
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
                style: AppTypography.overline.copyWith(
                  color: AppColors.mediumGray,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '2 Active',
                  style: AppTypography.overline.copyWith(color: AppColors.emergencyRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Trip cards
          Expanded(
            child: ListView(
              children: const [
                _ActiveTripCard(
                  driverName: 'Ambulance A-01',
                  route: 'MG Road → Central Hospital',
                  incidentType: 'Cardiac Emergency',
                  severity: 9,
                  etaMinutes: 4,
                  distanceKm: '2.3',
                ),
                SizedBox(height: 12),
                _ActiveTripCard(
                  driverName: 'Ambulance A-03',
                  route: 'Ring Road → City Hospital',
                  incidentType: 'Road Accident',
                  severity: 7,
                  etaMinutes: 8,
                  distanceKm: '5.1',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final String driverName;
  final String route;
  final String incidentType;
  final int severity;
  final int etaMinutes;
  final String distanceKm;

  const _ActiveTripCard({
    required this.driverName,
    required this.route,
    required this.incidentType,
    required this.severity,
    required this.etaMinutes,
    required this.distanceKm,
  });

  Color get _severityColor {
    if (severity >= 7) return AppColors.emergencyRed;
    if (severity >= 4) return AppColors.warmOrange;
    return AppColors.softYellow;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border(left: BorderSide(color: _severityColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 18, color: _severityColor),
                  const SizedBox(width: 8),
                  Text(
                    driverName,
                    style: AppTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _severityColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Severity $severity',
                  style: AppTypography.overline.copyWith(color: _severityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.route, size: 14, color: AppColors.mediumGray),
              const SizedBox(width: 6),
              Text(
                route,
                style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.medical_services, size: 14, color: AppColors.mediumGray),
              const SizedBox(width: 6),
              Text(
                incidentType,
                style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TripInfoChip(
                icon: Icons.timer,
                label: 'ETA ${etaMinutes}m',
                color: AppColors.emergencyRed,
              ),
              const SizedBox(width: 12),
              _TripInfoChip(
                icon: Icons.straighten,
                label: '$distanceKm km',
                color: AppColors.medicalBlue,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.calmPurple.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, size: 14, color: AppColors.calmPurple),
                    const SizedBox(width: 4),
                    Text(
                      'Track',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.calmPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TripInfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Tab 1: Map View ──
class _MapTab extends StatefulWidget {
  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jurisdiction Map', style: AppTypography.heading2.copyWith(color: onSurface)),
              const StatusBadge(status: BadgeStatus.synced, label: 'GPS ACTIVE'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: MapConfig.overviewCamera,
                      markers: {
                        Marker(
                          markerId: const MarkerId('ambulance_a01'),
                          position: MapConfig.ambulanceA01,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: const InfoWindow(title: 'A-01 — Cardiac', snippet: 'ETA 4 min'),
                        ),
                        Marker(
                          markerId: const MarkerId('ambulance_a03'),
                          position: MapConfig.ambulanceA03,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          infoWindow: const InfoWindow(title: 'A-03 — Trauma', snippet: 'ETA 8 min'),
                        ),
                      },
                      style: MapConfig.darkMapStyle,
                      liteModeEnabled: true,
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (c) => _mapController = c,
                    )
                  : MapPlaceholder.overview(),
            ),
          ),
          const SizedBox(height: 12),
          // Signal status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lifelineGreen.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.traffic, color: AppColors.lifelineGreen, size: 22),
                const SizedBox(width: 12),
                Text(
                  '3 signals set to GREEN on active routes',
                  style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Alerts ──
class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alerts', style: AppTypography.heading2.copyWith(color: onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '2 New',
                  style: AppTypography.overline.copyWith(color: AppColors.emergencyRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: const [
                _PoliceAlertItem(
                  type: _PoliceAlertType.emergency,
                  title: '🚨 Emergency Ambulance Approaching!',
                  subtitle: 'Cardiac Emergency — Severity 9/10 — ETA to your area: 4 min',
                  time: '1 min ago',
                ),
                SizedBox(height: 12),
                _PoliceAlertItem(
                  type: _PoliceAlertType.emergency,
                  title: '🚨 Route Clearance Needed',
                  subtitle: 'Road Accident — Severity 7/10 — Ring Road corridor',
                  time: '5 min ago',
                ),
                SizedBox(height: 12),
                _PoliceAlertItem(
                  type: _PoliceAlertType.success,
                  title: '✅ Trip #A7F2 Completed',
                  subtitle: 'Ambulance trip completed. Route clearance ended.',
                  time: '22 min ago',
                ),
                SizedBox(height: 12),
                _PoliceAlertItem(
                  type: _PoliceAlertType.info,
                  title: 'Shift Started',
                  subtitle: 'Your duty shift has been logged. Zone: Central',
                  time: '1 hr ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PoliceAlertType { emergency, warning, info, success }

class _PoliceAlertItem extends StatelessWidget {
  final _PoliceAlertType type;
  final String title;
  final String subtitle;
  final String time;

  const _PoliceAlertItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Color get _color {
    switch (type) {
      case _PoliceAlertType.emergency:
        return AppColors.emergencyRed;
      case _PoliceAlertType.warning:
        return AppColors.warmOrange;
      case _PoliceAlertType.info:
        return AppColors.medicalBlue;
      case _PoliceAlertType.success:
        return AppColors.lifelineGreen;
    }
  }

  IconData get _icon {
    switch (type) {
      case _PoliceAlertType.emergency:
        return Icons.warning_amber_rounded;
      case _PoliceAlertType.warning:
        return Icons.error_outline;
      case _PoliceAlertType.info:
        return Icons.info_outline;
      case _PoliceAlertType.success:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border(left: BorderSide(color: _color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 20, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
              ],
            ),
          ),
          Text(time, style: AppTypography.caption.copyWith(color: AppColors.mediumGray, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Tab 3: Settings ──
class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTypography.heading2.copyWith(color: onSurface)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                // Profile
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.calmPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: AppColors.calmPurple, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.fullName.isNotEmpty ? auth.fullName : 'Traffic Officer',
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: onSurface),
                            ),
                            Text(
                              'Traffic Police Department',
                              style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('ACCOUNT', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingItem(icon: Icons.info_outline, label: 'About LifeLine', subtitle: 'Version 1.0.0'),
                _SettingItem(icon: Icons.description_outlined, label: 'Terms of Service', subtitle: 'View legal information'),
                const SizedBox(height: 24),

                // Logout
                GestureDetector(
                  onTap: () async {
                    final nav = GoRouter.of(context);
                    await context.read<AuthProvider>().logout();
                    nav.go('/roles');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 22, color: AppColors.emergencyRed),
                        const SizedBox(width: 14),
                        Text(
                          'Log Out',
                          style: AppTypography.bodyS.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ],
                    ),
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

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  const _SettingItem({required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.mediumGray),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.mediumGray),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceSm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.heading3.copyWith(color: color)),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.mediumGray, fontSize: 9)),
        ],
      ),
    );
  }
}
