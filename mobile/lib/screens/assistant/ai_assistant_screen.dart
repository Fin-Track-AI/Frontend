import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _chatController = TextEditingController();

  final List<String> _suggestions = [
    'How can I reach my ₹10,000 monthly savings goal?',
    'Show all reimbursable receipts',
    'Who owes me money right now?',
    'Analyze my grocery habits',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                children: [
                  // Top Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Ask FinTrack AI', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                                  SizedBox(height: 2),
                                  Text('Real-time ledger analytics & spending breakdown', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('Private Sync', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 14),
                            SizedBox(width: 6),
                            Text('Powered by FinTrack Private Intelligence', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Guardrail Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guardrail Notice: FinTrack AI provides read-only financial insights based on your synchronized transaction metadata. It does not provide regulated investment, banking, or tax advice.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timestamp
                  const Center(
                    child: Text('Today, 10:42 AM', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),

                  // User Bubble 1
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Where did I overspend this month compared to August?',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Response 1
                  _buildAiInsightCard(
                    alertTag: 'SPEND VELOCITY ALERT',
                    alertSub: '1–12 Sep vs Aug',
                    tagColor: AppColors.primary,
                    intro: 'Here is what stands out in your September spending (1–12 Sep):',
                    items: [
                      _buildSpendInsightItem(
                        icon: Icons.restaurant_rounded,
                        title: 'Food & Dining',
                        diff: '+18% MoM',
                        diffColor: AppColors.red,
                        desc: '₹3,240 vs ₹2,700 pace. 7 Swiggy orders accounted for ₹2,450.',
                      ),
                      const SizedBox(height: 8),
                      _buildSpendInsightItem(
                        icon: Icons.directions_car_outlined,
                        title: 'Transit Mobility',
                        diff: '+₹680 Surge',
                        diffColor: AppColors.amber,
                        desc: 'Weekend Uber rides to Indiranagar spiked by ₹680 during late hours.',
                      ),
                    ],
                    tipBox: 'Limiting weekend food delivery to 2 orders could save approx ₹1,200 this month.',
                    footerNote: 'Computed across 28 ledger entries',
                  ),
                  const SizedBox(height: 16),

                  // User Bubble 2
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'What subscriptions do I have active?',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Response 2
                  _buildAiInsightCard(
                    alertTag: 'RECURRING COMMITMENTS',
                    alertSub: 'Active Autopay',
                    tagColor: AppColors.primary,
                    intro: 'You have 3 active auto-detected recurring subscriptions totaling ₹1,298/mo:',
                    items: [
                      _buildSubscriptionItem('N', 'Netflix India', 'Next bill: 18 Sep', '₹199/mo', 'Auto-debit', const Color(0xFFE50914)),
                      const SizedBox(height: 8),
                      _buildSubscriptionItem('S', 'Spotify Premium', 'Next bill: 24 Sep', '₹119/mo', 'Auto-debit', const Color(0xFF1DB954)),
                      const SizedBox(height: 8),
                      _buildSubscriptionItem('G', 'Gym Membership', 'Next bill: 01 Oct', '₹980/mo', 'UPI Mandate', const Color(0xFF8B5CF6)),
                    ],
                    badgeSuccess: 'No hidden recurring charges detected.',
                    footerAction: 'Manage Auto-mandates →',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // SUGGESTED INQUIRIES & INPUT BAR
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('SUGGESTED INQUIRIES', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        Text('Tap to ask', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: _suggestions.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: AppColors.surfaceMuted,
                            side: const BorderSide(color: AppColors.border),
                            label: Text(s, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              _chatController.text = s;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(
                              hintText: 'Ask anything about your money, budgets, or bills...',
                              fillColor: AppColors.surfaceMuted,
                              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              if (_chatController.text.trim().isNotEmpty) {
                                _chatController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'FinTrack AI protects personal credentials and never shares raw banking tokens.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsightCard({
    required String alertTag,
    required String alertSub,
    required Color tagColor,
    required String intro,
    required List<Widget> items,
    String? tipBox,
    String? badgeSuccess,
    String? footerNote,
    String? footerAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(alertTag, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                child: Text(alertSub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(intro, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...items,
          if (tipBox != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greenBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tipBox, style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
          if (badgeSuccess != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(badgeSuccess, style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (footerNote != null)
                Text(footerNote, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              if (footerAction != null)
                Text(footerAction, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
              Row(
                children: const [
                  Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Icon(Icons.thumb_down_alt_outlined, size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendInsightItem({
    required IconData icon,
    required String title,
    required String diff,
    required Color diffColor,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              Text(diff, style: TextStyle(color: diffColor, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(String badge, String title, String nextBill, String amount, String type, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: badgeColor,
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(nextBill, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              Text(type, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
