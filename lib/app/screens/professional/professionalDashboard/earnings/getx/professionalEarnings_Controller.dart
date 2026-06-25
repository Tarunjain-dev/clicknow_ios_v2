// ignore_for_file: file_names

import 'dart:async';

import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfessionalEarningsMonthlyOverview {
  const ProfessionalEarningsMonthlyOverview({
    required this.year,
    required this.month,
    required this.label,
    required this.earnings,
  });

  final int year;
  final int month;
  final String label;
  final double earnings;
}

class ProfessionalPaymentHistoryItem {
  const ProfessionalPaymentHistoryItem({
    required this.payrollId,
    required this.bookingId,
    required this.status,
    required this.eventDate,
    required this.bookingAmount,
    required this.netAmount,
    required this.transactionId,
    required this.payoutDate,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.gstAmount,
    required this.otherCharges,
    required this.stipendPdfUrl,
    required this.professionalConfirmationStatus,
    required this.professionalConfirmationComment,
    required this.professionalDisputeReason,
    required this.professionalConfirmedAt,
    required this.professionalDisputedAt,
  });

  final String payrollId;
  final String bookingId;
  final String status;
  final DateTime? eventDate;
  final int bookingAmount;
  final int netAmount;
  final String transactionId;
  final DateTime? payoutDate;
  final num commissionPercent;
  final int commissionAmount;
  final int gstAmount;
  final int otherCharges;
  final String stipendPdfUrl;
  final String professionalConfirmationStatus;
  final String professionalConfirmationComment;
  final String professionalDisputeReason;
  final DateTime? professionalConfirmedAt;
  final DateTime? professionalDisputedAt;
}

class ProfessionalEarningsController extends GetxController {
  static ProfessionalEarningsController get instance {
    if (Get.isRegistered<ProfessionalEarningsController>()) {
      return Get.find<ProfessionalEarningsController>();
    }
    return Get.put(ProfessionalEarningsController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RazorpayPaymentService _paymentService =
      RazorpayPaymentService.instance;

  final RxBool isLoading = true.obs;
  final RxInt totalRevenue = 0.obs;
  final RxInt monthlyRevenue = 0.obs;
  final RxInt pendingPayout = 0.obs;
  final RxInt settledAmount = 0.obs;
  final RxList<ProfessionalEarningsMonthlyOverview> monthlyOverview =
      <ProfessionalEarningsMonthlyOverview>[].obs;
  final Rx<DateTime> chartEndMonth =
      DateTime(DateTime.now().year, DateTime.now().month).obs;
  final RxList<ProfessionalPaymentHistoryItem> paymentHistory =
      <ProfessionalPaymentHistoryItem>[].obs;
  final RxSet<String> payoutActionsInProgress = <String>{}.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _payrollSub;

  void showPreviousChartMonths() {
    chartEndMonth.value = DateTime(
      chartEndMonth.value.year,
      chartEndMonth.value.month - 12,
    );
    _recalculate(paymentHistory.toList(growable: false));
  }

  void showNextChartMonths() {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    final next = DateTime(
      chartEndMonth.value.year,
      chartEndMonth.value.month + 12,
    );
    chartEndMonth.value = next.isAfter(current) ? current : next;
    _recalculate(paymentHistory.toList(growable: false));
  }

  bool get canShowNextChartMonths {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    return chartEndMonth.value.isBefore(current);
  }

  @override
  void onInit() {
    super.onInit();
    _bindPayrolls();
  }

  void _bindPayrolls() {
    final professionalId = _auth.currentUser?.uid;
    if (professionalId == null) {
      isLoading.value = false;
      return;
    }
    _payrollSub?.cancel();
    _payrollSub = _db
        .collection(ServiceCatalogPaths.payrollsCollection)
        .where('professionalId', isEqualTo: professionalId)
        .snapshots()
        .listen(
          (snapshot) async {
            final items = await Future.wait(
              snapshot.docs.map(_historyItemFromDoc),
            );
            items.sort((left, right) {
              final a =
                  left.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              final b =
                  right.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              return b.compareTo(a);
            });
            paymentHistory.assignAll(items);
            _recalculate(items);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
          },
        );
  }

  void _recalculate(List<ProfessionalPaymentHistoryItem> items) {
    final now = DateTime.now();
    final releasedItems = items
        .where((item) => item.status.toUpperCase() == 'RELEASED')
        .toList(growable: false);
    totalRevenue.value = items.fold<int>(
      0,
      (runningTotal, item) =>
          runningTotal +
          (item.status.toUpperCase() == 'RELEASED' ? item.netAmount : 0),
    );
    monthlyRevenue.value = releasedItems
        .where(
          (item) =>
              item.eventDate != null &&
              item.eventDate!.month == now.month &&
              item.eventDate!.year == now.year,
        )
        .fold<int>(
          0,
          (runningTotal, item) => runningTotal + item.netAmount,
        );
    pendingPayout.value = items
        .where((item) => item.status.toUpperCase() == 'PENDING')
        .fold<int>(0, (runningTotal, item) => runningTotal + item.netAmount);
    settledAmount.value = items
        .where((item) => item.status.toUpperCase() == 'RELEASED')
        .fold<int>(0, (runningTotal, item) => runningTotal + item.netAmount);

    final buckets = _emptyMonthlyBuckets(chartEndMonth.value);
    for (final item in releasedItems) {
      final date = item.eventDate;
      if (date == null) continue;
      final key = _monthKey(date);
      if (!buckets.containsKey(key)) continue;
      final current = buckets[key]!;
      buckets[key] = ProfessionalEarningsMonthlyOverview(
        year: current.year,
        month: current.month,
        label: current.label,
        earnings: current.earnings + item.netAmount,
      );
    }
    monthlyOverview.assignAll(buckets.values.toList(growable: false));
  }

  Future<ProfessionalPaymentHistoryItem> _historyItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final bookingDocumentId = _string(data['bookingId']);
    var bookingCode = _string(data['bookingCode']);
    if (bookingCode.isEmpty && bookingDocumentId.isNotEmpty) {
      try {
        final bookingSnapshot = await _db
            .collection(ServiceCatalogPaths.bookingsCollection)
            .doc(bookingDocumentId)
            .get();
        bookingCode = _string(bookingSnapshot.data()?['bookingCode']);
      } catch (_) {
        bookingCode = '';
      }
    }
    return ProfessionalPaymentHistoryItem(
      payrollId: doc.id,
      bookingId: bookingCode.isEmpty ? bookingDocumentId : bookingCode,
      status: _string(data['payoutStatus']).isEmpty
          ? 'PENDING'
          : _string(data['payoutStatus']),
      eventDate: _asDate(data['eventDate']),
      bookingAmount: _asInt(data['bookingAmount']),
      netAmount: _asInt(data['netPayoutAmount']),
      transactionId: _string(data['transactionReference']),
      payoutDate: _asDate(data['releasedAt']),
      commissionPercent: _asNum(data['commissionPercent']),
      commissionAmount: _asInt(data['commissionAmount']),
      gstAmount: _asInt(data['gstAmount']),
      otherCharges: _asInt(data['otherCharges']),
      stipendPdfUrl: _string(data['stipendPdfUrl']),
      professionalConfirmationStatus: _confirmationStatus(
        data['professionalConfirmationStatus'],
        data,
      ),
      professionalConfirmationComment: _string(
        data['professionalConfirmationComment'],
      ),
      professionalDisputeReason: _string(data['professionalDisputeReason']),
      professionalConfirmedAt: _asDate(data['professionalConfirmedAt']),
      professionalDisputedAt: _asDate(data['professionalDisputedAt']),
    );
  }

  Future<bool> submitPayoutConfirmation({
    required String payrollId,
    required String action,
    String message = '',
  }) async {
    if (payoutActionsInProgress.contains(payrollId)) return false;
    payoutActionsInProgress.add(payrollId);
    try {
      await _paymentService.confirmProfessionalPayout(
        payrollId: payrollId,
        action: action,
        comment: action == 'CONFIRM' ? message : '',
        reason: action == 'DISPUTE' ? message : '',
      );
      AppSnackbar.success(
        action == 'CONFIRM' ? 'Payout Confirmed' : 'Issue Reported',
        action == 'CONFIRM'
            ? 'The payout receipt has been confirmed.'
            : 'The payout issue has been sent to admin.',
      );
      return true;
    } catch (error) {
      AppSnackbar.error('Unable to update payout', error.toString());
      return false;
    } finally {
      payoutActionsInProgress.remove(payrollId);
    }
  }

  @override
  void onClose() {
    _payrollSub?.cancel();
    super.onClose();
  }
}

String _confirmationStatus(dynamic value, Map<String, dynamic> data) {
  final status = _string(value).toUpperCase();
  if (status.isNotEmpty) return status;
  return _string(data['payoutStatus']).toUpperCase() == 'RELEASED'
      ? 'PENDING'
      : '';
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

num _asNum(dynamic value, {num fallback = 0}) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim()) ?? fallback;
  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

String _monthLabel(int month) {
  const labels = <String>[
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return '-';
  return labels[month];
}

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _monthYearLabel(DateTime date) {
  final year = date.year.toString().substring(2);
  return '${_monthLabel(date.month)} $year';
}

Map<String, ProfessionalEarningsMonthlyOverview> _emptyMonthlyBuckets(
  DateTime endMonth,
) {
  final buckets = <String, ProfessionalEarningsMonthlyOverview>{};
  for (var index = 11; index >= 0; index--) {
    final date = DateTime(endMonth.year, endMonth.month - index);
    buckets[_monthKey(date)] = ProfessionalEarningsMonthlyOverview(
      year: date.year,
      month: date.month,
      label: _monthYearLabel(date),
      earnings: 0,
    );
  }
  return buckets;
}
