import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_financial_service.dart';
import '../../services/session_service.dart';
import '../../services/ocr_service.dart';

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
  String? _receiptFileName;
  bool _isScanningOcr = false;
  bool _ocrExtracted = false;
  String? _ocrErrorMessage;
  String? _detectedMerchant;

  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.primary},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_outlined, 'color': const Color(0xFF10B981)},
    {'name': 'Travel', 'icon': Icons.directions_car_outlined, 'color': const Color(0xFF38BDF8)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Bills & EMI', 'icon': Icons.bolt_outlined, 'color': const Color(0xFFF59E0B)},
    {'name': 'Health', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFEC4899)},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined, 'color': const Color(0xFF06B6D4)},
    {'name': 'Others', 'icon': Icons.more_horiz_rounded, 'color': AppColors.textSecondary},
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
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptFileName = pickedFile.name;
        _isScanningOcr = true;
        _ocrExtracted = false;
        _ocrErrorMessage = null;
      });

      // Try running OCR extraction if token is available
      final token = SessionService().token ?? '';
      if (token.isNotEmpty) {
        try {
          final data = await _ocrService.parseReceiptImage(
            fileBytes: bytes,
            fileName: pickedFile.name,
            authToken: token,
          );

          if (mounted && data.isNotEmpty) {
            final double? extractedAmt = (data['amount'] as num?)?.toDouble();
            final String? extractedMerchant = data['merchant']?.toString();
            final String? extractedDate = data['date']?.toString();
            final String? extractedCategory = data['category']?.toString();
            final bool? extractedReimbursable = data['isReimbursable'] as bool?;

            setState(() {
              _isScanningOcr = false;
              _ocrExtracted = true;
              _ocrErrorMessage = null;
              _detectedMerchant = extractedMerchant;

              if (extractedAmt != null && extractedAmt > 0) {
                _amountController.text = extractedAmt.toStringAsFixed(extractedAmt.truncateToDouble() == extractedAmt ? 0 : 2);
              }
              if (extractedMerchant != null && extractedMerchant.isNotEmpty && extractedMerchant != 'Unknown' && extractedMerchant != 'Store Expense') {
                _merchantController.text = extractedMerchant;
              }
              if (extractedCategory != null && _categories.any((c) => c['name'] == extractedCategory)) {
                _selectedCategory = extractedCategory;
              }
              if (extractedReimbursable != null) {
                _isReimbursable = extractedReimbursable;
              }
              if (extractedDate != null && extractedDate.isNotEmpty) {
                try {
                  final parsed = DateTime.tryParse(extractedDate);
                  if (parsed != null) _selectedDate = parsed;
                } catch (_) {}
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bill parsed! Auto-filled ${extractedMerchant ?? "details"}.',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        } catch (apiError) {
          final errStr = apiError.toString().replaceAll('Exception: ', '').trim();
          if (mounted) {
            setState(() {
              _isScanningOcr = false;
              _ocrExtracted = false;
              if (errStr.contains('Unauthorized') || errStr.contains('token') || errStr.contains('Session expired')) {
                _ocrErrorMessage = 'Session expired or unauthorized. Please re-login to scan bills.';
              } else if (errStr.contains('blurry') || errStr.contains('unreadable') || errStr.contains('UNREADABLE')) {
                _ocrErrorMessage = 'The bill image is blurry or unreadable. Please upload or take a clear photo of your bill again.';
              } else {
                _ocrErrorMessage = 'Could not process the bill ($errStr). Please try again with a clear, well-lit photo.';
              }
            });
            return;
          }
        }
      }

      // Fallback if OCR is offline or no token
      if (mounted) {
        setState(() {
          _isScanningOcr = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt attached! Confirm details below.'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanningOcr = false;
          _ocrErrorMessage = 'The bill was not readable or could not be processed. Please upload a clear photo again.';
        });
      }
    }
  }

  void _removeReceipt() {
    setState(() {
      _receiptBytes = null;
      _receiptFileName = null;
      _isScanningOcr = false;
      _ocrExtracted = false;
      _ocrErrorMessage = null;
      _detectedMerchant = null;
    });
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

    final dateDisplayStr = DateFormat('dd MMM').format(_selectedDate);

    await UserFinancialService().addTransaction(
      title: title.isNotEmpty ? title : _selectedCategory,
      category: _selectedCategory,
      amount: amountVal,
      paidVia: _paidVia,
      isReimbursable: _isReimbursable,
      dateString: '$dateDisplayStr, ${DateFormat('hh:mm a').format(_selectedDate)}',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Expense',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Form
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 20 + bottomInset),
              children: [
                // 1. HERO BILL SCAN / UPLOAD SECTION (Prominent Top Placement!)
                _buildBillUploadHeroSection(),

                const SizedBox(height: 20),

                // 2. EXPENSE AMOUNT SECTION
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXPENSE AMOUNT *',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'INR (₹)',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: false, // Prevents keyboard from violently obscuring modal
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 34),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quick Amount Increment Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
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

                const SizedBox(height: 18),

                // 3. MERCHANT / PLACE NAME
                const Text(
                  'MERCHANT / STORE NAME',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _merchantController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: _merchantController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _merchantController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    hintText: 'e.g. Starbucks, Blue Tokai, Kirana Store',
                    fillColor: AppColors.surface,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 18),

                // 4. CATEGORY SELECTOR
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
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
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          avatar: Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : (cat['color'] as Color? ?? AppColors.textSecondary),
                          ),
                          label: Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedCategory = cat['name'] as String);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 18),

                // 5. DATE & TIME PICKER
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        const Text(
                          'Transaction Date',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateDisplayStr,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 6. PAID VIA (PAYMENT METHOD)
                const Text(
                  'PAID VIA',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentChip('UPI', 'GPay / UPI', Icons.qr_code_rounded),
                    const SizedBox(width: 8),
                    _buildPaymentChip('CC', 'Credit Card', Icons.credit_card_rounded),
                    const SizedBox(width: 8),
                    _buildPaymentChip('DC', 'Debit Card', Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 8),
                    _buildPaymentChip('CASH', 'Cash', Icons.payments_outlined),
                  ],
                ),

                const SizedBox(height: 18),

                // 7. CORPORATE REIMBURSABLE SWITCH
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isReimbursable ? AppColors.greenBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isReimbursable ? AppColors.greenLight : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.verified_outlined,
                          color: _isReimbursable ? AppColors.green : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Reimbursable',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tags this receipt for your corporate claims ledger',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isReimbursable,
                        activeThumbColor: AppColors.green,
                        onChanged: (v) => setState(() => _isReimbursable = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 8. PRIMARY SAVE ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _amountController.text.trim().isNotEmpty && double.tryParse(_amountController.text.trim()) != null && double.parse(_amountController.text.trim()) > 0
                              ? 'Save Expense • ₹${_amountController.text.trim()}'
                              : 'Save Expense',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Stored locally in your private offline ledger',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Bill Upload Hero Card placed conveniently right at the top
  Widget _buildBillUploadHeroSection() {
    // STATE 1: Actively scanning with Gemini AI
    if (_isScanningOcr) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FinTrack AI is working...',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Analyzing merchant, amount, category & date...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // STATE 2: Unreadable / Blurry Error State (User Prompted to Retake)
    if (_ocrErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.blur_on_rounded, color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Couldn't Read Bill Clearly",
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Dismiss',
                  onPressed: () => setState(() => _ocrErrorMessage = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _ocrErrorMessage!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickReceiptImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    label: const Text('Retake Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickReceiptImage(ImageSource.gallery),
                    icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.textPrimary),
                    label: const Text('Upload Another', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _ocrErrorMessage = null),
                child: const Text(
                  'Or type expense details manually below',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // STATE 3: Success State - Bill Attached & Auto-Filled
    if (_receiptBytes != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.greenBorder, width: 1.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _receiptBytes!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Bill Attached',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_ocrExtracted) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.greenBorder),
                          ),
                          child: const Text(
                            '✨ FinTrack AI Auto-Filled',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (_detectedMerchant != null && _detectedMerchant!.isNotEmpty)
                        ? '$_detectedMerchant • ₹${_amountController.text.isNotEmpty ? _amountController.text : "0"} • $_selectedCategory'
                        : (_merchantController.text.isNotEmpty
                            ? '${_merchantController.text} • ₹${_amountController.text.isNotEmpty ? _amountController.text : "0"} • $_selectedCategory'
                            : (_receiptFileName ?? 'receipt.jpg')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
              tooltip: 'Retake / Replace',
              onPressed: () => _pickReceiptImage(ImageSource.gallery),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
              tooltip: 'Remove',
              onPressed: _removeReceipt,
            ),
          ],
        ),
      );
    }

    // STATE 4: Default "Have a Bill?" Hero Card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Have a Bill or Receipt?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'FinTrack AI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Snap or upload your bill to auto-fill merchant, amount, category & date with FinTrack AI.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickReceiptImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
                  label: const Text('Scan Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceiptImage(ImageSource.gallery),
                  icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.textPrimary),
                  label: const Text('Upload Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surfaceMuted,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int val) {
    return ActionChip(
      backgroundColor: AppColors.surfaceMuted,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      label: Text(
        '+₹$val',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () => _addQuickAmount(val),
    );
  }

  Widget _buildPaymentChip(String type, String label, IconData icon) {
    final isSelected = _paidVia == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paidVia = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
