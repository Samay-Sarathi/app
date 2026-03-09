import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'tabs/driver_status_tab.dart';
import 'tabs/driver_map_tab.dart';
import 'tabs/driver_alerts_tab.dart';
import 'tabs/driver_settings_tab.dart';

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
          children: const [
            DriverStatusTab(),
            DriverMapTab(),
            DriverAlertsTab(),
            DriverSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.shield, label: 'Status'),
          LifelineNavItem(icon: Icons.map, label: 'Map'),
          LifelineNavItem(icon: Icons.notifications, label: 'Alerts'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
