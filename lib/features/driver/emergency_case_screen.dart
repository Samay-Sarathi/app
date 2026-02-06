import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class EmergencyCaseScreen extends StatelessWidget {
  const EmergencyCaseScreen({super.key});

  static const _cases = [
    _CaseType(icon: Icons.favorite, label: 'Heart\nAttack', color: AppColors.emergencyRed),
    _CaseType(icon: Icons.car_crash, label: 'Road\nAccident', color: AppColors.warmOrange),
    _CaseType(icon: Icons.local_fire_department, label: 'Burn\nInjury', color: AppColors.warmOrange),
    _CaseType(icon: Icons.pregnant_woman, label: 'Pregnancy\nEmergency', color: AppColors.calmPurple),
    _CaseType(icon: Icons.psychology, label: 'Stroke', color: AppColors.emergencyRed),
    _CaseType(icon: Icons.air, label: 'Breathing\nIssue', color: AppColors.medicalBlue),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

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
                  childAspectRatio: 1.3,
                  children: _cases.map((c) {
                    return _CaseCard(
                      caseType: c,
                      onTap: () => context.go('/driver/severity', extra: c.label.replaceAll('\n', ' ')),
                    );
                  }).toList(),
                ),
              ),

              // Voice input
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusLg,
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: AppColors.emergencyRed, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Voice: "Say emergency type..."',
                      style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    ),
                  ],
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
  const _CaseType({required this.icon, required this.label, required this.color});
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
          boxShadow: AppSpacing.shadowMd,
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
          Icon(icon, size: 14, color: AppColors.emergencyRed),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
