import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';

/// Shows a modal bottom sheet with a QR code for paramedic handoff.
///
/// Fetches a time-limited paramedic token from the backend and displays it
/// as a scannable QR code. Used by the driver during navigation to hand off
/// trip details to arriving paramedics.
Future<void> showQrHandoffSheet(BuildContext context, dynamic trip) async {
  if (trip?.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No active trip found'),
        backgroundColor: AppColors.emergencyRed,
      ),
    );
    return;
  }

  final tripId = trip.id;
  final tripProvider = context.read<TripProvider>();

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(child: CircularProgressIndicator()),
  );

  // Fetch QR token from backend
  final qrTokenData = await tripProvider.getQrToken(tripId);

  if (!context.mounted) return;
  Navigator.of(context).pop(); // Close loading

  if (qrTokenData == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tripProvider.error ?? 'Failed to get QR token'),
        backgroundColor: AppColors.emergencyRed,
      ),
    );
    return;
  }

  final paramedicToken = qrTokenData['paramedicToken'] as String;
  final expiresAt = qrTokenData['expiresAt'] as String?;

  // Format expiry time if available
  String? expiryDisplay;
  if (expiresAt != null) {
    try {
      final expiry = DateTime.parse(expiresAt);
      final now = DateTime.now();
      final diff = expiry.difference(now);
      if (diff.inMinutes > 0) {
        expiryDisplay = '${diff.inMinutes} min';
      } else {
        expiryDisplay = 'Expired';
      }
    } catch (_) {
      expiryDisplay = null;
    }
  }

  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: const BoxDecoration(
        color: AppColors.commandDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Paramedic Handoff QR',
            style: AppTypography.heading3.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Have the paramedic scan this code to sync trip details',
            style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
          if (expiryDisplay != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: expiryDisplay == 'Expired'
                    ? AppColors.emergencyRed.withValues(alpha: 0.1)
                    : AppColors.warmOrange.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusFull,
              ),
              child: Text(
                'Expires in: $expiryDisplay',
                style: AppTypography.caption.copyWith(
                  color: expiryDisplay == 'Expired'
                      ? AppColors.emergencyRed
                      : AppColors.warmOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // QR Code
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: QrImageView(
              data: paramedicToken,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: AppColors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.commandDark,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.commandDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Trip ID display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lifelineGreen.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.confirmation_number, size: 16, color: AppColors.lifelineGreen),
                const SizedBox(width: 8),
                Text(
                  'Trip: ${tripId.toString().substring(0, tripId.toString().length.clamp(0, 8))}...',
                  style: AppTypography.vitalS.copyWith(color: AppColors.lifelineGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.mediumGray.withValues(alpha: 0.2),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Close',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.white),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ],
      ),
    ),
  );
}
