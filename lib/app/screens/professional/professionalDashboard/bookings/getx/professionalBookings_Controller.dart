import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── Booking Status Enum ───────────────────────────────────────────────────────
enum BookingStatus { confirmed, pending, completed, canceled }

// ─── Booking Model ─────────────────────────────────────────────────────────────
class BookingItemModel {
  final String bookingId;
  final String customerName;
  final String serviceType;
  final String dateTime;
  final String location;
  final String bookingAmount;
  final BookingStatus status;

  BookingItemModel({
    required this.bookingId,
    required this.customerName,
    required this.serviceType,
    required this.dateTime,
    required this.location,
    required this.bookingAmount,
    required this.status,
  });
}

// ─── Tab Filter Model ──────────────────────────────────────────────────────────
class BookingTab {
  final String label;
  final BookingStatus? status; // null = All

  BookingTab({required this.label, this.status});
}

// ─── Controller ───────────────────────────────────────────────────────────────
class ProfessionalBookingsController extends GetxController {
  // Selected tab index
  final selectedTabIndex = 0.obs;

  // All tabs
  final tabs = [
    BookingTab(label: 'All', status: null),
    BookingTab(label: 'Pending', status: BookingStatus.pending),
    BookingTab(label: 'Confirmed', status: BookingStatus.confirmed),
    BookingTab(label: 'Completed', status: BookingStatus.completed),
    BookingTab(label: 'Canceled', status: BookingStatus.canceled),
  ];

  // All bookings list
  final _allBookings = <BookingItemModel>[
    BookingItemModel(
      bookingId: 'BID293001',
      customerName: 'Tarun jain',
      serviceType: 'Photo & Videography.',
      dateTime: 'Feb 18, 2026 • 10:00 AM to 03:00 PM.',
      location: 'Vijay Nagar Indore, M.P.',
      bookingAmount: 'Rs. 15,000.',
      status: BookingStatus.confirmed,
    ),
    BookingItemModel(
      bookingId: 'BID293002',
      customerName: 'Rahul Sharma',
      serviceType: 'Photo & Videography.',
      dateTime: 'Feb 18, 2026 • 10:00 AM to 03:00 PM.',
      location: 'Vijay Nagar Indore, M.P.',
      bookingAmount: 'Rs. 15,000.',
      status: BookingStatus.pending,
    ),
    BookingItemModel(
      bookingId: 'BID293003',
      customerName: 'Priya Patel',
      serviceType: 'Photo & Videography.',
      dateTime: 'Feb 18, 2026 • 10:00 AM to 03:00 PM.',
      location: 'Vijay Nagar Indore, M.P.',
      bookingAmount: 'Rs. 15,000.',
      status: BookingStatus.completed,
    ),
    BookingItemModel(
      bookingId: 'BID293004',
      customerName: 'Ankit Verma',
      serviceType: 'Photo & Videography.',
      dateTime: 'Feb 18, 2026 • 10:00 AM to 03:00 PM.',
      location: 'Vijay Nagar Indore, M.P.',
      bookingAmount: 'Rs. 15,000.',
      status: BookingStatus.canceled,
    ),
    BookingItemModel(
      bookingId: 'BID293005',
      customerName: 'Sneha Gupta',
      serviceType: 'Photography.',
      dateTime: 'Feb 20, 2026 • 11:00 AM to 04:00 PM.',
      location: 'Palasia, Indore, M.P.',
      bookingAmount: 'Rs. 12,000.',
      status: BookingStatus.confirmed,
    ),
    BookingItemModel(
      bookingId: 'BID293006',
      customerName: 'Vikram Singh',
      serviceType: 'Videography.',
      dateTime: 'Feb 21, 2026 • 09:00 AM to 02:00 PM.',
      location: 'Scheme 54, Indore, M.P.',
      bookingAmount: 'Rs. 18,000.',
      status: BookingStatus.pending,
    ),
    BookingItemModel(
      bookingId: 'BID293007',
      customerName: 'Meera Joshi',
      serviceType: 'Photo & Videography.',
      dateTime: 'Feb 22, 2026 • 12:00 PM to 06:00 PM.',
      location: 'MG Road, Indore, M.P.',
      bookingAmount: 'Rs. 22,000.',
      status: BookingStatus.completed,
    ),
    BookingItemModel(
      bookingId: 'BID293008',
      customerName: 'Karan Malhotra',
      serviceType: 'Photography.',
      dateTime: 'Feb 23, 2026 • 10:00 AM to 02:00 PM.',
      location: 'Rajwada, Indore, M.P.',
      bookingAmount: 'Rs. 10,000.',
      status: BookingStatus.canceled,
    ),
  ];

  // Filtered bookings based on selected tab
  List<BookingItemModel> get filteredBookings {
    final currentStatus = tabs[selectedTabIndex.value].status;
    if (currentStatus == null) return _allBookings;
    return _allBookings.where((b) => b.status == currentStatus).toList();
  }

  void selectTab(int index) => selectedTabIndex.value = index;

  void onSeeDetails(String bookingId) {
    Get.snackbar(
      'Booking Details',
      'Viewing details for $bookingId',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1C1736),
      colorText: Colors.white,
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  String statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.canceled:
        return 'Canceled';
    }
  }

  Color statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFF00C853); // green
      case BookingStatus.pending:
        return const Color(0xFFB8860B); // dark golden
      case BookingStatus.completed:
        return const Color(0xFFBF00FF); // purple
      case BookingStatus.canceled:
        return const Color(0xFFCC3300); // red
    }
  }

  Color statusBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFF00C853).withValues(alpha: 0.12);
      case BookingStatus.pending:
        return const Color(0xFFB8860B).withValues(alpha: 0.18);
      case BookingStatus.completed:
        return const Color(0xFFBF00FF).withValues(alpha: 0.12);
      case BookingStatus.canceled:
        return const Color(0xFFCC3300).withValues(alpha: 0.18);
    }
  }
}
