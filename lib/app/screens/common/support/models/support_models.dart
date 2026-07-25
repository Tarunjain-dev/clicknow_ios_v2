import 'package:cloud_firestore/cloud_firestore.dart';

class SupportValues {
  SupportValues._();

  static const statuses = <String>[
    'OPEN',
    'IN_PROGRESS',
    'WAITING_FOR_USER',
    'WAITING_FOR_ADMIN',
    'RESOLVED',
    'CLOSED',
    'REOPENED',
  ];
  static const priorities = <String>['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
  static const customerCategories = <String>[
    'BOOKING_ISSUE',
    'PAYMENT_ISSUE',
    'REFUND_ISSUE',
    'SERVICE_QUALITY',
    'PROFESSIONAL_NOT_ARRIVED',
    'INVOICE_ISSUE',
    'TECHNICAL_ISSUE',
    'OTHER',
  ];
  static const professionalCategories = <String>[
    'BOOKING_ASSIGNMENT',
    'PAYROLL_ISSUE',
    'CUSTOMER_NOT_AVAILABLE',
    'OTP_START_ISSUE',
    'DOCUMENT_APPROVAL',
    'PAYMENT_OR_PAYOUT_ISSUE',
    'TECHNICAL_ISSUE',
    'OTHER',
  ];

  static String priorityFor(String category) {
    switch (category) {
      case 'PROFESSIONAL_NOT_ARRIVED':
        return 'URGENT';
      case 'PAYMENT_ISSUE':
      case 'REFUND_ISSUE':
      case 'PAYROLL_ISSUE':
      case 'CUSTOMER_NOT_AVAILABLE':
      case 'OTP_START_ISSUE':
      case 'PAYMENT_OR_PAYOUT_ISSUE':
        return 'HIGH';
      case 'OTHER':
        return 'LOW';
      default:
        return 'MEDIUM';
    }
  }

  static String label(String value) {
    if (value.isEmpty) return '-';
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word.substring(0, 1)}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class SupportTicketModel {
  const SupportTicketModel({
    required this.ticketId,
    required this.raisedByUserId,
    required this.raisedByRole,
    required this.raisedByName,
    required this.raisedByPhone,
    required this.raisedByEmail,
    required this.assignedAdminId,
    required this.assignedAdminName,
    required this.category,
    required this.subject,
    required this.description,
    required this.relatedBookingId,
    required this.relatedPaymentId,
    required this.relatedRefundId,
    required this.relatedPayrollId,
    required this.status,
    required this.priority,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.userUnreadCount,
    required this.adminUnreadCount,
    required this.initialAttachmentUrl,
    required this.initialAttachmentPath,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
    required this.closedAt,
    required this.reopenedAt,
  });

  final String ticketId;
  final String raisedByUserId;
  final String raisedByRole;
  final String raisedByName;
  final String raisedByPhone;
  final String? raisedByEmail;
  final String? assignedAdminId;
  final String? assignedAdminName;
  final String category;
  final String subject;
  final String description;
  final String? relatedBookingId;
  final String? relatedPaymentId;
  final String? relatedRefundId;
  final String? relatedPayrollId;
  final String status;
  final String priority;
  final String? lastMessage;
  final String? lastMessageType;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final int userUnreadCount;
  final int adminUnreadCount;
  final String? initialAttachmentUrl;
  final String? initialAttachmentPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? reopenedAt;

  factory SupportTicketModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return SupportTicketModel.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory SupportTicketModel.fromMap(
    Map<String, dynamic> map, {
    String id = '',
  }) {
    final now = DateTime.now();
    return SupportTicketModel(
      ticketId: _text(map['ticketId']).isEmpty ? id : _text(map['ticketId']),
      raisedByUserId: _text(map['raisedByUserId']),
      raisedByRole: _text(map['raisedByRole']),
      raisedByName: _text(map['raisedByName']),
      raisedByPhone: _text(map['raisedByPhone']),
      raisedByEmail: _nullableText(map['raisedByEmail']),
      assignedAdminId: _nullableText(map['assignedAdminId']),
      assignedAdminName: _nullableText(map['assignedAdminName']),
      category: _text(map['category']),
      subject: _text(map['subject']),
      description: _text(map['description']),
      relatedBookingId: _nullableText(map['relatedBookingId']),
      relatedPaymentId: _nullableText(map['relatedPaymentId']),
      relatedRefundId: _nullableText(map['relatedRefundId']),
      relatedPayrollId: _nullableText(map['relatedPayrollId']),
      status: _text(map['status']).isEmpty ? 'OPEN' : _text(map['status']),
      priority: _text(map['priority']).isEmpty
          ? 'MEDIUM'
          : _text(map['priority']),
      lastMessage: _nullableText(map['lastMessage']),
      lastMessageType: _nullableText(map['lastMessageType']),
      lastMessageSenderId: _nullableText(map['lastMessageSenderId']),
      lastMessageAt: _date(map['lastMessageAt']),
      userUnreadCount: _integer(map['userUnreadCount']),
      adminUnreadCount: _integer(map['adminUnreadCount']),
      initialAttachmentUrl: _nullableText(map['initialAttachmentUrl']),
      initialAttachmentPath: _nullableText(map['initialAttachmentPath']),
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
      resolvedAt: _date(map['resolvedAt']),
      closedAt: _date(map['closedAt']),
      reopenedAt: _date(map['reopenedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'ticketId': ticketId,
    'raisedByUserId': raisedByUserId,
    'raisedByRole': raisedByRole,
    'raisedByName': raisedByName,
    'raisedByPhone': raisedByPhone,
    'raisedByEmail': raisedByEmail,
    'assignedAdminId': assignedAdminId,
    'assignedAdminName': assignedAdminName,
    'category': category,
    'subject': subject,
    'description': description,
    'relatedBookingId': relatedBookingId,
    'relatedPaymentId': relatedPaymentId,
    'relatedRefundId': relatedRefundId,
    'relatedPayrollId': relatedPayrollId,
    'status': status,
    'priority': priority,
    'lastMessage': lastMessage,
    'lastMessageType': lastMessageType,
    'lastMessageSenderId': lastMessageSenderId,
    'lastMessageAt': lastMessageAt,
    'userUnreadCount': userUnreadCount,
    'adminUnreadCount': adminUnreadCount,
    'initialAttachmentUrl': initialAttachmentUrl,
    'initialAttachmentPath': initialAttachmentPath,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'resolvedAt': resolvedAt,
    'closedAt': closedAt,
    'reopenedAt': reopenedAt,
  };
}

class SupportMessageModel {
  const SupportMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.messageType,
    required this.text,
    required this.imageUrl,
    required this.imagePath,
    required this.isReadByUser,
    required this.isReadByAdmin,
    required this.createdAt,
  });

  final String messageId;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String messageType;
  final String? text;
  final String? imageUrl;
  final String? imagePath;
  final bool isReadByUser;
  final bool isReadByAdmin;
  final DateTime createdAt;

  factory SupportMessageModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    return SupportMessageModel(
      messageId: _text(map['messageId']).isEmpty
          ? doc.id
          : _text(map['messageId']),
      senderId: _text(map['senderId']),
      senderRole: _text(map['senderRole']),
      senderName: _text(map['senderName']),
      messageType: _text(map['messageType']).isEmpty
          ? 'text'
          : _text(map['messageType']),
      text: _nullableText(map['text']),
      imageUrl: _nullableText(map['imageUrl']),
      imagePath: _nullableText(map['imagePath']),
      isReadByUser: map['isReadByUser'] == true,
      isReadByAdmin: map['isReadByAdmin'] == true,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';
String? _nullableText(dynamic value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int _integer(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(_text(value)) ?? 0;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(_text(value));
}
