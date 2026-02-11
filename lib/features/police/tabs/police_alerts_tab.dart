import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/status_badge.dart';

/// Police Alerts tab — uses shared AlertItem.
class PoliceAlertsTab extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final bool isLoading;
  final VoidCallback onRefresh;

  const PoliceAlertsTab({
    super.key,
    required this.alerts,
    required this.isLoading,
    required this.onRefresh,
  });

  AlertType _typeFromEventType(String? eventType) {
    if (eventType == null) return AlertType.info;
    final upper = eventType.toUpperCase();
    if (upper.contains('CREATED') || upper.contains('EN_ROUTE') || upper.contains('TRIAGE')) {
      return AlertType.emergency;
    }
    if (upper.contains('COMPLETED') || upper.contains('ARRIVED')) {
      return AlertType.success;
    }
    if (upper.contains('CANCELLED') || upper.contains('REJECTED')) {
      return AlertType.warning;
    }
    return AlertType.info;
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DashboardHeader(
                roleIcon: Icons.notifications,
                roleColor: AppColors.emergencyRed,
                roleTitle: 'Alerts',
                userName: '${alerts.length} events',
                badgeStatus: BadgeStatus.active,
                badgeLabel: 'LIVE',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(Icons.refresh, size: 20, color: AppColors.medicalBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
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

                          return AlertItem(
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
