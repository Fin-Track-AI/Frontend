import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/claim_service.dart';
import '../../services/session_service.dart';
import '../../services/user_financial_service.dart';
import '../onboarding/employer_link_screen.dart';
import '../onboarding/financial_setup_screen.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _smsPermission = true;
  bool _ocrStorage = true;
  bool _privateAi = true;

  Map<String, dynamic>? _savedUser;
  Map<String, dynamic>? _employerInfo;
  bool _hasEmployer = false;
  bool _isLeavingCompany = false;
  final AuthService _authService = AuthService();
  final ClaimService _claimService = ClaimService();

  // Local financial state — refreshed whenever setup screen is closed
  double _monthlySalary = 0;
  double _fixedObligations = 0;
  double _safeCap = 0;

  void _refreshFinancials() {
    final svc = UserFinancialService();
    setState(() {
      _monthlySalary = svc.monthlySalary;
      _fixedObligations = svc.totalFixedObligations;
      _safeCap = svc.safeToSpendCap;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _loadEmployerStatus();
  }

  Future<void> _loadUserSession() async {
    final user = await _authService.getSavedUser();
    if (user != null && mounted) {
      setState(() => _savedUser = user);
    }
    // Also load financials on init
    _refreshFinancials();
  }

  Future<void> _loadEmployerStatus() async {
    final token = SessionService().token ?? '';
    if (token.isEmpty) return;
    try {
      final res = await _claimService.getMyCompany(authToken: token);
      if (mounted) {
        setState(() {
          _hasEmployer = res['hasEmployer'] == true;
          _employerInfo = res['employer'] as Map<String, dynamic>?;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLeaveCompany() async {
    final token = SessionService().token ?? '';
    if (token.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Company?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'You will lose access to corporate reimbursements for ${_employerInfo?['employerName'] ?? 'this company'}. You can rejoin with a new invite code.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLeavingCompany = true);
    try {
      await _claimService.leaveCompany(authToken: token);
      if (mounted) {
        setState(() {
          _hasEmployer = false;
          _employerInfo = null;
          _isLeavingCompany = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the company. You can join a new one via Claims.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLeavingCompany = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    await UserFinancialService().init();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  Future<void> _updateBackendConsent(String type, bool val) async {
    try {
      final token = SessionService().token ?? '';
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/consent'),
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'upiConsent': _smsPermission,
          'billStorageConsent': _ocrStorage,
          'aiUsageConsent': _privateAi,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? 'Consent granted for $type' : 'Consent revoked for $type (feature access blocked)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Profile consent sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            // Logged In User Account Session Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      ((_savedUser?['name'] ?? 'U') as String)[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _savedUser?['name'] ?? 'FinTrack User',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _savedUser?['phone'] != null && (_savedUser!['phone'] as String).isNotEmpty
                              ? 'Phone: +91 ${_savedUser!['phone']}'
                              : 'Phone: Not Linked',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _savedUser?['email'] ?? 'user@fintrack.app',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.red),
                    tooltip: 'Log Out Session',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),

            // Monthly Salary & Financial Setup Card
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Financial Setup',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Salary & Fixed Monthly Outflows',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FinancialSetupScreen(isModalEdit: true)),
                          );
                          if (updated == true && mounted) {
                            _refreshFinancials(); // re-read singleton values and trigger rebuild
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                        label: const Text('Edit Salary', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_monthlySalary.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fixed Obligations', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_fixedObligations.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: AppColors.border),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Safe Cap', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_safeCap.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Employer / Corporate Account Card
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasEmployer ? AppColors.primary.withOpacity(0.5) : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _hasEmployer ? AppColors.primaryLight : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.business_center_rounded,
                          color: _hasEmployer ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Corporate Account',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hasEmployer ? 'Linked via FinTrack invite code' : 'Not linked to any employer',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (_hasEmployer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Active', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  if (_hasEmployer && _employerInfo != null) ...[
                    _buildInfoRow(Icons.apartment_rounded, 'Company', _employerInfo!['employerName'] ?? 'Unknown'),
                    const SizedBox(height: 8),
                    if (_employerInfo!['department'] != null)
                      _buildInfoRow(Icons.group_work_rounded, 'Department', _employerInfo!['department']),
                    if (_employerInfo!['department'] != null) const SizedBox(height: 8),
                    if (_employerInfo!['reimbursementLimit'] != null)
                      _buildInfoRow(Icons.payments_rounded, 'Monthly Limit', '₹${_employerInfo!['reimbursementLimit']}/mo'),
                    if (_employerInfo!['reimbursementLimit'] != null) const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLeavingCompany ? null : _handleLeaveCompany,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.red, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLeavingCompany
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red))
                            : const Icon(Icons.exit_to_app_rounded, color: AppColors.red, size: 16),
                        label: Text(
                          _isLeavingCompany ? 'Leaving...' : 'Leave Company',
                          style: const TextStyle(color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Join your organization via the Claims tab using a company invite code.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final joined = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployerLinkScreen(isStandalone: true)),
                          );
                          if (joined == true && mounted) _loadEmployerStatus();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.vpn_key_rounded, size: 16),
                        label: const Text('Enter Invite Code', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Top Shield Badges
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.redLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppColors.red, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.green, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text(
                      'ISO 27001 Certified & RBI Compliant',
                      style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Data Consent & Privacy',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Manage device access permissions, encryption keys,\nand export or wipe your cloud footprint anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
              ),
            ),
            const SizedBox(height: 18),

            // Zero-Custody Promise Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.lock_outline_rounded, color: AppColors.red, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Zero-Custody Promise', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Read-only', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your financial privacy is non-negotiable. FinTrack is 100% read-only, end-to-end encrypted, and never holds money, initiates transfers, or shares personal data with advertisers.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Data Permissions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Data Permissions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
                  child: const Text('3 Active', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Permission 1: UPI & SMS Metadata
            _buildPermissionCard(
              icon: Icons.sms_outlined,
              iconBg: AppColors.redLight,
              iconColor: AppColors.red,
              title: 'UPI & SMS Metadata',
              desc: 'Reads transaction SMS alerts and UPI reference notes to auto-categorize daily spending. Credentials, bank pins, and OTPs are strictly excluded and never accessed.',
              value: _smsPermission,
              onChanged: (v) {
                setState(() => _smsPermission = v);
                _updateBackendConsent('UPI Sync', v);
              },
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.account_balance_outlined, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('View Synced Accounts', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Text('Revoke Access', style: TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Permission 2: OCR Bill & Receipt Storage
            _buildPermissionCard(
              icon: Icons.receipt_long_outlined,
              iconBg: AppColors.amberLight,
              iconColor: AppColors.amber,
              title: 'OCR Bill & Receipt Storage',
              desc: 'Stores scanned corporate receipts in an encrypted vault for employer reimbursement reporting and audit proof.',
              value: _ocrStorage,
              onChanged: (v) {
                setState(() => _ocrStorage = v);
                _updateBackendConsent('Bill Storage', v);
              },
              badgeInfo: 'Encrypted Vault (14 Receipts)',
            ),
            const SizedBox(height: 10),

            // Permission 3: Private AI Financial Insights
            _buildPermissionCard(
              icon: Icons.auto_awesome,
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              title: 'Private AI Financial Insights',
              desc: 'Allows FinTrack AI to analyze spending trends locally. Your financial data is never used to train public models.',
              value: _privateAi,
              onChanged: (v) {
                setState(() => _privateAi = v);
                _updateBackendConsent('AI Insights', v);
              },
              badgeInfo: 'Edge Device Inference',
            ),
            const SizedBox(height: 20),

            // Security Safeguards
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Security Safeguards', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('256-bit AES & TLS 1.3', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Resting data is encrypted with military-grade 256-bit AES. Active connections use TLS 1.3 forward secrecy.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Masked Active Identifiers', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _buildMaskedIdRow('rit***@okicici', 'Connected'),
                  const SizedBox(height: 6),
                  _buildMaskedIdRow('9876****10@hdfc', 'Connected'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Request Data Export
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.primary),
              label: const Text('Request Data Export (JSON/CSV)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export link sent to your registered email')),
                );
              },
            ),

            const SizedBox(height: 10),

            // Reset to Fresh Account & Clear Data
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.redLight.withOpacity(0.5),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.red),
              label: const Text('Reset to Fresh Account (Clear All Data)', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
              onPressed: () async {
                await UserFinancialService().resetAccountToFreshState();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account reset to fresh state! Launching setup...')),
                );
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.financialSetup, (route) => false);
              },
            ),

            const AskAiPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? footer,
    String? badgeInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Status: Active', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35)),
          if (badgeInfo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(badgeInfo, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          if (footer != null) ...[
            const Divider(color: AppColors.divider, height: 20),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _buildMaskedIdRow(String id, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(id, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            ],
          ),
          Text(status, style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
