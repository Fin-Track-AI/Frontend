import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';

class AiService {
  final String baseUrl;

  AiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// SCRUM-170, SCRUM-171, SCRUM-173:
  /// Send user chat prompt to FinTrack AI Assistant API and receive grounded response
  Future<Map<String, dynamic>> sendChatMessage({
    required String prompt,
    required String authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': prompt,
      }),
    );

    final jsonResponse = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(
        jsonResponse['message'] ?? 'Failed to process AI chat query (${response.statusCode})',
      );
    }
  }

  /// Get summary insights
  Future<Map<String, dynamic>> getInsights({required String authToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/insights'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to fetch AI insights');
    }
  }
}
