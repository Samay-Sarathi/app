import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/map/map_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/models/hospital_recommendation.dart';
import '../../widgets/buttons.dart';
import '../../core/widgets/map_placeholder.dart';

class HospitalSelectionScreen extends StatefulWidget {
  const HospitalSelectionScreen({super.key});

  @override
  State<HospitalSelectionScreen> createState() => _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 0;

  Set<Marker> _buildMarkers(List<HospitalRecommendation> recs) {
    if (!AppConfig.enableMaps || recs.isEmpty) return {};
    final markers = <Marker>{};
    for (int i = 0; i < recs.length; i++) {
      final h = recs[i];
      markers.add(Marker(
        markerId: MarkerId(h.hospitalId),
        position: LatLng(h.latitude, h.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          h.isRecommended ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueCyan,
        ),
        infoWindow: InfoWindow(
          title: h.hospitalName,
          snippet: h.isRecommended ? 'Recommended' : '${h.distanceKm.toStringAsFixed(1)} km',
        ),
        onTap: () => setState(() => _selectedIndex = i),
      ));
    }
    // Add user location marker
    final trip = context.read<TripProvider>().activeTrip;
    if (trip != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(trip.pickupLatitude, trip.pickupLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    return markers;
  }

  @override
  void initState() {
    super.initState();
    // Default select the recommended hospital
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recs = context.read<TripProvider>().recommendations;
      final idx = recs.indexWhere((r) => r.isRecommended);
      if (idx >= 0) setState(() => _selectedIndex = idx);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _selectHospital(BuildContext context, HospitalRecommendation hospital) async {
    // Show confirmation dialog before proceeding
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: Row(
          children: [
            const Icon(Icons.local_hospital, color: AppColors.emergencyRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Confirm Hospital',
                style: AppTypography.heading3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.hospitalName,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _ConfirmInfoRow(icon: Icons.timer, text: 'ETA: ${hospital.etaMinutes} minutes'),
            const SizedBox(height: 6),
            _ConfirmInfoRow(icon: Icons.bed, text: '${hospital.bedAvailable} beds available'),
            const SizedBox(height: 6),
            _ConfirmInfoRow(icon: Icons.route, text: '${hospital.distanceKm.toStringAsFixed(1)} km away'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warmOrange.withValues(alpha: 0.1),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.warmOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your live location will be shared with the hospital and traffic police. A QR code will be generated for paramedic handoff.',
                      style: AppTypography.caption.copyWith(color: AppColors.warmOrange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lifelineGreen,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Navigate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = GoRouter.of(context);
    final success = await tripProvider.lockHospital(
      hospital.hospitalId,
      etaSeconds: hospital.etaMinutes * 60,
    );
    if (!mounted) return;

    if (success) {
      nav.go('/driver/navigation');
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Failed to lock hospital'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cardColor = theme.colorScheme.surface;
    final tripProvider = context.watch<TripProvider>();
    final recommendations = tripProvider.recommendations;
    final hasRecs = recommendations.isNotEmpty;
    final selected = hasRecs
        ? recommendations[_selectedIndex.clamp(0, recommendations.length - 1)]
        : null;
    final markers = _buildMarkers(recommendations);
    final totalBeds = recommendations.fold<int>(0, (sum, r) => sum + r.bedAvailable);

    return Scaffold(
      body: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceMd),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/driver/severity'),
                    child: Icon(Icons.arrow_back, color: onSurface),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.bar_chart, size: 20, color: AppColors.medicalBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasRecs
                          ? '$totalBeds Available ER Beds'
                          : 'Loading hospitals...',
                      style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600, color: onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: AppConfig.enableMaps && markers.isNotEmpty
                ? GoogleMap(
                    initialCameraPosition: selected != null
                        ? CameraPosition(
                            target: LatLng(selected.latitude, selected.longitude),
                            zoom: 13,
                          )
                        : MapConfig.overviewCamera,
                    markers: markers,
                    liteModeEnabled: true,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  )
                : MapPlaceholder.hospitalSelect(),
          ),

          // Hospital list / detail
          if (hasRecs && selected != null)
            _HospitalDetailCard(
              recommendation: selected,
              isLoading: tripProvider.isLoading,
              onSelect: () => _selectHospital(context, selected),
              onNext: recommendations.length > 1
                  ? () => setState(() =>
                      _selectedIndex = (_selectedIndex + 1) % recommendations.length)
                  : null,
              onPrev: recommendations.length > 1
                  ? () => setState(() => _selectedIndex =
                      (_selectedIndex - 1 + recommendations.length) %
                          recommendations.length)
                  : null,
              currentIndex: _selectedIndex,
              totalCount: recommendations.length,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.spaceLg),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  if (tripProvider.isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    Text(
                      'No hospitals found',
                      style: AppTypography.heading3.copyWith(color: onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tripProvider.error ?? 'Try again later',
                      style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HospitalDetailCard extends StatelessWidget {
  final HospitalRecommendation recommendation;
  final bool isLoading;
  final VoidCallback onSelect;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final int currentIndex;
  final int totalCount;

  const _HospitalDetailCard({
    required this.recommendation,
    required this.isLoading,
    required this.onSelect,
    this.onNext,
    this.onPrev,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation arrows + hospital name
          Row(
            children: [
              if (onPrev != null)
                GestureDetector(
                  onTap: onPrev,
                  child: Icon(Icons.chevron_left, color: onSurface),
                ),
              Expanded(
                child: Text(
                  recommendation.hospitalName,
                  style: AppTypography.heading3.copyWith(color: onSurface),
                ),
              ),
              if (recommendation.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.lifelineGreen),
                      const SizedBox(width: 4),
                      Text(
                        'RECOMMENDED',
                        style: AppTypography.overline.copyWith(color: AppColors.lifelineGreen),
                      ),
                    ],
                  ),
                ),
              if (onNext != null)
                GestureDetector(
                  onTap: onNext,
                  child: Icon(Icons.chevron_right, color: onSurface),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${currentIndex + 1} of $totalCount hospitals • Score: ${recommendation.score}',
            style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.timer,
                label: '${recommendation.etaMinutes}m ETA',
              ),
              const SizedBox(width: 16),
              _InfoChip(
                icon: Icons.bed,
                label: '${recommendation.bedAvailable} Beds',
              ),
              const Spacer(),
              Text(
                '${recommendation.distanceKm.toStringAsFixed(1)} km',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (recommendation.specialties.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: recommendation.specialties.map((s) {
                return Chip(
                  label: Text(s, style: AppTypography.caption),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: isLoading ? 'Locking hospital...' : 'Select Hospital →',
            isLoading: isLoading,
            onPressed: isLoading ? null : onSelect,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.mediumGray),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
      ],
    );
  }
}

class _ConfirmInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ConfirmInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mediumGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray)),
        ),
      ],
    );
  }
}
