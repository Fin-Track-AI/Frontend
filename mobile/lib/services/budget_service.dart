import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import 'session_service.dart';
import 'user_financial_service.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  double overallBudget = 50000.0;
  List<Map<String, dynamic>> categoryBudgets = [
    {'category': 'Food & Dining', 'amount': 12000.0},
    {'category': 'Shopping', 'amount': 8000.0},
    {'category': 'Travel', 'amount': 6000.0},
    {'category': 'Bills & Utilities', 'amount': 15000.0},
    {'category': 'Entertainment', 'amount': 4000.0},
    {'category': 'Others', 'amount': 5000.0},
  ];
  List<int> alertThresholds = [80, 100];
  List<Map<String, dynamic>> activeAlerts = [];
  Map<String, dynamic>? peerBenchmarkData;

  String _userKey(String key) {
    final uid = SessionService().userId;
    return uid.isNotEmpty ? 'fintrack_${uid}_$key' : 'fintrack_guest_$key';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedOverall = prefs.getDouble(_userKey('overall_budget'));
    if (cachedOverall != null && cachedOverall > 0) {
      overallBudget = cachedOverall;
    }

    final cachedCats = prefs.getString(_userKey('category_budgets'));
    if (cachedCats != null && cachedCats.isNotEmpty) {
      try {
        final List decoded = jsonDecode(cachedCats);
        categoryBudgets = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }

    // Evaluate initial local alerts based on current financial service transactions
    evaluateLocalAlerts();

    // Sync with backend
    await fetchBackendBudget();
    await fetchPeerBenchmark();
  }

  void evaluateLocalAlerts() {
    final finService = UserFinancialService();
    final currentSpent = finService.currentMonthSpent;
    final catSpentMap = <String, double>{};

    for (var tx in finService.userTransactions) {
      if (tx['type'] == 'income') continue;
      final cat = tx['category'] as String? ?? 'Others';
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      catSpentMap[cat] = (catSpentMap[cat] ?? 0.0) + amt;
    }

    final alerts = <Map<String, dynamic>>[];
    final warnT = alertThresholds.isNotEmpty ? alertThresholds.first : 80;
    final alertT = alertThresholds.length > 1 ? alertThresholds.last : 100;

    // Overall check
    if (overallBudget > 0) {
      final pct = (currentSpent / overallBudget) * 100;
      if (pct >= alertT) {
        alerts.add({
          'id': 'overall_exceeded',
          'type': 'OVERALL',
          'category': 'Overall Monthly Budget',
          'level': 'EXCEEDED',
          'thresholdPercent': alertT,
          'currentPct': pct.round(),
          'spent': currentSpent,
          'limit': overallBudget,
          'message': '🚨 Overall monthly budget EXCEEDED! Spent ₹${currentSpent.toStringAsFixed(0)} of ₹${overallBudget.toStringAsFixed(0)} (${pct.round()}%).',
        });
      } else if (pct >= warnT) {
        alerts.add({
          'id': 'overall_warn',
          'type': 'OVERALL',
          'category': 'Overall Monthly Budget',
          'level': 'WARNING',
          'thresholdPercent': warnT,
          'currentPct': pct.round(),
          'spent': currentSpent,
          'limit': overallBudget,
          'message': '⚠️ Budget warning: Reached ${pct.round()}% of overall monthly budget.',
        });
      }
    }

    // Category check
    for (var cb in categoryBudgets) {
      final cat = cb['category'] as String;
      final limit = (cb['amount'] as num?)?.toDouble() ?? 0.0;
      if (limit <= 0) continue;

      final spent = catSpentMap[cat] ?? 0.0;
      final pct = (spent / limit) * 100;

      if (pct >= alertT) {
        alerts.add({
          'id': 'cat_exceeded_$cat',
          'type': 'CATEGORY',
          'category': cat,
          'level': 'EXCEEDED',
          'thresholdPercent': alertT,
          'currentPct': pct.round(),
          'spent': spent,
          'limit': limit,
          'message': '🚨 $cat budget EXCEEDED! Spent ₹${spent.toStringAsFixed(0)} of ₹${limit.toStringAsFixed(0)} (${pct.round()}%).',
        });
      } else if (pct >= warnT) {
        alerts.add({
          'id': 'cat_warn_$cat',
          'type': 'CATEGORY',
          'category': cat,
          'level': 'WARNING',
          'thresholdPercent': warnT,
          'currentPct': pct.round(),
          'spent': spent,
          'limit': limit,
          'message': '⚠️ $cat warning: Reached ${pct.round()}% of ₹${limit.toStringAsFixed(0)} limit.',
        });
      }
    }

    activeAlerts = alerts;
  }

  Future<void> fetchBackendBudget() async {
    final token = SessionService().token;
    if (token == null || token.isEmpty) return;

    try {
      final baseUrl = await ApiConfig.getActiveBaseUrl();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(Uri.parse('$baseUrl/budgets'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data != null) {
          overallBudget = (data['overallBudget'] as num?)?.toDouble() ?? overallBudget;

          final rawCats = data['categoryBudgets'] as List<dynamic>?;
          if (rawCats != null && rawCats.isNotEmpty) {
            categoryBudgets = rawCats.map((e) => {
              'category': e['category'] ?? 'Others',
              'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
            }).toList();
          }

          final rawAlerts = data['alerts'] as List<dynamic>?;
          if (rawAlerts != null) {
            activeAlerts = rawAlerts.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(_userKey('overall_budget'), overallBudget);
          await prefs.setString(_userKey('category_budgets'), jsonEncode(categoryBudgets));
        }
      }
    } catch (_) {}
  }

  Future<bool> saveBudget({
    required double newOverall,
    required List<Map<String, dynamic>> newCategoryBudgets,
    List<int>? newThresholds,
  }) async {
    overallBudget = newOverall;
    categoryBudgets = newCategoryBudgets;
    if (newThresholds != null) alertThresholds = newThresholds;

    evaluateLocalAlerts();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_userKey('overall_budget'), overallBudget);
    await prefs.setString(_userKey('category_budgets'), jsonEncode(categoryBudgets));

    final token = SessionService().token;
    if (token != null && token.isNotEmpty) {
      try {
        final baseUrl = await ApiConfig.getActiveBaseUrl();
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final body = jsonEncode({
          'overallBudget': overallBudget,
          'categoryBudgets': categoryBudgets,
          'alertThresholds': alertThresholds,
        });

        final res = await http.post(Uri.parse('$baseUrl/budgets'), headers: headers, body: body);
        if (res.statusCode == 200) {
          final resData = jsonDecode(res.body)['data'];
          if (resData != null && resData['alerts'] != null) {
            activeAlerts = (resData['alerts'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      } catch (_) {}
    }
    return true;
  }

  Future<void> fetchPeerBenchmark() async {
    final token = SessionService().token;
    if (token == null || token.isEmpty) {
      // Fallback mock peer data for offline/unauthenticated
      peerBenchmarkData = {
        'cohortName': '25–30 age group',
        'peerCount': 3820,
        'cohortAvgSpend': 36200,
        'userOverallSpent': UserFinancialService().currentMonthSpent,
        'comparisonText': 'You spent 12% less than peers in your age group this month. Great job!',
        'isAnonymized': true,
        'categoryBreakdown': [
          {'category': 'Food & Dining', 'cohortAvg': 10100, 'userSpent': 7800},
          {'category': 'Shopping', 'cohortAvg': 7900, 'userSpent': 4500},
          {'category': 'Bills & Utilities', 'cohortAvg': 9000, 'userSpent': 8500},
          {'category': 'Travel', 'cohortAvg': 5400, 'userSpent': 3200},
          {'category': 'Entertainment', 'cohortAvg': 3800, 'userSpent': 2100},
        ],
      };
      return;
    }

    try {
      final baseUrl = await ApiConfig.getActiveBaseUrl();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final res = await http.get(Uri.parse('$baseUrl/budgets/peer-benchmark'), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        peerBenchmarkData = Map<String, dynamic>.from(body['data'] as Map);
      }
    } catch (_) {}
  }
}
