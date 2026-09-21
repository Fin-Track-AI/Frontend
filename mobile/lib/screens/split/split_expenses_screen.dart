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
              Text('Group "${created.name}" created with ${created.members.length} members!'),
            ],
          ),
        ),
      );
    }
  }

  void _openAddExpense(SplitGroup group) async {
    final expense = await AddSplitExpenseModal.show(context, group: group);
    if (expense != null && mounted) {
      setState(() {});
    }
  }

  void _openGentleReminder(DebtRelation debt, String groupName) {
    GentleReminderModal.show(context, debt: debt, groupName: groupName);
  }

  void _markDebtSettled(DebtRelation debt) async {
    await _splitService.markSettlementComplete(debt);
    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _splitService,
      builder: (context, _) {
        final groups = _splitService.groups;
        if (groups.isEmpty) {
          return const Scaffold(
            appBar: FinTrackHeader(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_selectedGroupIndex >= groups.length) {
          _selectedGroupIndex = 0;
        }

        final selectedGroup = groups[_selectedGroupIndex];
        final debts = _splitService.getSimplifiedDebts(selectedGroup.id);
        final currentUserId = _splitService.currentUser.id;

        // User relevant debts in current group
        final userDebts = debts.where((d) => d.fromMemberId == currentUserId || d.toMemberId == currentUserId).toList();

        // Overall Net Position across all groups
        final netPosition = _splitService.getOverallUserPosition();
        final netFormatted = '${netPosition.netBalance >= 0 ? '+' : '-'}₹${netPosition.netBalance.abs().toStringAsFixed(0)}';
        final netColor = netPosition.netBalance >= 0 ? AppColors.green : AppColors.red;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const FinTrackHeader(),
          body: SafeArea(
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

                // Net Balance Position Card (Dynamic BR-18 / BR-19)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
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
                            netFormatted,
                            style: TextStyle(color: netColor, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            netPosition.netBalance >= 0 ? 'net to receive' : 'net to pay',
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

                // Active Circles Horizontal Scroll (BR-16)
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
                      const SizedBox(height: 16),

                      Text('${selectedGroup.members.length} FRIENDS SHARING', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: selectedGroup.members.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: m.isSelf ? AppColors.green : AppColors.primary,
                                        backgroundImage: m.avatarUrl.isNotEmpty
                                            ? NetworkImage(m.avatarUrl)
                                            : null,
                                        child: m.avatarUrl.isEmpty
                                            ? Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                            : null,
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
                                  Text(m.name.split(' ').first, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
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

                // YOUR SIMPLIFIED NET BALANCES (BR-18)
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
                    final isIncoming = debt.toMemberId == currentUserId;
                    final otherPartyName = isIncoming ? debt.fromMemberName : debt.toMemberName;
                    final title = isIncoming ? '$otherPartyName owes you' : 'You owe $otherPartyName';
                    final amountFormatted = '${isIncoming ? '+' : '-'}₹${debt.amount.toStringAsFixed(0)}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSimplifiedBalanceCard(
                        isIncoming: isIncoming,
                        title: title,
                        subtitle: 'Simplified group balance',
                        amount: amountFormatted,
                        hasRemind: isIncoming,
                        onSettle: () => _markDebtSettled(debt),
                        onRemind: () => _openGentleReminder(debt, selectedGroup.name),
                      ),
                    );
                  }),
                const SizedBox(height: 22),

                // RECENT GROUP EXPENSES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENT GROUP EXPENSES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Text('${selectedGroup.expenses.length} entries', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),

                if (selectedGroup.expenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('No expenses recorded yet in this group', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                  )
                else
                  ...selectedGroup.expenses.reversed.take(6).map((exp) {
                    final isPayer = exp.paidById == currentUserId;
                    final userAlloc = exp.allocations.firstWhere(
                      (a) => a.memberId == currentUserId,
                      orElse: () => SplitAllocation(memberId: '', memberName: '', shareAmount: 0),
                    );

                    String shareText;
                    bool isPositiveShare = false;

                    if (isPayer) {
                      final backAmt = exp.totalAmount - userAlloc.shareAmount;
                      shareText = backAmt > 0 ? '+₹${backAmt.toStringAsFixed(0)} back' : 'Paid in full';
                      isPositiveShare = true;
                    } else if (userAlloc.shareAmount > 0) {
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

                // Debt Simplification Enabled Banner (BR-18)
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

                const AskAiPill(),
              ],
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
