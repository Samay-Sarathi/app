import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LifelineBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LifelineNavItem> items;

  const LifelineBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final navColor = Theme.of(context).colorScheme.surface;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: navColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -4),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = index == currentIndex;
            final item = items[index];
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 28,
                      color: isActive ? AppColors.lifelineGreen : AppColors.mediumGray,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.lifelineGreen : AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class LifelineNavItem {
  final IconData icon;
  final String label;
  const LifelineNavItem({required this.icon, required this.label});
}
