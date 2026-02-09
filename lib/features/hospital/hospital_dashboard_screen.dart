import 'package:flutter/material.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'tabs/capacity_tab.dart';
import 'tabs/incoming_tab.dart';
import 'tabs/hospital_map_tab.dart';
import 'tabs/hospital_settings_tab.dart';

/// Hospital dashboard screen — tabbed interface for capacity management,
/// incoming patient tracking, live map, and settings.
///
/// Tabs are split into separate files under `tabs/` for maintainability.
/// Shared widgets live in `widgets/hospital_shared_widgets.dart`.
class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  int _navIndex = 0;

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
