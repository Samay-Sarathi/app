import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/user_role.dart';
import '../../core/models/trip_status.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.tryRestoreSession();
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    if (!auth.isAuthenticated) {
      context.go('/roles');
      return;
    }

    // For drivers, check if there's an active trip to resume
    if (auth.role == UserRole.driver) {
      final tripProvider = context.read<TripProvider>();
      final trip = await tripProvider.fetchActiveTrip();
      if (!mounted) return;

      if (trip != null && trip.status.isActive) {
        // Resume to the appropriate screen based on trip status
        switch (trip.status) {
          case TripStatus.triage:
            // Trip created but no hospital selected yet — go to hospital select
            await tripProvider.fetchRecommendations();
            if (!mounted) return;
            context.go('/driver/hospital-select');
            return;
          case TripStatus.destinationLocked:
          case TripStatus.enRoute:
            context.go('/driver/navigation');
            return;
          case TripStatus.arrived:
            context.go('/driver/triage');
            return;
          default:
            break;
        }
      }
    }

    context.go(auth.dashboardRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.lifelineGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 64,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'LIFELINE',
                  style: AppTypography.heading1.copyWith(
                    color: onSurface,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.lifelineGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Every Second Counts',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.mediumGray,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.lifelineGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
