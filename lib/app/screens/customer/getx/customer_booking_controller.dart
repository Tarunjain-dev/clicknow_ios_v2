import 'dart:async';

import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerBookingItem {
  const CustomerBookingItem({
    required this.id,
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
    required this.createdAt,
  });

  final String id;
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
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceCatalogId': serviceCatalogId,
      'serviceTitle': serviceTitle,
      'eventTypeId': eventTypeId,
      'eventTypeName': eventTypeName,
      'planKey': planKey,
      'planName': planName,
      'basePrice': basePrice,
      'gstPercent': gstPercent,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'eventDate': eventDate == null ? null : Timestamp.fromDate(eventDate!),
      'eventTime': eventTime,
      'eventDurationHours': eventDurationHours,
      'guestCount': guestCount,
      'venueName': venueName,
      'venueHouseDetails': venueHouseDetails,
      'venueLandmarkDetails': venueLandmarkDetails,
      'fullAddress': fullAddress,
      'state': state,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'specialRequirements': specialRequirements,
      'urgentBooking': urgentBooking,
      'onsiteContactName': onsiteContactName,
      'onsiteContactPhone': onsiteContactPhone,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return <String, dynamic>{
      'id': id,
      'serviceCatalogId': serviceCatalogId,
      'serviceTitle': serviceTitle,
      'eventTypeId': eventTypeId,
      'eventTypeName': eventTypeName,
      'planKey': planKey,
      'planName': planName,
      'basePrice': basePrice,
      'gstPercent': gstPercent,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'eventDate': eventDate?.toIso8601String(),
      'eventTime': eventTime,
      'eventDurationHours': eventDurationHours,
      'guestCount': guestCount,
      'venueName': venueName,
      'venueHouseDetails': venueHouseDetails,
      'venueLandmarkDetails': venueLandmarkDetails,
      'fullAddress': fullAddress,
      'state': state,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'specialRequirements': specialRequirements,
      'urgentBooking': urgentBooking,
      'onsiteContactName': onsiteContactName,
      'onsiteContactPhone': onsiteContactPhone,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory CustomerBookingItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CustomerBookingItem.fromMap(doc.data(), id: doc.id);
  }

  factory CustomerBookingItem.fromLocalMap(Map<String, dynamic> data) {
    return CustomerBookingItem.fromMap(
      data,
      id: (data['id'] as String? ?? '').trim(),
    );
  }

  factory CustomerBookingItem.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return CustomerBookingItem(
      id: id,
      serviceCatalogId: (data['serviceCatalogId'] as String? ?? '').trim(),
      serviceTitle: (data['serviceTitle'] as String? ?? '').trim(),
      eventTypeId: (data['eventTypeId'] as String? ?? '').trim(),
      eventTypeName: (data['eventTypeName'] as String? ?? '').trim(),
      planKey: (data['planKey'] as String? ?? '').trim(),
      planName: (data['planName'] as String? ?? '').trim(),
      basePrice: _asInt(data['basePrice']),
      gstPercent: _asDouble(data['gstPercent'], fallback: 18.0),
      gstAmount: _asInt(data['gstAmount']),
      totalAmount: _asInt(data['totalAmount']),
      eventDate: _asDateTime(data['eventDate']),
      eventTime: (data['eventTime'] as String? ?? '').trim(),
      eventDurationHours: (data['eventDurationHours'] as String? ?? '').trim(),
      guestCount: (data['guestCount'] as String? ?? '').trim(),
      venueName: (data['venueName'] as String? ?? '').trim(),
      venueHouseDetails: (data['venueHouseDetails'] as String? ?? '').trim(),
      venueLandmarkDetails: (data['venueLandmarkDetails'] as String? ?? '')
          .trim(),
      fullAddress: (data['fullAddress'] as String? ?? '').trim(),
      state: (data['state'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      pincode: (data['pincode'] as String? ?? '').trim(),
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
      specialRequirements: (data['specialRequirements'] as String? ?? '')
          .trim(),
      urgentBooking: (data['urgentBooking'] as bool?) ?? false,
      onsiteContactName: (data['onsiteContactName'] as String? ?? '').trim(),
      onsiteContactPhone: (data['onsiteContactPhone'] as String? ?? '').trim(),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  CustomerBookingItem copyWith({String? id, DateTime? createdAt}) {
    return CustomerBookingItem(
      id: id ?? this.id,
      serviceCatalogId: serviceCatalogId,
      serviceTitle: serviceTitle,
      eventTypeId: eventTypeId,
      eventTypeName: eventTypeName,
      planKey: planKey,
      planName: planName,
      basePrice: basePrice,
      gstPercent: gstPercent,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      eventDate: eventDate,
      eventTime: eventTime,
      eventDurationHours: eventDurationHours,
      guestCount: guestCount,
      venueName: venueName,
      venueHouseDetails: venueHouseDetails,
      venueLandmarkDetails: venueLandmarkDetails,
      fullAddress: fullAddress,
      state: state,
      city: city,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
      specialRequirements: specialRequirements,
      urgentBooking: urgentBooking,
      onsiteContactName: onsiteContactName,
      onsiteContactPhone: onsiteContactPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CustomerBookingController extends GetxController {
  static const String _guestScope = 'guest';
  static const String _cartStoragePrefix = 'customer_booking_cart_v1_';
  static const String _checkoutStoragePrefix = 'customer_booking_checkout_v1_';

  static CustomerBookingController get instance {
    if (Get.isRegistered<CustomerBookingController>()) {
      return Get.find<CustomerBookingController>();
    }
    return Get.put(CustomerBookingController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService.instance;
  final RazorpayPaymentService _paymentService =
      RazorpayPaymentService.instance;
  final GetStorage _storage = GetStorage();

  final RxBool isCartLoading = true.obs;
  final RxBool isCheckoutSubmitting = false.obs;
  final RxBool isPaymentQuoteLoading = false.obs;
  final Rx<CustomerPaymentMode> checkoutPaymentMode =
      CustomerPaymentMode.advance.obs;
  final RxString checkoutCouponCode = ''.obs;
  final RxString checkoutCouponMessage = ''.obs;
  final RxString checkoutPaymentQuoteError = ''.obs;
  final Rxn<RazorpayPaymentQuote> checkoutPaymentQuote =
      Rxn<RazorpayPaymentQuote>();
  final RxList<CustomerBookingItem> cartItems = <CustomerBookingItem>[].obs;
  final RxList<CustomerBookingItem> checkoutItems = <CustomerBookingItem>[].obs;
  final RxInt cartCount = 0.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartSub;
  StreamSubscription<User?>? _authSub;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _bindCart();
    _authSub = _auth.authStateChanges().listen((_) {
      _bindCart();
    });
  }

  Future<void> _bindCart() async {
    _cartSub?.cancel();
    final uid = _uid;
    _restoreCheckoutFromLocal(uid: uid);
    final isGuestUser =
        _storage.read(AuthController.guestUserStorageKey) == true;

    if (uid == null) {
      if (isGuestUser) {
        clearCheckout();
        _applyCartItems(
          const <CustomerBookingItem>[],
          uid: null,
          persistLocal: true,
        );
        isCartLoading.value = false;
        return;
      }
      final cachedGuestCart = _readCartFromLocal(uid: null);
      _applyCartItems(cachedGuestCart, uid: null, persistLocal: false);
      isCartLoading.value = false;
      return;
    }

    final cachedUserCart = _readCartFromLocal(uid: uid);
    if (cachedUserCart.isNotEmpty) {
      _applyCartItems(cachedUserCart, uid: uid, persistLocal: false);
    }

    isCartLoading.value = cachedUserCart.isEmpty;
    _cartSub = _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .collection(ServiceCatalogPaths.customerCartSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(CustomerBookingItem.fromDoc)
                .toList(growable: false);
            _applyCartItems(items, uid: uid, persistLocal: true);
            isCartLoading.value = false;
          },
          onError: (_) {
            final fallback = _readCartFromLocal(uid: uid);
            _applyCartItems(fallback, uid: uid, persistLocal: false);
            isCartLoading.value = false;
            AppSnackbar.error(
              'Cart Error',
              'Unable to fetch booking cart right now.',
            );
          },
        );
  }

  Future<bool> addToCart(CustomerBookingItem item) async {
    final isGuestUser =
        _storage.read(AuthController.guestUserStorageKey) == true;
    if (isGuestUser) {
      await AuthController.instance.showLoginRequiredSheet();
      return false;
    }

    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error(
        'Login Required',
        'Please login to add booking to cart.',
      );
      return false;
    }

    try {
      final docRef = await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerCartSubcollection)
          .add(item.toMap());
      final optimistic = <CustomerBookingItem>[
        item.copyWith(id: docRef.id, createdAt: DateTime.now()),
        ...cartItems,
      ];
      _applyCartItems(optimistic, uid: uid, persistLocal: true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to add booking to cart: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error(
        'Add Failed',
        'Unable to add this booking to cart. Please retry.',
      );
      return false;
    }
  }

  Future<void> removeFromCart(String id) async {
    final uid = _uid;
    if (uid == null) {
      final updated = cartItems.where((item) => item.id != id).toList();
      _applyCartItems(updated, uid: null, persistLocal: true);
      return;
    }

    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerCartSubcollection)
          .doc(id)
          .delete();
      final updated = cartItems.where((item) => item.id != id).toList();
      _applyCartItems(updated, uid: uid, persistLocal: true);
    } catch (error, stackTrace) {
      debugPrint('Unable to remove booking from cart: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error('Delete Failed', 'Unable to remove booking item.');
    }
  }

  void loadCheckoutFromCart() {
    checkoutItems.assignAll(cartItems);
    _resetCheckoutOptions();
    _persistCheckoutToLocal(checkoutItems, uid: _uid);
    unawaited(refreshCheckoutPaymentQuote());
  }

  void setInstantCheckout(CustomerBookingItem item) {
    checkoutItems.assignAll(<CustomerBookingItem>[item]);
    _resetCheckoutOptions();
    _persistCheckoutToLocal(checkoutItems, uid: _uid);
    unawaited(refreshCheckoutPaymentQuote());
  }

  void _resetCheckoutOptions() {
    checkoutPaymentMode.value = CustomerPaymentMode.advance;
    checkoutCouponCode.value = '';
    checkoutCouponMessage.value = '';
    checkoutPaymentQuoteError.value = '';
    checkoutPaymentQuote.value = null;
  }

  Future<void> updateCartItem({
    required int index,
    required CustomerBookingItem item,
  }) async {
    if (index < 0 || index >= cartItems.length) {
      return;
    }
    final updated = cartItems.toList(growable: true);
    final existing = updated[index];
    final merged = item.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
    );
    updated[index] = merged;
    _applyCartItems(updated, uid: _uid, persistLocal: true);

    final uid = _uid;
    if (uid == null || merged.id.trim().isEmpty) {
      return;
    }
    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerCartSubcollection)
          .doc(merged.id)
          .set(merged.toMap(), SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Unable to sync cart item update: $error');
      debugPrintStack(stackTrace: stackTrace);
      AppSnackbar.error(
        'Update Failed',
        'Your booking changes could not be synced. Please retry.',
      );
    }
  }

  void updateCheckoutItem({
    required int index,
    required CustomerBookingItem item,
  }) {
    if (index < 0 || index >= checkoutItems.length) {
      return;
    }
    final updated = checkoutItems.toList(growable: true);
    final existing = updated[index];
    final merged = item.copyWith(
      id: existing.id,
      createdAt: existing.createdAt,
    );
    updated[index] = merged;
    checkoutItems.assignAll(updated);
    _persistCheckoutToLocal(checkoutItems, uid: _uid);
    unawaited(refreshCheckoutPaymentQuote());

    final cartId = merged.id.trim();
    if (cartId.isNotEmpty) {
      final cartIndex = cartItems.indexWhere((entry) => entry.id == cartId);
      if (cartIndex >= 0) {
        updateCartItem(index: cartIndex, item: merged);
      }
    }
  }

  Future<void> removeCheckoutItemAt(int index) async {
    if (index < 0 || index >= checkoutItems.length) {
      return;
    }
    final target = checkoutItems[index];
    final updatedCheckout = checkoutItems.toList(growable: true)
      ..removeAt(index);
    checkoutItems.assignAll(updatedCheckout);
    _persistCheckoutToLocal(checkoutItems, uid: _uid);
    unawaited(refreshCheckoutPaymentQuote());

    final cartId = target.id.trim();
    if (cartId.isNotEmpty) {
      await removeFromCart(cartId);
    }
  }

  void clearCheckout() {
    checkoutItems.clear();
    checkoutCouponCode.value = '';
    checkoutCouponMessage.value = '';
    checkoutPaymentQuoteError.value = '';
    checkoutPaymentQuote.value = null;
    checkoutPaymentMode.value = CustomerPaymentMode.advance;
    _clearCheckoutLocal(uid: _uid);
  }

  Future<void> setCheckoutPaymentMode(CustomerPaymentMode mode) async {
    checkoutPaymentMode.value = mode;
    await refreshCheckoutPaymentQuote();
  }

  void setCheckoutCouponCode(String value) {
    checkoutCouponCode.value = value.trim();
    checkoutCouponMessage.value = '';
  }

  Future<void> applyCheckoutCoupon() async {
    debugPrint('[Coupon] Applying coupon: "${checkoutCouponCode.value}"');
    await refreshCheckoutPaymentQuote(showMessage: true);
    final q = checkoutPaymentQuote.value;
    if (q != null) {
      debugPrint('[Coupon] Result: applied=${q.couponApplied} code="${q.couponCode}" '
          'discount=${q.discountAmount} subtotal=${q.netAmount} '
          'taxable=${q.taxableAmount} final=${q.finalAmount} payable=${q.payableAmount}');
    }
  }

  Future<void> refreshCheckoutPaymentQuote({bool showMessage = false}) async {
    final uid = _uid;
    final items = checkoutItems.toList(growable: false);
    if (uid == null || items.isEmpty) {
      checkoutPaymentQuote.value = null;
      checkoutPaymentQuoteError.value = '';
      return;
    }
    isPaymentQuoteLoading.value = true;
    checkoutPaymentQuoteError.value = '';
    try {
      if (items.length != 1) {
        throw StateError('Please quote one booking at a time.');
      }
      final item = items.first;
      final quote = await _paymentService.quoteCheckoutPayment(
        paymentMode: checkoutPaymentMode.value,
        couponCode: checkoutCouponCode.value,
        serviceCatalogId: item.serviceCatalogId,
        eventTypeId: item.eventTypeId,
        planKey: item.planKey,
        eventDurationHours: item.eventDurationHours,
      );
      if (quote.finalAmount <= 0 || quote.payableAmount <= 0) {
        throw StateError('Checkout amount is unavailable. Please retry.');
      }
      checkoutPaymentQuote.value = quote;
      if (showMessage) {
        checkoutCouponMessage.value = quote.couponApplied
            ? 'Coupon ${quote.couponCode} applied successfully.'
            : checkoutCouponCode.value.isEmpty
            ? 'Coupon removed.'
            : 'Coupon applied with no discount.';
      }
    } catch (error) {
      checkoutPaymentQuote.value = null;
      checkoutPaymentQuoteError.value = error is StateError
          ? error.message
          : 'Unable to calculate checkout amount. Please retry.';
      if (showMessage) {
        AppSnackbar.error('Checkout Error', checkoutPaymentQuoteError.value);
      }
    } finally {
      isPaymentQuoteLoading.value = false;
    }
  }

  Future<bool> submitCheckoutBookings() async {
    if (isCheckoutSubmitting.value) {
      return false;
    }
    final items = checkoutItems.toList(growable: false);
    if (items.isEmpty) {
      AppSnackbar.error(
        'No Booking',
        'Checkout does not have any booking items.',
      );
      return false;
    }
    if (items.length > 1) {
      AppSnackbar.error(
        'One Booking Per Checkout',
        'Please pay for one booking at a time until grouped checkout is enabled.',
      );
      return false;
    }

    final uid = _uid;
    if (uid == null) {
      await AuthController.instance.showLoginRequiredSheet(
        message: 'Please login to continue checkout',
      );
      AppSnackbar.error('Login Required', 'Please login to continue checkout.');
      return false;
    }

    if (checkoutPaymentQuote.value == null) {
      await refreshCheckoutPaymentQuote();
      if (checkoutPaymentQuote.value == null) {
        AppSnackbar.error(
          'Checkout Unavailable',
          checkoutPaymentQuoteError.value.isEmpty
              ? 'Unable to calculate checkout amount. Please retry.'
              : checkoutPaymentQuoteError.value,
        );
        return false;
      }
    }

    isCheckoutSubmitting.value = true;
    try {
      final drafts = items
          .map(
            (item) => BookingDraft(
              cartItemId: item.id,
              serviceCatalogId: item.serviceCatalogId,
              serviceTitle: item.serviceTitle,
              eventTypeId: item.eventTypeId,
              eventTypeName: item.eventTypeName,
              planKey: item.planKey,
              planName: item.planName,
              basePrice: item.basePrice,
              gstPercent: item.gstPercent,
              gstAmount: item.gstAmount,
              totalAmount: item.totalAmount,
              eventDate: item.eventDate,
              eventTime: item.eventTime,
              eventDurationHours: item.eventDurationHours,
              guestCount: item.guestCount,
              venueName: item.venueName,
              venueHouseDetails: item.venueHouseDetails,
              venueLandmarkDetails: item.venueLandmarkDetails,
              fullAddress: item.fullAddress,
              state: item.state,
              city: item.city,
              pincode: item.pincode,
              latitude: item.latitude,
              longitude: item.longitude,
              specialRequirements: item.specialRequirements,
              urgentBooking: item.urgentBooking,
              onsiteContactName: item.onsiteContactName,
              onsiteContactPhone: item.onsiteContactPhone,
            ),
          )
          .toList(growable: false);

      final results = await _bookingService.createBookingsFromCheckout(
        customerId: uid,
        drafts: drafts,
      );
      await _completeRazorpayPayments(results);
      final cartIdsToRemove = items
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (cartIdsToRemove.isNotEmpty) {
        final updated = cartItems
            .where((item) => !cartIdsToRemove.contains(item.id))
            .toList(growable: false);
        _applyCartItems(updated, uid: uid, persistLocal: true);
      } else {
        _applyCartItems(cartItems, uid: uid, persistLocal: true);
      }
      clearCheckout();
      AppSnackbar.success(
        'Payment Successful',
        'Booking request submitted successfully.',
      );
      return true;
    } catch (error) {
      final message = error is FirebaseException
          ? (error.message ??
                'Unable to submit booking right now. Please retry.')
          : error is StateError
          ? error.message
          : 'Unable to submit booking right now. Please retry.';
      AppSnackbar.error('Checkout Failed', message);
      return false;
    } finally {
      isCheckoutSubmitting.value = false;
    }
  }

  Future<void> _completeRazorpayPayments(
    List<BookingCommitResult> results,
  ) async {
    if (results.isEmpty) {
      throw StateError('No booking was created for payment.');
    }
    // Use the coupon code validated by the quote, not the raw text input.
    final quote = checkoutPaymentQuote.value;
    final validatedCouponCode =
        (quote?.couponApplied == true ? quote?.couponCode : null) ??
        checkoutCouponCode.value;
    final paymentMode = checkoutPaymentMode.value;

    debugPrint('[Checkout] Starting payment: mode=${paymentMode.code} '
        'coupon="$validatedCouponCode" bookings=${results.length}');
    if (quote != null) {
      debugPrint('[Checkout] Quote: subtotal=${quote.netAmount} '
          'discount=${quote.discountAmount} final=${quote.finalAmount} '
          'payable=${quote.payableAmount}');
    }

    for (final result in results) {
      debugPrint('[Payment] Creating order: bookingId=${result.bookingId} coupon="$validatedCouponCode"');
      final order = await _paymentService.createPaymentOrder(
        bookingId: result.bookingId,
        paymentMode: paymentMode,
        couponCode: validatedCouponCode,
      );
      debugPrint('[Payment] Order created: orderId=${order.orderId} '
          'amountPaise=${order.amountPaise} payable=${order.payableAmount} '
          'discount=${order.discountAmount} '
          'keyId=${order.keyId.isNotEmpty ? "present" : "MISSING"}');
      late final RazorpayCheckoutResult checkoutResult;
      try {
        checkoutResult = await _paymentService.openCheckout(order);
      } catch (_) {
        await _paymentService.markPaymentAbandoned(bookingId: result.bookingId);
        rethrow;
      }
      await _paymentService.verifyPayment(
        bookingId: result.bookingId,
        paymentId: order.paymentId,
        result: checkoutResult,
      );
    }
  }

  int totalFor(List<CustomerBookingItem> items) {
    return items.fold<int>(
      0,
      (runningTotal, item) => runningTotal + item.totalAmount,
    );
  }

  @override
  void onClose() {
    _cartSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }

  void _applyCartItems(
    List<CustomerBookingItem> items, {
    required String? uid,
    required bool persistLocal,
  }) {
    cartItems.assignAll(items);
    cartCount.value = items.length;
    if (persistLocal) {
      _persistCartToLocal(items, uid: uid);
    }
  }

  void _persistCartToLocal(
    List<CustomerBookingItem> items, {
    required String? uid,
  }) {
    final key = _cartStorageKey(uid: uid);
    if (items.isEmpty) {
      _storage.remove(key);
      return;
    }
    _storage.write(
      key,
      items.map((item) => item.toLocalMap()).toList(growable: false),
    );
  }

  List<CustomerBookingItem> _readCartFromLocal({required String? uid}) {
    return _readItemsFromLocalKey(_cartStorageKey(uid: uid));
  }

  void _persistCheckoutToLocal(
    List<CustomerBookingItem> items, {
    required String? uid,
  }) {
    final key = _checkoutStorageKey(uid: uid);
    if (items.isEmpty) {
      _storage.remove(key);
      return;
    }
    _storage.write(
      key,
      items.map((item) => item.toLocalMap()).toList(growable: false),
    );
  }

  void _restoreCheckoutFromLocal({required String? uid}) {
    final items = _readItemsFromLocalKey(_checkoutStorageKey(uid: uid));
    checkoutItems.assignAll(items);
    if (uid != null && items.isNotEmpty) {
      unawaited(refreshCheckoutPaymentQuote());
    }
  }

  void _clearCheckoutLocal({required String? uid}) {
    _storage.remove(_checkoutStorageKey(uid: uid));
  }

  List<CustomerBookingItem> _readItemsFromLocalKey(String key) {
    final raw = _storage.read(key);
    if (raw is! List) {
      return const <CustomerBookingItem>[];
    }

    final items = <CustomerBookingItem>[];
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      try {
        final data = Map<String, dynamic>.from(entry);
        final item = CustomerBookingItem.fromLocalMap(data);
        if (item.serviceTitle.isNotEmpty && item.totalAmount > 0) {
          items.add(item);
        }
      } catch (error, stackTrace) {
        debugPrint('Skipping invalid cached booking item: $error');
        debugPrintStack(stackTrace: stackTrace);
        continue;
      }
    }
    return items;
  }

  String _cartStorageKey({required String? uid}) {
    return '$_cartStoragePrefix${_storageScope(uid)}';
  }

  String _checkoutStorageKey({required String? uid}) {
    return '$_checkoutStoragePrefix${_storageScope(uid)}';
  }

  String _storageScope(String? uid) {
    final value = (uid ?? _guestScope).trim();
    if (value.isEmpty) {
      return _guestScope;
    }
    return value;
  }
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

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
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
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}
