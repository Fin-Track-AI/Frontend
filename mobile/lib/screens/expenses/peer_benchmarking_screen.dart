import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/budget_service.dart';

class PeerBenchmarkingScreen extends StatefulWidget {
  const PeerBenchmarkingScreen({super.key});

  @override
  State<PeerBenchmarkingScreen> createState() => _PeerBenchmarkingScreenState();
}

class _PeerBenchmarkingScreenState extends State<PeerBenchmarkingScreen> {
  final BudgetService _budgetService = BudgetService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBenchmark();
  }

  Future<void> _loadBenchmark() async {
    setState(() => _isLoading = true);
    await _budgetService.fetchPeerBenchmark();
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

    final data = _budgetService.peerBenchmarkData ?? {};
    final cohortName = data['cohortName'] as String? ?? '25–30 age group';
    final peerCount = (data['peerCount'] as num?)?.toInt() ?? 3820;
    final cohortAvg = (data['cohortAvgSpend'] as num?)?.toDouble() ?? 36200.0;
    final userSpent = (data['userOverallSpent'] as num?)?.toDouble() ?? 0.0;
    final comparisonText = data['comparisonText'] as String? ?? '';
    final categories = (data['categoryBreakdown'] as List<dynamic>?) ?? [];

    final diff = userSpent - cohortAvg;
    final isUserLower = diff <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Peer Benchmarking'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBenchmark,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Anonymization Privacy Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.greenBorder),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.green, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% Anonymized & Aggregated: No individual user data or personal identifiers are ever exposed.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Cohort Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cohortName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$peerCount anonymized peers in cohort',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Spend Comparison Cards (User vs Peer Average)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Spend',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${userSpent.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cohort Average',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${cohortAvg.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (comparisonText.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUserLower
                              ? AppColors.greenLight
                              : AppColors.amberLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUserLower
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: isUserLower
                                  ? AppColors.green
                                  : AppColors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comparisonText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isUserLower
                                      ? AppColors.green
                                      : AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Category Breakdown Comparison List
              const Text(
                'Category Benchmark Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Compare your category spending against age cohort averages',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              ...categories.map((catObj) {
                final cat = catObj['category'] as String;
                final cAvg = (catObj['cohortAvg'] as num?)?.toDouble() ?? 0.0;
                final uSpent = (catObj['userSpent'] as num?)?.toDouble() ?? 0.0;
                final maxVal = (cAvg > uSpent ? cAvg : uSpent) * 1.2;

                final cRatio = maxVal > 0 ? (cAvg / maxVal) : 0.0;
                final uRatio = maxVal > 0 ? (uSpent / maxVal) : 0.0;

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
                      Text(
                        cat,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // User Bar
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: uRatio.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: AppColors.surfaceMuted,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '₹${uSpent.toStringAsFixed(0)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Cohort Bar
                      Row(
                        children: [
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Peers Avg',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: cRatio.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: AppColors.surfaceMuted,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '₹${cAvg.toStringAsFixed(0)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
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
