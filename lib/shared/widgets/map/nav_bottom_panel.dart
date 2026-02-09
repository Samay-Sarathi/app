import 'package:flutter/material.dart';
import '../../../core/utils/navigation_helpers.dart';

/// Bottom panel for navigation screens showing ETA, speed, destination, and actions.
///
/// Designed to be placed in a Stack as a bottom-positioned element.
/// The [actions] list is used as children of a Row — callers provide
/// Expanded-wrapped [MapActionButton]s with SizedBox spacers between them.
///
/// Usage (inside a Stack):
/// ```dart
/// Positioned(
///   bottom: 0, left: 0, right: 0,
///   child: NavBottomPanel(
///     remainingDurationSeconds: 600,
///     remainingDistanceMeters: 5000,
///     currentSpeed: 45.0,
///     destinationName: 'Central Hospital',
///     actions: [ ... ],
///   ),
/// )
/// ```
class NavBottomPanel extends StatelessWidget {
  final int remainingDurationSeconds;
  final int remainingDistanceMeters;
  final double currentSpeed;
  final String destinationName;
  final IconData destinationIcon;
  final Color destinationIconColor;
  final List<Widget> actions;

  const NavBottomPanel({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ETA row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NavigationHelpers.formatEta(remainingDurationSeconds),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NavigationHelpers.formatDistance(remainingDistanceMeters),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Speed pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          '${currentSpeed.round()} km/h',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
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
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(destinationIcon, color: destinationIconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        destinationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
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
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
