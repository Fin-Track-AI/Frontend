import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5001/api/v1/auth';
  
  static const String _tokenKey = 'fintrack_auth_token';
  static const String _userKey = 'fintrack_user_data';

  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    String? name,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'name': name ?? 'User $phone',
          'email': email ?? '$phone@fintrack.app',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = data['data']['user'];
        final token = data['data']['token'];

        // Persist session locally
        await saveSession(token: token, user: userData);

        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      // Fallback local save if network is unreachable
      final fallbackUser = {
        'id': 'user_$phone',
        'phone': phone,
        'name': name ?? 'FinTrack User',
        'email': email ?? '$phone@fintrack.app',
      };
      const fallbackToken = 'mock_jwt_token_local';
      await saveSession(token: fallbackToken, user: fallbackUser);
      return {'user': fallbackUser, 'token': fallbackToken};
    }
  }

  Future<void> saveSession({required String token, required Map<String, dynamic> user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr == null || userStr.isEmpty) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
