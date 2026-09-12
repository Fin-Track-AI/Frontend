import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_financial_service.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  static Future<bool?> show(BuildContext context) async {
    return await showModalBottomSheet<bool>(
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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  String _paidVia = 'UPI';
  bool _isReimbursable = false;
  DateTime _selectedDate = DateTime.now();

  Uint8List? _receiptBytes;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _tags = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.primary},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Travel', 'icon': Icons.directions_car_outlined, 'color': const Color(0xFF38BDF8)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Health', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFEC4899)},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _receiptBytes = bytes;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt photo attached successfully!'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: ${e.toString()}'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _addQuickAmount(int delta) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final updated = current + delta;
    _amountController.text = updated.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _saveExpense() async {
    final title = _merchantController.text.trim();
    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    await UserFinancialService().addTransaction(
      title: title.isNotEmpty ? title : 'Expense Entry',
      category: _selectedCategory,
      amount: amountVal,
      paidVia: _paidVia,
      isReimbursable: _isReimbursable,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ₹${amountVal.toStringAsFixed(0)} for ${title.isNotEmpty ? title : _selectedCategory}!'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplayStr = DateFormat('dd MMM yyyy').format(_selectedDate);

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
                  onPressed: _saveExpense,
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
                // Editable Expense Amount Section
                Center(
                  child: Column(
                    children: [
                      const Text('EXPENSE AMOUNT (₹) *', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Container(
                        width: 220,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('₹', style: TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 32),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
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

                // Merchant / Place Input (Starts Empty!)
                const Text('MERCHANT / PLACE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                TextField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.storefront_outlined, color: AppColors.primary),
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

                // Date Picker Action Row
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text('Date & Time', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          dateDisplayStr,
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Paid Via Selector
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

                // Mark as Reimbursable Toggle
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
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isReimbursable = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Receipt Photo Attachment Box (Takes Image via Camera or Gallery!)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _receiptBytes != null ? AppColors.green : AppColors.primary.withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_receiptBytes != null ? Icons.check_circle_rounded : Icons.photo_camera_rounded, color: _receiptBytes != null ? AppColors.green : AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _receiptBytes != null ? 'Receipt Attached' : 'Attach Receipt Photo',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('OCR Supported', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_receiptBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
                            child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickReceiptImage(ImageSource.camera),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)),
                              icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              label: const Text('Take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickReceiptImage(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.photo_library, size: 16, color: AppColors.primary),
                              label: const Text('Gallery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                  label: const Text('Add Expense to Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saveExpense,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'FinTrack only records this entry for your analytics; it does not process payments.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
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
      onPressed: () => _addQuickAmount(val),
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
