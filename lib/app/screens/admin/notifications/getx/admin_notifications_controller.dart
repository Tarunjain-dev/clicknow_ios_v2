import 'package:clicknow_version2/app/services/notifications/admin_notification_service.dart';
import 'package:clicknow_version2/app/services/notifications/notification_model.dart';
import 'package:clicknow_version2/app/services/notifications/notification_repository.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminNotificationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AdminNotificationService _service = AdminNotificationService.instance;
  final NotificationRepository _repo = NotificationRepository.instance;

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final imageUrlController = TextEditingController();
  final deepLinkController = TextEditingController();
  final selectedUserIdsController = TextEditingController();

  final RxString recipientType = 'all_customers'.obs;
  final RxBool isSending = false.obs;

  Stream<List<NotificationCampaign>> watchCampaigns() => _repo.watchCampaigns();

  Stream<List<AdminNotificationUserOption>> watchUserOptions() {
    return _db
        .collection(ServiceCatalogPaths.usersCollection)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final options = snapshot.docs
          .map((doc) => AdminNotificationUserOption.fromDoc(doc.id, doc.data()))
          .where((option) => option.displayName.isNotEmpty)
          .toList(growable: false);
      options.sort((left, right) => left.displayName.compareTo(right.displayName));
      return options;
    });
  }

  Future<void> send() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      AppSnackbar.error('Missing Details', 'Please enter title and message.');
      return;
    }
    final selectedIds = selectedUserIdsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (recipientType.value == 'selected_users' && selectedIds.isEmpty) {
      AppSnackbar.error('Select Users', 'Enter at least one user ID.');
      return;
    }

    isSending.value = true;
    try {
      final result = await _service.sendCustomNotification(
        title: title,
        body: body,
        recipientType: recipientType.value,
        selectedUserIds: selectedIds,
        imageUrl: imageUrlController.text.trim(),
        deepLinkRoute: deepLinkController.text.trim(),
        data: <String, dynamic>{
          'type': 'admin_custom',
          'source': 'admin',
        },
      );
      AppSnackbar.success(
        'Notification Sent',
        'Delivered to ${result.successCount}/${result.totalTokens} device tokens.',
      );
      if (result.successCount > 0 || result.totalRecipients > 0) {
        titleController.clear();
        bodyController.clear();
        imageUrlController.clear();
        deepLinkController.clear();
        selectedUserIdsController.clear();
      }
    } catch (error) {
      AppSnackbar.error('Send Failed', error.toString());
    } finally {
      isSending.value = false;
    }
  }

  void toggleSelectedUser(String uid) {
    final current = selectedUserIdsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (!current.add(uid)) {
      current.remove(uid);
    }
    selectedUserIdsController.text = current.join(', ');
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    imageUrlController.dispose();
    deepLinkController.dispose();
    selectedUserIdsController.dispose();
    super.onClose();
  }
}

class AdminNotificationUserOption {
  const AdminNotificationUserOption({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.phone,
  });

  final String uid;
  final String displayName;
  final String role;
  final String phone;

  factory AdminNotificationUserOption.fromDoc(
    String uid,
    Map<String, dynamic> data,
  ) {
    final role = _first(<dynamic>[
      data['rbacRole'],
      data['role'],
      data['userRole'],
    ]);
    final name = _first(<dynamic>[
      data['fullName'],
      data['name'],
      data['displayName'],
      data['customerName'],
    ]);
    final phone = _first(<dynamic>[
      data['phoneNumber'],
      data['phone'],
      data['mobile'],
    ]);
    return AdminNotificationUserOption(
      uid: uid,
      displayName: name.isEmpty ? uid : name,
      role: role.isEmpty ? 'user' : role,
      phone: phone,
    );
  }

  static String _first(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
