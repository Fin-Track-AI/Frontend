import '../services/session_service.dart';

enum SplitType {
  equal,
  itemized,
  percentage,
}

class GroupMember {
  final String id;
  final String name;
  final String avatarUrl;
  final String phone;
  final String status;

  const GroupMember({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    bool isCurrentUser = false,
    this.phone = '',
    this.status = 'ACCEPTED',
    String? phoneNumber,
    bool? isSelf,
  }) : _rawPhone = phoneNumber ?? phone,
       _rawIsSelf = isSelf ?? isCurrentUser;

  final String _rawPhone;
  final bool _rawIsSelf;

  bool get isSelf {
    final session = SessionService();
    final currentUserId = session.userId;
    final currentUserPhone = session.userPhone.replaceAll(RegExp(r'\D'), '');
    final last10 = currentUserPhone.length >= 10
        ? currentUserPhone.substring(currentUserPhone.length - 10)
        : currentUserPhone;

    // If an active session exists, dynamically detect self by ID or phone
    if (session.isLoggedIn || currentUserId.isNotEmpty || last10.isNotEmpty) {
      if (currentUserId.isNotEmpty && currentUserId != 'usr_me' && id == currentUserId) {
        return true;
      }
      if (last10.isNotEmpty) {
        final mDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
        if (mDigits.isNotEmpty && mDigits.endsWith(last10)) {
          return true;
        }
      }
      return false;
    }

    return _rawIsSelf;
  }

  bool get isCurrentUser => isSelf;
  String get phoneNumber => _rawPhone;
  bool get isPendingInvite => status == 'PENDING_INVITE';

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'isCurrentUser': isCurrentUser,
        'phone': phone,
        'status': status,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: (json['id'] ?? json['memberId'] ?? '').toString(),
        name: (json['name'] ?? 'Member') as String,
        avatarUrl: (json['avatarUrl'] as String?) ?? '',
        isCurrentUser: (json['isCurrentUser'] as bool?) ?? false,
        phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
        status: (json['status'] as String?) ?? 'ACCEPTED',
      );

  GroupMember copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isCurrentUser,
    String? phone,
    String? status,
  }) {
    return GroupMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }
}

class SplitAllocation {
  final String memberId;
  final String memberName;
  final double amount;
  final double percentage;
  final List<String> items;

  const SplitAllocation({
    required this.memberId,
    required this.memberName,
    double? amount,
    double? shareAmount,
    this.percentage = 0.0,
    this.items = const [],
  }) : amount = amount ?? shareAmount ?? 0.0;

  double get shareAmount => amount;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'amount': amount,
        'percentage': percentage,
        'items': items,
      };

  factory SplitAllocation.fromJson(Map<String, dynamic> json) => SplitAllocation(
        memberId: (json['memberId'] ?? '').toString(),
        memberName: (json['memberName'] ?? '').toString(),
        amount: ((json['amount'] ?? json['shareAmount'] ?? 0.0) as num).toDouble(),
        percentage: ((json['percentage'] ?? 0.0) as num).toDouble(),
        items: (json['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class ItemizedEntry {
  final String id;
  final String itemName;
  final double price;
  final List<String> assignedMemberIds;

  const ItemizedEntry({
    required this.id,
    String? itemName,
    String? name,
    required this.price,
    required this.assignedMemberIds,
  }) : itemName = itemName ?? name ?? '';

  String get name => itemName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'price': price,
        'assignedMemberIds': assignedMemberIds,
      };

  factory ItemizedEntry.fromJson(Map<String, dynamic> json) => ItemizedEntry(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        itemName: (json['itemName'] ?? json['name'] ?? '').toString(),
        price: ((json['price'] ?? 0.0) as num).toDouble(),
        assignedMemberIds: (json['assignedMemberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class GroupExpense {
  final String id;
  final String groupId;
  final String title;
  final double totalAmount;
  final String paidByMemberId;
  final String paidByMemberName;
  final SplitType splitType;
  final List<SplitAllocation> allocations;
  final DateTime createdAt;
  final String? category;
  final String? notes;
  final List<ItemizedEntry>? itemizedEntries;

  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidByMemberId,
    required this.paidByMemberName,
    required this.splitType,
    required this.allocations,
    required this.createdAt,
    this.category = 'Food & Dining',
    this.notes,
    this.itemizedEntries,
  });

  String get paidById => paidByMemberId;
  String get paidByName => paidByMemberName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'totalAmount': totalAmount,
        'paidByMemberId': paidByMemberId,
        'paidByMemberName': paidByMemberName,
        'splitType': splitType.name,
        'allocations': allocations.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'notes': notes,
        'itemizedEntries': itemizedEntries?.map((e) => e.toJson()).toList(),
      };

  factory GroupExpense.fromJson(Map<String, dynamic> json) => GroupExpense(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        groupId: (json['groupId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        totalAmount: ((json['totalAmount'] ?? 0.0) as num).toDouble(),
        paidByMemberId: (json['paidByMemberId'] ?? '').toString(),
        paidByMemberName: (json['paidByMemberName'] ?? '').toString(),
        splitType: SplitType.values.firstWhere(
          (t) => t.name.toLowerCase() == (json['splitType'] ?? 'equal').toString().toLowerCase(),
          orElse: () => SplitType.equal,
        ),
        allocations: (json['allocations'] as List<dynamic>?)
                ?.map((a) => SplitAllocation.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
            : DateTime.now(),
        category: json['category'] as String?,
        notes: json['notes'] as String?,
        itemizedEntries: (json['itemizedEntries'] as List<dynamic>?)
            ?.map((e) => ItemizedEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DebtRelation {
  final String id;
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;
  final bool isSettled;
  final String? settlementNote;
  final DateTime? settledAt;

  const DebtRelation({
    required this.id,
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
    this.isSettled = false,
    this.settlementNote,
    this.settledAt,
  });

  DebtRelation copyWith({
    String? id,
    String? fromMemberId,
    String? fromMemberName,
    String? toMemberId,
    String? toMemberName,
    double? amount,
    bool? isSettled,
    String? settlementNote,
    DateTime? settledAt,
  }) {
    return DebtRelation(
      id: id ?? this.id,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      fromMemberName: fromMemberName ?? this.fromMemberName,
      toMemberId: toMemberId ?? this.toMemberId,
      toMemberName: toMemberName ?? this.toMemberName,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settlementNote: settlementNote ?? this.settlementNote,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMemberId': fromMemberId,
        'fromMemberName': fromMemberName,
        'toMemberId': toMemberId,
        'toMemberName': toMemberName,
        'amount': amount,
        'isSettled': isSettled,
        'settlementNote': settlementNote,
        'settledAt': settledAt?.toIso8601String(),
      };

  factory DebtRelation.fromJson(Map<String, dynamic> json) => DebtRelation(
        id: json['id'] as String,
        fromMemberId: json['fromMemberId'] as String,
        fromMemberName: json['fromMemberName'] as String,
        toMemberId: json['toMemberId'] as String,
        toMemberName: json['toMemberName'] as String,
        amount: (json['amount'] as num).toDouble(),
        isSettled: (json['isSettled'] as bool?) ?? false,
        settlementNote: json['settlementNote'] as String?,
        settledAt: json['settledAt'] != null ? DateTime.parse(json['settledAt'] as String) : null,
      );
}

class UserNetPosition {
  final double netBalance;
  final double totalOwedToYou;
  final double totalYouOwe;

  const UserNetPosition({
    required this.netBalance,
    required this.totalOwedToYou,
    required this.totalYouOwe,
  });

  double operator [](String key) {
    if (key == 'net') return netBalance;
    if (key == 'youAreOwed') return totalOwedToYou;
    if (key == 'youOwe') return totalYouOwe;
    return 0.0;
  }
}

class SplitGroup {
  final String id;
  final String title;
  final String icon;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;
  final List<String> settledDebtKeys;
  final DateTime createdAt;
  final String createdBy;

  const SplitGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.members,
    required this.expenses,
    this.settledDebtKeys = const [],
    required this.createdAt,
    this.createdBy = '',
    String? name,
  }) : _rawName = name ?? title;

  final String _rawName;
  String get name => _rawName;

  double get totalSpend => expenses.fold(0.0, (sum, e) => sum + e.totalAmount);

  SplitGroup copyWith({
    String? id,
    String? title,
    String? icon,
    List<GroupMember>? members,
    List<GroupExpense>? expenses,
    List<String>? settledDebtKeys,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SplitGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settledDebtKeys: settledDebtKeys ?? this.settledDebtKeys,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'settledDebtKeys': settledDebtKeys,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory SplitGroup.fromJson(Map<String, dynamic> json) => SplitGroup(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        title: (json['title'] ?? json['name'] ?? 'Split Group') as String,
        icon: (json['icon'] as String?) ?? '👥',
        members: (json['members'] as List<dynamic>?)
                ?.map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        expenses: (json['expenses'] as List<dynamic>?)
                ?.map((e) => GroupExpense.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        settledDebtKeys: (json['settledDebtKeys'] as List<dynamic>?)
                ?.map((k) => k.toString())
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdBy: (json['createdBy'] as String?) ?? '',
      );
}
