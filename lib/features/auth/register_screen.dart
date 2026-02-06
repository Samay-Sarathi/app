import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_role.dart';
import '../../widgets/buttons.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = _mapStringToRole(widget.role);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  UserRole _mapStringToRole(String role) {
    switch (role) {
      case 'driver':
        return UserRole.driver;
      case 'hospital':
        return UserRole.hospital;
      case 'police':
        return UserRole.police;
      case 'admin':
        return UserRole.admin;
      case 'paramedic':
        return UserRole.paramedic;
      default:
        return UserRole.driver;
    }
  }

  Color get _roleColor {
    switch (_selectedRole) {
      case UserRole.driver:
        return AppColors.medicalBlue;
      case UserRole.police:
        return AppColors.calmPurple;
      case UserRole.hospital:
        return AppColors.hospitalTeal;
      case UserRole.admin:
        return AppColors.warmOrange;
      case UserRole.paramedic:
        return AppColors.lifelineGreen;
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.register(
      phoneNumber: _phoneController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );
    if (!mounted) return;

    if (success) {
      context.go(auth.dashboardRoute);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppColors.emergencyRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spaceXl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => context.go('/sign-in', extra: widget.role),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: onSurface),
                      const SizedBox(width: 8),
                      Text('Back to Sign In', style: AppTypography.body.copyWith(color: onSurface)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Header
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.person_add, size: 32, color: _roleColor),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Create Account',
                    style: AppTypography.heading2.copyWith(color: onSurface),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Join LifeLine as ${_selectedRole.label}',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                  ),
                ),
                const SizedBox(height: 32),

                // Full name
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+919876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (v.trim().length < 10) return 'Invalid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role selector
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),
                  onChanged: (role) {
                    if (role != null) setState(() => _selectedRole = role);
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Min 8 characters',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: auth.isLoading ? 'Creating account...' : 'Register',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/sign-in', extra: widget.role),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                        children: [
                          TextSpan(
                            text: 'Sign In →',
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
      ),
    );
  }
}
