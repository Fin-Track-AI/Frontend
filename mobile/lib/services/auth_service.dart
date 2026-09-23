import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'session_service.dart';
import 'user_financial_service.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  final SessionService _session = SessionService();

  /// Send email verification OTP via backend.
  Future<Map<String, dynamic>> sendEmailOtp({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Failed to send OTP. Please check your email.');
    }
  }

  /// Verify OTP and log user in. Sets up session and user-specific financial profile.
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
    String? name,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final payload = data['data'] as Map<String, dynamic>;
      final userData = payload['user'] as Map<String, dynamic>;
      final token = payload['token'] as String;

      // Save user session
      await _session.saveSession(token: token, user: userData);

      // Auto-grant default consents on successful login/verification
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/consent'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'upiConsent': true,
            'billStorageConsent': true,
            'aiUsageConsent': true,
          }),
        );
      } catch (_) {}

      // Initialize financial service for this specific user
      final financialService = UserFinancialService();
      await financialService.init();

      // If backend has user financial data, sync it
      final salary = (userData['salary'] as num?)?.toDouble() ?? 0.0;
      if (salary > 0 && !financialService.isSetupComplete) {
        await financialService.saveFinancialSetup(
          name: userData['name'] as String? ?? 'User',
          salary: salary,
          rentVal: (userData['rent'] as num?)?.toDouble() ?? 0.0,
          billsVal: (userData['bills'] as num?)?.toDouble() ?? 0.0,
          emiVal: (userData['emi'] as num?)?.toDouble() ?? 0.0,
        );
      }

      return payload;
    } else {
      throw Exception(data['message'] ?? 'Verification failed. Please check the code.');
    }
  }

  /// Fallback login with phone/dummy for compatibility
  Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
    String? name,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'name': name ?? 'User $phone',
        'email': email ?? '$phone@fintrack.app',
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final userData = data['data']['user'] as Map<String, dynamic>;
      final token = data['data']['token'] as String;
      await _session.saveSession(token: token, user: userData);
      await UserFinancialService().init();
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Login failed.');
    }
  }

  /// Delegate to SessionService for backward compatibility.
  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) =>
      _session.saveSession(token: token, user: user);

  /// Returns the saved user object from memory (via SessionService).
  Future<Map<String, dynamic>?> getSavedUser() async => _session.user;

  /// Returns the saved JWT token from memory (via SessionService).
  Future<String?> getSavedToken() async => _session.token;

  /// Clear session, reset financial service, and logout.
  Future<void> logout() async {
    await _session.clearSession();
    await UserFinancialService().init(); // re-inits into unauthenticated fresh state
  }
}
