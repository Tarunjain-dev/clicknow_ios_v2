import 'package:clicknow_version2/app/screens/customer/getx/customerBottomNavController.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/getx/customer_booking_controller.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/widgets/customer_service_detail_template.dart';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CustomerBookingViewMode { cart, checkout }

class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({
    super.key,
    this.mode = CustomerBookingViewMode.cart,
  });

  final CustomerBookingViewMode mode;

  bool get _isCheckout => mode == CustomerBookingViewMode.checkout;

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final bookingController = CustomerBookingController.instance;
    final isDark = HelperFunctions.isDarkMode(context);
    final pageBg = isDark ? const Color(0xff0F1020) : const Color(0xffF3F3F3);
    final cardBg = isDark
        ? const Color(0xff131333).withValues(alpha: 0.96)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0xff2A2F65)
        : const Color(0xffD9D9D9);
    final titleColor = isDark ? Colors.white : const Color(0xff1E1E1E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black54;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Obx(() {
          final items = _isCheckout
              ? bookingController.checkoutItems
              : bookingController.cartItems;
          final isLoading =
              !_isCheckout && bookingController.isCartLoading.value;
          final isSubmittingCheckout =
              bookingController.isCheckoutSubmitting.value;
          final total = bookingController.totalFor(items);
          final isEmpty = items.isEmpty;
          final paymentMode = bookingController.checkoutPaymentMode.value;
          final couponCode = bookingController.checkoutCouponCode.value;
          final quote = bookingController.checkoutPaymentQuote.value;
          final quoteLoading = bookingController.isPaymentQuoteLoading.value;
          final quoteError = bookingController.checkoutPaymentQuoteError.value;
          final couponMessage = bookingController.checkoutCouponMessage.value;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(
                    scale: scale,
                    title: _isCheckout ? 'Checkout' : 'Your Bookings',
                    subtitle: _isCheckout
                        ? '${items.length} services only'
                        : '${items.length} services added',
                    onBack: () => _handleBack(),
                    isDark: isDark,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD000FF),
                            ),
                          )
                        : isEmpty
                        ? _emptyState(
                            scale: scale,
                            isDark: isDark,
                            onBrowse: () => _goHomeTab(),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              scale.getScaledWidth(12),
                              scale.getScaledHeight(12),
                              scale.getScaledWidth(12),
                              scale.getScaledHeight(120),
                            ),
                            child: _summaryCard(
                              context: context,
                              scale: scale,
                              items: items,
                              total: total,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              isDark: isDark,
                              isCheckout: _isCheckout,
                              paymentMode: paymentMode,
                              quote: quote,
                              quoteLoading: quoteLoading,
                              quoteError: quoteError,
                              couponCode: couponCode,
                              couponMessage: couponMessage,
                              onPaymentModeChanged: (mode) => bookingController
                                  .setCheckoutPaymentMode(mode),
                              onCouponChanged:
                                  bookingController.setCheckoutCouponCode,
                              onApplyCoupon:
                                  bookingController.applyCheckoutCoupon,
                              onDelete: (index, item) async {
                                if (_isCheckout) {
                                  await bookingController.removeCheckoutItemAt(
                                    index,
                                  );
                                  return;
                                }
                                await bookingController.removeFromCart(item.id);
                              },
                              onEdit: (index, item) =>
                                  _openEditForm(index, item),
                              onCheckout: _isCheckout
                                  ? null
                                  : (item) =>
                                        _checkoutItem(bookingController, item),
                            ),
                          ),
                  ),
                ],
              ),
              if (!isEmpty && (_isCheckout || items.length == 1))
                _bottomButton(
                  scale: scale,
                  text: _isCheckout
                      ? quoteLoading
                            ? 'Calculating...'
                            : quote == null
                            ? 'Retry amount'
                            : 'Pay Rs.${_formatInt(quote.payableAmount)}'
                      : 'Proceed to checkout',
                  isLoading: isSubmittingCheckout,
                  onTap: () async {
                    if (AuthController.isGuestModeActive) {
                      await AuthController.instance.showLoginRequiredSheet();
                      return;
                    }
                    if (!_isCheckout) {
                      bookingController.loadCheckoutFromCart();
                      await Get.to(
                        () => const CustomerBookingsScreen(
                          mode: CustomerBookingViewMode.checkout,
                        ),
                        preventDuplicates: false,
                      );
                      return;
                    }
                    if (quote == null) {
                      await bookingController.refreshCheckoutPaymentQuote(
                        showMessage: true,
                      );
                      return;
                    }

                    final success = await bookingController
                        .submitCheckoutBookings();
                    if (!success) {
                      return;
                    }

                    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (Get.isRegistered<CustomerBottomNavController>()) {
                        Get.find<CustomerBottomNavController>().changeTab(2);
                      }
                    });
                  },
                  isDark: isDark,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _header({
    required ScalingUtility scale,
    required String title,
    required String subtitle,
    required VoidCallback onBack,
    required bool isDark,
    required Color titleColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            scale.getScaledWidth(10),
            scale.getScaledHeight(8),
            scale.getScaledWidth(12),
            scale.getScaledHeight(8),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(width: scale.getScaledWidth(6)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: scale.getScaledFont(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: scale.getScaledFont(14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: borderColor),
      ],
    );
  }

  Widget _emptyState({
    required ScalingUtility scale,
    required VoidCallback onBrowse,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: scale.getScaledHeight(96),
              width: scale.getScaledWidth(96),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xffD600FF), Color(0xff7B08AA)],
                ),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 42,
              ),
            ),
            SizedBox(height: scale.getScaledHeight(30)),
            Text(
              'No Bookings Yet',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: scale.getScaledFont(30 / 2),
              ),
            ),
            SizedBox(height: scale.getScaledHeight(8)),
            Text(
              'Browse our services and add them to your cart to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
                fontSize: scale.getScaledFont(14),
              ),
            ),
            SizedBox(height: scale.getScaledHeight(24)),
            SizedBox(
              width: double.infinity,
              height: scale.getScaledHeight(46),
              child: ElevatedButton(
                onPressed: onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white
                      : AppColors.primaryColor,
                  foregroundColor: isDark ? Color(0xff4C156F) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Browse Services',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: scale.getScaledFont(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required ScalingUtility scale,
    required List<CustomerBookingItem> items,
    required int total,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required bool isCheckout,
    required CustomerPaymentMode paymentMode,
    required RazorpayPaymentQuote? quote,
    required bool quoteLoading,
    required String quoteError,
    required String couponCode,
    required String couponMessage,
    required ValueChanged<CustomerPaymentMode> onPaymentModeChanged,
    required ValueChanged<String> onCouponChanged,
    required Future<void> Function() onApplyCoupon,
    required Future<void> Function(int index, CustomerBookingItem item)
    onDelete,
    required void Function(int index, CustomerBookingItem item) onEdit,
    required Future<void> Function(CustomerBookingItem item)? onCheckout,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: scale.getScaledWidth(10),
              vertical: scale.getScaledHeight(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xff2D2E58),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Color(0xff5282FF),
                    size: 12,
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(8)),
                Text(
                  'Booking Summary',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff1E1E1E),
                    fontWeight: FontWeight.w600,
                    fontSize: scale.getScaledFont(16),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: borderColor.withValues(alpha: 0.8)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(8),
              scale.getScaledWidth(10),
              scale.getScaledHeight(8),
            ),
            child: Column(
              children: [
                ...items.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
                    child: _summaryItem(
                      scale: scale,
                      item: entry.value,
                      isDark: isDark,
                      onDelete: () => onDelete(entry.key, entry.value),
                      onEdit: () => onEdit(entry.key, entry.value),
                      onCheckout: onCheckout == null
                          ? null
                          : () => onCheckout(entry.value),
                    ),
                  ),
                ),
                if (!isCheckout && items.length > 1) ...[
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
                    padding: EdgeInsets.all(scale.getScaledWidth(10)),
                    decoration: BoxDecoration(
                      color: const Color(0xffD000FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xffD000FF).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Please checkout one service at a time. Tap Checkout This Service on the item you want to pay for.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: scale.getScaledFont(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isCheckout) ...[
                  Container(
                    height: 1,
                    color: borderColor.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: scale.getScaledHeight(12)),
                  _paymentSection(
                    context: context,
                    scale: scale,
                    total: total,
                    isDark: isDark,
                    paymentMode: paymentMode,
                    quote: quote,
                    quoteLoading: quoteLoading,
                    quoteError: quoteError,
                    couponCode: couponCode,
                    couponMessage: couponMessage,
                    onPaymentModeChanged: onPaymentModeChanged,
                    onCouponChanged: onCouponChanged,
                    onApplyCoupon: onApplyCoupon,
                  ),
                  SizedBox(height: scale.getScaledHeight(12)),
                ],
                Container(height: 1, color: borderColor.withValues(alpha: 0.6)),
                SizedBox(height: scale.getScaledHeight(8)),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: const Color(0xffD000FF),
                        fontSize: scale.getScaledFont(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs.${_formatInt(isCheckout ? quote?.finalAmount ?? total : total)}',
                      style: TextStyle(
                        color: const Color(0xffD000FF),
                        fontSize: scale.getScaledFont(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required ScalingUtility scale,
    required CustomerBookingItem item,
    required bool isDark,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Future<void> Function()? onCheckout,
  }) {
    final location = [
      if (item.city.isNotEmpty) item.city,
      if (item.state.isNotEmpty) item.state,
      if (item.fullAddress.isNotEmpty) item.fullAddress,
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.serviceTitle,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xff1E1E1E),
                      fontSize: scale.getScaledFont(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff2B1D45)
                          : const Color(0xffFFF4E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xffFF9F1A),
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(6)),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff2B1D45)
                          : const Color(0xffFFEDEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xffFF475D),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Rs.${_formatInt(item.totalAmount)}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: scale.getScaledFont(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(4)),
                Text(
                  '(inc. GST)',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: scale.getScaledFont(10),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: scale.getScaledHeight(3)),
            _bulletText(scale, 'Date : ${_formatDate(item.eventDate)}', isDark),
            _bulletText(scale, 'Event type : ${item.eventTypeName}', isDark),
            _bulletText(scale, 'Price plan : ${item.planName}', isDark),
            _bulletText(scale, 'Taxable amount : Rs.${_formatInt(item.basePrice)}', isDark,),
            if (!_isLiveWeddingPainter(item.serviceCatalogId, item.serviceTitle))
              _bulletText(scale, 'Duration : ${item.eventDurationHours} Hrs.', isDark,),
            _bulletText(scale, 'Venue : ${item.venueName.isEmpty ? 'Not provided' : item.venueName}', isDark,),
            _bulletText(scale, 'House / Plot / Hall : ${item.venueHouseDetails.isEmpty ? 'Not provided' : item.venueHouseDetails}', isDark,),
            _bulletText(scale, 'Landmark / Directions : ${item.venueLandmarkDetails.isEmpty ? 'Not provided' : item.venueLandmarkDetails}', isDark,),
            _bulletText(scale, 'Venue Address : ${location.isEmpty ? 'Not provided' : location}', isDark,),
          ],
        ),
        if (onCheckout != null) ...[
          SizedBox(height: scale.getScaledHeight(9)),
          SizedBox(
            height: scale.getScaledHeight(40),
            child: OutlinedButton.icon(
              onPressed: () async => onCheckout(),
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: const Text('Checkout This Service'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? Colors.white
                    : const Color(0xff3E015E),
                side: BorderSide(
                  color: isDark ? Colors.white54 : const Color(0xff3E015E),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _paymentSection({
    required BuildContext context,
    required ScalingUtility scale,
    required int total,
    required bool isDark,
    required CustomerPaymentMode paymentMode,
    required RazorpayPaymentQuote? quote,
    required bool quoteLoading,
    required String quoteError,
    required String couponCode,
    required String couponMessage,
    required ValueChanged<CustomerPaymentMode> onPaymentModeChanged,
    required ValueChanged<String> onCouponChanged,
    required Future<void> Function() onApplyCoupon,
  }) {
    final quoteAvailable = quote != null;
    final advanceAmount = quote?.advanceAmount ?? 0;
    final fullAmount = quote?.finalAmount ?? 0;
    final payableAmount = quote?.payableAmount ?? 0;
    final remainingAmount = quote?.remainingAmount ?? 0;
    final discountAmount = quote?.discountAmount ?? 0;
    final netAmount = quote?.netAmount ?? 0;
    final taxableAmount = quote?.taxableAmount ?? 0;
    final gstAmount = quote?.gstAmount ?? 0;
    final finalAmount = quote?.finalAmount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Option',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xff1E1E1E),
            fontSize: scale.getScaledFont(15),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: scale.getScaledHeight(8)),
        Row(
          children: [
            Expanded(
              child: _paymentModeTile(
                scale: scale,
                title: '20% Advance',
                subtitle: quoteAvailable
                    ? 'Pay Rs.${_formatInt(advanceAmount)} now'
                    : quoteLoading
                    ? 'Loading amount...'
                    : 'Amount unavailable',
                selected: paymentMode == CustomerPaymentMode.advance,
                isDark: isDark,
                onTap: () => onPaymentModeChanged(CustomerPaymentMode.advance),
              ),
            ),
            SizedBox(width: scale.getScaledWidth(8)),
            Expanded(
              child: _paymentModeTile(
                scale: scale,
                title: 'Full Payment',
                subtitle: quoteAvailable
                    ? 'Pay Rs.${_formatInt(fullAmount)} now'
                    : quoteLoading
                    ? 'Loading amount...'
                    : 'Amount unavailable',
                selected: paymentMode == CustomerPaymentMode.full,
                isDark: isDark,
                onTap: () => onPaymentModeChanged(CustomerPaymentMode.full),
              ),
            ),
          ],
        ),
        SizedBox(height: scale.getScaledHeight(12)),
        _couponSelectorTile(
          context: context,
          scale: scale,
          isDark: isDark,
          quote: quote,
          couponCode: couponCode,
          discountAmount: discountAmount,
          quoteLoading: quoteLoading,
          onCouponChanged: onCouponChanged,
          onApplyCoupon: onApplyCoupon,
        ),
        if (couponMessage.isNotEmpty)
          Text(
            couponMessage,
            style: TextStyle(
              color:
                  couponMessage.toLowerCase().contains('error') ||
                      couponMessage.toLowerCase().contains('could not') ||
                      couponMessage.toLowerCase().contains('invalid')
                  ? const Color(0xffFF475D)
                  : const Color(0xff00A63E),
              fontSize: scale.getScaledFont(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        if (quoteError.isNotEmpty)
          Text(
            quoteError,
            style: TextStyle(
              color: const Color(0xffFF475D),
              fontSize: scale.getScaledFont(12),
              fontWeight: FontWeight.w600,
            ),
          ),
        SizedBox(height: scale.getScaledHeight(8)),
        if (quoteAvailable) ...[
          _amountLine(scale, 'Service Subtotal', netAmount, isDark),
          if (discountAmount > 0)
            _amountLine(scale, 'Coupon Discount', -discountAmount, isDark),
          if (discountAmount > 0)
            _amountLine(
              scale,
              'Discounted Subtotal',
              taxableAmount,
              isDark,
              isBold: true,
              labelColor: const Color(0xff2D55F5),
              valueColor: const Color(0xff2D55F5),
            ),
          _amountLine(
            scale,
            'GST (${quote.gstPercent.toStringAsFixed(0)}%)',
            gstAmount,
            isDark,
          ),
          _amountLine(scale, 'Final Amount', finalAmount, isDark),
        ],
        _amountLine(
          scale,
          paymentMode == CustomerPaymentMode.advance
              ? 'Advance Payment (20%)'
              : 'Payable Amount',
          payableAmount,
          isDark,
        ),
        if (paymentMode == CustomerPaymentMode.advance)
          _amountLine(scale, 'Remaining Payment', remainingAmount, isDark),
        SizedBox(height: scale.getScaledHeight(8)),
        Text(
          paymentMode == CustomerPaymentMode.advance
              ? 'Remaining amount will be collected before service completion.'
              : 'Your booking will be fully paid after successful payment.',
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.62)
                : Colors.black54,
            fontSize: scale.getScaledFont(12),
          ),
        ),
      ],
    );
  }

  Widget _couponSelectorTile({
    required BuildContext context,
    required ScalingUtility scale,
    required bool isDark,
    required RazorpayPaymentQuote? quote,
    required String couponCode,
    required int discountAmount,
    required bool quoteLoading,
    required ValueChanged<String> onCouponChanged,
    required Future<void> Function() onApplyCoupon,
  }) {
    final appliedCode = (quote?.couponApplied == true
            ? quote?.couponCode
            : couponCode)
        ?.trim();
    final hasApplied = quote?.couponApplied == true && (appliedCode ?? '').isNotEmpty;
    return InkWell(
      onTap: quoteLoading
          ? null
          : () => _showCouponBottomSheet(
                context: context,
                scale: scale,
                isDark: isDark,
                couponCode: appliedCode ?? couponCode,
                onCouponChanged: onCouponChanged,
                onApplyCoupon: onApplyCoupon,
              ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(scale.getScaledWidth(12)),
        decoration: BoxDecoration(
          color: hasApplied
              ? const Color(0xff00A63E).withValues(alpha: 0.1)
              : isDark
              ? const Color(0xff1A1B3C)
              : const Color(0xffF7F3FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasApplied
                ? const Color(0xff00A63E)
                : isDark
                ? const Color(0xff2A2F65)
                : const Color(0xffD9D9D9),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: hasApplied
                  ? const Color(0xff00A63E)
                  : const Color(0xffD000FF),
            ),
            SizedBox(width: scale.getScaledWidth(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasApplied ? 'Coupon $appliedCode applied' : 'Apply coupon',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xff1E1E1E),
                      fontWeight: FontWeight.w800,
                      fontSize: scale.getScaledFont(14),
                    ),
                  ),
                  Text(
                    hasApplied
                        ? 'Discount: Rs.${_formatInt(discountAmount)}. Tap to change or remove.'
                        : 'Choose from available coupons or enter a code.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: scale.getScaledFont(11),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCouponBottomSheet({
    required BuildContext context,
    required ScalingUtility scale,
    required bool isDark,
    required String couponCode,
    required ValueChanged<String> onCouponChanged,
    required Future<void> Function() onApplyCoupon,
  }) async {
    final controller = TextEditingController(text: couponCode);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xff111229) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(16),
              scale.getScaledHeight(16),
              scale.getScaledWidth(16),
              MediaQuery.of(sheetContext).viewInsets.bottom +
                  scale.getScaledHeight(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Choose Coupon',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: scale.getScaledFont(18),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                ..._visibleCoupons.map(
                  (coupon) => Padding(
                    padding: EdgeInsets.only(bottom: scale.getScaledHeight(8)),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xff2A2F65)
                              : const Color(0xffE0DCE8),
                        ),
                      ),
                      title: Text(
                        coupon.code,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(coupon.description),
                      trailing: const Icon(Icons.add_circle_outline_rounded),
                      onTap: () async {
                        controller.text = coupon.code;
                        setSheetState(() {});
                        onCouponChanged(coupon.code);
                        await onApplyCoupon();
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Enter coupon code',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    suffixIcon: controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear coupon',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () async {
                              controller.clear();
                              setSheetState(() {});
                              onCouponChanged('');
                              await onApplyCoupon();
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setSheetState(() {});
                    onCouponChanged(value);
                  },
                ),
                SizedBox(height: scale.getScaledHeight(12)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          controller.clear();
                          onCouponChanged('');
                          await onApplyCoupon();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        child: const Text('Remove'),
                      ),
                    ),
                    SizedBox(width: scale.getScaledWidth(10)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          onCouponChanged(controller.text.trim().toUpperCase());
                          await onApplyCoupon();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
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
    controller.dispose();
  }

  Widget _amountLine(
    ScalingUtility scale,
    String label,
    int amount,
    bool isDark, {
    bool isBold = false,
    bool strikeThrough = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    final prefix = amount < 0 ? '- Rs.' : 'Rs.';
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(4)),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  labelColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.72)
                      : Colors.black54),
              fontSize: scale.getScaledFont(13),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$prefix${_formatInt(amount.abs())}',
            style: TextStyle(
              color:
                  valueColor ??
                  (isDark ? Colors.white : const Color(0xff1E1E1E)),
              fontSize: scale.getScaledFont(13),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              decoration: strikeThrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentModeTile({
    required ScalingUtility scale,
    required String title,
    required String subtitle,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(scale.getScaledWidth(10)),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xff30124D) : const Color(0xffF9E8FF))
              : (isDark ? const Color(0xff191936) : const Color(0xffFAFAFA)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xffD000FF)
                : (isDark ? const Color(0xff2A2F65) : const Color(0xffD9D9D9)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xff1E1E1E),
                      fontSize: scale.getScaledFont(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? const Color(0xffD000FF) : Colors.grey,
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: scale.getScaledHeight(4)),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.66)
                    : Colors.black54,
                fontSize: scale.getScaledFont(11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulletText(ScalingUtility scale, String text, bool isDark) {
    return Text(
      '- $text',
      style: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.64) : Colors.black54,
        fontSize: scale.getScaledFont(14),
      ),
    );
  }

  Widget _bottomButton({
    required ScalingUtility scale,
    required String text,
    required bool isLoading,
    required Future<void> Function() onTap,
    required bool isDark,
  }) {
    return Positioned(
      left: scale.getScaledWidth(24),
      right: scale.getScaledWidth(24),
      bottom: scale.getScaledHeight(24),
      child: SizedBox(
        height: scale.getScaledHeight(52),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  await onTap();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : const Color(0xff3E015E),
            foregroundColor: isDark ? const Color(0xff35105B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: scale.getScaledWidth(20),
                  height: scale.getScaledHeight(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? const Color(0xff35105B) : Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: scale.getScaledFont(18),
                  ),
                ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    _goHomeTab();
  }

  void _goHomeTab() {
    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (Get.isRegistered<CustomerBottomNavController>()) {
        Get.find<CustomerBottomNavController>().changeTab(0);
      }
    });
  }

  Future<void> _checkoutItem(
    CustomerBookingController bookingController,
    CustomerBookingItem item,
  ) async {
    if (AuthController.isGuestModeActive) {
      await AuthController.instance.showLoginRequiredSheet();
      return;
    }
    bookingController.setInstantCheckout(item);
    await Get.to(
      () =>
          const CustomerBookingsScreen(mode: CustomerBookingViewMode.checkout),
      preventDuplicates: false,
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not selected';
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _formatInt(int value) {
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

  bool _isLiveWeddingPainter(String serviceId, String title) {
    final id = serviceId.trim().toLowerCase();
    final name = title.trim().toLowerCase();
    return id == 'live_wedding_painter' ||
        id == 'live_painter' ||
        name.contains('wedding painter') ||
        name.contains('live painter');
  }

  void _openEditForm(int index, CustomerBookingItem item) {
    final config = CustomerServiceDetailConfigs.fromCatalogServiceId(
      item.serviceCatalogId,
    );
    if (config == null) {
      return;
    }
    Get.to(
      () => CustomerServiceDetailScreen(
        config: config,
        initialBookingItem: item,
        editingMode: mode,
        editingIndex: index,
      ),
    );
  }
}

class _VisibleCoupon {
  const _VisibleCoupon(this.code, this.description);

  final String code;
  final String description;
}

const _visibleCoupons = <_VisibleCoupon>[
  _VisibleCoupon(
    'CLICKNOW10',
    'Get 10% off up to Rs.1,500. First-time users only.',
  ),
  _VisibleCoupon('STEALDEAL5', 'Get 5% off. Can be used twice per user.'),
  _VisibleCoupon(
    'ACT500',
    'Flat Rs.500 off on Magician, Anchor, or Musician. Minimum Rs.2,000.',
  ),
  _VisibleCoupon(
    'TALENT1000',
    'Flat Rs.1,000 off on Live Painter. Minimum Rs.8,000.',
  ),
];
