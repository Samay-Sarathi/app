import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'tabs/paramedic_trip_tab.dart';
import 'tabs/paramedic_vitals_tab.dart';
import 'tabs/paramedic_settings_tab.dart';

class ParamedicDashboardScreen extends StatefulWidget {
  const ParamedicDashboardScreen({super.key});

  @override
  State<ParamedicDashboardScreen> createState() => _ParamedicDashboardScreenState();
}

class _ParamedicDashboardScreenState extends State<ParamedicDashboardScreen> {
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
            ParamedicTripTab(),
            ParamedicVitalsTab(),
            ParamedicSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.local_shipping, label: 'Trip'),
          LifelineNavItem(icon: Icons.monitor_heart, label: 'Vitals'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
