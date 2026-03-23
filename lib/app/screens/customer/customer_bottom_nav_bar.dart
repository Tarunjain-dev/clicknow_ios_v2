import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:flutter/material.dart';

class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          title: const Text(
            "Customer Dashboard",
            style: TextStyle(color: AppColors.white),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "Welcome to ClickNow",
            style: TextStyle(color: AppColors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
