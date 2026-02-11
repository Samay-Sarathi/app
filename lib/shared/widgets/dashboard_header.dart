import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

import 'status_badge.dart';

/// Consistent header used across all role dashboards.
///
/// Shows a role icon, title, user name, and a [StatusBadge].
class DashboardHeader extends StatelessWidget {
  final IconData roleIcon;
  final Color roleColor;
  final String roleTitle;
  final String userName;
  final BadgeStatus badgeStatus;
  final String badgeLabel;

  const DashboardHeader({
    super.key,
    required this.roleIcon,
    required this.roleColor,
    required this.roleTitle,
    required this.userName,
    required this.badgeStatus,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(roleIcon, size: 20, color: roleColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleTitle,
                  style: AppTypography.heading3.copyWith(color: onSurface),
                ),
                Text(
                  userName,
                  style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                ),
              ],
            ),
          ],
        ),
        StatusBadge(status: badgeStatus, label: badgeLabel),
      ],
    );
  }
}
