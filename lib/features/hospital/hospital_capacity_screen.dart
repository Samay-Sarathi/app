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
                      activeTrackColor: AppColors.lifelineGreen),
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
class _IncomingTab extends StatefulWidget {
  @override
  State<_IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<_IncomingTab> {
  final Set<String> _acceptedTrips = {};
  final Set<String> _declinedTrips = {};

  void _showTripDecisionDialog(BuildContext context, dynamic trip) {
    final sevColor = trip.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [sevColor, sevColor.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_hospital, size: 40, color: AppColors.white),
                  const SizedBox(height: 8),
                  Text(
                    '🚑 INCOMING AMBULANCE',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prepare to receive patient',
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _HospitalDetailRow(
                    icon: Icons.medical_services,
                    label: 'Emergency Type',
                    value: trip.incidentType.label,
                    color: sevColor,
                  ),
                  const SizedBox(height: 12),
                  _HospitalDetailRow(
                    icon: Icons.speed,
                    label: 'Severity',
                    value: '${trip.severity} / 10',
                    color: sevColor,
                  ),
                  if (trip.driverName != null) ...[
                    const SizedBox(height: 12),
                    _HospitalDetailRow(
                      icon: Icons.local_shipping,
                      label: 'Ambulance',
                      value: trip.driverName!,
                      color: AppColors.medicalBlue,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Warning info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmOrange.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.warmOrange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.warmOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Accepting will notify the driver that your hospital is ready. Declining will route the ambulance to the next available hospital.',
                            style: AppTypography.caption.copyWith(color: AppColors.warmOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() => _declinedTrips.add(trip.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.info_outline, color: AppColors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Patient re-routed to next hospital'),
                                  ],
                                ),
                                backgroundColor: AppColors.warmOrange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyRed.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.borderRadiusMd,
                              border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close, size: 18, color: AppColors.emergencyRed),
                                const SizedBox(width: 6),
                                Text(
                                  'Decline',
                                  style: AppTypography.bodyS.copyWith(
                                    color: AppColors.emergencyRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            setState(() => _acceptedTrips.add(trip.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle, color: AppColors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Patient accepted — preparing bay'),
                                  ],
                                ),
                                backgroundColor: AppColors.lifelineGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.lifelineGreen, Color(0xFF15A366)],
                              ),
                              borderRadius: AppSpacing.borderRadiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lifelineGreen.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 18, color: AppColors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Accept Patient',
                                  style: AppTypography.bodyS.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
    );
  }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incoming Patients', style: AppTypography.heading3.copyWith(color: onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    '${hp.incomingTrips.length} ambulances en route',
                    style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => hp.fetchIncomingTrips(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.medicalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, color: AppColors.medicalBlue, size: 20),
                ),
              ),
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
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trip = hp.incomingTrips[index];
                  final sevColor = trip.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;
                  final isAccepted = _acceptedTrips.contains(trip.id);
                  final isDeclined = _declinedTrips.contains(trip.id);

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: AppSpacing.borderRadiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: sevColor.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Gradient header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [sevColor, sevColor.withValues(alpha: 0.7)],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.local_shipping, size: 16, color: AppColors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  trip.incidentType.label,
                                  style: AppTypography.bodyS.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: AppSpacing.borderRadiusFull,
                                ),
                                child: Text(
                                  'SEV ${trip.severity}',
                                  style: AppTypography.overline.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (trip.driverName != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 15, color: AppColors.medicalBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Driver: ${trip.driverName}',
                                      style: AppTypography.bodyS.copyWith(color: onSurface),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ],
                              Row(
                                children: [
                                  Icon(Icons.confirmation_number, size: 15, color: AppColors.mediumGray),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Trip: ${trip.id.substring(0, trip.id.length.clamp(0, 8))}...',
                                    style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Buttons
                              if (isAccepted)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.borderRadiusSm,
                                    border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle, size: 18, color: AppColors.lifelineGreen),
                                      const SizedBox(width: 8),
                                      Text('Accepted — Preparing Bay',
                                          style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600)),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          await hp.confirmArrival(trip.id);
                                          if (context.mounted) await hp.completeTrip(trip.id);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.hospitalTeal,
                                            borderRadius: AppSpacing.borderRadiusSm,
                                          ),
                                          child: Text('Patient Received',
                                              style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isDeclined)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.mediumGray.withValues(alpha: 0.1),
                                    borderRadius: AppSpacing.borderRadiusSm,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.close, size: 18, color: AppColors.mediumGray),
                                      const SizedBox(width: 8),
                                      Text('Declined — Rerouted',
                                          style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                                    ],
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showTripDecisionDialog(context, trip),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [AppColors.lifelineGreen, Color(0xFF15A366)],
                                            ),
                                            borderRadius: AppSpacing.borderRadiusSm,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.lifelineGreen.withValues(alpha: 0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.notifications_active, size: 16, color: AppColors.white),
                                              const SizedBox(width: 6),
                                              Text('Review & Respond',
                                                  style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => context.go('/hospital/alert'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.medicalBlue.withValues(alpha: 0.1),
                                          borderRadius: AppSpacing.borderRadiusSm,
                                        ),
                                        child: const Icon(Icons.open_in_new, size: 18, color: AppColors.medicalBlue),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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

class _HospitalDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HospitalDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.overline.copyWith(color: AppColors.mediumGray, fontSize: 9),
              ),
              Text(
                value,
                style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
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
