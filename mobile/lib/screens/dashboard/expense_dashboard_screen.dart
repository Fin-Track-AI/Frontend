import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../transaction/add_transaction_modal.dart';
import '../../routes/app_routes.dart';
import '../reimbursement/claim_form_screen.dart';
import '../reimbursement/my_claims_screen.dart';
import '../../services/user_financial_service.dart';
import '../../services/session_service.dart';
import '../main_shell.dart';
import '../expenses/statement_import_screen.dart';

class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  final UserFinancialService _financialService = UserFinancialService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await _financialService.init();
    if (mounted) setState(() {});

    // Prompt for fresh setup if not completed yet
    if (!_financialService.isSetupComplete && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, AppRoutes.financialSetup);
      });
    }
  }

  Future<void> _openAddExpenseModal() async {
    final added = await AddTransactionModal.show(context);
    if (added == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openImportStatement() async {
    final imported = await StatementImportScreen.show(context);
    if (imported == true && mounted) {
      await _financialService.fetchBackendData();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeCap = _financialService.safeToSpendCap;
    final remaining = _financialService.remainingSafeToSpend;
    final discretionarySpent = _financialService.currentMonthDiscretionarySpent;
    final totalSpent = _financialService.currentMonthSpent;
    final salary = _financialService.monthlySalary;
    final fixedCosts = _financialService.totalFixedObligations;
    final pct = _financialService.budgetUtilizedPercent;
    final hasStatement = _financialService.userTransactions.any((t) => t['source'] == 'statement' || t['category'] == 'Salary');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard_expense',
        onPressed: _openAddExpenseModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _financialService.fetchBackendData();
            if (mounted) setState(() {});
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              // Greeting and Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FINANCIAL OVERVIEW',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hi, ${_financialService.userName.isNotEmpty ? _financialService.userName : "Professional"} 👋',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Safe-to-Spend Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'MONTHLY FINANCIAL OVERVIEW',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                          child: const Text('LIVE CAP', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Safe-to-Spend', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _financialService.currentCycleLabel,
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: remaining < 0 ? AppColors.red : AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: remaining >= 0 ? AppColors.greenLight : AppColors.redLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: remaining >= 0 ? AppColors.greenBorder : AppColors.red),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                remaining >= 0 ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
                                color: remaining >= 0 ? AppColors.green : AppColors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                remaining >= 0 ? 'On Track' : 'Over Budget',
                                style: TextStyle(
                                  color: remaining >= 0 ? AppColors.green : AppColors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discretionary Budget: ${pct.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Safe Cap: ₹${safeCap.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(remaining >= 0 ? AppColors.primary : AppColors.red),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('₹0', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text('₹${discretionarySpent.toStringAsFixed(0)} spent', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        Text('₹${safeCap.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const Divider(color: AppColors.divider, height: 28),

                    // Dual Salary vs Fixed Obligations
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text('Monthly Salary', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.green),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₹${salary.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(hasStatement ? 'Bank Statement' : 'User Salary Input', style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.border),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text('Fixed Obligations', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  SizedBox(width: 4),
                                  Icon(Icons.lock_outline, size: 12, color: AppColors.primary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₹${fixedCosts.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              const Text('Rent + Bills + EMI', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QUICK ACTIONS
              const Text('QUICK ACTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Add\nExpense',
                      onTap: _openAddExpenseModal,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionButton(
                      icon: Icons.account_balance_outlined,
                      label: 'Import\nStatement',
                      onTap: _openImportStatement,
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Submit\nClaim',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClaimFormScreen(
                            authToken: SessionService().token ?? '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionButton(
                      icon: Icons.receipt_long,
                      label: 'My\nClaims',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyClaimsScreen(
                            authToken: SessionService().token ?? '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickActionButton(
                      icon: Icons.incomplete_circle_rounded,
                      label: 'Split\nBill',
                      isAccent: true,
                      onTap: () => MainShell.navigateToTab(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Recent Transactions', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ),
                  Text(
                    '${_financialService.userTransactions.length} items',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Render User Dynamic Transactions or Fresh Start Banner
              if (_financialService.userTransactions.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: 10),
                      const Text(
                        'Fresh Account Setup Complete! 🎉',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No dummy data loaded. Tap "Add Expense" below or scan a corporate receipt to track your first live transaction.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _openAddExpenseModal,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Your First Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._financialService.userTransactions.map((tx) {
                  final isIncome = tx['type'] == 'income' ||
                      tx['category'] == 'Salary' ||
                      (tx['title'] as String? ?? '').toLowerCase().contains('salary') ||
                      (tx['note'] as String? ?? '').toLowerCase().contains('salary');
                  return _buildTransactionCard(
                    title: tx['title'] as String? ?? (isIncome ? 'Salary Credit' : 'Expense Entry'),
                    category: '${tx['category']} • ${tx['date']}',
                    tag: tx['paidVia'] as String? ?? (isIncome ? 'NEFT' : 'UPI'),
                    amount: isIncome
                        ? '+₹${(tx['amount'] as num).toStringAsFixed(0)}'
                        : '-₹${(tx['amount'] as num).toStringAsFixed(0)}',
                    isCredit: isIncome,
                    status: isIncome ? 'Income' : 'Saved',
                  );
                }).toList(),
              ],

              const SizedBox(height: 24),
              const AskAiPill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isAccent ? AppColors.primaryLight : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: isAccent ? AppColors.primary : AppColors.border, width: 1.2),
            ),
            child: Icon(icon, color: isAccent ? AppColors.primary : AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String category,
    required String tag,
    required String amount,
    required bool isCredit,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCredit ? AppColors.greenBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? AppColors.greenLight : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
              color: isCredit ? AppColors.green : AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCredit) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.greenBorder),
                        ),
                        child: const Text(
                          'Income',
                          style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(category, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: isCredit ? AppColors.green : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
