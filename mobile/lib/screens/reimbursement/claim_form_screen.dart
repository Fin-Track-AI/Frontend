import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/bill_upload_service.dart';
import '../../services/claim_service.dart';
import '../../services/ocr_service.dart';
import 'my_claims_screen.dart';

class ClaimFormScreen extends StatefulWidget {
  final String authToken;

  const ClaimFormScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  _ClaimFormScreenState createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
  Uint8List? _imageBytes;
  String? _imagePath;
  String? _attachedBillId;

  final _picker = ImagePicker();
  final _billService = BillUploadService();
  final _ocrService = OcrService();
  final _claimService = ClaimService();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _taxController = TextEditingController();

  bool _isReimbursable = true;
  bool _isProcessingOcr = false;
  bool _isSubmitting = false;
  bool _isLowConfidence = false;
  String? _statusMessage;
  String? _errorMessage;

  String? _selectedCategory = 'Meals & Dining';
  String? _selectedProject = 'Project Alpha';
  String? _selectedCostCenter = 'CC-102-FINANCE';

  final List<String> _categories = [
    'Meals & Dining',
    'Travel & Transport',
    'Office Equipment',
    'Software & Tools',
    'Medical & Health',
    'Miscellaneous'
  ];

  final List<String> _projects = [
    'Project Alpha',
    'Project Beta',
    'Client Meeting',
    'Infrastructure Modernization',
    'Q3 Strategic Operations'
  ];

  final List<String> _costCenters = [
    'CC-102-FINANCE',
    'CC-300-ENG',
    'CC-404-SALES',
    'CC-500-EXEC',
    'CC-601-OPS'
  ];

  Future<void> _captureAndUploadReceipt(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imagePath = pickedFile.path;
        _isProcessingOcr = true;
        _statusMessage = null;
        _errorMessage = null;
      });

      // 1. Run OCR Extraction first to parse receipt & auto-fill fields
      Map<String, dynamic> ocrData = {};
      try {
        ocrData = await _ocrService.parseReceiptImage(
          filePath: _imagePath,
          fileBytes: _imageBytes,
          fileName: pickedFile.name,
          authToken: widget.authToken,
        );

        if (ocrData['merchant'] != null && ocrData['merchant'].toString().isNotEmpty) {
          _titleController.text = ocrData['merchant'].toString();
        }
        if (ocrData['amount'] != null) {
          _amountController.text = (ocrData['amount'] ?? 0.0).toString();
        }
        if (ocrData['date'] != null && ocrData['date'].toString().isNotEmpty) {
          _dateController.text = ocrData['date'].toString();
        }
        if (ocrData['tax'] != null) {
          _taxController.text = (ocrData['tax'] ?? 0.0).toString();
        }

        final ocrCat = ocrData['category']?.toString() ?? '';
        if (ocrCat.contains('Food') || ocrCat.contains('Dining') || ocrCat.contains('Groceries')) {
          _selectedCategory = 'Meals & Dining';
        } else if (ocrCat.contains('Travel') || ocrCat.contains('Commute')) {
          _selectedCategory = 'Travel & Commute';
        } else if (ocrCat.contains('Office') || ocrCat.contains('Shopping')) {
          _selectedCategory = 'Office Supplies';
        } else if (ocrCat.contains('Health') || ocrCat.contains('Medical')) {
          _selectedCategory = 'Medical & Health';
        } else if (_categories.contains(ocrCat)) {
          _selectedCategory = ocrCat;
        }

        _isLowConfidence = ocrData['isLowConfidence'] ?? false;
      } catch (ocrErr) {
        debugPrint('OCR parsing note: $ocrErr');
      }

      // 2. Upload Bill to Secure Storage
      try {
        final uploadRes = await _billService.uploadBillPhoto(
          filePath: _imagePath,
          fileBytes: _imageBytes,
          fileName: pickedFile.name,
          merchantName: _titleController.text.isNotEmpty ? _titleController.text : 'Scanned Expense',
          totalAmount: double.tryParse(_amountController.text) ?? 0.0,
          authToken: widget.authToken,
        );
        _attachedBillId = uploadRes['data']?['id'] ?? uploadRes['data']?['billId'];
      } catch (uploadErr) {
        debugPrint('Bill upload note: $uploadErr');
      }

      setState(() {
        _isProcessingOcr = false;
        if (_isLowConfidence) {
          _statusMessage = '⚠️ Low OCR confidence. Please review pre-filled values.';
        } else if (ocrData.isNotEmpty) {
          _statusMessage = '✨ Bill uploaded & fields auto-extracted via OCR!';
        } else {
          _statusMessage = '📸 Receipt attached. Please verify expense details below.';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _errorMessage = 'Attachment failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _submitClaim() async {
    if (!_isReimbursable) {
      setState(() => _errorMessage = 'Expense must be tagged as Reimbursable before submitting.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter an expense title.');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid expense amount.');
      return;
    }
    if (_selectedCategory == null || _selectedProject == null || _selectedCostCenter == null) {
      setState(() => _errorMessage = 'Category, Project, and Cost-Center selection are mandatory.');
      return;
    }
    if (_attachedBillId == null) {
      setState(() => _errorMessage = 'Please attach a bill/receipt photo before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final claimRes = await _claimService.submitClaim(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory!,
        project: _selectedProject!,
        costCenter: _selectedCostCenter!,
        billId: _attachedBillId!,
        authToken: widget.authToken,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim submitted successfully! Status: ${claimRes['status']}'),
          backgroundColor: Colors.green[800],
        ),
      );

      // Navigate to My Claims View
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyClaimsScreen(authToken: widget.authToken)),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Submit Claim',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppColors.primary),
            tooltip: 'My Claims',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyClaimsScreen(authToken: widget.authToken)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reimbursable Tag Toggle
            Card(
              elevation: 0,
              color: _isReimbursable ? AppColors.primaryLight : AppColors.surfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _isReimbursable ? AppColors.primary : AppColors.border, width: 1.2),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Tag as Reimbursable Expense',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(_isReimbursable ? 'Claim will be submitted to linked employer' : 'Personal expense only'),
                value: _isReimbursable,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _isReimbursable = val),
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Attachment Container
            GestureDetector(
              onTap: () => _captureAndUploadReceipt(ImageSource.camera),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _attachedBillId != null ? AppColors.green : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text('Attach Bill / Receipt Photo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text('Required for claim submission', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _captureAndUploadReceipt(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureAndUploadReceipt(ImageSource.gallery),
                    icon: const Icon(Icons.photo, color: AppColors.primary),
                    label: const Text('Gallery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isProcessingOcr) ...[
              const LinearProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 12),
            ],

            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isLowConfidence ? Colors.amber[50] : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isLowConfidence ? Colors.amber[700]! : AppColors.greenBorder),
                ),
                child: Text(_statusMessage!, style: TextStyle(color: _isLowConfidence ? Colors.amber[900] : AppColors.green)),
              ),
              const SizedBox(height: 12),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withOpacity(0.4)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Expense Title *',
                prefixIcon: Icon(Icons.edit, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (\$) *',
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Mandatory Classifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category, color: AppColors.primary),
              ),
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedProject,
              decoration: const InputDecoration(
                labelText: 'Project *',
                prefixIcon: Icon(Icons.work, color: AppColors.primary),
              ),
              items: _projects.map((proj) => DropdownMenuItem(value: proj, child: Text(proj))).toList(),
              onChanged: (val) => setState(() => _selectedProject = val),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCostCenter,
              decoration: const InputDecoration(
                labelText: 'Cost Center *',
                prefixIcon: Icon(Icons.account_tree, color: AppColors.primary),
              ),
              items: _costCenters.map((cc) => DropdownMenuItem(value: cc, child: Text(cc))).toList(),
              onChanged: (val) => setState(() => _selectedCostCenter = val),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Claim to Employer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
