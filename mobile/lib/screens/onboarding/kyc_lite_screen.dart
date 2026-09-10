import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class KycLiteScreen extends StatefulWidget {
  const KycLiteScreen({super.key});

  @override
  State<KycLiteScreen> createState() => _KycLiteScreenState();
}

class _KycLiteScreenState extends State<KycLiteScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Samarth Devadiga');
  final TextEditingController _panController = TextEditingController(text: 'ABCDE1234F');
  bool _isLoading = false;

  void _submitKyc() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, AppRoutes.employerLink);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('KYC-Lite Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Identity & Account Setup',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We use non-invasive KYC-lite to verify account ownership under RBI guidelines. All sensitive data is masked at rest.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (as per Bank)',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _panController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'PAN Number (Masked)',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                  helperText: 'e.g. •••••1234F (Stored securely via DPDP encryption)',
                  helperStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FinTrack only acts as a read-only insights layer. We will never debit money or initiate payments.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKyc,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Continue to Employer Link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
