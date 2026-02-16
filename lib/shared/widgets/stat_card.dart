import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Compact stat card with icon, value, and label.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool compact;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : AppSpacing.spaceMd,
        vertical: compact ? 10 : AppSpacing.spaceMd,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusCard,
        boxShadow: isDark ? AppSpacing.shadowSmDark : AppSpacing.shadowSm,
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 18 : 22, color: color),
          SizedBox(height: compact ? 2 : 4),
          Text(value, style: AppTypography.heading3.copyWith(color: color, fontSize: compact ? 16 : null)),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.mediumGray, fontSize: 9)),
        ],
      ),
    );
  }
}
