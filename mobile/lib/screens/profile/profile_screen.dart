import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/mock_data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _dataMaskingEnabled = true;
  bool _rbiAaLinked = true;
  bool _biometricLock = false;

  @override
  Widget build(BuildContext context) {
    final user = MockDataService.userProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Security'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: const Text(
                      'SD',
                      style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] as String,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user['employer']} • ${user['phone']}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'KYC-Lite Verified',
                            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Security & Compliance (DPDP Act)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingSwitchTile(
              title: 'Sensitive Data Masking',
              subtitle: 'Mask PAN, Bank Account & UPI IDs across UI views',
              value: _dataMaskingEnabled,
              onChanged: (v) => setState(() => _dataMaskingEnabled = v),
              icon: Icons.visibility_off_outlined,
            ),
            const SizedBox(height: 10),

            _buildSettingSwitchTile(
              title: 'RBI Account Aggregator Connection',
              subtitle: 'Read-only financial insights sync is ACTIVE',
              value: _rbiAaLinked,
              onChanged: (v) => setState(() => _rbiAaLinked = v),
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),

            _buildSettingSwitchTile(
              title: 'App Lock / Biometrics',
              subtitle: 'Require FaceID / Fingerprint to open FinTrack',
              value: _biometricLock,
              onChanged: (v) => setState(() => _biometricLock = v),
              icon: Icons.fingerprint_rounded,
            ),
            const SizedBox(height: 24),

            const Text(
              'Team & Workspace',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildTeamMemberRow('Samarth Devadiga', 'Scrum Master / UI-UX Coding (mobile/)'),
                  const Divider(color: AppColors.divider, height: 20),
                  _buildTeamMemberRow('Atharva', 'Backend & API Architecture (backend/)'),
                  const Divider(color: AppColors.divider, height: 20),
                  _buildTeamMemberRow('Ameya Sagwekar', 'BA & UI-UX Figma Design (docs/)'),
                  const Divider(color: AppColors.divider, height: 20),
                  _buildTeamMemberRow('Ritesh', 'DB Infrastructure & APIs (backend/)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: const Text('Log Out & Revoke Local Tokens', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (r) => false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(String name, String role) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
