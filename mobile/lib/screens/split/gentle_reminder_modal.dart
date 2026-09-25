import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/split_models.dart';
import '../../services/split_service.dart';

class GentleReminderModal extends StatefulWidget {
  final DebtRelation debt;
  final String groupName;
  final String? groupId;

  const GentleReminderModal({
    super.key,
    required this.debt,
    required this.groupName,
    this.groupId,
  });

  static Future<void> show(
    BuildContext context, {
    required DebtRelation debt,
    required String groupName,
    String? groupId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GentleReminderModal(
        debt: debt,
        groupName: groupName,
        groupId: groupId,
      ),
    );
  }

  @override
  State<GentleReminderModal> createState() => _GentleReminderModalState();
}

class _GentleReminderModalState extends State<GentleReminderModal> {
  int _selectedToneIndex = 0;
  bool _isSending = false;

  final List<String> _tones = ['Friendly & Casual', 'Quick Poke', 'Direct & Clear'];


  String _getToneMessage(int index) {
    final name = widget.debt.fromMemberName;
    final amt = '₹${widget.debt.amount.toStringAsFixed(0)}';
    final grp = widget.groupName;

    switch (index) {
      case 0:
        return 'Hey $name! 👋 FinTrack friendly ping regarding our split in "$grp" ($amt). Whenever you get a moment, settle up via UPI/Cash and let me know!';
      case 1:
        return 'Hey $name, quick nudge for the "$grp" balance ($amt). Whenever you get time, cheers! ☕';
      case 2:
      default:
        return 'Hi $name, FinTrack ledger update: Outstanding balance of $amt for "$grp". Ping me once settled externally!';
    }
  }

  void _copyToClipboard() {
    final text = _getToneMessage(_selectedToneIndex);
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.green, size: 18),
            SizedBox(width: 8),
            Text('Reminder copied to clipboard! Paste in WhatsApp or SMS.'),
          ],
        ),
      ),
    );
  }

  void _sendAppNotification() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final targetGroupId = widget.groupId ?? widget.debt.id.split('_').first;
    final message = _getToneMessage(_selectedToneIndex);

    final success = await SplitService().sendReminder(
      groupId: targetGroupId,
      debt: widget.debt,
      message: message,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          content: Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gentle reminder sent to ${widget.debt.fromMemberName} for ₹${widget.debt.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.textPrimary,
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not deliver in-app reminder. Try copying to clipboard.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountFormatted = '₹${widget.debt.amount.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mail_outline, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Gentle Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            SizedBox(height: 2),
                            Text(
                              'BR-19: Friendly, zero-awkward nudges',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Summary Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          widget.debt.fromMemberName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.debt.fromMemberName} owes you',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'In group: ${widget.groupName}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        amountFormatted,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tone Selector Chips
                const Text('SELECT MESSAGE TONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_tones.length, (idx) {
                    final isSelected = _selectedToneIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_tones[idx]),
                        selected: isSelected,
                        selectedColor: AppColors.greenLight,
                        backgroundColor: AppColors.surfaceMuted,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.green : AppColors.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.greenBorder : AppColors.border,
                        ),
                        onSelected: (_) => setState(() => _selectedToneIndex = idx),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Pre-composed Message Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('PREVIEW COPY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5)),
                          Icon(Icons.edit_note_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getToneMessage(_selectedToneIndex),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Non-Monetary Disclaimer Alert
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'FinTrack is a non-monetary ledger. Payments happen directly outside the app via cash or UPI.',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF1E40AF), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Text', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendAppNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.white),
                        label: Text(
                          _isSending ? 'Sending...' : 'Send Nudge',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
