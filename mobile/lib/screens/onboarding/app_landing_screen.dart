import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/fintrack_logo.dart';
import '../legal/terms_privacy_screen.dart';

class AppLandingScreen extends StatefulWidget {
  const AppLandingScreen({super.key});

  @override
  State<AppLandingScreen> createState() => _AppLandingScreenState();
}

class _AppLandingScreenState extends State<AppLandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<LandingSlideData> _slides = const [
    LandingSlideData(
      badge: 'AUTOMATED TRACKING',
      badgeColor: AppColors.primary,
      badgeBg: AppColors.primaryLight,
      icon: Icons.bolt_rounded,
      title: 'Automated UPI &\nExpense Intelligence',
      description:
          'Track instant UPI transactions, monitor real-time monthly burn rate, and get smart financial budget insights.',
      previewType: 0,
    ),
    LandingSlideData(
      badge: 'WORKPLACE REIMBURSEMENTS',
      badgeColor: AppColors.blue,
      badgeBg: AppColors.blueLight,
      icon: Icons.receipt_long_rounded,
      title: '1-Click Corporate\nExpense Claims',
      description:
          'Scan physical bills with high-accuracy OCR, sync directly with your employer dashboard, and track payout timelines.',
      previewType: 1,
    ),
    LandingSlideData(
      badge: 'COLLABORATIVE SPLITS',
      badgeColor: AppColors.green,
      badgeBg: AppColors.greenLight,
      icon: Icons.group_work_rounded,
      title: 'Frictionless Group\nBill Splits & Settling',
      description:
          'Fair-share splits for rent, dining, and trips with roommates and colleagues. Gentle reminders with zero social friction.',
      previewType: 2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Top Header: Bigger Logo (RBI & DPDP tag removed)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      FinTrackLogo(size: 42, fontSize: 24),
                    ],
                  ),
                ),

                // Carousel Slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: slide.badgeBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(slide.icon, color: slide.badgeColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    slide.badge,
                                    style: TextStyle(
                                      color: slide.badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              slide.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle description
                            Text(
                              slide.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Rich Interactive Example Card (Packed with content, no blank space)
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: _buildRichExample(slide.previewType),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls: Indicators + Buttons
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4.0, bottom: 12.0),
                  child: Column(
                    children: [
                      // Animated Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isActive = idx == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),

                      // Primary Action: Create Account
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.signup);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create New Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Secondary Action: Sign In
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          child: const Text(
                            'I Already Have an Account • Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Terms Footnote (Guaranteed single line via FittedBox & calibrated font size)
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'By continuing, you agree to FinTrack’s Terms of Service & Privacy Policy',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Read Terms & Privacy Policy Action Button (Compact & elegant)
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border, width: 1.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {
                            TermsPrivacyScreen.show(context);
                          },
                          icon: const Icon(Icons.description_outlined, size: 14, color: AppColors.primary),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Read Terms of Service and Privacy Policy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichExample(int previewType) {
    switch (previewType) {
      case 0:
        return _buildExpenseExample();
      case 1:
        return _buildReimbursementExample();
      case 2:
      default:
        return _buildSplitExample();
    }
  }

  /// Example 1: Dense, high-value UPI & Expense Tracker showcase (No AI Tip, zero blank space)
  Widget _buildExpenseExample() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank & Safe-to-Spend Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'HDFC Bank •• 4092 (Synced)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'On Track (72%)',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Safe to spend balance + daily budget pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safe-to-Spend Balance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '₹38,450',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.speed_rounded, color: AppColors.primary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '₹2,100 / day',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Auto-Categorized Feed
          const Text(
            'LIVE AUTO-CATEGORIZED SPEND FEED',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          _buildTransactionRow(
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            title: 'Swiggy Gourmet • UPI',
            subtitle: 'Today, 1:15 PM • Instant read',
            category: 'Dining',
            amount: '-₹480',
            isCredit: false,
          ),
          const SizedBox(height: 8),
          _buildTransactionRow(
            icon: Icons.local_taxi_rounded,
            iconColor: AppColors.blue,
            iconBg: AppColors.blueLight,
            title: 'Uber Premier • UPI',
            subtitle: 'Yesterday, 8:45 PM • Trip commute',
            category: 'Travel',
            amount: '-₹320',
            isCredit: false,
          ),
          const SizedBox(height: 8),
          _buildTransactionRow(
            icon: Icons.shopping_basket_rounded,
            iconColor: AppColors.amber,
            iconBg: AppColors.amberLight,
            title: 'Zepto Instant • UPI',
            subtitle: 'Yesterday, 11:20 AM • Groceries',
            category: 'Groceries',
            amount: '-₹540',
            isCredit: false,
          ),
          const SizedBox(height: 8),
          _buildTransactionRow(
            icon: Icons.movie_filter_rounded,
            iconColor: AppColors.secondary,
            iconBg: AppColors.surfaceMuted,
            title: 'Netflix Subscription',
            subtitle: 'Sep 03 • Auto-debit recurring',
            category: 'Entertainment',
            amount: '-₹649',
            isCredit: false,
          ),
          const SizedBox(height: 8),
          _buildTransactionRow(
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.green,
            iconBg: AppColors.greenLight,
            title: 'TechCorp Salary Credit',
            subtitle: 'Sep 01 • Monthly In-Hand',
            category: 'Salary',
            amount: '+₹85,000',
            isCredit: true,
          ),
          const SizedBox(height: 12),

          // Bottom Quick Metrics Bar (fills footer cleanly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Month Spent', '₹28,400', AppColors.textPrimary),
                Container(width: 1, height: 22, color: AppColors.border),
                _buildSummaryStat('Daily Avg', '₹946', AppColors.textPrimary),
                Container(width: 1, height: 22, color: AppColors.border),
                _buildSummaryStat('Projected Save', '₹32,500', AppColors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Example 2: Dense Corporate Reimbursements & OCR Pipeline
  Widget _buildReimbursementExample() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.blueLight,
                      child: Icon(Icons.apartment_rounded, color: AppColors.blue, size: 16),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TechCorp Solutions India',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Corporate Policy Synced',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quota Summary Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Claimed This Month', '₹18,400', AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile('Available Limit', '₹25,000', AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Claim Card 1
          _buildClaimItemCard(
            title: 'Team Dinner & Client Hosting',
            code: 'OCR Extracted: GSTIN 29AAACT1234A • Tax Invoice #8841',
            status: 'Approved',
            statusColor: AppColors.green,
            statusBg: AppColors.greenLight,
            amount: '₹4,250.00',
          ),
          const SizedBox(height: 8),

          // Active Claim Card 2
          _buildClaimItemCard(
            title: 'Airport Travel to Client Office',
            code: 'Uber Commercial Ride • Receipt #UB-99410',
            status: 'Processing',
            statusColor: AppColors.amber,
            statusBg: AppColors.amberLight,
            amount: '₹1,180.00',
          ),
          const SizedBox(height: 12),

          // Multi-step Claim Tracker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepPill('1. Scan Bill', true),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.blue, size: 10),
                _buildStepPill('2. Auto Audit', true),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.blue, size: 10),
                _buildStepPill('3. HR Approval', true),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.blue, size: 10),
                _buildStepPill('4. Salary Payout', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Example 3: Dense Group Bill Splits with Settle-Up
  Widget _buildSplitExample() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.greenLight,
                      child: Icon(Icons.home_work_rounded, color: AppColors.green, size: 16),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flat 402 • Roommates & Trips',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '4 Members Active',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UPI Settled',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Total You Are Owed Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL BALANCE',
                        style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'You get back ₹3,850',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '1-Tap Settle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Member Rows
          const Text(
            'ACTIVE SPLITS BREAKDOWN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          _buildMemberSplitTile('Aman Sharma', 'Owes ₹1,850 for WiFi & Groceries', 'Pending', AppColors.amber),
          const SizedBox(height: 6),
          _buildMemberSplitTile('Rohit Verma', 'Owes ₹2,000 for Electricity Bill', 'Sent Reminder', AppColors.primary),
          const SizedBox(height: 6),
          _buildMemberSplitTile('Priya Patel', 'Settled up ₹1,400 via Google Pay', 'Settled ✓', AppColors.green),
          const SizedBox(height: 6),
          _buildMemberSplitTile('Sneha Roy', 'Flat rent share reconciled', 'Balanced ✓', AppColors.textSecondary),
          const SizedBox(height: 10),

          // Footnote tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.green, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Smart debt simplification minimizes total UPI transactions between friends.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildClaimItemCard({
    required String title,
    required String code,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.document_scanner_rounded, color: AppColors.blue, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reimbursement Amount',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
              Text(
                amount,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String category,
    required String amount,
    required bool isCredit,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: isCredit ? AppColors.green : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String title, bool isDone) {
    return Text(
      title,
      style: TextStyle(
        color: isDone ? AppColors.blue : AppColors.textMuted,
        fontSize: 9.5,
        fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }

  Widget _buildMemberSplitTile(String name, String sub, String badge, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    name[0],
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            badge,
            style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class LandingSlideData {
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final String title;
  final String description;
  final int previewType;

  const LandingSlideData({
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.title,
    required this.description,
    required this.previewType,
  });
}
