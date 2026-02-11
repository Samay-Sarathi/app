import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

// ── Stepper Row (bed count adjustment) ──

class HospitalStepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const HospitalStepperRow({
    super.key,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

// ── Crisis Slider ──

class CrisisSlider extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const CrisisSlider({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

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
            activeTrackColor: color,
            inactiveTrackColor: AppColors.lightGray,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: max.toDouble(),
            divisions: max - 1,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

// ── Sync Summary Row (heartbeat confirmation dialog) ──

class SyncSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const SyncSummaryRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Detail Row (used in dialogs and cards) ──

class HospitalDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const HospitalDetailRow({
    super.key,
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
              Text(label, style: AppTypography.overline.copyWith(color: AppColors.mediumGray, fontSize: 9)),
              Text(value, style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Map Detail Row (compact, used in ambulance cards) ──

class MapDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const MapDetailRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mediumGray),
        const SizedBox(width: 6),
        Text('$label:', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Ambulance Tracker Card (used by hospital map tab and police) ──

class AmbulanceTrackerCard extends StatelessWidget {
  final String driverName;
  final String tripIdShort;
  final String incidentLabel;
  final int severity;
  final String? hospitalName;
  final String statusLabel;
  final int etaMinutes;

  const AmbulanceTrackerCard({
    super.key,
    required this.driverName,
    required this.tripIdShort,
    required this.incidentLabel,
    required this.severity,
    this.hospitalName,
    required this.statusLabel,
    required this.etaMinutes,
  });

  Color _getSeverityColor() {
    if (severity >= 8) return AppColors.emergencyRed;
    if (severity >= 6) return AppColors.warmOrange;
    return AppColors.softYellow;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final sevColor = _getSeverityColor();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: sevColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(Icons.local_shipping, size: 20, color: AppColors.emergencyRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driverName, style: AppTypography.bodyL.copyWith(fontWeight: FontWeight.w700)),
                    Text('Trip: $tripIdShort...', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  'Level $severity',
                  style: AppTypography.caption.copyWith(color: sevColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details
          MapDetailRow(icon: Icons.favorite, label: 'Emergency', value: incidentLabel),
          const SizedBox(height: 6),
          if (hospitalName != null) ...[
            MapDetailRow(icon: Icons.local_hospital, label: 'To', value: hospitalName!),
            const SizedBox(height: 6),
          ],
          MapDetailRow(icon: Icons.info_outline, label: 'Status', value: statusLabel),
          const SizedBox(height: 12),

          // ETA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lifelineGreen.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: AppColors.lifelineGreen),
                const SizedBox(width: 6),
                Text(
                  etaMinutes > 0 ? 'ETA: $etaMinutes min' : 'ETA: —',
                  style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.lifelineGreen, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: AppTypography.caption.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
