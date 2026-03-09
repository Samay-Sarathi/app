import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_role.dart';
import '../../../core/services/document_service.dart';
import '../../../shared/widgets/buttons.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Required fields (sent to backend) ──
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Optional role-specific fields (UI only, stored later) ──
  final _documentService = DocumentService();
  // Driver
  final _ambulanceNumberController = TextEditingController();
  String? _govtIdFileName;
  PlatformFile? _govtIdFile;
  // Hospital
  final _hospitalNameController = TextEditingController();
  final _hospitalNumberController = TextEditingController();
  String? _hospitalProofFileName;
  PlatformFile? _hospitalProofFile;
  // Police
  final _deptNameController = TextEditingController();
  final _areaNameController = TextEditingController();
  String? _policeIdFileName;
  PlatformFile? _policeIdFile;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ambulanceNumberController.dispose();
    _hospitalNameController.dispose();
    _hospitalNumberController.dispose();
    _deptNameController.dispose();
    _areaNameController.dispose();
    super.dispose();
  }

  // ── Role helpers ──

  bool get _isDriver => widget.role == 'driver';
  bool get _isHospital => widget.role == 'hospital';
  bool get _isPolice => widget.role == 'police';

  Color get _roleColor {
    if (_isDriver) return AppColors.medicalBlue;
    if (_isHospital) return AppColors.hospitalTeal;
    if (_isPolice) return AppColors.calmPurple;
    return AppColors.lifelineGreen;
  }

  String get _roleLabel {
    if (_isDriver) return 'Ambulance Driver';
    if (_isHospital) return 'Hospital';
    if (_isPolice) return 'Traffic Police';
    return '';
  }

  UserRole get _userRole {
    if (_isDriver) return UserRole.driver;
    if (_isHospital) return UserRole.hospital;
    if (_isPolice) return UserRole.police;
    return UserRole.driver;
  }

  String get _nameHint {
    if (_isDriver) return 'e.g. Ravi Kumar';
    if (_isHospital) return 'e.g. Dr. Anand Patel';
    if (_isPolice) return 'e.g. Inspector Singh';
    return 'Enter your full name';
  }

  String get _nameLabel {
    if (_isDriver) return 'Driver\'s Full Name';
    if (_isHospital) return 'Contact Person Name';
    if (_isPolice) return 'Officer\'s Full Name';
    return 'Full Name';
  }

  // ── File picker ──

  Future<void> _pickDocument(String fieldName) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    setState(() {
      if (fieldName == 'govtId') {
        _govtIdFileName = file.name;
        _govtIdFile = file;
      } else if (fieldName == 'hospitalProof') {
        _hospitalProofFileName = file.name;
        _hospitalProofFile = file;
      } else if (fieldName == 'policeId') {
        _policeIdFileName = file.name;
        _policeIdFile = file;
      }
    });
  }

  Future<void> _uploadPendingDocuments() async {
    final filesToUpload = <(PlatformFile, String)>[];
    if (_govtIdFile?.path != null) filesToUpload.add((_govtIdFile!, 'GOVT_ID'));
    if (_hospitalProofFile?.path != null) filesToUpload.add((_hospitalProofFile!, 'HOSPITAL_PROOF'));
    if (_policeIdFile?.path != null) filesToUpload.add((_policeIdFile!, 'POLICE_ID'));

    for (final (file, docType) in filesToUpload) {
      try {
        await _documentService.uploadDocument(
          filePath: file.path!,
          fileName: file.name,
          documentType: docType,
        );
      } catch (_) {
        // Non-critical — documents can be re-uploaded later
      }
    }
  }

  // ── Registration handler — sends only backend-compatible fields ──

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final phone = _phoneController.text.trim();
    final phoneNumber = '+91${phone.replaceAll(RegExp(r'[^\d]'), '')}';

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await auth.register(
      phoneNumber: phoneNumber,
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
      role: _userRole,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      // Upload any selected documents in the background
      await _uploadPendingDocuments();
      if (!mounted) return;
      router.go(auth.dashboardRoute);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Admin should never reach this screen
    if (widget.role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/sign-in', extra: 'admin');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                // ── Back button ──
                GestureDetector(
                  onTap: () => context.go('/sign-in', extra: widget.role),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: onSurface, size: 20),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Header ──
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.person_add, size: 32, color: _roleColor),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    '$_roleLabel Registration',
                    style: AppTypography.heading2.copyWith(color: onSurface),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Create your LifeLine account',
                    style: AppTypography.bodyS.copyWith(color: AppColors.mediumGray),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Role-specific form ──
                if (_isDriver) _buildDriverForm(onSurface),
                if (_isHospital) _buildHospitalForm(onSurface),
                if (_isPolice) _buildPoliceForm(onSurface),

                const SizedBox(height: 28),

                // ── Register button ──
                PrimaryButton(
                  label: auth.isLoading ? 'Creating account...' : 'Register',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: 20),

                // ── Back to sign in ──
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

  // ═══════════════════════════════════════════════════════════
  // SHARED: Required credential fields (phone + password)
  // These map directly to backend RegisterRequest DTO
  // ═══════════════════════════════════════════════════════════

  Widget _buildCredentialFields(Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Account Credentials', Icons.lock_outlined),
        const SizedBox(height: 12),

        // Full Name
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _nameLabel,
            hintText: _nameHint,
            prefixIcon: const Icon(Icons.person_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Name is required';
            if (v.trim().length < 2) return 'Name is too short';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone Number
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter 10-digit number',
            prefixIcon: Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                '+91',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone number is required';
            final digits = v.replaceAll(RegExp(r'[^\d]'), '');
            if (digits.length != 10) return 'Enter a valid 10-digit phone number';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email (optional)
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (optional)',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v != null && v.trim().isNotEmpty) {
              final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // PIN
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: '6-Digit PIN',
            hintText: 'Enter a 6-digit PIN',
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
            if (v == null || v.isEmpty) return 'PIN is required';
            if (v.length != 6) return 'PIN must be exactly 6 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm PIN
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: 'Confirm PIN',
            hintText: 'Re-enter your 6-digit PIN',
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
            if (v != _passwordController.text) return 'PINs do not match';
            return null;
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DRIVER REGISTRATION FORM
  // Required: name, phone, password (via _buildCredentialFields)
  // Optional: ambulance number, govt ID upload
  // ═══════════════════════════════════════════════════════════

  Widget _buildDriverForm(Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required credentials first
        _buildCredentialFields(onSurface),
        const SizedBox(height: 28),

        // Optional role-specific fields
        _buildSectionLabel('Additional Details', Icons.local_shipping_outlined),
        _buildOptionalTag(),
        const SizedBox(height: 12),

        TextFormField(
          controller: _ambulanceNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Ambulance Number',
            hintText: 'e.g. DL-01-AB-1234',
            prefixIcon: Icon(Icons.local_shipping_outlined),
          ),
          // No validator — optional
        ),
        const SizedBox(height: 16),

        _buildFileUploadField(
          label: 'Government ID',
          hint: 'Upload driving license or Aadhaar',
          fileName: _govtIdFileName,
          onTap: () => _pickDocument('govtId'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOSPITAL REGISTRATION FORM
  // Required: name, phone, password (via _buildCredentialFields)
  // Optional: hospital name, govt registration number, proof
  // ═══════════════════════════════════════════════════════════

  Widget _buildHospitalForm(Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required credentials first
        _buildCredentialFields(onSurface),
        const SizedBox(height: 28),

        // Optional role-specific fields
        _buildSectionLabel('Hospital Details', Icons.local_hospital_outlined),
        _buildOptionalTag(),
        const SizedBox(height: 12),

        TextFormField(
          controller: _hospitalNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Hospital Name',
            hintText: 'e.g. AIIMS Delhi',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Hospital Email (Optional)',
            hintText: 'e.g. contact@hospital.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _hospitalNumberController,
          decoration: const InputDecoration(
            labelText: 'Govt. Registration Number',
            hintText: 'e.g. REG-2024-XXXXX',
            prefixIcon: Icon(Icons.numbers_outlined),
          ),
        ),
        const SizedBox(height: 16),

        _buildFileUploadField(
          label: 'Hospital Registration Proof',
          hint: 'Upload govt. registration certificate',
          fileName: _hospitalProofFileName,
          onTap: () => _pickDocument('hospitalProof'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // POLICE REGISTRATION FORM
  // Required: name, phone, password (via _buildCredentialFields)
  // Optional: department name, area, police ID
  // ═══════════════════════════════════════════════════════════

  Widget _buildPoliceForm(Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required credentials first
        _buildCredentialFields(onSurface),
        const SizedBox(height: 28),

        // Optional role-specific fields
        _buildSectionLabel('Department Details', Icons.shield_outlined),
        _buildOptionalTag(),
        const SizedBox(height: 12),

        TextFormField(
          controller: _deptNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Department Name',
            hintText: 'e.g. Delhi Traffic Police',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _areaNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Area / Jurisdiction',
            hintText: 'e.g. South Delhi',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),

        _buildFileUploadField(
          label: 'Police ID / Govt Document',
          hint: 'Upload police ID or authorization letter',
          fileName: _policeIdFileName,
          onTap: () => _pickDocument('policeId'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _roleColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.caption.copyWith(
            color: _roleColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalTag() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'These fields are optional for now — will be required in future updates.',
        style: AppTypography.caption.copyWith(
          color: AppColors.mediumGray,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required String hint,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasFile = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile
              ? _roleColor.withValues(alpha: 0.06)
              : onSurface.withValues(alpha: 0.03),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: hasFile
                ? _roleColor.withValues(alpha: 0.3)
                : onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (hasFile ? _roleColor : AppColors.mediumGray)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: hasFile ? _roleColor : AppColors.mediumGray,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? fileName : hint,
                    style: AppTypography.caption.copyWith(
                      color: hasFile ? _roleColor : AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.attach_file,
              size: 18,
              color: AppColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }
}
