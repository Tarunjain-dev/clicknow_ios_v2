import 'dart:async';

import 'package:clicknow_version2/app/screens/professional/professionalDashboard/bookings/getx/professionalBookings_Controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfessionalBookingDetailsScreen extends StatelessWidget {
  const ProfessionalBookingDetailsScreen({
    required this.bookingItem,
    super.key,
  });

  final ProfessionalBookingItem bookingItem;

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = ProfessionalBookingsController.instance;
    final statusColor = controller.statusColor(bookingItem.status);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
              scale.getScaledWidth(12),
              scale.getScaledHeight(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: scale.getScaledWidth(6)),
                    Expanded(
                      child: Text(
                        'Booking Details',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: scale.getScaledFont(17),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: scale.getScaledHeight(12)),
                _detailCard(
                  scale: scale,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _valueBlock(
                              scale: scale,
                              isDark: isDark,
                              title: 'Booking ID',
                              value: bookingItem.bookingCode,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scale.getScaledWidth(12),
                              vertical: scale.getScaledHeight(4),
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              controller.statusLabel(bookingItem.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: scale.getScaledFont(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Customer name',
                        value: bookingItem.customerName,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Customer phone number',
                        value: bookingItem.customerPhone,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Event Date & Time:',
                        value: bookingItem.dateAndTime,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Venue Name:',
                        value: bookingItem.venueName.isEmpty
                            ? 'Not provided'
                            : bookingItem.venueName,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'House / Plot / Hall:',
                        value: bookingItem.venueHouseDetails.isEmpty
                            ? 'Not provided'
                            : bookingItem.venueHouseDetails,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Landmark / Directions:',
                        value: bookingItem.venueLandmarkDetails.isEmpty
                            ? 'Not provided'
                            : bookingItem.venueLandmarkDetails,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Venue Location:',
                        value: bookingItem.location,
                      ),
                      _valueBlock(
                        scale: scale,
                        isDark: isDark,
                        title: 'Special Instructions',
                        value: bookingItem.specialInstructions,
                        valueMaxLines: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                _detailCard(
                  scale: scale,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services & event type booked',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: scale.getScaledFont(16),
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(4)),
                      _bullet(
                        scale,
                        'Service : ${bookingItem.serviceName}.',
                        isDark,
                      ),
                      _bullet(
                        scale,
                        'Event type : ${bookingItem.eventName}.',
                        isDark,
                      ),
                      _bullet(
                        scale,
                        'Price plan : ${bookingItem.professionalType}',
                        isDark,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(12)),
                _pricePreviewCard(scale, isDark),
                if (bookingItem.canEnd) ...[
                  SizedBox(height: scale.getScaledHeight(12)),
                  _timerCard(scale: scale, isDark: isDark, item: bookingItem),
                ],
                SizedBox(height: scale.getScaledHeight(12)),
                Obx(() {
                  final currentItem =
                      controller.itemById(bookingItem.bookingId) ?? bookingItem;
                  final loading = controller.isActionLoading(
                    bookingItem.bookingId,
                  );

                  if (currentItem.canAccept || currentItem.canReject) {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () => controller.acceptBooking(currentItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                              foregroundColor: isDark ? Color(0xFF4A176E) : Colors.white,
                              minimumSize: Size.fromHeight(
                                scale.getScaledHeight(46),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: loading
                                ? SizedBox(
                                    width: scale.getScaledWidth(18),
                                    height: scale.getScaledHeight(18),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF4A176E),
                                    ),
                                  )
                                : Text(
                                    'Accept Booking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: scale.getScaledFont(14),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: scale.getScaledWidth(10)),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading
                                ? null
                                : () => _showRejectDialog(
                                    context: context,
                                    controller: controller,
                                    item: currentItem,
                                  ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF4055)),
                              foregroundColor: const Color(0xFFFF4055),
                              minimumSize: Size.fromHeight(
                                scale.getScaledHeight(46),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Reject Booking',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: scale.getScaledFont(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : currentItem.canStart
                          ? () => _showStartOtpDialog(
                              context: context,
                              controller: controller,
                              item: currentItem,
                              scale: scale,
                              isDark: isDark,
                            )
                          : currentItem.canEnd
                          ? () => _showEndConfirmationDialog(
                              context: context,
                              controller: controller,
                              item: currentItem,
                              isDark: isDark,
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A176E),
                        minimumSize: Size.fromHeight(scale.getScaledHeight(46)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? SizedBox(
                              width: scale.getScaledWidth(18),
                              height: scale.getScaledHeight(18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4A176E),
                              ),
                            )
                          : currentItem.canEnd
                          ? StreamBuilder<int>(
                              stream: Stream<int>.periodic(
                                const Duration(seconds: 1),
                                (tick) => tick,
                              ),
                              builder: (context, _) {
                                final timerText = _timerText(currentItem);
                                return Text(
                                  timerText.isEmpty
                                      ? 'End Booking'
                                      : 'End Booking ($timerText)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: scale.getScaledFont(16),
                                  ),
                                );
                              },
                            )
                          : Text(
                              currentItem.canStart
                                  ? 'Start Booking'
                                  : currentItem.awaitingFullPayment
                                  ? 'Customer has not completed the remaining payment.'
                                  : 'View Only',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: scale.getScaledFont(
                                  currentItem.awaitingFullPayment ? 13 : 18,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailCard({
    required ScalingUtility scale,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(12),
        scale.getScaledHeight(10),
        scale.getScaledWidth(12),
        scale.getScaledHeight(10),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF101430).withValues(alpha: 0.92)
            : Color(0xFFFCFBFF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: child,
    );
  }

  Widget _valueBlock({
    required ScalingUtility scale,
    required String title,
    required String value,
    required bool isDark,
    int valueMaxLines = 2,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: scale.getScaledFont(14),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: scale.getScaledHeight(2)),
          Text(
            value.trim() == "" ? "-" : value,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
              fontSize: scale.getScaledFont(15),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(ScalingUtility scale, String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(2)),
      child: Text(
        '- $text',
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.black.withValues(alpha: 0.75),
          fontSize: scale.getScaledFont(15),
        ),
      ),
    );
  }

  Widget _pricePreviewCard(ScalingUtility scale, bool isDark) {
    final commissionAmount = bookingItem.commissionAmount > 0
        ? bookingItem.commissionAmount
        : 0;
    final payoutAmount = bookingItem.professionalPayoutAmount > 0
        ? bookingItem.professionalPayoutAmount
        : bookingItem.totalPayable;
    final bookingAmount =
        payoutAmount + bookingItem.gstAmount + commissionAmount;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(9),
              scale.getScaledWidth(10),
              scale.getScaledHeight(9),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Color(0xff6A117F)
                  : Color(0xffBFD5FB).withValues(alpha: 0.5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(
                  'Payout Preview',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: scale.getScaledFont(16),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.getScaledWidth(10),
                    vertical: scale.getScaledHeight(3),
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Color(0xff12D86D).withValues(alpha: 0.18)
                        : Color(0xffE4FFD2).withValues(alpha: 1),
                    border: Border.all(
                      color: isDark ? Color(0xff12D86D) : Color(0xff00A63E),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    bookingItem.paymentStatusLabel,
                    style: TextStyle(
                      color: isDark ? Color(0xff12D86D) : Color(0xff00A63E),
                      fontSize: scale.getScaledFont(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(10),
              scale.getScaledWidth(10),
              scale.getScaledHeight(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookingItem.serviceName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: scale.getScaledFont(16),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(1)),
                Text(
                  '${bookingItem.professionalType} . ${bookingItem.eventName}',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.black.withValues(alpha: 0.65),
                    fontSize: scale.getScaledFont(13),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(10)),
                _priceLine(
                  scale,
                  'Booking value',
                  'Rs.${_formatAmount(bookingAmount)}',
                  isDark,
                ),
                _priceLine(
                  scale,
                  'GST deduction',
                  '- Rs.${_formatAmount(bookingItem.gstAmount)}',
                  isDark,
                ),
                _priceLine(
                  scale,
                  'Platform Commission (21%)',
                  '- Rs.${_formatAmount(commissionAmount)}',
                  isDark,
                ),
                Container(
                  margin: EdgeInsets.only(top: scale.getScaledHeight(2)),
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _priceLine(
                  scale,
                  'Expected Payout',
                  'Rs.${_formatAmount(payoutAmount)}',
                  isDark,
                  isBold: true,
                ),
                Text(
                  'Payout = Booking value - GST - 21% commission',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.55),
                    fontSize: scale.getScaledFont(11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceLine(
    ScalingUtility scale,
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(4)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: isBold ? 0.94 : 0.72)
                  : Colors.black.withValues(alpha: isBold ? 0.94 : 0.72),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: scale.getScaledFont(14),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: isBold ? 0.94 : 0.72)
                  : Colors.black.withValues(alpha: isBold ? 0.94 : 0.72),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: scale.getScaledFont(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerCard({
    required ScalingUtility scale,
    required bool isDark,
    required ProfessionalBookingItem item,
  }) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, _) {
        final timerText = _timerText(item);
        return _detailCard(
          scale: scale,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Timer',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: scale.getScaledFont(16),
                ),
              ),
              SizedBox(height: scale.getScaledHeight(6)),
              Text(
                timerText.isEmpty
                    ? 'Timer starts after OTP verification.'
                    : timerText,
                style: TextStyle(
                  color: const Color(0xff00A63E),
                  fontWeight: FontWeight.w800,
                  fontSize: scale.getScaledFont(22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timerText(ProfessionalBookingItem item) {
    final endTime = item.bookingEndTime;
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

  String _formatAmount(int value) {
    return NumberFormat.decimalPattern('en_IN').format(value);
  }

  Future<void> _showRejectDialog({
    required BuildContext context,
    required ProfessionalBookingsController controller,
    required ProfessionalBookingItem item,
  }) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: const Text(
          'Reject Booking',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.trim().isEmpty) {
      return;
    }
    await controller.rejectBooking(booking: item, reason: reason);
  }

  Future<void> _showStartOtpDialog({
    required BuildContext context,
    required ProfessionalBookingsController controller,
    required ProfessionalBookingItem item,
    required ScalingUtility scale,
    required bool isDark,
  }) async {
    final otpController = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
        title: Text(
          'Enter Customer OTP',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: otpController,
          maxLength: 4,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: scale.getScaledFont(24),
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '****',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xff100C1F)
                : const Color(0xffF7F3FA),
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
            onPressed: () => Navigator.pop(context, otpController.text.trim()),
            child: const Text('Start Booking'),
          ),
        ],
      ),
    );
    otpController.dispose();
    if (otp == null || otp.trim().length != 4) {
      return;
    }
    await controller.startBooking(booking: item, otp: otp);
  }

  Future<void> _showEndConfirmationDialog({
    required BuildContext context,
    required ProfessionalBookingsController controller,
    required ProfessionalBookingItem item,
    required bool isDark,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
        title: Text(
          'End Booking?',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'This will mark the booking as completed and stop the timer.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.endBooking(item);
    }
  }
}
