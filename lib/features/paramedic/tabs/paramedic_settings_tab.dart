import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/profile_card.dart';
import '../../../shared/widgets/setting_toggle.dart';
import '../../../shared/widgets/setting_item.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../shared/widgets/status_badge.dart';

/// Paramedic Settings tab — profile, preferences, and account.
class ParamedicSettingsTab extends StatelessWidget {
  const ParamedicSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();

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
                Text('PREFERENCES', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingToggle(
                  icon: Icons.dark_mode,
                  label: 'Dark Mode',
                  subtitle: 'Use dark theme across the app',
                  value: settings.isDarkMode,
                  onChanged: settings.toggleDarkMode,
                ),
                SettingToggle(
                  icon: Icons.volume_up,
                  label: 'Sound Alerts',
                  subtitle: 'Play sound for trip updates',
                  value: settings.soundEnabled,
                  onChanged: settings.toggleSound,
                ),
                const SizedBox(height: 24),
                Text('ACCOUNT', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingItem(icon: Icons.info_outline, label: 'About LifeLine', subtitle: 'Version 1.0.0', onTap: () => context.push('/about')),
                SettingItem(icon: Icons.description_outlined, label: 'Terms of Service', subtitle: 'View legal information', onTap: () => context.push('/terms')),
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
