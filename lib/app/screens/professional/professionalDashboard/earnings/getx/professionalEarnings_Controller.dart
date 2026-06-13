// ignore_for_file: file_names

import 'dart:async';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfessionalEarningsMonthlyOverview {
  const ProfessionalEarningsMonthlyOverview({
    required this.month,
    required this.revenue,
    required this.payout,
  });

  final String month;
  final double revenue;
  final double payout;
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

  final RxBool isLoading = true.obs;
  final RxInt totalRevenue = 0.obs;
  final RxInt monthlyRevenue = 0.obs;
  final RxInt pendingPayout = 0.obs;
  final RxInt settledAmount = 0.obs;
  final RxList<ProfessionalEarningsMonthlyOverview> monthlyOverview =
      <ProfessionalEarningsMonthlyOverview>[].obs;
  final RxList<ProfessionalPaymentHistoryItem> paymentHistory =
      <ProfessionalPaymentHistoryItem>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _payrollSub;

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
        .listen((snapshot) {
          final items = snapshot.docs.map(_historyItemFromDoc).toList();
          items.sort((left, right) {
            final a = left.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final b = right.eventDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            return b.compareTo(a);
          });
          paymentHistory.assignAll(items);
          _recalculate(items);
          isLoading.value = false;
        }, onError: (_) {
          isLoading.value = false;
        });
  }

  void _recalculate(List<ProfessionalPaymentHistoryItem> items) {
    final now = DateTime.now();
    totalRevenue.value = items.fold<int>(
      0,
      (runningTotal, item) => runningTotal + item.bookingAmount,
    );
    monthlyRevenue.value = items
        .where(
          (item) =>
              item.eventDate != null &&
              item.eventDate!.month == now.month &&
              item.eventDate!.year == now.year,
        )
        .fold<int>(
          0,
          (runningTotal, item) => runningTotal + item.bookingAmount,
        );
    pendingPayout.value = items
        .where((item) => item.status.toUpperCase() == 'PENDING')
        .fold<int>(0, (runningTotal, item) => runningTotal + item.netAmount);
    settledAmount.value = items
        .where((item) => item.status.toUpperCase() == 'RELEASED')
        .fold<int>(0, (runningTotal, item) => runningTotal + item.netAmount);

    final buckets = <String, (int revenue, int payout)>{};
    for (final item in items) {
      final date = item.eventDate;
      if (date == null) continue;
      final key = _monthLabel(date.month);
      final current = buckets[key] ?? (0, 0);
      buckets[key] = (
        current.$1 + item.bookingAmount,
        current.$2 + (item.status.toUpperCase() == 'RELEASED' ? item.netAmount : 0),
      );
    }
    monthlyOverview.assignAll(
      buckets.entries.map((entry) {
        return ProfessionalEarningsMonthlyOverview(
          month: entry.key,
          revenue: entry.value.$1 / 1000,
          payout: entry.value.$2 / 1000,
        );
      }).toList(growable: false),
    );
  }

  ProfessionalPaymentHistoryItem _historyItemFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ProfessionalPaymentHistoryItem(
      payrollId: doc.id,
      bookingId: _string(data['bookingId']),
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
    );
  }

  @override
  void onClose() {
    _payrollSub?.cancel();
    super.onClose();
  }
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
