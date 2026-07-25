import 'dart:async';

import 'package:clicknow_version2/app/services/notifications/notification_model.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? get _currentNotificationsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .collection(ServiceCatalogPaths.userNotificationsSubcollection);
  }

  Stream<List<ClickNowNotification>> watchCurrentUserNotifications() {
    final ref = _currentNotificationsRef;
    if (ref == null) return Stream.value(const <ClickNowNotification>[]);
    return ref.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(ClickNowNotification.fromDoc)
              .toList(growable: false),
        );
  }

  Stream<int> watchCurrentUserUnreadCount() {
    final ref = _currentNotificationsRef;
    if (ref == null) return Stream.value(0);
    return ref
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> markRead(String notificationId) async {
    final ref = _currentNotificationsRef;
    if (ref == null || notificationId.trim().isEmpty) return;
    await ref.doc(notificationId.trim()).set(<String, dynamic>{
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllRead() async {
    final ref = _currentNotificationsRef;
    if (ref == null) return;
    final snapshot = await ref.where('read', isEqualTo: false).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, <String, dynamic>{
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<NotificationCampaign>> watchCampaigns() {
    return _db
        .collection(ServiceCatalogPaths.notificationCampaignsCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificationCampaign.fromDoc)
              .toList(growable: false),
        );
  }
}
