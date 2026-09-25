import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/insight_service.dart';
import '../services/session_service.dart';

class CategoryCorrectionSheet extends StatefulWidget {
  final String transactionId;
  final String currentCategory;
  final String merchantTitle;
  final Function(String newCategory)? onCategoryUpdated;

  const CategoryCorrectionSheet({
    super.key,
    required this.transactionId,
    required this.currentCategory,
    required this.merchantTitle,
    this.onCategoryUpdated,
  });

  @override
  State<CategoryCorrectionSheet> createState() => _CategoryCorrectionSheetState();
}

class _CategoryCorrectionSheetState extends State<CategoryCorrectionSheet> {
  final List<String> _categories = [
    'Food & Dining',
    'Shopping',
    'Transport',
    'Bills & Utilities',
    'Entertainment',
    'Subscriptions',
    'Health & Medical',
    'General',
  ];

  late String _selectedCategory;
  bool _applyToFuture = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
  }

  Future<void> _submitRecategorization() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final token = SessionService().token ?? '';
      await InsightService().recategorizeTransaction(
        transactionId: widget.transactionId,
        newCategory: _selectedCategory,
        authToken: token,
        applyToFuture: _applyToFuture,
      );

      if (mounted) {
        widget.onCategoryUpdated?.call(_selectedCategory);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category updated to "$_selectedCategory" and smart rule saved!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update category: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Category & Train AI',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Merchant: ${widget.merchantTitle}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = cat == _selectedCategory;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: AppColors.surfaceMuted,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Always assign "${widget.merchantTitle}" to $_selectedCategory',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'FinTrack smart categorization will learn from this correction.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
            value: _applyToFuture,
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _applyToFuture = val;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitRecategorization,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text(
                      'Save Category Rule',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
