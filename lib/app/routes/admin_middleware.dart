import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appConstants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminMiddleware extends GetMiddleware {
  AdminMiddleware({int priority = 0}) : super(priority: priority);

  final GetStorage _storage = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  RouteSettings? redirect(String? route) {
    if (_auth.currentUser == null) {
      return const RouteSettings(name: AppRoutes.loginRoute);
    }
    final role = _storage.read('userRole');
    final rbacRole = _storage.read('rbacRole');
    final isAdmin =
        (role is String && role == AppConstants.adminRole) ||
        (rbacRole is String && rbacRole == AppConstants.adminRole);
    if (!isAdmin) {
      return const RouteSettings(name: AppRoutes.loginRoute);
    }
    return null;
  }
}
