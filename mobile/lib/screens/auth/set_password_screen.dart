import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/fintrack_logo.dart';

class SetPasswordScreen extends StatefulWidget {
  final bool isFirstTime;
  final bool requireCurrentPassword;
  final String? email;

  const SetPasswordScreen({
    super.key,
    this.isFirstTime = false,
    this.requireCurrentPassword = false,
    this.email,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newPasswordController.text.length >= 6;
  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  bool get _effectiveIsFirstTime {
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return routeArgs?['isFirstTime'] ?? widget.isFirstTime;
  }

  bool get _effectiveRequireCurrentPassword {
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return routeArgs?['requireCurrentPassword'] ?? widget.requireCurrentPassword;
  }

  Future<void> _handleSavePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newPass = _newPasswordController.text.trim();
      final currentPass = _effectiveRequireCurrentPassword
          ? _currentPasswordController.text.trim()
          : null;

      await _authService.setPassword(
        newPassword: newPass,
        currentPassword: currentPass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password saved successfully! You can now log in with it anytime.'),
          backgroundColor: AppColors.green,
        ),
      );

      if (_effectiveIsFirstTime) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _handleSkip() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve arguments if passed via Named Route
    final isFirst = _effectiveIsFirstTime;
    final requireCurrent = _effectiveRequireCurrentPassword;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isFirst
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (isFirst)
            TextButton(
              onPressed: _handleSkip,
              child: const Text('Skip for now', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FinTrackLogo(size: 38, fontSize: 22),
                const SizedBox(height: 24),

                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  requireCurrent
                      ? 'Change Password'
                      : (isFirst ? 'Create Account Password' : 'Set Password'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  requireCurrent
                      ? 'Enter your current password and pick a new secure password.'
                      : (isFirst
                          ? 'Set a permanent password so you can sign in directly next time without waiting for email OTP codes.'
                          : 'Enter your new account password below to secure your financial profile.'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // Current Password Field (if required)
                if (requireCurrent) ...[
                  _buildFieldLabel('CURRENT PASSWORD'),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      hintText: 'Enter current password',
                      prefixIcon: const Icon(Icons.key_outlined, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // New Password Field
                _buildFieldLabel('NEW PASSWORD'),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter at least 6 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password Field
                _buildFieldLabel('CONFIRM NEW PASSWORD'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Re-enter your new password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (v != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Checklist Indicators
                Row(
                  children: [
                    _buildCheckItem('At least 6 chars', _hasMinLength),
                    const SizedBox(width: 14),
                    _buildCheckItem('Passwords match', _passwordsMatch),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Password Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _handleSavePassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            requireCurrent ? 'Update Password' : 'Save Password',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                if (isFirst) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _handleSkip,
                      child: const Text(
                        'I’ll do this later',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isSatisfied) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isSatisfied ? AppColors.green : AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: isSatisfied ? AppColors.green : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSatisfied ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
