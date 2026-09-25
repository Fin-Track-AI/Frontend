import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/split_models.dart';
import '../../services/split_service.dart';

class CreateGroupModal extends StatefulWidget {
  const CreateGroupModal({super.key});

  static Future<SplitGroup?> show(BuildContext context) {
    return showModalBottomSheet<SplitGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupModal(),
    );
  }

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedEmoji = '🏖️';
  final List<String> _emojiOptions = ['🏖️', '🏡', '🍱', '✈️', '🎉', '☕', '🎮', '🚗', '🍕', '🏕️', '🍿', '💡'];

  late List<GroupMember> _members;
  bool _isSearching = false;
  String? _phoneErrorMessage;
  String? _unregisteredPhone;

  @override
  void initState() {
    super.initState();
    // Creator is the only initial member — no demo/mock members
    final currentUser = SplitService().currentUser;
    _members = [currentUser];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addUnregisteredContact() {
    if (_unregisteredPhone == null) return;
    final phone = _unregisteredPhone!;
    setState(() {
      _members.add(
        GroupMember(
          id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Contact (${phone.length >= 10 ? phone.substring(phone.length - 4) : phone})',
          phone: phone,
          avatarUrl: '',
          status: 'PENDING_INVITE',
        ),
      );
      _phoneController.clear();
      _unregisteredPhone = null;
      _phoneErrorMessage = null;
    });
  }

  Future<void> _verifyAndAddMember() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _phoneErrorMessage = 'Please enter a 10-digit mobile number';
        _unregisteredPhone = null;
      });
      return;
    }

    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      setState(() {
        _phoneErrorMessage = 'Please enter a valid 10-digit mobile number';
        _unregisteredPhone = null;
      });
      return;
    }

    final last10 = digitsOnly.substring(digitsOnly.length - 10);
    final currentUser = SplitService().currentUser;

    // Check if adding own number
    if (currentUser.phoneNumber.isNotEmpty) {
      final userDigits = currentUser.phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (userDigits.endsWith(last10)) {
        setState(() {
          _phoneErrorMessage = 'You are already added as the group creator';
          _unregisteredPhone = null;
        });
        return;
      }
    }

    // Check if already in member list
    final alreadyAdded = _members.any((m) {
      final mDigits = m.phoneNumber.replaceAll(RegExp(r'\D'), '');
      return mDigits.isNotEmpty && mDigits.endsWith(last10);
    });

    if (alreadyAdded) {
      setState(() {
        _phoneErrorMessage = 'This person is already in the member list';
        _unregisteredPhone = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _phoneErrorMessage = null;
      _unregisteredPhone = null;
    });

    final result = await SplitService().lookupUserByPhone(rawPhone);

    if (!mounted) return;

    if (result['exists'] == true) {
      final userData = result['user'] as Map<String, dynamic>;
      setState(() {
        _members.add(
          GroupMember(
            id: userData['id']?.toString() ?? 'mem_${DateTime.now().millisecondsSinceEpoch}',
            name: userData['name']?.toString() ?? 'FinTrack Member',
            phone: userData['phone']?.toString() ?? rawPhone,
            avatarUrl: userData['avatarUrl']?.toString() ?? '',
            status: 'PENDING_INVITE',
          ),
        );
        _phoneController.clear();
        _isSearching = false;
        _phoneErrorMessage = null;
        _unregisteredPhone = null;
      });
    } else {
      setState(() {
        _isSearching = false;
        _unregisteredPhone = rawPhone;
        _phoneErrorMessage = null;
      });
    }
  }

  void _removeMember(int index) {
    if (index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove yourself from the group')),
      );
      return;
    }
    setState(() {
      _members.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Please add at least 1 friend by mobile number to split expenses'),
        ),
      );
      return;
    }

    final newGroup = SplitService().createGroup(
      name: _nameController.text.trim(),
      icon: _selectedEmoji,
      members: _members,
    );

    Navigator.pop(context, newGroup);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: 60, bottom: keyboardHeight),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Create Split Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text(
                        'Add friends via mobile number & split shared expenses',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
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

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Icon Selection
                    const Text('GROUP ICON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _emojiOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final emoji = _emojiOptions[index];
                          final isSelected = _selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedEmoji = emoji),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.greenLight : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.green : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Group Name
                    const Text('GROUP NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Manali Trip, Flat 402, Hackathon Team',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.group_work_outlined, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a group name' : null,
                    ),
                    const SizedBox(height: 24),

                    // Members Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GROUP MEMBERS (${_members.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const Text('Verified by FinTrack', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Existing members list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final isSelf = member.isSelf || member.isCurrentUser;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelf ? AppColors.greenLight.withOpacity(0.4) : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelf ? AppColors.greenBorder : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isSelf ? AppColors.green : AppColors.primary,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          member.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        if (isSelf)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('YOU (ADMIN)', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('INVITATION WILL BE SENT', style: TextStyle(color: AppColors.blue, fontSize: 8, fontWeight: FontWeight.w800)),
                                          ),
                                      ],
                                    ),
                                    if (member.phoneNumber.isNotEmpty)
                                      Text(
                                        member.phoneNumber,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isSelf)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.red),
                                  onPressed: () => _removeMember(index),
                                  tooltip: 'Remove member',
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Add new member input by Mobile Number
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add Member by Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          const Text('We will check if this friend has a FinTrack account and send an invitation', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 9876543210',
                                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: AppColors.surfaceMuted,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                  onSubmitted: (_) => _verifyAndAddMember(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSearching ? null : _verifyAndAddMember,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                child: _isSearching
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Row(
                                        children: [
                                          Icon(Icons.search, size: 16),
                                          SizedBox(width: 4),
                                          Text('Check & Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                          if (_unregisteredPhone != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBAE0FF)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$_unregisteredPhone is not on FinTrack yet. You can still invite them!',
                                          style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addUnregisteredContact,
                                    icon: const Icon(Icons.person_add_outlined, size: 14),
                                    label: Text('Add & Invite $_unregisteredPhone', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_phoneErrorMessage != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFCCC7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _phoneErrorMessage!,
                                      style: const TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create Group & Send Invites',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
