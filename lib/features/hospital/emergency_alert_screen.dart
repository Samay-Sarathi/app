import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/settings_provider.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late int _countdown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _countdown = context.read<SettingsProvider>().countdownSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final autoAccept = context.read<SettingsProvider>().autoAcceptEnabled;
    if (autoAccept) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          timer.cancel();
          if (mounted) context.go('/hospital/sync');
        }
      });
    }

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.emergencyRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Priority badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'PRIORITY 1',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.volume_up, color: AppColors.white, size: 28),
                  ),
                ],
              ),
              const Spacer(flex: 1),

              // Phone icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone, size: 40, color: AppColors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              Text(
                'EMERGENCY ALERT',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ambulance Alpha-01',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(flex: 1),

              // Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.spaceLg),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.local_hospital, text: 'City Central Hospital'),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.favorite, text: 'Cardiac - Stable'),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.location_on, text: 'Outer Ring Road'),
                  ],
                ),
              ),
              const Spacer(flex: 1),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/hospital/sync'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.emergencyRed,
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.go('/hospital/capacity'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.white, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                        ),
                        child: const Text(
                          'REDIRECT',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.watch<SettingsProvider>().autoAcceptEnabled
                    ? 'Auto-accepting in ${_countdown}s'
                    : 'Auto-accept disabled',
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTypography.body.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}
