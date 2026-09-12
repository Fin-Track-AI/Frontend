import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserFinancialService {
  static final UserFinancialService _instance = UserFinancialService._internal();
  factory UserFinancialService() => _instance;
  UserFinancialService._internal();

  static const String _keySetupComplete = 'fintrack_setup_complete';
  static const String _keyUserName = 'fintrack_user_name';
  static const String _keyMonthlySalary = 'fintrack_monthly_salary';
  static const String _keyRent = 'fintrack_rent';
  static const String _keyBills = 'fintrack_bills';
  static const String _keyEmi = 'fintrack_emi';
  static const String _keyTransactions = 'fintrack_user_transactions';

  bool isSetupComplete = false;
  String userName = 'Atharva';
  double monthlySalary = 50000.0;
  double rent = 15000.0;
  double bills = 3000.0;
  double emi = 2000.0;

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
    isSetupComplete = prefs.getBool(_keySetupComplete) ?? false;
    userName = prefs.getString(_keyUserName) ?? 'Atharva';
    monthlySalary = prefs.getDouble(_keyMonthlySalary) ?? 50000.0;
    rent = prefs.getDouble(_keyRent) ?? 15000.0;
    bills = prefs.getDouble(_keyBills) ?? 3000.0;
    emi = prefs.getDouble(_keyEmi) ?? 2000.0;

    final txStr = prefs.getString(_keyTransactions);
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
    await prefs.setBool(_keySetupComplete, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setDouble(_keyMonthlySalary, salary);
    await prefs.setDouble(_keyRent, rentVal);
    await prefs.setDouble(_keyBills, billsVal);
    await prefs.setDouble(_keyEmi, emiVal);
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
    await prefs.setString(_keyTransactions, jsonEncode(userTransactions));
  }

  Future<void> resetAccountToFreshState() async {
    isSetupComplete = false;
    userName = 'Atharva';
    monthlySalary = 0.0;
    rent = 0.0;
    bills = 0.0;
    emi = 0.0;
    userTransactions = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySetupComplete);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyMonthlySalary);
    await prefs.remove(_keyRent);
    await prefs.remove(_keyBills);
    await prefs.remove(_keyEmi);
    await prefs.remove(_keyTransactions);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
