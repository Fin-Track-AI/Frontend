import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';
import '../../services/claim_service.dart';

class EmployerLinkScreen extends StatefulWidget {
  final bool isStandalone;

  const EmployerLinkScreen({super.key, this.isStandalone = false});

  @override
  State<EmployerLinkScreen> createState() => _EmployerLinkScreenState();
}

class _EmployerLinkScreenState extends State<EmployerLinkScreen> {
  final TextEditingController _codeController = TextEditingController();
  final ClaimService _claimService = ClaimService();

  bool _isVerifying = false;
  bool _isClaiming = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _verifiedInfo;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _verifiedInfo = null;
      _successMessage = null;
    });

    try {
      final token = SessionService().token;
      final result = await _claimService.verifyInviteCode(code: code, authToken: token);
      setState(() {
        _isVerifying = false;
        _verifiedInfo = result;
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _claimCode() async {
    final code = _codeController.text.trim().toUpperCase();
    final token = SessionService().token ?? '';
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _isClaiming = true;
      _errorMessage = null;
    });

    try {
      final result = await _claimService.claimInviteCode(code: code, authToken: token);
      setState(() {
        _isClaiming = false;
        _successMessage = 'Successfully joined ${(result['employer']?['companyName']) ?? 'Organization'}!';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_successMessage!),
          backgroundColor: Colors.green[800],
        ),
      );

      // If opened as modal from claims, pop with true; otherwise continue onboarding
      if (widget.isStandalone || Navigator.canPop(context)) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.consent);
        });
      }
    } catch (e) {
      setState(() {
        _isClaiming = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _skipOrContinue() {
    if (widget.isStandalone || Navigator.canPop(context)) {
      Navigator.pop(context, false);
    } else {
      Navigator.pushNamed(context, AppRoutes.consent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join Organization', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Corporate Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text(
                      'CORPORATE REIMBURSEMENT NETWORK',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter Company Invite Code',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask your employer or finance manager for your unique single-use invite code. Joining your company unlocks instant AI receipt scanning and automated reimbursement payouts.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Invite Code Input Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _verifiedInfo != null ? AppColors.green : AppColors.border,
                    width: _verifiedInfo != null ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CORPORATE INVITE CODE',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              hintText: 'TC-XXXX-XXX',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted.withOpacity(0.5),
                                letterSpacing: 2.0,
                              ),
                              prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (_verifiedInfo != null) {
                                setState(() => _verifiedInfo = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Verified Preview Card
              if (_verifiedInfo != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2818),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF52B788), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'INVITE CODE VALIDATED',
                            style: TextStyle(
                              color: Color(0xFF74C69D),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _verifiedInfo!['companyName'] ?? 'Corporate Employer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Department: ${_verifiedInfo!['department'] ?? 'General'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Limit: ₹${_verifiedInfo!['monthlyAllowance'] ?? 50000}/mo',
                              style: const TextStyle(color: Color(0xFF95D5B2), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isClaiming ? null : _claimCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isClaiming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.domain_verification, color: Colors.white, size: 20),
                          label: Text(
                            _isClaiming ? 'Joining Company...' : 'Join & Activate Reimbursements',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Informational feature pills
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      icon: Icons.auto_awesome,
                      title: 'AI Smart Receipt Parsing',
                      desc: 'Scan receipts from cab rides, food, or hotels — AI extracts merchant, amount, and taxes.',
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    _buildFeatureRow(
                      icon: Icons.approval,
                      title: 'Direct Employer Payouts',
                      desc: 'Employer dashboard reviews in real-time and marks payment done straight to you.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Skip option for individuals / freelancers
              Center(
                child: TextButton(
                  onPressed: _skipOrContinue,
                  child: const Text(
                    'I am an Individual / Freelancer (Skip for now)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
