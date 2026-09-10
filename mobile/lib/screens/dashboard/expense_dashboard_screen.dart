import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../transaction/add_transaction_modal.dart';
import '../../routes/app_routes.dart';
import '../../services/mock_data_service.dart';

class ExpenseDashboardScreen extends StatelessWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // Greeting and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Friday, 12 September',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Good morning,\n${(MockDataService.userProfile['name'] as String?)?.split(' ').first ?? 'Samarth'}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auto-synced pill
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Auto-synced from SMS & UPI metadata • Read-only',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SEPTEMBER OVERVIEW Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text(
                            'SEPTEMBER OVERVIEW',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      const Text(
                        'Day 12 of 30',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Remaining Safe-to-Spend', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        '₹26,550',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.greenBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.trending_up_rounded, color: AppColors.green, size: 14),
                            SizedBox(width: 4),
                            Text('On Track', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Budget Utilized: 41%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Total Cap: ₹45,000', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.41,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('₹0', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text('₹18,450 spent', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      Text('₹45,000', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const Divider(color: AppColors.divider, height: 28),

                  // Dual Income / Spent
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text('Total Income', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.green),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('₹45,000', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            const Text('↗ +8% vs Aug', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
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
                                Text('Total Spent', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('₹18,450', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            const Text('18 days left', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Spending Spike Alert Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.redLight.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 4),
                          Text('AI SPENDING SPIKE', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Food Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                      children: [
                        TextSpan(text: 'Your Food & Dining spending is '),
                        TextSpan(text: '18% higher', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                        TextSpan(text: ' than last month (₹3,240 vs ₹2,700).\nOrdering 2 fewer times this week keeps you fully on track.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('View Breakdown →', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                      Text('Updated 2h ago', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QUICK ACTIONS
            const Text('QUICK ACTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Capture\nBill',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reimbursement),
                ),
                _buildQuickActionButton(
                  icon: Icons.add_rounded,
                  label: 'Add\nExpense',
                  onTap: () => AddTransactionModal.show(context),
                ),
                _buildQuickActionButton(
                  icon: Icons.people_outline_rounded,
                  label: 'Split\nBill',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.splitExpenses),
                ),
                _buildQuickActionButton(
                  icon: Icons.auto_awesome,
                  label: 'Ask\nAI',
                  isAccent: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Where your money goes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Where your money goes', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('September spending distribution', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
                const Text('Analytics', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),

            // Category Spend Cards
            _buildSpendCategoryRow(icon: Icons.home_outlined, name: 'Rent & Housing', note: 'Fixed monthly cost', amount: '₹12,000', percent: '65.0%'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSmallSpendCard(icon: Icons.restaurant_rounded, name: 'Food & Dining', amount: '₹3,240', percent: '17.5%', color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallSpendCard(icon: Icons.shopping_basket_outlined, name: 'Groceries', amount: '₹4,850', percent: '26.3%', color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSmallSpendCard(icon: Icons.directions_car_outlined, name: 'Travel & Commute', amount: '₹2,100', percent: '11.4%', color: Color(0xFF38BDF8))),
                const SizedBox(width: 10),
                Expanded(child: _buildSmallSpendCard(icon: Icons.subscriptions_outlined, name: 'Subscriptions', amount: '₹799', percent: '4.3%', color: Color(0xFF8B5CF6))),
              ],
            ),
            const SizedBox(height: 10),
            _buildSpendCategoryRow(icon: Icons.medical_services_outlined, name: 'Health & Pharmacy', note: '', amount: '₹356', percent: '1.9%'),

            const SizedBox(height: 24),

            // Recent Transactions
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
                const Text('See all (42)', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),

            _buildTransactionCard(title: 'Swiggy', category: 'Food • 12 Sep', tag: 'UPI', amount: '-₹487.00', isCredit: false, status: 'Debit'),
            _buildTransactionCard(title: 'Uber India', category: 'Travel • 11 Sep', tag: 'UPI', amount: '-₹215.50', isCredit: false, status: 'Debit'),
            _buildTransactionCard(title: 'Salary Credit', category: '01 Sep Income • Auto', tag: 'Auto', amount: '+₹45,000.00', isCredit: true, status: 'Credited'),

            const SizedBox(height: 16),

            // Privacy Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'FinTrack uses on-device SMS parsing to categorize expenses. Your credentials and banking passcodes are never accessed or stored.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),

            const AskAiPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isAccent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isAccent ? AppColors.primaryLight : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: isAccent ? AppColors.primary.withOpacity(0.4) : AppColors.border),
            ),
            child: Icon(icon, color: isAccent ? AppColors.primary : AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendCategoryRow({required IconData icon, required String name, required String note, required String amount, required String percent}) {
    return Container(
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
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                if (note.isNotEmpty) Text(note, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              Text(percent, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSpendCard({required IconData icon, required String name, required String amount, required String percent, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, size: 20, color: color),
              Text(percent, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({required String title, required String category, required String tag, required String amount, required bool isCredit, required String status}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit ? AppColors.greenLight : AppColors.surfaceMuted,
            child: Icon(
              isCredit ? Icons.account_balance : Icons.receipt_outlined,
              color: isCredit ? AppColors.green : AppColors.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(category, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(status, style: TextStyle(color: isCredit ? AppColors.green : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
