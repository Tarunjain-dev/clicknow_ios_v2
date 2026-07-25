import 'dart:async';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminDashboardController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<AdminDashboardSnapshot> dashboard =
      AdminDashboardSnapshot.empty().obs;
  final Rx<DateTime> chartEndMonth =
      DateTime(DateTime.now().year, DateTime.now().month).obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _professionalsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _paymentsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _payrollsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _professionals = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _bookings = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _payments = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _payrolls = const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _tickets = const [];

  final Set<String> _loadedSources = <String>{};

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    _usersSub = _watch(ServiceCatalogPaths.usersCollection, 'users', (docs) {
      _users = docs;
    });
    _professionalsSub = _watch('professional_profiles', 'professionals', (
      docs,
    ) {
      _professionals = docs;
    });
    _bookingsSub = _watch(ServiceCatalogPaths.bookingsCollection, 'bookings', (
      docs,
    ) {
      _bookings = docs;
    });
    _paymentsSub = _watch(ServiceCatalogPaths.paymentsCollection, 'payments', (
      docs,
    ) {
      _payments = docs;
    });
    _payrollsSub = _watch(ServiceCatalogPaths.payrollsCollection, 'payrolls', (
      docs,
    ) {
      _payrolls = docs;
    });
    _ticketsSub = _watch(
      ServiceCatalogPaths.supportTicketsCollection,
      'tickets',
      (docs) {
        _tickets = docs;
      },
    );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _watch(
    String collection,
    String source,
    void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) consume,
  ) {
    return _db
        .collection(collection)
        .snapshots()
        .listen(
          (snapshot) {
            consume(snapshot.docs);
            _loadedSources.add(source);
            errorMessage.value = '';
            _rebuild();
          },
          onError: (_) {
            _loadedSources.add(source);
            errorMessage.value =
                'Some dashboard data could not be loaded. Pull down to retry.';
            _rebuild();
          },
        );
  }

  @override
  Future<void> refresh() async {
    isRefreshing.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        _db.collection(ServiceCatalogPaths.usersCollection).get(),
        _db.collection('professional_profiles').get(),
        _db.collection(ServiceCatalogPaths.bookingsCollection).get(),
        _db.collection(ServiceCatalogPaths.paymentsCollection).get(),
        _db.collection(ServiceCatalogPaths.payrollsCollection).get(),
        _db.collection(ServiceCatalogPaths.supportTicketsCollection).get(),
      ]);
      _users = results[0].docs;
      _professionals = results[1].docs;
      _bookings = results[2].docs;
      _payments = results[3].docs;
      _payrolls = results[4].docs;
      _tickets = results[5].docs;
      _loadedSources.addAll(const [
        'users',
        'professionals',
        'bookings',
        'payments',
        'payrolls',
        'tickets',
      ]);
      _rebuild();
    } catch (_) {
      errorMessage.value =
          'Dashboard refresh failed. Existing data is still displayed.';
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  void _rebuild() {
    dashboard.value = AdminDashboardSnapshot.fromDocuments(
      users: _users,
      professionals: _professionals,
      bookings: _bookings,
      payments: _payments,
      payrolls: _payrolls,
      tickets: _tickets,
      chartEndMonth: chartEndMonth.value,
    );
    isLoading.value = _loadedSources.length < 6;
  }

  void showPreviousChartMonths() {
    chartEndMonth.value = DateTime(
      chartEndMonth.value.year,
      chartEndMonth.value.month - 12,
    );
    _rebuild();
  }

  void showNextChartMonths() {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    final next = DateTime(
      chartEndMonth.value.year,
      chartEndMonth.value.month + 12,
    );
    chartEndMonth.value = next.isAfter(current) ? current : next;
    _rebuild();
  }

  bool get canShowNextChartMonths {
    final current = DateTime(DateTime.now().year, DateTime.now().month);
    return chartEndMonth.value.isBefore(current);
  }

  @override
  void onClose() {
    _usersSub?.cancel();
    _professionalsSub?.cancel();
    _bookingsSub?.cancel();
    _paymentsSub?.cancel();
    _payrollsSub?.cancel();
    _ticketsSub?.cancel();
    super.onClose();
  }
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.totalProfessionals,
    required this.pendingApprovals,
    required this.totalCustomers,
    required this.activeBookings,
    required this.totalRevenue,
    required this.pendingPayout,
    required this.completedBookings,
    required this.inProgressBookings,
    required this.rejectedBookings,
    required this.confirmedBookings,
    required this.openSupportTickets,
    required this.monthlyOverview,
  });

  factory AdminDashboardSnapshot.empty() => AdminDashboardSnapshot(
    totalProfessionals: 0,
    pendingApprovals: 0,
    totalCustomers: 0,
    activeBookings: 0,
    totalRevenue: 0,
    pendingPayout: 0,
    completedBookings: 0,
    inProgressBookings: 0,
    rejectedBookings: 0,
    confirmedBookings: 0,
    openSupportTickets: 0,
    monthlyOverview: _emptyMonths(),
  );

  factory AdminDashboardSnapshot.fromDocuments({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> professionals,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> payments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> payrolls,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tickets,
    required DateTime chartEndMonth,
  }) {
    final professionalUsers = users.where(
      (doc) => _normal(doc.data()['role']) == 'professional',
    );
    final customers = users
        .where((doc) => _normal(doc.data()['role']) == 'customer')
        .length;
    final professionalIds = <String>{
      ...professionalUsers.map((doc) => doc.id),
      ...professionals.map((doc) => doc.id),
    };
    final adminVisibleBookings = bookings
        .where((doc) => _isAdminVisibleBooking(doc.data()))
        .toList(growable: false);

    final pendingApprovals = professionals.where((doc) {
      final data = doc.data();
      final status = _normal(
        data['approvalStatus'] ?? data['professionalStatus'] ?? data['status'],
      );
      return status.isEmpty ||
          status == 'pending' ||
          status == 'pending_approval' ||
          status == 'submitted' ||
          status == 'under_review' ||
          status == 'reupload_requested' ||
          status == 'reupload_required';
    }).length;

    var completed = 0;
    var inProgress = 0;
    var rejected = 0;
    var confirmed = 0;
    var active = 0;
    for (final doc in adminVisibleBookings) {
      final status = _bookingStatus(doc.data());
      if (_completedStatuses.contains(status)) completed++;
      if (_inProgressStatuses.contains(status)) inProgress++;
      if (_rejectedStatuses.contains(status)) rejected++;
      if (_confirmedStatuses.contains(status)) confirmed++;
      if (_activeStatuses.contains(status)) active++;
    }

    final months = _emptyMonths(chartEndMonth);
    double revenue = 0;
    for (final doc in payments) {
      final data = doc.data();
      if (!_isSuccessfulPayment(data)) continue;
      final amount = _amount(data, const [
        'amountPaid',
        'paidAmount',
        'totalPaid',
        'amount',
        'totalPayable',
      ]);
      revenue += amount;
      _addToMonth(months, _date(data), revenue: amount);
    }

    double pendingPayout = 0;
    for (final doc in payrolls) {
      final data = doc.data();
      final amount = _amount(data, const [
        'payoutAmount',
        'professionalPayout',
        'netPayout',
        'netPayoutAmount',
        'amount',
      ]);
      final status = _normal(data['status'] ?? data['payoutStatus']);
      final paid =
          status == 'paid' ||
          status == 'released' ||
          status == 'settled' ||
          status == 'completed';
      if (!paid) pendingPayout += amount;
      _addToMonth(months, _date(data), payout: amount);
    }

    final openTickets = tickets.where((doc) {
      final status = _normal(doc.data()['status']);
      return status != 'resolved' && status != 'closed' && status != 'rejected';
    }).length;

    return AdminDashboardSnapshot(
      totalProfessionals: professionalIds.length,
      pendingApprovals: pendingApprovals,
      totalCustomers: customers,
      activeBookings: active,
      totalRevenue: revenue,
      pendingPayout: pendingPayout,
      completedBookings: completed,
      inProgressBookings: inProgress,
      rejectedBookings: rejected,
      confirmedBookings: confirmed,
      openSupportTickets: openTickets,
      monthlyOverview: months,
    );
  }

  final int totalProfessionals;
  final int pendingApprovals;
  final int totalCustomers;
  final int activeBookings;
  final double totalRevenue;
  final double pendingPayout;
  final int completedBookings;
  final int inProgressBookings;
  final int rejectedBookings;
  final int confirmedBookings;
  final int openSupportTickets;
  final List<AdminMonthlyOverview> monthlyOverview;
}

class AdminMonthlyOverview {
  final int year;
  final int month;
  final String label;
  double get revenue => _revenue;
  double get payout => _payout;
  final double _revenue;
  final double _payout;

  AdminMonthlyOverview copyWith({double? revenue, double? payout}) =>
      AdminMonthlyOverview._(
        year: year,
        month: month,
        label: label,
        revenue: revenue ?? this.revenue,
        payout: payout ?? this.payout,
      );

  const AdminMonthlyOverview._({
    required this.year,
    required this.month,
    required this.label,
    required double revenue,
    required double payout,
  }) : _revenue = revenue,
       _payout = payout;
}

List<AdminMonthlyOverview> _emptyMonths([DateTime? endMonth]) {
  const labels = [
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
  final end = endMonth ?? DateTime.now();
  return List.generate(12, (index) {
    final date = DateTime(end.year, end.month - (11 - index));
    final year = date.year.toString().substring(2);
    return AdminMonthlyOverview._(
      year: date.year,
      month: date.month,
      label: '${labels[date.month - 1]} $year',
      revenue: 0,
      payout: 0,
    );
  });
}

void _addToMonth(
  List<AdminMonthlyOverview> months,
  DateTime? date, {
  double revenue = 0,
  double payout = 0,
}) {
  if (date == null) return;
  final index = months.indexWhere(
    (item) => item.year == date.year && item.month == date.month,
  );
  if (index < 0) return;
  final current = months[index];
  months[index] = current.copyWith(
    revenue: current.revenue + revenue,
    payout: current.payout + payout,
  );
}

DateTime? _date(Map<String, dynamic> data) {
  for (final key in const [
    'paidAt',
    'completedAt',
    'releasedAt',
    'settledAt',
    'updatedAt',
    'createdAt',
  ]) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double _amount(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

bool _isSuccessfulPayment(Map<String, dynamic> data) {
  final status = _normal(data['status'] ?? data['paymentStatus']);
  return status == 'paid' ||
      status == 'captured' ||
      status == 'success' ||
      status == 'successful' ||
      status == 'completed' ||
      status == 'partially_paid' ||
      status == 'advance_paid' ||
      status == 'fully_paid';
}

bool _isAdminVisibleBooking(Map<String, dynamic> data) {
  if (data['adminVisible'] == false) {
    return false;
  }
  final payment = _normal(
    data['paymentStatus'] ?? _asMap(data['payment'])['status'],
  );
  return const <String>{
    'paid',
    'fully_paid',
    'partially_paid',
    'advance_paid',
    'refund_pending',
    'refund_processing',
    'partially_refunded',
    'refunded',
  }.contains(payment);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

String _bookingStatus(Map<String, dynamic> data) => _normal(
  data['statusCode'] ??
      data['bookingStatus'] ??
      data['status'] ??
      data['workflowStatus'],
);

String _normal(dynamic value) =>
    value.toString().trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

const _completedStatuses = {
  'completed',
  'service_completed',
  'payment_settled',
};
const _inProgressStatuses = {
  'in_progress',
  'service_started',
  'event_started',
  'started',
  'on_the_way',
};
const _rejectedStatuses = {
  'rejected',
  'admin_rejected',
  'professional_rejected',
  'cancelled',
  'canceled',
};
const _confirmedStatuses = {
  'confirmed',
  'accepted',
  'professional_assigned',
  'assigned',
  'approved',
};
const _activeStatuses = {..._confirmedStatuses, ..._inProgressStatuses};
