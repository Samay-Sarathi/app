import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/helper_service.dart';

/// Helper scans the driver's QR code to link to the active trip (no auth required).
class HelperScanScreen extends StatefulWidget {
  const HelperScanScreen({super.key});

  @override
  State<HelperScanScreen> createState() => _HelperScanScreenState();
}

class _HelperScanScreenState extends State<HelperScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final HelperService _helperService = HelperService();

  bool _isProcessing = false;
  String? _errorMsg;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final token = barcode.rawValue!.trim();
    if (token.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });
    _scannerController.stop();

    try {
      final result = await _helperService.linkToTrip(paramedicToken: token);
      if (!mounted) return;

      final sessionToken = result['sessionToken'] as String;
      final tripId = result['tripId'] as String;
      final hospitalName = result['hospitalName'] as String?;

      context.go('/helper/triage', extra: {
        'sessionToken': sessionToken,
        'tripId': tripId,
        'hospitalName': hospitalName,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMsg = 'Failed to link to trip. Please try again.';
      });
      _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
                    onTap: () => context.go('/roles'),
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
                    'Scan the QR code on the driver\'s phone to assist with triage vitals.',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    _errorMsg!,
                    style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

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
