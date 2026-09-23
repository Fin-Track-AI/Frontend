import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsPrivacyScreen extends StatefulWidget {
  final int initialTabIndex;

  const TermsPrivacyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: TermsPrivacyScreen(initialTabIndex: initialTabIndex),
        ),
      ),
    );
  }

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        title: const Text(
          'Legal & Compliance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.article_outlined, size: 18),
                  text: 'Terms of Service',
                ),
                Tab(
                  icon: Icon(Icons.shield_outlined, size: 18),
                  text: 'Privacy Policy',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Compliance Badge Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary.withOpacity(0.08),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DPDP Act 2023 & RBI Compliant • Updated September 2026',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTermsOfServiceTab(),
                _buildPrivacyPolicyTab(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'I Understand and Accept',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsOfServiceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionCard(
          number: '1',
          title: 'Acceptance of Terms',
          content:
              'By accessing, downloading, or using FinTrack ("App", "Service", "Platform"), operated by FinTrack Technologies India Pvt. Ltd., you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the application.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'Informational & Intelligence Nature',
          content:
              'FinTrack is an informational financial analysis, expense tracking, and budget intelligence tool. FinTrack IS NOT a bank, payment service provider, wallet, or non-banking financial company (NBFC). FinTrack does not execute funds transfers, accept deposits, or provide regulated investment, financial, or tax advice.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'User Eligibility & Account Registration',
          content:
              'You must be at least 18 years of age and a resident of India to create a FinTrack account. You agree to provide accurate, current, and complete mobile phone numbers and profile details during registration. You are solely responsible for maintaining the confidentiality of your credentials and one-time passcodes (OTPs).',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Expense Telemetry & Automated Tracking',
          content:
              'To deliver automated transaction categorization and budget warnings, FinTrack analyzes SMS alerts and transactional notifications strictly on your device or via secure, encrypted ingestion pipes where consent has been granted. FinTrack never reads personal messages, promotional spam, or private chats.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Split Expenses & Group Ledgers',
          content:
              'The Split Expense feature enables shared ledger calculation and balance tracking among registered peers. FinTrack provides ledger calculation assistance; any actual fund settlements between group members take place outside the app directly via peer-to-peer UPI apps. FinTrack is not liable for interpersonal payment disputes.',
        ),
        _buildSectionCard(
          number: '6',
          title: 'OCR Receipt Scanning & Employer Claims',
          content:
              'When uploading bills and tax invoices for corporate reimbursement or automated spend tracking, you represent that you have lawful authorization to submit such documentation. FinTrack parses tax breakdowns and merchant GSTINs via AI OCR to assist your workplace claims filing.',
        ),
        _buildSectionCard(
          number: '7',
          title: 'Prohibited Activities',
          content:
              'You may not reverse-engineer, decompile, or tamper with the application, inject automated scraping bots, use FinTrack for fraudulent tax claims or money laundering activities, or breach applicable RBI and Indian cyber security regulations.',
        ),
        _buildSectionCard(
          number: '8',
          title: 'Termination & Data Erasure',
          content:
              'You may delete your account and request complete erasure of your data at any time from the Profile & Settings menu. FinTrack reserves the right to suspend or terminate accounts that breach these terms or engage in illicit behavior.',
        ),
        _buildSectionCard(
          number: '9',
          title: 'Limitation of Liability & Disclaimer of Warranties',
          content:
              'FinTrack is provided on an "as is" and "as available" basis without warranties of any kind. FinTrack shall not be liable for indirect, punitive, or consequential damages resulting from algorithmic estimations, third-party bank server outages, or user input errors.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrivacyPolicyTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionCard(
          number: '1',
          title: 'Digital Personal Data Protection (DPDP) Act 2023',
          content:
              'FinTrack strictly complies with India\'s Digital Personal Data Protection (DPDP) Act 2023 and the Reserve Bank of India (RBI) Data Localization Guidelines. All user data is processed with explicit, lawful consent and stored exclusively on secure servers located within India.',
        ),
        _buildSectionCard(
          number: '2',
          title: 'What Information We Collect',
          content:
              '• Profile Data: Full name, verified mobile phone number, email address.\n'
              '• Financial Profile: Optional monthly salary bracket, savings goals, and rent amount for budget benchmarking.\n'
              '• Spend Metadata: Transaction amount, merchant category, timestamp, and payment method (e.g. UPI, card).\n'
              '• Bill Attachments: Invoices and receipts voluntarily uploaded for reimbursement claims.',
        ),
        _buildSectionCard(
          number: '3',
          title: 'What We NEVER Collect or Store',
          content:
              '• We NEVER ask for or store your Net Banking Passwords.\n'
              '• We NEVER access or record your UPI PIN or ATM PIN.\n'
              '• We NEVER record your Debit/Credit Card CVV or full card numbers.\n'
              '• We NEVER read personal conversation messages, photos, or contacts without explicit permission.',
        ),
        _buildSectionCard(
          number: '4',
          title: 'Data Encryption & Infrastructure Security',
          content:
              'All data in transit is encrypted using Transport Layer Security (TLS 1.3 / HTTPS). Data at rest in our databases is encrypted using industry-standard AES-256 bit encryption keys. Multi-factor authentication safeguards all backend service interactions.',
        ),
        _buildSectionCard(
          number: '5',
          title: 'Zero Third-Party Data Selling',
          content:
              'Your financial privacy is non-negotiable. FinTrack DOES NOT sell, rent, or trade your personal or financial data to advertising networks, telemarketers, credit card telecallers, or third-party data brokers.',
        ),
        _buildSectionCard(
          number: '6',
          title: 'Your Statutory Data Rights',
          content:
              'Under the DPDP Act, you have full ownership over your data:\n'
              '• Right to Access: View all transactions and profile records anytime.\n'
              '• Right to Rectification: Correct inaccurate details directly in the app.\n'
              '• Right to Consent Withdrawal: Turn off AI insights, SMS parsing, or employer linking anytime.\n'
              '• Right to Erasure: Permanently delete your FinTrack account and purge all data.',
        ),
        _buildSectionCard(
          number: '7',
          title: 'Data Protection Officer (DPO) & Redressal',
          content:
              'For grievances, data inquiries, or consent revocation requests, you may contact our designated Data Protection Officer:\n'
              'Email: privacy@fintrack.ai\n'
              'Grievance Officer: Ritesh Jadhav\n'
              'FinTrack Technologies India Pvt. Ltd., Outer Ring Road, Bengaluru, Karnataka 560103.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
