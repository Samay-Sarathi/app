import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/hospital_provider.dart';
import '../../core/services/websocket_service.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'tabs/capacity_tab.dart';
import 'tabs/incoming_tab.dart';
import 'tabs/hospital_map_tab.dart';
import 'tabs/hospital_settings_tab.dart';

/// Hospital dashboard screen — tabbed interface for capacity management,
/// incoming patient tracking, live map, and settings.
class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  int _navIndex = 0;
  String? _incomingTopic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToIncoming();
    });
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  /// Subscribe to real-time incoming trip alerts for this hospital.
  void _subscribeToIncoming() {
    final hp = context.read<HospitalProvider>();
    final hospitalId = hp.heartbeat?.hospitalId;
    if (hospitalId == null) {
      // Heartbeat not loaded yet — try again after fetching
      hp.addListener(_onProviderChanged);
      return;
    }
    _doSubscribe(hospitalId);
  }

  void _onProviderChanged() {
    final hp = context.read<HospitalProvider>();
    final hospitalId = hp.heartbeat?.hospitalId;
    if (hospitalId != null && _incomingTopic == null) {
      hp.removeListener(_onProviderChanged);
      _doSubscribe(hospitalId);
    }
  }

  void _doSubscribe(String hospitalId) {
    if (_incomingTopic != null) return;
    final ws = context.read<WebSocketService>();
    final topic = '/topic/hospital/$hospitalId/incoming';
    _incomingTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      // Refresh incoming trips on any notification
      if (type == 'INCOMING_TRIP' || type == 'AMBULANCE_NEARBY' || type == 'AMBULANCE_ARRIVED') {
        context.read<HospitalProvider>().fetchIncomingTrips();
      }
    });
  }

  void _unsubscribe() {
    if (_incomingTopic != null) {
      try {
        context.read<WebSocketService>().unsubscribe(_incomingTopic!);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: const [
            CapacityTab(),
            IncomingTab(),
            HospitalMapTab(),
            HospitalSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.bed, label: 'Capacity'),
          LifelineNavItem(icon: Icons.notifications, label: 'Incoming'),
          LifelineNavItem(icon: Icons.map, label: 'Map'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
