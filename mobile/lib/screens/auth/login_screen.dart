import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/fintrack_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isPhoneMode = false;
  bool _obscurePasscode = true;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passcodeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (_isPhoneMode) {
        // Phone login flow
        await _authService.loginWithPhone(phone: identifier);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
        return;
      }

      // Email OTP flow
      await _authService.sendEmailOtp(email: identifier);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $identifier. Please check your inbox.'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
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

  Future<void> _handleVerifyAndLogin() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final identifier = _identifierController.text.trim();
      final res = await _authService.verifyEmailOtp(
        email: identifier,
        otp: otp,
      );

      if (!mounted) return;

      final userName = res['user']?['name'] ?? 'User';
      final token = res['token'] as String?;

      // Auto-grant consent defaults if needed
      if (token != null && token.isNotEmpty) {
        try {
          http.post(
            Uri.parse('${ApiConfig.baseUrl}/consent'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'upiConsent': true,
              'billStorageConsent': true,
              'aiUsageConsent': true,
            }),
          );
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, $userName!'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (_otpSent) {
              setState(() => _otpSent = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              const FinTrackLogo(size: 38, fontSize: 22),
              const SizedBox(height: 28),

              // Title
              Text(
                _otpSent ? 'Verification Code' : 'Welcome Back',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to ${_identifierController.text}'
                    : 'Sign in to access your expenses, claims, and AI copilot.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              if (!_otpSent) ...[
                // Mode Toggle: Email vs Phone
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneMode = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isPhoneMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: !_isPhoneMode ? Border.all(color: AppColors.border) : null,
                            ),
                            child: Center(
                              child: Text(
                                'Email Address',
                                style: TextStyle(
                                  color: !_isPhoneMode ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneMode = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isPhoneMode ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: _isPhoneMode ? Border.all(color: AppColors.border) : null,
                            ),
                            child: Center(
                              child: Text(
                                'Phone Number',
                                style: TextStyle(
                                  color: _isPhoneMode ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Credentials Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identifier field
                      _buildFieldLabel(_isPhoneMode ? 'MOBILE NUMBER' : 'EMAIL ADDRESS'),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: _isPhoneMode ? '9876543210' : 'samarth@example.com',
                          prefixIcon: _isPhoneMode
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.email_outlined, color: AppColors.textMuted),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your ${_isPhoneMode ? "phone number" : "email"}';
                          }
                          if (!_isPhoneMode && (!value.contains('@') || !value.contains('.'))) {
                            return 'Please enter a valid email address';
                          }
                          if (_isPhoneMode && value.trim().length != 10) {
                            return 'Please enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Passcode / Password
                      _buildFieldLabel('PASSCODE / PASSWORD'),
                      TextFormField(
                        controller: _passcodeController,
                        obscureText: _obscurePasscode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasscode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePasscode = !_obscurePasscode),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return 'Enter your passcode';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleRequestOtp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isPhoneMode ? 'Sign In Directly' : 'Send One-Time Code',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // OTP Entry Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.primary, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'One-Time Code',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sent to ${_identifierController.text}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                          color: AppColors.primary,
                        ),
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleRequestOtp,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Confirm Login
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleVerifyAndLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Verify & Sign In',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Switch to Sign Up
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don’t have an account yet?',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.signup);
                      },
                      child: const Text(
                        'Create One',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
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
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
