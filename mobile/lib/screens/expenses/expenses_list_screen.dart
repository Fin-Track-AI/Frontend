import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../transaction/add_transaction_modal.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'UPI Auto-tracked', 'Manual', 'Reimbursable'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      body: SafeArea(
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
                    children: const [
                      Text('TOTAL SEP ', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                      Text('₹18,450', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search merchants, notes, tags...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

            // Add Expense & Export Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Add Expense', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => AddTransactionModal.show(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.file_upload_outlined, size: 18, color: AppColors.textPrimary),
                    label: const Text('Export', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense export report generated (CSV/PDF)')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TIMELINE: Today 12 Sep
            _buildTimelineHeader('Today', '12 Sep', '₹702.50'),
            const SizedBox(height: 8),
            _buildExpenseTile(
              icon: Icons.restaurant_rounded,
              iconColor: AppColors.primary,
              title: 'Swiggy',
              category: 'Food & Dining',
              time: '1:24 PM',
              method: 'UPI • ICICI',
              badgeText: 'Personal',
              amount: '₹487.00',
            ),
            _buildExpenseTile(
              icon: Icons.directions_car_outlined,
              iconColor: Color(0xFF38BDF8),
              title: 'Uber India',
              category: 'Travel & Commute',
              time: '9:10 AM',
              method: 'UPI • HDFC',
              badgeText: 'Reimbursable',
              badgeColor: AppColors.green,
              amount: '₹215.50',
            ),

            const SizedBox(height: 16),

            // TIMELINE: Yesterday 11 Sep
            _buildTimelineHeader('Yesterday', '11 Sep', '₹1,596.75'),
            const SizedBox(height: 8),
            _buildExpenseTile(
              icon: Icons.shopping_basket_outlined,
              iconColor: AppColors.green,
              title: 'Big Basket',
              category: 'Groceries & Kitchen',
              time: '7:45 PM',
              method: 'UPI • ICICI',
              badgeText: 'Split 3 ways',
              badgeColor: Color(0xFF8B5CF6),
              amount: '₹1,240.75',
            ),
            _buildExpenseTile(
              icon: Icons.medical_services_outlined,
              iconColor: Color(0xFFEC4899),
              title: 'Apollo Pharmacy',
              category: 'Health & Wellness',
              time: '11:18 AM',
              method: 'Card • Axis',
              badgeText: 'Personal',
              amount: '₹356.00',
            ),

            const SizedBox(height: 16),

            // TIMELINE: 08 Sep 2026 Tuesday
            _buildTimelineHeader('08 Sep 2026', 'Tuesday', '₹579.00'),
            const SizedBox(height: 8),
            _buildExpenseTile(
              icon: Icons.subscriptions_outlined,
              iconColor: Color(0xFFF59E0B),
              title: 'Netflix India',
              category: 'Subscriptions',
              time: 'Recurring',
              method: 'Auto-debit',
              badgeText: 'Personal',
              amount: '₹199.00',
            ),
            _buildExpenseTile(
              icon: Icons.local_cafe_outlined,
              iconColor: AppColors.green,
              title: 'Starbucks Coffee',
              category: 'Food & Dining',
              time: '4:15 PM',
              method: 'UPI',
              badgeText: 'Reimbursable',
              badgeColor: AppColors.green,
              amount: '₹380.00',
            ),

            const SizedBox(height: 20),

            // Auto-Categorization Health
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
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
                          Icon(Icons.verified_outlined, color: AppColors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Auto-Categorization Health', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
                        child: const Text('98.4% Acc.', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart matching parsed 4 auto-receipts from your bank alerts today. 1 transaction flagged for tax deduction review.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Starbucks ₹380', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Uber ₹215.50', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Read-only metadata notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transactions are read-only metadata synced with consent. FinTrack cannot transfer funds or store sensitive banking credentials.',
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
              Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 6),
              const Icon(Icons.more_horiz, size: 16, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
