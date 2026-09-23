import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fintrack_mobile/models/split_models.dart';
import 'package:fintrack_mobile/services/split_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SplitService service;
  final memberA = const GroupMember(id: 'u_1', name: 'Ritesh', isCurrentUser: true);
  final memberB = const GroupMember(id: 'u_2', name: 'Ameya');
  final memberC = const GroupMember(id: 'u_3', name: 'Aarav');
  final memberD = const GroupMember(id: 'u_4', name: 'Sneha');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SplitService();
  });

  group('BR-16: Group Creation and Member Management', () {
    test('User can create a group with 3+ members and custom icon', () {
      final group = service.createGroup(
        name: 'Weekend Trek',
        icon: '🏕️',
        members: [memberA, memberB, memberC, memberD],
      );

      expect(group.name, 'Weekend Trek');
      expect(group.icon, '🏕️');
      expect(group.members.length, 4);
      expect(service.groups.any((g) => g.id == group.id), isTrue);
    });
  });

  group('BR-17: All 3 Split Methods Reconcile to Exactly 100%', () {
    test('Equal split with 3 members reconciles to 100% of expense with zero discrepancy', () {
      const totalAmount = 100.0;
      final allocations = service.calculateEqualSplit(
        totalAmount: totalAmount,
        includedMembers: [memberA, memberB, memberC],
      );

      expect(allocations.length, 3);
      final sum = allocations.fold<double>(0.0, (acc, a) => acc + a.shareAmount);
      // Remainder cent must be absorbed: 33.34 + 33.33 + 33.33 = 100.00
      expect(sum, closeTo(totalAmount, 0.0001));
      expect(allocations[0].shareAmount, 33.34);
      expect(allocations[1].shareAmount, 33.33);
      expect(allocations[2].shareAmount, 33.33);
    });

    test('Equal split with 5 members reconciles cleanly', () {
      const totalAmount = 34200.0;
      final allocations = service.calculateEqualSplit(
        totalAmount: totalAmount,
        includedMembers: [memberA, memberB, memberC, memberD, GroupMember(id: 'u_5', name: 'Rohan')],
      );

      final sum = allocations.fold<double>(0.0, (acc, a) => acc + a.shareAmount);
      expect(sum, closeTo(totalAmount, 0.0001));
      expect(allocations[0].shareAmount, 6840.0);
    });

    test('Percentage split reconciles to 100% of original expense', () {
      const totalAmount = 2500.0;
      final percentages = {
        memberA.id: 50.0,
        memberB.id: 25.0,
        memberC.id: 25.0,
      };

      final allocations = service.calculatePercentageSplit(
        totalAmount: totalAmount,
        members: [memberA, memberB, memberC],
        percentages: percentages,
      );

      final sum = allocations.fold<double>(0.0, (acc, a) => acc + a.shareAmount);
      expect(sum, closeTo(totalAmount, 0.0001));
      expect(allocations.firstWhere((a) => a.memberId == memberA.id).shareAmount, 1250.0);
      expect(allocations.firstWhere((a) => a.memberId == memberB.id).shareAmount, 625.0);
      expect(allocations.firstWhere((a) => a.memberId == memberC.id).shareAmount, 625.0);
    });

    test('Percentage split with recurring decimals (33.33% each) reconciles to exact total', () {
      const totalAmount = 1000.0;
      final percentages = {
        memberA.id: 33.34,
        memberB.id: 33.33,
        memberC.id: 33.33,
      };

      final allocations = service.calculatePercentageSplit(
        totalAmount: totalAmount,
        members: [memberA, memberB, memberC],
        percentages: percentages,
      );

      final sum = allocations.fold<double>(0.0, (acc, a) => acc + a.shareAmount);
      expect(sum, closeTo(totalAmount, 0.0001));
    });

    test('Itemized split correctly apportions item prices and shared tax/tip to 100%', () {
      final List<ItemizedEntry> items = [
        ItemizedEntry(id: 'i1', name: 'Pizza', price: 600.0, assignedMemberIds: [memberA.id, memberB.id]), // 300 ea
        ItemizedEntry(id: 'i2', name: 'Garlic Bread', price: 200.0, assignedMemberIds: [memberB.id]), // 200 to B
        ItemizedEntry(id: 'i3', name: 'Drinks', price: 200.0, assignedMemberIds: [memberA.id, memberB.id, memberC.id]), // ~66.67 ea
      ];
      const taxAndTip = 100.0;
      const totalAmount = 1100.0; // 600 + 200 + 200 + 100

      final allocations = service.calculateItemizedSplit(
        totalAmount: totalAmount,
        members: [memberA, memberB, memberC],
        items: items,
        taxAndTipAmount: taxAndTip,
      );

      final sum = allocations.fold<double>(0.0, (acc, a) => acc + a.shareAmount);
      expect(sum, closeTo(totalAmount, 0.0001));
    });
  });

  group('BR-18: Debt Simplification Algorithm', () {
    test('Simplifies circular debts (A owes B, B owes C -> A owes C)', () {
      final group = service.createGroup(
        name: 'Test Simplification',
        icon: '⚡',
        members: [memberA, memberB, memberC],
      );

      service.addExpense(
        groupId: group.id,
        title: 'Dinner',
        totalAmount: 300.0,
        paidById: memberB.id,
        splitType: SplitType.equal,
        allocations: [
          SplitAllocation(memberId: memberA.id, memberName: memberA.name, amount: 100.0),
          SplitAllocation(memberId: memberB.id, memberName: memberB.name, amount: 100.0),
          SplitAllocation(memberId: memberC.id, memberName: memberC.name, amount: 100.0),
        ],
      );

      service.addExpense(
        groupId: group.id,
        title: 'Cab',
        totalAmount: 300.0,
        paidById: memberC.id,
        splitType: SplitType.equal,
        allocations: [
          SplitAllocation(memberId: memberA.id, memberName: memberA.name, amount: 100.0),
          SplitAllocation(memberId: memberB.id, memberName: memberB.name, amount: 100.0),
          SplitAllocation(memberId: memberC.id, memberName: memberC.name, amount: 100.0),
        ],
      );

      final debts = service.getSimplifiedDebts(group.id);
      expect(debts.length, 2);
      expect(debts.every((d) => d.fromMemberId == memberA.id), isTrue);
      final totalSettledAmt = debts.fold<double>(0.0, (acc, d) => acc + d.amount);
      expect(totalSettledAmt, closeTo(200.0, 0.001));
    });
  });

  group('BR-19: Non-Monetary Settlement & Reminders', () {
    test('Marking debt settled removes debt without money transfer', () async {
      final group = service.createGroup(
        name: 'Settlement Test',
        icon: '🤝',
        members: [memberA, memberB],
      );

      service.addExpense(
        groupId: group.id,
        title: 'Lunch',
        totalAmount: 200.0,
        paidById: memberA.id,
        splitType: SplitType.equal,
        allocations: [
          SplitAllocation(memberId: memberA.id, memberName: memberA.name, amount: 100.0),
          SplitAllocation(memberId: memberB.id, memberName: memberB.name, amount: 100.0),
        ],
      );

      var debts = service.getSimplifiedDebts(group.id);
      expect(debts.length, 1);
      expect(debts.first.fromMemberId, memberB.id);
      expect(debts.first.amount, 100.0);

      // Mark settled externally
      await service.markSettlementComplete(debts.first);

      final updatedDebts = service.getSimplifiedDebts(group.id);
      expect(updatedDebts.isEmpty, isTrue);
    });

    test('Generates pre-composed gentle reminder copy', () {
      final copy = service.generateReminderCopy(
        debtorName: 'Ameya',
        amount: 750.0,
        groupName: 'Goa Trip 2026',
      );

      expect(copy.contains('Ameya'), isTrue);
      expect(copy.contains('750'), isTrue);
      expect(copy.contains('Goa Trip 2026'), isTrue);
      expect(copy.contains('FinTrack'), isTrue);
    });
  });

  group('Group Deletion and Invitations', () {
    test('User can delete a group from SplitService', () async {
      final group = service.createGroup(
        name: 'Temporary Trip',
        icon: '🚗',
        members: [memberA, memberB],
      );

      expect(service.groups.any((g) => g.id == group.id), isTrue);

      await service.deleteGroup(group.id);

      expect(service.groups.any((g) => g.id == group.id), isFalse);
    });

    test('Initializes with empty groups when no data exists (no demo seeding)', () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = SplitService();
      await fresh.initialize();
      expect(fresh.groups.isEmpty, isTrue);
    });

    test('Member invitation status is preserved and can be accepted', () async {
      final invitedMember = memberB.copyWith(status: 'PENDING_INVITE');
      final group = service.createGroup(
        name: 'Invite Test',
        icon: '🏖️',
        members: [memberA, invitedMember],
      );

      final addedMember = group.members.firstWhere((m) => m.id == memberB.id);
      expect(addedMember.isPendingInvite, isTrue);
    });
  });
}
