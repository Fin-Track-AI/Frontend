import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';

class OcrService {
  final String baseUrl;

  OcrService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Send receipt image to OCR auto-extraction service (supports Web bytes & File path)
  Future<Map<String, dynamic>> parseReceiptImage({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/ocr/upload-and-parse');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $authToken';

    if (fileBytes != null && fileBytes.isNotEmpty) {
      final name = fileName ?? 'receipt.jpg';
      request.files.add(http.MultipartFile.fromBytes(
        'billImage',
        fileBytes,
        filename: name,
      ));
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('billImage', filePath));
    } else {
      throw Exception('No valid image file or bytes provided for OCR');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      final data = jsonResponse['data'];
      if (data is Map<String, dynamic>) {
        if (data['extractedData'] is Map<String, dynamic>) {
          return data['extractedData'];
        }
        return data;
      }
      return <String, dynamic>{};
    } else {
      throw Exception(jsonResponse['message'] ?? 'OCR extraction failed (${response.statusCode})');
    }
  }
}
