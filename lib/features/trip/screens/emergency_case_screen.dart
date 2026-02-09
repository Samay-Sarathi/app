import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/incident_type.dart';

class EmergencyCaseScreen extends StatelessWidget {
  const EmergencyCaseScreen({super.key});

  static const _cases = [
    _CaseType(icon: Icons.favorite, label: 'Heart\nAttack', color: AppColors.emergencyRed, incidentType: IncidentType.cardiac),
    _CaseType(icon: Icons.car_crash, label: 'Road\nAccident', color: AppColors.warmOrange, incidentType: IncidentType.trauma),
    _CaseType(icon: Icons.local_fire_department, label: 'Burn\nInjury', color: AppColors.warmOrange, incidentType: IncidentType.burn),
    _CaseType(icon: Icons.pregnant_woman, label: 'Pregnancy\nEmergency', color: AppColors.calmPurple, incidentType: IncidentType.obstetric),
    _CaseType(icon: Icons.psychology, label: 'Stroke', color: AppColors.emergencyRed, incidentType: IncidentType.stroke),
    _CaseType(icon: Icons.air, label: 'Breathing\nIssue', color: AppColors.medicalBlue, incidentType: IncidentType.respiratory),
    _CaseType(icon: Icons.accessibility_new, label: 'Fracture /\nTrauma', color: AppColors.hospitalTeal, incidentType: IncidentType.pediatric),
    _CaseType(icon: Icons.more_horiz, label: 'Other', color: AppColors.mediumGray, incidentType: IncidentType.other),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GestureDetector(
                onTap: () => context.go('/driver/dashboard'),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: onSurface),
                    const SizedBox(width: 12),
                    Text('Select Emergency Type', style: AppTypography.heading3.copyWith(color: onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Choose the emergency case',
                  style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                ),
              ),
              const SizedBox(height: 24),

              // Recent
              Row(
                children: [
                  Text('RECENT:', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                  const SizedBox(width: 12),
                  _RecentChip(icon: Icons.favorite, label: 'Heart'),
                  const SizedBox(width: 8),
                  _RecentChip(icon: Icons.car_crash, label: 'Accident'),
                ],
              ),
              const SizedBox(height: 24),

              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: _cases.map((c) {
                    return _CaseCard(
                      caseType: c,
                      onTap: () => context.go(
                        '/driver/severity',
                        extra: {
                          'label': c.label.replaceAll('\n', ' '),
                          'incidentType': c.incidentType.toJson(),
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseType {
  final IconData icon;
  final String label;
  final Color color;
  final IncidentType incidentType;
  const _CaseType({required this.icon, required this.label, required this.color, required this.incidentType});
}

class _CaseCard extends StatelessWidget {
  final _CaseType caseType;
  final VoidCallback onTap;
  const _CaseCard({required this.caseType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: caseType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(caseType.icon, size: 28, color: caseType.color),
            ),
            const SizedBox(height: 10),
            Text(
              caseType.label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RecentChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mediumGray),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption.copyWith(color: onSurface)),
        ],
      ),
    );
  }
}
