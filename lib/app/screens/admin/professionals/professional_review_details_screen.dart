import 'package:clicknow_version2/app/screens/admin/professionals/getx/admin_professionals_controller.dart';
import 'package:clicknow_version2/app/screens/admin/professionals/models/admin_professional_profile.dart';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/shared/admin_user_summary.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalReviewDetailsScreen extends StatefulWidget {
  const ProfessionalReviewDetailsScreen({super.key, required this.professionalId,});

  final String professionalId;

  @override
  State<ProfessionalReviewDetailsScreen> createState() => _ProfessionalReviewDetailsScreenState();
}

class _ProfessionalReviewDetailsScreenState extends State<ProfessionalReviewDetailsScreen> {
  late final AdminProfessionalsController controller;

  final Map<String, bool> expandedSections = {
    'basic': true,
    'personal': false,
    'profile': false,
    'legal': false,
    'services': false,
    'questions': false,
    'financial': false,
    'decision': false,
    'actions': true,
  };

  @override
  void initState() {
    super.initState();
    controller = Get.find<AdminProfessionalsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('professional_profiles').doc(widget.professionalId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
        
            final doc = snapshot.data;
            if (doc == null || !doc.exists) {
              return const Center(
                child: Text('Professional not found', style: TextStyle(color: Colors.black),),
              );
            }
        
            final profile = AdminProfessionalProfile.fromDocument(doc);
            final statusStyle = _statusStyle(profile.accountStatus);
        
            return Column(
              children: [
                _topHeader(profile, statusStyle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveUtility.only(left: 12, top: 12, right: 12, bottom: 16),
                    child: Column(
                      children: [
                        _basicVerificationCard(profile, statusStyle),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _personalDetailsCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _professionalProfileCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _legalCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _servicesCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _questionsCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _financialCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _reviewDecisionCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _summaryCard(profile),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _adminActionsCard(profile),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topHeader(AdminProfessionalProfile profile, _LabelStyle statusStyle) {
    return Container(
      padding: ResponsiveUtility.only(left: 10, top: 60, bottom: 10, right: 10),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            splashRadius: 20,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22,),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Professionals Details", style: TextStyle(color: Colors.white, fontSize: ResponsiveUtility.fontSize(16), fontWeight: FontWeight.w700,),),
                Text("ID: ${_displayProfessionalId(profile.uid)}", style: TextStyle(color: Colors.white.withValues(alpha: 0.56), fontSize: ResponsiveUtility.fontSize(12),),),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusStyle.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusStyle.color.withValues(alpha: 0.64),),
            ),
            child: Text(statusStyle.label, style: TextStyle(color: statusStyle.color, fontSize: ResponsiveUtility.fontSize(12), fontWeight: FontWeight.w600,),),
          ),
        ],
      ),
    );
  }

  Widget _basicVerificationCard(
    AdminProfessionalProfile profile,
    _LabelStyle statusStyle,
  ) {
    return _collapsibleCard(
      keyName: 'basic',
      icon: Icons.phone_rounded,
      title: "Basic Verification",
      subtitle: "Phone Verification status",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dualRow(
            leftTitle: "Phone Number",
            leftValue: _v(profile.phoneNumber),
            rightTitle: "OTP Status",
            rightValueWidget: _pillText("Verified", const Color(0xff0CDB6D)),
          ),
          const SizedBox(height: 10),
          _singleField("Professional ID", _displayProfessionalId(profile.uid)),
        ],
      ),
    );
  }

  Widget _personalDetailsCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'personal',
      icon: Icons.person_outline_rounded,
      title: "Personal Details",
      subtitle: "identity and address information",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dualRow(
            leftTitle: "Full Name",
            leftValue: profile.fullName,
            rightTitle: "Gender",
            rightValue: _v(profile.gender),
          ),
          const SizedBox(height: 10),
          _dualRow(
            leftTitle: "Date of birth",
            leftValue: _formatDate(profile.dob),
            rightTitle: "PIN CODE",
            rightValue: _v(profile.pincode),
          ),
          const SizedBox(height: 10),
          _singleField("Permanent Address", _v(profile.permanentAddress)),
          const SizedBox(height: 10),
          _singleField("Languages Known", ''),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.languages.isEmpty
                  ? [_chip("-", const Color(0xff313A5A))]
                  : profile.languages
                        .map((lang) => _chip(lang, const Color(0xff313A5A)))
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _professionalProfileCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'profile',
      icon: Icons.work_outline_rounded,
      title: "Professional Profile",
      subtitle: "work experience & portfolio",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dualRow(
            leftTitle: "Experience",
            leftValue: _experienceLabel(profile.experienceYears),
            rightTitle: "Company or Brand Name",
            rightValue: _v(profile.companyName),
          ),
          const SizedBox(height: 10),
          _locationBlock("Primary Working Locations", profile.primaryLocations),
          const SizedBox(height: 10),
          _locationBlock(
            "Secondary Working Locations",
            profile.secondaryLocations,
          ),
          const SizedBox(height: 10),
          _singleField("Available working days", ''),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.workingDays.isEmpty
                  ? [_chip("-", const Color(0xff313A5A))]
                  : profile.workingDays
                        .map((day) => _chip(day, const Color(0xff313A5A)))
                        .toList(),
            ),
          ),
          const SizedBox(height: 10),
          _singleField("Short Bio", _v(profile.shortBio), multiline: true),
          const SizedBox(height: 10),
          _singleField("Portfolio Links", ''),
          const SizedBox(height: 6),
          _linkRow("Google Drive Portfolio", profile.googleDriveUrl),
          _linkRow("Instagram Profile", profile.instagramUrl),
          _linkRow("Personal Website", profile.websiteUrl),
          const SizedBox(height: 10),
          _singleField("Past client experience", _v(profile.clientExperience)),
          const SizedBox(height: 10),
          _singleField("Awards & Achievements", _v(profile.awards)),
        ],
      ),
    );
  }

  Widget _legalCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'legal',
      icon: Icons.verified_user_outlined,
      title: "Legal & Identity Verification",
      subtitle: "Government ID & document verification",
      child: Column(
        children: [
          _dualRow(
            leftTitle: "Aadhar Number",
            leftValue: _v(profile.aadhaarNumber),
            rightTitle: "Pan Number",
            rightValue: _v(profile.panNumber),
          ),
          const SizedBox(height: 10),
          _documentActionRow("PAN Card", profile.panUrl),
          const SizedBox(height: 8),
          _documentActionRow("Aadhar Card", profile.aadhaarUrl),
        ],
      ),
    );
  }

  Widget _servicesCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'services',
      icon: Icons.miscellaneous_services_rounded,
      title: "Services Details",
      subtitle: "service offerings & specifications.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _singleField("Service Type", _shortServiceName(profile.serviceType)),
          const SizedBox(height: 10),
          _singleField("Speciality or Event Type", ''),
          const SizedBox(height: 4),
          if (profile.serviceSpecialities.isEmpty)
            _bullet("-")
          else
            ...profile.serviceSpecialities.map((item) => _bullet(item)),
          const SizedBox(height: 10),
          _statusInfoCard(
            title: "Available for urgent bookings",
            subtitle: "Last-minute requests within 24 hours",
            label: profile.urgentBookingAvailable ? "Available" : "Unavailable",
            color: profile.urgentBookingAvailable
                ? const Color(0xff0CDB6D)
                : const Color(0xffFFB300),
          ),
          const SizedBox(height: 8),
          _statusInfoCard(
            title: "Willing to travel outside city",
            subtitle: "For additional charges",
            label: profile.willingToTravel ? "Agreed" : "Not Agreed",
            color: profile.willingToTravel
                ? const Color(0xff0CDB6D)
                : const Color(0xffFFB300),
          ),
          const SizedBox(height: 8),
          _statusInfoCard(
            title: "Cancellation Policy",
            subtitle: "I agree to the platform's cancellation policy",
            label: profile.cancellationPolicyAccepted ? "Accepted" : "Pending",
            color: profile.cancellationPolicyAccepted
                ? const Color(0xff0CDB6D)
                : const Color(0xffFFB300),
          ),
          const SizedBox(height: 8),
          _statusInfoCard(
            title: "Platform Commission Agreement",
            subtitle: "I agree to the 15% platform commission on bookings.",
            label: profile.platformCommissionAccepted ? "Agreed" : "Pending",
            color: profile.platformCommissionAccepted
                ? const Color(0xff0CDB6D)
                : const Color(0xffFFB300),
          ),
        ],
      ),
    );
  }

  Widget _questionsCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'questions',
      icon: Icons.help_outline_rounded,
      title: "Services Specific Questions",
      subtitle: "Additional service details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.questionnaire.isEmpty)
            Text(
              "No service-specific answers available.",
              style: TextStyle(color: Colors.black, fontSize: ResponsiveUtility.fontSize(12)),
            )
          else
            ...profile.questionnaire.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final qa = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: ResponsiveUtility.fontSize(12),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: "$index. ${qa.question}\n"),
                      TextSpan(
                        text: "   ${_v(qa.answer)}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _financialCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'financial',
      icon: Icons.account_balance_wallet_outlined,
      title: "Financial Details",
      subtitle: "Bank account and payment information",
      child: Column(
        children: [
          _dualRow(
            leftTitle: "Account holder",
            leftValue: _v(profile.accountHolderName),
            rightTitle: "Account number",
            rightValue: _v(profile.accountNumber),
          ),
          const SizedBox(height: 10),
          _dualRow(
            leftTitle: "Bank Name",
            leftValue: _v(profile.bankName),
            rightTitle: "Branch",
            rightValue: _v(profile.branchName),
          ),
          const SizedBox(height: 10),
          _dualRow(
            leftTitle: "IFSC Code",
            leftValue: _v(profile.ifscCode),
            rightTitle: "UPI ID",
            rightValue: _v(profile.upiId),
          ),
          const SizedBox(height: 10),
          _documentActionRow("Bank Passbook", profile.bankPassbookUrl),
        ],
      ),
    );
  }

  Widget _reviewDecisionCard(AdminProfessionalProfile profile) {
    if (!const <String>{
      'PENDING',
      'UNDER_REVIEW',
      'PROFILE_SUBMITTED',
      'SUBMITTED',
      'REUPLOAD_REQUESTED',
      'REUPLOAD_REQUIRED',
      'REJECTED',
      'PHONE_VERIFIED',
    }.contains(profile.approvalStatus)) {
      return const SizedBox.shrink();
    }
    return _collapsibleCard(
      keyName: 'decision',
      icon: Icons.rule_folder_outlined,
      title: "Review Decision",
      subtitle: "Take action on this professional application",
      child: Obx(() {
        final approveLoading = controller.isActionLoading(
          profile.uid,
          action: AdminProfessionalAction.approve,
        );
        final rejectLoading = controller.isActionLoading(
          profile.uid,
          action: AdminProfessionalAction.reject,
        );
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 210,
              child: _decisionButton(
                label: "Approve\nApplication",
                color: const Color(0xff00E47C),
                loading: approveLoading,
                enabled: true,
                onPressed: () async {
                  final approvedType = await _askType(context);
                  if (approvedType == null) return;
                  await controller.approveProfessional(
                    profile: profile,
                    professionalType: approvedType.type,
                    comment: approvedType.comment,
                  );
                },
              ),
            ),
            SizedBox(
              width: 210,
              child: _decisionButton(
                label: "Reject\nApplication",
                color: const Color(0xffFF6A6A),
                loading: rejectLoading,
                enabled: true,
                onPressed: () async {
                  final comment = await _askComment(
                    context,
                    'Reject Professional',
                    'Add rejection reason',
                  );
                  if (comment == null) return;
                  await controller.rejectProfessional(
                    profile: profile,
                    comment: comment,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _adminActionsCard(AdminProfessionalProfile profile) {
    final hasAccountRestriction =
        profile.accountStatus == 'SUSPENDED' ||
        profile.accountStatus == 'BLOCKED';
    if (!hasAccountRestriction &&
        const <String>{
          'PENDING',
          'UNDER_REVIEW',
          'PROFILE_SUBMITTED',
          'SUBMITTED',
          'REUPLOAD_REQUESTED',
          'REUPLOAD_REQUIRED',
          'REJECTED',
          'PHONE_VERIFIED',
        }.contains(profile.approvalStatus)) {
      return const SizedBox.shrink();
    }
    return _collapsibleCard(
      keyName: 'actions',
      icon: Icons.admin_panel_settings_outlined,
      title: 'Professional Actions',
      subtitle: 'Account control and related records',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_professionalAccountActions(profile).isNotEmpty) ...[
            _actionGroup(
              'Account Control',
              _professionalAccountActions(profile),
            ),
            const SizedBox(height: 14),
          ],
          _actionGroup('Related Records', <Widget>[
            _routeAction(
              'View Professional Bookings',
              Icons.event_note_outlined,
              AppRoutes.adminBookingsRoute,
              profile.uid,
            ),
            _routeAction(
              'View Support Tickets',
              Icons.support_agent,
              AppRoutes.adminSupportDisputesRoute,
              profile.uid,
            ),
          ]),
          if (profile.suspensionReason.isNotEmpty ||
              profile.blockedReason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              profile.accountStatus == 'BLOCKED'
                  ? 'Blocked reason: ${profile.blockedReason}'
                  : 'Suspension reason: ${profile.suspensionReason}',
              style: const TextStyle(color: Color(0xffFFB347), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _professionalAccountActions(AdminProfessionalProfile profile) {
    if (profile.accountStatus == 'BLOCKED') {
      return <Widget>[
        _professionalActionButton(
          profile,
          AdminProfessionalAction.unblock,
          'Unblock / Reactivate Professional',
          Icons.lock_open_rounded,
          const Color(0xff20C777),
          () => _confirmProfessionalAction(
            profile,
            AdminProfessionalAction.unblock,
            'Unblock Professional',
            'Unblock and restore access for this professional?',
          ),
        ),
      ];
    }
    if (profile.accountStatus == 'SUSPENDED') {
      return <Widget>[
        _professionalActionButton(
          profile,
          AdminProfessionalAction.reactivate,
          'Reactivate Professional',
          Icons.play_circle_outline,
          const Color(0xff20C777),
          () => _confirmProfessionalAction(
            profile,
            AdminProfessionalAction.reactivate,
            'Reactivate Professional',
            'Restore this professional account?',
          ),
        ),
        _professionalActionButton(
          profile,
          AdminProfessionalAction.block,
          'Block Professional',
          Icons.block,
          const Color(0xffFF5B65),
          () => _reasonProfessionalAction(
            profile,
            AdminProfessionalAction.block,
            'Block Professional',
          ),
        ),
      ];
    }
    return <Widget>[
      _professionalActionButton(
        profile,
        AdminProfessionalAction.suspend,
        'Suspend Professional',
        Icons.pause_circle_outline,
        const Color(0xffF39A32),
        () => _reasonProfessionalAction(
          profile,
          AdminProfessionalAction.suspend,
          'Suspend Professional',
        ),
      ),
      _professionalActionButton(
        profile,
        AdminProfessionalAction.block,
        'Block Professional',
        Icons.block,
        const Color(0xffFF5B65),
        () => _reasonProfessionalAction(
          profile,
          AdminProfessionalAction.block,
          'Block Professional',
        ),
      ),
    ];
  }

  Widget _summaryCard(AdminProfessionalProfile profile) {
    return _collapsibleCard(
      keyName: 'summary',
      icon: Icons.analytics_outlined,
      title: 'Activity Summary',
      subtitle: 'Booking and support context at a glance',
      child: FutureBuilder<AdminUserSummary>(
        future: AdminUserSummaryService.instance.load(
          userId: profile.uid,
          role: 'professional',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data;
          if (summary == null) {
            return const Text(
              'Summary is temporarily unavailable.',
              style: TextStyle(color: Colors.white60),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryMetric('Bookings', summary.totalBookings),
              _summaryMetric('Active', summary.activeBookings),
              _summaryMetric('Completed', summary.completedBookings),
              _summaryMetric('Open Tickets', summary.openSupportTickets),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryMetric(String label, int value) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: Colors.black,
              fontSize: ResponsiveUtility.fontSize(18),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: ResponsiveUtility.fontSize(12)),
          ),
        ],
      ),
    );
  }

  Widget _actionGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }

  Widget _professionalActionButton(
    AdminProfessionalProfile profile,
    AdminProfessionalAction action,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Obx(() {
      final loading = controller.isActionLoading(profile.uid, action: action);
      return SizedBox(
        width: 230,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? SizedBox(
                  height: 17,
                  width: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 19),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: color.withValues(alpha: 0.55)),
          ),
        ),
      );
    });
  }

  Widget _routeAction(
    String label,
    IconData icon,
    String route,
    String uid, {
    String? tab,
  }) {
    return SizedBox(
      width: 230,
      child: OutlinedButton.icon(
        onPressed: () => Get.toNamed(
          route,
          arguments: <String, dynamic>{
            'targetUserId': uid,
            if (tab != null) 'tab': tab,
          },
        ),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xffBCA7FF),
          minimumSize: const Size.fromHeight(46),
        ),
      ),
    );
  }

  Future<void> _reasonProfessionalAction(
    AdminProfessionalProfile profile,
    AdminProfessionalAction action,
    String title,
  ) async {
    final reason = await _askComment(context, title, 'Mandatory reason');
    if (reason == null || reason.trim().isEmpty) return;
    await controller.manageProfessional(
      profile: profile,
      action: action,
      reason: reason,
    );
  }

  Future<void> _confirmProfessionalAction(
    AdminProfessionalProfile profile,
    AdminProfessionalAction action,
    String title,
    String message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      await controller.manageProfessional(profile: profile, action: action);
    }
  }

  Widget _collapsibleCard({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final expanded = expandedSections[keyName] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() => expandedSections[keyName] = !expanded);
            },
            child: Padding(
              padding: ResponsiveUtility.all(8),
              child: Row(
                children: [
                  Container(
                    height: ResponsiveUtility.height(24),
                    width: ResponsiveUtility.width(24),
                    decoration: BoxDecoration(
                      color: const Color(0xff68A0FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: const Color(0xff155DFC), size: 15),
                  ),
                  SizedBox(width: ResponsiveUtility.width(8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: ResponsiveUtility.fontSize(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff7D80A7),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) Container(height: 1, color: const Color(0xffD9D9D9)),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _dualRow({
    required String leftTitle,
    required String leftValue,
    required String rightTitle,
    String? rightValue,
    Widget? rightValueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _singleField(leftTitle, leftValue)),
        SizedBox(width: ResponsiveUtility.width(10)),
        Expanded(
          child: rightValueWidget != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rightTitle,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtility.height(2)),
                    rightValueWidget,
                  ],
                )
              : _singleField(rightTitle, rightValue ?? '-', alignStart: false),
        ),
      ],
    );
  }

  Widget _singleField(
    String title,
    String value, {
    bool multiline = false,
    bool alignStart = true,
  }) {
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.45),
            fontSize: ResponsiveUtility.fontSize(12),
          ),
        ),
        if (value.isNotEmpty) SizedBox(height: ResponsiveUtility.height(2)),
        if (value.isNotEmpty)
          Text(
            value,
            maxLines: multiline ? null : 3,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: ResponsiveUtility.fontSize(14),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _locationBlock(String title, List<AdminWorkingLocation> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        if (locations.isEmpty)
          const Text("-", style: TextStyle(color: Colors.black, fontSize: 13))
        else
          ...locations.map((location) {
            return Text(
              "- ${location.state} : ${location.cities.join(', ')}.",
              style: const TextStyle(color: Colors.black, fontSize: 13),
            );
          }),
      ],
    );
  }

  Widget _linkRow(String label, String url) {
    final valid = _v(url) != '-';
    return InkWell(
      onTap: valid ? () => _previewDocument(url) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.link, color: Color(0xff7D70FF), size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: valid ? Colors.black : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: valid ? Colors.black : Colors.black54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentActionRow(String title, String url) {
    final hasUrl = _v(url) != '-';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xff1F2A58),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.link,
              size: 14,
              color: Color(0xff68A0FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: hasUrl ? () => _previewDocument(url) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff3A1A57),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              child: const Text(
                "Preview",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: hasUrl ? () => _downloadDocument(url) : null,
            icon: const Icon(
              Icons.download_rounded,
              color: Color(0xff7A7FAE),
              size: 20,
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(30, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusInfoCard({
    required String title,
    required String subtitle,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: ResponsiveUtility.fontSize(12.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.45),
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
              ],
            ),
          ),
          _pillText(label, color),
        ],
      ),
    );
  }

  Widget _pillText(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.58)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 14),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        "- $text",
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
    );
  }

  Widget _decisionButton({
    required String label,
    required Color color,
    required bool loading,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: loading || !enabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: loading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
      ),
    );
  }

  Future<void> _previewDocument(String value) async {
    await _openDocument(value, external: false);
  }

  Future<void> _downloadDocument(String value) async {
    await _openDocument(value, external: true);
  }

  Future<void> _openDocument(String value, {required bool external}) async {
    final raw = value.trim();
    if (raw.isEmpty || raw == '-') {
      AppSnackbar.error('Missing File', 'Document URL is unavailable.');
      return;
    }

    Uri? uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$raw');
    }

    if (uri == null) {
      AppSnackbar.error('Invalid URL', 'Could not open this document.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
    );

    if (!launched) {
      AppSnackbar.error('Open Failed', 'Unable to open document right now.');
    }
  }

  Future<_ApprovalTypeInput?> _askType(BuildContext context) async {
    String selected = 'normal';
    final commentController = TextEditingController();
    try {
      final result = await showDialog<_ApprovalTypeInput>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xff171129),
            title: const Text(
              'Approve Professional',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (value) {
                      setDialogState(() => selected = value ?? 'normal');
                    },
                    child: Column(
                      children: const [
                        RadioListTile<String>(
                          value: 'normal',
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Color(0xff7D70FF),
                          title: Text(
                            'Normal',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        RadioListTile<String>(
                          value: 'pro',
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Color(0xff7D70FF),
                          title: Text(
                            'Pro',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    minLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Optional comment',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xff100C1F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  _ApprovalTypeInput(
                    type: selected,
                    comment: commentController.text.trim(),
                  ),
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
        ),
      );
      return result;
    } finally {
      commentController.dispose();
    }
  }

  Future<String?> _askComment(
    BuildContext context,
    String title,
    String hint,
  ) async {
    final textController = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xff171129),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: TextField(
              controller: textController,
              maxLines: 4,
              minLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xff100C1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isEmpty) {
                  AppSnackbar.error('Comment Required', 'Please add comment.');
                  return;
                }
                Navigator.pop(context, text);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      return value;
    } finally {
      textController.dispose();
    }
  }

  _LabelStyle _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const _LabelStyle(label: 'Active', color: Color(0xff0CDB6D));
      case 'BLOCKED':
        return const _LabelStyle(label: 'Blocked', color: Color(0xffFF001A));
      case 'SUSPENDED':
        return const _LabelStyle(label: 'Suspended', color: Color(0xffFF8A00));
    }
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return const _LabelStyle(label: 'Verified', color: Color(0xff0CDB6D));
      case 'online':
      case 'active':
      case 'available':
        return const _LabelStyle(label: 'Online', color: Color(0xff5D5CFF));
      case 'working':
      case 'on_ground':
      case 'in_service':
        return const _LabelStyle(label: 'Working', color: Color(0xffB533FF));
      case 'suspended':
        return const _LabelStyle(label: 'Suspended', color: Color(0xffFF001A));
      default:
        return const _LabelStyle(label: 'Pending', color: Color(0xffFFB300));
    }
  }

  String _v(String value) => value.trim().isEmpty ? '-' : value.trim();

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _displayProfessionalId(String uid) {
    final cleaned = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return 'PR000000';
    final suffix = cleaned.length > 6
        ? cleaned.substring(cleaned.length - 6)
        : cleaned.padLeft(6, '0');
    return 'PR$suffix';
  }

  String _shortServiceName(String service) {
    final value = service.trim();
    if (value.isEmpty) return '-';
    final lower = value.toLowerCase();
    if (lower.contains('photo')) return 'Photo & Videography';
    if (lower.contains('music')) return 'Music & Live Performance';
    if (lower.contains('anchor')) return 'Professional Anchor Services';
    if (lower.contains('dj')) return 'Professional DJ Services';
    if (lower.contains('magician')) return 'Professional Magician Services';
    if (lower.contains('wedding')) return 'Wedding Planner Services';
    return value;
  }

  String _experienceLabel(int years) {
    if (years <= 0) return '-';
    return '$years Years';
  }
}

class _LabelStyle {
  const _LabelStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

class _ApprovalTypeInput {
  const _ApprovalTypeInput({required this.type, required this.comment});

  final String type;
  final String comment;
}
