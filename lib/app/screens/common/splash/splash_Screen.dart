import 'package:clicknow_version2/app/screens/common/splash/getx/splash_Controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(SplashController());
  }

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
        backgroundColor: AppColors.transparent,
        resizeToAvoidBottomInset: true,

        /// -- Logo
        body: Center(
          child: SizedBox(
            height: scale.getScaledHeight(70),
            width: double.maxFinite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// -- "CN" in a box.
                Container(
                  height: scale.getScaledHeight(70),
                  width: scale.getScaledWidth(70),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.white,
                  ),
                  child: Center(
                    child: Padding(
                      padding: scale.getPadding(all: 8),
                      child: Text("CN", style: TextStyle(fontSize: scale.getScaledFont(32), color: AppColors.purple3, fontWeight: FontWeight.bold,),),
                    ),
                  ),
                ),

                /// -- ClickNow
                SizedBox(width: scale.getScaledWidth(8)),
                Text('Click', style: TextStyle(fontSize: scale.getScaledFont(38), fontWeight: FontWeight.bold, color: AppColors.white, height: 1,),),
                Text('Now', style: TextStyle(fontSize: scale.getScaledFont(38), fontWeight: FontWeight.normal, color: AppColors.white, height: 1,),),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
