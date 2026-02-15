import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';

/// End-of-trip screen with two paths:
/// 1. **Confirm Arrival** — simple tap, transitions EN_ROUTE → ARRIVED
/// 2. **Cancel Trip** — requires a reason, transitions to CANCELLED
class TriageSyncScreen extends StatefulWidget {
  const TriageSyncScreen({super.key});

  @override
  State<TriageSyncScreen> createState() => _TriageSyncScreenState();
}

class _TriageSyncScreenState extends State<TriageSyncScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _confirmArrival() async {
    setState(() { _isSubmitting = true; _errorMessage = null; });

    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Get current location for proximity validation
    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}

    final success = await tripProvider.arriveAtHospital(
      latitude: lat,
      longitude: lng,
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Arrival confirmed — hospital notified'),
          backgroundColor: AppColors.lifelineGreen,
        ),
      );
      router.go('/driver/dashboard');
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = tripProvider.error ?? 'Failed to confirm arrival';
      });
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed),
            const SizedBox(width: 10),
            const Expanded(child: Text('Cancel Trip?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The hospital and traffic police have been notified and are preparing. '
              'Only cancel if absolutely necessary.',
              style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation (required)',
                filled: true,
                fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              final tripProvider = context.read<TripProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);

              Navigator.of(ctx).pop();

              final cancelled = await tripProvider.cancelTrip(reason: reason);

              if (!mounted) return;

              if (cancelled) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Trip cancelled'),
                    backgroundColor: AppColors.warmOrange,
                  ),
                );
                router.go('/driver/dashboard');
              } else {
                setState(() {
                  _errorMessage = tripProvider.error ?? 'Failed to cancel trip';
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: AppColors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Cancel Trip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final hospitalName = tripProvider.handshakeResult?.hospitalName
        ?? trip?.hospitalName
        ?? 'Hospital';

    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.lifelineGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag, size: 48, color: AppColors.lifelineGreen),
              ),
              const SizedBox(height: 24),
              Text(
                'End Trip',
                style: AppTypography.heading1.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'You are arriving at $hospitalName.\nThe hospital and traffic police have been notified.',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.emergencyRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              // Confirm Arrival — primary action
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _confirmArrival,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSubmitting ? 'Confirming...' : 'Confirm Arrival',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lifelineGreen,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.lifelineGreen.withValues(alpha: 0.5),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Trip — requires reason
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _showCancelDialog,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Trip', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergencyRed,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.emergencyRed),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Go back to navigation
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => context.go('/driver/navigation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(color: AppColors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Go Back', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
