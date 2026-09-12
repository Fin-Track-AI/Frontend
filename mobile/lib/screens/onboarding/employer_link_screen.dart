import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class EmployerLinkScreen extends StatefulWidget {
  const EmployerLinkScreen({super.key});

  @override
  State<EmployerLinkScreen> createState() => _EmployerLinkScreenState();
}

class _EmployerLinkScreenState extends State<EmployerLinkScreen> {
  final TextEditingController _corpEmailController = TextEditingController();
  String _selectedEmployer = 'TechCorp Solutions India';
  bool _isFreelancer = false;
  bool _isLoading = false;

  final List<String> _employers = [
    'TechCorp Solutions India',
    'Razorpay Technologies',
    'Infosys Ltd',
    'Flipkart Internet',
    'Swiggy / Bundl Tech',
    'Other Organization',
  ];

  Future<void> _proceed() async {
    setState(() => _isLoading = true);
    try {
      final token = SessionService().token ?? '';
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/employer/link'),
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'employerName': _selectedEmployer,
          'corporateEmail': _corpEmailController.text.trim(),
        }),
      );
      print('Employer link API result: ${response.body}');
    } catch (e) {
      print('Employer link API error: $e');
    } finally {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.consent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employer Linking'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Link Work Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Linking your company enables automated corporate reimbursement claims, tax-saving categorizations, and expense policies.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              if (!_isFreelancer) ...[
                DropdownButtonFormField<String>(
                  value: _selectedEmployer,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Select Organization / Employer',
                    prefixIcon: Icon(Icons.apartment_rounded, color: AppColors.textMuted),
                  ),
                  items: _employers.map((emp) {
                    return DropdownMenuItem(
                      value: emp,
                      child: Text(emp, style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedEmployer = val);
                  },
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _corpEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Work Email Address (Optional)',
                    hintText: 'samarth@techcorp.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                    helperText: 'Used only for corporate reimbursement auto-routing',
                    helperStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isFreelancer,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I am a Freelancer / Self-Employed or Student',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                onChanged: (val) {
                  setState(() => _isFreelancer = val ?? false);
                },
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _proceed,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Continue to Consent & Privacy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
