import 'dart:async';

import 'package:clicknow_version2/app/screens/admin/customers/models/admin_customer.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/services/admin_user_management_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

enum AdminCustomerAction {
  suspend,
  reactivate,
  block,
  unblock,
  markVerified,
  removeVerified,
}

class AdminCustomersController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminUserManagementService _accountService =
      AdminUserManagementService.instance;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString searchQuery = ''.obs;
  final RxList<AdminCustomer> allCustomers = <AdminCustomer>[].obs;
  final RxList<AdminCustomer> filteredCustomers = <AdminCustomer>[].obs;
  final RxMap<String, bool> actionLoadingByKey = <String, bool>{}.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customerSub;

  @override
  void onInit() {
    super.onInit();
    _listenCustomers();
  }

  int get totalCustomers => allCustomers.length;

  int get completedProfilesCount =>
      allCustomers.where((customer) => customer.profileCompleted).length;

  int get pendingProfilesCount => totalCustomers - completedProfilesCount;

  void updateSearch(String value) {
    searchQuery.value = value.trim().toLowerCase();
    _applyFilters();
  }

  bool isActionLoading(String uid, AdminCustomerAction action) =>
      actionLoadingByKey['$uid|${action.name}'] == true;

  Future<bool> manageCustomer({
    required AdminCustomer customer,
    required AdminCustomerAction action,
    String reason = '',
  }) async {
    if (_auth.currentUser == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }
    final key = '${customer.uid}|${action.name}';
    final config = _customerActionConfig(action);
    actionLoadingByKey[key] = true;
    try {
      await _accountService.performAction(
        targetUserId: customer.uid,
        targetUserRole: 'customer',
        action: config.backendAction,
        reason: reason,
      );
      AppSnackbar.success(config.successTitle, config.successMessage);
      return true;
    } catch (error) {
      AppSnackbar.error(
        'Action Failed',
        error is StateError ? error.message : config.errorMessage,
      );
      return false;
    } finally {
      actionLoadingByKey.remove(key);
    }
  }

  _CustomerActionConfig _customerActionConfig(AdminCustomerAction action) {
    switch (action) {
      case AdminCustomerAction.suspend:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.suspendCustomer,
          successTitle: 'Customer Suspended',
          successMessage: 'The customer cannot create new bookings.',
          errorMessage: 'Could not suspend this customer.',
        );
      case AdminCustomerAction.reactivate:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.reactivateCustomer,
          successTitle: 'Customer Reactivated',
          successMessage: 'The customer account is active again.',
          errorMessage: 'Could not reactivate this customer.',
        );
      case AdminCustomerAction.block:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.blockCustomer,
          successTitle: 'Customer Blocked',
          successMessage: 'The customer account has been blocked.',
          errorMessage: 'Could not block this customer.',
        );
      case AdminCustomerAction.unblock:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.unblockCustomer,
          successTitle: 'Customer Unblocked',
          successMessage: 'The customer account is active again.',
          errorMessage: 'Could not unblock this customer.',
        );
      case AdminCustomerAction.markVerified:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.markCustomerVerified,
          successTitle: 'Customer Verified',
          successMessage: 'The verified customer badge is now active.',
          errorMessage: 'Could not verify this customer.',
        );
      case AdminCustomerAction.removeVerified:
        return const _CustomerActionConfig(
          backendAction: AdminUserAction.removeCustomerVerified,
          successTitle: 'Verification Removed',
          successMessage: 'The verified customer badge was removed.',
          errorMessage: 'Could not remove customer verification.',
        );
    }
  }

  Future<void> refreshCustomers({bool showMessage = false}) async {
    isRefreshing.value = true;
    try {
      final snapshot = await _db
          .collection(ServiceCatalogPaths.usersCollection)
          .get();
      _consumeSnapshot(snapshot.docs);
      if (showMessage) {
        AppSnackbar.success('Refreshed', 'Customers list refreshed.');
      }
    } catch (_) {
      if (showMessage) {
        AppSnackbar.error('Refresh Failed', 'Unable to refresh customers.');
      }
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  Future<void> _listenCustomers() async {
    await refreshCustomers();
    _customerSub = _db
        .collection(ServiceCatalogPaths.usersCollection)
        .snapshots()
        .listen(
          (snapshot) {
            _consumeSnapshot(snapshot.docs);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to fetch customers from server.',
            );
          },
        );
  }

  void _consumeSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final parsed = docs
        .where(_isCustomerDoc)
        .map(AdminCustomer.fromDoc)
        .toList(growable: false)
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    allCustomers.assignAll(parsed);
    _applyFilters();
  }

  bool _isCustomerDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    final rbacRole = (data['rbacRole'] ?? '').toString().trim().toLowerCase();
    final userRole = (data['userRole'] ?? '').toString().trim().toLowerCase();
    return role == 'customer' ||
        rbacRole == 'customer' ||
        userRole == 'customer';
  }

  void _applyFilters() {
    final query = searchQuery.value;
    if (query.isEmpty) {
      filteredCustomers.assignAll(allCustomers);
      return;
    }
    filteredCustomers.assignAll(
      allCustomers.where((customer) => customer.searchableText.contains(query)),
    );
  }

  @override
  void onClose() {
    _customerSub?.cancel();
    super.onClose();
  }
}

class _CustomerActionConfig {
  const _CustomerActionConfig({
    required this.backendAction,
    required this.successTitle,
    required this.successMessage,
    required this.errorMessage,
  });

  final String backendAction;
  final String successTitle;
  final String successMessage;
  final String errorMessage;
}
