import 'package:cloud_firestore/cloud_firestore.dart';

class ClickNowNotification {
  const ClickNowNotification({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.body,
    required this.type,
    required this.source,
    required this.data,
    required this.imageUrl,
    required this.deepLinkRoute,
    required this.read,
    required this.createdAt,
    required this.readAt,
    required this.sentByAdminId,
    required this.campaignId,
  });

  final String id;
  final String recipientId;
  final String recipientRole;
  final String title;
  final String body;
  final String type;
  final String source;
  final Map<String, dynamic> data;
  final String imageUrl;
  final String deepLinkRoute;
  final bool read;
  final DateTime? createdAt;
  final DateTime? readAt;
  final String sentByAdminId;
  final String campaignId;

  factory ClickNowNotification.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ClickNowNotification(
      id: _string(data['notificationId']).isEmpty
          ? doc.id
          : _string(data['notificationId']),
      recipientId: _string(data['recipientId']),
      recipientRole: _string(data['recipientRole']),
      title: _string(data['title']),
      body: _string(data['body']),
      type: _string(data['type']),
      source: _string(data['source']),
      data: _asMap(data['data']),
      imageUrl: _string(data['imageUrl']),
      deepLinkRoute: _string(data['deepLinkRoute']),
      read: data['read'] == true,
      createdAt: _date(data['createdAt']),
      readAt: _date(data['readAt']),
      sentByAdminId: _string(data['sentByAdminId']),
      campaignId: _string(data['campaignId']),
    );
  }

  String get displayType {
    switch (type) {
      case 'admin_custom':
        return 'Announcement';
      case 'booking_created':
      case 'booking_approved':
      case 'new_booking_assigned':
      case 'professional_assigned':
      case 'professional_accepted':
      case 'booking_started':
      case 'booking_completed':
      case 'booking_reschedule_requested':
      case 'booking_reschedule_approved':
      case 'booking_reschedule_rejected':
        return 'Booking';
      case 'refund_approved':
      case 'refund_completed':
        return 'Refund';
      case 'payroll_released':
      case 'payout_confirmed':
        return 'Payroll';
      case 'document_reupload_requested':
        return 'Documents';
      case 'account_suspended':
      case 'account_blocked':
      case 'account_reactivated':
        return 'Account';
      default:
        return 'Notification';
    }
  }
}

class NotificationCampaign {
  const NotificationCampaign({
    required this.id,
    required this.title,
    required this.body,
    required this.recipientType,
    required this.totalRecipients,
    required this.totalTokens,
    required this.successCount,
    required this.failureCount,
    required this.status,
    required this.createdAt,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String body;
  final String recipientType;
  final int totalRecipients;
  final int totalTokens;
  final int successCount;
  final int failureCount;
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory NotificationCampaign.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return NotificationCampaign(
      id: _string(data['campaignId']).isEmpty
          ? doc.id
          : _string(data['campaignId']),
      title: _string(data['title']),
      body: _string(data['body']),
      recipientType: _string(data['recipientType']),
      totalRecipients: _int(data['totalRecipients']),
      totalTokens: _int(data['totalTokens']),
      successCount: _int(data['successCount']),
      failureCount: _int(data['failureCount']),
      status: _string(data['status']),
      createdAt: _date(data['createdAt']),
      completedAt: _date(data['completedAt']),
    );
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(_string(value)) ?? 0;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}
