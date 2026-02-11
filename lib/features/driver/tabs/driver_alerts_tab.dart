import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/alert_item.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Alerts tab — real-time trip events via WebSocket, with empty state.
class DriverAlertsTab extends StatefulWidget {
  const DriverAlertsTab({super.key});

  @override
  State<DriverAlertsTab> createState() => _DriverAlertsTabState();
}

class _DriverAlertsTabState extends State<DriverAlertsTab> {
  final List<_AlertEntry> _alerts = [];
  String? _subscribedTopic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSubscription());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSubscription();
  }

  void _syncSubscription() {
    final trip = context.read<TripProvider>().activeTrip;
    final tripId = trip?.id;
    final desiredTopic =
        (tripId != null && trip!.status.isActive) ? '/topic/trip/$tripId' : null;

    if (desiredTopic == _subscribedTopic) return;

    // Unsubscribe from old topic
    if (_subscribedTopic != null) {
      context.read<WebSocketService>().unsubscribe(_subscribedTopic!);
    }

    _subscribedTopic = desiredTopic;

    if (desiredTopic != null) {
      context.read<WebSocketService>().subscribe(desiredTopic, _onTripEvent);
    }
  }

  void _onTripEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    final status = data['status'] as String?;
    final message = data['message'] as String?;

    final AlertType type;
    final String title;
    final String subtitle;

    if (status != null) {
      type = _typeForStatus(status);
      title = 'Trip Status: ${status.replaceAll('_', ' ')}';
      subtitle = message ?? 'Trip status updated';
    } else if (message != null) {
      type = AlertType.info;
      title = 'Trip Update';
      subtitle = message;
    } else {
      return; // unrecognized payload
    }

    setState(() {
      _alerts.insert(0, _AlertEntry(type: type, title: title, subtitle: subtitle, time: DateTime.now()));
    });
  }

  AlertType _typeForStatus(String status) {
    final s = status.toUpperCase();
    if (s.contains('CANCEL') || s.contains('FAIL')) return AlertType.emergency;
    if (s.contains('EN_ROUTE') || s.contains('LOCKED')) return AlertType.warning;
    if (s.contains('ARRIVED') || s.contains('COMPLETED')) return AlertType.success;
    return AlertType.info;
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  @override
  void dispose() {
    if (_subscribedTopic != null) {
      context.read<WebSocketService>().unsubscribe(_subscribedTopic!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch trip so we re-subscribe when it changes
    final trip = context.watch<TripProvider>().activeTrip;
    final hasTrip = trip != null && trip.status.isActive;

    // Dev-mode fallback alerts
    final showDevAlerts = AppConfig.devMode && _alerts.isEmpty;

    final alertCount = showDevAlerts ? 5 : _alerts.length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.notifications,
            roleColor: AppColors.emergencyRed,
            roleTitle: 'Alerts',
            userName: alertCount > 0 ? '$alertCount alerts' : 'No alerts',
            badgeStatus: hasTrip ? BadgeStatus.active : BadgeStatus.pending,
            badgeLabel: hasTrip ? 'LIVE' : 'IDLE',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: showDevAlerts
                ? _buildDevAlerts()
                : _alerts.isEmpty
                    ? _buildEmptyState()
                    : _buildRealAlerts(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 56, color: AppColors.mediumGray.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No alerts yet',
              style: AppTypography.body
                  .copyWith(color: onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 6),
          Text('Alerts will appear here during active trips',
              style: AppTypography.caption
                  .copyWith(color: AppColors.mediumGray)),
        ],
      ),
    );
  }

  Widget _buildRealAlerts() {
    return ListView.separated(
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _alerts[index];
        return AlertItem(
          type: a.type,
          title: a.title,
          subtitle: a.subtitle,
          time: _timeAgo(a.time),
        );
      },
    );
  }

  Widget _buildDevAlerts() {
    return ListView(
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
    );
  }
}

class _AlertEntry {
  final AlertType type;
  final String title;
  final String subtitle;
  final DateTime time;

  const _AlertEntry({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
