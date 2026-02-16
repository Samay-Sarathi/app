import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/trip.dart';
import '../../../core/providers/hospital_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../widgets/hospital_shared_widgets.dart';

/// Incoming patients tab — shows ambulances en route, accept/decline, live tracking.
class IncomingTab extends StatefulWidget {
  const IncomingTab({super.key});

  @override
  State<IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<IncomingTab> {
  final Set<String> _acceptedTrips = {};
  final Set<String> _declinedTrips = {};
  final Set<String> _receivingTrips = {};
  final Map<String, String> _declineReasons = {};
  bool _hasLoadedOnce = false;

  // Real-time ambulance locations from WebSocket
  final Map<String, LatLng> _ambulanceLocations = {};
  final Set<String> _subscribedTopics = {};

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  // ── WebSocket Location Tracking ──

  void _subscribeToLocation(String tripId) {
    final topic = '/topic/trip/$tripId/location';
    if (_subscribedTopics.contains(topic)) return;

    final ws = context.read<WebSocketService>();
    ws.subscribe(topic, (data) {
      if (!mounted) return;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        setState(() => _ambulanceLocations[tripId] = LatLng(lat, lng));
      }
    });
    _subscribedTopics.add(topic);
  }

  void _unsubscribeAll() {
    final ws = context.read<WebSocketService>();
    for (final topic in _subscribedTopics) {
      try { ws.unsubscribe(topic); } catch (_) {}
    }
    _subscribedTopics.clear();
  }

  int _getDistanceMeters(String tripId) {
    final ambulanceLoc = _ambulanceLocations[tripId];
    if (ambulanceLoc == null) return -1; // No location data yet

    final hp = context.read<HospitalProvider>();
    final hb = hp.heartbeat;
    if (hb == null || hb.latitude == 0) return -1;

    return NavigationHelpers.haversineDistance(
      ambulanceLoc,
      LatLng(hb.latitude, hb.longitude),
    ).round();
  }

  // ── Trip Decision Dialog ──

  Future<bool?> _showTripDecisionDialog(BuildContext context, dynamic trip) {
    final sevColor = trip.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [sevColor, sevColor.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_hospital, size: 40, color: AppColors.white),
                  const SizedBox(height: 8),
                  Text('INCOMING AMBULANCE',
                      style: AppTypography.heading3.copyWith(color: AppColors.white, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Prepare to receive patient',
                      style: AppTypography.bodyS.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  HospitalDetailRow(icon: Icons.medical_services, label: 'Emergency Type', value: trip.incidentType.label, color: sevColor),
                  const SizedBox(height: 12),
                  HospitalDetailRow(icon: Icons.speed, label: 'Severity', value: '${trip.severity} / 10', color: sevColor),
                  if (trip.driverName != null) ...[
                    const SizedBox(height: 12),
                    HospitalDetailRow(icon: Icons.local_shipping, label: 'Ambulance', value: trip.driverName!, color: AppColors.medicalBlue),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmOrange.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.borderRadiusSm,
                      border: Border.all(color: AppColors.warmOrange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.warmOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Accepting will share live ambulance location with your hospital and notify the driver. Declining requires a reason.',
                            style: AppTypography.caption.copyWith(color: AppColors.warmOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyRed.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.borderRadiusMd,
                              border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close, size: 18, color: AppColors.emergencyRed),
                                const SizedBox(width: 6),
                                Text('Decline', style: AppTypography.bodyS.copyWith(color: AppColors.emergencyRed, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.lifelineGreen, AppColors.greenDark]),
                              borderRadius: AppSpacing.borderRadiusMd,
                              boxShadow: [BoxShadow(color: AppColors.lifelineGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, size: 18, color: AppColors.white),
                                const SizedBox(width: 6),
                                Text('Accept Patient', style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                              ],
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

  // ── Decline Reason Dialog ──

  Future<String?> _showDeclineReasonDialog(BuildContext context) {
    String? selectedReason;
    final reasons = [
      'No available beds',
      'No specialist on duty',
      'Equipment not available',
      'ER at full capacity',
      'Mass casualty event in progress',
      'Other',
    ];
    final customController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.emergencyRed, AppColors.redDark]),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.report_problem, size: 32, color: AppColors.white),
                    const SizedBox(height: 6),
                    Text('Reason for Declining', style: AppTypography.heading3.copyWith(color: AppColors.white)),
                    const SizedBox(height: 4),
                    Text('This information helps route the patient faster',
                        style: AppTypography.caption.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT A REASON', style: AppTypography.overline.copyWith(color: AppColors.mediumGray, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    ...reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedReason = reason),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.emergencyRed.withValues(alpha: 0.08) : Theme.of(ctx).scaffoldBackgroundColor,
                            borderRadius: AppSpacing.borderRadiusSm,
                            border: Border.all(
                              color: isSelected ? AppColors.emergencyRed.withValues(alpha: 0.4) : AppColors.lightGray,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18,
                                  color: isSelected ? AppColors.emergencyRed : AppColors.mediumGray),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(reason, style: AppTypography.bodyS.copyWith(
                                  color: isSelected ? AppColors.emergencyRed : Theme.of(ctx).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                )),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: 'Please specify the reason...',
                          hintStyle: AppTypography.caption.copyWith(color: AppColors.mediumGray),
                          filled: true,
                          fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightGray)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.emergencyRed)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                        style: AppTypography.bodyS,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.mediumGray.withValues(alpha: 0.1),
                                borderRadius: AppSpacing.borderRadiusMd,
                                border: Border.all(color: AppColors.mediumGray.withValues(alpha: 0.3)),
                              ),
                              child: Center(child: Text('Cancel', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray, fontWeight: FontWeight.w600))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: selectedReason == null
                                ? null
                                : () {
                                    final reason = selectedReason == 'Other'
                                        ? (customController.text.trim().isNotEmpty ? customController.text.trim() : 'Other')
                                        : selectedReason!;
                                    Navigator.of(ctx).pop(reason);
                                  },
                            child: AnimatedOpacity(
                              opacity: selectedReason == null ? 0.4 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.emergencyRed, AppColors.redDark]),
                                  borderRadius: AppSpacing.borderRadiusMd,
                                ),
                                child: Center(child: Text('Confirm Decline', style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w700))),
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
      ),
    );
  }

  // ── Handle Review Action ──

  Future<void> _handleReviewTrip(dynamic trip) async {
    final accepted = await _showTripDecisionDialog(context, trip);
    if (!mounted) return;

    if (accepted == true) {
      setState(() => _acceptedTrips.add(trip.id));
      _subscribeToLocation(trip.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: AppColors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Patient accepted — live tracking started')),
          ]),
          backgroundColor: AppColors.lifelineGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (accepted == false) {
      final reason = await _showDeclineReasonDialog(context);
      if (reason == null || !mounted) return;

      final hp = context.read<HospitalProvider>();
      final success = await hp.rejectTrip(trip.id, reason);
      if (!mounted) return;

      if (success) {
        setState(() { _declinedTrips.add(trip.id); _declineReasons[trip.id] = reason; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Patient re-routed — reason recorded')),
            ]),
            backgroundColor: AppColors.warmOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hp.error ?? 'Failed to decline trip'),
            backgroundColor: AppColors.emergencyRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildSkeletonTripCard() {
    final trip = Trip.dummy();
    final cardColor = Theme.of(context).colorScheme.surface;
    final sevColor = AppColors.warmOrange;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15)),
            child: Row(
              children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 10),
                Text(trip.incidentType.label, style: AppTypography.bodyS),
                const Spacer(),
                Text('SEV ${trip.severity}', style: AppTypography.overline),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.person, size: 15),
                  const SizedBox(width: 8),
                  Text('Driver: ${trip.driverName}', style: AppTypography.bodyS),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.confirmation_number, size: 15),
                  const SizedBox(width: 8),
                  Text('Trip: ${trip.id.substring(0, 8)}...', style: AppTypography.caption),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: const Center(child: Text('Review & Respond')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;
    final hp = context.watch<HospitalProvider>();

    // Mark first load complete once provider finishes loading
    if (!hp.isLoading && !_hasLoadedOnce) _hasLoadedOnce = true;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incoming Patients', style: AppTypography.heading3.copyWith(color: onSurface)),
                  const SizedBox(height: 2),
                  Text('${hp.incomingTrips.length} ambulances en route',
                      style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                ],
              ),
              GestureDetector(
                onTap: hp.isLoading ? null : () {
                  _hasLoadedOnce = true;
                  hp.fetchIncomingTrips();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.medicalBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: hp.isLoading && _hasLoadedOnce
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.medicalBlue),
                        )
                      : const Icon(Icons.refresh, color: AppColors.medicalBlue, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hp.isLoading && !_hasLoadedOnce)
            Expanded(
              child: Skeletonizer(
                child: ListView.separated(
                  itemCount: 2,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => _buildSkeletonTripCard(),
                ),
              ),
            )
          else if (hp.incomingTrips.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: AppColors.lifelineGreen.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No incoming patients', style: AppTypography.body.copyWith(color: AppColors.mediumGray)),
                    const SizedBox(height: 4),
                    Text('All clear for now', style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: hp.incomingTrips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trip = hp.incomingTrips[index];
                  final sevColor = trip.severity >= 7 ? AppColors.emergencyRed : AppColors.warmOrange;
                  final isAccepted = _acceptedTrips.contains(trip.id);
                  final isDeclined = _declinedTrips.contains(trip.id);
                  final distanceM = isAccepted ? _getDistanceMeters(trip.id) : -1;
                  final hasLocation = distanceM >= 0;
                  final isInRange = hasLocation && distanceM <= 500;

                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: AppSpacing.borderRadiusLg,
                      boxShadow: [BoxShadow(color: sevColor.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        // Gradient header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [sevColor, sevColor.withValues(alpha: 0.7)])),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.local_shipping, size: 16, color: AppColors.white),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(trip.incidentType.label,
                                  style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w700, color: AppColors.white))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: AppSpacing.borderRadiusFull),
                                child: Text('SEV ${trip.severity}', style: AppTypography.overline.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        // Body
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (trip.driverName != null) ...[
                                Row(children: [
                                  const Icon(Icons.person, size: 15, color: AppColors.medicalBlue),
                                  const SizedBox(width: 8),
                                  Text('Driver: ${trip.driverName}', style: AppTypography.bodyS.copyWith(color: onSurface)),
                                ]),
                                const SizedBox(height: 6),
                              ],
                              Row(children: [
                                const Icon(Icons.confirmation_number, size: 15, color: AppColors.mediumGray),
                                const SizedBox(width: 8),
                                Text('Trip: ${trip.id.substring(0, trip.id.length.clamp(0, 8))}...',
                                    style: AppTypography.caption.copyWith(color: AppColors.mediumGray)),
                              ]),
                              const SizedBox(height: 14),

                              // ── ACCEPTED ──
                              if (isAccepted) ...[
                                _buildLiveTrackingCard(distanceM, hasLocation, isInRange),
                                const SizedBox(height: 10),
                                _buildAcceptedStatus(trip, isInRange, hp),
                              ]
                              // ── DECLINED ──
                              else if (isDeclined)
                                _buildDeclinedStatus(trip)
                              // ── NOT RESPONDED ──
                              else
                                _buildRespondRow(trip),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingCard(int distanceM, bool hasLocation, bool isInRange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.medicalBlue.withValues(alpha: 0.06),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.medicalBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: isInRange ? AppColors.lifelineGreen : AppColors.medicalBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (isInRange ? AppColors.lifelineGreen : AppColors.medicalBlue).withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 8),
              Text('LIVE TRACKING', style: AppTypography.overline.copyWith(color: AppColors.medicalBlue, letterSpacing: 1.2)),
              const Spacer(),
              Icon(Icons.my_location, size: 14, color: isInRange ? AppColors.lifelineGreen : AppColors.medicalBlue),
              const SizedBox(width: 4),
              Text(
                hasLocation
                    ? (distanceM >= 1000 ? '${(distanceM / 1000).toStringAsFixed(1)} km away' : '${distanceM}m away')
                    : 'Waiting for location...',
                style: AppTypography.caption.copyWith(
                  color: hasLocation ? (isInRange ? AppColors.lifelineGreen : AppColors.medicalBlue) : AppColors.mediumGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (1.0 - (distanceM / 5000).clamp(0.0, 1.0)), minHeight: 4,
                backgroundColor: AppColors.medicalBlue.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(isInRange ? AppColors.lifelineGreen : AppColors.medicalBlue),
              ),
            ),
          ],
          if (isInRange) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.notifications_active, size: 12, color: AppColors.lifelineGreen),
              const SizedBox(width: 4),
              Text('Ambulance is within 500m — prepare for arrival',
                  style: AppTypography.caption.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptedStatus(dynamic trip, bool isInRange, HospitalProvider hp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lifelineGreen.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.lifelineGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.lifelineGreen),
          const SizedBox(width: 8),
          Expanded(child: Text('Accepted — Preparing Bay',
              style: AppTypography.bodyS.copyWith(color: AppColors.lifelineGreen, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: (isInRange && !_receivingTrips.contains(trip.id))
                ? () async {
                    setState(() => _receivingTrips.add(trip.id));
                    await hp.confirmArrival(trip.id);
                    if (context.mounted) await hp.completeTrip(trip.id);
                    if (mounted) setState(() => _receivingTrips.remove(trip.id));
                  }
                : null,
            child: AnimatedOpacity(
              opacity: (isInRange && !_receivingTrips.contains(trip.id)) ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInRange ? AppColors.hospitalTeal : AppColors.mediumGray,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isInRange ? Icons.done_all : Icons.lock_clock, size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text('Patient Received', style: AppTypography.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedStatus(dynamic trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.mediumGray.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.close, size: 18, color: AppColors.mediumGray),
            const SizedBox(width: 8),
            Text('Declined — Rerouted', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
          ]),
          if (_declineReasons.containsKey(trip.id)) ...[
            const SizedBox(height: 6),
            Row(children: [
              const SizedBox(width: 26),
              Icon(Icons.notes, size: 13, color: AppColors.mediumGray.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Expanded(child: Text('Reason: ${_declineReasons[trip.id]}',
                  style: AppTypography.caption.copyWith(color: AppColors.mediumGray, fontStyle: FontStyle.italic))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildRespondRow(dynamic trip) {
    return GestureDetector(
      onTap: () => _handleReviewTrip(trip),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.lifelineGreen, AppColors.greenDark]),
          borderRadius: AppSpacing.borderRadiusSm,
          boxShadow: [BoxShadow(color: AppColors.lifelineGreen.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active, size: 16, color: AppColors.white),
            const SizedBox(width: 6),
            Text('Review & Respond', style: AppTypography.bodyS.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
