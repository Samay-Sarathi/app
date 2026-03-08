import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/models/trip.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/police_service.dart';
import '../../core/services/websocket_service.dart';
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
  List<Map<String, dynamic>> _assignments = [];
  bool _isFirstLoad = true;
  bool _isFetching = false;
  String? _error;

  // WebSocket subscriptions
  String? _officerTopic;
  final Set<String> _locationTopics = {};

  // Live ambulance locations from WebSocket
  final Map<String, LatLng> _ambulanceLocations = {};

  // Officer's own location
  LatLng? _officerLocation;
  StreamSubscription<Position>? _locationSub;

  bool get _isLoading => _isFirstLoad && _isFetching;

  void _goToMapTab() {
    setState(() => _navIndex = 1);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _startOfficerLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToCorridors());
  }

  @override
  void dispose() {
    _unsubscribeAll();
    _locationSub?.cancel();
    super.dispose();
  }

  // ── WebSocket ──

  void _subscribeToCorridors() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final userId = auth.userId;
    if (userId == null) return;

    final ws = context.read<WebSocketService>();
    final topic = '/topic/police/$userId/corridors';
    if (_officerTopic == topic) return;

    _officerTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      if (type == 'CORRIDOR_ASSIGNED' || type == 'CORRIDOR_EXPIRED') {
        // Refresh assignments + subscribe to new trip locations
        _loadData();
      }
    });
  }

  void _subscribeToTripLocations() {
    final ws = context.read<WebSocketService>();
    // Subscribe to location updates for all active corridor trips
    for (final corridor in _activeCorridors) {
      final topic = '/topic/trip/${corridor.id}/location';
      if (_locationTopics.contains(topic)) continue;
      _locationTopics.add(topic);
      ws.subscribe(topic, (data) {
        if (!mounted) return;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() => _ambulanceLocations[corridor.id] = LatLng(lat, lng));
        }
      });
    }
  }

  void _unsubscribeAll() {
    try {
      final ws = context.read<WebSocketService>();
      if (_officerTopic != null) ws.unsubscribe(_officerTopic!);
      for (final topic in _locationTopics) {
        ws.unsubscribe(topic);
      }
    } catch (_) {}
    _locationTopics.clear();
  }

  // ── Officer Location ──

  void _startOfficerLocationTracking() async {
    try {
      _locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _officerLocation = LatLng(pos.latitude, pos.longitude));
      });
    } catch (_) {}
  }

  // ── Data Loading ──

  Future<void> _loadData() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _policeService.getActiveTrips(),
        _policeService.getActiveCorridors(),
        _policeService.getAlerts(),
        _policeService.getMyAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _activeTrips = results[0] as List<Trip>;
        _activeCorridors = results[1] as List<Trip>;
        _alerts = results[2] as List<Map<String, dynamic>>;
        _assignments = results[3] as List<Map<String, dynamic>>;
        _isFirstLoad = false;
        _isFetching = false;
      });
      _subscribeToTripLocations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data';
        _isFirstLoad = false;
        _isFetching = false;
      });
    }
  }

  // ── Actions ──

  Future<void> _acknowledgeAssignment(String assignmentId) async {
    try {
      await _policeService.acknowledgeAssignment(
        assignmentId,
        latitude: _officerLocation?.latitude,
        longitude: _officerLocation?.longitude,
      );
      if (!mounted) return;
      _loadData();
    } catch (_) {}
  }

  Future<void> _clearRoute(String assignmentId) async {
    try {
      await _policeService.clearRoute(
        assignmentId,
        latitude: _officerLocation?.latitude,
        longitude: _officerLocation?.longitude,
      );
      if (!mounted) return;
      _loadData();
    } catch (_) {}
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
              assignments: _assignments,
              isLoading: _isLoading,
              isRefreshing: _isFetching && !_isFirstLoad,
              error: _error,
              onRefresh: _loadData,
              onTrackTrip: (_) => _goToMapTab(),
              onAcknowledge: _acknowledgeAssignment,
              onClearRoute: _clearRoute,
            ),
            PoliceMapTab(
              trips: _activeTrips,
              corridorCount: _activeCorridors.length,
              ambulanceLocations: _ambulanceLocations,
              officerLocation: _officerLocation,
            ),
            PoliceAlertsTab(alerts: _alerts, isLoading: _isLoading, isRefreshing: _isFetching && !_isFirstLoad, onRefresh: _loadData),
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
