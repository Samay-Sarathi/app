import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/trip_provider.dart';
import '../../widgets/buttons.dart';

class SeverityRatingScreen extends StatefulWidget {
  final String caseType;
  final String incidentType; // backend IncidentType value e.g. "CARDIAC"
  const SeverityRatingScreen({
    super.key,
    required this.caseType,
    this.incidentType = 'CARDIAC',
  });

  @override
  State<SeverityRatingScreen> createState() => _SeverityRatingScreenState();
}

class _SeverityRatingScreenState extends State<SeverityRatingScreen> {
  double _severity = 7;
  int _selectedLevel = 0; // 0=critical, 1=serious, 2=stable

  Color get _severityColor {
    if (_severity >= 7) return AppColors.emergencyRed;
    if (_severity >= 4) return AppColors.warmOrange;
    return AppColors.softYellow;
  }

  Future<void> _findHospital(BuildContext context) async {
    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = GoRouter.of(context);

    // Use mock pickup coordinates (Delhi center — replace with real GPS later)
    const pickupLat = 28.6139;
    const pickupLng = 77.2090;

    // Step 1: Create trip
    final created = await tripProvider.createTrip(
      incidentType: widget.incidentType,
      severity: _severity.round(),
      pickupLatitude: pickupLat,
      pickupLongitude: pickupLng,
    );

    if (!mounted) return;

    if (!created) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Failed to create trip'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      return;
    }

    // Step 2: Fetch recommendations
    final fetched = await tripProvider.fetchRecommendations();
    if (!mounted) return;

    if (!fetched) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Failed to get recommendations'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
      // Still navigate — screen will show empty/error state
    }

    nav.go('/driver/hospital-select');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => context.go('/driver/emergency-case'),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: onSurface),
                    const SizedBox(width: 12),
                    Text('Back', style: AppTypography.body.copyWith(color: onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Rate the severity',
                  style: AppTypography.heading2.copyWith(color: onSurface),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  widget.caseType,
                  style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                ),
              ),
              const SizedBox(height: 32),

              // Severity number
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _severityColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _severity.round().toString(),
                      style: AppTypography.displayL.copyWith(
                        color: _severityColor,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _severityColor,
                  inactiveTrackColor: AppColors.lightGray,
                  thumbColor: _severityColor,
                  overlayColor: _severityColor.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _severity,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => setState(() {
                    _severity = v;
                    if (v >= 7) {
                      _selectedLevel = 0;
                    } else if (v >= 4) {
                      _selectedLevel = 1;
                    } else {
                      _selectedLevel = 2;
                    }
                  }),
                ),
              ),

              // Color indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 20, height: 8, decoration: BoxDecoration(color: AppColors.lifelineGreen, borderRadius: BorderRadius.circular(4))),
                    Container(width: 20, height: 8, decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(4))),
                    Container(width: 20, height: 8, decoration: BoxDecoration(color: AppColors.warmOrange, borderRadius: BorderRadius.circular(4))),
                    Container(width: 20, height: 8, decoration: BoxDecoration(color: AppColors.emergencyRed, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Level buttons
              _LevelButton(
                label: 'CRITICAL',
                color: AppColors.emergencyRed,
                isSelected: _selectedLevel == 0,
                onTap: () => setState(() { _selectedLevel = 0; _severity = 9; }),
              ),
              const SizedBox(height: 12),
              _LevelButton(
                label: 'SERIOUS',
                color: AppColors.warmOrange,
                isSelected: _selectedLevel == 1,
                onTap: () => setState(() { _selectedLevel = 1; _severity = 5; }),
              ),
              const SizedBox(height: 12),
              _LevelButton(
                label: 'STABLE',
                color: AppColors.softYellow,
                isSelected: _selectedLevel == 2,
                onTap: () => setState(() { _selectedLevel = 2; _severity = 2; }),
              ),

              const Spacer(),

              PrimaryButton(
                label: context.watch<TripProvider>().isLoading
                    ? 'Finding hospitals...'
                    : 'Find Best Hospital',
                icon: Icons.local_hospital,
                isLoading: context.watch<TripProvider>().isLoading,
                onPressed: context.watch<TripProvider>().isLoading
                    ? null
                    : () => _findHospital(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
