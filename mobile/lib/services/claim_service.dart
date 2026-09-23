import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';

class ClaimService {
  final String baseUrl;

  ClaimService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  /// Verify corporate invite code before claiming
  Future<Map<String, dynamic>> verifyInviteCode({
    required String code,
    String? authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employer/invites/verify'),
      headers: {
        if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code.trim().toUpperCase()}),
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Invalid or inactive invite code');
    }
  }

  /// Claim invite code to join the organization
  Future<Map<String, dynamic>> claimInviteCode({
    required String code,
    required String authToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employer/invites/claim'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code.trim().toUpperCase()}),
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to join company with code');
    }
  }

  /// Check linked employer affiliation for current employee
  Future<Map<String, dynamic>> getMyCompany({required String authToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employer/my-company'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    final jsonResponse = jsonDecode(response.body);
    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      return jsonResponse['data'];
    } else {
      return {'hasEmployer': false, 'employer': null};
    }
  }
}
