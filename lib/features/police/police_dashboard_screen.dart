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

  // Track accepted / declined trips
  final List<_TripData> _allTrips = [
    _TripData(
      id: 'A-01',
      driverName: 'Ambulance A-01',
      route: 'MG Road → Central Hospital',
      incidentType: 'Cardiac Emergency',
      severity: 9,
      etaMinutes: 4,
      distanceKm: '2.3',
      hospital: 'Central Hospital',
      patientInfo: 'Male, ~55 yrs',
    ),
    _TripData(
      id: 'A-03',
      driverName: 'Ambulance A-03',
      route: 'Ring Road → City Hospital',
      incidentType: 'Road Accident',
      severity: 7,
      etaMinutes: 8,
      distanceKm: '5.1',
      hospital: 'City Hospital',
      patientInfo: 'Female, ~30 yrs',
    ),
  ];

  // Pending incoming request (simulated new trip)
  _TripData? _pendingTrip;
  bool _showedInitialAlert = false;

  void _goToMapTab() {
    setState(() => _navIndex = 1);
  }

  void _simulateNewTrip() {
    setState(() {
      _pendingTrip = _TripData(
        id: 'A-07',
        driverName: 'Ambulance A-07',
        route: 'NH-48 → Metro Hospital',
        incidentType: 'Burn Emergency',
        severity: 8,
        etaMinutes: 6,
        distanceKm: '3.8',
        hospital: 'Metro Hospital',
        patientInfo: 'Child, ~8 yrs',
      );
    });
    _showTripRequestDialog(_pendingTrip!);
  }

  void _showTripRequestDialog(_TripData trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TripRequestDialog(
        trip: trip,
        onAccept: () {
          Navigator.of(ctx).pop();
          setState(() {
            _allTrips.add(trip);
            _pendingTrip = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Route clearance accepted — signals cleared'),
                ],
              ),
              backgroundColor: AppColors.lifelineGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show a simulated incoming alert once after build
    if (!_showedInitialAlert) {
      _showedInitialAlert = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _simulateNewTrip();
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
              trips: _allTrips,
              onTrackTrip: (_) => _goToMapTab(),
            ),
            _MapTab(trips: _allTrips),
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

// ── Trip Request Accept/Decline Dialog ──

class _TripRequestDialog extends StatelessWidget {
  final _TripData trip;
  final VoidCallback onAccept;

  const _TripRequestDialog({
    required this.trip,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = trip.severity >= 7
        ? AppColors.emergencyRed
        : (trip.severity >= 4 ? AppColors.warmOrange : AppColors.softYellow);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red header with pulse
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sevColor, sevColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.emergency, size: 40, color: AppColors.white),
                const SizedBox(height: 8),
                Text(
                  '🚨 INCOMING AMBULANCE',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Route clearance requested',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // Trip details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.local_shipping,
                  label: 'Vehicle',
                  value: trip.driverName,
                  color: AppColors.medicalBlue,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.medical_services,
                  label: 'Emergency',
                  value: trip.incidentType,
                  color: sevColor,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.route,
                  label: 'Route',
                  value: trip.route,
                  color: AppColors.calmPurple,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.local_hospital,
                  label: 'Destination',
                  value: trip.hospital,
                  color: AppColors.hospitalTeal,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        icon: Icons.timer,
                        label: 'ETA',
                        value: '${trip.etaMinutes} min',
                        color: AppColors.warmOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailRow(
                        icon: Icons.speed,
                        label: 'Severity',
                        value: '${trip.severity}/10',
                        color: sevColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Duty notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.calmPurple.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: AppColors.calmPurple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield, size: 16, color: AppColors.calmPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'As an on-duty officer, you are required to clear the route for emergency vehicles. This action will activate signal overrides along the ambulance route.',
                          style: AppTypography.caption.copyWith(color: AppColors.calmPurple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Single accept button — no decline for police
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.lifelineGreen, Color(0xFF15A366)],
                      ),
                      borderRadius: AppSpacing.borderRadiusMd,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lifelineGreen.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, size: 20, color: AppColors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Accept & Clear Route',
                          style: AppTypography.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.overline.copyWith(
                  color: AppColors.mediumGray,
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab 0: Active Ambulance Trips ──

class _ActiveTripsTab extends StatelessWidget {
  final List<_TripData> trips;
  final ValueChanged<_TripData> onTrackTrip;

  const _ActiveTripsTab({required this.trips, required this.onTrackTrip});

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
            child: trips.isEmpty
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
  final _TripData trip;
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
                      trip.driverName,
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
                  // Incident type
                  Row(
                    children: [
                      Icon(Icons.medical_services, size: 15, color: sevColor),
                      const SizedBox(width: 8),
                      Text(
                        trip.incidentType,
                        style: AppTypography.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Route
                  Row(
                    children: [
                      const Icon(Icons.route, size: 15, color: AppColors.calmPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.route,
                          style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Hospital
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, size: 15, color: AppColors.hospitalTeal),
                      const SizedBox(width: 8),
                      Text(
                        trip.hospital,
                        style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Bottom info row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, size: 15, color: AppColors.emergencyRed),
                        const SizedBox(width: 4),
                        Text(
                          'ETA ${trip.etaMinutes}m',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.emergencyRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.straighten, size: 15, color: AppColors.medicalBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.distanceKm} km',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.medicalBlue,
                            fontWeight: FontWeight.w600,
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
  final List<_TripData> trips;

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
                              t.driverName,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: sColor,
                              ),
                            ),
                            Text(
                              'ETA ${t.etaMinutes}m • ${t.distanceKm}km',
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
              Text('Alerts', style: AppTypography.heading3.copyWith(color: onSurface)),
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _PoliceAlertItem(
                  type: _PoliceAlertType.emergency,
                  title: '🚨 Emergency Ambulance Approaching!',
                  subtitle: 'Cardiac Emergency — Severity 9/10 — ETA to your area: 4 min',
                  time: '1 min ago',
                ),
                SizedBox(height: 10),
                _PoliceAlertItem(
                  type: _PoliceAlertType.emergency,
                  title: '🚨 Route Clearance Needed',
                  subtitle: 'Road Accident — Severity 7/10 — Ring Road corridor',
                  time: '5 min ago',
                ),
                SizedBox(height: 10),
                _PoliceAlertItem(
                  type: _PoliceAlertType.success,
                  title: '✅ Trip #A7F2 Completed',
                  subtitle: 'Ambulance trip completed. Route clearance ended.',
                  time: '22 min ago',
                ),
                SizedBox(height: 10),
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

// ── Data Model ──

class _TripData {
  final String id;
  final String driverName;
  final String route;
  final String incidentType;
  final int severity;
  final int etaMinutes;
  final String distanceKm;
  final String hospital;
  final String patientInfo;

  const _TripData({
    required this.id,
    required this.driverName,
    required this.route,
    required this.incidentType,
    required this.severity,
    required this.etaMinutes,
    required this.distanceKm,
    required this.hospital,
    required this.patientInfo,
  });
}
