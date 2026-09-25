import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';

class InsightService {
  final String baseUrl;

  InsightService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Fetch active proactive nudges (SCRUM-179)
  Future<List<Map<String, dynamic>>> getProactiveNudges({required String authToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/nudges'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      final List<dynamic> list = jsonResponse['data'] ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to fetch proactive nudges');
    }
  }

  /// Dismiss a proactive nudge
  Future<bool> dismissNudge({required String nudgeId, required String authToken}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/ai/nudges/$nudgeId/dismiss'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    final jsonResponse = jsonDecode(response.body);
    return response.statusCode == 200 && jsonResponse['success'] == true;
  }

  /// Recategorize a transaction & provide smart feedback (SCRUM-190)
  Future<Map<String, dynamic>> recategorizeTransaction({
    required String transactionId,
    required String newCategory,
    required String authToken,
    bool applyToFuture = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/recategorize'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'transactionId': transactionId,
        'newCategory': newCategory,
        'applyToFuture': applyToFuture,
      }),
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return Map<String, dynamic>.from(jsonResponse['data'] as Map);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to recategorize transaction');
    }
  }
}
