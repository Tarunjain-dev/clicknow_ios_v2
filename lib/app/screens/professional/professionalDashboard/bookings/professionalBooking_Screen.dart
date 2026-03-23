import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:flutter/material.dart';
import '../../../../utils/device_utils/scale_utility.dart' show ScalingUtility;

class ProfessionalBookingsScreen extends StatelessWidget {
  const ProfessionalBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text("Professional Bookings")),
      ),
    );
  }
}
