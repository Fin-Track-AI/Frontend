import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionModal(),
    );
  }

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  int _amount = 450;
  String _selectedCategory = 'Food & Dining';
  String _paidVia = 'UPI';
  bool _isReimbursable = true;
  final TextEditingController _merchantController = TextEditingController(text: 'Blue Tokai Coffee');
  final List<String> _tags = ['#TeamLunch', '#ProjectAlpha'];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.primary},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_outlined, 'color': Color(0xFF10B981)},
    {'name': 'Travel', 'icon': Icons.directions_car_outlined, 'color': Color(0xFF38BDF8)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': Color(0xFF8B5CF6)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('MANUAL LEDGER', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense added successfully!')),
                    );
                  },
                  child: const Text('Save', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Expense Amount Section
                Center(
                  child: Column(
                    children: [
                      const Text('EXPENSE AMOUNT', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('₹', style: TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Text(
                            '$_amount',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 44, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildQuickAmountChip(100),
                          _buildQuickAmountChip(500),
                          _buildQuickAmountChip(1000),
                          _buildQuickAmountChip(2000),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Merchant / Place
                const Text('MERCHANT / PLACE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.textMuted),
                    hintText: 'e.g. Blue Tokai Coffee, Local Kirana',
                  ),
                ),
                const SizedBox(height: 20),

                // Category Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('CATEGORY', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    Text('Browse All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
                          label: Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          onSelected: (val) => setState(() => _selectedCategory = cat['name'] as String),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Date & Time
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 18),
                      SizedBox(width: 10),
                      Text('Date & Time', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      Spacer(),
                      Text('Today, 12 Sep 2026 • 04:30 PM', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Paid Via
                const Text('PAID VIA (PERSONAL RECORD)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildPaymentMethodCard('UPI • GPay/PhonePe', 'Instant app tag', 'UPI'),
                    _buildPaymentMethodCard('Credit Card', 'HDFC Regalia', 'CC'),
                    _buildPaymentMethodCard('Debit Card', 'Salary A/C', 'DC'),
                    _buildPaymentMethodCard('Cash Pocket', 'Physical notes', 'CASH'),
                  ],
                ),
                const SizedBox(height: 20),

                // Mark as Reimbursable
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.green, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Mark as Reimbursable', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('Tags this transaction to submit for corporate reimbursement claims.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isReimbursable,
                        activeColor: AppColors.green,
                        onChanged: (v) => setState(() => _isReimbursable = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tags & Notes
                const Text('TAGS & NOTES', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      backgroundColor: AppColors.greenLight,
                      side: const BorderSide(color: AppColors.greenBorder),
                      label: Text(tag, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                      deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.green),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Tax Receipt Document (OCR Enabled)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.document_scanner_outlined, color: AppColors.textPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Attach receipt photo', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('OCR Enabled', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('FinTrack OCR will auto-verify GSTIN & totals', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Expense to Tracker'),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to expenses!')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        'FinTrack only records this entry for your analytics; it does not process payments.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int val) {
    return ActionChip(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      label: Text('+₹$val', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
      onPressed: () {
        setState(() => _amount += val);
      },
    );
  }

  Widget _buildPaymentMethodCard(String title, String subtitle, String type) {
    final isSelected = _paidVia == type;
    return GestureDetector(
      onTap: () => setState(() => _paidVia = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
