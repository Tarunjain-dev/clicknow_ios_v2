import 'dart:io';

import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SupportActor {
  const SupportActor({
    required this.userId,
    required this.role,
    required this.name,
    required this.phone,
    required this.email,
  });

  final String userId;
  final String role;
  final String name;
  final String phone;
  final String? email;
}

class SupportService {
  SupportService._();

  static final SupportService instance = SupportService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _tickets =>
      _db.collection(ServiceCatalogPaths.supportTicketsCollection);

  Future<SupportActor> currentActor({String? preferredRole}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please login to use support.');

    final userDoc = await _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? const <String, dynamic>{};
    final profileDoc = await _db
        .collection('professional_profiles')
        .doc(user.uid)
        .get();
    final profileData = profileDoc.data() ?? const <String, dynamic>{};
    final professional = _map(profileData['professional']);
    final storedRole = _string(
      userData['rbacRole'] ?? userData['userRole'] ?? userData['role'],
    ).toLowerCase();
    // Never grant admin support privileges from mutable local storage.
    final isAdmin = storedRole == 'admin';
    final role = isAdmin
        ? 'admin'
        : storedRole.contains('professional') || profileDoc.exists
        ? 'professional'
        : 'customer';
    final name = _first(<dynamic>[
      userData['fullName'],
      userData['name'],
      professional['fullName'],
      profileData['fullName'],
      user.displayName,
    ], fallback: role == 'admin' ? 'ClickNow Admin' : 'ClickNow User');
    final phone = _first(<dynamic>[
      userData['phoneNumber'],
      userData['phone'],
      professional['phoneNumber'],
      profileData['phoneNumber'],
      user.phoneNumber,
    ]);
    final email = _first(<dynamic>[
      userData['email'],
      professional['email'],
      profileData['email'],
      user.email,
    ]);
    return SupportActor(
      userId: user.uid,
      role: role,
      name: name,
      phone: phone,
      email: email.isEmpty ? null : email,
    );
  }

  Stream<List<SupportTicketModel>> streamMyTickets(String userId) {
    return _tickets.where('raisedByUserId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map(SupportTicketModel.fromDoc)
          .toList(growable: false);
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Stream<List<SupportTicketModel>> streamAllTicketsForAdmin() {
    return _tickets.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(SupportTicketModel.fromDoc)
          .toList(growable: false);
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Stream<SupportTicketModel?> streamTicket(String ticketId) {
    return _tickets
        .doc(ticketId)
        .snapshots()
        .map((doc) => doc.exists ? SupportTicketModel.fromDoc(doc) : null);
  }

  Stream<List<SupportMessageModel>> streamMessages(String ticketId) {
    return _tickets
        .doc(ticketId)
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SupportMessageModel.fromDoc)
              .toList(growable: false),
        );
  }

  Future<String> createTicket({
    required SupportActor actor,
    required String category,
    required String subject,
    required String description,
    String? relatedBookingId,
    String? relatedPaymentId,
    String? relatedRefundId,
    String? relatedPayrollId,
    File? initialAttachment,
  }) async {
    _assertUserActor(actor);
    final safeCategory = category.trim().toUpperCase();
    final safeSubject = subject.trim();
    final safeDescription = description.trim();
    if (safeCategory.isEmpty) throw StateError('Please select a category.');
    if (safeSubject.length < 5) {
      throw StateError('Subject must contain at least 5 characters.');
    }
    if (safeDescription.length < 15) {
      throw StateError('Description must contain at least 15 characters.');
    }

    final ticketRef = _tickets.doc();
    String? attachmentUrl;
    String? attachmentPath;
    if (initialAttachment != null) {
      final uploaded = await _uploadImage(
        initialAttachment,
        'support_tickets/${ticketRef.id}/attachments/initial_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      attachmentUrl = uploaded.$1;
      attachmentPath = uploaded.$2;
    }
    final systemRef = ticketRef
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .doc();
    final userMessageRef = ticketRef
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .doc();
    final auditRef = _db
        .collection(ServiceCatalogPaths.supportAuditLogsCollection)
        .doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.set(ticketRef, <String, dynamic>{
      'ticketId': ticketRef.id,
      'raisedByUserId': actor.userId,
      'raisedByRole': actor.role,
      'raisedByName': actor.name,
      'raisedByPhone': actor.phone,
      'raisedByEmail': actor.email,
      'assignedAdminId': null,
      'assignedAdminName': null,
      'category': safeCategory,
      'subject': safeSubject,
      'description': safeDescription,
      'relatedBookingId': _nullable(relatedBookingId),
      'relatedPaymentId': _nullable(relatedPaymentId),
      'relatedRefundId': _nullable(relatedRefundId),
      'relatedPayrollId': _nullable(relatedPayrollId),
      'status': 'OPEN',
      'priority': SupportValues.priorityFor(safeCategory),
      'lastMessage': safeDescription,
      'lastMessageType': 'text',
      'lastMessageSenderId': actor.userId,
      'lastMessageAt': now,
      'userUnreadCount': 0,
      'adminUnreadCount': 1,
      'initialAttachmentUrl': attachmentUrl,
      'initialAttachmentPath': attachmentPath,
      'createdAt': now,
      'updatedAt': now,
      'resolvedAt': null,
      'closedAt': null,
      'reopenedAt': null,
    });
    batch.set(
      systemRef,
      _message(
        ref: systemRef,
        actor: const SupportActor(
          userId: 'system',
          role: 'admin',
          name: 'ClickNow Support',
          phone: '',
          email: null,
        ),
        type: 'system',
        text: 'Ticket created. Our support team will assist you shortly.',
        now: now,
      ),
    );
    batch.set(
      userMessageRef,
      _message(
        ref: userMessageRef,
        actor: actor,
        type: 'text',
        text: safeDescription,
        now: now,
      ),
    );
    batch.set(
      auditRef,
      _audit(
        ref: auditRef,
        ticketId: ticketRef.id,
        action: 'TICKET_CREATED',
        actor: actor,
        newValue: 'OPEN',
        now: now,
      ),
    );
    await batch.commit();
    return ticketRef.id;
  }

  Future<void> sendTextMessage({
    required String ticketId,
    required SupportActor actor,
    required String text,
  }) async {
    final safeText = text.trim();
    if (safeText.isEmpty) throw StateError('Message cannot be empty.');
    await _sendMessage(
      ticketId: ticketId,
      actor: actor,
      type: 'text',
      text: safeText,
    );
  }

  Future<void> sendImageMessage({
    required String ticketId,
    required SupportActor actor,
    required File imageFile,
  }) async {
    await _assertTicketAccess(ticketId, actor);
    final messageId = _tickets
        .doc(ticketId)
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .doc()
        .id;
    final uploaded = await _uploadImage(
      imageFile,
      'support_tickets/$ticketId/chat_images/$messageId.jpg',
    );
    await _sendMessage(
      ticketId: ticketId,
      actor: actor,
      type: 'image',
      text: 'Photo',
      imageUrl: uploaded.$1,
      imagePath: uploaded.$2,
      messageId: messageId,
    );
  }

  Future<void> _sendMessage({
    required String ticketId,
    required SupportActor actor,
    required String type,
    required String text,
    String? imageUrl,
    String? imagePath,
    String? messageId,
  }) async {
    await _assertTicketAccess(ticketId, actor);
    final ticketRef = _tickets.doc(ticketId);
    final messageRef = ticketRef
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .doc(messageId);
    final auditRef = _db
        .collection(ServiceCatalogPaths.supportAuditLogsCollection)
        .doc();
    await _db.runTransaction((transaction) async {
      final ticket = await transaction.get(ticketRef);
      final data = ticket.data();
      if (data == null) throw StateError('Support ticket not found.');
      if (_string(data['status']).toUpperCase() == 'CLOSED') {
        throw StateError(
          'Closed tickets cannot receive messages. Reopen it first.',
        );
      }
      final isAdmin = actor.role == 'admin';
      final now = FieldValue.serverTimestamp();
      transaction.set(
        messageRef,
        _message(
          ref: messageRef,
          actor: actor,
          type: type,
          text: type == 'image' ? null : text,
          imageUrl: imageUrl,
          imagePath: imagePath,
          now: now,
        ),
      );
      transaction.update(ticketRef, <String, dynamic>{
        'status': isAdmin ? 'WAITING_FOR_USER' : 'WAITING_FOR_ADMIN',
        'lastMessage': text,
        'lastMessageType': type,
        'lastMessageSenderId': actor.userId,
        'lastMessageAt': now,
        'updatedAt': now,
        if (isAdmin) 'userUnreadCount': FieldValue.increment(1),
        if (!isAdmin) 'adminUnreadCount': FieldValue.increment(1),
      });
      transaction.set(
        auditRef,
        _audit(
          ref: auditRef,
          ticketId: ticketId,
          action: type == 'image' ? 'IMAGE_MESSAGE_SENT' : 'MESSAGE_SENT',
          actor: actor,
          now: now,
        ),
      );
    });
  }

  Future<void> markMessagesRead({
    required String ticketId,
    required SupportActor actor,
  }) async {
    await _assertTicketAccess(ticketId, actor);
    final ticketRef = _tickets.doc(ticketId);
    final field = actor.role == 'admin'
        ? 'adminUnreadCount'
        : 'userUnreadCount';
    await ticketRef.update(<String, dynamic>{field: 0});
    final snapshot = await ticketRef
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .where(
          actor.role == 'admin' ? 'isReadByAdmin' : 'isReadByUser',
          isEqualTo: false,
        )
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, <String, dynamic>{
        actor.role == 'admin' ? 'isReadByAdmin' : 'isReadByUser': true,
      });
    }
    await batch.commit();
  }

  Future<void> updateStatus({
    required String ticketId,
    required String status,
    required SupportActor actor,
  }) async {
    final next = status.trim().toUpperCase();
    if (!SupportValues.statuses.contains(next)) {
      throw StateError('Invalid ticket status.');
    }
    await _changeTicketValue(
      ticketId: ticketId,
      actor: actor,
      field: 'status',
      value: next,
      action: next == 'RESOLVED'
          ? 'TICKET_RESOLVED'
          : next == 'CLOSED'
          ? 'TICKET_CLOSED'
          : next == 'REOPENED'
          ? 'TICKET_REOPENED'
          : 'STATUS_CHANGED',
      adminOnly: !const <String>['REOPENED'].contains(next),
    );
  }

  Future<void> updatePriority({
    required String ticketId,
    required String priority,
    required SupportActor actor,
  }) async {
    final next = priority.trim().toUpperCase();
    if (!SupportValues.priorities.contains(next)) {
      throw StateError('Invalid ticket priority.');
    }
    await _changeTicketValue(
      ticketId: ticketId,
      actor: actor,
      field: 'priority',
      value: next,
      action: 'PRIORITY_CHANGED',
      adminOnly: true,
    );
  }

  Future<void> assignToAdmin({
    required String ticketId,
    required SupportActor adminActor,
  }) async {
    if (adminActor.role != 'admin') throw StateError('Admin access required.');
    await _assertTicketAccess(ticketId, adminActor);
    final ticketRef = _tickets.doc(ticketId);
    final auditRef = _db
        .collection(ServiceCatalogPaths.supportAuditLogsCollection)
        .doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.update(ticketRef, <String, dynamic>{
      'assignedAdminId': adminActor.userId,
      'assignedAdminName': adminActor.name,
      'status': 'IN_PROGRESS',
      'updatedAt': now,
    });
    batch.set(
      auditRef,
      _audit(
        ref: auditRef,
        ticketId: ticketId,
        action: 'ADMIN_ASSIGNED',
        actor: adminActor,
        newValue: adminActor.name,
        now: now,
      ),
    );
    await batch.commit();
  }

  Future<void> _changeTicketValue({
    required String ticketId,
    required SupportActor actor,
    required String field,
    required String value,
    required String action,
    required bool adminOnly,
  }) async {
    await _assertTicketAccess(ticketId, actor);
    if (adminOnly && actor.role != 'admin') {
      throw StateError('Admin access required.');
    }
    final ticketRef = _tickets.doc(ticketId);
    final systemRef = ticketRef
        .collection(ServiceCatalogPaths.supportMessagesSubcollection)
        .doc();
    final auditRef = _db
        .collection(ServiceCatalogPaths.supportAuditLogsCollection)
        .doc();
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ticketRef);
      final data = snapshot.data();
      if (data == null) throw StateError('Support ticket not found.');
      final oldValue = _string(data[field]);
      if (field == 'status' &&
          value == 'REOPENED' &&
          !const <String>['RESOLVED', 'CLOSED'].contains(oldValue)) {
        throw StateError('Only resolved or closed tickets can be reopened.');
      }
      final now = FieldValue.serverTimestamp();
      final patch = <String, dynamic>{
        field: value,
        'updatedAt': now,
        if (value == 'RESOLVED') 'resolvedAt': now,
        if (value == 'CLOSED') 'closedAt': now,
        if (value == 'REOPENED') 'reopenedAt': now,
      };
      transaction.update(ticketRef, patch);
      transaction.set(
        systemRef,
        _message(
          ref: systemRef,
          actor: actor,
          type: 'system',
          text:
              '${SupportValues.label(field)} changed to ${SupportValues.label(value)}.',
          now: now,
        ),
      );
      transaction.set(
        auditRef,
        _audit(
          ref: auditRef,
          ticketId: ticketId,
          action: action,
          actor: actor,
          oldValue: oldValue,
          newValue: value,
          now: now,
        ),
      );
    });
  }

  Future<void> _assertTicketAccess(String ticketId, SupportActor actor) async {
    final doc = await _tickets.doc(ticketId).get();
    final data = doc.data();
    if (data == null) throw StateError('Support ticket not found.');
    if (actor.role != 'admin' &&
        _string(data['raisedByUserId']) != actor.userId) {
      throw StateError('You cannot access this support ticket.');
    }
  }

  void _assertUserActor(SupportActor actor) {
    if (!const <String>['customer', 'professional'].contains(actor.role)) {
      throw StateError('Only customers and professionals can raise tickets.');
    }
    if (_auth.currentUser?.uid != actor.userId) {
      throw StateError('Invalid support user.');
    }
  }

  Future<(String, String)> _uploadImage(File file, String path) async {
    final extension = file.path.split('.').last.toLowerCase();
    if (!const <String>['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw StateError('Only JPG, PNG, and WEBP images are supported.');
    }
    final length = await file.length();
    if (length > 8 * 1024 * 1024) {
      throw StateError('Support images must be smaller than 8 MB.');
    }
    final ref = _storage.ref(path);
    final contentType =
        const <String, String>{'jpg': 'image/jpeg', 'jpeg': 'image/jpeg'}[extension] ??
            'image/$extension';
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return (await ref.getDownloadURL(), path);
  }

  Map<String, dynamic> _message({
    required DocumentReference<Map<String, dynamic>> ref,
    required SupportActor actor,
    required String type,
    required dynamic now,
    String? text,
    String? imageUrl,
    String? imagePath,
  }) {
    return <String, dynamic>{
      'messageId': ref.id,
      'senderId': actor.userId,
      'senderRole': actor.role,
      'senderName': actor.name,
      'messageType': type,
      'text': text,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'isReadByUser': actor.role != 'admin',
      'isReadByAdmin': actor.role == 'admin',
      'createdAt': now,
    };
  }

  Map<String, dynamic> _audit({
    required DocumentReference<Map<String, dynamic>> ref,
    required String ticketId,
    required String action,
    required SupportActor actor,
    required dynamic now,
    String? oldValue,
    String? newValue,
  }) {
    return <String, dynamic>{
      'logId': ref.id,
      'ticketId': ticketId,
      'action': action,
      'oldValue': oldValue,
      'newValue': newValue,
      'performedBy': actor.userId,
      'performedByRole': actor.role,
      'performedByName': actor.name,
      'createdAt': now,
    };
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';
String? _nullable(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _first(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = _string(value);
    if (text.isNotEmpty) return text;
  }
  return fallback;
}
