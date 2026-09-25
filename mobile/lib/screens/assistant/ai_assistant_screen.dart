import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../services/session_service.dart';
import '../../services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();

  bool _isLoading = false;

  final List<String> _suggestions = [
    'Where did I spend money this month?',
    'What subscriptions do I have active?',
    'Show all reimbursable receipts',
    'Who owes me money right now?',
    'How can I reach my savings goal?',
  ];

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialGroundingSummary();
  }

  Future<void> _fetchInitialGroundingSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = SessionService().token ?? '';
      final responseData = await _aiService.sendChatMessage(
        prompt: 'Give me an overview of my spending and financial status',
        authToken: token,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'data': responseData,
          });
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _chatController.clear();
    setState(() {
      _messages.add({
        'isUser': true,
        'text': query,
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final token = SessionService().token ?? '';
      final responseData = await _aiService.sendChatMessage(
        prompt: query,
        authToken: token,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'data': responseData,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'data': {
              'alertTag': 'AI ASSISTANT NOTICE',
              'alertSub': 'FinTrack Engine',
              'intro': 'AI Analysis Output:',
              'reply': 'Unable to connect to AI grounding backend: ${e.toString().replaceAll('Exception: ', '')}',
              'tipBox': 'Make sure your backend server is running and your account has active transactions.',
            },
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _parseHexColor(String? hexString, Color defaultColor) {
    if (hexString == null || !hexString.startsWith('#')) return defaultColor;
    try {
      final hex = hexString.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transit':
        return Icons.directions_car_outlined;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'people':
        return Icons.group_rounded;
      case 'movie':
        return Icons.movie_outlined;
      case 'music':
        return Icons.music_note_rounded;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.auto_awesome;
    }
  }

  Widget _buildSuggestedChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: _suggestions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.surfaceMuted,
              side: const BorderSide(color: AppColors.border),
              avatar: const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
              label: Text(
                s,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                _sendMessage(s);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

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
                controller: _scrollController,
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                        const Row(
                          children: [
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
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  const SizedBox(height: 14),

                  // ALWAYS VISIBLE TOP SUGGESTED INQUIRIES SECTION
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('SUGGESTED INQUIRIES', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              Text('Tap to ask AI', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        _buildSuggestedChipsRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timestamp
                  const Center(
                    child: Text('Live Session • Grounded in Real Data', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),

                  // Messages List
                  ..._messages.map((msg) {
                    if (msg['isUser'] == true) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final data = msg['data'] as Map<String, dynamic>? ?? {};
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDynamicAiCard(data),
                      );
                    }
                  }),

                  if (_isLoading) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'FinTrack AI is analyzing your ledger context...',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // FIXED DOCKED INPUT BAR WITH QUICK CHIPS
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSuggestedChipsRow(),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            onSubmitted: _sendMessage,
                            decoration: const InputDecoration(
                              hintText: 'Ask about your real spending, claims, or bills...',
                              fillColor: AppColors.surfaceMuted,
                              prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            onPressed: () => _sendMessage(_chatController.text),
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

  Widget _buildDynamicAiCard(Map<String, dynamic> data) {
    final alertTag = data['alertTag']?.toString() ?? 'AI INSIGHT';
    final alertSub = data['alertSub']?.toString() ?? 'FinTrack Intelligence';
    final intro = data['intro']?.toString() ?? '';
    final reply = data['reply']?.toString();
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    final tipBox = data['tipBox']?.toString();
    final badgeSuccess = data['badgeSuccess']?.toString();
    final footerNote = data['footerNote']?.toString();
    final footerAction = data['footerAction']?.toString();

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
          if (intro.isNotEmpty) ...[
            Text(intro, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
          ],
          if (reply != null && reply.isNotEmpty) ...[
            Text(reply, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
            const SizedBox(height: 10),
          ],
          ...itemsList.map((item) {
            final itemMap = item as Map<String, dynamic>;
            final iconData = _getIconData(itemMap['icon']?.toString());
            final title = itemMap['title']?.toString() ?? 'Spend Item';
            final diff = itemMap['diff']?.toString() ?? '';
            final diffColor = _parseHexColor(itemMap['diffColor']?.toString(), AppColors.primary);
            final desc = itemMap['desc']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSpendInsightItem(
                icon: iconData,
                title: title,
                diff: diff,
                diffColor: diffColor,
                desc: desc,
              ),
            );
          }),
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
                  Expanded(
                    child: Text(badgeSuccess, style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (footerNote != null)
                Expanded(
                  child: Text(
                    footerNote,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (footerAction != null) ...[
                const SizedBox(width: 8),
                Text(footerAction, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
              const SizedBox(width: 8),
              const Row(
                children: [
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
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(diff, style: TextStyle(color: diffColor, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
          ],
        ],
      ),
    );
  }
}
