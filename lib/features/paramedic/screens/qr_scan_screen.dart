import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';

/// Paramedic scans the QR code shown by the driver to link to the active trip.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isLinked = false;
  String? _linkedTripId;
  String? _linkedHospitalName;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isLinked) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final token = barcode.rawValue!.trim();
    if (token.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    final tripProvider = context.read<TripProvider>();
    final result = await tripProvider.linkParamedic(token);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _isLinked = true;
        _linkedTripId = result['tripId'] as String?;
        _linkedHospitalName = result['hospitalName'] as String?;
      });
    } else {
      setState(() => _isProcessing = false);
      _scannerController.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Failed to link to trip'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    if (_isLinked) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.lifelineGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 56, color: AppColors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Linked Successfully',
                    style: AppTypography.heading2.copyWith(color: onSurface),
                  ),
                  const SizedBox(height: 12),
                  if (_linkedHospitalName != null) ...[
                    Text(
                      'Destination',
                      style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _linkedHospitalName!,
                      style: AppTypography.body.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_linkedTripId != null)
                    Text(
                      'Trip: ${_linkedTripId!.substring(0, 8)}...',
                      style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.lifelineGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are now linked to this trip. You will receive live location updates and can prepare for patient handoff.',
                            style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/paramedic/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lifelineGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
                      ),
                      child: const Text('View Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/paramedic/dashboard'),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back, color: onSurface),
                        const SizedBox(width: 12),
                        Text('Back', style: AppTypography.body.copyWith(color: onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
              child: Column(
                children: [
                  Text(
                    'Scan QR Code',
                    style: AppTypography.heading2.copyWith(color: onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan the QR code displayed on the driver\'s phone to link to the active trip.',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),

                  // Scan overlay
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lifelineGreen, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  // Loading indicator
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.lifelineGreen),
                            SizedBox(height: 16),
                            Text(
                              'Linking to trip...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 20, color: AppColors.mediumGray),
                  const SizedBox(width: 8),
                  Text(
                    'Point camera at the driver\'s QR code',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
