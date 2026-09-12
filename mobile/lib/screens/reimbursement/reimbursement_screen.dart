import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/fintrack_header.dart';
import '../../services/session_service.dart';
import '../../services/claim_service.dart';
import 'claim_form_screen.dart';
import 'my_claims_screen.dart';

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
  // Real JWT from SessionService singleton — no hardcoded tokens
  String get _authToken => SessionService().token ?? '';

  bool _isLoading = true;
  List<dynamic> _claims = [];
  Map<String, double> _metrics = {
    'pending': 0,
    'inReview': 0,
    'approved': 0,
    'rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    if (_authToken.isEmpty) return;
    try {
      final claims = await ClaimService().getMyClaims(authToken: _authToken);
      double pending = 0, inReview = 0, approved = 0, rejected = 0;
      for (final c in claims) {
        final amt = (c['amount'] as num?)?.toDouble() ?? 0;
        switch (c['status']) {
          case 'Submitted':
            pending += amt;
            break;
          case 'In Review':
            inReview += amt;
            break;
          case 'Approved':
          case 'Reimbursed':
            approved += amt;
            break;
          case 'Rejected':
            rejected += amt;
            break;
        }
      }
      if (mounted) {
        setState(() {
          _claims = claims;
          _metrics = {
            'pending': pending,
            'inReview': inReview,
            'approved': approved,
            'rejected': rejected,
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openClaimForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClaimFormScreen(authToken: _authToken)),
    ).then((_) => _loadClaims());
  }

  void _openMyClaims() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyClaimsScreen(authToken: _authToken)),
    ).then((_) => _loadClaims());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const FinTrackHeader(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_reimbursement_claim',
        onPressed: _openClaimForm,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_a_photo, color: Colors.black),
        label: const Text('Submit Claim', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            // Top Badge and Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POLICY COMPLIANT',
                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Syncing Workday', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Corporate\nReimbursements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Quick Actions Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openClaimForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                    label: const Text('Scan & Submit Claim', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _openMyClaims,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('My Claims'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 Metrics Grid
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openMyClaims,
                    child: _buildMetricCard(
                      title: 'Pending Claim',
                      amount: '₹${(_metrics['pending'] ?? 0).toStringAsFixed(0)}',
                      subtitle: 'Tap to view claims',
                      icon: Icons.access_time_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openMyClaims,
                    child: _buildMetricCard(
                      title: 'In Review',
                      amount: '₹${(_metrics['inReview'] ?? 0).toStringAsFixed(0)}',
                      subtitle: 'Claims under audit',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Approved',
                    amount: '₹${(_metrics['approved'] ?? 0).toStringAsFixed(0)}',
                    subtitle: 'Approved for payout',
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Rejected',
                    amount: '₹${(_metrics['rejected'] ?? 0).toStringAsFixed(0)}',
                    subtitle: 'Rejected claims',
                    icon: Icons.check_circle_outline,
                    iconColor: (_metrics['rejected'] ?? 0) > 0 ? AppColors.red : AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instant Receipt Recognition Card (PROPRIETARY FINOCR V3.2)
            Container(
              padding: const EdgeInsets.all(18),
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
                    children: const [
                      Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'PROPRIETARY FINOCR V3.2',
                        style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Instant Receipt Recognition', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'Autodetects GSTIN, invoice date, split totals, tax deductions, and auto-tags internal corporate cost codes.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTagPill('Merchant OCR: 99.8%'),
                      _buildTagPill('GST Auto-Validation'),
                      _buildTagPill('Audit Proof'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.black),
                    label: const Text('Scan & Submit Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                    onPressed: _openClaimForm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Claims Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Active Claims', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${_claims.length} Active',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _openMyClaims,
                  child: const Text('View Ledger', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_claims.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    const Text(
                      'No Reimbursement Claims Yet',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan a corporate bill or receipt to submit your first claim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openClaimForm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                      label: const Text('Scan Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._claims.map((c) {
                final merchant = (c['merchantName'] ?? c['category'] ?? 'Corporate Expense').toString();
                final category = (c['category'] ?? 'General').toString();
                final claimId = '#CLM-${c['id'] ?? (c['_id'] != null ? c['_id'].toString().substring(0, 6) : '0000')}';
                final amount = '₹${(c['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}';
                final status = (c['status'] ?? 'Submitted').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActiveClaimCard(
                    icon: Icons.receipt_rounded,
                    merchant: merchant,
                    sub: '$category • Status: $status',
                    claimId: claimId,
                    amount: amount,
                    gst: 'Audit Checked',
                    tags: 'Status: $status',
                    date: 'Live Claim',
                    hasAuditProgress: status == 'In Review' || status == 'Submitted',
                    approvalNote: status == 'Approved' ? 'Approved by Finance' : null,
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActiveClaimCard({
    required IconData icon,
    required String merchant,
    required String sub,
    required String claimId,
    required String amount,
    required String gst,
    required String tags,
    required String date,
    required bool hasAuditProgress,
    String? approvalNote,
    String? payoutNote,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchant, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(gst, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tags, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
