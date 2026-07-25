import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/services/notifications/fcm_notification_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class CustomerInvoiceItem {
  const CustomerInvoiceItem({
    required this.id,
    required this.bookingId,
    required this.serviceName,
    required this.eventName,
    required this.date,
    required this.totalAmount,
    required this.pdfUrl,
  });

  final String id;
  final String bookingId;
  final String serviceName;
  final String eventName;
  final String date;
  final int totalAmount;
  final String pdfUrl;

  factory CustomerInvoiceItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final generatedAt = _toDateTimeValue(data['generatedAt']);
    return CustomerInvoiceItem(
      id: (data['invoiceNumber'] as String? ?? doc.id).trim(),
      bookingId: (data['bookingId'] as String? ?? '').trim(),
      serviceName: (data['serviceName'] as String? ?? 'Service').trim(),
      eventName: (data['eventTypeName'] as String? ?? '-').trim(),
      date: generatedAt == null
          ? '-'
          : '${generatedAt.day} ${_monthLabelStatic(generatedAt.month)}, ${generatedAt.year}',
      totalAmount: _asIntValue(data['invoiceAmount']),
      pdfUrl: (data['pdfUrl'] as String? ?? '').trim(),
    );
  }
}

class CustomerAddressItem {
  const CustomerAddressItem({
    required this.id,
    required this.title,
    required this.address,
    required this.state,
    required this.city,
    required this.pincode,
  });

  final String id;
  final String title;
  final String address;
  final String state;
  final String city;
  final String pincode;

  factory CustomerAddressItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CustomerAddressItem(
      id: doc.id,
      title: (data['title'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      state: (data['state'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      pincode: (data['pincode'] as String? ?? '').trim(),
    );
  }

  CustomerAddressItem copyWith({
    String? id,
    String? title,
    String? address,
    String? state,
    String? city,
    String? pincode,
  }) {
    return CustomerAddressItem(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
    );
  }
}

class CustomerProfileController extends GetxController {
  static CustomerProfileController get instance {
    if (Get.isRegistered<CustomerProfileController>()) {
      return Get.find<CustomerProfileController>();
    }
    return Get.put(CustomerProfileController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final GetStorage _storage = GetStorage();
  final ImagePicker _imagePicker = ImagePicker();

  final RxString fullName = 'Guest User'.obs;
  final RxString profileImageUrl = ''.obs;
  final RxString phone = 'Login with phone to continue'.obs;
  final RxString location = 'Address not added'.obs;
  final RxString memberSince = '-'.obs;
  final RxString address = ''.obs;
  final RxString landmark = ''.obs;
  final RxString state = ''.obs;
  final RxString city = ''.obs;
  final RxString pincode = ''.obs;
  final RxString gstNumber = ''.obs;
  final RxnDouble latitude = RxnDouble();
  final RxnDouble longitude = RxnDouble();

  final RxBool isGuestUser = false.obs;
  final RxBool isProfileLoading = true.obs;
  final RxBool isSavingPersonalInfo = false.obs;
  final RxBool isAddressLoading = false.obs;
  final RxBool isAddressSaving = false.obs;
  final RxBool isUploadingProfileImage = false.obs;
  final RxBool isProfileCompleted = false.obs;

  final RxList<CustomerInvoiceItem> invoices = <CustomerInvoiceItem>[].obs;

  final RxList<CustomerAddressItem> savedAddresses =
      <CustomerAddressItem>[].obs;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _addressSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invoiceSub;

  int get totalInvoiceAmount {
    return invoices.fold<int>(
      0,
      (runningTotal, item) => runningTotal + item.totalAmount,
    );
  }

  String? get _uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _bindCurrentUserData();
    _authSub = _auth.authStateChanges().listen((_) {
      _bindCurrentUserData();
    });
  }

  Future<void> onSupport() async {
    final allowed = await ensureLoggedInForRestrictedAction(
      message: 'Please login to access Help & Support',
    );
    if (!allowed) return;
    Get.toNamed(
      AppRoutes.helpSupportRoute,
      arguments: <String, dynamic>{'role': 'customer'},
    );
  }

  void onPrivacyPolicy() {
    AppSnackbar.success('Privacy', 'Privacy policy screen will be added next.');
  }

  void onRateApp() {
    AppSnackbar.success('Rate App', 'Rate app flow will be added next.');
  }

  Future<void> onProfileImageTap() async {
    final allowed = await ensureLoggedInForRestrictedAction(
      message: 'Please login to update your profile photo',
    );
    if (!allowed) {
      return;
    }
    final selectedSource = await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF151233),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose image source',
                  style: TextStyle(color: Color(0xFFB7BDE6), fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.back(result: ImageSource.camera),
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Camera',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF394078)),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(result: ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4B176F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );

    if (selectedSource == null) {
      return;
    }
    await _pickAndUploadProfileImage(selectedSource);
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    if (isUploadingProfileImage.value) {
      return;
    }
    final uid = _uid;
    if (uid == null) {
      return;
    }

    try {
      isUploadingProfileImage.value = true;
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final storagePath =
          'customer_profiles/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _firebaseStorage.ref(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      await _db.collection(ServiceCatalogPaths.usersCollection).doc(uid).set(
        <String, dynamic>{
          'profileImageUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      profileImageUrl.value = downloadUrl;
      AppSnackbar.success('Updated', 'Profile photo updated successfully.');
    } catch (_) {
      AppSnackbar.error(
        'Upload Failed',
        'Unable to update profile photo right now.',
      );
    } finally {
      isUploadingProfileImage.value = false;
    }
  }

  Future<void> onLogout() async {
    try {
      await FcmNotificationService.instance.deactivateLastToken();
      await _auth.signOut();
      AuthController.instance.resetLocalAuthState(keepGuestMode: false);
      Get.offAllNamed(AppRoutes.loginRoute);
      AppSnackbar.success('Logout', 'You have been logged out successfully.');
    } catch (_) {
      AppSnackbar.error('Logout Failed', 'Unable to logout right now.');
    }
  }

  Future<bool> addAddress({
    required String title,
    required String address,
    required String state,
    required String city,
    required String pincode,
  }) async {
    if (!await ensureLoggedInForRestrictedAction()) {
      return false;
    }
    final uid = _uid;
    if (uid == null) {
      return false;
    }

    isAddressSaving.value = true;
    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerSavedAddressSubcollection)
          .add(<String, dynamic>{
            'title': title.trim(),
            'address': address.trim(),
            'state': state.trim(),
            'city': city.trim(),
            'pincode': pincode.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      AppSnackbar.success('Saved', 'Address added successfully.');
      return true;
    } catch (_) {
      AppSnackbar.error('Save Failed', 'Unable to add address.');
      return false;
    } finally {
      isAddressSaving.value = false;
    }
  }

  Future<bool> updateAddress({
    required String id,
    required String title,
    required String address,
    required String state,
    required String city,
    required String pincode,
  }) async {
    if (!await ensureLoggedInForRestrictedAction()) {
      return false;
    }
    final uid = _uid;
    if (uid == null) {
      return false;
    }

    isAddressSaving.value = true;
    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerSavedAddressSubcollection)
          .doc(id)
          .set(<String, dynamic>{
            'title': title.trim(),
            'address': address.trim(),
            'state': state.trim(),
            'city': city.trim(),
            'pincode': pincode.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      AppSnackbar.success('Updated', 'Address updated successfully.');
      return true;
    } catch (_) {
      AppSnackbar.error('Update Failed', 'Unable to update address.');
      return false;
    } finally {
      isAddressSaving.value = false;
    }
  }

  Future<void> removeAddress(String id) async {
    if (!await ensureLoggedInForRestrictedAction()) {
      return;
    }
    final uid = _uid;
    if (uid == null) {
      return;
    }

    isAddressSaving.value = true;
    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerSavedAddressSubcollection)
          .doc(id)
          .delete();
      AppSnackbar.success('Deleted', 'Address removed.');
    } catch (_) {
      AppSnackbar.error('Delete Failed', 'Unable to delete address.');
    } finally {
      isAddressSaving.value = false;
    }
  }

  Future<bool> updatePersonalInfo({
    required String name,
    required String landmark,
    required String address,
    required String state,
    required String city,
    required String pincode,
    String gstNumber = '',
    required double latitude,
    required double longitude,
    bool showSuccessMessage = true,
  }) async {
    if (!await ensureLoggedInForRestrictedAction(
      message: 'Please login to update personal information',
    )) {
      return false;
    }
    final uid = _uid;
    if (uid == null) {
      return false;
    }

    isSavingPersonalInfo.value = true;
    try {
      await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .set(<String, dynamic>{
            'fullName': name.trim(),
            'landmark': landmark.trim(),
            'address': address.trim(),
            'state': state.trim(),
            'city': city.trim(),
            'pincode': pincode.trim(),
            'gstin': gstNumber.trim().toUpperCase(),
            'gstNumber': gstNumber.trim().toUpperCase(),
            'latitude': latitude,
            'longitude': longitude,
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      fullName.value = name.trim();
      this.landmark.value = landmark.trim();
      this.address.value = address.trim();
      this.state.value = state.trim();
      this.city.value = city.trim();
      this.pincode.value = pincode.trim();
      this.gstNumber.value = gstNumber.trim().toUpperCase();
      this.latitude.value = latitude;
      this.longitude.value = longitude;
      location.value = _composeLocation(
        address: this.address.value,
        city: this.city.value,
        state: this.state.value,
      );
      isProfileCompleted.value = true;
      _storage.write(AuthController.customerProfileCompletedStorageKey, true);

      if (showSuccessMessage) {
        AppSnackbar.success('Saved', 'Personal information updated.');
      }
      return true;
    } catch (_) {
      AppSnackbar.error(
        'Update Failed',
        'Unable to update personal information right now.',
      );
      return false;
    } finally {
      isSavingPersonalInfo.value = false;
    }
  }

  Future<bool> ensureLoggedInForRestrictedAction({
    String message = 'Please login to continue',
  }) async {
    final guest = _storage.read(AuthController.guestUserStorageKey) == true;
    final loggedInUser = _auth.currentUser;
    if (!guest && loggedInUser != null) {
      return true;
    }

    isGuestUser.value = true;
    await AuthController.instance.showLoginRequiredSheet(message: message);
    return false;
  }

  Future<void> _bindCurrentUserData() async {
    await _profileSub?.cancel();
    await _addressSub?.cancel();
    await _invoiceSub?.cancel();

    final uid = _uid;
    final guestFlag = _storage.read(AuthController.guestUserStorageKey) == true;
    isGuestUser.value = guestFlag || uid == null;

    if (uid == null) {
      _applyGuestDefaults();
      savedAddresses.clear();
      invoices.clear();
      isProfileLoading.value = false;
      isAddressLoading.value = false;
      return;
    }

    isProfileLoading.value = true;
    isAddressLoading.value = true;

    _profileSub = _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data() ?? <String, dynamic>{};
            final rawFullName = (data['fullName'] as String? ?? '').trim();
            final nextName = rawFullName.isEmpty ? 'Customer' : rawFullName;
            final nextAddress = (data['address'] as String? ?? '').trim();
            final nextLandmark = (data['landmark'] as String? ?? '').trim();
            final nextState = (data['state'] as String? ?? '').trim();
            final nextCity = (data['city'] as String? ?? '').trim();
            final nextPincode = (data['pincode'] as String? ?? '').trim();
            final nextGstNumber =
                (data['gstin'] ?? data['gstNumber'] ?? '').toString().trim();
            final nextLatitude = (data['latitude'] as num?)?.toDouble();
            final nextLongitude = (data['longitude'] as num?)?.toDouble();
            final nextProfileImageUrl =
                (data['profileImageUrl'] as String? ?? '').trim();
            final nextPhone =
                (data['phoneNumber'] as String? ?? '').trim().isEmpty
                ? (_auth.currentUser?.phoneNumber ?? '')
                : (data['phoneNumber'] as String).trim();

            final createdAt = _toDateTime(data['createdAt']);
            fullName.value = nextName;
            phone.value = nextPhone.isEmpty ? '-' : nextPhone;
            address.value = nextAddress;
            landmark.value = nextLandmark;
            state.value = nextState;
            city.value = nextCity;
            pincode.value = nextPincode;
            gstNumber.value = nextGstNumber;
            latitude.value = nextLatitude;
            longitude.value = nextLongitude;
            profileImageUrl.value = nextProfileImageUrl;
            location.value = _composeLocation(
              address: nextAddress,
              city: nextCity,
              state: nextState,
            );
            memberSince.value = createdAt == null
                ? '-'
                : '${_monthLabel(createdAt.month)} ${createdAt.year}';

            final completedByFields = rawFullName.isNotEmpty;
            final completed =
                (data['profileCompleted'] as bool?) == true ||
                completedByFields;
            isProfileCompleted.value = completed;
            _storage.write(
              AuthController.customerProfileCompletedStorageKey,
              completed,
            );
            _storage.write(AuthController.guestUserStorageKey, false);
            isGuestUser.value = false;
            isProfileLoading.value = false;
          },
          onError: (_) {
            isProfileLoading.value = false;
          },
        );

    _addressSub = _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .collection(ServiceCatalogPaths.customerSavedAddressSubcollection)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map(CustomerAddressItem.fromDoc)
                .toList(growable: false);
            savedAddresses.assignAll(items);
            isAddressLoading.value = false;
          },
          onError: (_) {
            isAddressLoading.value = false;
          },
        );

    _invoiceSub = _db
        .collection(ServiceCatalogPaths.invoicesCollection)
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          final items =
              snapshot.docs
                  .map(CustomerInvoiceItem.fromDoc)
                  .toList(growable: true)
                ..sort((left, right) => right.date.compareTo(left.date));
          invoices.assignAll(items);
        });
  }

  void _applyGuestDefaults() {
    fullName.value = 'Guest User';
    profileImageUrl.value = '';
    phone.value = 'Login with phone to continue';
    address.value = '';
    landmark.value = '';
    state.value = '';
    city.value = '';
    pincode.value = '';
    latitude.value = null;
    longitude.value = null;
    location.value = 'Address not added';
    memberSince.value = '-';
    isProfileCompleted.value = false;
  }

  String _composeLocation({
    required String address,
    required String city,
    required String state,
  }) {
    final parts = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
    ];
    if (parts.isEmpty) {
      return 'Address not added';
    }
    return parts.join(', ');
  }

  DateTime? _toDateTime(dynamic value) {
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

  String _monthLabel(int month) {
    const labels = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return labels[(month - 1).clamp(0, 11)];
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _addressSub?.cancel();
    _invoiceSub?.cancel();
    super.onClose();
  }
}

DateTime? _toDateTimeValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  return null;
}

int _asIntValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _monthLabelStatic(int month) {
  const labels = <String>[
    '',
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
  if (month < 1 || month > 12) return '-';
  return labels[month];
}
