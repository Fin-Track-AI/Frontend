import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/claim_service.dart';

class MyClaimsScreen extends StatefulWidget {
  final String authToken;

  const MyClaimsScreen({super.key, required this.authToken});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  final _service = ClaimService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _claims = [];

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final claimsList = await _service.getMyClaims(authToken: widget.authToken);
      setState(() {
        _claims = claimsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Claims', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchClaims,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchClaims,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : _claims.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No reimbursement claims submitted yet.', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _claims.length,
                      itemBuilder: (context, index) {
                        final claim = _claims[index];
                        final status = claim['status'] ?? 'Submitted';
                        final requestedInfoNote = claim['requestedInfoNote'] ?? claim['adminNotes'];
                        final rejectionReason = claim['rejectionReason'] ?? claim['adminNotes'];

                        // Status Badge styling
                        Color badgeBg = AppColors.primaryLight;
                        Color badgeBorder = AppColors.primary;
                        Color badgeText = AppColors.primary;

                        if (status == 'Approved') {
                          badgeBg = const Color(0xFFECFDF5);
                          badgeBorder = const Color(0xFFA7F3D0);
                          badgeText = const Color(0xFF047857);
                        } else if (status == 'Rejected') {
                          badgeBg = const Color(0xFFFEF2F2);
                          badgeBorder = const Color(0xFFFECACA);
                          badgeText = const Color(0xFFDC2626);
                        } else if (status == 'Info Requested' || status == 'Action Required') {
                          badgeBg = const Color(0xFFFFF7ED);
                          badgeBorder = const Color(0xFFFFEDD5);
                          badgeText = const Color(0xFFEA580C);
                        } else if (status == 'Reimbursed' || status == 'Paid') {
                          badgeBg = const Color(0xFFEFF6FF);
                          badgeBorder = const Color(0xFFBFDBFE);
                          badgeText = const Color(0xFF1D4ED8);
                        }

                        // BR-14 Timeline progress steps
                        final steps = ['Submitted', 'In Review', 'Approved', 'Reimbursed'];
                        final currentStepIdx = (status == 'Reimbursed' || status == 'Paid')
                            ? 3
                            : (status == 'Approved')
                                ? 2
                                : (status == 'In Review' || status == 'Pending')
                                    ? 1
                                    : 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 0,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        claim['title'] ?? 'Untitled Claim',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: badgeBorder),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: badgeText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${(claim['amount'] ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // BR-14 Visual Lifecycle Timeline
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'BR-14 CLAIM LIFECYCLE TIMELINE',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: List.generate(steps.length, (idx) {
                                          final isDone = idx <= currentStepIdx;
                                          return Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 9,
                                                  backgroundColor: isDone ? AppColors.primary : AppColors.surfaceMuted,
                                                  child: Icon(
                                                    isDone ? Icons.check : Icons.circle,
                                                    size: 10,
                                                    color: isDone ? Colors.white : AppColors.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  steps[idx],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                                                    color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                                                  ),
                                                ),
                                                if (idx < steps.length - 1)
                                                  Expanded(
                                                    child: Container(
                                                      height: 2,
                                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                                      color: isDone && idx < currentStepIdx ? AppColors.primary : AppColors.border,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // BR-13 Reviewer Action Alert Feedback
                                if (status == 'Info Requested' || status == 'Action Required')
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFEDD5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.help_outline, color: Color(0xFFEA580C), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reviewer Requested Info: ${requestedInfoNote ?? "Please clarify claim details."}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (status == 'Rejected')
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Rejection Reason: ${rejectionReason ?? "Policy non-compliance."}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                Row(
                                  children: [
                                    const Icon(Icons.business, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Employer: ${claim['employerName'] ?? 'Unlinked'}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Chip(
                                      label: Text(claim['category'] ?? 'Category'),
                                      backgroundColor: AppColors.surfaceMuted,
                                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Chip(
                                      label: Text(claim['project'] ?? 'Project'),
                                      backgroundColor: AppColors.primaryLight,
                                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Chip(
                                      label: Text(claim['costCenter'] ?? 'Cost Center'),
                                      backgroundColor: AppColors.surfaceMuted,
                                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
