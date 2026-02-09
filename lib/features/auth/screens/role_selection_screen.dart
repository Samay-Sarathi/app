import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceXl),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.lifelineGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.favorite, size: 40, color: AppColors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'LIFELINE',
                style: AppTypography.heading2.copyWith(
                  letterSpacing: 3,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emergency Access Portal',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.25,
                  children: [
                    _RoleCard(
                      icon: Icons.local_shipping,
                      label: 'Ambulance\nDriver',
                      color: AppColors.medicalBlue,
                      onTap: () => context.go('/sign-in', extra: 'driver'),
                    ),
                    _RoleCard(
                      icon: Icons.shield,
                      label: 'Traffic\nPolice',
                      color: AppColors.calmPurple,
                      onTap: () => context.go('/sign-in', extra: 'police'),
                    ),
                    _RoleCard(
                      icon: Icons.local_hospital,
                      label: 'Hospital',
                      color: AppColors.hospitalTeal,
                      onTap: () => context.go('/sign-in', extra: 'hospital'),
                    ),
                    _RoleCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Admin',
                      color: AppColors.warmOrange,
                      onTap: () => context.go('/sign-in', extra: 'admin'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.language, size: 18, color: AppColors.mediumGray),
                  const SizedBox(width: 8),
                  Text('English', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                  const Icon(Icons.arrow_drop_down, color: AppColors.mediumGray),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Emergency: 108',
                style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
