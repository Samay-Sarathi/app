import 'package:flutter/material.dart';
import '../../core/models/trip.dart';
import '../../core/services/police_service.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'tabs/police_active_tab.dart';
import 'tabs/police_map_tab.dart';
import 'tabs/police_alerts_tab.dart';
import 'tabs/police_settings_tab.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});

  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  int _navIndex = 0;

  final PoliceService _policeService = PoliceService();

  List<Trip> _activeTrips = [];
  List<Trip> _activeCorridors = [];
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
      final results = await Future.wait([
        _policeService.getActiveTrips(),
        _policeService.getActiveCorridors(),
        _policeService.getAlerts(),
      ]);
      if (!mounted) return;
      setState(() {
        _activeTrips = results[0] as List<Trip>;
        _activeCorridors = results[1] as List<Trip>;
        _alerts = results[2] as List<Map<String, dynamic>>;
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
            PoliceActiveTab(
              trips: _activeTrips,
              corridorCount: _activeCorridors.length,
              isLoading: _isLoading,
              error: _error,
              onRefresh: _loadData,
              onTrackTrip: (_) => _goToMapTab(),
            ),
            PoliceMapTab(trips: _activeTrips, corridorCount: _activeCorridors.length),
            PoliceAlertsTab(alerts: _alerts, isLoading: _isLoading, onRefresh: _loadData),
            const PoliceSettingsTab(),
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
