import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/pdf/pdf_preview_screen.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/services/pdf/customer_invoice_pdf_service.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_data_builder.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:clicknow_version2/app/services/pdf/professional_payroll_pdf_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/id_utils/clicknow_id_utils.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RazorpayPaymentService _paymentService = RazorpayPaymentService.instance;
  late final String _targetUserId;
  bool _isReconcilingPayrolls = false;

  @override
  void initState() {
    super.initState();
    final arguments = (Get.arguments as Map?) ?? const <String, dynamic>{};
    _targetUserId = (arguments['targetUserId'] ?? '').toString().trim();
    final tab = (arguments['tab'] ?? '').toString().trim().toLowerCase();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: tab == 'refunds' ? 1 : tab == 'payroll' ? 2 : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateMissingPayrolls(showMessage: false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminPaymentsRoute,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _header(scale),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: const Color(0xffB629FF),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xffB629FF),
                unselectedLabelColor: Colors.black.withValues(alpha: 0.6),
                tabs: const [
                  Tab(text: 'Revenue'),
                  Tab(text: 'Refunds'),
                  Tab(text: 'Payroll'),
                  Tab(text: 'Analytics'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _paymentsTab(scale),
                    _refundsTab(scale),
                    _payrollTab(scale),
                    _analyticsTab(scale),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(8),
        scale.getScaledWidth(12),
        scale.getScaledHeight(12),
      ),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9))),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text(
              'Payments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentsTab(ScalingUtility scale) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection(ServiceCatalogPaths.paymentsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = (snapshot.data?.docs ?? [])
            .where((doc) => _matchesTarget(doc.data()))
            .toList(growable: false);
        final grossBookingValue = docs.fold<int>(
          0,
          (runningTotal, doc) => runningTotal + _finalAmount(doc.data()),
        );
        final totalCollected = docs.fold<int>(
          0,
          (runningTotal, doc) => runningTotal + _collectedAmount(doc.data()),
        );
        final outstanding = docs.fold<int>(
          0,
          (runningTotal, doc) => runningTotal + _outstandingAmount(doc.data()),
        );
        final refunded = docs.fold<int>(
          0,
          (runningTotal, doc) =>
              runningTotal + _asInt(doc.data()['refundedAmount']),
        );
        final paidCount = docs
            .where((doc) => _hasCollectedPayment(doc.data()))
            .length;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length + 5,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _metric(scale, 'Gross Booking Value', grossBookingValue);
            }
            if (index == 1) {
              return _metric(scale, 'Collected Revenue', totalCollected);
            }
            if (index == 2) {
              return _metric(scale, 'Outstanding Revenue', outstanding);
            }
            if (index == 3) {
              return _metric(scale, 'Refunded Revenue', refunded);
            }
            if (index == 4) {
              return _countMetric(scale, 'Paid Transactions', paidCount);
            }
            final paymentDoc = docs[index - 5];
            final data = paymentDoc.data();
            final bookingDocumentId = _firstNonEmpty(<String>[
              _string(data['bookingId']),
              paymentDoc.id,
            ]);
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _db
                  .collection(ServiceCatalogPaths.bookingsCollection)
                  .doc(bookingDocumentId)
                  .get(),
              builder: (context, bookingSnapshot) {
                final idSource = <String, dynamic>{
                  ...data,
                  ...(bookingSnapshot.data?.data() ?? const <String, dynamic>{}),
                };
                final displayBookingId = ClickNowIdUtils.bookingDisplayId(
                  idSource,
                  fallbackDocumentId: bookingDocumentId,
                );
                final orderId = ClickNowIdUtils.paymentOrderDisplayId(data);
                final transactionId =
                    ClickNowIdUtils.transactionDisplayId(data);
                return _card(
                  scale,
                  title: 'Booking ID: $displayBookingId',
                  status: _string(data['paymentStatus']),
                  lines: [
                    'Customer UID: ${_string(data['customerId'])}',
                    'Payment ID: ${ClickNowIdUtils.paymentDisplayId(data, fallbackDocumentId: paymentDoc.id)}',
                    if (orderId.isNotEmpty) 'Payment Order ID: $orderId',
                    'Final Amount: Rs.${_formatAmount(_finalAmount(data))}',
                    'Collected: Rs.${_formatAmount(_collectedAmount(data))}',
                    'Outstanding: Rs.${_formatAmount(_outstandingAmount(data))}',
                    'Method: ${_string(data['paymentMethod'])}',
                    'Gateway: ${_string(data['paymentGateway'])}',
                    if (transactionId.isNotEmpty)
                      'Transaction ID: $transactionId',
                    'Date: ${_formatDate(_asDate(data['paidAt']))}',
                  ],
                  actions: [
                    _actionButton(
                      label: 'View Customer Invoice',
                      onTap: () => _openCustomerInvoice(bookingDocumentId),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _refundsTab(ScalingUtility scale) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _refundPolicyCard(scale),
        ),
        Expanded(
          child: _collectionList(
            collection: ServiceCatalogPaths.refundsCollection,
            itemBuilder: (doc) {
              final data = doc.data();
              final status = _normalizeStatus(data['refundStatus']);
              return _card(
                scale,
                title: 'Booking ID: ${_string(data['bookingId'])}',
                status: status,
                lines: [
                  'Customer: ${_string(data['customerId'])}',
                  'Refund: Rs.${_formatAmount(_asInt(data['refundAmount']))}',
                  'Type: ${_string(data['refundType'])}',
                  'Reason: ${_string(data['refundReason'])}',
                ],
                actions: [
                  if (const <String>{
                    'REQUESTED',
                    'PENDING',
                    'UNDER_REVIEW',
                    'PENDING_MANUAL',
                  }.contains(status))
                    _actionButton(
                      label: 'Approve Refund',
                      onTap: () => _refundAction(doc.id, 'approve'),
                    ),
                  if (const <String>{
                    'REQUESTED',
                    'PENDING',
                    'UNDER_REVIEW',
                    'PENDING_MANUAL',
                  }.contains(status))
                    _actionButton(
                      label: 'Reject Refund',
                      danger: true,
                      onTap: () => _refundAction(doc.id, 'reject'),
                    ),
                  if (const <String>{'APPROVED', 'PROCESSING'}.contains(status))
                    _actionButton(
                      label: 'Mark Completed',
                      onTap: () => _refundAction(doc.id, 'complete'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _payrollTab(ScalingUtility scale) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: _actionButton(
              label: 'Generate Missing Payrolls',
              onTap: _generateMissingPayrolls,
            ),
          ),
        ),
        Expanded(
          child: _collectionList(
            collection: ServiceCatalogPaths.payrollsCollection,
            itemBuilder: (doc) {
              final data = doc.data();
              final status = _normalizeStatus(data['payoutStatus']);
              final confirmationStatus = status == 'RELEASED'
                  ? _normalizeStatus(
                      data['professionalConfirmationStatus'] ?? 'PENDING',
                    )
                  : '';
              final bookingDocumentId = _string(data['bookingId']);
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: bookingDocumentId.isEmpty
                    ? null
                    : _db
                          .collection(ServiceCatalogPaths.bookingsCollection)
                          .doc(bookingDocumentId)
                          .get(),
                builder: (context, bookingSnapshot) {
                  final idSource = <String, dynamic>{
                    ...data,
                    ...(bookingSnapshot.data?.data() ??
                        const <String, dynamic>{}),
                  };
                  return _card(
                    scale,
                    title:
                        'Payroll Slip: ${ClickNowIdUtils.professionalPayrollDisplayId(data, fallbackDocumentId: doc.id)}',
                    status:
                        confirmationStatus == 'DISPUTED' ? 'DISPUTED' : status,
                    lines: [
                      'Professional UID: ${_string(data['professionalId'])}',
                      'Booking ID: ${ClickNowIdUtils.bookingDisplayId(idSource, fallbackDocumentId: bookingDocumentId)}',
                      'Booking Amount: Rs.${_formatAmount(_asInt(data['bookingAmount']))}',
                      'Commission: Rs.${_formatAmount(_asInt(data['commissionAmount']))}',
                      'Net Payout: Rs.${_formatAmount(_asInt(data['netPayoutAmount']))}',
                      'Released: ${_formatDate(_asDate(data['releasedAt']))}',
                      if (confirmationStatus.isNotEmpty)
                        'Professional Confirmation: ${_professionalConfirmationLabel(confirmationStatus)}',
                      if (_string(data['professionalDisputeReason']).isNotEmpty)
                        'Reported Issue: ${_string(data['professionalDisputeReason'])}',
                      if (_asDate(data['professionalDisputedAt']) != null)
                        'Disputed: ${_formatDate(_asDate(data['professionalDisputedAt']))}',
                      if (_string(
                        data['professionalConfirmationComment'],
                      ).isNotEmpty)
                        'Professional Comment: ${_string(data['professionalConfirmationComment'])}',
                    ],
                    actions: [
                      if (status == 'PENDING')
                        _actionButton(
                          label: 'Release Payout',
                          onTap: () => _releasePayout(doc.id),
                        ),
                      if (status == 'RELEASED')
                        _actionButton(
                          label: 'View Stipend Slip',
                          onTap: () => _openStipendSlip(doc.id),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _analyticsTab(ScalingUtility scale) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection(ServiceCatalogPaths.paymentsCollection)
          .snapshots(),
      builder: (context, paymentSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection(ServiceCatalogPaths.refundsCollection)
              .snapshots(),
          builder: (context, refundSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection(ServiceCatalogPaths.payrollsCollection)
                  .snapshots(),
              builder: (context, payrollSnapshot) {
                final payments = paymentSnapshot.data?.docs ?? [];
                final refunds = refundSnapshot.data?.docs ?? [];
                final payrolls = payrollSnapshot.data?.docs ?? [];
                final capturedPayments = payments
                    .where((doc) => _hasCollectedPayment(doc.data()))
                    .toList(growable: false);
                final completedRefunds = refunds
                    .where((doc) {
                      final status = _normalizeStatus(
                        doc.data()['refundStatus'],
                      );
                      return const <String>{
                        'COMPLETED',
                        'REFUNDED',
                        'PROCESSED',
                      }.contains(status);
                    })
                    .toList(growable: false);
                final grossBookingValue = capturedPayments.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _finalAmount(doc.data()),
                );
                final collected = capturedPayments.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _collectedAmount(doc.data()),
                );
                final outstanding = capturedPayments.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _outstandingAmount(doc.data()),
                );
                final refundAmount = completedRefunds.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _asInt(doc.data()['refundAmount']),
                );
                final pendingRefundLiability = refunds
                    .where((doc) {
                      final status = _normalizeStatus(
                        doc.data()['refundStatus'],
                      );
                      return const <String>{
                        'REQUESTED',
                        'APPROVED',
                        'PROCESSING',
                        'UNDER_REVIEW',
                      }.contains(status);
                    })
                    .fold<int>(
                      0,
                      (runningTotal, doc) =>
                          runningTotal + _asInt(doc.data()['refundAmount']),
                    );
                final payouts = payrolls
                    .where(
                      (doc) =>
                          _normalizeStatus(doc.data()['payoutStatus']) ==
                          'RELEASED',
                    )
                    .fold<int>(
                      0,
                      (runningTotal, doc) =>
                          runningTotal + _asInt(doc.data()['netPayoutAmount']),
                    );
                final liability = payrolls
                    .where(
                      (doc) =>
                          _normalizeStatus(doc.data()['payoutStatus']) ==
                          'PENDING',
                    )
                    .fold<int>(
                      0,
                      (runningTotal, doc) =>
                          runningTotal + _asInt(doc.data()['netPayoutAmount']),
                    );
                final commission = payrolls.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _asInt(doc.data()['commissionAmount']),
                );
                final gstLiability = capturedPayments.fold<int>(
                  0,
                  (runningTotal, doc) =>
                      runningTotal + _asInt(doc.data()['gstAmount']),
                );
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _metric(scale, 'Gross Booking Value', grossBookingValue),
                    _metric(scale, 'Collected Revenue', collected),
                    _metric(scale, 'Outstanding Revenue', outstanding),
                    _metric(scale, 'Commission Revenue', commission),
                    _metric(scale, 'Refund Amount', refundAmount),
                    _metric(
                      scale,
                      'Pending Refund Liability',
                      pendingRefundLiability,
                    ),
                    _metric(scale, 'Net Revenue', collected - refundAmount),
                    _metric(scale, 'Released Professional Payouts', payouts),
                    _metric(scale, 'Pending Professional Payout', liability),
                    _metric(scale, 'GST / Tax Liability', gstLiability),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _collectionList({
    required String collection,
    required Widget Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
    itemBuilder,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = (snapshot.data?.docs ?? [])
            .where((doc) => _matchesTarget(doc.data()))
            .toList(growable: false);
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No records found.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => itemBuilder(docs[index]),
        );
      },
    );
  }

  Widget _card(
    ScalingUtility scale, {
    required String title,
    required String status,
    required List<String> lines,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line, style: const TextStyle(color: Colors.black54)),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }

  bool _matchesTarget(Map<String, dynamic> data) {
    if (_targetUserId.isEmpty) return true;
    final nestedCustomer = _asMap(data['customer']);
    return <dynamic>[
      data['customerId'],
      data['userId'],
      data['professionalId'],
      data['assignedProfessionalId'],
      nestedCustomer['id'],
    ].any((value) => _string(value) == _targetUserId);
  }

  Widget _metric(ScalingUtility scale, String label, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black)),
          ),
          Text(
            'Rs.${_formatAmount(value)}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countMetric(ScalingUtility scale, String label, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black)),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _refundPolicyCard(ScalingUtility scale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Refund Policy',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'More than 72 hrs: full refund\nLess than 72 hrs: up to 80% refund\nLess than 48 hrs: up to 50% refund\nLess than 24 hrs: no refund',
            style: TextStyle(color: Colors.black, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffB629FF).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffB629FF)),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: const TextStyle(color: Color(0xffB629FF), fontSize: 12),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: danger ? const Color(0xff3A1220) : const Color(0xff42155E),
        foregroundColor: danger
            ? const Color(0xffFF7B8C)
            : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Future<void> _refundAction(String refundId, String action) async {
    final remarks = await _prompt('Admin remarks');
    final adminId = _auth.currentUser?.uid;
    if (remarks == null || remarks.trim().isEmpty || adminId == null) return;
    try {
      if (action == 'approve') {
        await _paymentService.adminUpdateRefund(
          refundId: refundId,
          action: 'APPROVE',
          remarks: remarks,
        );
      } else if (action == 'reject') {
        await _paymentService.adminUpdateRefund(
          refundId: refundId,
          action: 'REJECT',
          remarks: remarks,
        );
      } else {
        await _paymentService.adminUpdateRefund(
          refundId: refundId,
          action: 'COMPLETE',
          remarks: remarks,
        );
      }
      AppSnackbar.success('Updated', 'Refund record updated.');
    } catch (error) {
      AppSnackbar.error(
        'Failed',
        _errorMessage(error, 'Unable to update refund.'),
      );
    }
  }

  Future<void> _releasePayout(String payrollId) async {
    final reference = await _prompt('Transaction reference');
    final adminId = _auth.currentUser?.uid;
    if (reference == null || reference.trim().isEmpty || adminId == null) {
      return;
    }
    try {
      await _paymentService.releaseProfessionalPayout(
        payrollId: payrollId,
        transactionReference: reference,
      );
      AppSnackbar.success('Released', 'Payout released successfully.');
    } catch (error) {
      AppSnackbar.error(
        'Failed',
        _errorMessage(error, 'Unable to release payout.'),
      );
    }
  }

  Future<void> _generateMissingPayrolls({bool showMessage = true}) async {
    if (_isReconcilingPayrolls) {
      return;
    }
    final adminId = _auth.currentUser?.uid;
    if (adminId == null) {
      if (showMessage) {
        AppSnackbar.error('Login Required', 'Please login again.');
      }
      return;
    }
    _isReconcilingPayrolls = true;
    try {
      final bookings = await _db
          .collection(ServiceCatalogPaths.bookingsCollection)
          .where('status', isEqualTo: 'COMPLETED')
          .get();
      var generated = 0;
      var skippedUnpaid = 0;
      for (final booking in bookings.docs) {
        final payroll = await _db
            .collection(ServiceCatalogPaths.payrollsCollection)
            .doc(booking.id)
            .get();
        if (payroll.exists) {
          continue;
        }
        final payment = await _db
            .collection(ServiceCatalogPaths.paymentsCollection)
            .doc(booking.id)
            .get();
        if (!_isPaymentFullyCollected(
          booking.data(),
          payment.data() ?? const <String, dynamic>{},
        )) {
          skippedUnpaid++;
          continue;
        }
        await _paymentService.reconcileCompletedBookingFinancials(
          bookingId: booking.id,
        );
        generated++;
      }
      if (showMessage) {
        AppSnackbar.success(
          'Payroll Scan Complete',
          generated == 0 && skippedUnpaid == 0
              ? 'No missing payrolls found.'
              : 'Generated $generated record(s). Skipped $skippedUnpaid unpaid booking(s).',
        );
      }
    } catch (error) {
      if (showMessage) {
        AppSnackbar.error(
          'Failed',
          _errorMessage(error, 'Unable to generate missing payrolls.'),
        );
      }
    } finally {
      _isReconcilingPayrolls = false;
    }
  }

  Future<void> _openStipendSlip(String payrollId) async {
    try {
      final slip = await PdfDataBuilder.instance.professionalPayrollForPayroll(
        payrollId: payrollId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: 'Payroll Slip ${slip.payrollId}',
            fileName:
                'ClickNow_Payroll_${PdfFormatters.safeFileName(slip.payrollId)}.pdf',
            buildPdf: () => ProfessionalPayrollPdfService.generate(slip),
          ),
        ),
      );
    } catch (error) {
      AppSnackbar.error(
        'Slip Failed',
        _errorMessage(error, 'Unable to generate stipend slip.'),
      );
    }
  }

  Future<void> _openCustomerInvoice(String bookingId) async {
    if (bookingId.isEmpty) {
      AppSnackbar.error('Missing Booking', 'Booking ID is unavailable.');
      return;
    }
    try {
      final invoice = await PdfDataBuilder.instance.customerInvoiceForBooking(
        bookingId: bookingId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: 'Invoice ${invoice.invoiceNumber}',
            fileName:
                'ClickNow_Invoice_${PdfFormatters.safeFileName(invoice.invoiceNumber)}.pdf',
            buildPdf: () => CustomerInvoicePdfService.generate(invoice),
          ),
        ),
      );
    } catch (error) {
      AppSnackbar.error(
        'Invoice Failed',
        _errorMessage(error, 'Unable to generate invoice.'),
      );
    }
  }

  Future<String?> _prompt(String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter details',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

String _normalizeStatus(dynamic value) => _string(value).toUpperCase();

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

int _finalAmount(Map<String, dynamic> data) {
  final payment = _asMap(data['payment']);
  return _asInt(
    data['finalAmount'],
    fallback: _asInt(
      data['finalPayableAmount'],
      fallback: _asInt(
        payment['finalAmount'],
        fallback: _asInt(data['totalAmount']),
      ),
    ),
  );
}

int _collectedAmount(Map<String, dynamic> data) {
  final payment = _asMap(data['payment']);
  return _asInt(data['paidAmount'], fallback: _asInt(payment['paidAmount']));
}

int _outstandingAmount(Map<String, dynamic> data) {
  return (_finalAmount(data) - _collectedAmount(data))
      .clamp(0, 1 << 31)
      .toInt();
}

bool _hasCollectedPayment(Map<String, dynamic> data) {
  final status = _normalizeStatus(data['paymentStatus']);
  return _collectedAmount(data) > 0 &&
      const <String>{
        'PAID',
        'FULLY_PAID',
        'PARTIALLY_PAID',
        'ADVANCE_PAID',
      }.contains(status);
}

bool _isPaymentFullyCollected(
  Map<String, dynamic> bookingData,
  Map<String, dynamic> paymentData,
) {
  final payment = _asMap(bookingData['payment']);
  final status = _normalizeStatus(
    paymentData['paymentStatus'] ??
        bookingData['paymentStatus'] ??
        payment['status'],
  );
  final finalAmount = _finalAmount(<String, dynamic>{
    ...bookingData,
    ...paymentData,
  });
  final collectedAmount = _collectedAmount(<String, dynamic>{
    ...bookingData,
    ...paymentData,
  });
  return const <String>{'PAID', 'FULLY_PAID'}.contains(status) &&
      finalAmount > 0 &&
      collectedAmount >= finalAmount;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final text = value.trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _errorMessage(Object error, String fallback) {
  if (error is StateError && error.message.isNotEmpty) {
    return error.message;
  }
  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('MMM d, yyyy').format(value);
}

String _professionalConfirmationLabel(String status) {
  switch (status) {
    case 'CONFIRMED':
      return 'Confirmed by Professional';
    case 'DISPUTED':
      return 'Disputed by Professional';
    default:
      return 'Confirmation Pending';
  }
}

String _formatAmount(int value) {
  return NumberFormat.decimalPattern('en_IN').format(value);
}
