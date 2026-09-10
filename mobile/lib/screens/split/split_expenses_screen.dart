import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../widgets/ask_ai_pill.dart';
import '../transaction/add_transaction_modal.dart';

class SplitExpensesScreen extends StatefulWidget {
  const SplitExpensesScreen({super.key});

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
  int _selectedCircleIndex = 0;

  final List<Map<String, dynamic>> _circles = [
    {'title': 'Goa Trip 2026', 'icon': '🏖️', 'members': 5, 'spend': '₹34,200'},
    {'title': 'Flatmates (HSR)', 'icon': '🏡', 'members': 3, 'spend': '₹22,000'},
    {'title': 'Office Lunch', 'icon': '🍱', 'members': 4, 'spend': '₹3,200'},
  ];

  final List<Map<String, String>> _friends = [
    {'name': 'Ritesh', 'tag': 'YOU', 'img': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80'},
    {'name': 'Ameya', 'tag': '', 'img': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80'},
    {'name': 'Atharva', 'tag': '', 'img': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80'},
    {'name': 'Sneha', 'tag': '', 'img': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80'},
    {'name': 'Rohan', 'tag': '', 'img': 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop&q=80'},
  ];

  @override
  Widget build(BuildContext context) {
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

            // Net Balance Position Card
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
                    children: const [
                      Text(
                        '+₹750',
                        style: TextStyle(color: AppColors.green, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(width: 8),
                      Text('net to receive', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
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
                              children: const [
                                Text('You are owed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                SizedBox(height: 2),
                                Text('+₹1,250', style: TextStyle(color: AppColors.green, fontSize: 16, fontWeight: FontWeight.w800)),
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
                              children: const [
                                Text('You owe', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                SizedBox(height: 2),
                                Text('-₹500', style: TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.w800)),
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Create new group flow')),
                    );
                  },
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

            // Active Circles Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_circles.length, (idx) {
                  final c = _circles[idx];
                  final isSelected = _selectedCircleIndex == idx;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCircleIndex = idx),
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
                          Text(c['icon'] as String, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['title'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c['members']} members • ${c['spend']}',
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

            // Selected Group Details (Goa Trip 2026)
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
                          const Text('🏖️', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Goa Trip 2026', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                              SizedBox(height: 2),
                              Text('Total group spend: ₹34,200', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
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
                        onPressed: () => AddTransactionModal.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('5 FRIENDS TRAVELING', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _friends.map((f) {
                      final hasTag = (f['tag'] ?? '').isNotEmpty;
                      return Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.border,
                                backgroundImage: NetworkImage(f['img']!),
                              ),
                              if (hasTag)
                                Positioned(
                                  bottom: -4,
                                  left: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                    child: Center(
                                      child: Text(
                                        f['tag']!,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(f['name']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // YOUR SIMPLIFIED NET BALANCES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('YOUR SIMPLIFIED NET BALANCES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                Text('3 transfers needed', style: TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),

            // Balance 1: Ameya owes you
            _buildSimplifiedBalanceCard(
              isIncoming: true,
              title: 'Ameya owes you',
              subtitle: "For Fisherman's Wharf Dinner",
              amount: '+₹750',
              hasRemind: true,
            ),
            const SizedBox(height: 10),

            // Balance 2: Atharva owes you
            _buildSimplifiedBalanceCard(
              isIncoming: true,
              title: 'Atharva owes you',
              subtitle: 'Split remainder',
              amount: '+₹500',
              hasRemind: true,
            ),
            const SizedBox(height: 10),

            // Balance 3: You owe Rohan
            _buildSimplifiedBalanceCard(
              isIncoming: false,
              title: 'You owe Rohan',
              subtitle: 'Scooter Rental share',
              amount: '-₹500',
              hasRemind: false,
            ),
            const SizedBox(height: 22),

            // RECENT GROUP EXPENSES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('RECENT GROUP EXPENSES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                Text('3 entries', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),

            _buildGroupExpenseRow(
              icon: Icons.restaurant_rounded,
              title: "Dinner at Fisherman's Wharf",
              subtitle: 'Paid by Ritesh (You) • Split equal (₹600/ea)',
              total: '₹3,000',
              share: '+₹2,400 back',
              isPositiveShare: true,
            ),
            _buildGroupExpenseRow(
              icon: Icons.two_wheeler_rounded,
              title: 'Scooter Rental (3 days)',
              subtitle: 'Paid by Rohan • Split between 5',
              total: '₹2,500',
              share: 'Your share: ₹500',
            ),
            _buildGroupExpenseRow(
              icon: Icons.lunch_dining_rounded,
              title: 'Beach Shack Snacks',
              subtitle: 'Paid by Ameya • Split between 4',
              total: '₹1,200',
              share: 'Your share: ₹300',
            ),
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
                children: const [
                  Icon(Icons.hub_outlined, color: AppColors.green, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Debt Simplification Enabled', style: TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text(
                          'FinTrack algorithms reduced 8 individual peer debts down to just 3 direct transactions. No more circular transfers!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
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
  }

  Widget _buildSimplifiedBalanceCard({
    required bool isIncoming,
    required String title,
    required String subtitle,
    required String amount,
    required bool hasRemind,
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
                    onPressed: () {},
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
                    onPressed: () {},
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
              onPressed: () {},
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
