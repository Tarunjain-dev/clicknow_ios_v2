import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();

  static void error(String title, String message) {
    _show(title, message, isError: true);
  }

  static void success(String title, String message) {
    _show(title, message, isError: false);
  }

  static void info(String title, String message) {
    final accent = const Color(0xff63A4FF);
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xff1C1736).withValues(alpha: 0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      borderColor: accent,
      borderWidth: 1,
      icon: Icon(
        Icons.info_outline,
        color: accent,
      ),
      duration: const Duration(seconds: 2),
    );
  }

  static void _show(String title, String message, {required bool isError}) {

    final accent = isError ? const Color(0xffFF5B5B) : const Color(0xff5BFFB0);

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: const Color(0xff1C1736).withValues(alpha: 0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      borderColor: accent,
      borderWidth: 1,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: accent,
      ),
      duration: const Duration(seconds: 2),
    );
  }
}
