import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/finance/finance_service.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/services/pdf/customer_invoice_pdf_service.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_data_builder.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/screens/common/pdf/pdf_preview_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/raise_ticket_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/services/support_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerBookingStatusScreen extends StatefulWidget {
  const CustomerBookingStatusScreen({
    required this.bookingId,
    required this.bookingCode,
    required this.serviceTitle,
    super.key,
  });

  final String bookingId;
  final String bookingCode;
  final String serviceTitle;

  @override
  State<CustomerBookingStatusScreen> createState() =>
      _CustomerBookingStatusScreenState();
}

class _CustomerBookingStatusScreenState
    extends State<CustomerBookingStatusScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService.instance;
  final FinanceService _financeService = FinanceService.instance;
  final RazorpayPaymentService _paymentService =
      RazorpayPaymentService.instance;
  bool _rescheduleLoading = false;
  bool _cancelLoading = false;
  bool _remainingPaymentLoading = false;
  bool _reviewPromptOpen = false;
  bool _reviewPromptDismissed = false;

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final uid = _auth.currentUser?.uid;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

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
          child: uid == null
              ? _errorState(scale, 'Please login to view booking details.')
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _db
                      .collection(ServiceCatalogPaths.usersCollection)
                      .doc(uid)
                      .collection(
                        ServiceCatalogPaths.customerBookingsSubcollection,
                      )
                      .doc(widget.bookingId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffC500FF),
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        !(snapshot.data?.exists ?? false)) {
                      return _errorState(scale, 'Booking details not found.');
                    }

                    final data = snapshot.data!.data() ?? <String, dynamic>{};
                    final statusCode = _normalizedStatusCode(data);
                    final statusChip = _statusStyle(statusCode);
                    final completedSteps = _completedStepCount(data);
                    final serviceName = _string(data['serviceTitle']).isEmpty
                        ? widget.serviceTitle
                        : _string(data['serviceTitle']);
                    final eventName = _string(data['eventTypeName']);
                    final planName = _string(data['planName']);
                    final specialRequirements = _string(
                      data['specialRequirements'],
                    );
                    final eventDate = _asDateTime(data['eventDate']);
                    final eventTime = _string(data['eventTime']);
                    final venueName = _string(data['venueName']);
                    final venueHouseDetails = _string(
                      data['venueHouseDetails'],
                    );
                    final venueLandmarkDetails = _string(
                      data['venueLandmarkDetails'],
                    );
                    final fullAddress = _string(data['fullAddress']);
                    final city = _string(data['city']);
                    final state = _string(data['state']);
                    final financials = _CustomerBookingFinancials.from(data);
                    final basePrice = financials.rateAmount;
                    final duration = _string(data['eventDurationHours']);
                    final paymentStatus = financials.paymentStatus;
                    final paymentMap = financials.paymentMap;
                    final rescheduleRequest = _asMap(data['rescheduleRequest']);
                    final rescheduleStatus = _string(
                      rescheduleRequest['status'],
                    ).toLowerCase();
                    final hasPendingReschedule = rescheduleStatus == 'pending';
                    final bookingAllowsPayment = !const <String>{
                      'CANCELLED',
                      'REJECTED',
                      'COMPLETED',
                    }.contains(statusCode);
                    final canPayRemaining =
                        bookingAllowsPayment &&
                        financials.remainingAmount > 0 &&
                        !financials.isFullyPaid &&
                        financials.paidAmount > 0;
                    final canReschedule =
                        const <String>{
                          'APPROVED',
                          'ASSIGNED',
                          'CONFIRMED',
                        }.contains(statusCode) &&
                        !hasPendingReschedule;
                    final canCancel = const <String>{
                      'REQUESTED',
                      'APPROVED',
                      'ASSIGNED',
                      'CONFIRMED',
                    }.contains(statusCode);
                    final canDownload = statusCode == 'COMPLETED';
                    final canReview =
                        statusCode == 'COMPLETED' &&
                        data['customerReviewSubmitted'] != true;
                    if (canReview &&
                        !_reviewPromptOpen &&
                        !_reviewPromptDismissed) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showReviewDialog(data);
                        }
                      });
                    }
                    final otp = _string(data['otp'] ?? data['bookingOtp']);
                    final canShowOtp =
                        financials.isFullyPaid &&
                        statusCode != 'COMPLETED' &&
                        otp.isNotEmpty;
                    final hasTimer = _timerText(data).isNotEmpty;
                    final professionalMap = _asMap(data['professional']);
                    final assignedProfessionalName = _string(
                      professionalMap['name'],
                    );
                    final assignedProfessionalPhone = _string(
                      professionalMap['phoneNumber'],
                    );
                    final showProfessionalPhone = _isEventDateTodayOrPast(
                      eventDate,
                    );
                    final professionalPhoneDisplay = showProfessionalPhone
                        ? assignedProfessionalPhone
                        : _maskPhoneNumber(assignedProfessionalPhone);
                    final location = [
                      if (city.isNotEmpty) city,
                      if (state.isNotEmpty) state,
                      if (fullAddress.isNotEmpty) fullAddress,
                    ].join(', ');

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(10),
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).maybePop();
                                },
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
                              Text(
                                'Booking Details',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: ResponsiveUtility.fontSize(18),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Help & Support',
                                onPressed: () => _openBookingSupport(data),
                                icon: Icon(
                                  Icons.support_agent_rounded,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: scale.getScaledHeight(10)),
                          _card(
                            scale,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _titleValue(
                                        scale,
                                        'Booking ID',
                                        _string(data['bookingCode']).isEmpty
                                            ? widget.bookingCode
                                            : _string(data['bookingCode']),
                                        isDark,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: scale.getScaledWidth(12),
                                        vertical: scale.getScaledHeight(4),
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusChip.$1.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        statusChip.$2,
                                        style: TextStyle(
                                          color: statusChip.$1,
                                          fontWeight: FontWeight.w600,
                                          fontSize: ResponsiveUtility.fontSize(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _titleValue(
                                  scale,
                                  'Event Date & Time:',
                                  _dateTimeLabel(eventDate, eventTime),
                                  isDark,
                                ),
                                _titleValue(
                                  scale,
                                  'Venue Name:',
                                  venueName.isEmpty
                                      ? 'Not provided'
                                      : venueName,
                                  isDark,
                                ),
                                _titleValue(
                                  scale,
                                  'House / Plot / Hall:',
                                  venueHouseDetails.isEmpty
                                      ? 'Not provided'
                                      : venueHouseDetails,
                                  isDark,
                                ),
                                _titleValue(
                                  scale,
                                  'Landmark / Directions:',
                                  venueLandmarkDetails.isEmpty
                                      ? 'Not provided'
                                      : venueLandmarkDetails,
                                  isDark,
                                ),
                                _titleValue(
                                  scale,
                                  'Venue location:',
                                  location.isEmpty ? '-' : location,
                                  isDark,
                                ),
                                _titleValue(
                                  scale,
                                  'Special Instructions',
                                  specialRequirements.isEmpty
                                      ? '-'
                                      : specialRequirements,
                                  isDark,
                                ),
                                if (assignedProfessionalName.isNotEmpty)
                                  _titleValue(
                                    scale,
                                    'Assigned Professional',
                                    assignedProfessionalName,
                                    isDark,
                                  ),
                                if (assignedProfessionalPhone.isNotEmpty)
                                  _professionalContactValue(
                                    scale: scale,
                                    phone: professionalPhoneDisplay,
                                    isDark: isDark,
                                    showUnlockNote: !showProfessionalPhone,
                                  ),
                              ],
                            ),
                            isDark,
                          ),
                          SizedBox(height: scale.getScaledHeight(9)),
                          _card(
                            scale,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Services & event type booked',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: scale.getScaledFont(14),
                                  ),
                                ),
                                SizedBox(height: scale.getScaledHeight(4)),
                                _bullet(
                                  scale,
                                  'Service : $serviceName.',
                                  isDark,
                                ),
                                _bullet(
                                  scale,
                                  'Event type : $eventName.',
                                  isDark,
                                ),
                                _bullet(
                                  scale,
                                  'Price plan : ${planName.isEmpty ? '-' : planName}',
                                  isDark,
                                ),
                              ],
                            ),
                            isDark,
                          ),
                          SizedBox(height: scale.getScaledHeight(9)),
                          _timelineCard(
                            scale: scale,
                            bookingData: data,
                            statusCode: statusCode,
                            completedSteps: completedSteps,
                            isDark: isDark,
                          ),
                          if (rescheduleRequest.isNotEmpty) ...[
                            SizedBox(height: scale.getScaledHeight(9)),
                            _rescheduleStatusCard(
                              scale: scale,
                              request: rescheduleRequest,
                              currentDate: eventDate,
                              currentTime: eventTime,
                              isDark: isDark,
                            ),
                          ],
                          SizedBox(height: scale.getScaledHeight(9)),
                          _priceCard(
                            scale: scale,
                            serviceName: serviceName,
                            planName: planName,
                            eventName: eventName,
                            ratePerHour: basePrice,
                            durationHours: duration,
                            bookingAmount: financials.bookingAmount,
                            netAmount: financials.netAmount,
                            discountAmount: financials.discountAmount,
                            gstAmount: financials.gstAmount,
                            taxableAmount: financials.taxableAmount,
                            totalAmount: financials.finalAmount,
                            paymentStatus: paymentStatus,
                            isDark: isDark,
                          ),
                          SizedBox(height: scale.getScaledHeight(9)),
                          _paymentStatusCard(
                            scale: scale,
                            bookingAmount: financials.finalAmount,
                            paidAmount: financials.paidAmount,
                            remainingAmount: financials.remainingAmount,
                            paymentMap: paymentMap,
                            financialBreakdown: financials.financialBreakdown,
                            paymentStatus: paymentStatus,
                            paymentType: financials.paymentTypeLabel,
                            isDark: isDark,
                          ),
                          SizedBox(height: scale.getScaledHeight(9)),
                          _refundStatusCard(
                            scale: scale,
                            customerId: uid,
                            isDark: isDark,
                          ),
                          if (canShowOtp || hasTimer)
                            SizedBox(height: scale.getScaledHeight(9)),
                          if (canShowOtp || hasTimer)
                            _card(
                              scale,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (canShowOtp) ...[
                                    Text(
                                      'Booking Start OTP',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: scale.getScaledFont(14),
                                      ),
                                    ),
                                    SizedBox(height: scale.getScaledHeight(2)),
                                    Text(
                                      otp,
                                      style: TextStyle(
                                        color: const Color(0xffD000FF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: scale.getScaledFont(14),
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    SizedBox(height: scale.getScaledHeight(2)),
                                    Text(
                                      'Share this OTP with the professional only when they arrive.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: scale.getScaledFont(10),
                                      ),
                                    ),
                                  ],
                                  if (hasTimer) ...[
                                    if (canShowOtp)
                                      SizedBox(
                                        height: scale.getScaledHeight(12),
                                      ),
                                    Text(
                                      'Booking Timer',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: scale.getScaledFont(14),
                                      ),
                                    ),
                                    SizedBox(height: scale.getScaledHeight(4)),
                                    StreamBuilder<int>(
                                      stream: Stream<int>.periodic(
                                        const Duration(seconds: 1),
                                        (tick) => tick,
                                      ),
                                      builder: (context, _) {
                                        return Text(
                                          'Booking Ends in: ${_timerText(data)}',
                                          style: TextStyle(
                                            color: const Color(0xff00A63E),
                                            fontWeight: FontWeight.normal,
                                            fontSize: scale.getScaledFont(14),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              isDark,
                            ),
                          SizedBox(height: scale.getScaledHeight(8)),
                          if (canPayRemaining)
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                scale: scale,
                                title:
                                    'Pay Remaining Rs.${_formatAmount(financials.remainingAmount)}',
                                icon: Icons.payment_rounded,
                                loading: _remainingPaymentLoading,
                                isDark: isDark,
                                onTap: () => _payRemainingAmount(),
                              ),
                            ),
                          if (canPayRemaining)
                            SizedBox(height: scale.getScaledHeight(8)),
                          if (canReschedule)
                            Row(
                              children: [
                                if (canReschedule)
                                  Expanded(
                                    child: _actionButton(
                                      scale: scale,
                                      title: 'Reschedule',
                                      loading: _rescheduleLoading,
                                      isDark: isDark,
                                      onTap: () => _requestReschedule(
                                        eventDate,
                                        eventTime,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (canReschedule)
                            SizedBox(height: scale.getScaledHeight(10)),
                          if (canCancel)
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                scale: scale,
                                title: 'Cancel Booking',
                                icon: Icons.cancel_outlined,
                                loading: _cancelLoading,
                                isDark: isDark,
                                danger: true,
                                onTap: () => _cancelBooking(),
                              ),
                            ),
                          if (canCancel)
                            SizedBox(height: scale.getScaledHeight(10)),
                          if (canDownload)
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                scale: scale,
                                title: 'Download Invoice',
                                icon: Icons.download_rounded,
                                isDark: isDark,
                                onTap: () => _downloadInvoice(data),
                              ),
                            ),
                          if (canReview) ...[
                            if (canDownload)
                              SizedBox(height: scale.getScaledHeight(10)),
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                scale: scale,
                                title: 'Rate & Review Booking',
                                icon: Icons.star_rate_rounded,
                                isDark: isDark,
                                onTap: () => _showReviewDialog(data),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _payRemainingAmount() async {
    if (_remainingPaymentLoading) {
      return;
    }
    setState(() => _remainingPaymentLoading = true);
    try {
      final order = await _paymentService.createRemainingPaymentOrder(
        bookingId: widget.bookingId,
      );
      final result = await _paymentService.openCheckout(order);
      await _paymentService.verifyPayment(
        bookingId: widget.bookingId,
        paymentId: order.paymentId,
        result: result,
      );
      AppSnackbar.success('Payment Successful', 'Remaining amount paid.');
    } catch (error) {
      AppSnackbar.error(
        'Payment Failed',
        error is StateError ? error.message : 'Unable to complete payment.',
      );
    } finally {
      if (mounted) {
        setState(() => _remainingPaymentLoading = false);
      }
    }
  }

  Future<void> _openBookingSupport(Map<String, dynamic> bookingData) async {
    try {
      final actor = await SupportService.instance.currentActor(
        preferredRole: 'customer',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RaiseTicketScreen(
            actor: actor,
            initialCategory: 'BOOKING_ISSUE',
            initialSubject:
                'Issue with booking ${_firstNonEmpty([_string(bookingData['bookingCode']), widget.bookingCode, widget.bookingId])}',
            relatedBookingId: widget.bookingId,
          ),
        ),
      );
    } catch (error) {
      AppSnackbar.error(
        'Support Unavailable',
        error is StateError ? error.message : 'Unable to open support.',
      );
    }
  }

  Future<void> _cancelBooking() async {
    if (_cancelLoading) return;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final isDark = HelperFunctions.isDarkMode(dialogContext);
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
          title: Text(
            'Cancel Booking',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: reasonController,
            minLines: 3,
            maxLines: 5,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Tell us why you want to cancel this booking',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF475D),
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, reasonController.text.trim()),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null) return;
    if (reason.trim().length < 5) {
      AppSnackbar.error('Reason Required', 'Please enter a valid reason.');
      return;
    }
    setState(() => _cancelLoading = true);
    try {
      await _bookingService.cancelBookingByCustomer(
        bookingId: widget.bookingId,
        reason: reason,
      );
      AppSnackbar.success(
        'Booking Cancelled',
        'Your cancellation request has been submitted.',
      );
    } catch (error) {
      AppSnackbar.error(
        'Cancellation Failed',
        error is StateError ? error.message : 'Unable to cancel booking.',
      );
    } finally {
      if (mounted) setState(() => _cancelLoading = false);
    }
  }

  Future<void> _downloadInvoice(Map<String, dynamic> bookingData) async {
    try {
      final invoice = await PdfDataBuilder.instance.customerInvoiceForBooking(
        bookingId: widget.bookingId,
        fallbackBookingData: <String, dynamic>{
          ...bookingData,
          'bookingId': widget.bookingId,
          'serviceTitle': _firstNonEmpty([
            _string(bookingData['serviceTitle']),
            widget.serviceTitle,
          ]),
        },
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: 'Invoice ${invoice.invoiceNumber}',
            fileName:
                'ClickNow_Invoice_${PdfFormatters.safeFileName(invoice.invoiceNumber)}.pdf',
            buildPdf: () => CustomerInvoicePdfService.generate(invoice),
          ),
        ),
      );
      final user = _auth.currentUser;
      if (user != null) {
        await _financeService.markInvoiceDownloaded(
          invoiceId: widget.bookingId,
          actorId: user.uid,
        );
      }
    } catch (_) {
      AppSnackbar.error('Invoice Failed', 'Unable to generate invoice PDF.');
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> bookingData) async {
    if (_reviewPromptOpen) {
      return;
    }
    _reviewPromptOpen = true;
    var rating = 5;
    final commentController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = HelperFunctions.isDarkMode(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xff171129) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xffD000FF), Color(0xff600080)],
                      ),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Booking Completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please rate and review your experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => setDialogState(() => rating = value),
                        icon: Icon(
                          value <= rating ? Icons.star : Icons.star_border,
                          color: const Color(0xffFFC400),
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    minLines: 3,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38,
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    _reviewPromptOpen = false;
    if (submitted != true) {
      _reviewPromptDismissed = true;
      commentController.dispose();
      return;
    }
    final comment = commentController.text.trim();
    commentController.dispose();
    if (comment.isEmpty) {
      AppSnackbar.error('Review Required', 'Please add your review comment.');
      _reviewPromptDismissed = false;
      return;
    }
    _reviewPromptDismissed = true;
    await _submitReview(
      bookingData: bookingData,
      rating: rating,
      comment: comment,
    );
  }

  Future<void> _submitReview({
    required Map<String, dynamic> bookingData,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return;
    }
    try {
      final userSnap = await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(user.uid)
          .get();
      final userData = userSnap.data() ?? <String, dynamic>{};
      final reviewRef = _db
          .collection(ServiceCatalogPaths.reviewsCollection)
          .doc(widget.bookingId);
      final customerName = _firstNonEmpty([
        _string(userData['fullName']),
        _string(userData['name']),
        _string(bookingData['customerName']),
        'Customer',
      ]);
      final location = _firstNonEmpty([
        _string(bookingData['city']),
        _string(bookingData['state']),
        _string(bookingData['fullAddress']),
      ]);
      final payload = <String, dynamic>{
        'reviewId': reviewRef.id,
        'bookingId': widget.bookingId,
        'customerId': user.uid,
        'customerName': customerName,
        'location': location.isEmpty ? 'India' : location,
        'serviceTitle': _string(bookingData['serviceTitle']),
        'serviceCatalogId': _string(bookingData['serviceCatalogId']),
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'visible': true,
      };
      final batch = _db.batch();
      batch.set(reviewRef, payload, SetOptions(merge: true));
      final patch = <String, dynamic>{
        'customerReviewSubmitted': true,
        'customerReview': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.set(
        _db
            .collection(ServiceCatalogPaths.bookingsCollection)
            .doc(widget.bookingId),
        patch,
        SetOptions(merge: true),
      );
      batch.set(
        _db
            .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
            .doc(widget.bookingId),
        patch,
        SetOptions(merge: true),
      );
      batch.set(
        _db
            .collection(ServiceCatalogPaths.usersCollection)
            .doc(user.uid)
            .collection(ServiceCatalogPaths.customerBookingsSubcollection)
            .doc(widget.bookingId),
        patch,
        SetOptions(merge: true),
      );
      await batch.commit();
      AppSnackbar.success('Thank You', 'Your review has been submitted.');
    } catch (_) {
      AppSnackbar.error('Review Failed', 'Could not submit review right now.');
    }
  }

  Widget _errorState(ScalingUtility scale, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(24)),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: scale.getScaledFont(14),
          ),
        ),
      ),
    );
  }

  Widget _card(ScalingUtility scale, Widget child, bool isDark) {
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

  Widget _titleValue(
    ScalingUtility scale,
    String title,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(2)),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.black.withValues(alpha: 0.72),
              fontSize: ResponsiveUtility.fontSize(12),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rescheduleStatusCard({
    required ScalingUtility scale,
    required Map<String, dynamic> request,
    required DateTime? currentDate,
    required String currentTime,
    required bool isDark,
  }) {
    final status = _string(request['status']).toLowerCase();
    final newDate = _asDateTime(request['newEventDate']);
    final newTime = _string(request['newEventTime']);
    final reason = _string(request['reason']);
    final rejectionReason = _string(request['rejectionReason']);
    final title = switch (status) {
      'approved' => 'RESCHEDULE APPROVED',
      'rejected' => 'RESCHEDULE REJECTED',
      _ => 'RESCHEDULE REQUESTED',
    };
    final statusText = switch (status) {
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      _ => 'Pending Admin Approval',
    };
    return _card(
      scale,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveUtility.fontSize(13),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(8)),
          if (status != 'approved')
            _titleValue(
              scale,
              'Current Schedule',
              _dateTimeLabel(currentDate, currentTime),
              isDark,
            ),
          _titleValue(
            scale,
            status == 'approved'
                ? 'New Booking Schedule'
                : 'Requested Schedule',
            _dateTimeLabel(newDate, newTime),
            isDark,
          ),
          if (reason.isNotEmpty) _titleValue(scale, 'Reason', reason, isDark),
          _titleValue(scale, 'Status', statusText, isDark),
          if (status == 'rejected' && rejectionReason.isNotEmpty)
            _titleValue(scale, 'Rejection Reason', rejectionReason, isDark),
          if (status == 'rejected')
            Text(
              'Original booking schedule remains unchanged.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: ResponsiveUtility.fontSize(12),
              ),
            ),
        ],
      ),
      isDark,
    );
  }

  Widget _professionalContactValue({
    required ScalingUtility scale,
    required String phone,
    required bool isDark,
    required bool showUnlockNote,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Contact',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(2)),
          Text(
            "+ $phone",
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.black.withValues(alpha: 0.72),
              fontSize: ResponsiveUtility.fontSize(12),
              height: 1.35,
            ),
          ),
          if (showUnlockNote) ...[
            SizedBox(height: scale.getScaledHeight(4)),
            Text(
              'Professional phone number will get unlocked on the day of event.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.58)
                    : Colors.black.withValues(alpha: 0.58),
                fontSize: ResponsiveUtility.fontSize(12),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bullet(ScalingUtility scale, String value, bool isDark) {
    return Text(
      '☉ $value',
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.74)
            : Colors.black.withValues(alpha: 0.74),
        fontSize: ResponsiveUtility.fontSize(12),
      ),
    );
  }

  Widget _timelineCard({
    required ScalingUtility scale,
    required Map<String, dynamic> bookingData,
    required String statusCode,
    required int completedSteps,
    required bool isDark,
  }) {
    const steps = <String>[
      'Booking Request Submitted',
      'Admin Approval & Booking Status',
      'Professional Assigned',
      'Event Started',
      'Event Completed',
    ];
    final statusTimeline = _asMap(bookingData['statusTimeline']);
    final cancellation = _asMap(bookingData['cancellation']);
    final rejectionReason = _string(bookingData['rejectionReason']);
    final rejectedAt = _asDateTime(
      bookingData['rejectedByAdminAt'] ?? statusTimeline['rejectedAt'],
    );
    final cancellationByRaw = _string(
      cancellation['cancelledBy'],
    ).toLowerCase();
    final cancelledByRole =
        (cancellationByRaw == 'admin' || cancellationByRaw == 'customer')
        ? cancellationByRaw
        : _string(bookingData['cancelledByRole']).toLowerCase();
    final cancelledReason = _string(
      cancellation['reason'] ?? bookingData['cancellationReason'],
    );
    final cancelledAt = _asDateTime(
      cancellation['cancelledAt'] ?? statusTimeline['cancelledAt'],
    );
    final isFinalizedAtStep2 =
        statusCode == 'CANCELLED' || statusCode == 'REJECTED';
    final finalStatusLabel = statusCode == 'REJECTED'
        ? 'REJECTED'
        : 'CANCELLED';
    final finalStatusMessage = statusCode == 'REJECTED'
        ? 'Rejected by admin'
        : cancelledByRole == 'admin'
        ? 'Canceled by admin'
        : 'Canceled by customer';
    final finalReason = statusCode == 'REJECTED'
        ? rejectionReason
        : cancelledReason;
    final canShowAdminReason =
        (statusCode == 'REJECTED' || cancelledByRole == 'admin') &&
        finalReason.isNotEmpty;
    final finalStatusAt = statusCode == 'REJECTED' ? rejectedAt : cancelledAt;
    final finalStatusTimestamp = finalStatusAt == null
        ? ''
        : DateFormat('MMM d, yyyy hh:mm a').format(finalStatusAt);
    return _card(
      scale,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Progress Timeline',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtility.fontSize(14),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(8)),
          ...List.generate(steps.length, (index) {
            final number = index + 1;
            final isStep2FinalStatus = isFinalizedAtStep2 && number == 2;
            final done = isStep2FinalStatus || number <= completedSteps;
            final active =
                !isStep2FinalStatus && !done && number == completedSteps + 1;
            final iconBg = isStep2FinalStatus
                ? const Color(0xffFF4B5C)
                : done
                ? const Color(0xffB500FF)
                : active
                ? const Color(0xff575C6F)
                : const Color(0xff40475E);
            final titleColor = done || active
                ? isDark
                      ? Colors.white
                      : Colors.black
                : isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4);
            final subtitle = finalStatusLabel == 'REJECTED'
                ? "Rejected"
                : done
                ? 'Completed'
                : active
                ? (number == 2 ? 'In Progress (1 - 24 Hrs.)' : 'In Progress')
                : 'Pending';
            final subtitleColor = done
                ? finalStatusLabel == 'REJECTED'
                      ? const Color(0xffFF4B5C)
                      : isDark
                      ? Color(0xff48E86F)
                      : Color(0xff00A63E)
                : active
                ? finalStatusLabel == 'REJECTED'
                      ? const Color(0xffFF4B5C)
                      : isDark
                      ? Color(0xffE9B64A)
                      : Color(0xffFF8C00)
                : finalStatusLabel == 'REJECTED'
                ? const Color(0xffFF4B5C)
                : isDark
                ? Colors.white38
                : Colors.black38;

            return Padding(
              padding: EdgeInsets.only(bottom: scale.getScaledHeight(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: scale.getScaledWidth(28),
                    height: scale.getScaledHeight(28),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: scale.getScaledWidth(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index],
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveUtility.fontSize(12),
                          ),
                        ),
                        if (isStep2FinalStatus) ...[
                          SizedBox(height: scale.getScaledHeight(4)),
                          Wrap(
                            spacing: scale.getScaledWidth(8),
                            runSpacing: scale.getScaledHeight(4),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: scale.getScaledWidth(8),
                                  vertical: scale.getScaledHeight(2),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xffFF4B5C,
                                  ).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xffFF4B5C),
                                  ),
                                ),
                                child: Text(
                                  finalStatusLabel,
                                  style: TextStyle(
                                    color: const Color(0xffFF4B5C),
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveUtility.fontSize(12),
                                  ),
                                ),
                              ),
                              if (finalStatusTimestamp.isNotEmpty)
                                Text(
                                  finalStatusTimestamp,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: ResponsiveUtility.fontSize(12),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: scale.getScaledHeight(2)),
                          Text(
                            finalStatusMessage,
                            style: TextStyle(
                              color: const Color(0xffFF4B5C),
                              fontSize: ResponsiveUtility.fontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (canShowAdminReason)
                            Text(
                              'Reason: $finalReason',
                              style: TextStyle(
                                color: const Color(0xffFF9AA3),
                                fontSize: ResponsiveUtility.fontSize(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ] else
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: ResponsiveUtility.fontSize(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      isDark,
    );
  }

  Widget _priceCard({
    required ScalingUtility scale,
    required String serviceName,
    required String planName,
    required String eventName,
    required int ratePerHour,
    required String durationHours,
    required int bookingAmount,
    required int netAmount,
    required int discountAmount,
    required int gstAmount,
    required int taxableAmount,
    required int totalAmount,
    required String paymentStatus,
    required bool isDark,
  }) {
    final paymentLabel = paymentStatus.isEmpty
        ? 'Payment: -'
        : 'Payment: ${paymentStatus.toLowerCase()}';
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
            width: double.infinity,
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
                  'Price Preview',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtility.width(10),
                    vertical: ResponsiveUtility.height(3),
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
                    paymentLabel,
                    style: TextStyle(
                      color: isDark ? Color(0xff12D86D) : Color(0xff00A63E),
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtility.width(10),
              ResponsiveUtility.height(10),
              ResponsiveUtility.width(10),
              ResponsiveUtility.height(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(1)),
                Text(
                  '${planName.isEmpty ? '-' : planName} . ${eventName.isEmpty ? '-' : eventName}',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.black.withValues(alpha: 0.65),
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(10)),
                _priceLine(
                  scale,
                  'Rate per hour',
                  'Rs.${_formatAmount(ratePerHour)}',
                  isDark,
                ),
                if (!_isLiveWeddingPainterService(serviceName))
                  _priceLine(
                    scale,
                    'Duration',
                    '${durationHours.isEmpty ? '-' : durationHours} Hrs.',
                    isDark,
                  ),
                _priceLine(
                  scale,
                  'Booking amount',
                  'Rs.${_formatAmount(bookingAmount)}',
                  isDark,
                ),
                _priceLine(
                  scale,
                  'Net amount',
                  'Rs.${_formatAmount(netAmount)}',
                  isDark,
                ),
                if (discountAmount > 0)
                  _priceLine(
                    scale,
                    'Coupon discount',
                    '- Rs.${_formatAmount(discountAmount)}',
                    isDark,
                  ),
                _priceLine(
                  scale,
                  'Taxable amount',
                  'Rs.${_formatAmount(taxableAmount)}',
                  isDark,
                ),
                _priceLine(
                  scale,
                  'GST (18%)',
                  'Rs.${_formatAmount(gstAmount)}',
                  isDark,
                ),
                Container(
                  margin: EdgeInsets.only(top: scale.getScaledHeight(6)),
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.14),
                ),
                SizedBox(height: scale.getScaledHeight(6)),
                _priceLine(
                  scale,
                  'Total Payable',
                  'Rs.${_formatAmount(totalAmount)}',
                  isDark,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStatusCard({
    required ScalingUtility scale,
    required int bookingAmount,
    required int paidAmount,
    required int remainingAmount,
    required Map<String, dynamic> paymentMap,
    required Map<String, dynamic> financialBreakdown,
    required String paymentStatus,
    required String paymentType,
    required bool isDark,
  }) {
    final refundEligibility = _string(
      paymentMap['refundEligibility'] ??
          financialBreakdown['refundEligibility'],
    );
    final refundPercentage = _asInt(
      paymentMap['refundPercentage'] ?? financialBreakdown['refundPercentage'],
    );
    return _card(
      scale,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: scale.getScaledFont(14),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          _titleValue(
            scale,
            'Total Booking Amount',
            'Rs.${_formatAmount(bookingAmount)}',
            isDark,
          ),
          _titleValue(
            scale,
            'Amount Paid',
            'Rs.${_formatAmount(paidAmount)}',
            isDark,
          ),
          _titleValue(
            scale,
            'Remaining Amount',
            'Rs.${_formatAmount(remainingAmount)}',
            isDark,
          ),
          _titleValue(scale, 'Payment Type', paymentType, isDark),
          _titleValue(
            scale,
            'Status',
            paymentStatus.isEmpty ? 'Pending' : paymentStatus,
            isDark,
          ),
          if (refundEligibility.isNotEmpty)
            _titleValue(scale, 'Refund Eligibility', refundEligibility, isDark),
          if (refundPercentage > 0)
            _titleValue(
              scale,
              'Refund Percentage',
              '$refundPercentage%',
              isDark,
            ),
        ],
      ),
      isDark,
    );
  }

  Widget _refundStatusCard({
    required ScalingUtility scale,
    required String customerId,
    required bool isDark,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection(ServiceCatalogPaths.refundsCollection)
          .where('bookingId', isEqualTo: widget.bookingId)
          .where('customerId', isEqualTo: customerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _card(
            scale,
            const Center(child: CircularProgressIndicator()),
            isDark,
          );
        }
        if (snapshot.hasError) {
          return _card(
            scale,
            Text(
              'Refund status is temporarily unavailable.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: scale.getScaledFont(12),
              ),
            ),
            isDark,
          );
        }
        final records = (snapshot.data?.docs ?? []).toList()
          ..sort((left, right) {
            final leftData = left.data();
            final rightData = right.data();
            final leftDate =
                _asDateTime(leftData['updatedAt']) ??
                _asDateTime(leftData['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final rightDate =
                _asDateTime(rightData['updatedAt']) ??
                _asDateTime(rightData['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return rightDate.compareTo(leftDate);
          });
        if (records.isEmpty) {
          return _card(
            scale,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Status',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: scale.getScaledFont(14),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(2)),
                Text(
                  'No refund has been requested for this booking.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: scale.getScaledFont(12),
                  ),
                ),
              ],
            ),
            isDark,
          );
        }

        final refund = records.first.data();
        final status = _string(refund['refundStatus']).toUpperCase();
        final mode = _string(refund['refundMode']).toUpperCase();
        final providerReference = _firstNonEmpty(<String>[
          _string(refund['razorpayRefundId']),
          _string(refund['providerRefundId']),
          _string(refund['providerReference']),
          _string(refund['transactionReference']),
        ]);
        final reason = _firstNonEmpty(<String>[
          _string(refund['failureReason']),
          status == 'REJECTED' ? _string(refund['adminRemarks']) : '',
          _string(refund['adminNote']),
        ]);
        return _card(
          scale,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refund Status',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: scale.getScaledFont(14),
                ),
              ),
              SizedBox(height: scale.getScaledHeight(4)),
              _titleValue(
                scale,
                'Refund ID',
                _string(refund['refundId']).isEmpty
                    ? records.first.id
                    : _string(refund['refundId']),
                isDark,
              ),
              _titleValue(
                scale,
                'Amount',
                'Rs.${_formatAmount(_asInt(refund['refundAmount']))}',
                isDark,
              ),
              _titleValue(scale, 'Status', _refundStatusLabel(status), isDark),
              _titleValue(
                scale,
                'Destination',
                mode == 'RAZORPAY' || mode == 'PENDING_PROVIDER'
                    ? 'Original payment method'
                    : 'Manual refund by admin',
                isDark,
              ),
              _titleValue(
                scale,
                'Requested On',
                _formatRefundDate(
                  _asDateTime(refund['requestedAt']) ??
                      _asDateTime(refund['createdAt']),
                ),
                isDark,
              ),
              if (_asDateTime(refund['approvedAt']) != null)
                _titleValue(
                  scale,
                  'Approved On',
                  _formatRefundDate(_asDateTime(refund['approvedAt'])),
                  isDark,
                ),
              if (_asDateTime(refund['processedAt']) != null)
                _titleValue(
                  scale,
                  'Processed On',
                  _formatRefundDate(_asDateTime(refund['processedAt'])),
                  isDark,
                ),
              if (_asDateTime(refund['completedAt']) != null)
                _titleValue(
                  scale,
                  'Completed On',
                  _formatRefundDate(_asDateTime(refund['completedAt'])),
                  isDark,
                ),
              if (providerReference.isNotEmpty)
                _titleValue(
                  scale,
                  'Provider Reference',
                  providerReference,
                  isDark,
                ),
              if (reason.isNotEmpty)
                _titleValue(scale, 'Details', reason, isDark),
            ],
          ),
          isDark,
        );
      },
    );
  }

  String _refundStatusLabel(String status) {
    switch (status) {
      case 'REQUESTED':
        return 'Requested';
      case 'UNDER_REVIEW':
        return 'Under review';
      case 'APPROVED':
        return 'Approved';
      case 'PROCESSING':
        return 'Processing to original payment method';
      case 'COMPLETED':
        return 'Refund completed';
      case 'REFUNDED':
        return 'Refunded';
      case 'REJECTED':
        return 'Rejected';
      case 'PROVIDER_FAILED':
        return 'Provider processing failed';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  String _formatRefundDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('MMM d, yyyy h:mm a').format(value);
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
              fontSize: scale.getScaledFont(12),
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
              fontSize: scale.getScaledFont(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required ScalingUtility scale,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool loading = false,
    bool danger = false,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: danger
            ? const Color.fromARGB(255, 202, 0, 24)
            : isDark
            ? Colors.white
            : AppColors.primaryColor,
        foregroundColor: danger
            ? Colors.white
            : isDark
            ? Color(0xff45156A)
            : Colors.white,
        minimumSize: Size.fromHeight(scale.getScaledHeight(46)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: loading
          ? SizedBox(
              width: scale.getScaledWidth(16),
              height: scale.getScaledHeight(16),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  SizedBox(width: scale.getScaledWidth(6)),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: scale.getScaledFont(15),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _requestReschedule(
    DateTime? currentDate,
    String currentTime,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _rescheduleLoading) {
      return;
    }
    final now = DateTime.now();
    final initialDate = currentDate != null && currentDate.isAfter(now)
        ? currentDate
        : now;
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (newDate == null || !mounted) {
      return;
    }
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (newTime == null || !mounted) {
      return;
    }

    final reasonController = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff171129),
        title: const Text(
          'Request Reschedule',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${_dateTimeLabel(currentDate, currentTime)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Requested: ${_dateTimeLabel(newDate, newTime.format(context))}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Admin approval is required before the booking schedule changes.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Add reason',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xff100C1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (shouldSubmit != true || !mounted) {
      return;
    }
    if (reason.length < 5) {
      AppSnackbar.error(
        'Reason Required',
        'Please enter at least 5 characters.',
      );
      return;
    }

    setState(() => _rescheduleLoading = true);
    try {
      await _bookingService.requestReschedule(
        bookingId: widget.bookingId,
        customerId: uid,
        newDate: newDate,
        newTime: newTime.format(context),
        reason: reason,
      );
      AppSnackbar.success(
        'Request Submitted',
        'Your reschedule request is pending admin approval.',
      );
    } catch (_) {
      AppSnackbar.error(
        'Request Failed',
        'Unable to request reschedule right now.',
      );
    } finally {
      if (mounted) {
        setState(() => _rescheduleLoading = false);
      }
    }
  }
}

class _CustomerBookingFinancials {
  const _CustomerBookingFinancials({
    required this.paymentMap,
    required this.financialBreakdown,
    required this.paymentStatus,
    required this.paymentTypeLabel,
    required this.rateAmount,
    required this.bookingAmount,
    required this.netAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.isFullyPaid,
  });

  final Map<String, dynamic> paymentMap;
  final Map<String, dynamic> financialBreakdown;
  final String paymentStatus;
  final String paymentTypeLabel;
  final int rateAmount;
  final int bookingAmount;
  final int netAmount;
  final int discountAmount;
  final int taxableAmount;
  final int gstAmount;
  final int finalAmount;
  final int paidAmount;
  final int remainingAmount;
  final bool isFullyPaid;

  factory _CustomerBookingFinancials.from(Map<String, dynamic> data) {
    final payment = _asMap(data['payment']);
    final breakdown = _asMap(
      data['financialBreakdown'] ??
          data['pricingSnapshot'] ??
          payment['financialBreakdown'],
    );
    final paymentStatus = _firstNonEmpty(<String>[
      _string(data['paymentStatus']),
      _string(payment['paymentStatus']),
      _string(payment['status']),
    ]).toUpperCase();
    final finalAmount = _firstPositiveInt(<dynamic>[
      data['finalAmount'],
      data['finalCustomerPayable'],
      breakdown['finalAmount'],
      breakdown['finalCustomerPayable'],
      payment['finalAmount'],
      payment['finalPayableAmount'],
      data['totalAmount'],
      breakdown['totalAmount'],
    ]);
    final bookingAmount = _firstPositiveInt(<dynamic>[
      breakdown['grossAmount'],
      breakdown['originalAmount'],
      breakdown['totalAmount'],
      data['originalCustomerPayable'],
      data['totalAmount'],
      finalAmount,
    ]);
    final paidAmount = _firstPositiveInt(<dynamic>[
      data['paidAmount'],
      payment['paidAmount'],
      data['depositAmount'],
      payment['depositAmount'],
    ]);
    final storedRemaining = _firstPositiveInt(<dynamic>[
      data['remainingAmount'],
      payment['remainingAmount'],
      breakdown['remainingAmount'],
      breakdown['remainingDue'],
    ]);
    final isFullyPaid =
        paymentStatus == 'PAID' ||
        paymentStatus == 'FULLY_PAID' ||
        data['remainingPaid'] == true ||
        payment['remainingPaid'] == true;
    final remainingAmount = isFullyPaid
        ? 0
        : paidAmount > 0 && finalAmount > 0
        ? (finalAmount - paidAmount).clamp(0, finalAmount)
        : storedRemaining;
    final netAmount = _firstPositiveInt(<dynamic>[
      breakdown['netAmount'],
      breakdown['serviceSubtotal'],
      data['basePrice'],
    ]);
    final discountAmount = _asInt(
      breakdown['discountAmount'] ??
          breakdown['couponDiscountAmount'] ??
          data['discountAmount'] ??
          payment['discountAmount'],
    );
    final gstAmount = _firstPositiveInt(<dynamic>[
      breakdown['gstAmount'],
      data['gstAmount'],
      payment['gstAmount'],
      bookingAmount - netAmount,
    ]);
    final taxableAmount = _firstPositiveInt(<dynamic>[
      breakdown['taxableAmount'],
      breakdown['discountedServiceSubtotal'],
      netAmount - discountAmount,
    ]);
    final quantity = _asInt(
      breakdown['quantityOrDuration'] ?? data['eventDurationHours'],
      fallback: 0,
    );
    final rateAmount = _firstPositiveInt(<dynamic>[
      breakdown['rateAmount'],
      data['rateAmount'],
      payment['rateAmount'],
      quantity > 0 ? (netAmount / quantity).round() : 0,
      data['basePrice'],
    ]);

    return _CustomerBookingFinancials(
      paymentMap: payment,
      financialBreakdown: breakdown,
      paymentStatus: paymentStatus.isEmpty ? 'PENDING' : paymentStatus,
      paymentTypeLabel: _paymentTypeLabelFromValues(
        mode: _firstNonEmpty(<String>[
          _string(data['paymentMode']),
          _string(payment['mode']),
          _string(payment['paymentMode']),
        ]),
        status: paymentStatus,
        remainingPaid: isFullyPaid,
      ),
      rateAmount: rateAmount,
      bookingAmount: bookingAmount,
      netAmount: netAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      isFullyPaid: isFullyPaid,
    );
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value).replaceAll(RegExp(r'[^0-9-]'), '')) ??
      fallback;
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

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

String _dateTimeLabel(DateTime? date, String time) {
  if (date == null && time.isEmpty) return '-';
  final dateLabel = date == null ? '' : DateFormat('MMM d, yyyy').format(date);
  if (dateLabel.isEmpty) return time;
  if (time.isEmpty) return dateLabel;
  return '$dateLabel \u00b7 $time';
}

(Color, String) _statusStyle(String statusCode) {
  switch (statusCode) {
    case 'REQUESTED':
      return (const Color(0xffC98A2D), 'Requested');
    case 'APPROVED':
      return (const Color(0xff6D8BFF), 'Approved');
    case 'ASSIGNED':
      return (const Color(0xff59B5FF), 'Assigned');
    case 'CONFIRMED':
      return (const Color(0xff23D658), 'Confirmed');
    case 'IN_PROGRESS':
      return (const Color(0xff00A9FF), 'In Progress');
    case 'COMPLETED':
      return (const Color(0xffB31CFF), 'Completed');
    case 'CANCELLED':
      return (const Color(0xffFF2F2F), 'Canceled');
    case 'REJECTED':
      return (const Color(0xffFF7B8C), 'Rejected');
    default:
      return (const Color(0xffC98A2D), 'Requested');
  }
}

String _normalizedStatusCode(Map<String, dynamic> data) {
  final direct = _string(data['status']).toUpperCase();
  if (direct.isNotEmpty) {
    if (direct == 'CANCELED') return 'CANCELLED';
    if (direct.contains('CANCEL')) return 'CANCELLED';
    if (direct.contains('REJECT')) return 'REJECTED';
    if (direct == 'PENDING' || direct == 'REQUEST_PENDING') {
      return 'REQUESTED';
    }
    return direct;
  }

  final lifecycle = _string(data['lifecycleStatus']).toLowerCase();
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
  final bookingStatus = _string(data['bookingStatus']).toLowerCase();
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
      return 'CANCELLED';
    case 'rejected':
      return 'REJECTED';
  }
  return 'REQUESTED';
}

int _completedStepCount(Map<String, dynamic> data) {
  final statusCode = _normalizedStatusCode(data);
  final stage = _string(
    data['bookingStage'],
  ).toLowerCase().replaceAll(' ', '_');
  if (statusCode == 'CANCELLED' || statusCode == 'REJECTED') return 2;
  if (statusCode == 'COMPLETED' || stage == 'completed') return 5;
  if (statusCode == 'IN_PROGRESS' || stage == 'event_started') return 4;
  if (statusCode == 'CONFIRMED' ||
      statusCode == 'ASSIGNED' ||
      stage == 'professional_assigned' ||
      stage == 'professional_confirmed') {
    return 3;
  }
  if (statusCode == 'APPROVED' ||
      stage == 'booking_got_accepted_by_admin' ||
      stage == 'accepted_by_admin') {
    return 2;
  }
  return 1;
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

String _paymentTypeLabelFromValues({
  required String mode,
  required String status,
  required bool remainingPaid,
}) {
  final normalizedMode = mode.toUpperCase();
  final normalizedStatus = status.toUpperCase();
  if (normalizedMode == 'ADVANCE_20' ||
      normalizedStatus == 'PARTIALLY_PAID' ||
      normalizedStatus == 'ADVANCE_PAID') {
    return '20% Advance';
  }
  if (normalizedMode == 'REMAINING' || remainingPaid) {
    return 'Remaining Payment';
  }
  if (normalizedStatus == 'PAID' || normalizedStatus == 'FULLY_PAID') {
    return 'Full Payment';
  }
  return normalizedMode.isEmpty ? 'Pending' : normalizedMode;
}

String _timerText(Map<String, dynamic> data) {
  final status = _normalizedStatusCode(data);
  if (status != 'IN_PROGRESS') {
    return '';
  }
  final endTime = _asDateTime(data['bookingEndTime']);
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

bool _isEventDateTodayOrPast(DateTime? eventDate) {
  if (eventDate == null) {
    return false;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
  return !today.isBefore(eventDay);
}

String _maskPhoneNumber(String phoneNumber) {
  final trimmed = phoneNumber.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 5) {
    return '*****';
  }
  final visibleCount = digits.length > 10 ? digits.length - 10 : 0;
  final prefix = visibleCount > 0
      ? '${digits.substring(0, visibleCount)} '
      : '';
  final localNumber = visibleCount > 0
      ? digits.substring(visibleCount)
      : digits;
  final visibleStart = localNumber.substring(0, localNumber.length - 5);
  return '$prefix$visibleStart*****';
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

bool _isLiveWeddingPainterService(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.contains('wedding painter') ||
      normalized.contains('live painter');
}
