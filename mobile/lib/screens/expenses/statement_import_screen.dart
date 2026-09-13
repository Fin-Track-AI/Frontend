import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/statement_import_service.dart';
import '../../services/user_financial_service.dart';

/// FinTrack AI — Bank Statement Import Wizard
/// A premium 4-step modal-style screen:
///   Step 1: File picker (select PDF)
///   Step 2: AI processing with live progress animation
///   Step 3: Review extracted transactions (editable categories)
///   Step 4: Confirmation → success
class StatementImportScreen extends StatefulWidget {
  const StatementImportScreen({super.key});

  /// Push this screen as a full-page route and return true if import succeeded.
  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const StatementImportScreen(),
      ),
    );
  }

  @override
  State<StatementImportScreen> createState() => _StatementImportScreenState();
}

class _StatementImportScreenState extends State<StatementImportScreen>
    with TickerProviderStateMixin {
  final StatementImportService _service = StatementImportService();

  int _step = 1; // 1–4

  // Step 1
  String? _selectedFileName;
  PlatformFile? _selectedFile;

  // Step 2
  double _processingProgress = 0.0;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  String _processingStatus = 'Uploading statement...';

  // Step 3
  List<StatementTransaction> _transactions = [];
  int _numPages = 0;
  late Map<String, bool> _selectedMap; // transaction index → selected
  String _reviewFilter = 'All';

  // Step 4 / Error
  int _importedCount = 0;
  double? _detectedSalary;
  double? _detectedRent;
  String? _errorMessage;

  static const List<String> _categories = [
    'Salary',
    'Food & Dining',
    'Groceries',
    'Travel',
    'Shopping',
    'Bills & EMI',
    'Health',
    'Entertainment',
    'Rent',
    'ATM Withdrawal',
    'Transfer',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1: File picking
  // ---------------------------------------------------------------------------

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      _showSnack('Could not read the file. Please try again.');
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileName = file.name;
      _errorMessage = null;
    });
  }

  Future<void> _startProcessing() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _step = 2;
      _processingProgress = 0.0;
      _processingStatus = 'Uploading your bank statement...';
      _errorMessage = null;
    });

    try {
      // Animate through status messages during upload
      _animateStatus();

      final result = await _service.uploadStatement(
        pdfBytes: _selectedFile!.bytes!,
        filename: _selectedFile!.name,
        onProgress: (p) {
          if (mounted) {
            setState(() => _processingProgress = p * 0.2); // upload = 0–20%
          }
        },
      );

      if (!mounted) return;

      // Animate progress to 100%
      for (int i = 20; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 60));
        if (mounted) setState(() => _processingProgress = i / 100.0);
      }

      _transactions = result.transactions;
      _numPages = result.numPages;
      _selectedMap = {
        for (var i = 0; i < _transactions.length; i++) i.toString(): true,
      };

      setState(() => _step = 3);
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 1;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _animateStatus() async {
    final messages = [
      'Uploading your bank statement...',
      'FinTrack AI is reading your statement...',
      'Identifying transactions...',
      'Categorising expenses...',
      'Detecting salary & income...',
      'Detecting EMIs & bills...',
      'Finalising results...',
    ];
    for (final msg in messages) {
      if (!mounted || _step != 2) break;
      setState(() => _processingStatus = msg);
      await Future.delayed(const Duration(milliseconds: 1600));
    }
  }

  // ---------------------------------------------------------------------------
  // Step 3: Review
  // ---------------------------------------------------------------------------

  List<MapEntry<int, StatementTransaction>> get _filteredTransactions {
    return _transactions
        .asMap()
        .entries
        .where((e) {
          if (_reviewFilter == 'Income') return e.value.type == 'income';
          if (_reviewFilter == 'Expenses') return e.value.type == 'expense';
          return true;
        })
        .toList();
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (s, t) => s + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (s, t) => s + t.amount);

  int get _selectedCount =>
      _selectedMap.values.where((v) => v).length;

  Future<void> _confirmImport() async {
    final toImport = _transactions
        .asMap()
        .entries
        .where((e) => _selectedMap[e.key.toString()] == true)
        .map((e) => e.value)
        .toList();

    if (toImport.isEmpty) {
      _showSnack('Please select at least one transaction to import.');
      return;
    }

    setState(() => _step = 2);

    try {
      _processingStatus = 'Saving ${toImport.length} transactions...';
      final result = await _service.confirmImport(toImport);

      // Detect salary and rent from confirmed transactions to override onboarding profile
      double? detectedSalary;
      final salaryList = toImport.where((tx) =>
          tx.category == 'Salary' ||
          (tx.type == 'income' && tx.title.toLowerCase().contains('salary'))).toList();
      if (salaryList.isNotEmpty) {
        salaryList.sort((a, b) => b.date.compareTo(a.date));
        detectedSalary = salaryList.first.amount;
      }

      double? detectedRent;
      final rentList = toImport.where((tx) => tx.category == 'Rent').toList();
      if (rentList.isNotEmpty) {
        rentList.sort((a, b) => b.date.compareTo(a.date));
        detectedRent = rentList.first.amount;
      }

      // Convert transactions to UserFinancialService format
      final formattedTxns = toImport.map((tx) {
        return {
          'id': 'STMT_${DateTime.now().millisecondsSinceEpoch}_${tx.hashCode}',
          'title': tx.title,
          'category': tx.category,
          'amount': tx.amount,
          'type': tx.type,
          'date': tx.date,
          'paidVia': tx.paidVia,
          'source': 'statement',
          'isReimbursable': tx.isReimbursable,
          'note': tx.note,
        };
      }).toList();

      // Immediately store locally and override salary/rent
      await UserFinancialService().importStatementTransactions(
        transactions: formattedTxns,
        overrideSalary: detectedSalary,
        overrideRent: detectedRent,
      );

      // Also trigger a backend fetch to ensure full sync
      await UserFinancialService().fetchBackendData();

      if (!mounted) return;
      setState(() {
        _importedCount = result.imported;
        _detectedSalary = detectedSalary;
        _detectedRent = detectedRent;
        _step = 4;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 3;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: _step == 4
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(false),
              ),
        title: Text(
          _step == 1
              ? 'Import Bank Statement'
              : _step == 2
                  ? 'FinTrack AI Processing'
                  : _step == 3
                      ? 'Review Transactions'
                      : 'Import Complete',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _step / 4,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1(key: const ValueKey('s1'));
      case 2:
        return _buildStep2(key: const ValueKey('s2'));
      case 3:
        return _buildStep3(key: const ValueKey('s3'));
      case 4:
        return _buildStep4(key: const ValueKey('s4'));
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1 — File Picker
  // ---------------------------------------------------------------------------

  Widget _buildStep1({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload your PDF bank statement',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 6),
          const Text(
            'FinTrack AI will read through every page, extract all transactions, and auto-categorise them for you.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Supported banks row
          const Text(
            'WORKS WITH ALL MAJOR BANKS',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['HDFC', 'SBI', 'ICICI', 'Axis', 'Kotak', 'Yes Bank', 'IDFC', 'IndusInd', 'PNB']
                .map((bank) => _bankChip(bank))
                .toList(),
          ),
          const SizedBox(height: 28),

          // Drop zone / picker
          GestureDetector(
            onTap: _pickFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? AppColors.primary.withOpacity(0.06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedFile != null ? AppColors.primary : AppColors.border,
                  width: _selectedFile != null ? 2 : 1.2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.picture_as_pdf_rounded
                        : Icons.cloud_upload_outlined,
                    size: 52,
                    color: _selectedFile != null ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null
                        ? _selectedFileName ?? 'File selected'
                        : 'Tap to select your bank statement',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedFile != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: _selectedFile != null ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile != null
                        ? '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB • PDF'
                        : 'PDF format only • Max 50 MB',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Info bullets
          _infoBullet(Icons.auto_awesome_rounded, 'AI reads every page', 'Handles 60+ page statements — no page limit.'),
          const SizedBox(height: 10),
          _infoBullet(Icons.category_outlined, 'Smart categorisation', 'Salary, EMI, UPI, groceries, bills — all auto-tagged.'),
          const SizedBox(height: 10),
          _infoBullet(Icons.fact_check_outlined, 'You review before save', 'Nothing is saved until you confirm.'),
          const SizedBox(height: 10),
          _infoBullet(Icons.lock_outline_rounded, 'Your data stays yours', 'Statement is processed and not stored on our servers.'),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _selectedFile != null ? _startProcessing : null,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Analyse with FinTrack AI',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoBullet(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Processing Animation
  // ---------------------------------------------------------------------------

  Widget _buildStep2({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing orb
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 0.90 + 0.12 * _pulseController.value;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.9),
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'FinTrack AI is Working',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _processingStatus,
                key: ValueKey(_processingStatus),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _processingProgress > 0 ? _processingProgress : null,
                minHeight: 10,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _processingProgress > 0
                  ? '${(_processingProgress * 100).toStringAsFixed(0)}%'
                  : 'Starting...',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            const Text(
              'This may take 15–45 seconds for long statements.\nPlease keep this screen open.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Review
  // ---------------------------------------------------------------------------

  Widget _buildStep3({Key? key}) {
    final filtered = _filteredTransactions;

    return Column(
      key: key,
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_numPages-page statement',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_transactions.length} transactions found',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _summaryPill(
                      '₹${_formatAmount(_totalIncome)}',
                      'Total Income',
                      AppColors.green,
                      AppColors.greenLight,
                      Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryPill(
                      '₹${_formatAmount(_totalExpense)}',
                      'Total Spent',
                      AppColors.red,
                      AppColors.redLight,
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter chips + select all
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Income', 'Expenses'].map((f) {
                      final selected = _reviewFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _reviewFilter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Text(
                '$_selectedCount selected',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
            ),
          ),

        // Transaction list
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No transactions match this filter.', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final entry = filtered[i];
                    return _buildTransactionReviewTile(entry.key, entry.value);
                  },
                ),
        ),

        // Confirm bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _confirmImport,
              icon: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              label: Text(
                'Import $_selectedCount Transaction${_selectedCount == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryPill(String amount, String label, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionReviewTile(int index, StatementTransaction tx) {
    final isSelected = _selectedMap[index.toString()] ?? true;
    final isIncome = tx.type == 'income';

    return GestureDetector(
      onTap: () => setState(() => _selectedMap[index.toString()] = !isSelected),
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.border : AppColors.border.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),

              // Type icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isIncome ? AppColors.greenLight : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isIncome ? AppColors.green : AppColors.textSecondary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(tx.date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 6),
                        // Editable category tag
                        GestureDetector(
                          onTap: () => _showCategoryPicker(index, tx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tx.category,
                                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.edit_rounded, color: AppColors.primary, size: 9),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '${isIncome ? '+' : '-'}₹${_formatAmount(tx.amount)}',
                style: TextStyle(
                  color: isIncome ? AppColors.green : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(int index, StatementTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Change Category', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...(_categories.map((cat) => ListTile(
                leading: Icon(
                  cat == tx.category ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: cat == tx.category ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                title: Text(cat, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  setState(() {
                    _transactions[index] = _transactions[index].copyWith(category: cat);
                  });
                  Navigator.pop(ctx);
                },
              ))),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Success
  // ---------------------------------------------------------------------------

  Widget _buildStep4({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greenLight,
                border: Border.all(color: AppColors.green.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.green, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Import Successful! 🎉',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '$_importedCount transaction${_importedCount == 1 ? '' : 's'} have been imported and categorised.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'All imported transactions are tagged with a 🏦 bank badge in your Expenses tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            if (_detectedSalary != null && _detectedSalary! > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salary Profile Overridden',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monthly income updated to ₹${_detectedSalary!.toStringAsFixed(0)} (from statement).'
                            '${_detectedRent != null && _detectedRent! > 0 ? " Rent: ₹${_detectedRent!.toStringAsFixed(0)}/mo." : ""}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('View My Expenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _step = 1;
                  _selectedFile = null;
                  _selectedFileName = null;
                  _transactions = [];
                  _errorMessage = null;
                });
              },
              child: const Text('Import Another Statement', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
