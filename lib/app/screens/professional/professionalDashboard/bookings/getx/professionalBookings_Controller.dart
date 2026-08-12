// ignore_for_file: file_names

import 'dart:async';

import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ProfessionalBookingStatus {
  assigned,
  confirmed,
  inProgress,
  completed,
  cancelled,
  other,
}

class ProfessionalBookingItem {
  const ProfessionalBookingItem({
    required this.bookingId,
    required this.bookingCode,
    required this.serviceName,
    required this.eventName,
    required this.professionalType,
    required this.customerName,
    required this.customerPhone,
    required this.location,
    required this.venueName,
    required this.venueHouseDetails,
    required this.venueLandmarkDetails,
    required this.dateAndTime,
    required this.specialInstructions,
    required this.ratePerHour,
    required this.durationHours,
    required this.gstAmount,
    required this.totalPayable,
    required this.finalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.commissionAmount,
    required this.professionalPayoutAmount,
    required this.refundEligibility,
    required this.refundPercentage,
    required this.paymentStatusLabel,
    required this.amountWithGst,
    required this.bookingStartTime,
    required this.bookingEndTime,
    required this.bookingDuration,
    required this.statusCode,
    required this.lifecycleStatus,
    required this.reschedulePending,
    required this.rescheduleRequestedSchedule,
    required this.rescheduleReason,
    required this.status,
  });

  final String bookingId;
  final String bookingCode;
  final String serviceName;
  final String eventName;
  final String professionalType;
  final String customerName;
  final String customerPhone;
  final String location;
  final String venueName;
  final String venueHouseDetails;
  final String venueLandmarkDetails;
  final String dateAndTime;
  final String specialInstructions;
  final int ratePerHour;
  final int durationHours;
  final int gstAmount;
  final int totalPayable;
  final int finalAmount;
  final int paidAmount;
  final int remainingAmount;
  final int discountAmount;
  final int netAmount;
  final int commissionAmount;
  final int professionalPayoutAmount;
  final String refundEligibility;
  final int refundPercentage;
  final String paymentStatusLabel;
  final String amountWithGst;
  final DateTime? bookingStartTime;
  final DateTime? bookingEndTime;
  final int bookingDuration;
  final String statusCode;
  final String lifecycleStatus;
  final bool reschedulePending;
  final String rescheduleRequestedSchedule;
  final String rescheduleReason;
  final ProfessionalBookingStatus status;

  bool get canAccept => statusCode == 'ASSIGNED';
  bool get canReject => statusCode == 'ASSIGNED';
  bool get isFullyPaid {
    final status = paymentStatusLabel
        .replaceFirst('Payment:', '')
        .trim()
        .toUpperCase();
    return status == 'PAID' || status == 'FULLY_PAID';
  }

  bool get awaitingFullPayment => statusCode == 'CONFIRMED' && !isFullyPaid;
  bool get canStart => statusCode == 'CONFIRMED' && isFullyPaid;
  bool get canEnd => statusCode == 'IN_PROGRESS';

  factory ProfessionalBookingItem.fromRecord(ProfessionalBookingRecord record) {
    final duration = int.tryParse(record.eventDurationHours.trim()) ?? 0;
    final statusCode = _statusCodeFromRecord(record);
    final status = _statusFromCode(statusCode);
    final dateLabel = _dateTimeLabel(record.eventDate, record.eventTime);
    final reschedule = _asMap(record.rescheduleRequest);
    final reschedulePending =
        _string(reschedule['status']).toLowerCase() == 'pending';
    final rescheduleDate = _asDateTime(reschedule['newEventDate']);
    final rescheduleTime = _string(reschedule['newEventTime']);
    final payment = record.paymentStatus.isEmpty
        ? 'Payment: pending'
        : 'Payment: ${record.paymentStatus}';
    return ProfessionalBookingItem(
      bookingId: record.id,
      bookingCode: record.bookingCode,
      serviceName: record.serviceTitle,
      eventName: record.eventTypeName,
      professionalType: record.planName,
      customerName: record.customerName,
      customerPhone: record.customerPhone,
      location: record.locationText,
      venueName: record.venueName,
      venueHouseDetails: record.venueHouseDetails,
      venueLandmarkDetails: record.venueLandmarkDetails,
      dateAndTime: dateLabel,
      specialInstructions: record.specialRequirements,
      ratePerHour: record.basePrice,
      durationHours: duration,
      gstAmount: record.gstAmount,
      totalPayable: record.professionalPayoutAmount,
      finalAmount: record.finalAmount,
      paidAmount: 0,
      remainingAmount: 0,
      discountAmount: 0,
      netAmount: record.netAmount,
      commissionAmount: record.commissionAmount,
      professionalPayoutAmount: record.professionalPayoutAmount,
      refundEligibility: '',
      refundPercentage: 0,
      paymentStatusLabel: payment,
      amountWithGst:
          'Rs. ${_formatAmount(record.professionalPayoutAmount)} expected payout for $duration hours',
      bookingStartTime: record.bookingStartTime,
      bookingEndTime: record.bookingEndTime,
      bookingDuration: record.bookingDuration,
      statusCode: statusCode,
      lifecycleStatus: record.lifecycleStatus.toLowerCase().trim(),
      reschedulePending: reschedulePending,
      rescheduleRequestedSchedule: reschedulePending
          ? _dateTimeLabel(rescheduleDate, rescheduleTime)
          : '',
      rescheduleReason: _string(reschedule['reason']),
      status: status,
    );
  }

  static String _statusCodeFromRecord(ProfessionalBookingRecord record) {
    final direct = record.statusCode.trim().toUpperCase();
    if (direct.isNotEmpty) {
      return direct == 'CANCELED' ? 'CANCELLED' : direct;
    }

    final lifecycle = record.lifecycleStatus.trim().toLowerCase();
    switch (lifecycle) {
      case 'requested':
        return 'REQUESTED';
      case 'approved':
      case 'assignment_pending':
        return 'APPROVED';
      case 'assigned':
        return 'ASSIGNED';
      case 'confirmed':
        return 'CONFIRMED';
      case 'in_progress':
        return 'IN_PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
      case 'canceled':
        return 'CANCELLED';
      case 'rejected':
        return 'REJECTED';
      case 'reschedule_requested':
        return 'APPROVED';
    }

    final fallback = record.bookingStatus.trim().toUpperCase();
    if (fallback.isEmpty) {
      return 'REQUESTED';
    }
    return fallback == 'CANCELED' ? 'CANCELLED' : fallback;
  }

  static ProfessionalBookingStatus _statusFromCode(String code) {
    switch (code) {
      case 'ASSIGNED':
        return ProfessionalBookingStatus.assigned;
      case 'CONFIRMED':
        return ProfessionalBookingStatus.confirmed;
      case 'IN_PROGRESS':
        return ProfessionalBookingStatus.inProgress;
      case 'COMPLETED':
        return ProfessionalBookingStatus.completed;
      case 'CANCELLED':
      case 'REJECTED':
        return ProfessionalBookingStatus.cancelled;
      default:
        return ProfessionalBookingStatus.other;
    }
  }

  static String _dateTimeLabel(DateTime? date, String time) {
    if (date == null) {
      return time.isEmpty ? 'Date not selected' : time;
    }
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
    final dateText = '${months[date.month - 1]} ${date.day}, ${date.year}';
    if (time.trim().isEmpty) {
      return dateText;
    }
    return '$dateText - ${time.trim()}';
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

String _string(dynamic value) => value?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

class ProfessionalBookingsController extends GetxController {
  static ProfessionalBookingsController get instance {
    if (Get.isRegistered<ProfessionalBookingsController>()) {
      return Get.find<ProfessionalBookingsController>();
    }
    return Get.put(ProfessionalBookingsController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BookingService _bookingService = BookingService.instance;
  final RazorpayPaymentService _paymentService =
      RazorpayPaymentService.instance;

  final RxInt selectedTabIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxMap<String, bool> actionLoadingByBookingId = <String, bool>{}.obs;
  final RxList<ProfessionalBookingItem> allBookings =
      <ProfessionalBookingItem>[].obs;

  StreamSubscription<List<ProfessionalBookingRecord>>? _bookingsSub;
  StreamSubscription<User?>? _authSub;

  final List<String> tabs = const <String>[
    'All',
    'New Jobs',
    'Upcoming',
    'Ongoing',
    'Completed',
    'Rejected',
  ];

  String? get _uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _bindBookings();
    _authSub = _auth.authStateChanges().listen((_) => _bindBookings());
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  bool isActionLoading(String bookingId) {
    return actionLoadingByBookingId[bookingId] == true;
  }

  List<ProfessionalBookingItem> filteredBookingsForTab(int tabIndex) {
    if (tabIndex <= 0) {
      return allBookings;
    }

    final currentTab = tabs[tabIndex];
    return allBookings
        .where((item) {
          switch (currentTab) {
            case 'New Jobs':
              return item.statusCode == 'ASSIGNED';
            case 'Upcoming':
              return item.statusCode == 'CONFIRMED';
            case 'Ongoing':
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

  int countForTabIndex(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= tabs.length) {
      return 0;
    }
    return filteredBookingsForTab(tabIndex).length;
  }

  ProfessionalBookingItem? itemById(String bookingId) {
    for (final item in allBookings) {
      if (item.bookingId == bookingId) {
        return item;
      }
    }
    return null;
  }

  Future<bool> startBooking({
    required ProfessionalBookingItem booking,
    required String otp,
  }) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return false;
    }
    if (isActionLoading(booking.bookingId)) {
      return false;
    }
    actionLoadingByBookingId[booking.bookingId] = true;
    try {
      await _paymentService.verifyBookingOtpAndStart(
        bookingId: booking.bookingId,
        otp: otp,
      );
      AppSnackbar.success('Started', 'OTP verified. Booking started.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to start booking ${booking.bookingId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error(
        'Failed',
        'Could not start booking. Check OTP and full payment status.',
      );
      return false;
    } finally {
      actionLoadingByBookingId.remove(booking.bookingId);
    }
  }

  Future<bool> acceptBooking(ProfessionalBookingItem booking) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return false;
    }
    if (isActionLoading(booking.bookingId)) {
      return false;
    }
    actionLoadingByBookingId[booking.bookingId] = true;
    try {
      await _bookingService.acceptBooking(
        bookingId: booking.bookingId,
        professionalId: uid,
      );
      AppSnackbar.success('Accepted', 'Booking accepted successfully.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to accept booking ${booking.bookingId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error('Failed', 'Could not accept booking.');
      return false;
    } finally {
      actionLoadingByBookingId.remove(booking.bookingId);
    }
  }

  Future<bool> rejectBooking({
    required ProfessionalBookingItem booking,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return false;
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      AppSnackbar.error('Reason Required', 'Please add rejection reason.');
      return false;
    }
    if (isActionLoading(booking.bookingId)) {
      return false;
    }
    actionLoadingByBookingId[booking.bookingId] = true;
    try {
      await _bookingService.rejectBookingByProfessional(
        bookingId: booking.bookingId,
        professionalId: uid,
        reason: trimmedReason,
      );
      AppSnackbar.success(
        'Rejected',
        'Booking rejected and returned to admin.',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to reject booking ${booking.bookingId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error('Failed', 'Could not reject booking.');
      return false;
    } finally {
      actionLoadingByBookingId.remove(booking.bookingId);
    }
  }

  Future<bool> endBooking(ProfessionalBookingItem booking) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return false;
    }
    if (isActionLoading(booking.bookingId)) {
      return false;
    }
    actionLoadingByBookingId[booking.bookingId] = true;
    try {
      await _paymentService.endBooking(bookingId: booking.bookingId);
      AppSnackbar.success('Completed', 'Booking marked as completed.');
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to complete booking ${booking.bookingId}: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error('Failed', 'Could not complete booking.');
      return false;
    } finally {
      actionLoadingByBookingId.remove(booking.bookingId);
    }
  }

  Color statusColor(ProfessionalBookingStatus status) {
    switch (status) {
      case ProfessionalBookingStatus.assigned:
        return const Color(0xFF3EA7FF);
      case ProfessionalBookingStatus.confirmed:
        return const Color(0xFF23D658);
      case ProfessionalBookingStatus.inProgress:
        return const Color(0xFF00A9FF);
      case ProfessionalBookingStatus.completed:
        return const Color(0xFFB31CFF);
      case ProfessionalBookingStatus.cancelled:
        return const Color(0xFFFF2F2F);
      case ProfessionalBookingStatus.other:
        return const Color(0xFFC98A2D);
    }
  }

  String statusLabel(ProfessionalBookingStatus status) {
    switch (status) {
      case ProfessionalBookingStatus.assigned:
        return 'Assigned';
      case ProfessionalBookingStatus.confirmed:
        return 'Confirmed';
      case ProfessionalBookingStatus.inProgress:
        return 'In Progress';
      case ProfessionalBookingStatus.completed:
        return 'Completed';
      case ProfessionalBookingStatus.cancelled:
        return 'Cancelled';
      case ProfessionalBookingStatus.other:
        return 'Requested';
    }
  }

  void _bindBookings() {
    _bookingsSub?.cancel();
    final uid = _uid;
    if (uid == null) {
      allBookings.clear();
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    _bookingsSub = _bookingService
        .streamProfessionalBookings(uid)
        .listen(
          (records) {
            final mapped = records
                .map(ProfessionalBookingItem.fromRecord)
                .toList(growable: false);
            allBookings.assignAll(mapped);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to load bookings right now.',
            );
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
