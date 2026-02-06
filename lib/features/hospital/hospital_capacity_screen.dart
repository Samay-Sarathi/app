import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/hospital_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/bottom_nav.dart';

class HospitalCapacityScreen extends StatefulWidget {
  const HospitalCapacityScreen({super.key});

  @override
  State<HospitalCapacityScreen> createState() => _HospitalCapacityScreenState();
}

class _HospitalCapacityScreenState extends State<HospitalCapacityScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _CapacityTab(),
            _IncomingTab(),
            _SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: LifelineBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          LifelineNavItem(icon: Icons.bed, label: 'Capacity'),
          LifelineNavItem(icon: Icons.notifications, label: 'Incoming'),
          LifelineNavItem(icon: Icons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Tab 0: Capacity Management ──
class _CapacityTab extends StatefulWidget {
  @override
  State<_CapacityTab> createState() => _CapacityTabState();
}

class _CapacityTabState extends State<_CapacityTab> {
  int _vacantBeds = 12;
  int _totalBeds = 50;
  int _chaosScore = 4;
  int _freeDoctors = 3;
  int _activeDoctors = 8;
  String _staffingLevel = 'Adequate';
  final Map<String, bool> _equipment = {
    'Ventilators': true,
    'OT Rooms': true,
    'Blood Bank': true,
    'X-Ray / CT': false,
  };

  // Hourly timer
  Timer? _countdownTimer;
  int _secondsRemaining = 3600; // 60 minutes
  bool _timerExpired = false;
  bool _gracePeriod = false;
  int _graceSecondsRemaining = 240; // 4 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hp = context.read<HospitalProvider>();
      if (hp.heartbeat != null) {
        setState(() {
          _vacantBeds = hp.heartbeat!.bedAvailable;
          _totalBeds = hp.heartbeat!.bedCapacityTotal;
          _chaosScore = hp.heartbeat!.chaosScore;
        });
      }
      hp.fetchIncomingTrips();
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 3600;
      _timerExpired = false;
      _gracePeriod = false;
      _graceSecondsRemaining = 240;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else if (!_gracePeriod) {
        setState(() {
          _timerExpired = true;
          _gracePeriod = true;
        });
      } else if (_graceSecondsRemaining > 0) {
        setState(() => _graceSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    if (_gracePeriod) {
      final m = _graceSecondsRemaining ~/ 60;
      final s = _graceSecondsRemaining % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        content: Text(success ? 'Capacity synced ✓' : (hp.error ?? 'Sync failed')),
        backgroundColor: success ? AppColors.lifelineGreen : AppColors.emergencyRed,
        duration: const Duration(seconds: 2),
      ),
    );
    if (success) _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final occupancy = _totalBeds > 0 ? ((_totalBeds - _vacantBeds) / _totalBeds * 100).round() : 0;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;

    return SingleChildScrollView(
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
                  const Icon(Icons.local_hospital, size: 24, color: AppColors.hospitalTeal),
                  const SizedBox(width: 8),
                  Text('ER Dashboard', style: AppTypography.heading2.copyWith(color: onSurface)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.medicalBlue.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'ED TERMINAL',
                  style: AppTypography.overline.copyWith(color: AppColors.medicalBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Hourly Update Timer ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(
              color: _timerExpired
                  ? AppColors.emergencyRed.withValues(alpha: 0.1)
                  : _secondsRemaining < 300
                      ? AppColors.warmOrange.withValues(alpha: 0.1)
                      : AppColors.lifelineGreen.withValues(alpha: 0.08),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: _timerExpired
                    ? AppColors.emergencyRed.withValues(alpha: 0.3)
                    : _secondsRemaining < 300
                        ? AppColors.warmOrange.withValues(alpha: 0.3)
                        : AppColors.lifelineGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _timerExpired ? Icons.warning_amber : Icons.timer,
                  size: 28,
                  color: _timerExpired
                      ? AppColors.emergencyRed
                      : _secondsRemaining < 300
                          ? AppColors.warmOrange
                          : AppColors.lifelineGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timerExpired
                            ? (_gracePeriod && _graceSecondsRemaining > 0
                                ? 'UPDATE OVERDUE — Grace period'
                                : 'ESCALATED — Dept head notified')
                            : 'Next update due in',
                        style: AppTypography.caption.copyWith(
                          color: _timerExpired ? AppColors.emergencyRed : AppColors.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _timerDisplay,
                        style: AppTypography.heading2.copyWith(
                          color: _timerExpired
                              ? AppColors.emergencyRed
                              : _secondsRemaining < 300
                                  ? AppColors.warmOrange
                                  : onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_secondsRemaining < 300 || _timerExpired)
                  GestureDetector(
                    onTap: _syncHeartbeat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lifelineGreen,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        'Update Now',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Bed Counts ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
            child: Column(
              children: [
                _StepperRow(
                  icon: Icons.bed, label: 'VACANT BEDS', value: _vacantBeds, color: AppColors.lifelineGreen,
                  onDecrement: () => setState(() { if (_vacantBeds > 0) _vacantBeds--; }),
                  onIncrement: () => setState(() { if (_vacantBeds < _totalBeds) _vacantBeds++; }),
                ),
                const Divider(height: 24),
                _StepperRow(
                  icon: Icons.bar_chart, label: 'TOTAL CAPACITY', value: _totalBeds, color: AppColors.medicalBlue,
                  onDecrement: () => setState(() { if (_totalBeds > _vacantBeds) _totalBeds--; }),
                  onIncrement: () => setState(() => _totalBeds++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Occupancy ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('OCCUPANCY', style: AppTypography.overline.copyWith(color: AppColors.mediumGray)),
                    Text('$occupancy%', style: AppTypography.heading3.copyWith(
                      color: occupancy > 80 ? AppColors.emergencyRed : AppColors.warmOrange,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: occupancy / 100, minHeight: 10,
                    backgroundColor: AppColors.lightGray,
                    color: occupancy > 80 ? AppColors.emergencyRed : AppColors.warmOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Doctor Availability ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
            child: Column(
              children: [
                _StepperRow(
                  icon: Icons.person, label: 'FREE DOCTORS', value: _freeDoctors, color: AppColors.lifelineGreen,
                  onDecrement: () => setState(() { if (_freeDoctors > 0) _freeDoctors--; }),
                  onIncrement: () => setState(() { if (_freeDoctors < _activeDoctors) _freeDoctors++; }),
                ),
                const Divider(height: 24),
                _StepperRow(
                  icon: Icons.groups, label: 'DOCTORS ON DUTY', value: _activeDoctors, color: AppColors.medicalBlue,
                  onDecrement: () => setState(() { if (_activeDoctors > _freeDoctors) _activeDoctors--; }),
                  onIncrement: () => setState(() => _activeDoctors++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Staffing Level ──
          Text('STAFFING LEVEL', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Full', 'Adequate', 'Short-staffed', 'Critical'].map((level) {
              final isSelected = _staffingLevel == level;
              final color = level == 'Critical' ? AppColors.emergencyRed
                  : level == 'Short-staffed' ? AppColors.warmOrange
                  : level == 'Full' ? AppColors.lifelineGreen
                  : AppColors.medicalBlue;
              return GestureDetector(
                onTap: () => setState(() => _staffingLevel = level),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : cardColor,
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(color: isSelected ? color : AppColors.lightGray, width: isSelected ? 2 : 1),
                  ),
                  child: Text(level, style: AppTypography.caption.copyWith(
                    color: isSelected ? color : onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Equipment Status ──
          Text('EQUIPMENT STATUS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMd),
            decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
            child: Column(
              children: _equipment.entries.map((entry) {
                return Row(
                  children: [
                    Icon(entry.value ? Icons.check_circle : Icons.cancel, size: 20,
                      color: entry.value ? AppColors.lifelineGreen : AppColors.emergencyRed),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.key, style: AppTypography.bodyS.copyWith(color: onSurface))),
                    Switch(value: entry.value, onChanged: (v) => setState(() => _equipment[entry.key] = v),
                      activeColor: AppColors.lifelineGreen),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Chaos Slider ──
          Text('CRISIS PARAMETERS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _CrisisSlider(
            label: 'Chaos Level', value: _chaosScore, max: 10,
            color: _chaosScore > 7 ? AppColors.emergencyRed : _chaosScore > 4 ? AppColors.warmOrange : AppColors.lifelineGreen,
            onChanged: (v) => setState(() => _chaosScore = v),
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(child: GhostButton(label: 'View Alerts', icon: Icons.notifications, onPressed: () => context.go('/hospital/alert'))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'SYNC & RESET', icon: Icons.sync, onPressed: _syncHeartbeat)),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Tab 1: Incoming Trips ──
class _IncomingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final hp = context.watch<HospitalProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Incoming Patients', style: AppTypography.heading2.copyWith(color: onSurface)),
              GestureDetector(onTap: () => hp.fetchIncomingTrips(), child: const Icon(Icons.refresh, color: AppColors.medicalBlue)),
            ],
          ),
          const SizedBox(height: 16),
          if (hp.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (hp.incomingTrips.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.lifelineGreen.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No incoming patients', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                    const SizedBox(height: 4),
                    Text('All clear for now', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: hp.incomingTrips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trip = hp.incomingTrips[index];
                  final sevColor = trip.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.spaceMd),
                    decoration: BoxDecoration(
                      color: cardColor, borderRadius: AppSpacing.borderRadiusLg,
                      border: Border(left: BorderSide(color: sevColor, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(trip.incidentType.label, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: AppSpacing.borderRadiusFull),
                              child: Text('Severity ${trip.severity}', style: AppTypography.overline.copyWith(color: sevColor)),
                            ),
                          ],
                        ),
                        if (trip.driverName != null) ...[
                          const SizedBox(height: 4),
                          Text('Driver: ${trip.driverName}', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () => context.go('/hospital/alert'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lifelineGreen, foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
                                  ),
                                  child: const Text('View Details', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await hp.confirmArrival(trip.id);
                                    if (context.mounted) await hp.completeTrip(trip.id);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.hospitalTeal,
                                    side: const BorderSide(color: AppColors.hospitalTeal),
                                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
                                  ),
                                  child: const Text('Patient Received', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tab 2: Settings ──
class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTypography.heading2.copyWith(color: onSurface)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: BoxDecoration(color: cardColor, borderRadius: AppSpacing.borderRadiusLg),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.hospitalTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.local_hospital, color: AppColors.hospitalTeal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.fullName.isNotEmpty ? auth.fullName : 'Hospital Staff',
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: onSurface)),
                            Text('Emergency Department', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final nav = GoRouter.of(context);
                    await context.read<AuthProvider>().logout();
                    nav.go('/roles');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd, vertical: 14),
                    decoration: BoxDecoration(color: AppColors.emergencyRed.withValues(alpha: 0.08), borderRadius: AppSpacing.borderRadiusMd),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 22, color: AppColors.emergencyRed),
                        const SizedBox(width: 14),
                        Text('Log Out', style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: AppColors.emergencyRed)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ──

class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperRow({required this.icon, required this.label, required this.value,
    required this.color, required this.onDecrement, required this.onIncrement});

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
            Text('$value', style: AppTypography.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface)),
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
        width: 36, height: 36,
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

class _CrisisSlider extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _CrisisSlider({required this.label, required this.value, required this.max,
    required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyS.copyWith(color: onSurface)),
            Text('$value / $max', style: AppTypography.bodyS.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color, inactiveTrackColor: AppColors.lightGray,
            thumbColor: color, overlayColor: color.withValues(alpha: 0.2), trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(), min: 1, max: max.toDouble(), divisions: max - 1,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
