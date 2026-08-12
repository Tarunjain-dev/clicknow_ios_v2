import 'dart:convert';
import 'dart:math';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

enum BookingStatusCode {
  requested,
  approved,
  assigned,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
}

extension BookingStatusCodeX on BookingStatusCode {
  String get code {
    switch (this) {
      case BookingStatusCode.requested:
        return 'REQUESTED';
      case BookingStatusCode.approved:
        return 'APPROVED';
      case BookingStatusCode.assigned:
        return 'ASSIGNED';
      case BookingStatusCode.confirmed:
        return 'CONFIRMED';
      case BookingStatusCode.inProgress:
        return 'IN_PROGRESS';
      case BookingStatusCode.completed:
        return 'COMPLETED';
      case BookingStatusCode.cancelled:
        return 'CANCELLED';
      case BookingStatusCode.rejected:
        return 'REJECTED';
    }
  }
}

class BookingDraft {
  const BookingDraft({
    required this.cartItemId,
    required this.serviceCatalogId,
    required this.serviceTitle,
    required this.eventTypeId,
    required this.eventTypeName,
    required this.planKey,
    required this.planName,
    required this.basePrice,
    required this.gstPercent,
    required this.gstAmount,
    required this.totalAmount,
    required this.eventDate,
    required this.eventTime,
    required this.eventDurationHours,
    required this.guestCount,
    required this.venueName,
    required this.venueHouseDetails,
    required this.venueLandmarkDetails,
    required this.fullAddress,
    required this.state,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.specialRequirements,
    required this.urgentBooking,
    required this.onsiteContactName,
    required this.onsiteContactPhone,
  });

  final String cartItemId;
  final String serviceCatalogId;
  final String serviceTitle;
  final String eventTypeId;
  final String eventTypeName;
  final String planKey;
  final String planName;
  final int basePrice;
  final double gstPercent;
  final int gstAmount;
  final int totalAmount;
  final DateTime? eventDate;
  final String eventTime;
  final String eventDurationHours;
  final String guestCount;
  final String venueName;
  final String venueHouseDetails;
  final String venueLandmarkDetails;
  final String fullAddress;
  final String state;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final String specialRequirements;
  final bool urgentBooking;
  final String onsiteContactName;
  final String onsiteContactPhone;
}

class BookingCommitResult {
  const BookingCommitResult({
    required this.bookingId,
    required this.bookingCode,
  });

  final String bookingId;
  final String bookingCode;
}

class ProfessionalMatchSuggestion {
  const ProfessionalMatchSuggestion({
    required this.professionalId,
    required this.name,
    required this.phoneNumber,
    required this.score,
    required this.scoreBreakdown,
    required this.serviceType,
    required this.city,
    required this.state,
    required this.pincode,
    required this.experienceYears,
    required this.online,
    required this.languages,
  });

  final String professionalId;
  final String name;
  final String phoneNumber;
  final double score;
  final String scoreBreakdown;
  final String serviceType;
  final String city;
  final String state;
  final String pincode;
  final int experienceYears;
  final bool online;
  final List<String> languages;
}

class ProfessionalBookingRecord {
  const ProfessionalBookingRecord({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceTitle,
    required this.eventTypeName,
    required this.planName,
    required this.venueName,
    required this.venueHouseDetails,
    required this.venueLandmarkDetails,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.eventDate,
    required this.eventTime,
    required this.eventDurationHours,
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
    required this.specialRequirements,
    required this.paymentStatus,
    required this.statusCode,
    required this.lifecycleStatus,
    required this.bookingStatus,
    required this.bookingStage,
    required this.assignedProfessionalId,
    required this.rescheduleRequest,
    required this.bookingStartTime,
    required this.bookingEndTime,
    required this.bookingDuration,
    required this.createdAt,
  });

  final String id;
  final String bookingCode;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceTitle;
  final String eventTypeName;
  final String planName;
  final String venueName;
  final String venueHouseDetails;
  final String venueLandmarkDetails;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final DateTime? eventDate;
  final String eventTime;
  final String eventDurationHours;
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
  final String specialRequirements;
  final String paymentStatus;
  final String statusCode;
  final String lifecycleStatus;
  final String bookingStatus;
  final String bookingStage;
  final String assignedProfessionalId;
  final Map<String, dynamic> rescheduleRequest;
  final DateTime? bookingStartTime;
  final DateTime? bookingEndTime;
  final int bookingDuration;
  final DateTime? createdAt;

  String get locationText {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (fullAddress.isNotEmpty) fullAddress,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }

  factory ProfessionalBookingRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ProfessionalBookingRecord(
      id: doc.id,
      bookingCode: (data['bookingCode'] ?? 'BID-${doc.id}').toString().trim(),
      customerId: (data['userId'] ?? data['customerId'] ?? '')
          .toString()
          .trim(),
      customerName: _readCustomerName(data),
      customerPhone: _readCustomerPhone(data),
      serviceTitle: (data['serviceTitle'] ?? '').toString().trim(),
      eventTypeName: (data['eventTypeName'] ?? '').toString().trim(),
      planName: (data['planName'] ?? '').toString().trim(),
      venueName: (data['venueName'] ?? '').toString().trim(),
      venueHouseDetails: (data['venueHouseDetails'] ?? '').toString().trim(),
      venueLandmarkDetails: (data['venueLandmarkDetails'] ?? '')
          .toString()
          .trim(),
      fullAddress: (data['fullAddress'] ?? '').toString().trim(),
      city: (data['city'] ?? '').toString().trim(),
      state: (data['state'] ?? '').toString().trim(),
      pincode: (data['pincode'] ?? '').toString().trim(),
      eventDate: _asDateTime(data['eventDate']),
      eventTime: (data['eventTime'] ?? '').toString().trim(),
      eventDurationHours: (data['eventDurationHours'] ?? '').toString().trim(),
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
      specialRequirements: (data['specialRequirements'] ?? '')
          .toString()
          .trim(),
      paymentStatus: (data['paymentStatus'] ?? '').toString().trim(),
      statusCode: (data['status'] ?? '').toString().trim(),
      lifecycleStatus: (data['lifecycleStatus'] ?? '').toString().trim(),
      bookingStatus: (data['bookingStatus'] ?? '').toString().trim(),
      bookingStage: (data['bookingStage'] ?? '').toString().trim(),
      assignedProfessionalId: (data['assignedProfessionalId'] ?? '')
          .toString()
          .trim(),
      rescheduleRequest: _asMap(data['rescheduleRequest']),
      bookingStartTime: _asDateTime(data['bookingStartTime']),
      bookingEndTime: _asDateTime(data['bookingEndTime']),
      bookingDuration: _asInt(data['bookingDuration']),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  static String _readCustomerName(Map<String, dynamic> data) {
    final customer = _asMap(data['customer']);
    return (customer['name'] ??
            customer['fullName'] ??
            data['customerName'] ??
            '')
        .toString()
        .trim();
  }

  static String _readCustomerPhone(Map<String, dynamic> data) {
    final customer = _asMap(data['customer']);
    return (customer['phone'] ??
            customer['phoneNumber'] ??
            data['customerPhone'] ??
            '')
        .toString()
        .trim();
  }
}

class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<BookingCommitResult>> createBookingsFromCheckout({
    required String customerId,
    required List<BookingDraft> drafts,
  }) async {
    if (drafts.isEmpty) {
      return const <BookingCommitResult>[];
    }

    final result = <BookingCommitResult>[];
    for (final draft in drafts) {
      final response = await _callBackend(
        'createBookingDraft',
        <String, dynamic>{
          'booking': <String, dynamic>{
            'cartItemId': draft.cartItemId,
            'serviceCatalogId': draft.serviceCatalogId,
            'serviceTitle': draft.serviceTitle,
            'eventTypeId': draft.eventTypeId,
            'eventTypeName': draft.eventTypeName,
            'planKey': draft.planKey,
            'planName': draft.planName,
            'basePrice': draft.basePrice,
            'gstPercent': draft.gstPercent,
            'gstAmount': draft.gstAmount,
            'totalAmount': draft.totalAmount,
            'eventDate': draft.eventDate?.toUtc().toIso8601String(),
            'eventTime': draft.eventTime,
            'eventDurationHours': draft.eventDurationHours,
            'guestCount': draft.guestCount,
            'venueName': draft.venueName,
            'venueHouseDetails': draft.venueHouseDetails,
            'venueLandmarkDetails': draft.venueLandmarkDetails,
            'fullAddress': draft.fullAddress,
            'state': draft.state,
            'city': draft.city,
            'pincode': draft.pincode,
            'latitude': draft.latitude,
            'longitude': draft.longitude,
            'specialRequirements': draft.specialRequirements,
            'urgentBooking': draft.urgentBooking,
            'onsiteContactName': draft.onsiteContactName,
            'onsiteContactPhone': draft.onsiteContactPhone,
          },
        },
      );
      final bookingId = _string(response['bookingId']);
      final bookingCode = _string(response['bookingCode']);
      if (bookingId.isEmpty || bookingCode.isEmpty) {
        throw StateError('Booking server returned an invalid draft.');
      }
      result.add(
        BookingCommitResult(bookingId: bookingId, bookingCode: bookingCode),
      );
    }
    return result;
  }

  Future<Map<String, dynamic>> _callBackend(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please login to continue booking.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify login for booking.');
    }
    final projectId = Firebase.app().options.projectId;
    final response = await http.post(
      Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/$functionName',
      ),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'data': payload}),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _asMap(decoded['error']);
      throw StateError(
        _string(error['message']).isEmpty
            ? 'Booking server request failed.'
            : _string(error['message']),
      );
    }
    return Map<String, dynamic>.from(
      (decoded['result'] as Map?) ?? const <String, dynamic>{},
    );
  }

  Future<void> approveBooking({
    required String bookingId,
    required String adminId,
  }) async {
    await _callBackend('approveBookingByAdmin', <String, dynamic>{
      'bookingId': bookingId,
    });
  }

  Future<void> rejectBooking({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    await _callBackend('cancelUnacceptedBookingByAdmin', <String, dynamic>{
      'bookingId': bookingId,
      'reason': reason.trim(),
    });
  }

  Future<List<ProfessionalMatchSuggestion>> suggestProfessionals({
    required String bookingId,
    int limit = 20,
    List<String> excludeProfessionalIds = const <String>[],
  }) async {
    final booking = await _fetchBookingDoc(bookingId);
    final data = booking.data() ?? <String, dynamic>{};
    final eventDate = _asDateTime(data['eventDate']);
    final city = _string(data['city']).toLowerCase();
    final state = _string(data['state']).toLowerCase();
    final pincode = _string(data['pincode']).toLowerCase();
    final serviceType = _string(data['serviceTitle']);
    final serviceCatalogId = _string(data['serviceCatalogId']);
    final eventTypeName = _string(data['eventTypeName']);
    final requestedPlanType = _string(data['planName']);
    final requestedProfessionalType = _normalizeProfessionalType(
      _firstString(<dynamic>[
        data['professionalType'],
        data['proType'],
        data['customerProfessionalType'],
        requestedPlanType,
      ]),
    );
    final requestedEventTime = _string(data['eventTime']);
    final urgent = (data['urgentBooking'] as bool?) ?? false;

    final rejected = _stringList(data['rejectedProfessionalIds']);
    final excluded = <String>{
      ...excludeProfessionalIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ...rejected,
    };

    final profileSnapshot = await _db.collection('professional_profiles').get();
    final blockedProfessionalIds = await _blockedProfessionalIdsForDate(
      eventDate: eventDate,
      currentBookingId: bookingId,
    );

    final suggestions = <ProfessionalMatchSuggestion>[];
    for (final doc in profileSnapshot.docs) {
      final profile = doc.data();
      final professionalId = doc.id;
      if (excluded.contains(professionalId) ||
          blockedProfessionalIds.contains(professionalId)) {
        continue;
      }
      if (!_isAccountActiveData(profile)) {
        continue;
      }

      final status = _string(profile['status']).toLowerCase();
      if (!const <String>{
        'approved',
        'verified',
        'online',
        'active',
        'available',
      }.contains(status)) {
        continue;
      }

      final services = _asMap(profile['services']);
      final serviceText = _string(services['serviceType']);
      if (!_serviceMatches(
        bookingServiceType: serviceType,
        bookingCatalogId: serviceCatalogId,
        professionalServiceType: serviceText,
      )) {
        continue;
      }

      final specialities = _stringList(services['specialities']);
      if (!_eventTypeMatches(eventTypeName, specialities)) {
        continue;
      }

      final address = _asMap(profile['address']);
      final professionalCity = _string(address['city']);
      final professionalState = _string(address['state']);
      final professionalPincode = _string(address['pincode']);

      final professional = _asMap(profile['professional']);
      final languages = _stringList(_asMap(profile['basicInfo'])['languages']);
      final experienceYears = _asInt(professional['experienceYears']);
      final workingDays = _stringList(professional['workingDays']);
      final workingLocations = _locationPairs(professional['workingLocations']);
      final secondaryLocations = _locationPairs(
        professional['secondaryLocations'],
      );
      final availability = _asMap(profile['availability']);
      final profilePlanType = _firstString(<dynamic>[
        services['planType'],
        services['servicePlanType'],
        professional['planType'],
        profile['planType'],
      ]);
      if (!_planTypeMatches(requestedPlanType, profilePlanType)) {
        continue;
      }
      final profileProfessionalType = _normalizeProfessionalType(
        _firstString(<dynamic>[
          professional['professionalType'],
          professional['proType'],
          professional['workType'],
          services['professionalType'],
          profile['professionalType'],
        ]),
      );
      if (!_professionalTypeMatches(
        requestedType: requestedProfessionalType,
        profileType: profileProfessionalType,
        experienceYears: experienceYears,
      )) {
        continue;
      }
      if (!_timeSlotMatches(
        bookingTime: requestedEventTime,
        availability: availability,
      )) {
        continue;
      }
      final unavailableDateKeys = _stringList(availability['unavailableDates']);
      final urgentAvailable =
          (availability['urgentAvailable'] as bool?) ?? false;
      final online = _isOnline(profile);

      if (eventDate != null) {
        final eventKey = _dateKey(eventDate);
        if (unavailableDateKeys.contains(eventKey) ||
            !_workingDayMatches(eventDate, workingDays)) {
          continue;
        }
      }

      final locationBoost = _locationScore(
        bookingCity: city,
        bookingState: state,
        bookingPincode: pincode,
        profileCity: professionalCity.toLowerCase(),
        profileState: professionalState.toLowerCase(),
        profilePincode: professionalPincode.toLowerCase(),
        workingLocations: workingLocations,
        secondaryLocations: secondaryLocations,
      );
      if (locationBoost <= 0) {
        continue;
      }

      final performance = _asMap(profile['performance']);
      final acceptanceRate = _asDouble(performance['acceptanceRate']);
      final cancellationRate = _asDouble(performance['cancellationRate']);
      final rating = _asDouble(
        _firstString(<dynamic>[performance['rating'], profile['rating']]),
      );
      final score = _totalScore(
        locationScore: locationBoost,
        experienceYears: experienceYears,
        acceptanceRate: acceptanceRate,
        cancellationRate: cancellationRate,
        rating: rating,
        online: online,
        urgentBooking: urgent,
        urgentAvailable: urgentAvailable,
      );

      suggestions.add(
        ProfessionalMatchSuggestion(
          professionalId: professionalId,
          name: _string(_asMap(profile['basicInfo'])['fullName']),
          phoneNumber: _string(profile['phoneNumber']),
          score: score,
          scoreBreakdown:
              'Location match ${locationBoost.toStringAsFixed(1)} | Experience $experienceYears yrs | Acceptance ${acceptanceRate.toStringAsFixed(1)} | Cancellation ${cancellationRate.toStringAsFixed(1)} | Rating ${rating.toStringAsFixed(1)} | ${online ? "Online now" : "Offline"}',
          serviceType: serviceText,
          city: professionalCity,
          state: professionalState,
          pincode: professionalPincode,
          experienceYears: experienceYears,
          online: online,
          languages: languages,
        ),
      );
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(limit).toList(growable: false);
  }

  Future<bool> autoAssignBooking({
    required String bookingId,
    required String adminId,
  }) async {
    final suggestions = await suggestProfessionals(
      bookingId: bookingId,
      limit: 1,
    );
    if (suggestions.isEmpty) {
      return false;
    }
    final top = suggestions.first;
    await assignProfessional(
      bookingId: bookingId,
      professionalId: top.professionalId,
      adminId: adminId,
      autoAssigned: true,
      score: top.score,
      scoreBreakdown: top.scoreBreakdown,
    );
    return true;
  }

  Future<bool> autoAssignProfessional({
    required String bookingId,
    required String adminId,
  }) async {
    return autoAssignBooking(bookingId: bookingId, adminId: adminId);
  }

  Future<void> manualAssignProfessional({
    required String bookingId,
    required String professionalId,
    required String adminId,
  }) async {
    await assignProfessional(
      bookingId: bookingId,
      professionalId: professionalId,
      adminId: adminId,
      autoAssigned: false,
    );
  }

  Future<void> assignProfessional({
    required String bookingId,
    required String professionalId,
    required String adminId,
    bool autoAssigned = false,
    double? score,
    String? scoreBreakdown,
  }) async {
    await _callBackend('assignBookingByAdmin', <String, dynamic>{
      'bookingId': bookingId,
      'professionalId': professionalId,
      'autoAssigned': autoAssigned,
      'score': score,
      'scoreBreakdown': scoreBreakdown ?? '',
    });
  }

  Future<void> acceptBooking({
    required String bookingId,
    required String professionalId,
  }) async {
    await _callBackend('professionalRespondToBooking', <String, dynamic>{
      'bookingId': bookingId,
      'accepted': true,
    });
  }

  Future<void> rejectBookingByProfessional({
    required String bookingId,
    required String professionalId,
    required String reason,
  }) async {
    await _callBackend('professionalRespondToBooking', <String, dynamic>{
      'bookingId': bookingId,
      'accepted': false,
      'reason': reason.trim(),
    });
  }

  @Deprecated('Use acceptBooking for professional-driven confirmation flow.')
  Future<void> confirmBooking({
    required String bookingId,
    required String customerId,
  }) async {
    throw StateError(
      'Customer confirmation is disabled. Professional must accept booking.',
    );
  }

  Future<void> startBooking({
    required String bookingId,
    required String professionalId,
  }) async {
    throw StateError(
      'Direct booking start is disabled. Use the OTP-verified backend flow.',
    );
  }

  Future<void> endBooking({
    required String bookingId,
    required String professionalId,
  }) async {
    await _callBackend('endBooking', <String, dynamic>{'bookingId': bookingId});
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String actorId,
    required DateTime newDate,
    required String newTime,
    String reason = '',
  }) async {
    await _callBackend('requestBookingReschedule', <String, dynamic>{
      'bookingId': bookingId,
      'newEventDate': newDate.toUtc().toIso8601String(),
      'newEventTime': newTime.trim(),
      'reason': reason.trim(),
    });
  }

  Future<void> cancelBookingByCustomer({
    required String bookingId,
    required String reason,
  }) async {
    await _callBackend('cancelBookingByCustomer', <String, dynamic>{
      'bookingId': bookingId,
      'reason': reason.trim(),
    });
  }

  Future<void> approveReschedule({
    required String bookingId,
    required String adminId,
  }) async {
    await _callBackend('adminReviewBookingReschedule', <String, dynamic>{
      'bookingId': bookingId,
      'action': 'APPROVE',
    });
  }

  Future<void> cancelAssignedBookingForReassignment({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    await _callBackend('cancelAssignmentForReassignment', <String, dynamic>{
      'bookingId': bookingId,
      'reason': reason.trim(),
    });
  }

  Future<void> rejectReschedule({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    await _callBackend('adminReviewBookingReschedule', <String, dynamic>{
      'bookingId': bookingId,
      'action': 'REJECT',
      'reason': reason.trim(),
    });
  }

  Future<void> professionalRespond({
    required String bookingId,
    required String professionalId,
    required bool accepted,
    String reason = '',
  }) async {
    if (accepted) {
      await acceptBooking(bookingId: bookingId, professionalId: professionalId);
      return;
    }
    await rejectBookingByProfessional(
      bookingId: bookingId,
      professionalId: professionalId,
      reason: reason,
    );
  }

  Future<void> requestReschedule({
    required String bookingId,
    required String customerId,
    required DateTime newDate,
    required String newTime,
    String reason = '',
  }) async {
    await rescheduleBooking(
      bookingId: bookingId,
      actorId: customerId,
      newDate: newDate,
      newTime: newTime,
      reason: reason,
    );
  }

  Future<void> rejectBookingByAdmin({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    await _callBackend('cancelUnacceptedBookingByAdmin', <String, dynamic>{
      'bookingId': bookingId,
      'reason': reason.trim(),
    });
  }

  Future<void> markCompleted({
    required String bookingId,
    required String actorId,
  }) async {
    await endBooking(bookingId: bookingId, professionalId: actorId);
  }

  Stream<List<ProfessionalBookingRecord>> streamProfessionalBookings(
    String professionalId,
  ) {
    return _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(professionalId)
        .collection(
          ServiceCatalogPaths.professionalBookingRequestsSubcollection,
        )
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map(ProfessionalBookingRecord.fromDoc)
              .toList(growable: false);
          records.sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return records;
        });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchBookingDoc(
    String bookingId,
  ) async {
    final primary = await _db
        .collection(ServiceCatalogPaths.bookingsCollection)
        .doc(bookingId)
        .get();
    if (!primary.exists) {
      throw StateError('Booking not found');
    }
    return primary;
  }

  Future<Set<String>> _blockedProfessionalIdsForDate({
    required DateTime? eventDate,
    required String currentBookingId,
  }) async {
    if (eventDate == null) {
      return <String>{};
    }
    final dayStart = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _db
        .collection(ServiceCatalogPaths.bookingsCollection)
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
        )
        .where('eventDate', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    final blocked = <String>{};
    for (final doc in snapshot.docs) {
      if (doc.id == currentBookingId) {
        continue;
      }
      final data = doc.data();
      final lifecycle = _string(data['lifecycleStatus']).toLowerCase();
      if (!const <String>{
        'assigned',
        'confirmed',
        'completed',
      }.contains(lifecycle)) {
        continue;
      }
      final assigned = _string(data['assignedProfessionalId']).trim();
      if (assigned.isNotEmpty) {
        blocked.add(assigned);
      }
    }
    return blocked;
  }

  bool _serviceMatches({
    required String bookingServiceType,
    required String bookingCatalogId,
    required String professionalServiceType,
  }) {
    final booking = bookingServiceType.toLowerCase().trim();
    final professional = professionalServiceType.toLowerCase().trim();
    if (booking.isEmpty && bookingCatalogId.isEmpty) {
      return true;
    }
    if (professional.isEmpty) {
      return false;
    }
    if (professional.contains(booking) || booking.contains(professional)) {
      return true;
    }
    final catalogMap = <String, List<String>>{
      'photo_videography': <String>['photo', 'videography'],
      'music_live_performance': <String>['music', 'live performance'],
      'professional_dj': <String>['dj'],
      'live_wedding_painter': <String>['wedding painter', 'painter'],
      'professional_anchor': <String>['anchor'],
      'professional_magician': <String>['magician'],
    };
    final aliases = catalogMap[bookingCatalogId] ?? const <String>[];
    return aliases.any((alias) => professional.contains(alias));
  }

  bool _eventTypeMatches(String bookingEventType, List<String> specialities) {
    final normalizedBooking = bookingEventType.toLowerCase().trim();
    if (normalizedBooking.isEmpty) {
      return true;
    }
    if (specialities.isEmpty) {
      return false;
    }
    for (final item in specialities) {
      final normalizedItem = item.toLowerCase().trim();
      if (normalizedItem == normalizedBooking ||
          normalizedItem.contains(normalizedBooking) ||
          normalizedBooking.contains(normalizedItem)) {
        return true;
      }
    }
    return false;
  }

  bool _planTypeMatches(String requestedPlan, String profilePlan) {
    final requested = requestedPlan.toLowerCase().trim();
    if (requested.isEmpty) {
      return true;
    }
    final profile = profilePlan.toLowerCase().trim();
    if (profile.isEmpty) {
      // Keep backward compatibility where plan type is not modeled on profile.
      return true;
    }
    if (requested.contains('professional')) {
      return profile.contains('professional') || profile.contains('pro');
    }
    if (requested.contains('normal')) {
      return profile.contains('normal') || profile.contains('standard');
    }
    if (requested.contains('default') || requested.contains('basic')) {
      return profile.contains('default') ||
          profile.contains('basic') ||
          profile.contains('starter');
    }
    return profile.contains(requested) || requested.contains(profile);
  }

  bool _professionalTypeMatches({
    required String requestedType,
    required String profileType,
    required int experienceYears,
  }) {
    final requested = requestedType.toLowerCase().trim();
    if (requested.isEmpty) {
      return true;
    }
    final profile = profileType.toLowerCase().trim();
    if (profile.isNotEmpty &&
        (profile.contains(requested) || requested.contains(profile))) {
      return true;
    }
    if (requested == 'pro' || requested == 'professional') {
      return experienceYears >= 5;
    }
    if (requested == 'normal' || requested == 'standard') {
      return experienceYears < 8;
    }
    return true;
  }

  bool _timeSlotMatches({
    required String bookingTime,
    required Map<String, dynamic> availability,
  }) {
    final normalizedBooking = bookingTime.trim().toLowerCase();
    if (normalizedBooking.isEmpty) {
      return true;
    }
    final start = _firstString(<dynamic>[
      availability['startTime'],
      availability['fromTime'],
      availability['workingStartTime'],
    ]);
    final end = _firstString(<dynamic>[
      availability['endTime'],
      availability['toTime'],
      availability['workingEndTime'],
    ]);
    if (start.isEmpty || end.isEmpty) {
      // If availability slot isn't modeled yet, do not block assignment.
      return true;
    }
    final bookingHour = _extractHour(normalizedBooking);
    final startHour = _extractHour(start.toLowerCase().trim());
    final endHour = _extractHour(end.toLowerCase().trim());
    if (bookingHour == null || startHour == null || endHour == null) {
      return true;
    }
    if (endHour >= startHour) {
      return bookingHour >= startHour && bookingHour <= endHour;
    }
    // Overnight shift availability.
    return bookingHour >= startHour || bookingHour <= endHour;
  }

  int? _extractHour(String raw) {
    final match = RegExp(r'(\d{1,2})').firstMatch(raw);
    if (match == null) {
      return null;
    }
    final number = int.tryParse(match.group(1) ?? '');
    if (number == null) {
      return null;
    }
    final isPm = raw.contains('pm');
    final isAm = raw.contains('am');
    var hour = number;
    if (isPm && hour < 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }
    return hour.clamp(0, 23).toInt();
  }

  String _normalizeProfessionalType(String raw) {
    final text = raw.toLowerCase().trim();
    if (text.contains('professional') || text == 'pro') {
      return 'professional';
    }
    if (text.contains('normal') || text.contains('standard')) {
      return 'normal';
    }
    if (text.contains('default') || text.contains('basic')) {
      return 'basic';
    }
    return text;
  }

  bool _workingDayMatches(DateTime eventDate, List<String> workingDays) {
    if (workingDays.isEmpty) {
      return true;
    }
    const weekDays = <int, String>{
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'sunday',
    };
    final day = weekDays[eventDate.weekday] ?? '';
    return workingDays.any((item) => item.toLowerCase().trim() == day);
  }

  List<Map<String, String>> _locationPairs(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, String>>[];
    }
    final items = <Map<String, String>>[];
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(entry);
      final state = _string(map['state']).toLowerCase();
      final cities = _stringList(map['cities']).map((e) => e.toLowerCase());
      for (final city in cities) {
        items.add(<String, String>{'state': state, 'city': city});
      }
    }
    return items;
  }

  double _locationScore({
    required String bookingCity,
    required String bookingState,
    required String bookingPincode,
    required String profileCity,
    required String profileState,
    required String profilePincode,
    required List<Map<String, String>> workingLocations,
    required List<Map<String, String>> secondaryLocations,
  }) {
    var score = 0.0;
    if (bookingCity.isNotEmpty && profileCity == bookingCity) {
      score += 40;
    }
    if (bookingState.isNotEmpty && profileState == bookingState) {
      score += 22;
    }
    if (bookingPincode.isNotEmpty && profilePincode == bookingPincode) {
      score += 18;
    }
    if (workingLocations.any(
      (loc) => loc['city'] == bookingCity && loc['state'] == bookingState,
    )) {
      score += 20;
    }
    if (secondaryLocations.any(
      (loc) => loc['city'] == bookingCity && loc['state'] == bookingState,
    )) {
      score += 12;
    }
    if (score == 0 && bookingState.isNotEmpty) {
      final hasStateCoverage =
          workingLocations.any((loc) => loc['state'] == bookingState) ||
          secondaryLocations.any((loc) => loc['state'] == bookingState);
      if (hasStateCoverage) {
        score += 8;
      }
    }
    return score;
  }

  double _totalScore({
    required double locationScore,
    required int experienceYears,
    required double acceptanceRate,
    required double cancellationRate,
    required double rating,
    required bool online,
    required bool urgentBooking,
    required bool urgentAvailable,
  }) {
    var score = locationScore;
    score += min(max(experienceYears, 0), 20) * 2.1;
    score += acceptanceRate * 0.35;
    score -= cancellationRate * 0.28;
    score += rating * 6.0;
    if (online) {
      score += 16;
    }
    if (urgentBooking) {
      score += urgentAvailable ? 12 : -12;
    } else {
      score += 4;
    }
    return score;
  }

  bool _isOnline(Map<String, dynamic> profile) {
    final availability = _asMap(profile['availability']);
    final statusCandidates = <String>[
      _string(profile['professionalAvailabilityStatus']),
      _string(availability['professionalAvailabilityStatus']),
      _string(availability['visibilityStatus']),
      _string(availability['status']),
    ].map((e) => e.toLowerCase().trim());
    return statusCandidates.any(
      (item) => item == 'online' || item == 'active' || item == 'available',
    );
  }

  bool _isAccountActiveData(Map<String, dynamic> data) {
    final status = _string(data['accountStatus']).toUpperCase();
    return status != 'SUSPENDED' && status != 'BLOCKED';
  }
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

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

String _string(dynamic value) {
  return value?.toString().trim() ?? '';
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    final parsed = _string(value);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return '';
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final parsed = int.tryParse(_string(value));
  return parsed ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final parsed = double.tryParse(_string(value));
  return parsed ?? fallback;
}

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

String _dateKey(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
