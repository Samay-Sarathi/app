import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/dashboard_header.dart';
import '../../../shared/widgets/profile_card.dart';
import '../../../shared/widgets/setting_toggle.dart';
import '../../../shared/widgets/setting_item.dart';
import '../../../shared/widgets/logout_button.dart';
import '../../../shared/widgets/status_badge.dart';

/// Driver Settings tab — uses shared components throughout.
class DriverSettingsTab extends StatelessWidget {
  const DriverSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            roleIcon: Icons.settings,
            roleColor: AppColors.mediumGray,
            roleTitle: 'Settings',
            userName: auth.fullName.isNotEmpty ? auth.fullName : 'Driver',
            badgeStatus: BadgeStatus.active,
            badgeLabel: 'ONLINE',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                ProfileCard(
                  icon: Icons.person,
                  iconColor: AppColors.lifelineGreen,
                  name: auth.fullName.isNotEmpty ? auth.fullName : 'Driver',
                  subtitle: 'Ambulance Driver',
                ),
                const SizedBox(height: 24),
                Text('APPEARANCE', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingToggle(
                  icon: Icons.dark_mode,
                  label: 'Dark Mode',
                  subtitle: 'Switch to dark theme across the app',
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.toggleDarkMode(v),
                ),
                const SizedBox(height: 24),
                Text('NAVIGATION', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingToggle(
                  icon: Icons.vibration,
                  label: 'Haptic Feedback',
                  subtitle: 'Vibration on button presses',
                  value: settings.hapticsEnabled,
                  onChanged: (v) => settings.toggleHaptics(v),
                ),
                SettingToggle(
                  icon: Icons.speed,
                  label: 'Speed in km/h',
                  subtitle: settings.useKmh ? 'Using kilometers per hour' : 'Using miles per hour',
                  value: settings.useKmh,
                  onChanged: (v) => settings.toggleSpeedUnit(v),
                ),
                const SizedBox(height: 24),
                Text('ALERTS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingToggle(
                  icon: Icons.volume_up,
                  label: 'Sound Alerts',
                  subtitle: 'Play sounds for notifications',
                  value: settings.soundEnabled,
                  onChanged: (v) => settings.toggleSound(v),
                ),
                SettingToggle(
                  icon: Icons.record_voice_over,
                  label: 'Voice Alerts',
                  subtitle: 'Speak turn-by-turn directions',
                  value: settings.voiceAlertsEnabled,
                  onChanged: (v) => settings.toggleVoiceAlerts(v),
                ),
                SettingToggle(
                  icon: Icons.sync,
                  label: 'Auto-Sync Vitals',
                  subtitle: 'Continuously sync patient data',
                  value: settings.autoSyncEnabled,
                  onChanged: (v) => settings.toggleAutoSync(v),
                ),
                const SizedBox(height: 24),
                Text('EMERGENCY', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                SettingToggle(
                  icon: Icons.flash_on,
                  label: 'Auto-Accept Emergency',
                  subtitle: 'Automatically accept incoming alerts',
                  value: settings.autoAcceptEnabled,
                  onChanged: (v) => settings.toggleAutoAccept(v),
                ),
                // Countdown slider
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadiusCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 22, color: AppColors.medicalBlue),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Countdown Timer', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                Text('${settings.countdownSeconds}s before auto-accept', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                              ],
                            ),
                          ),
                          Text('${settings.countdownSeconds}s', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.medicalBlue)),
                        ],
                      ),
                      Slider(
                        value: settings.countdownSeconds.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 5,
                        activeColor: AppColors.medicalBlue,
                        label: '${settings.countdownSeconds}s',
                        onChanged: (v) => settings.setCountdown(v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('SYSTEM', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
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
