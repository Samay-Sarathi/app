import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/hospital_provider.dart';
import '../../../shared/widgets/buttons.dart';
import '../widgets/hospital_shared_widgets.dart';

/// Hospital Capacity Management tab — bed counts, equipment, chaos level, heartbeat sync.
class CapacityTab extends StatefulWidget {
  const CapacityTab({super.key});

  @override
  State<CapacityTab> createState() => _CapacityTabState();
}

class _CapacityTabState extends State<CapacityTab> {
  int _vacantBeds = 12;
  int _totalBeds = 50;
  int _chaosScore = 4;
  final Map<String, bool> _equipment = {
    'Ventilators': true,
    'OT Rooms': true,
    'Blood Bank': true,
    'X-Ray / CT': false,
  };

  // Hourly timer
  Timer? _countdownTimer;
  int _secondsRemaining = 3600;
  bool _timerExpired = false;
  bool _gracePeriod = false;
  int _graceSecondsRemaining = 240;

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
        setState(() { _timerExpired = true; _gracePeriod = true; });
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
    final confirmed = await _showSyncConfirmationDialog();
    if (confirmed != true) return;

    final hp = context.read<HospitalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await hp.sendHeartbeat(
      bedAvailable: _vacantBeds,
      bedCapacityTotal: _totalBeds,
      chaosScore: _chaosScore,
      equipment: {
        'ventilator': _equipment['Ventilators'] ?? true,
        'otRooms': _equipment['OT Rooms'] ?? true,
        'bloodBank': _equipment['Blood Bank'] ?? true,
        'ctScan': _equipment['X-Ray / CT'] ?? false,
      },
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

  Future<bool?> _showSyncConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warmOrange, AppColors.warmOrange.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 44, color: AppColors.white),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ CRITICAL INFORMATION',
                    style: AppTypography.heading3.copyWith(color: AppColors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review before submitting',
                    style: AppTypography.bodyS.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).scaffoldBackgroundColor,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DATA TO BE SYNCED',
                            style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        SyncSummaryRow(label: 'Vacant Beds', value: '$_vacantBeds / $_totalBeds'),
                        const SizedBox(height: 6),
                        SyncSummaryRow(label: 'Chaos Score', value: '$_chaosScore / 10'),
                        const SizedBox(height: 6),
                        SyncSummaryRow(
                          label: 'Equipment',
                          value: _equipment.entries.where((e) => e.value).map((e) => e.key).join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Critical warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyRed.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.emergencyRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This information is CRITICAL for ambulance routing. Incorrect data may result in patients being directed to an unprepared facility.',
                            style: AppTypography.caption.copyWith(color: AppColors.emergencyRed, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.mediumGray.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.borderRadiusMd,
                              border: Border.all(color: AppColors.mediumGray.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: Text('Go Back & Review',
                                  style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.hospitalTeal, Color(0xFF0A8F6F)]),
                              borderRadius: AppSpacing.borderRadiusMd,
                              boxShadow: [BoxShadow(color: AppColors.hospitalTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Center(
                              child: Text('Confirm & Sync',
                                  style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
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
                child: Text('ED TERMINAL', style: AppTypography.overline.copyWith(color: AppColors.medicalBlue)),
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
                      child: Text('Update Now',
                          style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
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
                HospitalStepperRow(
                  icon: Icons.bed, label: 'VACANT BEDS', value: _vacantBeds, color: AppColors.lifelineGreen,
                  onDecrement: () => setState(() { if (_vacantBeds > 0) _vacantBeds--; }),
                  onIncrement: () => setState(() { if (_vacantBeds < _totalBeds) _vacantBeds++; }),
                ),
                const Divider(height: 24),
                HospitalStepperRow(
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

          // ── Equipment ──
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
                    Switch(
                      value: entry.value,
                      onChanged: (v) => setState(() => _equipment[entry.key] = v),
                      activeTrackColor: AppColors.lifelineGreen,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Chaos Slider ──
          Text('CRISIS PARAMETERS', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          CrisisSlider(
            label: 'Chaos Level', value: _chaosScore, max: 10,
            color: _chaosScore > 7 ? AppColors.emergencyRed : _chaosScore > 4 ? AppColors.warmOrange : AppColors.lifelineGreen,
            onChanged: (v) => setState(() => _chaosScore = v),
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(child: GhostButton(label: 'View Alerts', icon: Icons.notifications, onPressed: () {})),
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
