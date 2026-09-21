import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  GroupMember get currentUser {
    final currentUserName = SessionService().userName.isNotEmpty
        ? SessionService().userName.split(' ').first
        : 'Ritesh';
    return GroupMember(
      id: 'usr_me',
      name: currentUserName,
      isCurrentUser: true,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      phone: '+91 98765 43210',
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
        _groups = decoded.map((g) => SplitGroup.fromJson(g as Map<String, dynamic>)).toList();
      } else {
        _seedInitialData();
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading split groups: $e');
      _seedInitialData();
    }
    notifyListeners();
  }

  void _seedInitialData() {
    final me = currentUser;
    final ameya = const GroupMember(
      id: 'usr_ameya',
      name: 'Ameya',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
      phone: '+91 98220 12345',
    );
    final atharva = const GroupMember(
      id: 'usr_atharva',
      name: 'Atharva',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80',
      phone: '+91 98330 23456',
    );
    final sneha = const GroupMember(
      id: 'usr_sneha',
      name: 'Sneha',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80',
      phone: '+91 98440 34567',
    );
    final rohan = const GroupMember(
      id: 'usr_rohan',
      name: 'Rohan',
      avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop&q=80',
      phone: '+91 98550 45678',
    );

    final goaMembers = [me, ameya, atharva, sneha, rohan];

    final dinnerAllocations = calculateEqualSplit(
      totalAmount: 3000.0,
      members: goaMembers,
    );
    final scooterAllocations = calculateEqualSplit(
      totalAmount: 2500.0,
      members: goaMembers,
    );
    final beachAllocations = calculateEqualSplit(
      totalAmount: 1200.0,
      members: [me, ameya, atharva, rohan],
    );

    final goaExpenses = [
      GroupExpense(
        id: 'exp_01',
        groupId: 'grp_goa',
        title: "Dinner at Fisherman's Wharf",
        totalAmount: 3000.0,
        paidByMemberId: me.id,
        paidByMemberName: '${me.name} (You)',
        splitType: SplitType.equal,
        allocations: dinnerAllocations,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Food & Dining',
      ),
      GroupExpense(
        id: 'exp_02',
        groupId: 'grp_goa',
        title: 'Scooter Rental (3 days)',
        totalAmount: 2500.0,
        paidByMemberId: rohan.id,
        paidByMemberName: rohan.name,
        splitType: SplitType.equal,
        allocations: scooterAllocations,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        category: 'Travel & Commute',
      ),
      GroupExpense(
        id: 'exp_03',
        groupId: 'grp_goa',
        title: 'Beach Shack Snacks',
        totalAmount: 1200.0,
        paidByMemberId: ameya.id,
        paidByMemberName: ameya.name,
        splitType: SplitType.equal,
        allocations: beachAllocations,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Food & Dining',
      ),
    ];

    final flatmates = [me, atharva, rohan];
    final rentExpense = GroupExpense(
      id: 'exp_flat_01',
      groupId: 'grp_flat',
      title: 'High-speed Fiber & Maintenance',
      totalAmount: 22000.0,
      paidByMemberId: atharva.id,
      paidByMemberName: atharva.name,
      splitType: SplitType.equal,
      allocations: calculateEqualSplit(totalAmount: 22000.0, members: flatmates),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Rent & Utilities',
    );

    final lunchMembers = [me, ameya, atharva, sneha];
    final lunchExpense = GroupExpense(
      id: 'exp_lunch_01',
      groupId: 'grp_lunch',
      title: 'Team Bento Box Lunch',
      totalAmount: 3200.0,
      paidByMemberId: me.id,
      paidByMemberName: '${me.name} (You)',
      splitType: SplitType.equal,
      allocations: calculateEqualSplit(totalAmount: 3200.0, members: lunchMembers),
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      category: 'Food & Dining',
    );

    _groups = [
      SplitGroup(
        id: 'grp_goa',
        title: 'Goa Trip 2026',
        icon: '🏖️',
        members: goaMembers,
        expenses: goaExpenses,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      SplitGroup(
        id: 'grp_flat',
        title: 'Flatmates (HSR)',
        icon: '🏡',
        members: flatmates,
        expenses: [rentExpense],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      SplitGroup(
        id: 'grp_lunch',
        title: 'Office Lunch',
        icon: '🍱',
        members: lunchMembers,
        expenses: [lunchExpense],
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ];
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
