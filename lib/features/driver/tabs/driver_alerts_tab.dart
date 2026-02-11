import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Alerts tab — uses shared AlertItem widget.
class DriverAlertsTab extends StatelessWidget {
  const DriverAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.notifications,
            roleColor: AppColors.emergencyRed,
            roleTitle: 'Alerts',
            userName: '3 new alerts',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'LIVE',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: const [
                AlertItem(
                  type: AlertType.emergency,
                  title: 'Green Corridor Activated',
                  subtitle: 'Corridor active on Route 7 — Main Ave to Central Hospital',
                  time: '2 min ago',
                ),
                SizedBox(height: 12),
                AlertItem(
                  type: AlertType.warning,
                  title: 'Traffic Congestion Ahead',
                  subtitle: 'Heavy traffic detected on Ring Road Sector 4',
                  time: '8 min ago',
                ),
                SizedBox(height: 12),
                AlertItem(
                  type: AlertType.info,
                  title: 'Signal Sync Complete',
                  subtitle: '14 traffic signals synchronized on your route',
                  time: '15 min ago',
                ),
                SizedBox(height: 12),
                AlertItem(
                  type: AlertType.success,
                  title: 'Shift Started',
                  subtitle: 'Your shift has been logged. Unit: Alpha-01',
                  time: '1 hr ago',
                ),
                SizedBox(height: 12),
                AlertItem(
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
