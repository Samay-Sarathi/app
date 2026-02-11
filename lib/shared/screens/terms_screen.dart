import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// Terms of Service screen with static legal content.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: onSurface),
                    const SizedBox(width: 12),
                    Text('Terms of Service',
                        style: AppTypography.heading3
                            .copyWith(color: onSurface)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadiusCard,
                  ),
                  child: ListView(
                    children: [
                      _Section(
                        title: '1. Acceptance of Terms',
                        body:
                            'By accessing and using the LifeLine application, you agree '
                            'to be bound by these Terms of Service. If you do not agree '
                            'to these terms, please do not use the application.',
                      ),
                      _Section(
                        title: '2. Description of Service',
                        body:
                            'LifeLine provides an emergency response coordination platform '
                            'connecting ambulance drivers, hospitals, paramedics, and traffic '
                            'police. The service includes real-time GPS tracking, hospital '
                            'matching, green corridor management, and vital signs monitoring.',
                      ),
                      _Section(
                        title: '3. User Responsibilities',
                        body:
                            'Users are responsible for maintaining the accuracy of their '
                            'profile information, using the application only for authorized '
                            'emergency response purposes, and complying with all applicable '
                            'laws and regulations.',
                      ),
                      _Section(
                        title: '4. Data and Privacy',
                        body:
                            'LifeLine collects location data, device information, and '
                            'emergency-related data to provide its services. All data is '
                            'handled in accordance with our Privacy Policy and applicable '
                            'data protection regulations.',
                      ),
                      _Section(
                        title: '5. Limitation of Liability',
                        body:
                            'LifeLine is provided "as is" and the developers make no '
                            'warranties regarding the reliability, accuracy, or availability '
                            'of the service. LifeLine shall not be liable for any damages '
                            'arising from the use or inability to use the application.',
                      ),
                      _Section(
                        title: '6. Changes to Terms',
                        body:
                            'We reserve the right to modify these terms at any time. '
                            'Continued use of the application after changes constitutes '
                            'acceptance of the new terms.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Last updated: February 2025',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.mediumGray),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w700, color: onSurface)),
          const SizedBox(height: 8),
          Text(body,
              style: AppTypography.bodyS
                  .copyWith(color: onSurface, height: 1.6)),
        ],
      ),
    );
  }
}
