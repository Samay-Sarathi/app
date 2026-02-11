import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Alert type determines color and icon.
enum AlertType { emergency, warning, info, success }

/// Reusable alert item with type-colored left border, icon, title, subtitle, and time.
class AlertItem extends StatelessWidget {
  final AlertType type;
  final String title;
  final String subtitle;
  final String time;

  const AlertItem({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Color get _color {
    switch (type) {
      case AlertType.emergency:
        return AppColors.emergencyRed;
      case AlertType.warning:
        return AppColors.warmOrange;
      case AlertType.info:
        return AppColors.medicalBlue;
      case AlertType.success:
        return AppColors.lifelineGreen;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.emergency:
        return Icons.warning_amber_rounded;
      case AlertType.warning:
        return Icons.error_outline;
      case AlertType.info:
        return Icons.info_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusCard,
        border: Border(left: BorderSide(color: _color, width: 2.5)),
        boxShadow: isDark ? AppSpacing.shadowSmDark : AppSpacing.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 20, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
              ],
            ),
          ),
          Text(time, style: AppTypography.caption.copyWith(color: AppColors.mediumGray, fontSize: 10)),
        ],
      ),
    );
  }
}
