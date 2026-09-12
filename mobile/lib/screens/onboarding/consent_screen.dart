import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentSms = true;
  bool _consentAa = true;
  bool _consentInsights = true;
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/v1/consent'),
        headers: {
          'Authorization': 'Bearer mock_token_123',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'upiConsent': _consentSms,
          'billStorageConsent': _consentAa,
          'aiUsageConsent': _consentInsights,
        }),
      );
      print('Consent API response: ${response.body}');
    } catch (e) {
      print('Consent API error: $e');
    } finally {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consent & Data Privacy'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text(
                  'DPDP Act & RBI Compliant Framework',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Granular Consent Controls',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'FinTrack never stores credentials or initiates transactions. You can revoke any permission anytime from Settings.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  children: [
                    _buildConsentTile(
                      title: 'UPI Read-Only Transaction Sync',
                      desc: 'Parses local bank transaction alerts to categorize spending automatically.',
                      value: _consentSms,
                      onChanged: (v) => setState(() => _consentSms = v),
                      icon: Icons.receipt_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildConsentTile(
                      title: 'RBI Account Aggregator (AA)',
                      desc: 'Secure encrypted financial data fetch for month-on-month trend analytics.',
                      value: _consentAa,
                      onChanged: (v) => setState(() => _consentAa = v),
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildConsentTile(
                      title: 'AI Financial Assistant Copilot',
                      desc: 'Generates personalized budget forecasts and expense anomalies in an anonymized sandbox.',
                      value: _consentInsights,
                      onChanged: (v) => setState(() => _consentInsights = v),
                      icon: Icons.auto_awesome_outlined,
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_consentSms && !_isLoading) ? _completeOnboarding : null,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Grant Consent & Launch FinTrack'),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Data is 256-bit AES encrypted at rest & in transit',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentTile({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
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
    );
  }
}
