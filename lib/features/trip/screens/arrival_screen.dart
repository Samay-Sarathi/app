import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/trip_status.dart';

/// End-of-trip screen:
/// - EN_ROUTE: Shows "Confirm Arrival" button
/// - ARRIVED: Shows waiting state with pulsing indicator until hospital confirms
/// - COMPLETED: Auto-navigates to dashboard
class ArrivalScreen extends StatefulWidget {
  const ArrivalScreen({super.key});

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen>
    with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _subscribedTopic;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToTripStatus();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _unsubscribe();
    super.dispose();
  }

  void _subscribeToTripStatus() {
    final trip = context.read<TripProvider>().activeTrip;
    if (trip == null) return;

    final ws = context.read<WebSocketService>();
    final topic = '/topic/trip/${trip.id}';
    _subscribedTopic = topic;

    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final status = data['status'] ?? data['newStatus'];
      if (status == 'COMPLETED') {
        _onTripCompleted();
      }
      if (status == 'CANCELLED') {
        _onTripCancelled();
      }
      // Refresh trip state in provider
      context.read<TripProvider>().refreshTrip();
    });
  }

  void _unsubscribe() {
    if (_subscribedTopic != null) {
      try {
        context.read<WebSocketService>().unsubscribe(_subscribedTopic!);
      } catch (_) {}
    }
  }

  void _onTripCompleted() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Trip completed — patient handed off successfully'),
        backgroundColor: AppColors.lifelineGreen,
        duration: Duration(seconds: 3),
      ),
    );
    context.read<TripProvider>().clearTrip();
    context.go('/driver/dashboard');
  }

  void _onTripCancelled() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip has been cancelled'),
        backgroundColor: AppColors.warmOrange,
      ),
    );
    context.go('/driver/dashboard');
  }

  Future<void> _confirmArrival() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);

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
          content: Text('Arrival confirmed — waiting for hospital'),
          backgroundColor: AppColors.lifelineGreen,
        ),
      );
      // Stay on this screen — now in ARRIVED waiting state
      setState(() => _isSubmitting = false);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = tripProvider.error ?? 'Failed to confirm arrival';
      });
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final reasonController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          actionsPadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.emergencyRed,
                size: 26,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cancel Trip?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The hospital and traffic police have been notified and are preparing. '
                'Only cancel if absolutely necessary.',
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.mediumGray,
                ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.emergencyRed,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a reason'),
                        ),
                      );
                      return;
                    }
                    final tripProvider = context.read<TripProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final router = GoRouter.of(context);
                    Navigator.of(ctx).pop();
                    final cancelled = await tripProvider.cancelTrip(
                      reason: reason,
                    );
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
                        _errorMessage =
                            tripProvider.error ?? 'Failed to cancel trip';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel Trip',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mediumGray,
                    side: BorderSide(
                      color: AppColors.mediumGray.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Go Back', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final trip = tripProvider.activeTrip;
    final hospitalName =
        tripProvider.handshakeResult?.hospitalName ??
        trip?.hospitalName ??
        'Hospital';
    final isArrived = trip != null && trip.status == TripStatus.arrived;

    return Scaffold(
      backgroundColor: AppColors.commandDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceLg),
          child: Column(
            children: [
              const Spacer(),

              // Icon — pulsing when waiting for hospital
              if (isArrived)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.1);
                    final opacity = 0.15 + (_pulseController.value * 0.15);
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.lifelineGreen.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppColors.lifelineGreen,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lifelineGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    size: 48,
                    color: AppColors.lifelineGreen,
                  ),
                ),

              const SizedBox(height: 24),
              Text(
                isArrived ? 'You\'ve Arrived' : 'End Trip',
                style: AppTypography.heading1.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: 12),
              Text(
                isArrived
                    ? 'You have arrived at $hospitalName.\nWaiting for hospital staff to confirm handoff.'
                    : 'You are arriving at $hospitalName.\nThe hospital and traffic police have been notified.',
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),

              // Waiting indicator for ARRIVED state
              if (isArrived) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.lifelineGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hospital will confirm once patient is received',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 12,
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.emergencyRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyS.copyWith(
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              // EN_ROUTE: Show confirm button | ARRIVED: No confirm needed
              if (!isArrived) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _confirmArrival,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _isSubmitting ? 'Confirming...' : 'Confirm Arrival',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lifelineGreen,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.lifelineGreen.withValues(
                        alpha: 0.5,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Cancel Trip — available in both EN_ROUTE and ARRIVED
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _showCancelDialog,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text(
                    'Cancel Trip',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergencyRed,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: AppColors.emergencyRed),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Go back to navigation map
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => context.go('/driver/navigation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child:
                      const Text('Go Back', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
