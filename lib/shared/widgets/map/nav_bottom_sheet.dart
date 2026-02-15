import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/navigation_helpers.dart';

/// Draggable bottom sheet for the navigation screen.
///
/// Shows ETA, distance, speed pill, destination name, and action buttons.
/// Uses theme colors instead of hardcoded Colors.white.
class NavBottomSheet extends StatelessWidget {
  final int remainingDurationSeconds;
  final int remainingDistanceMeters;
  final double currentSpeed;
  final String destinationName;
  final IconData destinationIcon;
  final Color destinationIconColor;
  final List<Widget> actions;

  const NavBottomSheet({
    super.key,
    required this.remainingDurationSeconds,
    required this.remainingDistanceMeters,
    required this.currentSpeed,
    required this.destinationName,
    this.destinationIcon = Icons.local_hospital,
    this.destinationIconColor = const Color(0xFFE63946),
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleGray = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100]!;
    final textSecondary = isDark ? Colors.white70 : Colors.grey[600]!;

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.40,
      snapSizes: const [0.25, 0.40],
      snap: true,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ETA row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NavigationHelpers.formatEta(remainingDurationSeconds),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navBlue,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NavigationHelpers.formatDistance(remainingDistanceMeters),
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Speed pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: subtleGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, size: 18, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${currentSpeed.round()} km/h',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Destination
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: subtleGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(destinationIcon, color: destinationIconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        destinationName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: actions),
              ],

              const SizedBox(height: 8),
            ],
          ),
            ),
          ),
        );
      },
    );
  }
}
