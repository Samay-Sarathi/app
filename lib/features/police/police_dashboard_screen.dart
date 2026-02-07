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
import '../../core/models/trip.dart';
import '../../core/services/police_service.dart';
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

  final PoliceService _policeService = PoliceService();

  // Real trip data from backend
  List<Trip> _activeTrips = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  void _goToMapTab() {
    setState(() => _navIndex = 1);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final trips = await _policeService.getActiveTrips();
      final alerts = await _policeService.getAlerts();
      if (!mounted) return;
      setState(() {
        _activeTrips = trips;
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _ActiveTripsTab(
              trips: _activeTrips,
              isLoading: _isLoading,
              error: _error,
              onRefresh: _loadData,
              onTrackTrip: (_) => _goToMapTab(),
            ),
            _MapTab(trips: _activeTrips),
            _AlertsTab(alerts: _alerts, isLoading: _isLoading, onRefresh: _loadData),
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
  final List<Trip> trips;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final ValueChanged<Trip> onTrackTrip;

  const _ActiveTripsTab({required this.trips, required this.isLoading, this.error, required this.onRefresh, required this.onTrackTrip});

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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.calmPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield, size: 20, color: AppColors.calmPurple),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traffic Police',
                        style: AppTypography.heading3.copyWith(color: onSurface),
                      ),
                      Text(
                        auth.isAuthenticated
                            ? 'Welcome, ${auth.fullName}'
                            : 'Route Clearance Control',
                        style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ],
              ),
              const StatusBadge(status: BadgeStatus.active, label: 'ON DUTY'),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${trips.length}',
                  label: 'Active Trips',
                  color: AppColors.emergencyRed,
                  icon: Icons.local_shipping,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '5',
                  label: 'Signals',
                  color: AppColors.lifelineGreen,
                  icon: Icons.traffic,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '12',
                  label: 'Cleared',
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emergencyRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trips.length} Active',
                      style: AppTypography.overline.copyWith(color: AppColors.emergencyRed),
                    ),
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
                              return _ActiveTripCard(
                                trip: trip,
                                onTap: () => onTrackTrip(trip),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Redesigned Active Trip Card ──

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
          boxShadow: [
            BoxShadow(
              color: sevColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sevColor, sevColor.withValues(alpha: 0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping, size: 16, color: AppColors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.driverName ?? 'Ambulance',
                      style: AppTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'SEV ${trip.severity}',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services, size: 15, color: sevColor),
                      const SizedBox(width: 8),
                      Text(
                        trip.incidentType.label,
                        style: AppTypography.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: AppColors.calmPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Status: ${trip.status.name.toUpperCase().replaceAll('_', ' ')}',
                          style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                        ),
                      ),
                    ],
                  ),
                  if (trip.hospitalName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 15, color: AppColors.hospitalTeal),
                        const SizedBox(width: 8),
                        Text(
                          trip.hospitalName!,
                          style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 15, color: AppColors.emergencyRed),
                        const SizedBox(width: 4),
                        Text(
                          etaMin > 0 ? 'ETA ${etaMin}m' : 'ETA —',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.emergencyRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.calmPurple.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map, size: 13, color: AppColors.calmPurple),
                              const SizedBox(width: 4),
                              Text(
                                'Track on Map',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.calmPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
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
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Map View ──

class _MapTab extends StatefulWidget {
  final List<Trip> trips;

  const _MapTab({required this.trips});

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
              Text('Jurisdiction Map', style: AppTypography.heading3.copyWith(color: onSurface)),
              const StatusBadge(status: BadgeStatus.synced, label: 'GPS ACTIVE'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusLg,
              child: AppConfig.enableMaps
                  ? GoogleMap(
                      initialCameraPosition: MapConfig.overviewCamera,
                      markers: {
                        for (final t in widget.trips)
                          Marker(
                            markerId: MarkerId(t.id),
                            position: LatLng(t.pickupLatitude, t.pickupLongitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              t.severity >= 7 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
                            ),
                            infoWindow: InfoWindow(
                              title: t.driverName ?? 'Ambulance',
                              snippet: '${t.incidentType.label} — SEV ${t.severity}',
                            ),
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
          // Active ambulances summary strip
          if (widget.trips.isNotEmpty) ...[
            Text(
              'AMBULANCES ON MAP',
              style: AppTypography.overline.copyWith(
                color: AppColors.mediumGray,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.trips.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final t = widget.trips[index];
                  final sColor = t.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;
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
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.driverName ?? 'Ambulance',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: sColor,
                              ),
                            ),
                            Text(
                              t.etaSeconds != null ? 'ETA ${(t.etaSeconds! / 60).ceil()}m' : 'ETA —',
                              style: AppTypography.overline.copyWith(
                                color: AppColors.mediumGray,
                                fontSize: 9,
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
          // Signal status bar
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
                  '3 signals set to GREEN on active routes',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.lifelineGreen,
                    fontWeight: FontWeight.w600,
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

// ── Tab 2: Alerts (wired to real backend data) ──

class _AlertsTab extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _AlertsTab({required this.alerts, required this.isLoading, required this.onRefresh});

  _PoliceAlertType _typeFromEventType(String? eventType) {
    if (eventType == null) return _PoliceAlertType.info;
    final upper = eventType.toUpperCase();
    if (upper.contains('CREATED') || upper.contains('EN_ROUTE') || upper.contains('TRIAGE')) {
      return _PoliceAlertType.emergency;
    }
    if (upper.contains('COMPLETED') || upper.contains('ARRIVED')) {
      return _PoliceAlertType.success;
    }
    if (upper.contains('CANCELLED') || upper.contains('REJECTED')) {
      return _PoliceAlertType.warning;
    }
    return _PoliceAlertType.info;
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
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
              Text('Alerts', style: AppTypography.heading3.copyWith(color: onSurface)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      '${alerts.length} Events',
                      style: AppTypography.overline.copyWith(color: AppColors.emergencyRed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Icon(Icons.refresh, size: 20, color: AppColors.medicalBlue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: AppColors.mediumGray.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text('No recent alerts', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          final eventType = alert['eventType'] as String?;
                          final tripId = alert['tripId'] as String?;
                          final payload = alert['payload'];
                          final createdAt = alert['createdAt'] as String?;

                          String title = eventType?.replaceAll('_', ' ') ?? 'Event';
                          String subtitle = '';
                          if (tripId != null) {
                            subtitle = 'Trip: ${tripId.substring(0, tripId.length.clamp(0, 8))}...';
                          }
                          if (payload is Map) {
                            final reason = payload['reason'];
                            if (reason != null) subtitle += ' — $reason';
                          }

                          return _PoliceAlertItem(
                            type: _typeFromEventType(eventType),
                            title: title,
                            subtitle: subtitle.isNotEmpty ? subtitle : 'No details',
                            time: _timeAgo(createdAt),
                          );
                        },
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border(left: BorderSide(color: _color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: _color),
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
          Text('Settings', style: AppTypography.heading3.copyWith(color: onSurface)),
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

// ── Shared Widgets ──

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


