import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum BadgeStatus { active, synced, warning, offline, pending }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label ?? config.defaultLabel,
            style: TextStyle(
              color: config.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(bool isDark) {
    switch (status) {
      case BadgeStatus.active:
        return _BadgeConfig(
          isDark ? AppColors.lifelineGreen.withValues(alpha: 0.15) : AppColors.activeBackground,
          isDark ? AppColors.lifelineGreen : AppColors.activeForeground,
          'Active',
        );
      case BadgeStatus.synced:
        return _BadgeConfig(
          isDark ? AppColors.medicalBlue.withValues(alpha: 0.15) : AppColors.syncedBackground,
          isDark ? AppColors.medicalBlue : AppColors.syncedForeground,
          'Synced',
        );
      case BadgeStatus.warning:
        return _BadgeConfig(
          isDark ? AppColors.warmOrange.withValues(alpha: 0.15) : AppColors.warningBackground,
          isDark ? AppColors.warmOrange : AppColors.warningForeground,
          'Warning',
        );
      case BadgeStatus.offline:
        return _BadgeConfig(
          isDark ? AppColors.emergencyRed.withValues(alpha: 0.15) : AppColors.offlineBackground,
          isDark ? AppColors.emergencyRed : AppColors.offlineForeground,
          'Offline',
        );
      case BadgeStatus.pending:
        return _BadgeConfig(
          isDark ? AppColors.mediumGray.withValues(alpha: 0.15) : AppColors.pendingBackground,
          isDark ? AppColors.mediumGray : AppColors.pendingForeground,
          'Pending',
        );
    }
  }
}

class _BadgeConfig {
  final Color background;
  final Color foreground;
  final String defaultLabel;
  _BadgeConfig(this.background, this.foreground, this.defaultLabel);
}
