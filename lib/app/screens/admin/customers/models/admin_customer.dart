import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCustomer {
  const AdminCustomer({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.profileCompleted,
    required this.createdAt,
    required this.lastLoginAt,
    required this.accountStatus,
    required this.isVerifiedCustomer,
    required this.suspensionReason,
    required this.blockedReason,
  });

  final String uid;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final bool profileCompleted;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String accountStatus;
  final bool isVerifiedCustomer;
  final String suspensionReason;
  final String blockedReason;

  factory AdminCustomer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final fullName = (data['fullName'] as String? ?? '').trim();
    return AdminCustomer(
      uid: doc.id,
      fullName: fullName.isEmpty ? 'Customer' : fullName,
      phoneNumber: (data['phoneNumber'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      state: (data['state'] as String? ?? '').trim(),
      pincode: (data['pincode'] as String? ?? '').trim(),
      profileCompleted: (data['profileCompleted'] as bool?) == true,
      createdAt: _asDateTime(data['createdAt']),
      lastLoginAt: _asDateTime(data['lastLoginAt']),
      accountStatus: (data['accountStatus'] ?? 'ACTIVE')
          .toString()
          .trim()
          .toUpperCase(),
      isVerifiedCustomer: data['isVerifiedCustomer'] == true,
      suspensionReason: (data['suspensionReason'] ?? '').toString().trim(),
      blockedReason: (data['blockedReason'] ?? '').toString().trim(),
    );
  }

  String get searchableText {
    return [
      uid,
      fullName,
      phoneNumber,
      city,
      state,
      pincode,
      accountStatus,
      suspensionReason,
      blockedReason,
    ].join(' ').toLowerCase();
  }

  String get addressLine {
    final segments = <String>[
      if (address.isNotEmpty) address,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    if (segments.isEmpty) {
      return 'Address not provided';
    }
    return segments.join(', ');
  }
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
  return null;
}
