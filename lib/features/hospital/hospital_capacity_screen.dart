import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/hospital_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/buttons.dart';

class HospitalCapacityScreen extends StatefulWidget {
  const HospitalCapacityScreen({super.key});

  @override
  State<HospitalCapacityScreen> createState() => _HospitalCapacityScreenState();
}

class _HospitalCapacityScreenState extends State<HospitalCapacityScreen> {
  int _vacantBeds = 12;
  int _totalBeds = 50;
  int _chaosScore = 4;

  @override
  void initState() {
    super.initState();
    // Load initial data from provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hp = context.read<HospitalProvider>();
      if (hp.heartbeat != null) {
        setState(() {
          _vacantBeds = hp.heartbeat!.bedAvailable;
          _totalBeds = hp.heartbeat!.bedCapacityTotal;
          _chaosScore = hp.heartbeat!.chaosScore;
        });
      }
      // Also fetch incoming trips in background
      hp.fetchIncomingTrips();
    });
  }

  Future<void> _syncHeartbeat() async {
    final hp = context.read<HospitalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await hp.sendHeartbeat(
      bedAvailable: _vacantBeds,
      bedCapacityTotal: _totalBeds,
      chaosScore: _chaosScore,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Capacity synced successfully' : (hp.error ?? 'Sync failed')),
        backgroundColor: success ? AppColors.lifelineGreen : AppColors.emergencyRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occupancy = ((_totalBeds - _vacantBeds) / _totalBeds * 100).round();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final nav = GoRouter.of(context);
                          await context.read<AuthProvider>().logout();
                          nav.go('/roles');
                        },
                        child: const Icon(Icons.logout, size: 20, color: AppColors.mediumGray),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 18, color: AppColors.medicalBlue),
                      const SizedBox(width: 6),
                      Text('1:29:26', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'ED TERMINAL 04',
                      style: AppTypography.overline.copyWith(color: AppColors.medicalBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('EMERGENCY LIVE', style: AppTypography.heading2.copyWith(color: onSurface)),
              const SizedBox(height: 24),

              // Bed counts
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  children: [
                    _BedRow(
                      icon: Icons.bed,
                      label: 'VACANT',
                      value: _vacantBeds,
                      color: AppColors.lifelineGreen,
                      onDecrement: () => setState(() { if (_vacantBeds > 0) _vacantBeds--; }),
                      onIncrement: () => setState(() { if (_vacantBeds < _totalBeds) _vacantBeds++; }),
                    ),
                    const Divider(height: 24),
                    _BedRow(
                      icon: Icons.bar_chart,
                      label: 'TOTAL',
                      value: _totalBeds,
                      color: AppColors.medicalBlue,
                      onDecrement: () => setState(() { if (_totalBeds > _vacantBeds) _totalBeds--; }),
                      onIncrement: () => setState(() => _totalBeds++),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Occupancy bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('OCCUPANCY', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                        Text(
                          '$occupancy%',
                          style: AppTypography.heading3.copyWith(
                            color: occupancy > 80 ? AppColors.emergencyRed : AppColors.warmOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: occupancy / 100,
                        minHeight: 10,
                        backgroundColor: AppColors.lightGray,
                        color: occupancy > 80 ? AppColors.emergencyRed : AppColors.warmOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Crisis parameters
              Text('CRISIS PARAMETERS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              _CrisisBar(label: 'Chaos', value: _chaosScore, max: 10, color: AppColors.emergencyRed),
              const SizedBox(height: 10),
              _CrisisBar(label: 'Doctors', value: 8, max: 10, color: AppColors.lifelineGreen),
              const SizedBox(height: 10),
              _CrisisBar(label: 'Staffing', value: 7, max: 10, color: AppColors.medicalBlue),
              const SizedBox(height: 10),
              _CrisisBar(label: 'Equipment', value: 9, max: 10, color: AppColors.lifelineGreen),

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'View Alert',
                      icon: Icons.notifications,
                      onPressed: () => context.go('/hospital/alert'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'SYNC & RESET',
                      onPressed: _syncHeartbeat,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _BedRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
            Text(
              '$value',
              style: AppTypography.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        const Spacer(),
        _StepperButton(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 8),
        _StepperButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _CrisisBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _CrisisBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
        ),
        Expanded(
          child: Row(
            children: List.generate(max, (i) {
              return Expanded(
                child: Container(
                  height: 10,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: i < value ? color : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$value/$max',
            style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
