import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/lifeline_logo.dart';

/// About LifeLine — app info, version, and team credits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: onSurface),
                    const SizedBox(width: 12),
                    Text('About LifeLine',
                        style: AppTypography.heading3
                            .copyWith(color: onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    // Logo and version
                    Center(
                      child: Column(
                        children: [
                          const LifelineLogo(size: 80),
                          const SizedBox(height: 16),
                          Text('LifeLine',
                              style: AppTypography.heading2
                                  .copyWith(color: onSurface)),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0',
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.mediumGray)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spaceMd),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Text(
                        'LifeLine is an intelligent emergency response system that '
                        'connects ambulance drivers, hospitals, paramedics, and '
                        'traffic police for faster, coordinated emergency care. '
                        'Using real-time GPS tracking, smart hospital matching, '
                        'and green corridor management, LifeLine aims to reduce '
                        'emergency response times and save lives.',
                        style: AppTypography.bodyS
                            .copyWith(color: onSurface, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Key features
                    Text('KEY FEATURES',
                        style: AppTypography.overline.copyWith(
                            color: AppColors.mediumGray, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _FeatureRow(
                        icon: Icons.navigation,
                        label: 'Real-time Navigation',
                        color: AppColors.medicalBlue),
                    _FeatureRow(
                        icon: Icons.local_hospital,
                        label: 'Smart Hospital Matching',
                        color: AppColors.hospitalTeal),
                    _FeatureRow(
                        icon: Icons.traffic,
                        label: 'Green Corridor Management',
                        color: AppColors.lifelineGreen),
                    _FeatureRow(
                        icon: Icons.monitor_heart,
                        label: 'Live Vital Signs Sync',
                        color: AppColors.emergencyRed),
                    const SizedBox(height: 24),

                    // Licenses
                    GestureDetector(
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'LifeLine',
                        applicationVersion: '1.0.0',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spaceMd, vertical: 14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined,
                                size: 22, color: AppColors.mediumGray),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('Open-Source Licenses',
                                  style: AppTypography.bodyS.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onSurface)),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 20, color: AppColors.mediumGray),
                          ],
                        ),
                      ),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureRow(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label,
              style: AppTypography.bodyS.copyWith(color: onSurface)),
        ],
      ),
    );
  }
}
