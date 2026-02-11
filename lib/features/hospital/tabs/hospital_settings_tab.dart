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

/// Hospital Settings tab — profile, preferences, and account.
class HospitalSettingsTab extends StatelessWidget {
  const HospitalSettingsTab({super.key});

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
            userName: auth.fullName.isNotEmpty ? auth.fullName : 'Hospital Staff',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'ONLINE',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                ProfileCard(
                  icon: Icons.local_hospital,
                  iconColor: AppColors.hospitalTeal,
                  name: auth.fullName.isNotEmpty ? auth.fullName : 'Hospital Staff',
                  subtitle: 'Emergency Department',
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
                  subtitle: 'Play sound for incoming emergencies',
                  value: settings.soundEnabled,
                  onChanged: settings.toggleSound,
                ),
                SettingToggle(
                  icon: Icons.timer,
                  label: 'Auto-Accept Emergency',
                  subtitle: 'Automatically accept after countdown',
                  value: settings.autoAcceptEnabled,
                  onChanged: settings.toggleAutoAccept,
                ),
                if (settings.autoAcceptEnabled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
                    child: Row(
                      children: [
                        Text('Countdown: ${settings.countdownSeconds}s',
                            style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                        Expanded(
                          child: Slider(
                            value: settings.countdownSeconds.toDouble(),
                            min: 5, max: 30, divisions: 25,
                            activeColor: AppColors.lifelineGreen,
                            onChanged: (v) => settings.setCountdown(v.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text('ACCOUNT', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingItem(icon: Icons.info_outline, label: 'About LifeLine', subtitle: 'Version 1.0.0', onTap: () => context.push('/about')),
                SettingItem(icon: Icons.description_outlined, label: 'Terms of Service', subtitle: 'View legal information', onTap: () => context.push('/terms')),
                const SizedBox(height: 24),
                const LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
