import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceXl),
          child: Column(
            children: [
              // QR Scanner button (top right)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => context.go('/paramedic/scan'),
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan QR to assist',
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 8),
              SvgPicture.asset(
                'assets/icons/lifeline_logo.svg',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 12),
              Text(
                'LIFELINE',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emergency Access Portal',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
              ),
              const SizedBox(height: 4),
              Text(
                'Every Second Counts \u2014 Emergency Response at Your Fingertips',
                style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _RoleCard(
                      svgAsset: 'assets/icons/icon_ambulance.svg',
                      label: 'Ambulance\nDriver',
                      color: AppColors.medicalBlue,
                      onTap: () => context.go('/sign-in', extra: 'driver'),
                    ),
                    _RoleCard(
                      icon: Icons.local_hospital,
                      label: 'Hospital',
                      color: AppColors.lifelineGreen,
                      onTap: () => context.go('/sign-in', extra: 'hospital'),
                    ),
                    _RoleCard(
                      svgAsset: 'assets/icons/icon_traffic_police.svg',
                      label: 'Traffic\nPolice',
                      color: AppColors.calmPurple,
                      onTap: () => context.go('/sign-in', extra: 'police'),
                    ),
                    _RoleCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Admin',
                      color: AppColors.warmOrange,
                      onTap: () => context.go('/sign-in', extra: 'admin'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.language, size: 18, color: AppColors.mediumGray),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox.shrink(),
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLanguage = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Emergency: 108',
                style: AppTypography.caption.copyWith(color: AppColors.mediumGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double containerSize;

  const _RoleCard({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconSize = 28,
    this.containerSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppSpacing.borderRadiusCard,
          boxShadow: isDark ? AppSpacing.shadowSmDark : AppSpacing.shadowSm,
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: svgAsset != null
                    ? SvgPicture.asset(
                        svgAsset!,
                        width: iconSize,
                        height: iconSize,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      )
                    : Icon(icon, size: iconSize, color: color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
