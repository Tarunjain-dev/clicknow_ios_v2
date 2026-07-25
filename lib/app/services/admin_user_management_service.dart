import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class AdminUserAction {
  AdminUserAction._();

  static const suspendProfessional = 'SUSPEND_PROFESSIONAL';
  static const reactivateProfessional = 'REACTIVATE_PROFESSIONAL';
  static const blockProfessional = 'BLOCK_PROFESSIONAL';
  static const unblockProfessional = 'UNBLOCK_PROFESSIONAL';
  static const markFeatured = 'MARK_FEATURED';
  static const removeFeatured = 'REMOVE_FEATURED';
  static const verifyDocuments = 'VERIFY_DOCUMENTS';
  static const requestBankUpdate = 'REQUEST_BANK_UPDATE';

  static const suspendCustomer = 'SUSPEND_CUSTOMER';
  static const reactivateCustomer = 'REACTIVATE_CUSTOMER';
  static const blockCustomer = 'BLOCK_CUSTOMER';
  static const unblockCustomer = 'UNBLOCK_CUSTOMER';
  static const markCustomerVerified = 'MARK_CUSTOMER_VERIFIED';
  static const removeCustomerVerified = 'REMOVE_CUSTOMER_VERIFIED';
}

class AdminUserManagementService {
  AdminUserManagementService._();

  static final instance = AdminUserManagementService._();

  Future<void> performAction({
    required String targetUserId,
    required String targetUserRole,
    required String action,
    String reason = '',
    List<String> requestedDocuments = const <String>[],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please login as admin again.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify the admin session.');
    }
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw StateError('Firebase project id is missing.');
    }

    final response = await http.post(
      Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/adminManageUserAccount',
      ),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{
          'targetUserId': targetUserId.trim(),
          'targetUserRole': targetUserRole.trim().toLowerCase(),
          'action': action.trim().toUpperCase(),
          'reason': reason.trim(),
          'requestedDocuments': requestedDocuments,
        },
      }),
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = Map<String, dynamic>.from(
        (decoded['error'] as Map?) ?? const <String, dynamic>{},
      );
      throw StateError(
        _string(error['message']).isEmpty
            ? 'The admin action could not be completed.'
            : _string(error['message']),
      );
    }
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';
