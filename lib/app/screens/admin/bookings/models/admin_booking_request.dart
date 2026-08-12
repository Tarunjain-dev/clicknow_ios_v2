import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBookingRequest {
  const AdminBookingRequest({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.bookingCode,
    required this.serviceTitle,
    required this.eventTypeName,
    required this.planName,
    required this.totalAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.gstAmount,
    required this.commissionAmount,
    required this.professionalPayoutAmount,
    required this.basePrice,
    required this.refundEligibility,
    required this.refundPercentage,
    required this.financialBreakdown,
    required this.eventDate,
    required this.eventTime,
    required this.eventDurationHours,
    required this.guestCount,
    required this.venueName,
    required this.venueHouseDetails,
    required this.venueLandmarkDetails,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.bookingStage,
    required this.bookingStatus,
    required this.lifecycleStatus,
    required this.assignedProfessionalId,
    required this.paymentStatus,
    required this.adminVisible,
    required this.statusCode,
    required this.isCanceled,
    required this.rejectionReason,
    required this.rescheduleRequested,
    required this.rescheduleRequestId,
    required this.rescheduleNewEventDate,
    required this.rescheduleNewEventTime,
    required this.rescheduleReason,
    required this.rescheduleRequestedAt,
    required this.professionalDecisionStatus,
    required this.rejectedProfessionalId,
    required this.rejectedProfessionalIds,
    required this.bookingStartTime,
    required this.bookingEndTime,
    required this.bookingDuration,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String userId;
  final String bookingCode;
  final String serviceTitle;
  final String eventTypeName;
  final String planName;
  final int totalAmount;
  final int finalAmount;
  final int paidAmount;
  final int remainingAmount;
  final int discountAmount;
  final int netAmount;
  final int gstAmount;
  final int commissionAmount;
  final int professionalPayoutAmount;
  final int basePrice;
  final String refundEligibility;
  final int refundPercentage;
  final Map<String, dynamic> financialBreakdown;
  final DateTime? eventDate;
  final String eventTime;
  final String eventDurationHours;
  final String guestCount;
  final String venueName;
  final String venueHouseDetails;
  final String venueLandmarkDetails;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final String bookingStage;
  final String bookingStatus;
  final String lifecycleStatus;
  final String assignedProfessionalId;
  final String paymentStatus;
  final bool? adminVisible;
  final String statusCode;
  final bool isCanceled;
  final String rejectionReason;
  final bool rescheduleRequested;
  final String rescheduleRequestId;
  final DateTime? rescheduleNewEventDate;
  final String rescheduleNewEventTime;
  final String rescheduleReason;
  final DateTime? rescheduleRequestedAt;
  final String professionalDecisionStatus;
  final String rejectedProfessionalId;
  final List<String> rejectedProfessionalIds;
  final DateTime? bookingStartTime;
  final DateTime? bookingEndTime;
  final int bookingDuration;
  final DateTime? createdAt;

  factory AdminBookingRequest.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rescheduleRequest = _asMap(data['rescheduleRequest']);
    return AdminBookingRequest(
      id: doc.id,
      requestId: (data['requestId'] as String? ?? doc.id).trim(),
      userId: (data['userId'] as String? ?? '').trim(),
      bookingCode: (data['bookingCode'] as String? ?? 'BID-${doc.id}').trim(),
      serviceTitle: (data['serviceTitle'] as String? ?? 'Service').trim(),
      eventTypeName: (data['eventTypeName'] as String? ?? '-').trim(),
      planName: (data['planName'] as String? ?? '-').trim(),
      totalAmount: _asInt(data['totalAmount']),
      finalAmount: _asInt(
        data['finalAmount'] ?? _asMap(data['payment'])['finalAmount'],
      ),
      paidAmount: _asInt(
        data['paidAmount'] ?? _asMap(data['payment'])['paidAmount'],
      ),
      remainingAmount: _asInt(
        data['remainingAmount'] ?? _asMap(data['payment'])['remainingAmount'],
      ),
      discountAmount: _asInt(
        data['discountAmount'] ?? _asMap(data['payment'])['discountAmount'],
      ),
      netAmount: _asInt(
        data['netAmount'] ?? _asMap(data['payment'])['netAmount'],
      ),
      gstAmount: _asInt(data['gstAmount']),
      commissionAmount: _asInt(
        data['commissionAmount'] ?? _asMap(data['payment'])['commissionAmount'],
      ),
      professionalPayoutAmount: _asInt(
        data['professionalPayoutAmount'] ??
            _asMap(data['payment'])['professionalPayoutAmount'],
      ),
      basePrice: _asInt(data['basePrice']),
      refundEligibility:
          (data['refundEligibility'] ??
                  _asMap(data['payment'])['refundEligibility'] ??
                  '')
              .toString()
              .trim(),
      refundPercentage: _asInt(
        data['refundPercentage'] ?? _asMap(data['payment'])['refundPercentage'],
      ),
      financialBreakdown: _asMap(
        data['financialBreakdown'] ??
            _asMap(data['payment'])['financialBreakdown'],
      ),
      eventDate: _asDateTime(data['eventDate']),
      eventTime: (data['eventTime'] as String? ?? '').trim(),
      eventDurationHours: (data['eventDurationHours'] as String? ?? '').trim(),
      guestCount: (data['guestCount'] as String? ?? '').trim(),
      venueName: (data['venueName'] as String? ?? '').trim(),
      venueHouseDetails: (data['venueHouseDetails'] as String? ?? '').trim(),
      venueLandmarkDetails: (data['venueLandmarkDetails'] as String? ?? '')
          .trim(),
      fullAddress: (data['fullAddress'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      state: (data['state'] as String? ?? '').trim(),
      pincode: (data['pincode'] as String? ?? '').trim(),
      bookingStage: (data['bookingStage'] as String? ?? '').trim(),
      bookingStatus: (data['bookingStatus'] as String? ?? '').trim(),
      lifecycleStatus: (data['lifecycleStatus'] as String? ?? '').trim(),
      assignedProfessionalId: (data['assignedProfessionalId'] as String? ?? '')
          .trim(),
      paymentStatus: _readPaymentStatus(data),
      adminVisible: data['adminVisible'] as bool?,
      statusCode: _readStatusCode(data),
      isCanceled: (data['isCanceled'] as bool?) ?? false,
      rejectionReason: (data['rejectionReason'] as String? ?? '').trim(),
      rescheduleRequested: _hasPendingReschedule(data),
      rescheduleRequestId: _string(rescheduleRequest['requestId']),
      rescheduleNewEventDate: _asDateTime(rescheduleRequest['newEventDate']),
      rescheduleNewEventTime: _string(rescheduleRequest['newEventTime']),
      rescheduleReason: _string(rescheduleRequest['reason']),
      rescheduleRequestedAt: _asDateTime(rescheduleRequest['requestedAt']),
      professionalDecisionStatus:
          (data['professionalDecisionStatus'] as String? ?? '').trim(),
      rejectedProfessionalId:
          (_asMap(data['lastProfessionalRejection'])['professionalId']
                      as String? ??
                  '')
              .trim(),
      rejectedProfessionalIds: _stringList(data['rejectedProfessionalIds']),
      bookingStartTime: _asDateTime(data['bookingStartTime']),
      bookingEndTime: _asDateTime(data['bookingEndTime']),
      bookingDuration: _asInt(data['bookingDuration']),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  String get normalizedStatus {
    if (isCanceled) return 'cancelled';
    final code = statusCode.toUpperCase().trim();
    if (code == 'CANCELED') return 'cancelled';
    return code.toLowerCase();
  }

  String get locationLine {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (fullAddress.isNotEmpty) fullAddress,
      if (pincode.isNotEmpty) pincode,
    ];
    if (parts.isEmpty) return '-';
    return parts.join(', ');
  }

  String get searchableText {
    return [
      id,
      requestId,
      bookingCode,
      userId,
      serviceTitle,
      eventTypeName,
      planName,
      locationLine,
      bookingStatus,
      lifecycleStatus,
      bookingStage,
      assignedProfessionalId,
      rejectionReason,
      rescheduleRequestId,
      rescheduleReason,
      rescheduleNewEventTime,
    ].join(' ').toLowerCase();
  }

  bool get hasSuccessfulPayment {
    final normalizedPayment = paymentStatus.toUpperCase().trim();
    return const <String>{
      'PAID',
      'FULLY_PAID',
      'PARTIALLY_PAID',
      'ADVANCE_PAID',
    }.contains(normalizedPayment);
  }

  bool get isAdminVisible {
    if (adminVisible == false) {
      return false;
    }
    final payment = paymentStatus.toUpperCase().trim();
    final status = normalizedStatus.toUpperCase().trim();
    const allowedPayments = <String>{
      'PAID',
      'FULLY_PAID',
      'PARTIALLY_PAID',
      'ADVANCE_PAID',
      'REFUND_PENDING',
      'REFUND_PROCESSING',
      'PARTIALLY_REFUNDED',
      'REFUNDED',
    };
    const allowedStatuses = <String>{
      'REQUESTED',
      'APPROVED',
      'ASSIGNED',
      'CONFIRMED',
      'ACCEPTED',
      'IN_PROGRESS',
      'COMPLETED',
      'CANCELLED',
      'REJECTED',
      'CANCELLED_BY_ADMIN',
    };
    return allowedPayments.contains(payment) &&
        allowedStatuses.contains(status);
  }

  bool get isBlockedByPayment {
    final normalizedPayment = paymentStatus.toUpperCase().trim();
    return normalizedPayment.isEmpty ||
        const <String>{
          'PENDING_PAYMENT',
          'UNPAID',
          'ORDER_CREATED',
          'PAYMENT_FAILED',
          'PAYMENT_ABANDONED',
          'ABANDONED_PAYMENT',
          'CREATED',
          'FAILED',
          'CANCELLED',
          'CANCELED',
          'REFUNDED',
          'REFUND_PROCESSING',
          'PARTIAL_REFUND_PROCESSING',
        }.contains(normalizedPayment);
  }

  bool get canApprove =>
      normalizedStatus == 'requested' && hasSuccessfulPayment;
  bool get canAssign =>
      hasSuccessfulPayment &&
      (normalizedStatus == 'approved' || normalizedStatus == 'assigned');
  bool get canReassign =>
      normalizedStatus == 'approved' &&
      professionalDecisionStatus.toLowerCase() == 'rejected' &&
      rejectedProfessionalId.isNotEmpty;
  bool get canAdminCancelAssignment {
    final decision = professionalDecisionStatus.toLowerCase();
    return normalizedStatus == 'assigned' &&
        (decision.isEmpty || decision == 'pending') &&
        bookingStage.toLowerCase() != 'event_started';
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

bool _hasPendingReschedule(Map<String, dynamic> data) {
  final request = _asMap(data['rescheduleRequest']);
  final requestStatus = (request['status'] as String? ?? '')
      .trim()
      .toLowerCase();
  if (requestStatus == 'pending') {
    return true;
  }
  return ((data['bookingStage'] as String? ?? '').trim().toLowerCase() ==
      'reschedule_requested');
}

String _readStatusCode(Map<String, dynamic> data) {
  final direct = (data['status'] as String? ?? '').trim().toUpperCase();
  if (direct.isNotEmpty) {
    return direct == 'CANCELED' ? 'CANCELLED' : direct;
  }

  final lifecycle = (data['lifecycleStatus'] as String? ?? '')
      .trim()
      .toLowerCase();
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
    case 'cancelled_by_admin':
      return 'CANCELLED';
    case 'rejected':
      return 'REJECTED';
    case 'reschedule_requested':
      return 'APPROVED';
  }

  final bookingStatus = (data['bookingStatus'] as String? ?? '')
      .trim()
      .toLowerCase();
  switch (bookingStatus) {
    case 'requested':
    case 'pending':
      return 'REQUESTED';
    case 'approved':
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
    case 'cancelled_by_admin':
      return 'CANCELLED';
    case 'rejected':
      return 'REJECTED';
  }
  return 'REQUESTED';
}

String _readPaymentStatus(Map<String, dynamic> data) {
  final direct = (data['paymentStatus'] as String? ?? '').trim();
  if (direct.isNotEmpty) {
    return direct;
  }
  final payment = _asMap(data['payment']);
  return (payment['status'] as String? ?? '').trim();
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _string(dynamic value) => value?.toString().trim() ?? '';

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}
