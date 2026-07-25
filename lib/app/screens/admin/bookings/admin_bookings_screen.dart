import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/bookings/getx/admin_bookings_controller.dart';
import 'package:clicknow_version2/app/screens/admin/bookings/models/admin_booking_request.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late final AdminBookingsController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminBookingsController>() ? Get.find<AdminBookingsController>() : Get.put(AdminBookingsController());
    searchController = TextEditingController(
      text: (Get.arguments as Map?)?['targetUserId']?.toString().trim().isNotEmpty == true ? (Get.arguments as Map)['targetUserId'].toString().trim() : controller.searchQuery.value,
    );
    controller.updateSearch(searchController.text);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminBookingsRoute,
        ),
        body: SafeArea(
          child: Obx(
            () => RefreshIndicator(
              onRefresh: () => controller.refreshBookings(showMessage: true),
              child: Column(
                children: [
                  /// -- app bar
                  _header(scale),

                  /// -- body
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            scale.getScaledWidth(14),
                            scale.getScaledHeight(12),
                            scale.getScaledWidth(14),
                            scale.getScaledHeight(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summaryRow(scale),
                              SizedBox(height: scale.getScaledHeight(12)),
                              _statusTabs(scale),
                              SizedBox(height: scale.getScaledHeight(12)),
                              if (controller.isLoading.value &&
                                  controller.filteredBookings.isEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: scale.getScaledHeight(42),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (controller.filteredBookings.isEmpty)
                                _emptyState(scale)
                              else
                                ...controller.filteredBookings.map(
                                  (booking) => _bookingCard(scale, booking),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(8),
        scale.getScaledWidth(12),
        scale.getScaledHeight(12),
      ),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  splashRadius: 22,
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: scale.getScaledWidth(28),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: scale.getScaledFont(18),
                      ),
                    ),
                    Text(
                      'Manage customer booking requests',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: scale.getScaledFont(11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(6)),
            child: TextField(
              controller: searchController,
              onChanged: controller.updateSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search bookings by ID, service, event or customer',
                hintStyle: const TextStyle(color: Color(0xffD9D9D9)),
                filled: true,
                fillColor: const Color(0xffFCFBFF),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xffD9D9D9),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    controller.updateSearch('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xffD9D9D9),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(ScalingUtility scale) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            scale: scale,
            title: 'Total Requests',
            value: '${controller.totalCount}',
            icon: Icons.calendar_month_rounded,
            iconBg: const Color(0xff4B45FF),
          ),
        ),
        SizedBox(width: scale.getScaledWidth(10)),
        Expanded(
          child: _metricCard(
            scale: scale,
            title: 'Pending',
            value: '${controller.pendingCount}',
            icon: Icons.pending_actions_rounded,
            iconBg: const Color(0xffFFB300),
          ),
        ),
        SizedBox(width: scale.getScaledWidth(10)),
        Expanded(
          child: _metricCard(
            scale: scale,
            title: 'Confirmed',
            value: '${controller.confirmedCount}',
            icon: Icons.verified_rounded,
            iconBg: const Color(0xff0ADB6D),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required ScalingUtility scale,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
  }) {
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(8)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: scale.getScaledHeight(22),
            width: scale.getScaledWidth(22),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          SizedBox(height: scale.getScaledHeight(6)),
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.7),
              fontSize: scale.getScaledFont(11),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: scale.getScaledFont(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTabs(ScalingUtility scale) {
    final tabs = const <(String, String)>[
      ('All', 'all'),
      ('Pending Requests', 'pending_requests'),
      ('Approved', 'approved'),
      ('Assigned', 'assigned'),
      ('Active Jobs', 'active'),
      ('Completed', 'completed'),
      ('Rejected', 'rejected'),
    ];

    return SizedBox(
      height: scale.getScaledHeight(36),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => SizedBox(width: scale.getScaledWidth(8)),
        itemBuilder: (context, index) {
          final (title, value) = tabs[index];
          final isSelected = controller.selectedStatus.value == value;
          final count = controller.countForStatusTab(value);
          return GestureDetector(
            onTap: () => controller.updateStatus(value),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.getScaledWidth(12),
                    vertical: scale.getScaledHeight(6),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xffB629FF) : const Color(0xffD9D9D9).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(13),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -scale.getScaledWidth(6),
                    top: -scale.getScaledHeight(0),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: scale.getScaledWidth(16),
                        minHeight: scale.getScaledHeight(16),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.getScaledWidth(4),
                        vertical: scale.getScaledHeight(1),
                      ),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xffFF2F43),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: scale.getScaledFont(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bookingCard(ScalingUtility scale, AdminBookingRequest booking) {
    final status = booking.normalizedStatus;
    final statusStyle = _statusStyle(status);
    final isAnyLoading = controller.isActionLoading(booking.id, action: 'all');
    final isRequested = status == 'requested';
    final isApproved = status == 'approved';
    final hasPendingReschedule = booking.rescheduleRequested;
    final isApproveLoading = controller.isActionLoading(
      booking.id,
      action: 'approve',
    );
    final isRejectLoading = controller.isActionLoading(
      booking.id,
      action: 'reject',
    );
    final isAutoAssignLoading = controller.isActionLoading(
      booking.id,
      action: 'auto_assign',
    );
    final isManualAssignLoading = controller.isActionLoading(
      booking.id,
      action: 'manual_assign',
    );
    final isApproveRescheduleLoading = controller.isActionLoading(
      booking.id,
      action: 'approve_reschedule',
    );
    final isRejectRescheduleLoading = controller.isActionLoading(
      booking.id,
      action: 'reject_reschedule',
    );
    final isCancelAssignmentLoading = controller.isActionLoading(
      booking.id,
      action: 'cancel_assignment',
    );
    final canApprove = isRequested && !hasPendingReschedule;
    final canReassign = booking.canReassign && !hasPendingReschedule;
    final canAutoAssign = isApproved && !canReassign && !hasPendingReschedule;
    final canManualAssign = isApproved && !canReassign && !hasPendingReschedule;
    final canReject = isRequested && !hasPendingReschedule;
    final canApproveReschedule = hasPendingReschedule;
    final canRejectReschedule = hasPendingReschedule;
    final canCancelAssignment = booking.canAdminCancelAssignment && !hasPendingReschedule;

    return Container(
      margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(9),
              scale.getScaledWidth(10),
              scale.getScaledHeight(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceTitle,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: scale.getScaledFont(15),
                            ),
                          ),
                          SizedBox(height: scale.getScaledHeight(2)),
                          Text(
                            'Booking ID: ${booking.bookingCode}',
                            style: TextStyle(
                              color: const Color(0xff00F2A4),
                              fontSize: scale.getScaledFont(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.getScaledWidth(10),
                        vertical: scale.getScaledHeight(3),
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.$1.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusStyle.$1.withValues(alpha: 0.58),
                        ),
                      ),
                      child: Text(
                        statusStyle.$2,
                        style: TextStyle(
                          color: statusStyle.$1,
                          fontWeight: FontWeight.w600,
                          fontSize: scale.getScaledFont(11),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: scale.getScaledHeight(4)),
                _line(scale, 'Customer ID: ${_customerCode(booking.userId)}'),
                _line(scale, 'Event: ${booking.eventTypeName}'),
                _line(scale, 'Plan: ${booking.planName}'),
                _line(scale, 'Date & Time: ${_dateTimeLabel(booking)}'),
                _line(scale, 'Venue: ${booking.venueName.isEmpty ? 'Not provided' : booking.venueName}',),
                _line(scale, 'House / Plot / Hall: ${booking.venueHouseDetails.isEmpty ? 'Not provided' : booking.venueHouseDetails}',),
                _line(scale, 'Landmark / Directions: ${booking.venueLandmarkDetails.isEmpty ? 'Not provided' : booking.venueLandmarkDetails}',),
                _line(scale, 'Location: ${booking.locationLine}'),
                _line(scale, 'Amount: Rs.${_formatAmount(booking.totalAmount)}', color: Colors.black, weight: FontWeight.w600,),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xffD9D9D9)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(7),
              scale.getScaledWidth(10),
              scale.getScaledHeight(7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.paymentStatus.isEmpty
                      ? 'Payment: -'
                      : 'Payment: ${booking.paymentStatus}',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.72),
                    fontSize: scale.getScaledFont(12),
                  ),
                ),
                _line(scale, 'Total Booking Amount: Rs.${_formatAmount(booking.totalAmount)}',),
                _line(scale, 'Amount Paid: Rs.${_formatAmount(booking.paidAmount)}',),
                _line(scale, 'Remaining Amount: Rs.${_formatAmount(booking.remainingAmount)}',),
                _line(scale, 'Coupon Discount: Rs.${_formatAmount(booking.discountAmount)}',),
                _line(scale, 'GST Amount: Rs.${_formatAmount(booking.gstAmount)}',),
                _line(scale, 'Platform Commission: Rs.${_formatAmount(booking.commissionAmount)}',),
                _line(scale, 'Professional Earnings: Rs.${_formatAmount(booking.professionalPayoutAmount)}',),
                if (booking.refundEligibility.isNotEmpty)
                  _line(scale, 'Refund: ${booking.refundEligibility}${booking.refundPercentage > 0 ? ' (${booking.refundPercentage}%)' : ''}',),
                if (_adminTimerText(booking).isNotEmpty) ...[
                  SizedBox(height: scale.getScaledHeight(4)),
                  StreamBuilder<int>(
                    stream: Stream<int>.periodic(
                      const Duration(seconds: 1),
                      (tick) => tick,
                    ),
                    builder: (context, _) {
                      final timerText = _adminTimerText(booking);
                      if (timerText.isEmpty) return const SizedBox.shrink();
                      return Text(
                        'Timer: $timerText',
                        style: TextStyle(
                          color: const Color(0xff12D86D),
                          fontWeight: FontWeight.w700,
                          fontSize: scale.getScaledFont(12),
                        ),
                      );
                    },
                  ),
                ],
                SizedBox(height: scale.getScaledHeight(7)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    runSpacing: scale.getScaledHeight(6),
                    children: [
                      if (canApprove)
                        _smallActionBtn(
                          scale: scale,
                          title: 'Approve',
                          onTap: () => controller.approveBooking(booking),
                          color: const Color(0xffECECEF),
                          textColor: const Color(0xff42155E),
                          loading: isApproveLoading,
                          enabled: !isAnyLoading || isApproveLoading,
                        ),
                      if (canReject) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Cancel & Refund',
                          onTap: () => _showRejectDialog(booking),
                          color: const Color(0xff3A1220),
                          textColor: const Color(0xffFF7B8C),
                          loading: isRejectLoading,
                          enabled: !isAnyLoading || isRejectLoading,
                        ),
                      ],
                      if (canApproveReschedule) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Approve Reschedule',
                          onTap: () => controller.approveReschedule(booking),
                          color: const Color(0xffECECEF),
                          textColor: const Color(0xff42155E),
                          loading: isApproveRescheduleLoading,
                          enabled: !isAnyLoading || isApproveRescheduleLoading,
                        ),
                      ],
                      if (canRejectReschedule) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Reject Reschedule',
                          onTap: () => _showRejectRescheduleDialog(booking),
                          color: const Color(0xff3A1220),
                          textColor: const Color(0xffFF7B8C),
                          loading: isRejectRescheduleLoading,
                          enabled: !isAnyLoading || isRejectRescheduleLoading,
                        ),
                      ],
                      if (canAutoAssign) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Auto Assign',
                          onTap: () => _showAutoAssignRecommendation(booking),
                          color: const Color(0xffECECEF),
                          textColor: const Color(0xff42155E),
                          loading: isAutoAssignLoading,
                          enabled: !isAnyLoading || isAutoAssignLoading,
                        ),
                      ],
                      if (canManualAssign) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Manual Assign',
                          onTap: () => _openAssignSheet(booking),
                          color: const Color(0xff1D1C40),
                          textColor: Colors.white,
                          loading: isManualAssignLoading,
                          enabled: !isAnyLoading || isManualAssignLoading,
                        ),
                      ],
                      if (canReassign) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Reassign',
                          onTap: () => _openAssignSheet(booking),
                          color: const Color(0xff1D1C40),
                          textColor: Colors.white,
                          loading: isManualAssignLoading,
                          enabled: !isAnyLoading || isManualAssignLoading,
                        ),
                      ],
                      if (canCancelAssignment) ...[
                        SizedBox(width: scale.getScaledWidth(6)),
                        _smallActionBtn(
                          scale: scale,
                          title: 'Cancel Assignment',
                          onTap: () => _showCancelAssignmentDialog(booking),
                          color: const Color(0xff3A1220),
                          textColor: const Color(0xffFF7B8C),
                          loading: isCancelAssignmentLoading,
                          enabled: !isAnyLoading || isCancelAssignmentLoading,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(
    ScalingUtility scale,
    String value, {
    Color? color,
    FontWeight? weight,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(2)),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? Colors.black.withValues(alpha: 0.76),
          fontSize: scale.getScaledFont(12),
          fontWeight: weight,
          height: 1.32,
        ),
      ),
    );
  }

  Widget _emptyState(ScalingUtility scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.getScaledWidth(14)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Text(
        'No booking requests found.',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.74),
          fontSize: scale.getScaledFont(13),
        ),
      ),
    );
  }

  (Color, String) _statusStyle(String status) {
    switch (status) {
      case 'requested':
        return (const Color(0xffFFB300), 'Requested');
      case 'approved':
        return (const Color(0xff7D70FF), 'Approved');
      case 'assigned':
        return (const Color(0xff3EA7FF), 'Assigned');
      case 'confirmed':
        return (const Color(0xff0ADB6D), 'Confirmed');
      case 'in_progress':
        return (const Color(0xff00A9FF), 'In Progress');
      case 'completed':
        return (const Color(0xffB629FF), 'Completed');
      case 'cancelled':
        return (const Color(0xffFF001A), 'Canceled');
      case 'rejected':
        return (const Color(0xffFF6E84), 'Rejected');
      default:
        return (const Color(0xffFFB300), 'Requested');
    }
  }

  Widget _smallActionBtn({
    required ScalingUtility scale,
    required String title,
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    required bool loading,
    required bool enabled,
  }) {
    return SizedBox(
      height: scale.getScaledHeight(30),
      child: ElevatedButton(
        onPressed: loading || !enabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(10)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: scale.getScaledFont(11),
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> _showRejectDialog(AdminBookingRequest booking) async {
    final reasonController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: const Text(
          'Cancel Booking & Refund',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter cancellation reason [Mandatory]',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            filled: true,
            fillColor: const Color(0xff100C1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Cancel & Refund'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (value == null || value.trim().isEmpty) {
      return;
    }
    await controller.rejectBooking(booking: booking, reason: value);
  }

  Future<void> _showCancelAssignmentDialog(AdminBookingRequest booking) async {
    final reasonController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: const Text(
          'Cancel Assignment',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason: professional inactive or unresponsive',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xff100C1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Cancel Assignment'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (value == null || value.trim().isEmpty) {
      return;
    }
    await controller.cancelAssignmentForReassignment(
      booking: booking,
      reason: value,
    );
  }

  Future<void> _showRejectRescheduleDialog(AdminBookingRequest booking) async {
    final reasonController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: const Text(
          'Reject Reschedule',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter rejection reason',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xff100C1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF334A),
            ),
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (value == null || value.trim().isEmpty) {
      return;
    }
    await controller.rejectReschedule(booking: booking, reason: value);
  }

  Future<void> _openAssignSheet(AdminBookingRequest booking) async {
    final suggestions = await controller.fetchSuggestions(booking);
    if (suggestions.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No professionals available for manual assignment yet.',
          ),
        ),
      );
    }
    if (!mounted) {
      return;
    }

    final queryController = TextEditingController();
    final cityOptions =
        suggestions
            .map((item) => item.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );
    final serviceOptions =
        suggestions
            .map((item) => item.serviceType.trim())
            .where((service) => service.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );

    String availabilityFilter = 'all';
    String cityFilter = 'all';
    String serviceFilter = 'all';
    String sortBy = 'score_high';
    var filtered = List.of(suggestions);

    int activeFilterCount() {
      var count = 0;
      if (availabilityFilter != 'all') {
        count++;
      }
      if (cityFilter != 'all') {
        count++;
      }
      if (serviceFilter != 'all') {
        count++;
      }
      return count;
    }

    void applyFilter(String raw) {
      final query = raw.trim().toLowerCase();
      final next = suggestions
          .where((item) {
            if (availabilityFilter == 'online' && !item.online) {
              return false;
            }
            if (availabilityFilter == 'offline' && item.online) {
              return false;
            }
            if (cityFilter != 'all' &&
                item.city.trim().toLowerCase() != cityFilter) {
              return false;
            }
            if (serviceFilter != 'all' &&
                item.serviceType.trim().toLowerCase() != serviceFilter) {
              return false;
            }
            if (query.isEmpty) {
              return true;
            }
            final searchable = [
              item.name,
              item.phoneNumber,
              item.serviceType,
              item.city,
              item.state,
              item.pincode,
              item.scoreBreakdown,
            ].join(' ').toLowerCase();
            return searchable.contains(query);
          })
          .toList(growable: true);

      next.sort((left, right) {
        switch (sortBy) {
          case 'score_low':
            return left.score.compareTo(right.score);
          case 'experience_high':
            return right.experienceYears.compareTo(left.experienceYears);
          case 'experience_low':
            return left.experienceYears.compareTo(right.experienceYears);
          case 'score_high':
          default:
            return right.score.compareTo(left.score);
        }
      });

      filtered = next;
    }

    Future<void> openFilterOptionsSheet(
      void Function(VoidCallback fn) setModalState,
      BuildContext sheetContext,
    ) async {
      var tempAvailabilityFilter = availabilityFilter;
      var tempCityFilter = cityFilter;
      var tempServiceFilter = serviceFilter;
      var tempSortBy = sortBy;

      await showModalBottomSheet<void>(
        context: sheetContext,
        backgroundColor: const Color(0xff18133A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (filterContext) {
          Widget sectionLabel(String title) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xffC5BFFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          InputDecoration dropDownDecoration() {
            return InputDecoration(
              filled: true,
              fillColor: const Color(0xff231C4C),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xff2C2750)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xff2C2750)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xff6C61C8)),
              ),
            );
          }

          return StatefulBuilder(
            builder: (context, setFilterState) {
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Professionals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        sectionLabel('Availability'),
                        DropdownButtonFormField<String>(
                          initialValue: tempAvailabilityFilter,
                          dropdownColor: const Color(0xff231C4C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          decoration: dropDownDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                              value: 'online',
                              child: Text('Online only'),
                            ),
                            DropdownMenuItem(
                              value: 'offline',
                              child: Text('Offline only'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setFilterState(() {
                              tempAvailabilityFilter = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        sectionLabel('City'),
                        DropdownButtonFormField<String>(
                          initialValue: tempCityFilter,
                          dropdownColor: const Color(0xff231C4C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          decoration: dropDownDecoration(),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All cities'),
                            ),
                            ...cityOptions.map(
                              (city) => DropdownMenuItem(
                                value: city.toLowerCase(),
                                child: Text(city),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setFilterState(() {
                              tempCityFilter = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        sectionLabel('Service Type'),
                        DropdownButtonFormField<String>(
                          initialValue: tempServiceFilter,
                          dropdownColor: const Color(0xff231C4C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          decoration: dropDownDecoration(),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All services'),
                            ),
                            ...serviceOptions.map(
                              (service) => DropdownMenuItem(
                                value: service.toLowerCase(),
                                child: Text(service),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setFilterState(() {
                              tempServiceFilter = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        sectionLabel('Sort By'),
                        DropdownButtonFormField<String>(
                          initialValue: tempSortBy,
                          dropdownColor: const Color(0xff231C4C),
                          style: const TextStyle(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          decoration: dropDownDecoration(),
                          items: const [
                            DropdownMenuItem(
                              value: 'score_high',
                              child: Text('Score: High to Low'),
                            ),
                            DropdownMenuItem(
                              value: 'score_low',
                              child: Text('Score: Low to High'),
                            ),
                            DropdownMenuItem(
                              value: 'experience_high',
                              child: Text('Experience: High to Low'),
                            ),
                            DropdownMenuItem(
                              value: 'experience_low',
                              child: Text('Experience: Low to High'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setFilterState(() {
                              tempSortBy = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    availabilityFilter = 'all';
                                    cityFilter = 'all';
                                    serviceFilter = 'all';
                                    sortBy = 'score_high';
                                    applyFilter(queryController.text);
                                  });
                                  Navigator.of(filterContext).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xff6C61C8),
                                  ),
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setModalState(() {
                                    availabilityFilter = tempAvailabilityFilter;
                                    cityFilter = tempCityFilter;
                                    serviceFilter = tempServiceFilter;
                                    sortBy = tempSortBy;
                                    applyFilter(queryController.text);
                                  });
                                  Navigator.of(filterContext).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff6C61C8),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    applyFilter('');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff161235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.82,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign Professional',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Search and filter before manual assignment',
                              style: TextStyle(
                                color: Color(0xff8F8BC5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: queryController,
                                onChanged: (value) {
                                  setModalState(() {
                                    applyFilter(value);
                                  });
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search professional by name, city, service',
                                  hintStyle: const TextStyle(
                                    color: Color(0xff6C6A93),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xff6C6A93),
                                  ),
                                  suffixIcon:
                                      queryController.text.trim().isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            queryController.clear();
                                            setModalState(() {
                                              applyFilter('');
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            color: Color(0xff6C6A93),
                                          ),
                                        ),
                                  filled: true,
                                  fillColor: const Color(0xff1E1A3F),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xff2C2750),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xff2C2750),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xff6C61C8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await openFilterOptionsSheet(
                                  setModalState,
                                  sheetContext,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xff6C61C8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.filter_list_rounded,
                                size: 18,
                              ),
                              label: Text(
                                activeFilterCount() == 0
                                    ? 'Filter'
                                    : 'Filter (${activeFilterCount()})',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${filtered.length} professionals found',
                            style: const TextStyle(
                              color: Color(0xff8F8BC5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No professionals match this search.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (itemContext, index) {
                                  final item = filtered[index];
                                  final name = item.name.trim().isEmpty
                                      ? 'Professional'
                                      : item.name;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1A1436),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xff2E2A53),
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.city}, ${item.state} (${item.pincode})',
                                              style: const TextStyle(
                                                color: Color(0xffB7B4D5),
                                              ),
                                            ),
                                            Text(
                                              'Service: ${item.serviceType} | Exp: ${item.experienceYears} yrs',
                                              style: const TextStyle(
                                                color: Color(0xff8F8BC5),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Score: ${item.score.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                color: Color(0xff52D3FF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (item.online
                                                      ? const Color(0xff0ADB6D)
                                                      : const Color(0xff5A5F72))
                                                  .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: item.online
                                                ? const Color(0xff0ADB6D)
                                                : const Color(0xff6F7488),
                                          ),
                                        ),
                                        child: Text(
                                          item.online ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            color: item.online
                                                ? const Color(0xff0ADB6D)
                                                : const Color(0xffA3A7BD),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      onTap: () async {
                                        Navigator.of(sheetContext).pop();
                                        await controller.assignToProfessional(
                                          booking: booking,
                                          suggestion: item,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    queryController.dispose();
  }

  Future<void> _showAutoAssignRecommendation(
    AdminBookingRequest booking,
  ) async {
    final suggestion = await controller.topAutoAssignSuggestion(booking);
    if (!mounted) return;
    if (suggestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible professional found for this booking.'),
        ),
      );
      return;
    }
    final name = suggestion.name.trim().isEmpty
        ? 'Professional'
        : suggestion.name.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Auto Assign Recommendation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional: $name'),
            Text('Score: ${suggestion.score.toStringAsFixed(1)}'),
            const SizedBox(height: 8),
            const Text('Why selected:'),
            Text(_readableScoreBreakdown(suggestion.scoreBreakdown)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Assign Professional'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.assignAutoRecommendation(
        booking: booking,
        suggestion: suggestion,
      );
    }
  }

  String _readableScoreBreakdown(String value) {
    if (value.trim().isEmpty) return '- Eligible and available';
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '- ${part.replaceAll(':', ': ')}')
        .join('\n');
  }

  String _customerCode(String uid) {
    final cleaned = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return '-';
    final suffix = cleaned.length > 6
        ? cleaned.substring(cleaned.length - 6)
        : cleaned.padLeft(6, '0');
    return 'CU$suffix';
  }

  String _dateTimeLabel(AdminBookingRequest booking) {
    final date = booking.eventDate;
    final dateLabel = date == null
        ? 'Date not selected'
        : '${_monthLabel(date.month)} ${date.day}, ${date.year}';
    if (booking.eventTime.isEmpty) {
      return dateLabel;
    }
    return '$dateLabel - ${booking.eventTime}';
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
    if (raw.length <= 3) {
      return raw;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final position = raw.length - i;
      buffer.write(raw[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _adminTimerText(AdminBookingRequest booking) {
    if (booking.statusCode.toUpperCase() != 'IN_PROGRESS') {
      return '';
    }
    final endTime = booking.bookingEndTime;
    if (endTime == null) {
      return '';
    }
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Completing...';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(hours)}Hr ${two(minutes)}Min ${two(seconds)}Sec';
  }
}
