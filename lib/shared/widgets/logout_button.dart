import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/trip_provider.dart';

/// Full-width red logout button used consistently in every Settings tab.
class LogoutButton extends StatelessWidget {
  /// Whether to also clear the trip provider on logout.
  final bool clearTrip;

  const LogoutButton({super.key, this.clearTrip = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final nav = GoRouter.of(context);
        final auth = context.read<AuthProvider>();
        if (clearTrip) {
          context.read<TripProvider>().clearTrip();
        }
        await auth.logout();
        nav.go('/roles');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.emergencyRed.withValues(alpha: 0.08),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 22, color: AppColors.emergencyRed),
            const SizedBox(width: 14),
            Text(
              'Log Out',
              style: AppTypography.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.emergencyRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
