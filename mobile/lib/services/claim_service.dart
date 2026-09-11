import 'package:http/http.dart' as http;
import 'dart:convert';

class ClaimService {
  final String baseUrl;

  ClaimService({this.baseUrl = 'http://localhost:5001/api/v1'});

  /// Submit a new reimbursement claim
  Future<Map<String, dynamic>> submitClaim({
    required String title,
    required double amount,
    required String category,
    required String project,
    required String costCenter,
    required String billId,
    required String authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/claims'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'category': category,
        'project': project,
        'costCenter': costCenter,
        'billId': billId,
      }),
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 201 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to submit claim (${response.statusCode})');
    }
  }

  /// Get user's submitted claims list ("My Claims" view)
  Future<List<dynamic>> getMyClaims({required String authToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/claims/my-claims'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data']['claims'] ?? [];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to fetch claims');
    }
  }
}
