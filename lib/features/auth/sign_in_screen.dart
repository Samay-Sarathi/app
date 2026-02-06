import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/buttons.dart';

class SignInScreen extends StatefulWidget {
  final String role;
  const SignInScreen({super.key, required this.role});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Role helpers ──

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
        return 'Ambulance Driver';
      case 'police':
        return 'Traffic Police';
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

  bool get _isAdmin => widget.role == 'admin';

  // ── Actions ──

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showError('Please enter phone number and password');
      return;
    }

    // Prepend +91 if user entered raw 10-digit number
    final phoneNumber =
        phone.startsWith('+') ? phone : '+91$phone';

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success =
        await auth.login(phoneNumber: phoneNumber, password: password);

    if (!mounted) return;

    if (success) {
      router.go(auth.dashboardRoute);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm),
        ),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.emergencyRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/roles'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back,
                            color: onSurface, size: 20),
                      ),
                    ),
                    // Demo bypass
                    GestureDetector(
                      onTap: () => context.go(_dashboardRoute),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              AppColors.lifelineGreen.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          'Demo →',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lifelineGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Role icon + title ──
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_roleIcon, size: 36, color: _roleColor),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _roleLabel,
                    style:
                        AppTypography.heading2.copyWith(color: onSurface),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Sign In',
                    style: AppTypography.bodyS
                        .copyWith(color: AppColors.mediumGray),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Dev-mode info badge ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.06),
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: _roleColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: _roleColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dev mode — use seed credentials\n'
                          'Phone: +9191000000XX  •  Pass: password123',
                          style: AppTypography.caption.copyWith(
                            color: _roleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Phone number field ──
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[\d+]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+919100000001',
                    prefixIcon: Container(
                      width: 52,
                      alignment: Alignment.center,
                      child: Text(
                        '📱',
                        style: AppTypography.body
                            .copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Password field ──
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 28),

                // ── Sign in button ──
                PrimaryButton(
                  label:
                      auth.isLoading ? 'Signing in...' : 'Sign In',
                  isLoading: auth.isLoading,
                  onPressed:
                      auth.isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: 28),

                // ── Register link (NOT for Admin) ──
                if (!_isAdmin)
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register',
                          extra: widget.role),
                      child: RichText(
                        text: TextSpan(
                          text: 'New here? ',
                          style: AppTypography.bodyS
                              .copyWith(color: AppColors.mediumGray),
                          children: [
                            TextSpan(
                              text: 'Register →',
                              style: AppTypography.bodyS.copyWith(
                                color: _roleColor,
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
      ),
    );
  }
}
