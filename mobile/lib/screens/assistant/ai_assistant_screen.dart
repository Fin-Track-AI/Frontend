import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/mock_data_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hi Samarth! 👋 I am your FinTrack AI Financial Assistant. I can analyze your spending trends, check tax-saving claim eligibility, or forecast your end-of-month budget. How can I help you today?',
      'time': 'Just now',
    },
  ];
  bool _isTyping = false;

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;
    final userText = query.trim();
    _chatController.clear();

    setState(() {
      _messages.add({
        'isUser': true,
        'text': userText,
        'time': 'Just now',
      });
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      String reply = "Based on your September transactions, your Dining & Food spend is ₹14,200 (33% of your budget). You have ₹17,150 remaining in your monthly target.";
      if (userText.toLowerCase().contains('reimbursement') || userText.toLowerCase().contains('claim')) {
        reply = "You have 1 pending claim of ₹1,250 ('Airport Cab') in review, and ₹3,850 was approved by TechCorp Solutions.";
      } else if (userText.toLowerCase().contains('split') || userText.toLowerCase().contains('owe')) {
        reply = "Across your active groups, you are net owed ₹1,200 (₹2,400 owed to you vs ₹1,200 you owe for Flat 402 rent).";
      }

      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': reply,
          'time': 'Just now',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = MockDataService.aiSuggestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AI Copilot'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        border: Border.all(
                          color: isUser ? Colors.transparent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isUser ? Colors.black : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Text('FinTrack AI is analyzing insights...', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),

            // Prompt Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: suggestions.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      label: Text(s['query'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      onPressed: () => _sendMessage(s['query'] as String),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask about spends, claims, or budgets...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () => _sendMessage(_chatController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
