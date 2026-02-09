import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/trip_status.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/info_card.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/map_placeholder.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch any active trip on dashboard load (for resume capability)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchActiveTrip();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _StatusTab(),
            _MapTab(),
            _SettingsTab(),
            _AlertsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.shield, label: 'Status'),
          LifelineNavItem(icon: Icons.map, label: 'Map'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
          LifelineNavItem(icon: Icons.notifications, label: 'Alerts'),
        ],
      ),
    );
  }
}

// ── Tab 0: Status (original dashboard) ──
class _StatusTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusBadge(status: BadgeStatus.active, label: 'SYSTEM ONLINE'),
              Row(
                children: [
                  Text(
                    '05:28 PM',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final nav = GoRouter.of(context);
                      final auth = context.read<AuthProvider>();
                      final trip = context.read<TripProvider>();
                      await auth.logout();
                      trip.clearTrip();
                      nav.go('/roles');
                    },
                    child: const Icon(Icons.logout, size: 20, color: AppColors.mediumGray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final trip = context.watch<TripProvider>().activeTrip;
              final auth = context.watch<AuthProvider>();
              if (trip != null && trip.status.isActive) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${trip.incidentType.label} — ${trip.status.label}',
                      style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed),
                    ),
                    const SizedBox(height: 8),
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
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
                        ),
                      ),
                    ),
                    // DEV_ONLY: Cancel trip button for testing
                    if (AppConfig.devMode) ...[                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final tripProvider = context.read<TripProvider>();
                            final cancelled = await tripProvider.cancelTrip(reason: 'DEV: Manual cancel');
                            if (context.mounted && cancelled) {
                              ScaffoldMessenger.of(context).showSnackBar(
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
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }
              return Text(
                auth.isAuthenticated
                    ? 'Welcome, ${auth.fullName}'
                    : 'No Active Emergencies',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              );
            },
          ),
          const SizedBox(height: 16),

          // Live area map
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(12.8456, 77.6603),
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      trafficEnabled: true,
                    )
                  : MapPlaceholder.overview(),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  value: '42${context.read<SettingsProvider>().speedUnit}',
                  title: 'Speed',
                  icon: Icons.speed,
                  accentColor: AppColors.medicalBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoCard(
                  value: 'Optimal',
                  title: 'Readiness',
                  icon: Icons.check_circle,
                  accentColor: AppColors.lifelineGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emergency button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/driver/emergency-case'),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Start Emergency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Map ──
class _MapTab extends StatefulWidget {
  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
  }

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
              Text('Live Map', style: AppTypography.heading2.copyWith(color: onSurface)),
              const StatusBadge(status: BadgeStatus.synced, label: 'GPS ACTIVE'),
            ],
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

// ── Tab 2: Settings ──
class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settings', style: AppTypography.heading2.copyWith(color: theme.colorScheme.onSurface)),
              GestureDetector(
                onTap: () => context.go('/roles'),
                child: Icon(Icons.logout, size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                // Profile card
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
                          color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColors.lifelineGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alpha-01 Driver', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                            Text('Unit: Ambulance Alpha-01', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.mediumGray),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('APPEARANCE', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingToggle(
                  icon: Icons.dark_mode,
                  label: 'Dark Mode',
                  subtitle: 'Switch to dark theme across the app',
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.toggleDarkMode(v),
                ),
                const SizedBox(height: 24),
                Text('NAVIGATION', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingToggle(
                  icon: Icons.vibration,
                  label: 'Haptic Feedback',
                  subtitle: 'Vibration on button presses',
                  value: settings.hapticsEnabled,
                  onChanged: (v) => settings.toggleHaptics(v),
                ),
                _SettingToggle(
                  icon: Icons.speed,
                  label: 'Speed in km/h',
                  subtitle: settings.useKmh ? 'Using kilometers per hour' : 'Using miles per hour',
                  value: settings.useKmh,
                  onChanged: (v) => settings.toggleSpeedUnit(v),
                ),
                const SizedBox(height: 24),
                Text('ALERTS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingToggle(
                  icon: Icons.volume_up,
                  label: 'Sound Alerts',
                  subtitle: 'Play sounds for notifications',
                  value: settings.soundEnabled,
                  onChanged: (v) => settings.toggleSound(v),
                ),
                _SettingToggle(
                  icon: Icons.record_voice_over,
                  label: 'Voice Alerts',
                  subtitle: 'Speak turn-by-turn directions',
                  value: settings.voiceAlertsEnabled,
                  onChanged: (v) => settings.toggleVoiceAlerts(v),
                ),
                _SettingToggle(
                  icon: Icons.sync,
                  label: 'Auto-Sync Vitals',
                  subtitle: 'Continuously sync patient data',
                  value: settings.autoSyncEnabled,
                  onChanged: (v) => settings.toggleAutoSync(v),
                ),
                const SizedBox(height: 24),
                Text('EMERGENCY', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingToggle(
                  icon: Icons.flash_on,
                  label: 'Auto-Accept Emergency',
                  subtitle: 'Automatically accept incoming alerts',
                  value: settings.autoAcceptEnabled,
                  onChanged: (v) => settings.toggleAutoAccept(v),
                ),
                // Countdown slider
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 22, color: AppColors.medicalBlue),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Countdown Timer', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                Text('${settings.countdownSeconds}s before auto-accept', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                              ],
                            ),
                          ),
                          Text('${settings.countdownSeconds}s', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.medicalBlue)),
                        ],
                      ),
                      Slider(
                        value: settings.countdownSeconds.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 5,
                        activeColor: AppColors.medicalBlue,
                        label: '${settings.countdownSeconds}s',
                        onChanged: (v) => settings.setCountdown(v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('SYSTEM', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                _SettingItem(icon: Icons.info_outline, label: 'About LifeLine', subtitle: 'Version 1.0.0'),
                _SettingItem(icon: Icons.description_outlined, label: 'Terms of Service', subtitle: 'View legal information'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Alerts ──
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
                child: Text('3 New', style: AppTypography.overline.copyWith(color: AppColors.emergencyRed)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: const [
                _AlertItem(
                  type: AlertType.emergency,
                  title: 'Green Corridor Activated',
                  subtitle: 'Corridor active on Route 7 — Main Ave to Central Hospital',
                  time: '2 min ago',
                ),
                SizedBox(height: 12),
                _AlertItem(
                  type: AlertType.warning,
                  title: 'Traffic Congestion Ahead',
                  subtitle: 'Heavy traffic detected on Ring Road Sector 4',
                  time: '8 min ago',
                ),
                SizedBox(height: 12),
                _AlertItem(
                  type: AlertType.info,
                  title: 'Signal Sync Complete',
                  subtitle: '14 traffic signals synchronized on your route',
                  time: '15 min ago',
                ),
                SizedBox(height: 12),
                _AlertItem(
                  type: AlertType.success,
                  title: 'Shift Started',
                  subtitle: 'Your shift has been logged. Unit: Alpha-01',
                  time: '1 hr ago',
                ),
                SizedBox(height: 12),
                _AlertItem(
                  type: AlertType.info,
                  title: 'System Update Available',
                  subtitle: 'LifeLine v1.1 is available for download',
                  time: '3 hr ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared private widgets ──

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.medicalBlue),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.lifelineGreen,
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

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

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

enum AlertType { emergency, warning, info, success }

class _AlertItem extends StatelessWidget {
  final AlertType type;
  final String title;
  final String subtitle;
  final String time;

  const _AlertItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Color get _color {
    switch (type) {
      case AlertType.emergency:
        return AppColors.emergencyRed;
      case AlertType.warning:
        return AppColors.warmOrange;
      case AlertType.info:
        return AppColors.medicalBlue;
      case AlertType.success:
        return AppColors.lifelineGreen;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.emergency:
        return Icons.warning_amber_rounded;
      case AlertType.warning:
        return Icons.error_outline;
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.success:
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
