import 'dart:async';

import 'package:clicknow_version2/app/screens/admin/bookings/models/admin_booking_request.dart';
import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AdminBookingsController extends GetxController {
  static const Set<String> _manualAssignableStatuses = <String>{
    'approved',
    'verified',
    'online',
    'active',
    'available',
  };

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BookingService _bookingService = BookingService.instance;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxMap<String, bool> actionLoadingByKey = <String, bool>{}.obs;

  final RxList<AdminBookingRequest> allBookings = <AdminBookingRequest>[].obs;
  final RxList<AdminBookingRequest> filteredBookings =
      <AdminBookingRequest>[].obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingSub;

  int get totalCount => allBookings.length;
  int get pendingCount => allBookings
      .where((booking) => booking.normalizedStatus == 'requested')
      .length;
  int get confirmedCount => allBookings
      .where(
        (booking) =>
            booking.normalizedStatus == 'confirmed' ||
            booking.normalizedStatus == 'in_progress',
      )
      .length;

  bool isActionLoading(String bookingId, {String action = 'all'}) {
    if (action == 'all') {
      final prefix = '$bookingId::';
      for (final entry in actionLoadingByKey.entries) {
        if (entry.value && entry.key.startsWith(prefix)) {
          return true;
        }
      }
      return false;
    }
    return actionLoadingByKey['$bookingId::$action'] == true;
  }

  @override
  void onInit() {
    super.onInit();
    _listenBookings();
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
    _applyFilters();
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
    _applyFilters();
  }

  Future<void> refreshBookings({bool showMessage = false}) async {
    isRefreshing.value = true;
    try {
      final snapshot = await _db
          .collection(ServiceCatalogPaths.bookingsCollection)
          .orderBy('createdAt', descending: true)
          .get();
      _consumeSnapshot(snapshot.docs);
      if (showMessage) {
        AppSnackbar.success('Refreshed', 'Bookings list refreshed.');
      }
    } catch (_) {
      if (showMessage) {
        AppSnackbar.error('Refresh Failed', 'Unable to refresh bookings.');
      }
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> approveBooking(AdminBookingRequest booking) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    if (!booking.canApprove) {
      if (booking.isBlockedByPayment) {
        AppSnackbar.error(
          'Payment Required',
          'Customer payment must succeed before this booking can be approved.',
        );
      } else {
        AppSnackbar.success('Info', 'This booking is already processed.');
      }
      return false;
    }

    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::approve';
    actionLoadingByKey[actionKey] = true;
    try {
      await _bookingService.approveBooking(bookingId: booking.id, adminId: uid);
      AppSnackbar.success('Approved', 'Booking approved successfully.');
      return true;
    } catch (error) {
      AppSnackbar.error(
        'Approval Failed',
        _errorMessage(error, 'Unable to approve booking.'),
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<bool> rejectBooking({
    required AdminBookingRequest booking,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.error('Reason Required', 'Please add rejection reason.');
      return false;
    }

    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::reject';
    actionLoadingByKey[actionKey] = true;
    try {
      await _bookingService.rejectBookingByAdmin(
        bookingId: booking.id,
        adminId: uid,
        reason: trimmed,
      );
      AppSnackbar.success(
        'Cancelled',
        'Booking cancelled and the exact eligible refund was started.',
      );
      return true;
    } catch (_) {
      AppSnackbar.error('Cancellation Failed', 'Unable to cancel booking.');
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<List<ProfessionalMatchSuggestion>> fetchSuggestions(
    AdminBookingRequest booking,
  ) async {
    List<ProfessionalMatchSuggestion> suggested =
        const <ProfessionalMatchSuggestion>[];
    try {
      suggested = await _bookingService.suggestProfessionals(
        bookingId: booking.id,
        limit: 40,
      );
    } catch (_) {}

    try {
      final fallbackCandidates = await _fetchManualAssignableProfessionals(
        booking: booking,
        excludeIds: <String>{
          ...suggested.map((item) => item.professionalId),
          ...booking.rejectedProfessionalIds,
          if (booking.rejectedProfessionalId.isNotEmpty)
            booking.rejectedProfessionalId,
        },
        limit: 100,
      );
      return <ProfessionalMatchSuggestion>[...suggested, ...fallbackCandidates];
    } catch (_) {
      if (suggested.isNotEmpty) {
        return suggested;
      }
      AppSnackbar.error(
        'Manual Assign Failed',
        'Could not load professionals for manual assignment.',
      );
      return const <ProfessionalMatchSuggestion>[];
    }
  }

  Future<List<ProfessionalMatchSuggestion>>
  _fetchManualAssignableProfessionals({
    required AdminBookingRequest booking,
    required Set<String> excludeIds,
    int limit = 100,
  }) async {
    final snapshot = await _db.collection('professional_profiles').get();
    final candidates = <ProfessionalMatchSuggestion>[];

    for (final doc in snapshot.docs) {
      final professionalId = doc.id.trim();
      if (professionalId.isEmpty || excludeIds.contains(professionalId)) {
        continue;
      }

      final profile = doc.data();
      final status = _normalize(profile['status']);
      if (!_manualAssignableStatuses.contains(status)) {
        continue;
      }

      final basicInfo = _asMap(profile['basicInfo']);
      final services = _asMap(profile['services']);
      final address = _asMap(profile['address']);
      final professional = _asMap(profile['professional']);

      final serviceType = _string(services['serviceType']);
      final city = _string(address['city']);
      final state = _string(address['state']);
      final pincode = _string(address['pincode']);
      final online = _isOnline(profile);
      final experienceYears = _asInt(professional['experienceYears']);
      final score = _manualPoolScore(
        booking: booking,
        serviceType: serviceType,
        city: city,
        state: state,
        pincode: pincode,
        online: online,
        experienceYears: experienceYears,
      );

      candidates.add(
        ProfessionalMatchSuggestion(
          professionalId: professionalId,
          name: _string(basicInfo['fullName']),
          phoneNumber: _string(profile['phoneNumber']),
          score: score,
          scoreBreakdown:
              'Service ${serviceType.isEmpty ? "unknown" : serviceType} | Location ${city.isEmpty ? state : "$city, $state"} | Experience $experienceYears yrs | ${online ? "Online now" : "Offline"}',
          serviceType: serviceType,
          city: city,
          state: state,
          pincode: pincode,
          experienceYears: experienceYears,
          online: online,
          languages: _stringList(basicInfo['languages']),
        ),
      );
    }

    candidates.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final experienceCompare = right.experienceYears.compareTo(
        left.experienceYears,
      );
      if (experienceCompare != 0) {
        return experienceCompare;
      }
      return _string(
        left.name,
      ).toLowerCase().compareTo(_string(right.name).toLowerCase());
    });

    return candidates.take(limit).toList(growable: false);
  }

  double _manualPoolScore({
    required AdminBookingRequest booking,
    required String serviceType,
    required String city,
    required String state,
    required String pincode,
    required bool online,
    required int experienceYears,
  }) {
    final bookingService = _normalize(booking.serviceTitle);
    final bookingCity = _normalize(booking.city);
    final bookingState = _normalize(booking.state);
    final bookingPincode = _normalize(booking.pincode);
    final profileService = _normalize(serviceType);
    final profileCity = _normalize(city);
    final profileState = _normalize(state);
    final profilePincode = _normalize(pincode);

    var score = 8.0;
    if (profileService.isNotEmpty &&
        bookingService.isNotEmpty &&
        (profileService.contains(bookingService) ||
            bookingService.contains(profileService))) {
      score += 40;
    }
    if (bookingCity.isNotEmpty && bookingCity == profileCity) {
      score += 25;
    } else if (bookingState.isNotEmpty && bookingState == profileState) {
      score += 12;
    }
    if (bookingPincode.isNotEmpty && bookingPincode == profilePincode) {
      score += 10;
    }
    if (online) {
      score += 5;
    }
    score += experienceYears.clamp(0, 20).toDouble();
    return score;
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

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _normalize(dynamic value) {
    return _string(value).toLowerCase();
  }

  String _errorMessage(Object error, String fallback) {
    if (error is StateError && error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool _isOnline(Map<String, dynamic> profile) {
    final rootStatus = _normalize(profile['status']);
    if (rootStatus == 'online') {
      return true;
    }
    final availability = _asMap(profile['availability']);
    final availabilityStatus = _normalize(availability['status']);
    if (availabilityStatus == 'online' || availabilityStatus == 'available') {
      return true;
    }
    return (profile['isOnline'] as bool?) ?? false;
  }

  Future<bool> autoAssign(AdminBookingRequest booking) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::auto_assign';
    actionLoadingByKey[actionKey] = true;
    try {
      if (!booking.canAssign) {
        AppSnackbar.error(
          'Payment Required',
          'Only paid or partially paid bookings can be assigned.',
        );
        return false;
      }
      final assigned = await _bookingService.autoAssignProfessional(
        bookingId: booking.id,
        adminId: uid,
      );
      if (!assigned) {
        AppSnackbar.error(
          'No Professional Available',
          'No matching professional found for auto assignment.',
        );
        return false;
      }
      AppSnackbar.success('Assigned', 'Professional assigned automatically.');
      return true;
    } catch (error) {
      AppSnackbar.error(
        'Assign Failed',
        _errorMessage(error, 'Unable to auto assign booking.'),
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<ProfessionalMatchSuggestion?> topAutoAssignSuggestion(
    AdminBookingRequest booking,
  ) async {
    try {
      final suggestions = await _bookingService.suggestProfessionals(
        bookingId: booking.id,
        limit: 1,
      );
      return suggestions.isEmpty ? null : suggestions.first;
    } catch (_) {
      return null;
    }
  }

  Future<bool> assignAutoRecommendation({
    required AdminBookingRequest booking,
    required ProfessionalMatchSuggestion suggestion,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    final actionKey = '${booking.id}::auto_assign';
    actionLoadingByKey[actionKey] = true;
    try {
      if (!booking.canAssign) {
        AppSnackbar.error(
          'Payment Required',
          'Only paid or partially paid bookings can be assigned.',
        );
        return false;
      }
      await _bookingService.assignProfessional(
        bookingId: booking.id,
        professionalId: suggestion.professionalId,
        adminId: uid,
        autoAssigned: true,
        score: suggestion.score,
        scoreBreakdown: suggestion.scoreBreakdown,
      );
      AppSnackbar.success(
        'Auto Assigned',
        '${suggestion.name.trim().isEmpty ? "Professional" : suggestion.name} assigned with score ${suggestion.score.toStringAsFixed(1)}.',
      );
      return true;
    } catch (error) {
      AppSnackbar.error(
        'Assign Failed',
        _errorMessage(error, 'Unable to auto assign booking.'),
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<bool> assignToProfessional({
    required AdminBookingRequest booking,
    required ProfessionalMatchSuggestion suggestion,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::manual_assign';
    actionLoadingByKey[actionKey] = true;
    try {
      if (!booking.canAssign) {
        AppSnackbar.error(
          'Payment Required',
          'Only paid or partially paid bookings can be assigned.',
        );
        return false;
      }
      await _bookingService.manualAssignProfessional(
        bookingId: booking.id,
        professionalId: suggestion.professionalId,
        adminId: uid,
      );
      AppSnackbar.success(
        'Assigned',
        '${suggestion.name.trim().isEmpty ? "Professional" : suggestion.name} assigned successfully.',
      );
      return true;
    } catch (error) {
      AppSnackbar.error(
        'Assign Failed',
        _errorMessage(error, 'Could not assign professional.'),
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<bool> cancelAssignmentForReassignment({
    required AdminBookingRequest booking,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      AppSnackbar.error('Reason Required', 'Please add cancellation reason.');
      return false;
    }
    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::cancel_assignment';
    actionLoadingByKey[actionKey] = true;
    try {
      await _bookingService.cancelAssignedBookingForReassignment(
        bookingId: booking.id,
        adminId: uid,
        reason: trimmedReason,
      );
      AppSnackbar.success(
        'Assignment Cancelled',
        'Booking is available for reassignment.',
      );
      return true;
    } catch (_) {
      AppSnackbar.error('Cancel Failed', 'Could not cancel this assignment.');
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<bool> approveReschedule(AdminBookingRequest booking) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    if (!booking.rescheduleRequested) {
      AppSnackbar.success('Info', 'No pending reschedule request found.');
      return false;
    }
    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::approve_reschedule';
    actionLoadingByKey[actionKey] = true;
    try {
      await _bookingService.approveReschedule(
        bookingId: booking.id,
        adminId: uid,
      );
      AppSnackbar.success('Rescheduled', 'Reschedule request approved.');
      return true;
    } catch (_) {
      AppSnackbar.error(
        'Reschedule Failed',
        'Unable to approve reschedule request.',
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<bool> rejectReschedule({
    required AdminBookingRequest booking,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.error('Reason Required', 'Please add rejection reason.');
      return false;
    }
    if (isActionLoading(booking.id, action: 'all')) {
      return false;
    }
    final actionKey = '${booking.id}::reject_reschedule';
    actionLoadingByKey[actionKey] = true;
    try {
      await _bookingService.rejectReschedule(
        bookingId: booking.id,
        adminId: uid,
        reason: trimmed,
      );
      AppSnackbar.success('Rejected', 'Reschedule request rejected.');
      return true;
    } catch (_) {
      AppSnackbar.error(
        'Reject Failed',
        'Unable to reject reschedule request.',
      );
      return false;
    } finally {
      actionLoadingByKey.remove(actionKey);
    }
  }

  Future<void> _listenBookings() async {
    await refreshBookings();
    _bookingSub = _db
        .collection(ServiceCatalogPaths.bookingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _consumeSnapshot(snapshot.docs);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error('Fetch Failed', 'Unable to fetch bookings.');
          },
        );
  }

  void _consumeSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final parsed =
        docs
            .map(AdminBookingRequest.fromDoc)
            .where((booking) => booking.isAdminVisible)
            .toList(growable: false)
          ..sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });

    allBookings.assignAll(parsed);
    _applyFilters();
  }

  void _applyFilters() {
    final query = searchQuery.value;
    final status = selectedStatus.value;

    filteredBookings.assignAll(
      allBookings.where((booking) {
        if (status != 'all') {
          final bookingStatus = booking.normalizedStatus;
          if (status == 'pending_requests' && bookingStatus != 'requested') {
            return false;
          }
          if (status == 'active' &&
              bookingStatus != 'confirmed' &&
              bookingStatus != 'in_progress') {
            return false;
          }
          if (status == 'rejected' && bookingStatus != 'rejected') {
            return false;
          }
          if (status != 'pending_requests' &&
              status != 'active' &&
              status != 'rejected' &&
              bookingStatus != status) {
            return false;
          }
        }
        if (query.isNotEmpty && !booking.searchableText.contains(query)) {
          return false;
        }
        return true;
      }),
    );
  }

  int countForStatusTab(String statusKey) {
    return allBookings.where((booking) {
      final bookingStatus = booking.normalizedStatus;
      if (statusKey == 'all') {
        return true;
      }
      if (statusKey == 'pending_requests') {
        return bookingStatus == 'requested';
      }
      if (statusKey == 'active') {
        return bookingStatus == 'confirmed' || bookingStatus == 'in_progress';
      }
      return bookingStatus == statusKey;
    }).length;
  }

  @override
  void onClose() {
    _bookingSub?.cancel();
    super.onClose();
  }
}
