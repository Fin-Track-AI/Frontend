import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/budget_service.dart';
import '../../services/user_financial_service.dart';
import 'peer_benchmarking_screen.dart';

class BudgetsAlertsScreen extends StatefulWidget {
  const BudgetsAlertsScreen({super.key});

  @override
  State<BudgetsAlertsScreen> createState() => _BudgetsAlertsScreenState();
}

class _BudgetsAlertsScreenState extends State<BudgetsAlertsScreen> {
  final BudgetService _budgetService = BudgetService();
  final UserFinancialService _financialService = UserFinancialService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _budgetService.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSetBudgetModal() {
    final overallController = TextEditingController(
      text: _budgetService.overallBudget.toStringAsFixed(0),
    );

    final catControllers = <String, TextEditingController>{};
    for (var cb in _budgetService.categoryBudgets) {
      catControllers[cb['category'] as String] = TextEditingController(
        text: ((cb['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
      );
    }

    int warnThreshold = _budgetService.alertThresholds.isNotEmpty
        ? _budgetService.alertThresholds.first
        : 80;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set Budget & Thresholds',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Overall Monthly Budget (₹)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: overallController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'Enter monthly target',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Category Budget Limits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._budgetService.categoryBudgets.map((cb) {
                      final cat = cb['category'] as String;
                      final ctrl = catControllers[cat];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  prefixText: '₹ ',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Alert Warning Threshold: $warnThreshold%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Slider(
                      value: warnThreshold.toDouble(),
                      min: 50,
                      max: 95,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      label: '$warnThreshold%',
                      onChanged: (val) {
                        setModalState(() => warnThreshold = val.round());
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final newOverall =
                              double.tryParse(overallController.text.trim()) ??
                                  _budgetService.overallBudget;

                          final newCats = <Map<String, dynamic>>[];
                          catControllers.forEach((catName, ctrl) {
                            final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                            newCats.add({'category': catName, 'amount': amt});
                          });

                          await _budgetService.saveBudget(
                            newOverall: newOverall,
                            newCategoryBudgets: newCats,
                            newThresholds: [warnThreshold, 100],
                          );

                          if (modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                          }
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Budget targets and alerts updated!'),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save Budget Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final currentSpent = _financialService.currentMonthSpent;
    final overallBudget = _budgetService.overallBudget;
    final overallPct = overallBudget > 0 ? (currentSpent / overallBudget) : 0.0;

    final catSpentMap = <String, double>{};
    for (var tx in _financialService.userTransactions) {
      if (tx['type'] == 'income') continue;
      final cat = tx['category'] as String? ?? 'Others';
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      catSpentMap[cat] = (catSpentMap[cat] ?? 0.0) + amt;
    }

    final alerts = _budgetService.activeAlerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budgets & Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Set Budget & Limits',
            onPressed: _showSetBudgetModal,
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Peer Benchmarking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const PeerBenchmarkingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Overall Monthly Budget Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Monthly Budget',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: _showSetBudgetModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Edit Target',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${currentSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' / ₹${overallBudget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallPct.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallPct >= 1.0
                              ? AppColors.red
                              : overallPct >= 0.8
                                  ? AppColors.amber
                                  : AppColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(overallPct * 100).toStringAsFixed(0)}% Used',
                          style: TextStyle(
                            color: overallPct >= 1.0
                                ? AppColors.red
                                : overallPct >= 0.8
                                    ? AppColors.amber
                                    : AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          overallBudget > currentSpent
                              ? '₹${(overallBudget - currentSpent).toStringAsFixed(0)} remaining'
                              : 'Exceeded by ₹${(currentSpent - overallBudget).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Active Threshold Alert Banners
              if (alerts.isNotEmpty) ...[
                const Text(
                  'Active Threshold Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...alerts.map((alert) {
                  final isExceeded = alert['level'] == 'EXCEEDED';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isExceeded ? AppColors.redLight : AppColors.amberLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExceeded
                            ? AppColors.red.withOpacity(0.3)
                            : AppColors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isExceeded
                              ? Icons.error_rounded
                              : Icons.warning_amber_rounded,
                          color: isExceeded ? AppColors.red : AppColors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert['category'] ?? 'Budget Alert',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isExceeded
                                      ? AppColors.red
                                      : AppColors.amber,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert['message'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // 3. Category Budgets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category Budgets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const PeerBenchmarkingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('Peer Benchmarks'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Budget Cards
              ..._budgetService.categoryBudgets.map((cb) {
                final cat = cb['category'] as String;
                final limit = (cb['amount'] as num?)?.toDouble() ?? 0.0;
                final spent = catSpentMap[cat] ?? 0.0;
                final pct = limit > 0 ? (spent / limit) : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 1.0
                                ? AppColors.red
                                : pct >= 0.8
                                    ? AppColors.amber
                                    : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}% utilized',
                            style: TextStyle(
                              fontSize: 11,
                              color: pct >= 1.0
                                  ? AppColors.red
                                  : pct >= 0.8
                                      ? AppColors.amber
                                      : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pct >= 1.0)
                            const Text(
                              '⚠️ Exceeded Target',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else if (pct >= 0.8)
                            const Text(
                              '⚠️ Near Threshold',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
