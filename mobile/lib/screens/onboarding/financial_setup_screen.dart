import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/user_financial_service.dart';

class FinancialSetupScreen extends StatefulWidget {
  final bool isModalEdit;
  const FinancialSetupScreen({super.key, this.isModalEdit = false});

  @override
  State<FinancialSetupScreen> createState() => _FinancialSetupScreenState();
}

class _FinancialSetupScreenState extends State<FinancialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserFinancialService();

  late TextEditingController _nameController;
  late TextEditingController _salaryController;
  late TextEditingController _rentController;
  late TextEditingController _billsController;
  late TextEditingController _emiController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _service.userName);
    _salaryController = TextEditingController(
      text: _service.monthlySalary > 0 ? _service.monthlySalary.toStringAsFixed(0) : '60000',
    );
    _rentController = TextEditingController(
      text: _service.rent > 0 ? _service.rent.toStringAsFixed(0) : '15000',
    );
    _billsController = TextEditingController(
      text: _service.bills > 0 ? _service.bills.toStringAsFixed(0) : '3000',
    );
    _emiController = TextEditingController(
      text: _service.emi > 0 ? _service.emi.toStringAsFixed(0) : '2000',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salaryController.dispose();
    _rentController.dispose();
    _billsController.dispose();
    _emiController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    final rent = double.tryParse(_rentController.text.trim()) ?? 0.0;
    final bills = double.tryParse(_billsController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;

    await _service.saveFinancialSetup(
      name: name.isNotEmpty ? name : 'Atharva',
      salary: salary,
      rentVal: rent,
      billsVal: bills,
      emiVal: emi,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial setup saved! Welcome to your fresh tracker.'),
        backgroundColor: AppColors.green,
      ),
    );

    if (widget.isModalEdit) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isModalEdit ? 'Edit Financial Setup' : 'Fresh Account Setup',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        automaticallyImplyLeading: widget.isModalEdit,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Up Your Salary & Budget',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Enter your monthly income and fixed obligations for live safe-to-spend tracking.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name Input
                const Text('YOUR NAME', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                    hintText: 'e.g. Atharva Kalekar',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 18),

                // Monthly Salary Input
                const Text('MONTHLY SALARY / TOTAL INCOME (₹) *', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee, color: AppColors.green),
                    hintText: 'e.g. 60000',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your monthly salary';
                    if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Please enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Text('FIXED MONTHLY OBLIGATIONS', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('These will be automatically subtracted from your salary to compute your Safe-to-Spend Cap.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 14),

                // Rent Input
                const Text('MONTHLY RENT / HOUSING (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary),
                    hintText: 'e.g. 15000',
                  ),
                ),
                const SizedBox(height: 14),

                // Bills Input
                const Text('FIXED BILLS & UTILITIES (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _billsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.bolt_outlined, color: AppColors.primary),
                    hintText: 'e.g. 3000',
                  ),
                ),
                const SizedBox(height: 14),

                // EMI & Subscriptions Input
                const Text('EMI & SAVINGS TARGET (₹)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.savings_outlined, color: AppColors.primary),
                    hintText: 'e.g. 2000',
                  ),
                ),
                const SizedBox(height: 28),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isModalEdit ? 'Update Financial Setup' : 'Save & Launch Fresh Tracker',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
}
