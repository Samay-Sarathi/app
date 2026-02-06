import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/settings_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/info_card.dart';
import '../../widgets/bottom_nav.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _navIndex = 0;

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
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

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
                    onTap: () => context.go('/roles'),
                    child: const Icon(Icons.logout, size: 20, color: AppColors.mediumGray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No Active Emergencies',
            style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 16),

          // City grid placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.commandDark,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _GridPainter(),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 48, color: AppColors.lifelineGreen.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'LIVE CITY GRID',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lifelineGreen.withValues(alpha: 0.7),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

          // Routine log
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: AppSpacing.borderRadiusLg,
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, size: 18, color: AppColors.mediumGray),
                    const SizedBox(width: 8),
                    Text('Routine Log', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                _LogItem(label: 'Signal Sync', time: '04:12'),
                const Divider(height: 16),
                _LogItem(label: 'Patrol Logged', time: '03:45'),
              ],
            ),
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

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('ambulance_a01'),
      position: MapConfig.ambulanceA01,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'A-01', snippet: 'Active'),
    ),
    Marker(
      markerId: const MarkerId('ambulance_a02'),
      position: MapConfig.ambulanceA02,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'A-02', snippet: 'Active'),
    ),
    Marker(
      markerId: const MarkerId('ambulance_a03'),
      position: MapConfig.ambulanceA03,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: 'A-03', snippet: 'Idle'),
    ),
    Marker(
      markerId: const MarkerId('central_hospital'),
      position: MapConfig.centralHospital,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Central Hospital'),
    ),
    Marker(
      markerId: const MarkerId('city_hospital'),
      position: MapConfig.cityHospital,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'City Hospital'),
    ),
    Marker(
      markerId: const MarkerId('user'),
      position: MapConfig.userLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You'),
    ),
  };

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
              child: GoogleMap(
                initialCameraPosition: MapConfig.overviewCamera,
                markers: _markers,
                style: MapConfig.darkMapStyle,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
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
                    boxShadow: AppSpacing.shadowSm,
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

class _LogItem extends StatelessWidget {
  final String label;
  final String time;
  const _LogItem({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyS),
        Text(time, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lifelineGreen.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
        boxShadow: AppSpacing.shadowSm,
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
