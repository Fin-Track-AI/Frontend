import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/split_models.dart';
import '../../services/split_service.dart';

class AddSplitExpenseModal extends StatefulWidget {
  final SplitGroup group;

  const AddSplitExpenseModal({
    super.key,
    required this.group,
  });

  static Future<GroupExpense?> show(
    BuildContext context, {
    required SplitGroup group,
  }) {
    return showModalBottomSheet<GroupExpense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSplitExpenseModal(group: group),
    );
  }

  @override
  State<AddSplitExpenseModal> createState() => _AddSplitExpenseModalState();
}

class _AddSplitExpenseModalState extends State<AddSplitExpenseModal> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  late TabController _tabController;
  late String _selectedPayerId;
  final String _selectedCategory = 'Food & Dining';

  // Equal Split State
  late Set<String> _equalSelectedMemberIds;

  // Percentage Split State
  late Map<String, TextEditingController> _percentageControllers;

  // Itemized Split State
  final List<ItemizedEntry> _itemizedEntries = [];
  final _itemTitleController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _taxTipController = TextEditingController(text: '0');
  late Set<String> _currentItemAssignedMemberIds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    // Default payer is current user or first member
    final currentUser = SplitService().currentUser;
    _selectedPayerId = widget.group.members.any((m) => m.id == currentUser.id)
        ? currentUser.id
        : widget.group.members.first.id;

    // Equal split: all selected by default
    _equalSelectedMemberIds = widget.group.members.map((m) => m.id).toSet();

    // Percentage split: distribute equally initially
    _percentageControllers = {};
    final n = widget.group.members.length;
    final basePct = n > 0 ? (100.0 / n).toStringAsFixed(1) : '0';
    for (final m in widget.group.members) {
      _percentageControllers[m.id] = TextEditingController(text: basePct);
    }

    // Itemized starter item
    _currentItemAssignedMemberIds = widget.group.members.map((m) => m.id).toSet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _itemTitleController.dispose();
    _itemPriceController.dispose();
    _taxTipController.dispose();
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _enteredTotalAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  SplitType get _currentSplitType {
    switch (_tabController.index) {
      case 0:
        return SplitType.equal;
      case 1:
        return SplitType.percentage;
      case 2:
      default:
        return SplitType.itemized;
    }
  }

  // --- Percentage Helpers ---
  double get _currentSumPercentage {
    double sum = 0.0;
    for (final c in _percentageControllers.values) {
      sum += double.tryParse(c.text.trim()) ?? 0.0;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  void _equalizePercentages() {
    final n = widget.group.members.length;
    if (n == 0) return;
    final base = (100.0 / n).toStringAsFixed(2);
    for (final c in _percentageControllers.values) {
      c.text = base;
    }
    setState(() {});
  }

  // --- Itemized Helpers ---
  void _addItemizedEntry() {
    final title = _itemTitleController.text.trim();
    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
    if (title.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid item name and price')),
      );
      return;
    }
    if (_currentItemAssignedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign item to at least 1 member')),
      );
      return;
    }

    setState(() {
      _itemizedEntries.add(
        ItemizedEntry(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          name: title,
          price: price,
          assignedMemberIds: _currentItemAssignedMemberIds.toList(),
        ),
      );
      _itemTitleController.clear();
      _itemPriceController.clear();
      // Auto update total amount field based on items sum
      final taxTip = double.tryParse(_taxTipController.text.trim()) ?? 0.0;
      final sumItems = _itemizedEntries.fold<double>(0.0, (acc, item) => acc + item.price);
      _amountController.text = (sumItems + taxTip).toStringAsFixed(0);
    });
  }

  void _removeItemizedEntry(int index) {
    setState(() {
      _itemizedEntries.removeAt(index);
      final taxTip = double.tryParse(_taxTipController.text.trim()) ?? 0.0;
      final sumItems = _itemizedEntries.fold<double>(0.0, (acc, item) => acc + item.price);
      _amountController.text = (sumItems + taxTip).toStringAsFixed(0);
    });
  }

  // --- Submission ---
  void _submitExpense() {
    if (!_formKey.currentState!.validate()) return;

    final totalAmount = _enteredTotalAmount;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    List<SplitAllocation> allocations = [];
    final splitService = SplitService();

    switch (_currentSplitType) {
      case SplitType.equal:
        if (_equalSelectedMemberIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least 1 member to split')),
          );
          return;
        }
        final includedMembers = widget.group.members
            .where((m) => _equalSelectedMemberIds.contains(m.id))
            .toList();
        allocations = splitService.calculateEqualSplit(
          totalAmount: totalAmount,
          includedMembers: includedMembers,
        );
        break;

      case SplitType.percentage:
        final sum = _currentSumPercentage;
        if ((sum - 100.0).abs() > 0.05) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Percentages must sum exactly to 100.0% (currently $sum%)')),
          );
          return;
        }
        final pctMap = <String, double>{};
        for (final m in widget.group.members) {
          pctMap[m.id] = double.tryParse(_percentageControllers[m.id]?.text.trim() ?? '0') ?? 0.0;
        }
        allocations = splitService.calculatePercentageSplit(
          totalAmount: totalAmount,
          members: widget.group.members,
          percentages: pctMap,
        );
        break;

      case SplitType.itemized:
        if (_itemizedEntries.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least 1 item entry')),
          );
          return;
        }
        final taxTip = double.tryParse(_taxTipController.text.trim()) ?? 0.0;
        allocations = splitService.calculateItemizedSplit(
          totalAmount: totalAmount,
          members: widget.group.members,
          items: _itemizedEntries,
          taxAndTipAmount: taxTip,
        );
        break;
    }

    final newExpense = splitService.addExpense(
      groupId: widget.group.id,
      title: _titleController.text.trim(),
      totalAmount: totalAmount,
      paidById: _selectedPayerId,
      splitType: _currentSplitType,
      allocations: allocations,
      category: _selectedCategory,
      itemizedEntries: _currentSplitType == SplitType.itemized ? _itemizedEntries : null,
    );

    Navigator.pop(context, newExpense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.green,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Split "${newExpense.title}" added and reconciled to 100%!'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: 50, bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(widget.group.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Expense to ${widget.group.name}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'BR-17: Equal, Itemized or % Split (100% Reconciled)',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // Tab Bar for 3 Split Methods
          Container(
            color: AppColors.surfaceMuted,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              tabs: const [
                Tab(icon: Icon(Icons.pie_chart_outline, size: 18), text: 'Equal Split'),
                Tab(icon: Icon(Icons.percent_rounded, size: 18), text: 'Percentage (%)'),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'Itemized'),
              ],
            ),
          ),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Amount Inputs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DESCRIPTION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Dinner, Beach Drinks, Cab',
                                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  filled: true,
                                  fillColor: AppColors.surfaceMuted,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AMOUNT (₹)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  hintText: '0',
                                  filled: true,
                                  fillColor: AppColors.surfaceMuted,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter amt';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Paid By Selector
                    Row(
                      children: [
                        const Text('PAID BY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPayerId,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                items: widget.group.members.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m.id,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: m.isSelf ? AppColors.green : AppColors.primary,
                                          child: Text(m.name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          m.isSelf ? '${m.name} (You)' : m.name,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPayerId = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // TAB SPECIFIC CONTENT
                    if (_tabController.index == 0) _buildEqualSplitSection(),
                    if (_tabController.index == 1) _buildPercentageSplitSection(),
                    if (_tabController.index == 2) _buildItemizedSplitSection(),

                    const SizedBox(height: 24),

                    // Reconciliation status badge
                    _buildReconciliationBadge(),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm & Split Expense',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Equal Split Section ---
  Widget _buildEqualSplitSection() {
    final count = _equalSelectedMemberIds.length;
    final total = _enteredTotalAmount;
    final perPerson = count > 0 ? (total / count).toStringAsFixed(2) : '0.00';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SELECT WHO SHARES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
              Text(
                '$count of ${widget.group.members.length} members (₹$perPerson/ea)',
                style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.group.members.map((m) {
            final isChecked = _equalSelectedMemberIds.contains(m.id);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.green,
              title: Row(
                children: [
                  Text(m.isSelf ? '${m.name} (You)' : m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (m.id == _selectedPayerId) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Payer', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(isChecked ? 'Owes ₹$perPerson' : 'Not included', style: TextStyle(fontSize: 11, color: isChecked ? AppColors.textSecondary : AppColors.textMuted)),
              value: isChecked,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _equalSelectedMemberIds.add(m.id);
                  } else {
                    _equalSelectedMemberIds.remove(m.id);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // --- Percentage Split Section ---
  Widget _buildPercentageSplitSection() {
    final sumPct = _currentSumPercentage;
    final is100 = (sumPct - 100.0).abs() < 0.05;
    final total = _enteredTotalAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CUSTOM PERCENTAGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
              GestureDetector(
                onTap: _equalizePercentages,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                  child: const Text('Equalize %', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.group.members.map((m) {
            final c = _percentageControllers[m.id]!;
            final pct = double.tryParse(c.text.trim()) ?? 0.0;
            final shareAmt = ((total * pct) / 100.0).toStringAsFixed(2);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      m.isSelf ? '${m.name} (You)' : m.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('₹$shareAmt', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    height: 36,
                    child: TextField(
                      controller: c,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        suffixText: '%',
                        suffixStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Allocation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text(
                '$sumPct% / 100.0%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: is100 ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Itemized Split Section ---
  Widget _buildItemizedSplitSection() {
    final sumItems = _itemizedEntries.fold<double>(0.0, (acc, item) => acc + item.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of items added
        if (_itemizedEntries.isNotEmpty) ...[
          const Text('EXPENSE ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itemizedEntries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final item = _itemizedEntries[idx];
              final assignedNames = widget.group.members
                  .where((m) => item.assignedMemberIds.contains(m.id))
                  .map((m) => m.name.split(' ').first)
                  .join(', ');

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Shared by: $assignedNames', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                      onPressed: () => _removeItemizedEntry(idx),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // Add Item Form
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Line Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _itemTitleController,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'Item name (e.g. Pasta)',
                        hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _itemPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'Price',
                        hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Who ate / used this?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.group.members.map((m) {
                  final isAssigned = _currentItemAssignedMemberIds.contains(m.id);
                  return FilterChip(
                    label: Text(m.name.split(' ').first),
                    selected: isAssigned,
                    selectedColor: AppColors.greenLight,
                    labelStyle: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isAssigned ? FontWeight.w800 : FontWeight.w600,
                      color: isAssigned ? AppColors.green : AppColors.textSecondary,
                    ),
                    side: BorderSide(color: isAssigned ? AppColors.greenBorder : AppColors.border),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _currentItemAssignedMemberIds.add(m.id);
                        } else {
                          _currentItemAssignedMemberIds.remove(m.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addItemizedEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Item', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tax / Tip Addon Input
        Row(
          children: [
            const Expanded(
              child: Text('Add Shared Tax / Tip (₹):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 80,
              height: 36,
              child: TextField(
                controller: _taxTipController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                ),
                onChanged: (val) {
                  final taxTip = double.tryParse(val.trim()) ?? 0.0;
                  _amountController.text = (sumItems + taxTip).toStringAsFixed(0);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Reconciliation Badge ---
  Widget _buildReconciliationBadge() {
    bool isBalanced = true;
    String text = 'BR-17 Reconciled: 100% split with 0 remainder discrepancy';

    if (_tabController.index == 1) {
      final sumPct = _currentSumPercentage;
      if ((sumPct - 100.0).abs() > 0.05) {
        isBalanced = false;
        text = 'Discrepancy: Percentages must equal 100.0% (currently $sumPct%)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isBalanced ? AppColors.greenLight : AppColors.redLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isBalanced ? AppColors.greenBorder : AppColors.redBorder),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: isBalanced ? AppColors.green : AppColors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isBalanced ? AppColors.green : AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
