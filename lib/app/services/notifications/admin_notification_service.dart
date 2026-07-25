import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class AdminNotificationSendResult {
  const AdminNotificationSendResult({
    required this.campaignId,
    required this.totalRecipients,
    required this.totalTokens,
    required this.successCount,
    required this.failureCount,
  });

  final String campaignId;
  final int totalRecipients;
  final int totalTokens;
  final int successCount;
  final int failureCount;

  factory AdminNotificationSendResult.fromMap(Map<String, dynamic> data) {
    return AdminNotificationSendResult(
      campaignId: _string(data['campaignId']),
      totalRecipients: _int(data['totalRecipients']),
      totalTokens: _int(data['totalTokens']),
      successCount: _int(data['successCount']),
      failureCount: _int(data['failureCount']),
    );
  }
}

class AdminNotificationService {
  AdminNotificationService._();

  static final AdminNotificationService instance = AdminNotificationService._();

  Future<AdminNotificationSendResult> sendCustomNotification({
    required String title,
    required String body,
    required String recipientType,
    required List<String> selectedUserIds,
    String imageUrl = '',
    String deepLinkRoute = '',
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    final result = await _callFunction(
      'sendAdminCustomNotification',
      <String, dynamic>{
        'title': title.trim(),
        'body': body.trim(),
        'recipientType': recipientType.trim(),
        'selectedUserIds': selectedUserIds,
        'imageUrl': imageUrl.trim(),
        'deepLinkRoute': deepLinkRoute.trim(),
        'data': data,
      },
    );
    return AdminNotificationSendResult.fromMap(result);
  }

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please login as admin again.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify admin session.');
    }
    final projectId = Firebase.app().options.projectId;
    final response = await http.post(
      Uri.parse('https://us-central1-$projectId.cloudfunctions.net/$functionName'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'data': payload}),
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
            ? 'Unable to send notification.'
            : _string(error['message']),
      );
    }
    return Map<String, dynamic>.from(
      (decoded['result'] as Map?) ?? const <String, dynamic>{},
    );
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(_string(value)) ?? 0;
}
