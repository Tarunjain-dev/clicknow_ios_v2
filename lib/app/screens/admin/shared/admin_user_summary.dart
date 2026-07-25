import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserSummary {
  const AdminUserSummary({
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.rejectedBookings,
    required this.totalSupportTickets,
    required this.openSupportTickets,
    required this.resolvedSupportTickets,
  });

  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int rejectedBookings;
  final int totalSupportTickets;
  final int openSupportTickets;
  final int resolvedSupportTickets;
}

class AdminUserSummaryService {
  AdminUserSummaryService._();

  static final instance = AdminUserSummaryService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AdminUserSummary> load({
    required String userId,
    required String role,
  }) async {
    final bookingsFuture = role == 'professional'
        ? _db
              .collection(ServiceCatalogPaths.bookingsCollection)
              .where('assignedProfessionalId', isEqualTo: userId)
              .get()
        : _db
              .collection(ServiceCatalogPaths.bookingsCollection)
              .where('customerId', isEqualTo: userId)
              .get();
    final ticketsFuture = _db
        .collection(ServiceCatalogPaths.supportTicketsCollection)
        .where('raisedByUserId', isEqualTo: userId)
        .get();
    final results = await Future.wait([bookingsFuture, ticketsFuture]);
    final bookings = results[0].docs;
    final tickets = results[1].docs;

    final bookingStatuses = bookings
        .map(
          (doc) => _status(doc.data(), const <String>[
            'status',
            'lifecycleStatus',
            'bookingStatus',
          ]),
        )
        .toList(growable: false);
    final ticketStatuses = tickets
        .map((doc) => _status(doc.data(), const <String>['status']))
        .toList(growable: false);
    return AdminUserSummary(
      totalBookings: bookings.length,
      activeBookings: bookingStatuses.where(_isActiveBooking).length,
      completedBookings: bookingStatuses
          .where((value) => value == 'COMPLETED')
          .length,
      rejectedBookings: bookingStatuses
          .where((value) => value == 'REJECTED' || value == 'CANCELLED')
          .length,
      totalSupportTickets: tickets.length,
      openSupportTickets: ticketStatuses
          .where(
            (value) => !const <String>{'RESOLVED', 'CLOSED'}.contains(value),
          )
          .length,
      resolvedSupportTickets: ticketStatuses
          .where(
            (value) => const <String>{'RESOLVED', 'CLOSED'}.contains(value),
          )
          .length,
    );
  }

  String _status(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim().toUpperCase();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _isActiveBooking(String value) => const <String>{
    'REQUESTED',
    'APPROVED',
    'ASSIGNED',
    'CONFIRMED',
    'IN_PROGRESS',
  }.contains(value);
}
