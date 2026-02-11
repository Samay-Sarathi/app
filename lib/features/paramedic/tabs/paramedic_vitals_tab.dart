import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/triage_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/triage_data.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/status_badge.dart';

/// Paramedic Vitals tab — live patient vitals display.
class ParamedicVitalsTab extends StatefulWidget {
  const ParamedicVitalsTab({super.key});

  @override
  State<ParamedicVitalsTab> createState() => _ParamedicVitalsTabState();
}

class _ParamedicVitalsTabState extends State<ParamedicVitalsTab> {
  final TriageService _triageService = TriageService();
  TriageData? _latestVitals;
  bool _isLoading = false;
  String? _subscribedTopic;

  @override
  void initState() {
    super.initState();
    _loadVitals();
    _subscribeToVitals();
  }

  void _loadVitals() async {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    setState(() => _isLoading = true);
    try {
      final vitals = await _triageService.getLatestVitals(trip.id);
      if (mounted) setState(() { _latestVitals = vitals; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToVitals() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;
    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}/vitals';
    _subscribedTopic = topic;
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      try {
        final vitals = TriageData.fromJson(data);
        setState(() => _latestVitals = vitals);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    if (_subscribedTopic != null) {
      try { context.read<WebSocketService>().unsubscribe(_subscribedTopic!); } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().activeTrip;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    if (trip == null || !trip.status.isActive) {
      return Center(
        child: Text('No active trip', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DashboardHeader(
                roleIcon: Icons.monitor_heart,
                roleColor: AppColors.emergencyRed,
                roleTitle: 'Patient Vitals',
                userName: 'Live monitoring',
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
                onTap: _loadVitals,
                child: const Icon(Icons.refresh, size: 22, color: AppColors.medicalBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_latestVitals == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 48, color: AppColors.mediumGray.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No vitals recorded yet', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                    const SizedBox(height: 4),
                    Text('Waiting for driver to submit...', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(child: _VitalCard(label: 'Heart Rate', value: '${_latestVitals!.heartRate ?? '—'}', unit: 'bpm', color: AppColors.emergencyRed, cardColor: cardColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _VitalCard(label: 'SpO2', value: '${_latestVitals!.spo2 ?? '—'}', unit: '%', color: AppColors.medicalBlue, cardColor: cardColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _VitalCard(label: 'Blood Pressure', value: _latestVitals!.bloodPressure ?? '—', unit: 'mmHg', color: AppColors.warmOrange, cardColor: cardColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _VitalCard(label: 'Resp Rate', value: '${_latestVitals!.respiratoryRate ?? '—'}', unit: '/min', color: AppColors.lifelineGreen, cardColor: cardColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _VitalCard(label: 'Temperature', value: '${_latestVitals!.temperature ?? '—'}', unit: '\u00B0C', color: AppColors.warmOrange, cardColor: cardColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _VitalCard(label: 'GCS', value: '${_latestVitals!.gcsScore ?? '—'}', unit: '/15', color: AppColors.calmPurple, cardColor: cardColor)),
                    ],
                  ),
                  if (_latestVitals!.notes != null && _latestVitals!.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.spaceMd),
                      decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOTES', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                          const SizedBox(height: 8),
                          Text(_latestVitals!.notes!, style: AppTypography.bodyS.copyWith(color: onSurface)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color cardColor;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.heading2.copyWith(color: color)),
              const SizedBox(width: 4),
              Text(unit, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
            ],
          ),
        ],
      ),
    );
  }
}
