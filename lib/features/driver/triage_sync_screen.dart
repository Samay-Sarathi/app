import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/trip_provider.dart';
import '../../widgets/buttons.dart';

class TriageSyncScreen extends StatelessWidget {
  const TriageSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final tripId = trip?.id.substring(0, 8).toUpperCase() ?? 'N/A';
    final severity = trip?.severity ?? 7;

    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.lifelineGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EMERGENCY PROTOCOL',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.emergencyRed,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'TRIAGE SYNC.',
                style: AppTypography.heading1.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.mediumGray),
                  const SizedBox(width: 4),
                  Text('#PX-$tripId', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: AppColors.mediumGray),
                  const SizedBox(width: 4),
                  Text('SECTOR 4', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                ],
              ),
              const SizedBox(height: 24),

              // Pain Matrix
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PAIN MATRIX',
                          style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.6)),
                        ),
                        Text(
                          '$severity',
                          style: AppTypography.heading2.copyWith(color: AppColors.emergencyRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: severity / 10,
                        minHeight: 8,
                        backgroundColor: AppColors.white.withValues(alpha: 0.1),
                        color: AppColors.emergencyRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Vitals grid
              Row(
                children: [
                  Expanded(child: _VitalCard(label: 'HR', value: '92', unit: 'bpm', color: AppColors.emergencyRed)),
                  const SizedBox(width: 12),
                  Expanded(child: _VitalCard(label: 'SpO2', value: '94', unit: '%', color: AppColors.medicalBlue)),
                ],
              ),
              const SizedBox(height: 12),
              _VitalCardWide(label: 'BP', value: '140/90', unit: 'mmHg', color: AppColors.warmOrange),
              const SizedBox(height: 12),
              _VitalCardWide(label: 'ECG', value: 'ST-ELEVATION', unit: '', color: AppColors.emergencyRed),

              const Spacer(),

              // Authorize button
              PrimaryButton(
                label: 'AUTHORIZE UPLINK',
                icon: Icons.upload,
                onPressed: () {
                  context.read<TripProvider>().clearTrip();
                  context.go('/driver/dashboard');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.vitalM.copyWith(color: color),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalCardWide extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalCardWide({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5)),
          ),
          Row(
            children: [
              Text(value, style: AppTypography.vitalM.copyWith(color: color)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.5))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
