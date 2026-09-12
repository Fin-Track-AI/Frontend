import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';

class BillUploadService {
  final String baseUrl;

  BillUploadService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Upload a bill image file (supports Web bytes and File path)
  Future<Map<String, dynamic>> uploadBillPhoto({
    String? filePath,
    Uint8List? fileBytes,
    required String merchantName,
    required double totalAmount,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/bills/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $authToken';
    request.fields['merchantName'] = merchantName;
    request.fields['totalAmount'] = totalAmount.toString();

    if (fileBytes != null && fileBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'billImage',
        fileBytes,
        filename: 'receipt.jpg',
      ));
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('billImage', filePath));
    } else {
      throw Exception('No valid image file or bytes provided');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 201 && jsonResponse['success'] == true) {
      return jsonResponse;
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to upload bill photo (${response.statusCode})');
    }
  }

  String getBillImageUrl(String billId) {
    return '$baseUrl/bills/$billId/image';
  }
}
