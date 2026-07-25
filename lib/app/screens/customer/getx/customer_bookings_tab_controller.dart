import 'dart:async';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class CustomerBookingStatusItem {
  const CustomerBookingStatusItem({
    required this.id,
    required this.bookingCode,
    required this.serviceName,
    required this.eventName,
    required this.professionalType,
    required this.venueName,
    required this.location,
    required this.dateTime,
    required this.amount,
    required this.statusCode,
    required this.status,
    required this.stage,
  });

  final String id;
  final String bookingCode;
  final String serviceName;
  final String eventName;
  final String professionalType;
  final String venueName;
  final String location;
  final String dateTime;
  final String amount;
  final String statusCode;
  final String status;
  final String stage;

  factory CustomerBookingStatusItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final amount = _customerFinalAmount(data);
    final city = (data['city'] as String? ?? '').trim();
    final state = (data['state'] as String? ?? '').trim();
    final address = (data['fullAddress'] as String? ?? '').trim();
    final locationParts = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (address.isNotEmpty) address,
    ];
    final location = locationParts.join(', ');

    final eventDate = _asDateTime(data['eventDate']);
    final eventTime = (data['eventTime'] as String? ?? '').trim();
    final dateText = eventDate == null
        ? 'Date not selected'
        : '${_monthLabel(eventDate.month)} ${eventDate.day}, ${eventDate.year}';
    final dateTime = eventTime.isEmpty ? dateText : '$dateText - $eventTime';

    final stage = (data['bookingStage'] as String? ?? '').trim();
    final statusCode = _statusCodeFromData(data: data, stage: stage);
    final status = _statusLabel(statusCode);
    return CustomerBookingStatusItem(
      id: doc.id,
      bookingCode:
          (data['bookingCode'] as String? ??
                  'BID-${doc.id.length >= 5 ? doc.id.substring(0, 5) : doc.id}')
              .trim(),
      serviceName: (data['serviceTitle'] as String? ?? 'Service').trim(),
      eventName: (data['eventTypeName'] as String? ?? 'Event').trim(),
      professionalType: (data['planName'] as String? ?? '-').trim(),
      venueName: (data['venueName'] as String? ?? '').trim(),
      location: location,
      dateTime: dateTime,
      amount: 'Rs.${_formatAmount(amount)}',
      statusCode: statusCode,
      status: status,
      stage: stage,
    );
  }
}

class CustomerBookingsTabController extends GetxController {
  static CustomerBookingsTabController get instance {
    if (Get.isRegistered<CustomerBookingsTabController>()) {
      return Get.find<CustomerBookingsTabController>();
    }
    return Get.put(CustomerBookingsTabController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxInt selectedTabIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxList<CustomerBookingStatusItem> bookings =
      <CustomerBookingStatusItem>[].obs;

  final List<String> tabs = const <String>[
    'All',
    'Pending',
    'Assigned',
    'Confirmed',
    'In Progress',
    'Completed',
    'Rejected',
  ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    _bindBookings();
    _authSub = _auth.authStateChanges().listen((_) {
      _bindBookings();
    });
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  List<CustomerBookingStatusItem> filteredBookingsForTab(int tabIndex) {
    final selected = tabs[tabIndex];
    if (selected == 'All') {
      return bookings;
    }
    return bookings
        .where((item) {
          switch (selected) {
            case 'Pending':
              return item.statusCode == 'REQUESTED' ||
                  item.statusCode == 'APPROVED';
            case 'Assigned':
              return item.statusCode == 'ASSIGNED';
            case 'Confirmed':
              return item.statusCode == 'CONFIRMED';
            case 'In Progress':
              return item.statusCode == 'IN_PROGRESS';
            case 'Completed':
              return item.statusCode == 'COMPLETED';
            case 'Rejected':
              return item.statusCode == 'REJECTED';
          }
          return false;
        })
        .toList(growable: false);
  }

  List<CustomerBookingStatusItem> get filteredBookings {
    return filteredBookingsForTab(selectedTabIndex.value);
  }

  int countForTabIndex(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= tabs.length) {
      return 0;
    }
    return filteredBookingsForTab(tabIndex).length;
  }

  Future<void> _bindBookings() async {
    await _bookingsSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      bookings.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _bookingsSub = _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .collection(ServiceCatalogPaths.customerBookingsSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final next = snapshot.docs
                .map(CustomerBookingStatusItem.fromDoc)
                .toList(growable: false);
            bookings.assignAll(next);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
          },
        );
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }
}

String _statusCodeFromData({
  required Map<String, dynamic> data,
  required String stage,
}) {
  final normalizedStage = stage.toLowerCase().replaceAll(' ', '_');
  switch (normalizedStage) {
    case 'event_started':
      return 'IN_PROGRESS';
    case 'event_date':
    case 'completed':
      return 'COMPLETED';
  }

  final direct = (data['status'] as String? ?? '').trim().toUpperCase();
  if (direct.isNotEmpty) {
    if (direct == 'CANCELED') return 'CANCELLED';
    return direct;
  }

  final isCanceled = (data['isCanceled'] as bool?) ?? false;
  if (isCanceled) return 'CANCELLED';

  final lifecycle = (data['lifecycleStatus'] as String? ?? '')
      .trim()
      .toLowerCase();
  if (lifecycle == 'requested') return 'REQUESTED';
  if (lifecycle == 'approved' || lifecycle == 'assignment_pending') {
    return 'APPROVED';
  }
  if (lifecycle == 'assigned') return 'ASSIGNED';
  if (lifecycle == 'confirmed') return 'CONFIRMED';
  if (lifecycle == 'in_progress') return 'IN_PROGRESS';
  if (lifecycle == 'completed') return 'COMPLETED';
  if (lifecycle == 'cancelled' || lifecycle == 'canceled') return 'CANCELLED';
  if (lifecycle == 'rejected') return 'REJECTED';
  if (lifecycle == 'reschedule_requested') {
    return 'APPROVED';
  }

  final rawStatus = (data['bookingStatus'] as String? ?? '')
      .trim()
      .toLowerCase();
  if (rawStatus == 'requested' || rawStatus == 'pending') return 'REQUESTED';
  if (rawStatus == 'approved') return 'APPROVED';
  if (rawStatus == 'assigned') return 'ASSIGNED';
  if (rawStatus == 'confirmed') return 'CONFIRMED';
  if (rawStatus == 'in_progress') return 'IN_PROGRESS';
  if (rawStatus == 'completed') return 'COMPLETED';
  if (rawStatus == 'canceled' || rawStatus == 'cancelled') return 'CANCELLED';
  if (rawStatus == 'rejected') return 'REJECTED';
  switch (normalizedStage) {
    case 'booking_request_submitted':
      return 'REQUESTED';
    case 'booking_got_accepted_by_admin':
    case 'accepted_by_admin':
      return 'APPROVED';
    case 'professional_assigned':
      return 'ASSIGNED';
    case 'professional_confirmed':
      return 'CONFIRMED';
    case 'event_started':
      return 'IN_PROGRESS';
    case 'event_date':
    case 'completed':
      return 'COMPLETED';
    default:
      return 'REQUESTED';
  }
}

String _statusLabel(String statusCode) {
  switch (statusCode) {
    case 'REQUESTED':
      return 'Requested';
    case 'APPROVED':
      return 'Approved';
    case 'ASSIGNED':
      return 'Assigned';
    case 'CONFIRMED':
      return 'Confirmed';
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'COMPLETED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    case 'REJECTED':
      return 'Rejected';
    default:
      return 'Requested';
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim().replaceAll(RegExp(r'[^0-9-]'), '')) ??
        fallback;
  }
  return fallback;
}

int _customerFinalAmount(Map<String, dynamic> data) {
  final payment = _asMap(data['payment']);
  final breakdown = _asMap(
    data['financialBreakdown'] ??
        data['pricingSnapshot'] ??
        payment['financialBreakdown'],
  );
  return _firstPositiveInt(<dynamic>[
    data['finalAmount'],
    data['finalCustomerPayable'],
    breakdown['finalAmount'],
    breakdown['finalCustomerPayable'],
    payment['finalAmount'],
    payment['finalPayableAmount'],
    data['totalAmount'],
    breakdown['totalAmount'],
  ]);
}

int _firstPositiveInt(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asInt(value);
    if (parsed > 0) {
      return parsed;
    }
  }
  return 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

String _monthLabel(int month) {
  const labels = <String>[
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
  return labels[(month - 1).clamp(0, 11)];
}

String _formatAmount(int value) {
  final raw = value.toString();
  final chars = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final index = raw.length - i;
    chars.add(raw[i]);
    if (index > 1 && index % 3 == 1) {
      chars.add(',');
    }
  }
  return chars.join();
}
