import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OcrService {
  final String baseUrl;

  OcrService({this.baseUrl = 'http://localhost:5001/api/v1'});

  /// Send receipt image to OCR auto-extraction service (supports Web bytes & File path)
  Future<Map<String, dynamic>> parseReceiptImage({
    String? filePath,
    Uint8List? fileBytes,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/ocr/upload-and-parse');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $authToken';

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'billImage',
        fileBytes,
        filename: 'receipt.jpg',
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
      return jsonResponse['data']['extractedData'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'OCR extraction failed (${response.statusCode})');
    }
  }
}
