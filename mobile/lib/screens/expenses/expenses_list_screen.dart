import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../transaction/add_transaction_modal.dart';
import '../../services/user_financial_service.dart';
import 'statement_import_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  String _selectedFilter = 'All';
  final UserFinancialService _financialService = UserFinancialService();
  final List<String> _filters = ['All', 'Expenses', 'Income', 'Bank Statement', 'Reimbursable'];

  @override
  void initState() {
    super.initState();
    _financialService.init().then((_) {
      if (mounted) setState(() {});
    });
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
    final currentSpent = _financialService.currentMonthSpent;
    final currentIncome = _financialService.currentMonthIncome;
    final allTransactions = _financialService.userTransactions;

    final transactions = allTransactions.where((tx) {
      if (_selectedFilter == 'Expenses') {
        return tx['type'] != 'income';
      }
      if (_selectedFilter == 'Income') {
        return tx['type'] == 'income';
      }
      if (_selectedFilter == 'Bank Statement') {
        return tx['source'] == 'statement';
      }
      if (_selectedFilter == 'Reimbursable') {
        return tx['isReimbursable'] == true;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _financialService.fetchBackendData();
            if (mounted) setState(() {});
          },
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            children: [
              // Month Selector & Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'September 2026',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Text('SPENT ', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                        Text('₹${currentSpent.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                        if (currentIncome > 0) ...[
                          const SizedBox(width: 8),
                          Container(width: 1, height: 12, color: AppColors.border),
                          const SizedBox(width: 8),
                          Text('+₹${currentIncome.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search narration, merchant, category...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        label: Text(
                          f,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onSelected: (val) => setState(() => _selectedFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Add Expense, Import Statement & Export Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      onPressed: _openAddExpenseModal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      icon: const Icon(Icons.account_balance_outlined, size: 16, color: AppColors.primary),
                      label: const Text('Import Statement', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      onPressed: _openImportStatement,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    child: const Icon(Icons.file_upload_outlined, size: 18, color: AppColors.textPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense export report generated (CSV/PDF)')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dynamic Transactions Ledger or Empty Fresh State
              if (transactions.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No Transactions Logged Yet',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your ledger is fresh and clean. Add an expense or import a bank statement to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openAddExpenseModal,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Log Expense Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildTimelineHeader(
                  'Transaction Ledger',
                  '${transactions.length} items',
                  _selectedFilter == 'Income'
                      ? '+₹${currentIncome.toStringAsFixed(0)}'
                      : '₹${currentSpent.toStringAsFixed(0)} spent',
                ),
                const SizedBox(height: 8),
                ...transactions.map((tx) {
                  final isIncome = tx['type'] == 'income';
                  final amountNum = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                  final badgeText = isIncome
                      ? '💰 Income'
                      : (tx['source'] == 'statement')
                          ? '🏦 Imported'
                          : (tx['isReimbursable'] == true)
                              ? 'Reimbursable'
                              : 'Personal';
                  final badgeColor = isIncome
                      ? AppColors.green
                      : (tx['source'] == 'statement')
                          ? AppColors.primary
                          : (tx['isReimbursable'] == true)
                              ? AppColors.green
                              : AppColors.textMuted;

                  return _buildExpenseTile(
                    icon: _txIcon(tx),
                    iconColor: _txIconColor(tx),
                    title: tx['title'] as String? ?? (isIncome ? 'Income Credit' : 'Expense'),
                    category: tx['category'] as String? ?? (isIncome ? 'Salary' : 'General'),
                    time: tx['date'] as String? ?? '',
                    method: tx['paidVia'] as String? ?? 'UPI',
                    badgeText: badgeText,
                    badgeColor: badgeColor,
                    amount: '${isIncome ? '+' : '-'}₹${amountNum.toStringAsFixed(0)}',
                    isIncome: isIncome,
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

  IconData _txIcon(Map<String, dynamic> tx) {
    if (tx['type'] == 'income') return Icons.arrow_downward_rounded;
    if (tx['source'] == 'statement') return Icons.account_balance_outlined;
    return Icons.shopping_bag_outlined;
  }

  Color _txIconColor(Map<String, dynamic> tx) {
    if (tx['type'] == 'income') return AppColors.green;
    if (tx['source'] == 'statement') return AppColors.primary;
    return AppColors.primary;
  }

  Widget _buildTimelineHeader(String primary, String secondary, String total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(primary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text(secondary, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
        Text(total, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildExpenseTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String category,
    required String time,
    required String method,
    required String badgeText,
    Color? badgeColor,
    required String amount,
    bool isIncome = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(category, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(method, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppColors.textMuted).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor ?? AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: isIncome ? AppColors.green : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
