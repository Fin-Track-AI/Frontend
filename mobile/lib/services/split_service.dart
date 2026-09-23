import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../models/split_models.dart';
import 'session_service.dart';

class SplitService extends ChangeNotifier {
  static final SplitService _instance = SplitService._internal();
  factory SplitService() => _instance;
  SplitService._internal();

  static const String _storageKey = 'fintrack_split_groups_v1';
  static const String _settledDebtsKey = 'fintrack_settled_debts_v1';

  List<SplitGroup> _groups = [];
  final Set<String> _settledDebtIds = {};

  List<SplitGroup> get groups => List.unmodifiable(_groups);

  List<SplitGroup> get pendingInvitations {
    final currentUserId = currentUser.id;
    final currentPhone = currentUser.phoneNumber;
    return _groups.where((g) {
      return g.members.any((m) {
        final matchesUser = (m.id == currentUserId && m.id != 'usr_me') ||
            (currentPhone.isNotEmpty && m.phoneNumber.isNotEmpty && m.phoneNumber.contains(currentPhone));
        return matchesUser && m.isPendingInvite;
      });
    }).toList();
  }

  GroupMember get currentUser {
    final session = SessionService();
    final currentUserName = session.userName.isNotEmpty
        ? session.userName.split(' ').first
        : 'You';
    return GroupMember(
      id: session.userId.isNotEmpty ? session.userId : 'usr_me',
      name: currentUserName,
      isCurrentUser: true,
      avatarUrl: session.avatarUrl,
      phone: session.userPhone,
      status: 'ACCEPTED',
    );
  }

  Future<void> init() => initialize();

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settledJson = prefs.getStringList(_settledDebtsKey);
      if (settledJson != null) {
        _settledDebtIds.addAll(settledJson);
      }

      final groupsJson = prefs.getString(_storageKey);
      if (groupsJson != null && groupsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(groupsJson) as List<dynamic>;
        // Strip out any legacy seeded mock trips
        _groups = decoded
            .map((g) => SplitGroup.fromJson(g as Map<String, dynamic>))
            .where((g) => g.id != 'grp_goa' && g.id != 'grp_flat' && g.id != 'grp_lunch')
            .toList();
      } else {
        _groups = [];
      }

      // Try syncing groups from backend
      await _syncFromBackend();
    } catch (e) {
      debugPrint('Error loading split groups: $e');
      _groups = [];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_groups.map((g) => g.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
      await prefs.setStringList(_settledDebtsKey, _settledDebtIds.toList());
    } catch (e) {
      debugPrint('Error saving split groups: $e');
    }
  }

  Future<void> _syncFromBackend() async {
    try {
      final token = SessionService().token;
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}/split/groups');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          final List<dynamic> list = data['data'] as List<dynamic>;
          if (list.isNotEmpty) {
            _groups = list.map((g) => SplitGroup.fromJson(g as Map<String, dynamic>)).toList();
            await _save();
          }
        }
      }
    } catch (e) {
      debugPrint('Backend sync split groups: $e');
    }
  }

  /// Look up registered user by mobile phone in FinTrack's database
  Future<Map<String, dynamic>> lookupUserByPhone(String phone) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) {
      return {
        'exists': false,
        'message': 'Please enter a mobile number',
      };
    }

    try {
      final token = SessionService().token;
      final uri = Uri.parse('${ApiConfig.baseUrl}/split/users/lookup?phone=${Uri.encodeComponent(cleanPhone)}');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['success'] == true) {
        final userData = (data['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>;
        return {
          'exists': true,
          'user': userData,
        };
      } else {
        return {
          'exists': false,
          'message': data['message'] ?? 'This person is not available on FinTrack. Please check the mobile number or invite them to join FinTrack.',
        };
      }
    } catch (e) {
      debugPrint('Error looking up user by phone: $e');
      return {
        'exists': false,
        'message': 'This person does not exist with FinTrack or is not available on FinTrack.',
      };
    }
  }

  /// Delete a split group completely and sync with backend
  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    await _save();
    notifyListeners();

    try {
      final token = SessionService().token;
      final uri = Uri.parse('${ApiConfig.baseUrl}/split/groups/$groupId');
      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Backend delete group error: $e');
    }
  }

  /// Accept or decline a group invitation
  Future<void> respondToInvitation(String groupId, bool accept) async {
    final action = accept ? 'ACCEPT' : 'DECLINE';
    final currentUserId = currentUser.id;

    final groupIndex = _groups.indexWhere((g) => g.id == groupId);
    if (groupIndex != -1) {
      final group = _groups[groupIndex];
      final updatedMembers = group.members.map((m) {
        if (m.id == currentUserId || m.isCurrentUser || (m.phoneNumber.isNotEmpty && m.phoneNumber == currentUser.phoneNumber)) {
          return m.copyWith(status: accept ? 'ACCEPTED' : 'DECLINED');
        }
        return m;
      }).toList();

      if (accept) {
        _groups[groupIndex] = group.copyWith(members: updatedMembers);
      } else {
        _groups.removeAt(groupIndex);
      }
      await _save();
      notifyListeners();
    }

    try {
      final token = SessionService().token;
      final uri = Uri.parse('${ApiConfig.baseUrl}/split/groups/$groupId/invitation');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Backend respond to invitation error: $e');
    }
  }

  // ===========================================================================
  // 1. EQUAL SPLIT CALCULATION (reconciles 100% with penny/paise balancing)
  // ===========================================================================
  List<SplitAllocation> calculateEqualSplit({
    required double totalAmount,
    List<GroupMember>? members,
    List<GroupMember>? includedMembers,
  }) {
    final activeMembers = members ?? includedMembers ?? [];
    if (activeMembers.isEmpty || totalAmount <= 0) return [];

    final count = activeMembers.length;
    final totalPaise = (totalAmount * 100).round();
    final basePaise = totalPaise ~/ count;
    final remainderPaise = totalPaise % count;

    final List<SplitAllocation> allocations = [];
    for (int i = 0; i < count; i++) {
      final memberPaise = basePaise + (i < remainderPaise ? 1 : 0);
      final memberAmount = memberPaise / 100.0;
      final percentage = (memberAmount / totalAmount) * 100.0;

      allocations.add(
        SplitAllocation(
          memberId: activeMembers[i].id,
          memberName: activeMembers[i].name,
          amount: memberAmount,
          percentage: double.parse(percentage.toStringAsFixed(2)),
        ),
      );
    }

    assert(
      (allocations.fold(0.0, (sum, a) => sum + a.amount) - totalAmount).abs() < 0.001,
      'Equal split must reconcile to 100% of total amount',
    );

    return allocations;
  }

  // ===========================================================================
  // 2. PERCENTAGE SPLIT CALCULATION (reconciles 100% of total)
  // ===========================================================================
  List<SplitAllocation> calculatePercentageSplit({
    required double totalAmount,
    required List<GroupMember> members,
    required Map<String, double> percentages,
  }) {
    if (members.isEmpty || totalAmount <= 0) return [];

    final totalPercent = percentages.values.fold(0.0, (s, p) => s + p);
    if ((totalPercent - 100.0).abs() > 0.1) {
      throw ArgumentError('Total percentages must equal 100%. Got $totalPercent%');
    }

    final totalPaise = (totalAmount * 100).round();
    int allocatedPaise = 0;
    final List<SplitAllocation> allocations = [];

    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final pct = percentages[m.id] ?? 0.0;
      int memberPaise;

      if (i == members.length - 1) {
        memberPaise = totalPaise - allocatedPaise;
      } else {
        memberPaise = ((totalAmount * (pct / 100.0)) * 100).round();
        allocatedPaise += memberPaise;
      }

      final amount = memberPaise / 100.0;
      allocations.add(
        SplitAllocation(
          memberId: m.id,
          memberName: m.name,
          amount: amount,
          percentage: pct,
        ),
      );
    }

    return allocations;
  }

  // ===========================================================================
  // 3. ITEMIZED SPLIT CALCULATION (per item + proportional tax/tip apportioning)
  // ===========================================================================
  List<SplitAllocation> calculateItemizedSplit({
    double? totalAmount,
    required List<ItemizedEntry> items,
    required List<GroupMember> members,
    double? taxAndTip,
    double? taxAndTipAmount,
  }) {
    final effectiveTaxTip = taxAndTip ?? taxAndTipAmount ?? 0.0;
    if (members.isEmpty) return [];

    final Map<String, double> memberSubtotals = {for (var m in members) m.id: 0.0};
    final Map<String, List<String>> memberItemNames = {for (var m in members) m.id: []};

    double rawItemsTotal = 0.0;
    for (final item in items) {
      rawItemsTotal += item.price;
      final assigned = item.assignedMemberIds.isEmpty
          ? members.map((m) => m.id).toList()
          : item.assignedMemberIds;

      final share = item.price / assigned.length;
      for (final id in assigned) {
        if (memberSubtotals.containsKey(id)) {
          memberSubtotals[id] = (memberSubtotals[id] ?? 0.0) + share;
          memberItemNames[id]?.add(item.name);
        }
      }
    }

    final double grandTotal = totalAmount ?? (rawItemsTotal + effectiveTaxTip);
    final int grandTotalPaise = (grandTotal * 100).round();
    int allocatedPaise = 0;

    final List<SplitAllocation> allocations = [];
    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final subtotal = memberSubtotals[m.id] ?? 0.0;
      final proportion = rawItemsTotal > 0 ? (subtotal / rawItemsTotal) : (1.0 / members.length);
      final memberTaxTip = effectiveTaxTip * proportion;
      final fullShare = subtotal + memberTaxTip;

      int memberPaise;
      if (i == members.length - 1) {
        memberPaise = grandTotalPaise - allocatedPaise;
      } else {
        memberPaise = (fullShare * 100).round();
        allocatedPaise += memberPaise;
      }

      final finalAmount = memberPaise / 100.0;
      final pct = grandTotal > 0 ? (finalAmount / grandTotal) * 100.0 : 0.0;

      allocations.add(
        SplitAllocation(
          memberId: m.id,
          memberName: m.name,
          amount: finalAmount,
          percentage: double.parse(pct.toStringAsFixed(2)),
          items: memberItemNames[m.id] ?? [],
        ),
      );
    }

    return allocations;
  }

  // ===========================================================================
  // 4. "WHO OWES WHOM" & NET BALANCES ENGINE (BR-18)
  // ===========================================================================
  Map<String, double> calculateNetBalances(SplitGroup group) {
    final Map<String, double> netBalances = {for (var m in group.members) m.id: 0.0};

    for (final expense in group.expenses) {
      netBalances[expense.paidByMemberId] =
          (netBalances[expense.paidByMemberId] ?? 0.0) + expense.totalAmount;

      for (final allocation in expense.allocations) {
        netBalances[allocation.memberId] =
            (netBalances[allocation.memberId] ?? 0.0) - allocation.amount;
      }
    }

    return netBalances;
  }

  // ===========================================================================
  // 5. DEBT SIMPLIFICATION ALGORITHM (Reduces NxN debts to minimum transfers)
  // ===========================================================================
  List<DebtRelation> getSimplifiedDebts(String groupId) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return [];
    return calculateSimplifiedDebts(_groups[index]);
  }

  List<DebtRelation> calculateSimplifiedDebts(SplitGroup group) {
    final netBalances = calculateNetBalances(group);
    final memberMap = {for (var m in group.members) m.id: m};

    final List<_BalanceNode> debtors = [];
    final List<_BalanceNode> creditors = [];

    netBalances.forEach((memberId, balance) {
      final rounded = double.parse(balance.toStringAsFixed(2));
      if (rounded < -0.05) {
        debtors.add(_BalanceNode(memberId, rounded.abs()));
      } else if (rounded > 0.05) {
        creditors.add(_BalanceNode(memberId, rounded));
      }
    });

    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final List<DebtRelation> simplifiedDebts = [];
    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final settleAmount = debtor.amount < creditor.amount ? debtor.amount : creditor.amount;
      final roundedAmount = double.parse(settleAmount.toStringAsFixed(2));

      if (roundedAmount > 0.05) {
        final debtKey = '${group.id}_${debtor.id}_${creditor.id}';
        final isSettled = _settledDebtIds.contains(debtKey);

        if (!isSettled) {
          simplifiedDebts.add(
            DebtRelation(
              id: debtKey,
              fromMemberId: debtor.id,
              fromMemberName: memberMap[debtor.id]?.name ?? 'Unknown',
              toMemberId: creditor.id,
              toMemberName: memberMap[creditor.id]?.name ?? 'Unknown',
              amount: roundedAmount,
              isSettled: false,
            ),
          );
        }
      }

      debtor.amount -= settleAmount;
      creditor.amount -= settleAmount;

      if (debtor.amount < 0.05) dIdx++;
      if (creditor.amount < 0.05) cIdx++;
    }

    return simplifiedDebts;
  }

  // ===========================================================================
  // 6. NON-MONETARY SETTLEMENT LOGIC (BR-19: No money transfer occurs)
  // ===========================================================================
  Future<void> markSettlementComplete(
    dynamic debtOrKey, {
    String note = 'Settled via external UPI/Cash',
  }) async {
    final debtKey = debtOrKey is DebtRelation ? debtOrKey.id : debtOrKey.toString();
    _settledDebtIds.add(debtKey);
    await _save();
    notifyListeners();
  }

  Future<void> revertSettlement({required String debtKey}) async {
    _settledDebtIds.remove(debtKey);
    await _save();
    notifyListeners();
  }

  // ===========================================================================
  // 7. GENTLE REMINDER NOTIFICATION LOGIC (BR-19)
  // ===========================================================================
  String generateReminderCopy({
    required String debtorName,
    required double amount,
    required String groupName,
  }) {
    final formattedAmount = '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
    return 'Hey $debtorName! 👋 FinTrack gentle nudge for your "$groupName" share of $formattedAmount. You can settle whenever convenient via external UPI/Cash!';
  }

  String generateReminderMessage({
    required String groupTitle,
    required String debtorName,
    required String creditorName,
    required double amount,
  }) {
    return generateReminderCopy(debtorName: debtorName, amount: amount, groupName: groupTitle);
  }

  // ===========================================================================
  // 8. GROUP CREATION & EXPENSE OPERATIONS (BR-16 & BR-17)
  // ===========================================================================
  SplitGroup createGroup({
    String? title,
    String? name,
    required String icon,
    required List<GroupMember> members,
  }) {
    final groupTitle = title ?? name ?? 'New Group';
    final hasCurrentUser = members.any((m) => m.isCurrentUser || m.isSelf);
    final finalMembers = hasCurrentUser ? members : [currentUser, ...members];

    final newGroup = SplitGroup(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      title: groupTitle.trim(),
      icon: icon.trim().isEmpty ? '👥' : icon.trim(),
      members: finalMembers,
      expenses: [],
      createdAt: DateTime.now(),
    );

    _groups.add(newGroup);
    _save();
    notifyListeners();
    return newGroup;
  }

  GroupExpense addExpense({
    required String groupId,
    required String title,
    required double totalAmount,
    required String paidById,
    required SplitType splitType,
    required List<SplitAllocation> allocations,
    String? category,
    String? notes,
    List<ItemizedEntry>? itemizedEntries,
  }) {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) {
      throw StateError('Group not found');
    }

    final group = _groups[index];
    final paidMember = group.members.firstWhere(
      (m) => m.id == paidById,
      orElse: () => group.members.first,
    );

    final expense = GroupExpense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      title: title.trim(),
      totalAmount: totalAmount,
      paidByMemberId: paidMember.id,
      paidByMemberName: paidMember.isCurrentUser ? '${paidMember.name} (You)' : paidMember.name,
      splitType: splitType,
      allocations: allocations,
      createdAt: DateTime.now(),
      category: category ?? 'Food & Dining',
      notes: notes,
      itemizedEntries: itemizedEntries,
    );

    final updatedExpenses = [...group.expenses, expense];
    _groups[index] = group.copyWith(expenses: updatedExpenses);
    _save();
    notifyListeners();
    return expense;
  }

  // ===========================================================================
  // 9. OVERALL USER LEDGER BALANCE ACROSS ALL CIRCLES
  // ===========================================================================
  UserNetPosition getOverallUserPosition() {
    double totalYouAreOwed = 0.0;
    double totalYouOwe = 0.0;
    final currentUserId = currentUser.id;

    for (final group in _groups) {
      final debts = calculateSimplifiedDebts(group);
      for (final debt in debts) {
        if (debt.isSettled) continue;
        if (debt.toMemberId == currentUserId) {
          totalYouAreOwed += debt.amount;
        } else if (debt.fromMemberId == currentUserId) {
          totalYouOwe += debt.amount;
        }
      }
    }

    return UserNetPosition(
      netBalance: totalYouAreOwed - totalYouOwe,
      totalOwedToYou: totalYouAreOwed,
      totalYouOwe: totalYouOwe,
    );
  }
}

class _BalanceNode {
  final String id;
  double amount;
  _BalanceNode(this.id, this.amount);
}
