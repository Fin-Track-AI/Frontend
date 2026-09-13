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
  /// Returns the active month (YYYY-MM) present in transactions, defaulting to latest or current
  String get activeMonth {
    final now = DateTime.now();
    final currentYM = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final hasCurrent = userTransactions.any((t) => (t['date'] as String? ?? '').startsWith(currentYM));
    if (hasCurrent) return currentYM;

    String latest = currentYM;
    for (var tx in userTransactions) {
      final d = (tx['date'] as String? ?? '').trim();
      if (d.length >= 7 && (latest == currentYM || d.substring(0, 7).compareTo(latest) > 0)) {
        latest = d.substring(0, 7);
      }
    }
    return latest;
  }

  bool _isTxIncome(Map<String, dynamic> tx) {
    if (tx['type'] == 'income') return true;
    if (tx['category'] == 'Salary') return true;
    final title = (tx['title'] as String? ?? '').toLowerCase();
    final note = (tx['note'] as String? ?? '').toLowerCase();
    if (title.contains('salary') || note.contains('salary')) return true;
    return false;
  }

  /// Expenses scoped to the active/current month (strictly excludes income)
  double get currentMonthSpent {
    final ym = activeMonth;
    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) continue;
      final d = (tx['date'] as String? ?? '').trim();
      if (d.startsWith(ym) || userTransactions.length < 5) {
        sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return sum;
  }

  /// Returns the latest salary transaction, if any
  Map<String, dynamic>? get latestSalaryTransaction {
    Map<String, dynamic>? latest;
    for (var tx in userTransactions) {
      final isSalary = tx['category'] == 'Salary' ||
          (tx['type'] == 'income' &&
              ((tx['title'] as String? ?? '').toLowerCase().contains('salary') ||
               (tx['note'] as String? ?? '').toLowerCase().contains('salary')));
      if (isSalary) {
        final d = (tx['date'] as String? ?? '').trim();
        if (d.isNotEmpty) {
          if (latest == null || d.compareTo(latest['date'] as String? ?? '') > 0) {
            latest = tx;
          }
        }
      }
    }
    return latest;
  }

  /// Returns the start date of the active spending cycle (YYYY-MM-DD)
  String get currentCycleStartDate {
    final salaryTx = latestSalaryTransaction;
    if (salaryTx != null) {
      final d = (salaryTx['date'] as String? ?? '').trim();
      if (d.isNotEmpty) return d;
    }
    return '$activeMonth-01';
  }

  /// Label describing the current active spending cycle
  String get currentCycleLabel {
    final salaryTx = latestSalaryTransaction;
    if (salaryTx != null) {
      final d = (salaryTx['date'] as String? ?? '').trim();
      if (d.isNotEmpty) {
        try {
          final dt = DateTime.parse(d);
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return 'Cycle: Since ${dt.day} ${months[dt.month - 1]} Salary';
        } catch (_) {
          return 'Cycle: Since $d Salary';
        }
      }
    }
    return 'Active Month: $activeMonth';
  }

  /// Discretionary expenses in the active spending cycle (since latest salary arrived).
  /// Excludes income/salary, and excludes fixed obligations like Rent when already deducted in Safe Cap.
  double get currentCycleDiscretionarySpent {
    final salaryTx = latestSalaryTransaction;
    final cycleStart = currentCycleStartDate;

    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) continue;

      // Fixed rent is already accounted for in safeToSpendCap
      if (rent > 0 && (tx['category'] as String? ?? '').toLowerCase() == 'rent') {
        continue;
      }

      final d = (tx['date'] as String? ?? '').trim();
      if (salaryTx != null) {
        if (d.compareTo(cycleStart) > 0) {
          sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        } else if (d == cycleStart) {
          if (tx['source'] != 'statement') {
            sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } else {
        if (d.startsWith(activeMonth) || userTransactions.length < 5) {
          sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return sum;
  }

  /// Total expenses in active spending cycle (since latest salary arrived)
  double get currentCycleSpent {
    final salaryTx = latestSalaryTransaction;
    final cycleStart = currentCycleStartDate;

    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) continue;
      final d = (tx['date'] as String? ?? '').trim();
      if (salaryTx != null) {
        if (d.compareTo(cycleStart) > 0) {
          sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        } else if (d == cycleStart) {
          if (tx['source'] != 'statement') {
            sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } else {
        if (d.startsWith(activeMonth) || userTransactions.length < 5) {
          sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return sum;
  }

  /// Discretionary expenses scoped to active calendar month
  double get currentMonthDiscretionarySpent {
    final ym = activeMonth;
    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) continue;
      if (rent > 0 && (tx['category'] as String? ?? '').toLowerCase() == 'rent') {
        continue;
      }
      final d = (tx['date'] as String? ?? '').trim();
      if (d.startsWith(ym) || userTransactions.length < 5) {
        sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return sum;
  }

  /// Income scoped to the active/current month
  double get currentMonthIncome {
    final ym = activeMonth;
    double sum = 0.0;
    for (var tx in userTransactions) {
      if (!_isTxIncome(tx)) continue;
      final d = (tx['date'] as String? ?? '').trim();
      if (d.startsWith(ym)) {
        sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return sum;
  }

  /// Total expenses across all time (strictly excludes income)
  double get totalSpent {
    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) continue;
      sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return sum;
  }

  /// Total income across all time
  double get totalIncome {
    double sum = 0.0;
    for (var tx in userTransactions) {
      if (_isTxIncome(tx)) {
        sum += (tx['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return sum;
  }

  double get remainingSafeToSpend => safeToSpendCap - currentCycleDiscretionarySpent;

  double get budgetUtilizedPercent {
    if (safeToSpendCap <= 0) return 0.0;
    final pct = (currentCycleDiscretionarySpent / safeToSpendCap) * 100;
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

    // Sync from backend if user is authenticated
    await fetchBackendData();
  }

  Future<void> fetchBackendData() async {
    final token = SessionService().token;
    if (token == null || token.isEmpty) return;

    try {
      final baseUrl = await ApiConfig.getActiveBaseUrl();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Fetch user profile to get latest salary/rent
      final profileRes = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: headers);
      if (profileRes.statusCode == 200) {
        final body = jsonDecode(profileRes.body);
        final user = body['data']?['user'];
        if (user != null) {
          final salaryVal = (user['salary'] as num?)?.toDouble() ?? 0.0;
          final rentVal = (user['rent'] as num?)?.toDouble() ?? 0.0;
          final billsVal = (user['bills'] as num?)?.toDouble() ?? 0.0;
          final emiVal = (user['emi'] as num?)?.toDouble() ?? 0.0;
          final nameVal = user['name'] as String? ?? userName;

          if (salaryVal > 0) monthlySalary = salaryVal;
          if (rentVal > 0) rent = rentVal;
          if (billsVal > 0) bills = billsVal;
          if (emiVal > 0) emi = emiVal;
          userName = nameVal;
          isSetupComplete = user['isSetupComplete'] == true || salaryVal > 0;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(_userKey('monthly_salary'), monthlySalary);
          await prefs.setDouble(_userKey('rent'), rent);
          await prefs.setDouble(_userKey('bills'), bills);
          await prefs.setDouble(_userKey('emi'), emi);
          await prefs.setString(_userKey('user_name'), userName);
          await prefs.setBool(_userKey('setup_complete'), isSetupComplete);
        }
      }

      // 2. Fetch user transactions from MongoDB
      final txRes = await http.get(Uri.parse('$baseUrl/transactions?limit=1000'), headers: headers);
      if (txRes.statusCode == 200) {
        final body = jsonDecode(txRes.body);
        final rawList = body['data']?['transactions'] as List<dynamic>?;
        if (rawList != null) {
          final backendTxns = rawList.map((tx) {
            final map = tx as Map<String, dynamic>;
            final dateRaw = map['date']?.toString() ?? '';
            final dateStr = dateRaw.contains('T') ? dateRaw.split('T')[0] : dateRaw;

            return {
              'id': map['_id']?.toString() ?? map['id']?.toString() ?? '',
              'title': map['title'] ?? 'Transaction',
              'category': map['category'] ?? 'Others',
              'amount': (map['amount'] as num?)?.toDouble() ?? 0.0,
              'type': map['type'] ?? 'expense',
              'date': dateStr,
              'paidVia': map['paidVia'] ?? 'UPI',
              'source': map['source'] ?? 'manual',
              'isReimbursable': map['isReimbursable'] == true,
              'note': map['note'] ?? '',
            };
          }).toList();

          userTransactions = backendTxns;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey('transactions'), jsonEncode(userTransactions));
        }
      }
    } catch (_) {}
  }

  Future<void> importStatementTransactions({
    required List<Map<String, dynamic>> transactions,
    double? overrideSalary,
    double? overrideRent,
  }) async {
    // Prepend new statement transactions
    userTransactions.insertAll(0, transactions);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey('transactions'), jsonEncode(userTransactions));

    if (overrideSalary != null && overrideSalary > 0) {
      monthlySalary = overrideSalary;
      await prefs.setDouble(_userKey('monthly_salary'), overrideSalary);
      await SessionService().updateUser({'salary': overrideSalary});
    }

    if (overrideRent != null && overrideRent > 0) {
      rent = overrideRent;
      await prefs.setDouble(_userKey('rent'), overrideRent);
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
        final activeBaseUrl = await ApiConfig.getActiveBaseUrl();
        await http.put(
          Uri.parse('$activeBaseUrl/auth/profile'),
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
    String? dateString,
  }) async {
    final now = DateTime.now();
    final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tx = {
      'id': 'TX_${now.millisecondsSinceEpoch}',
      'title': title,
      'category': category,
      'amount': amount,
      'date': dateString ?? todayIso,
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
