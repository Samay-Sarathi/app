import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/triage_service.dart';
import '../../../core/models/triage_data.dart';
import '../../../shared/widgets/buttons.dart';

class TriageSyncScreen extends StatefulWidget {
  const TriageSyncScreen({super.key});

  @override
  State<TriageSyncScreen> createState() => _TriageSyncScreenState();
}

class _TriageSyncScreenState extends State<TriageSyncScreen> {
  final _triageService = TriageService();

  final _heartRateController = TextEditingController();
  final _bpController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _gcsController = TextEditingController();
  final _painLevelController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSending = false;
  bool _sent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _heartRateController.dispose();
    _bpController.dispose();
    _spo2Controller.dispose();
    _respiratoryRateController.dispose();
    _temperatureController.dispose();
    _gcsController.dispose();
    _painLevelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitVitals() async {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;

    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    try {
      final data = TriageData(
        heartRate: int.tryParse(_heartRateController.text),
        bloodPressure: _bpController.text.trim().isNotEmpty ? _bpController.text.trim() : null,
        spo2: int.tryParse(_spo2Controller.text),
        respiratoryRate: int.tryParse(_respiratoryRateController.text),
        temperature: double.tryParse(_temperatureController.text),
        gcsScore: int.tryParse(_gcsController.text),
        painLevel: int.tryParse(_painLevelController.text),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      await _triageService.recordVitals(trip.id, data);

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMsg = 'Failed to submit vitals. Please try again.';
      });
    }
  }

  void _finishAndGoHome() {
    // Don't clearTrip() — the trip is still ARRIVED on the backend.
    // Hospital-side completes it via POST /trips/{id}/complete.
    // Dashboard will re-fetch and show the active trip until then.
    context.go('/driver/dashboard');
  }

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
                  const Icon(Icons.speed, size: 16, color: AppColors.mediumGray),
                  const SizedBox(width: 4),
                  Text('SEV $severity', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable vitals form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Pain level + severity bar
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
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

                      // Vitals input grid
                      Row(
                        children: [
                          Expanded(child: _VitalInput(label: 'HR (bpm)', controller: _heartRateController, color: AppColors.emergencyRed)),
                          const SizedBox(width: 12),
                          Expanded(child: _VitalInput(label: 'SpO2 (%)', controller: _spo2Controller, color: AppColors.medicalBlue)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _VitalInput(label: 'BP (mmHg)', controller: _bpController, color: AppColors.warmOrange, isNumeric: false)),
                          const SizedBox(width: 12),
                          Expanded(child: _VitalInput(label: 'Resp Rate', controller: _respiratoryRateController, color: AppColors.lifelineGreen)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _VitalInput(label: 'Temp (°C)', controller: _temperatureController, color: AppColors.warmOrange, isDecimal: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _VitalInput(label: 'GCS (3-15)', controller: _gcsController, color: AppColors.calmPurple)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _VitalInput(label: 'Pain Level (0-10)', controller: _painLevelController, color: AppColors.emergencyRed),
                      const SizedBox(height: 12),

                      // Notes
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.spaceMd),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: AppSpacing.borderRadiusLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NOTES', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 2,
                              style: AppTypography.bodyS.copyWith(color: AppColors.white),
                              decoration: InputDecoration(
                                hintText: 'Additional observations...',
                                hintStyle: AppTypography.bodyS.copyWith(color: AppColors.white.withValues(alpha: 0.3)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      if (_errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_errorMsg!, style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed)),
                        ),

                      // Success message
                      if (_sent)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.lifelineGreen.withValues(alpha: 0.15),
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: AppColors.lifelineGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vitals submitted & synced with hospital',
                                  style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              if (!_sent)
                PrimaryButton(
                  label: _isSending ? 'UPLOADING...' : 'SUBMIT VITALS',
                  icon: Icons.upload,
                  onPressed: _isSending ? null : _submitVitals,
                )
              else
                Column(
                  children: [
                    PrimaryButton(
                      label: 'SUBMIT UPDATED VITALS',
                      icon: Icons.refresh,
                      onPressed: () {
                        setState(() => _sent = false);
                        _submitVitals();
                      },
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _finishAndGoHome,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.mediumGray.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(color: AppColors.mediumGray.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Done — Return to Dashboard',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                        ),
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

class _VitalInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final bool isNumeric;
  final bool isDecimal;

  const _VitalInput({
    required this.label,
    required this.controller,
    required this.color,
    this.isNumeric = true,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surface1,
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
          TextField(
            controller: controller,
            keyboardType: isNumeric
                ? (isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number)
                : TextInputType.text,
            style: AppTypography.vitalM.copyWith(color: color),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '—',
              hintStyle: AppTypography.vitalM.copyWith(color: AppColors.white.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}
