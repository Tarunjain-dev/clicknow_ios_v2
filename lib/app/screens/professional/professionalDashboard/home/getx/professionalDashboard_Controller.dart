import 'dart:async';

import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/notifications/notification_repository.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfessionalDashboardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService.instance;

  final RxBool isLoading = true.obs;
  final RxBool isToggleUpdating = false.obs;

  final RxString professionalName = 'Professional'.obs;
  final RxString profileStatus = 'approved'.obs;
  final RxBool isAvailableForBooking = true.obs;

  final RxInt todaysBookings = 0.obs;
  final RxInt upcomingBookings = 0.obs;
  final RxInt pendingAcceptance = 0.obs;
  final RxInt activeBookings = 0.obs;
  final RxInt monthlyRevenue = 0.obs;
  final RxInt notificationCount = 0.obs;
  final RxList<ProfessionalDashboardBooking> currentActiveBookings =
      <ProfessionalDashboardBooking>[].obs;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<List<ProfessionalBookingRecord>>? _bookingSub;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<int>? _notificationCountSub;

  String? get _uid => _auth.currentUser?.uid;

  bool get isApproved {
    final status = profileStatus.value.toLowerCase().trim();
    return <String>{
      'approved',
      'online',
      'active',
      'available',
      'working',
      'on_ground',
      'in_service',
    }.contains(status);
  }

  @override
  void onInit() {
    super.onInit();
    _listenProfile();
    _bindBookings();
    _bindNotificationCount();
    _authSub = _auth.authStateChanges().listen((_) {
      _listenProfile();
      _bindBookings();
      _bindNotificationCount();
    });
  }

  Future<void> toggleVisibility(bool value) async {
    if (isToggleUpdating.value) {
      return;
    }
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return;
    }
    if (!isApproved) {
      AppSnackbar.error(
        'Profile Under Review',
        'Visibility can be changed after profile approval.',
      );
      return;
    }

    final previous = isAvailableForBooking.value;

    isAvailableForBooking.value = value;
    isToggleUpdating.value = true;

    try {
      final now = FieldValue.serverTimestamp();
      await _db.collection('professional_profiles').doc(uid).set({
        'updatedAt': now,
        'professionalAvailabilityStatus': value ? 'online' : 'offline',
        'availability': {
          'isVisibleForBooking': value,
          'isAvailableForBooking': value,
          'professionalAvailabilityStatus': value ? 'online' : 'offline',
          'visibilityStatus': value ? 'online' : 'offline',
          'visibilityUpdatedAt': now,
        },
      }, SetOptions(merge: true));

      await _db.collection('users').doc(uid).set({
        'professionalAvailableForBooking': value,
        'professionalAvailabilityStatus': value ? 'online' : 'offline',
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {
      isAvailableForBooking.value = previous;
      AppSnackbar.error(
        'Update Failed',
        'Could not update booking visibility. Please retry.',
      );
    } finally {
      isToggleUpdating.value = false;
    }
  }

  void _listenProfile() {
    _profileSub?.cancel();
    final uid = _uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _profileSub = _db
        .collection('professional_profiles')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            isLoading.value = false;
            if (!snapshot.exists) {
              return;
            }
            _applyProfile(snapshot.data() ?? <String, dynamic>{});
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to load professional dashboard right now.',
            );
          },
        );
  }

  void _applyProfile(Map<String, dynamic> data) {
    final basicInfo = _asMap(data['basicInfo']);
    final availability = _asMap(data['availability']);

    final name = _firstNonEmptyString(<dynamic>[
      basicInfo['fullName'],
      basicInfo['name'],
      data['fullName'],
      data['name'],
    ]);
    if (name.isNotEmpty) {
      professionalName.value = name;
    }

    final status = _firstNonEmptyString(<dynamic>[
      data['status'],
      data['professionalStatus'],
    ]).toLowerCase();
    if (status.isNotEmpty) {
      profileStatus.value = status;
    }

    final visibilityStatus = _firstNonEmptyString(<dynamic>[
      data['professionalAvailabilityStatus'],
      availability['professionalAvailabilityStatus'],
      availability['visibilityStatus'],
      availability['status'],
    ]).toLowerCase();
    final hasAvailabilityFlag =
        availability.containsKey('isVisibleForBooking') ||
        availability.containsKey('isAvailableForBooking');
    final onlineByAvailabilityFlag =
        _toBool(availability['isVisibleForBooking']) ||
        _toBool(availability['isAvailableForBooking']);
    final onlineByAvailabilityStatus = const <String>{
      'online',
      'active',
      'available',
    }.contains(visibilityStatus);
    final offlineByAvailabilityStatus = const <String>{
      'offline',
      'inactive',
      'unavailable',
    }.contains(visibilityStatus);
    final onlineByStatus = <String>{
      'online',
      'active',
      'available',
    }.contains(profileStatus.value);

    if (hasAvailabilityFlag) {
      isAvailableForBooking.value = onlineByAvailabilityFlag;
    } else if (visibilityStatus.isNotEmpty) {
      isAvailableForBooking.value =
          onlineByAvailabilityStatus || !offlineByAvailabilityStatus;
    } else {
      isAvailableForBooking.value = onlineByStatus || isApproved;
    }
  }

  void _bindBookings() {
    _bookingSub?.cancel();
    final uid = _uid;
    if (uid == null) {
      _clearBookingMetrics();
      return;
    }
    _bookingSub = _bookingService
        .streamProfessionalBookings(uid)
        .listen(
          _applyBookingMetrics,
          onError: (_) {
            _clearBookingMetrics();
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to load professional bookings right now.',
            );
          },
        );
  }

  void _applyBookingMetrics(List<ProfessionalBookingRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);

    final activeRecords =
        records
            .where((record) {
              return _activeDashboardStatuses.contains(
                _statusCodeFromRecord(record),
              );
            })
            .toList(growable: false)
          ..sort((left, right) {
            final leftDate = left.eventDate ?? DateTime(9999);
            final rightDate = right.eventDate ?? DateTime(9999);
            return leftDate.compareTo(rightDate);
          });

    todaysBookings.value = records.where((record) {
      final eventDate = record.eventDate;
      if (eventDate == null) {
        return false;
      }
      final status = _statusCodeFromRecord(record);
      return _activeDashboardStatuses.contains(status) &&
          !eventDate.isBefore(today) &&
          eventDate.isBefore(tomorrow);
    }).length;

    upcomingBookings.value = records.where((record) {
      final eventDate = record.eventDate;
      if (eventDate == null) {
        return false;
      }
      final status = _statusCodeFromRecord(record);
      return _activeDashboardStatuses.contains(status) &&
          !eventDate.isBefore(tomorrow);
    }).length;

    pendingAcceptance.value = records
        .where((record) => _statusCodeFromRecord(record) == 'ASSIGNED')
        .length;
    activeBookings.value = activeRecords.length;
    monthlyRevenue.value = records
        .where((record) {
          final eventDate = record.eventDate;
          if (eventDate == null ||
              _statusCodeFromRecord(record) != 'COMPLETED') {
            return false;
          }
          return !eventDate.isBefore(monthStart) &&
              eventDate.isBefore(nextMonthStart);
        })
        .fold<int>(0, (sum, record) => sum + record.professionalPayoutAmount);

    currentActiveBookings.assignAll(
      activeRecords
          .take(3)
          .map(ProfessionalDashboardBooking.fromRecord)
          .toList(growable: false),
    );
  }

  void _clearBookingMetrics() {
    todaysBookings.value = 0;
    upcomingBookings.value = 0;
    pendingAcceptance.value = 0;
    activeBookings.value = 0;
    monthlyRevenue.value = 0;
    currentActiveBookings.clear();
  }

  void _bindNotificationCount() {
    _notificationCountSub?.cancel();
    if (_uid == null) {
      notificationCount.value = 0;
      return;
    }
    _notificationCountSub = NotificationRepository.instance
        .watchCurrentUserUnreadCount()
        .listen(
          (count) => notificationCount.value = count,
          onError: (_) => notificationCount.value = 0,
        );
  }

  static const Set<String> _activeDashboardStatuses = <String>{
    'ASSIGNED',
    'CONFIRMED',
    'IN_PROGRESS',
  };

  String _statusCodeFromRecord(ProfessionalBookingRecord record) {
    final direct = record.statusCode.trim().toUpperCase();
    if (direct.isNotEmpty) {
      return direct == 'CANCELED' ? 'CANCELLED' : direct;
    }
    final lifecycle = record.lifecycleStatus.trim().toLowerCase();
    switch (lifecycle) {
      case 'assigned':
        return 'ASSIGNED';
      case 'confirmed':
        return 'CONFIRMED';
      case 'in_progress':
        return 'IN_PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      case 'approved':
      case 'assignment_pending':
      case 'reschedule_requested':
        return 'APPROVED';
      case 'requested':
        return 'REQUESTED';
    }
    final bookingStatus = record.bookingStatus.trim().toUpperCase();
    return bookingStatus == 'CANCELED' ? 'CANCELLED' : bookingStatus;
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

  String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final parsed = value?.toString().toLowerCase().trim();
    return parsed == 'true' || parsed == '1' || parsed == 'yes';
  }

  @override
  void onClose() {
    _profileSub?.cancel();
    _bookingSub?.cancel();
    _authSub?.cancel();
    _notificationCountSub?.cancel();
    super.onClose();
  }
}

class ProfessionalDashboardBooking {
  const ProfessionalDashboardBooking({
    required this.bookingCode,
    required this.serviceName,
    required this.eventName,
    required this.location,
    required this.dateAndTime,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
  });

  final String bookingCode;
  final String serviceName;
  final String eventName;
  final String location;
  final String dateAndTime;
  final String amount;
  final String statusLabel;
  final int statusColor;

  factory ProfessionalDashboardBooking.fromRecord(
    ProfessionalBookingRecord record,
  ) {
    final statusCode = _statusCodeFromRecord(record);
    return ProfessionalDashboardBooking(
      bookingCode: record.bookingCode,
      serviceName: record.serviceTitle.trim().isEmpty
          ? 'Booking'
          : record.serviceTitle.trim(),
      eventName: record.eventTypeName.trim().isEmpty
          ? '-'
          : record.eventTypeName.trim(),
      location: record.locationText.trim().isEmpty
          ? '-'
          : record.locationText.trim(),
      dateAndTime: _dateTimeLabel(record.eventDate, record.eventTime),
      amount: 'Rs. ${_formatAmount(record.professionalPayoutAmount)} payout',
      statusLabel: _statusLabel(statusCode),
      statusColor: _statusColorValue(statusCode),
    );
  }

  static String _statusCodeFromRecord(ProfessionalBookingRecord record) {
    final direct = record.statusCode.trim().toUpperCase();
    if (direct.isNotEmpty) {
      return direct == 'CANCELED' ? 'CANCELLED' : direct;
    }
    final lifecycle = record.lifecycleStatus.trim().toLowerCase();
    switch (lifecycle) {
      case 'assigned':
        return 'ASSIGNED';
      case 'confirmed':
        return 'CONFIRMED';
      case 'in_progress':
        return 'IN_PROGRESS';
      default:
        return lifecycle.toUpperCase();
    }
  }

  static String _statusLabel(String statusCode) {
    switch (statusCode) {
      case 'ASSIGNED':
        return 'Assigned';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      default:
        return 'Active';
    }
  }

  static int _statusColorValue(String statusCode) {
    switch (statusCode) {
      case 'ASSIGNED':
        return 0xff3EA7FF;
      case 'CONFIRMED':
        return 0xff23D658;
      case 'IN_PROGRESS':
        return 0xff00A9FF;
      default:
        return 0xffC98A2D;
    }
  }

  static String _dateTimeLabel(DateTime? date, String time) {
    if (date == null) {
      return time.trim().isEmpty ? '-' : time.trim();
    }
    final dateText = '${_monthLabel(date.month)} ${date.day}, ${date.year}';
    return time.trim().isEmpty ? dateText : '$dateText - ${time.trim()}';
  }

  static String _monthLabel(int month) {
    const months = <String>[
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
    return months[(month - 1).clamp(0, months.length - 1)];
  }

  static String _formatAmount(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final indexFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
