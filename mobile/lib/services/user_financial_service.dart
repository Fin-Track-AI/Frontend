import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import 'session_service.dart';

class UserFinancialService {
  static final UserFinancialService _instance = UserFinancialService._internal();
  factory UserFinancialService() => _instance;
  UserFinancialService._internal();

  String _userKey(String key) {
    final uid = SessionService().userId;
    if (uid.isNotEmpty) {
      return 'fintrack_${uid}_$key';
    }
    return 'fintrack_guest_$key';
  }

  bool isSetupComplete = false;
  String userName = '';
  double monthlySalary = 0.0;
  double rent = 0.0;
  double bills = 0.0;
  double emi = 0.0;

  List<Map<String, dynamic>> userTransactions = [];

  double get totalFixedObligations => rent + bills + emi;
  double get safeToSpendCap => (monthlySalary - totalFixedObligations) > 0 ? (monthlySalary - totalFixedObligations) : monthlySalary;
  
  double get totalSpent {
    double sum = 0.0;
    for (var tx in userTransactions) {
      sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  double get remainingSafeToSpend => safeToSpendCap - totalSpent;

  double get budgetUtilizedPercent {
    if (safeToSpendCap <= 0) return 0.0;
    final pct = (totalSpent / safeToSpendCap) * 100;
    return pct.clamp(0.0, 100.0);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultName = SessionService().userName;

    isSetupComplete = prefs.getBool(_userKey('setup_complete')) ?? false;
    userName = prefs.getString(_userKey('user_name')) ?? defaultName;
    monthlySalary = prefs.getDouble(_userKey('monthly_salary')) ?? 0.0;
    rent = prefs.getDouble(_userKey('rent')) ?? 0.0;
    bills = prefs.getDouble(_userKey('bills')) ?? 0.0;
    emi = prefs.getDouble(_userKey('emi')) ?? 0.0;

    final txStr = prefs.getString(_userKey('transactions'));
    if (txStr != null && txStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(txStr);
        userTransactions = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        userTransactions = [];
      }
    } else {
      userTransactions = [];
    }
  }

  Future<void> saveFinancialSetup({
    required String name,
    required double salary,
    required double rentVal,
    required double billsVal,
    required double emiVal,
  }) async {
    isSetupComplete = true;
    userName = name;
    monthlySalary = salary;
    rent = rentVal;
    bills = billsVal;
    emi = emiVal;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userKey('setup_complete'), true);
    await prefs.setString(_userKey('user_name'), name);
    await prefs.setDouble(_userKey('monthly_salary'), salary);
    await prefs.setDouble(_userKey('rent'), rentVal);
    await prefs.setDouble(_userKey('bills'), billsVal);
    await prefs.setDouble(_userKey('emi'), emiVal);

    // Also update session user name
    await SessionService().updateUser({'name': name, 'salary': salary});

    // Sync to backend if token available
    final token = SessionService().token;
    if (token != null && token.isNotEmpty) {
      try {
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'salary': salary,
            'rent': rentVal,
            'bills': billsVal,
            'emi': emiVal,
          }),
        );
      } catch (_) {}
    }
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    String? paidVia,
    bool isReimbursable = false,
  }) async {
    final tx = {
      'id': 'TX_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'category': category,
      'amount': amount,
      'date': 'Today, ${_formatTime(DateTime.now())}',
      'paidVia': paidVia ?? 'UPI',
      'isReimbursable': isReimbursable,
    };

    userTransactions.insert(0, tx);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey('transactions'), jsonEncode(userTransactions));
  }

  Future<void> resetAccountToFreshState() async {
    isSetupComplete = false;
    userName = SessionService().userName;
    monthlySalary = 0.0;
    rent = 0.0;
    bills = 0.0;
    emi = 0.0;
    userTransactions = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey('setup_complete'));
    await prefs.remove(_userKey('user_name'));
    await prefs.remove(_userKey('monthly_salary'));
    await prefs.remove(_userKey('rent'));
    await prefs.remove(_userKey('bills'));
    await prefs.remove(_userKey('emi'));
    await prefs.remove(_userKey('transactions'));
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
