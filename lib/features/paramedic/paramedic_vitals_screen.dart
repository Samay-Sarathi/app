import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/vitals_data.dart';
import '../../core/services/paramedic_service.dart';
import '../../core/services/websocket_service.dart';
import '../../shared/widgets/buttons.dart';

/// Paramedic vitals form — enter vitals anonymously for the linked trip.
class ParamedicVitalsScreen extends StatefulWidget {
  final String sessionToken;
  final String tripId;
  final String? hospitalName;

  const ParamedicVitalsScreen({
    super.key,
    required this.sessionToken,
    required this.tripId,
    this.hospitalName,
  });

  @override
  State<ParamedicVitalsScreen> createState() => _ParamedicVitalsScreenState();
}

class _ParamedicVitalsScreenState extends State<ParamedicVitalsScreen> {
  final _paramedicService = ParamedicService();

  final _heartRateController = TextEditingController();
  final _bpController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _gcsController = TextEditingController();
  final _painLevelController = TextEditingController();
  final _notesController = TextEditingController();

  // Identity fields
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isSending = false;
  bool _sent = false;
  String? _errorMsg;
  bool _tripEnded = false;
  bool _showIdentityForm = false;
  String? _subscribedTopic;

  @override
  void initState() {
    super.initState();
    _subscribeToTripStatus();
  }

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
    _nameController.dispose();
    _contactController.dispose();
    if (_subscribedTopic != null) {
      try {
        context.read<WebSocketService>().unsubscribe(_subscribedTopic!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _subscribeToTripStatus() {
    if (widget.tripId.isEmpty) return;
    try {
      final ws = context.read<WebSocketService>();
      final topic = '/topic/trip/${widget.tripId}';
      _subscribedTopic = topic;
      ws.subscribe(topic, (data) {
        if (!mounted) return;
        final status = data['status'] as String?;
        if (status == 'COMPLETED' || status == 'CANCELLED') {
          _showTripEndedDialog();
        }
      });
    } catch (_) {
      // WebSocket may not be connected for unauthenticated users
    }
  }

  void _showTripEndedDialog() {
    if (_tripEnded) return;
    setState(() => _tripEnded = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warmOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Trip Ended', style: AppTypography.heading3),
            ),
          ],
        ),
        content: Text(
          'Trip ended by driver. Review your data before final submission. This is critical medical information.',
          style: AppTypography.bodyS,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Edit Data', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lifelineGreen,
              foregroundColor: AppColors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!_sent) {
                _submitVitals(finalSubmit: true);
              } else {
                setState(() => _showIdentityForm = true);
              }
            },
            child: const Text('Submit & Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVitals({bool finalSubmit = false}) async {
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    try {
      final data = VitalsData(
        heartRate: int.tryParse(_heartRateController.text),
        bloodPressure: _bpController.text.trim().isNotEmpty ? _bpController.text.trim() : null,
        spo2: int.tryParse(_spo2Controller.text),
        respiratoryRate: int.tryParse(_respiratoryRateController.text),
        temperature: double.tryParse(_temperatureController.text),
        gcsScore: int.tryParse(_gcsController.text),
        painLevel: int.tryParse(_painLevelController.text),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      await _paramedicService.submitVitals(
        sessionToken: widget.sessionToken,
        data: data,
      );

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sent = true;
      });

      if (finalSubmit) {
        setState(() => _showIdentityForm = true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMsg = 'Failed to submit vitals. Please try again.';
      });
    }
  }

  Future<void> _submitIdentity() async {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isNotEmpty || contact.isNotEmpty) {
      try {
        await _paramedicService.updateIdentity(
          sessionToken: widget.sessionToken,
          paramedicName: name.isNotEmpty ? name : null,
          contactNumber: contact.isNotEmpty ? contact : null,
        );
      } catch (_) {
        // Non-critical — continue even if identity update fails
      }
    }

    if (mounted) context.go('/roles');
  }

  @override
  Widget build(BuildContext context) {
    final tripId = widget.tripId.length >= 8
        ? widget.tripId.substring(0, 8).toUpperCase()
        : widget.tripId;

    if (_showIdentityForm) {
      return _buildIdentityForm(context);
    }

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
                    'PARAMEDIC VITALS',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.lifelineGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (_tripEnded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withValues(alpha: 0.2),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        'TRIP ENDED',
                        style: AppTypography.overline.copyWith(color: AppColors.emergencyRed),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'VITALS ENTRY',
                style: AppTypography.heading1.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.mediumGray),
                  const SizedBox(width: 4),
                  Text('#PX-$tripId', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
                  if (widget.hospitalName != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.local_hospital, size: 16, color: AppColors.mediumGray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.hospitalName!,
                        style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Vitals form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                          Expanded(child: _VitalInput(label: 'Temp (\u00B0C)', controller: _temperatureController, color: AppColors.warmOrange, isDecimal: true)),
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

                      if (_errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_errorMsg!, style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed)),
                        ),

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
                      onTap: () => setState(() => _showIdentityForm = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.mediumGray.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusMd,
                          border: Border.all(color: AppColors.mediumGray.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Done \u2014 Add Your Details',
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

  Widget _buildIdentityForm(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.lifelineGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 44, color: AppColors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Vitals Submitted',
                style: AppTypography.heading2.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your help. You may optionally add your details below for medical records.',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Name
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR NAME (OPTIONAL)', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.body.copyWith(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: AppTypography.body.copyWith(color: AppColors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Contact
              Container(
                padding: const EdgeInsets.all(AppSpacing.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTACT NUMBER (OPTIONAL)', style: AppTypography.overline.copyWith(color: AppColors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.body.copyWith(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: AppTypography.body.copyWith(color: AppColors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.medicalBlue.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.medicalBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your details help maintain medical records. This information is optional but appreciated.',
                        style: AppTypography.caption.copyWith(color: AppColors.medicalBlue),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              PrimaryButton(
                label: 'SUBMIT & CLOSE',
                icon: Icons.check,
                onPressed: _submitIdentity,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.go('/roles'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Skip',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                  ),
                ),
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
              hintText: '\u2014',
              hintStyle: AppTypography.vitalM.copyWith(color: AppColors.white.withValues(alpha: 0.2)),
            ),
          ),
        ],
      ),
    );
  }
}
