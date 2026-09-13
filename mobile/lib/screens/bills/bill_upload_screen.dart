import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/bill_upload_service.dart';

class BillUploadScreen extends StatefulWidget {
  final String authToken;

  const BillUploadScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  _BillUploadScreenState createState() => _BillUploadScreenState();
}

class _BillUploadScreenState extends State<BillUploadScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _service = BillUploadService();

  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadBill() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Please capture or select a bill photo.');
      return;
    }
    if (_merchantController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter merchant name.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _service.uploadBillPhoto(
        filePath: _selectedImage!.path,
        merchantName: _merchantController.text.trim(),
        totalAmount: amount,
        authToken: widget.authToken,
      );

      setState(() {
        _isUploading = false;
        _successMessage = 'Receipt uploaded successfully! (ID: ${result['data']['id']})';
        _selectedImage = null;
        _merchantController.clear();
        _amountController.clear();
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Capture & Upload Bill', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Image Container
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary),
                        SizedBox(height: 8),
                        Text('No receipt image selected', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Camera / Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('Capture Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: AppColors.primary),
                    label: const Text('Gallery', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form Inputs
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
                prefixIcon: Icon(Icons.store, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount (\$) ',
                prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Feedback Messages
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.red.withOpacity(0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w500),
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.greenBorder),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Upload & Save Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
