import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendEmailOtp(email: email);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to $email. Please check your inbox.'),
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
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP sent to your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _authService.verifyEmailOtp(
        email: email,
        otp: otp,
        name: name.isNotEmpty ? name : null,
        phone: phone.isNotEmpty ? phone : null,
      );

      if (!mounted) return;

      final userName = res['user']?['name'] ?? 'User';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, $userName!'),
          backgroundColor: AppColors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Brand Logo
              const FinTrackLogo(
                size: 40,
                fontSize: 24,
              ),
              const SizedBox(height: 32),

              // Title & Subtitle
              Text(
                _otpSent ? 'Enter Email OTP' : 'Sign in with Email',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to ${_emailController.text}'
                    : 'Enter your email to sign in or create a fresh account. We will send a one-time verification code.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              if (!_otpSent) ...[
                // Name Input Field (Optional for new users)
                const Text(
                  'YOUR FULL NAME (OPTIONAL)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ritesh Jadhav',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 18),

                // Email Input Field
                const Text(
                  'WORK OR PERSONAL EMAIL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'you@company.com or you@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 18),

                // Mobile Number Input Field (User defined)
                const Text(
                  'MOBILE NUMBER (USER DEFINED)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 9820012345',
                    prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted),
                    prefixText: '+91 ',
                    prefixStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Send Verification Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ] else ...[


                // OTP Input State
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10,
                        ),
                        decoration: const InputDecoration(
                          hintText: '• • • • • •',
                          counterText: '',
                          fillColor: AppColors.surfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _otpSent = false),
                            child: const Text('Change Email', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ),
                          TextButton(
                            onPressed: _handleSendOtp,
                            child: const Text('Resend Code', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Verify & Sign In CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyAndLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify & Enter Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Security Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.green, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DPDP Act & RBI AA Compliant. Accounts and ledgers are completely isolated per authenticated user.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
