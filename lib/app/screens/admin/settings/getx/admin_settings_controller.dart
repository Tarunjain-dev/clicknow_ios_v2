import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AdminSettingsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool isLogoutInProgress = false.obs;

  Future<void> logout() async {
    if (isLogoutInProgress.value) {
      return;
    }

    isLogoutInProgress.value = true;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set(<String, dynamic>{
          'lastLogoutAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _auth.signOut();
      AuthController.instance.resetLocalAuthState(keepGuestMode: false);
      Get.offAllNamed(AppRoutes.loginRoute);
      AppSnackbar.success('Logged Out', 'You have been logged out successfully.');
    } catch (_) {
      AppSnackbar.error('Logout Failed', 'Unable to logout right now.');
    } finally {
      isLogoutInProgress.value = false;
    }
  }
}

