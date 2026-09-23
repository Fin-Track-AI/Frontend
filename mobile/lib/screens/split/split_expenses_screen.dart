import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../../services/split_service.dart';
import '../../models/split_models.dart';
import 'create_group_modal.dart';
import 'add_split_expense_modal.dart';
import 'gentle_reminder_modal.dart';

class SplitExpensesScreen extends StatefulWidget {
  const SplitExpensesScreen({super.key});

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
  int _selectedGroupIndex = 0;
  final SplitService _splitService = SplitService();

  @override
  void initState() {
    super.initState();
    _splitService.init();
  }

  void _openCreateGroup() async {
    final created = await CreateGroupModal.show(context);
    if (created != null && mounted) {
      setState(() {
        _selectedGroupIndex = _splitService.groups.length - 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Group "${created.name}" created! Invitations sent.'),
            ],
          ),
        ),
      );
    }
  }

  void _openAddExpense(SplitGroup group) async {
    final expense = await AddSplitExpenseModal.show(context, group: group);
    if (expense != null && mounted) {
      await _splitService.syncFromBackend();
      if (mounted) setState(() {});
    }
  }

  void _openGentleReminder(DebtRelation debt, SplitGroup group) {
    GentleReminderModal.show(context, debt: debt, groupName: group.name, groupId: group.id);
  }

  void _markDebtSettled(DebtRelation debt, {String? groupId}) async {
    await _splitService.markSettlementComplete(debt, groupId: groupId);
    await _splitService.syncFromBackend();
    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Settlement recorded: ₹${debt.amount.toStringAsFixed(0)} between ${debt.fromMemberName} & ${debt.toMemberName} (External UPI/Cash)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _revertDebtSettlement(DebtRelation debt, {String? groupId}) async {
    await _splitService.revertSettlement(debtKey: debt.id, groupId: groupId);
    await _splitService.syncFromBackend();
    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Row(
          children: [
            const Icon(Icons.undo, color: AppColors.blue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Settlement reverted: ₹${debt.amount.toStringAsFixed(0)} between ${debt.fromMemberName} & ${debt.toMemberName}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteGroup(SplitGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Group?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? All shared expenses and balance records for this circle will be permanently removed.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final name = group.name;
      await _splitService.deleteGroup(group.id);
      if (mounted) {
        setState(() {
          if (_selectedGroupIndex > 0) {
            _selectedGroupIndex--;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.textPrimary,
            content: Text('Group "$name" deleted.'),
          ),
        );
      }
    }
  }

  void _acceptInvitation(SplitGroup group) async {
    await _splitService.respondToInvitation(group.id, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          content: Text('Joined "${group.name}"!'),
        ),
      );
    }
  }

  void _declineInvitation(SplitGroup group) async {
    await _splitService.respondToInvitation(group.id, false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.textPrimary,
          content: Text('Declined invitation to "${group.name}".'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _splitService,
      builder: (context, _) {
        final groups = _splitService.groups;
        final pendingInvites = _splitService.pendingInvitations;
        final hasGroups = groups.isNotEmpty;

        if (_selectedGroupIndex >= groups.length) {
          _selectedGroupIndex = groups.isNotEmpty ? groups.length - 1 : 0;
        }

        final selectedGroup = hasGroups ? groups[_selectedGroupIndex] : null;
        final debts = selectedGroup != null ? _splitService.getSimplifiedDebts(selectedGroup.id) : <DebtRelation>[];
        final settledDebts = selectedGroup != null ? _splitService.getSettledDebts(selectedGroup.id) : <DebtRelation>[];
        final currentUserId = _splitService.currentUser.id;
        final myMemberIds = <String>{currentUserId};
        if (selectedGroup != null) {
          for (final m in selectedGroup.members) {
            if (m.isSelf) {
              myMemberIds.add(m.id);
            }
          }
        }

        // User relevant debts in current group
        final userDebts = debts.where((d) => myMemberIds.contains(d.fromMemberId) || myMemberIds.contains(d.toMemberId)).toList();
        final userSettledDebts = settledDebts.where((d) => myMemberIds.contains(d.fromMemberId) || myMemberIds.contains(d.toMemberId)).toList();

        // Overall Net Position across all groups
        final netPosition = _splitService.getOverallUserPosition();
        final netFormatted = '${netPosition.netBalance >= 0 ? '+' : '-'}₹${netPosition.netBalance.abs().toStringAsFixed(0)}';
        final netColor = netPosition.netBalance >= 0 ? AppColors.green : AppColors.red;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const FinTrackHeader(),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _splitService.syncFromBackend(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                children: [
                // Header Tag: SOCIAL LEDGER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.hub_outlined, color: AppColors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'SOCIAL LEDGER',
                            style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Split with Friends',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Track who owes what without awkward money talks.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),

                // Net Balance Position Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('NET BALANCE POSITION', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: AppColors.green, size: 12),
                                SizedBox(width: 4),
                                Text('Balanced Ledgers', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            hasGroups ? netFormatted : '₹0',
                            style: TextStyle(color: hasGroups ? netColor : AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !hasGroups
                                ? 'all settled up'
                                : (netPosition.netBalance >= 0 ? 'net to receive' : 'net to pay'),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('You are owed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('+₹${netPosition.totalOwedToYou.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.green, fontSize: 16, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: AppColors.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('You owe', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text('-₹${netPosition.totalYouOwe.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Pending Group Invitations Banner (if any)
                if (pendingInvites.isNotEmpty) ...[
                  ...pendingInvites.map((inviteGroup) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE0FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(inviteGroup.icon, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          inviteGroup.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('INVITATION', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${inviteGroup.members.length} members sharing shared expenses',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                onPressed: () => _declineInvitation(inviteGroup),
                                child: const Text('Decline', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                ),
                                onPressed: () => _acceptInvitation(inviteGroup),
                                child: const Text('Accept & Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Active Circles Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ACTIVE CIRCLES', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    GestureDetector(
                      onTap: _openCreateGroup,
                      child: Row(
                        children: const [
                          Icon(Icons.add_circle_outline, color: AppColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text('New Group', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!hasGroups) ...[
                  // Empty State Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group_add_outlined, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Split Groups Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a circle to split expenses for weekend trips, flat rent, dining out, or team events.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Your First Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                            onPressed: _openCreateGroup,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Active Circles Horizontal Scroll
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(groups.length, (idx) {
                        final c = groups[idx];
                        final isSelected = _selectedGroupIndex == idx;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGroupIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F172A) : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? const Color(0xFF0F172A) : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Text(c.icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.members.length} members • ₹${c.totalSpend.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF94A3B8) : AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Group Details
                  if (selectedGroup != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(selectedGroup.icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedGroup.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 2),
                                      Text('Total group spend: ₹${selectedGroup.totalSpend.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
                                    tooltip: 'Delete Group',
                                    onPressed: () => _deleteGroup(selectedGroup),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                    onPressed: () => _openAddExpense(selectedGroup),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text('${selectedGroup.members.length} FRIENDS SHARING', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: selectedGroup.members.map((m) {
                                final isPending = m.isPendingInvite;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: Column(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: m.isSelf ? AppColors.green : (isPending ? AppColors.surfaceMuted : AppColors.primary),
                                            child: Text(
                                              m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: isPending ? AppColors.textSecondary : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (m.isSelf)
                                            Positioned(
                                              bottom: -4,
                                              left: 4,
                                              right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                                child: const Center(
                                                  child: Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        m.name.split(' ').first,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      if (isPending) ...[
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.blue.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Invited', style: TextStyle(color: AppColors.blue, fontSize: 8, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // YOUR SIMPLIFIED NET BALANCES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('YOUR SIMPLIFIED NET BALANCES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        Text(
                          '${debts.length} transfers needed',
                          style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (userDebts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle, color: AppColors.green, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All settled up! You have no outstanding balances in this group.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...userDebts.map((debt) {
                        final isIncoming = myMemberIds.contains(debt.toMemberId);
                        final otherPartyName = isIncoming ? debt.fromMemberName : debt.toMemberName;
                        final title = isIncoming ? '$otherPartyName owes you' : 'You owe $otherPartyName';
                        final amountFormatted = '${isIncoming ? '+' : '-'}₹${debt.amount.toStringAsFixed(0)}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildSimplifiedBalanceCard(
                            isIncoming: isIncoming,
                            title: title,
                            subtitle: 'External UPI / Cash Settlement',
                            amount: amountFormatted,
                            hasRemind: isIncoming,
                            onSettle: () => _markDebtSettled(debt, groupId: selectedGroup.id),
                            onRemind: () => _openGentleReminder(debt, selectedGroup),
                          ),
                        );
                      }),

                    if (userSettledDebts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SETTLED BALANCES', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          Text('${userSettledDebts.length} settled', style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...userSettledDebts.map((debt) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '₹${debt.amount.toStringAsFixed(0)} settled between ${debt.fromMemberName} & ${debt.toMemberName}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _revertDebtSettlement(debt, groupId: selectedGroup.id),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Undo', style: TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 22),

                    // RECENT GROUP EXPENSES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RECENT GROUP EXPENSES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        Text('${selectedGroup.expenses.length} entries', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (selectedGroup.expenses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('No expenses recorded yet in this group', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      )
                    else
                      ...selectedGroup.expenses.reversed.map((exp) {
                        final isPayer = myMemberIds.contains(exp.paidByMemberId);
                        final userAlloc = exp.allocations.where((a) => myMemberIds.contains(a.memberId)).firstOrNull;

                        String shareText;
                        bool isPositiveShare = false;
                        if (isPayer) {
                          final othersShare = exp.totalAmount - (userAlloc?.shareAmount ?? 0);
                          shareText = 'You get back ₹${othersShare.toStringAsFixed(0)}';
                          isPositiveShare = true;
                        } else if (userAlloc != null) {
                          shareText = 'Your share: ₹${userAlloc.shareAmount.toStringAsFixed(0)}';
                        } else {
                          shareText = 'Not involved';
                        }

                        IconData categoryIcon = Icons.receipt_long_rounded;
                        if (exp.category == 'Food & Dining') categoryIcon = Icons.restaurant_rounded;
                        if (exp.category == 'Travel & Commute') categoryIcon = Icons.two_wheeler_rounded;
                        if (exp.category == 'Entertainment') categoryIcon = Icons.movie_filter_rounded;

                        return _buildGroupExpenseRow(
                          icon: categoryIcon,
                          title: exp.title,
                          subtitle: 'Paid by ${isPayer ? 'You' : exp.paidByName} • Split ${exp.splitType.name}',
                          total: '₹${exp.totalAmount.toStringAsFixed(0)}',
                          share: shareText,
                          isPositiveShare: isPositiveShare,
                        );
                      }),
                    const SizedBox(height: 16),

                    // Debt Simplification Enabled Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.greenBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.hub_outlined, color: AppColors.green, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Debt Simplification Enabled (BR-18)', style: TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  'FinTrack algorithms simplified multi-party circular debts down to ${debts.length} minimum direct transactions. No more circular transfers!',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const AskAiPill(),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildSimplifiedBalanceCard({
    required bool isIncoming,
    required String title,
    required String subtitle,
    required String amount,
    required bool hasRemind,
    required VoidCallback onSettle,
    required VoidCallback onRemind,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIncoming ? AppColors.greenLight : AppColors.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: isIncoming ? AppColors.green : AppColors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: isIncoming ? AppColors.green : AppColors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasRemind)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Mark Settled', style: TextStyle(fontSize: 11)),
                    onPressed: onSettle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFFFE4E0)),
                      backgroundColor: const Color(0xFFFFF7F5),
                    ),
                    icon: const Icon(Icons.mail_outline, size: 14, color: AppColors.primary),
                    label: const Text('Gentle Reminder', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: onRemind,
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 14),
              label: const Text('Mark as Settled (External UPI/Cash)', style: TextStyle(fontSize: 11)),
              onPressed: onSettle,
            ),
        ],
      ),
    );
  }

  Widget _buildGroupExpenseRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String total,
    required String share,
    bool isPositiveShare = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(total, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                share,
                style: TextStyle(
                  color: isPositiveShare ? AppColors.green : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
