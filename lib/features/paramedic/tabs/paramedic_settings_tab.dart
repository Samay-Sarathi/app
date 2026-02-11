import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/profile_card.dart';
import '../../../shared/widgets/setting_item.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../shared/widgets/status_badge.dart';

/// Paramedic Settings tab — uses shared components.
class ParamedicSettingsTab extends StatelessWidget {
  const ParamedicSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.settings,
            roleColor: AppColors.mediumGray,
            roleTitle: 'Settings',
            userName: auth.fullName.isNotEmpty ? auth.fullName : 'Paramedic',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'ONLINE',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                ProfileCard(
                  icon: Icons.medical_services,
                  iconColor: AppColors.hospitalTeal,
                  name: auth.fullName.isNotEmpty ? auth.fullName : 'Paramedic',
                  subtitle: 'Paramedic',
                ),
                const SizedBox(height: 24),
                Text('ACCOUNT', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                const SettingItem(icon: Icons.info_outline, label: 'About LifeLine', subtitle: 'Version 1.0.0'),
                const SettingItem(icon: Icons.description_outlined, label: 'Terms of Service', subtitle: 'View legal information'),
                const SizedBox(height: 24),
                const LogoutButton(clearTrip: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
