import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/hospital_provider.dart';
import '../../../core/models/trip.dart';

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

  void _showDeclineReasonDialog(BuildContext parentContext, Trip? trip, HospitalProvider hp) {
    if (trip == null) return;

    String? selectedReason;
    final reasons = [
      'No available beds',
      'No specialist on duty',
      'Equipment not available',
      'ER at full capacity',
      'Mass casualty event in progress',
      'Other',
    ];
    final customController = TextEditingController();

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.emergencyRed, AppColors.redDark],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.report_problem, size: 32, color: AppColors.white),
                    const SizedBox(height: 6),
                    Text(
                      'Reason for Declining',
                      style: AppTypography.heading3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This helps route the patient faster',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT A REASON',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.mediumGray,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedReason = reason),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emergencyRed.withValues(alpha: 0.08)
                                : Theme.of(ctx).scaffoldBackgroundColor,
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emergencyRed.withValues(alpha: 0.4)
                                  : AppColors.lightGray,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 18,
                                color: isSelected ? AppColors.emergencyRed : AppColors.mediumGray,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTypography.bodyS.copyWith(
                                    color: isSelected ? AppColors.emergencyRed : Theme.of(ctx).colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: 'Please specify the reason...',
                          hintStyle: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                          filled: true,
                          fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.lightGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.emergencyRed),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                        style: AppTypography.bodyS,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.mediumGray.withValues(alpha: 0.1),
                                borderRadius: AppSpacing.borderRadiusMd,
                                border: Border.all(color: AppColors.mediumGray.withValues(alpha: 0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: AppTypography.bodyS.copyWith(
                                    color: AppColors.mediumGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: selectedReason == null
                                ? null
                                : () async {
                                    final reason = selectedReason == 'Other'
                                        ? (customController.text.trim().isNotEmpty
                                            ? customController.text.trim()
                                            : 'Other')
                                        : selectedReason!;
                                    
                                    // Close dialog
                                    if (!ctx.mounted) return;
                                    Navigator.of(ctx).pop();
                                    
                                    // Perform async operations
                                    await hp.rejectTrip(trip.id, reason);
                                    
                                    // Navigate back to capacity screen using parent context
                                    if (!parentContext.mounted) return;
                                    GoRouter.of(parentContext).go('/hospital/capacity');
                                  },
                            child: AnimatedOpacity(
                              opacity: selectedReason == null ? 0.4 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.emergencyRed, AppColors.redDark],
                                  ),
                                  borderRadius: AppSpacing.borderRadiusMd,
                                ),
                                child: Center(
                                  child: Text(
                                    'Confirm Decline',
                                    style: AppTypography.bodyS.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HospitalProvider>();
    final Trip? incomingTrip = hp.incomingTrips.isNotEmpty ? hp.incomingTrips.first : null;
    final incidentLabel = incomingTrip?.incidentType.label ?? 'Cardiac';
    final driverName = incomingTrip?.driverName ?? 'Ambulance';
    final hospitalName = incomingTrip?.hospitalName ?? 'Hospital';

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
                      incomingTrip != null
                          ? (incomingTrip.severity >= 8
                              ? 'PRIORITY 1'
                              : incomingTrip.severity >= 5
                                  ? 'PRIORITY 2'
                                  : 'PRIORITY 3')
                          : 'PRIORITY 1',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
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
                driverName,
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
                    _DetailRow(icon: Icons.local_hospital, text: hospitalName),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.favorite, text: '$incidentLabel - Severity ${incomingTrip?.severity ?? "?"}'),
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.location_on, text: 'Pickup Location'),
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
                        onPressed: () => _showDeclineReasonDialog(context, incomingTrip, hp),
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
