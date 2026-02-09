import 'package:flutter/material.dart';

/// Reusable action button for map navigation panels.
///
/// Displays an icon above a label with a tinted background.
/// Typically wrapped in [Expanded] and used inside a [Row] within [NavBottomPanel].
///
/// ```dart
/// Expanded(
///   child: MapActionButton(
///     icon: Icons.bolt,
///     label: 'Corridor',
///     color: AppColors.lifelineGreen,
///     onTap: () => ...,
///   ),
/// )
/// ```
class MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const MapActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
