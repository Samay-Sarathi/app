import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons.dart';

class SignInScreen extends StatefulWidget {
  final String role;
  const SignInScreen({super.key, required this.role});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;

  IconData get _roleIcon {
    switch (widget.role) {
      case 'driver':
        return Icons.local_shipping;
      case 'police':
        return Icons.shield;
      case 'hospital':
        return Icons.local_hospital;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color get _roleColor {
    switch (widget.role) {
      case 'driver':
        return AppColors.medicalBlue;
      case 'police':
        return AppColors.calmPurple;
      case 'hospital':
        return AppColors.hospitalTeal;
      case 'admin':
        return AppColors.warmOrange;
      default:
        return AppColors.lifelineGreen;
    }
  }

  String get _roleLabel {
    switch (widget.role) {
      case 'driver':
        return 'Driver';
      case 'police':
        return 'Police';
      case 'hospital':
        return 'Hospital';
      case 'admin':
        return 'Admin';
      default:
        return '';
    }
  }

  String get _dashboardRoute {
    switch (widget.role) {
      case 'driver':
        return '/driver/dashboard';
      case 'police':
        return '/driver/dashboard';
      case 'hospital':
        return '/hospital/capacity';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/driver/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spaceXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/roles'),
                    child: Icon(Icons.arrow_back, color: onSurface),
                  ),
                  GestureDetector(
                    onTap: () => context.go(_dashboardRoute),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.lifelineGreen.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        'Demo',
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.lifelineGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_roleIcon, size: 40, color: _roleColor),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$_roleLabel Sign-In',
                  style: AppTypography.heading2.copyWith(color: onSurface),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: AppTypography.bodyS.copyWith(color: AppColors.medicalBlue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GhostButton(
                label: 'Sign In with Biometrics',
                icon: Icons.fingerprint,
                onPressed: () => context.go(_dashboardRoute),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Sign In',
                onPressed: () => context.go(_dashboardRoute),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: RichText(
                    text: TextSpan(
                      text: 'New here? ',
                      style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                      children: [
                        TextSpan(
                          text: 'Register →',
                          style: AppTypography.bodyS.copyWith(
                            color: AppColors.lifelineGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
