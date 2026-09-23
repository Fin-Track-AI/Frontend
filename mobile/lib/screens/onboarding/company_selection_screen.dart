import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  // 0: Corporate / Salaried, 1: Freelancer / Founder, 2: Student / Personal
  int _selectedPersona = 0;

  final TextEditingController _companyController = TextEditingController(text: 'TechCorp Solutions India');
  final TextEditingController _workEmailController = TextEditingController();

  bool _isSaving = false;

  final List<String> _popularCompanies = [
    'TechCorp Solutions India',
    'Razorpay Technologies',
    'Google India',
    'Infosys Ltd',
    'Tata Consultancy Services',
    'Flipkart',
    'Swiggy / Bundl',
    'Microsoft India',
    'Zomato',
    'Wipro',
  ];

  @override
  void dispose() {
    _companyController.dispose();
    _workEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete({bool isSkipped = false}) async {
    setState(() => _isSaving = true);

    try {
      if (!isSkipped && _selectedPersona == 0) {
        final employerName = _companyController.text.trim();
        final workEmail = _workEmailController.text.trim();

        if (employerName.isNotEmpty) {
          final token = SessionService().token ?? '';
          try {
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/employer/link'),
              headers: {
                if (token.isNotEmpty) 'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'employerName': employerName,
                'corporateEmail': workEmail.isNotEmpty ? workEmail : null,
              }),
            );
          } catch (_) {
            // Non-blocking fallback
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSkipped
                  ? 'All set! You can link your company anytime in Profile.'
                  : 'Work profile linked successfully!',
            ),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _handleComplete(isSkipped: true),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'STEP 3 OF 3 • WORK PROFILE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              const Text(
                'Where do you work?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Linking your company unlocks 1-click corporate reimbursement claims, automatic OCR bill matching, and real-time payout tracking.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Persona Selection Cards
              _buildPersonaCard(
                index: 0,
                icon: Icons.apartment_rounded,
                title: 'Corporate / Salaried Employee',
                subtitle: 'Submit bills for reimbursement directly to your HR/Finance team',
                badgeText: 'Recommended for Claims',
                badgeColor: AppColors.blue,
                badgeBg: AppColors.blueLight,
              ),
              const SizedBox(height: 12),

              _buildPersonaCard(
                index: 1,
                icon: Icons.laptop_chromebook_rounded,
                title: 'Freelancer / Founder / Consultant',
                subtitle: 'Track 100% tax-deductible client expenses, invoices & GST',
                badgeText: 'Tax Optimization',
                badgeColor: AppColors.green,
                badgeBg: AppColors.greenLight,
              ),
              const SizedBox(height: 12),

              _buildPersonaCard(
                index: 2,
                icon: Icons.school_rounded,
                title: 'Student / Personal Budgeter',
                subtitle: 'Skip employer link — optimized for personal spends & group splits',
                badgeText: 'Personal Mode',
                badgeColor: AppColors.amber,
                badgeBg: AppColors.amberLight,
              ),
              const SizedBox(height: 24),

              // Conditional Persona Details
              if (_selectedPersona == 0) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUICK SELECT POPULAR ORGANIZATIONS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Company Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _popularCompanies.map((comp) {
                          final isSelected = _companyController.text == comp;
                          return ChoiceChip(
                            label: Text(comp),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight,
                            backgroundColor: AppColors.surfaceMuted,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _companyController.text = comp);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Custom Company Input
                      const Text(
                        'COMPANY NAME',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _companyController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter company name',
                          prefixIcon: Icon(Icons.business_rounded, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Work Email
                      const Text(
                        'WORK EMAIL (OPTIONAL)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _workEmailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. samarth@company.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textMuted),
                          helperText: 'Enables real-time claim status notifications',
                          helperStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedPersona == 1) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.green, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Freelancer Mode enabled. Corporate claim quotas are turned off; client project expense tagging will be enabled in your dashboard.',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Personal mode activated. You can always connect an employer or team anytime from your Account Profile settings.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Primary Continue Button
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
                  onPressed: _isSaving ? null : () => _handleComplete(isSkipped: false),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save & Launch FinTrack',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.rocket_launch_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Secondary Skip Button
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : () => _handleComplete(isSkipped: true),
                  child: const Text(
                    'I’ll link this later • Continue to Dashboard',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    final isSelected = _selectedPersona == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPersona = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
