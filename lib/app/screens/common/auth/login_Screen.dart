import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_constants/appStrings.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility Instance
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Auth Image height
    final double imageHeight = scale.getScaledHeight(300);

    return Container(
      color: AppColors.black,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              /// -- Login Image and body Content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  /// -- Login photographer Image
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(AppImages.photographer, fit: BoxFit.cover,),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.black.withValues(alpha: 0.6),
                                    AppColors.black.withValues(alpha: 0.9),
                                  ],
                                  stops: const [0.4, 0.7, 1],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// -- Login Body Content
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.getScaledWidth(16),
                        vertical: scale.getScaledHeight(10),
                      ),
                      child: _BodyContent(scale: scale),
                    ),
                  ),
                ],
              ),

              /// -- Guest Login: Cross "X" button
              Positioned(
                top: scale.getScaledHeight(8),
                right: scale.getScaledWidth(8),
                child: Container(
                  height: scale.getScaledHeight(36),
                  width: scale.getScaledWidth(36),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: IconButton(
                      onPressed: () => Get.offAllNamed(
                        AppRoutes.customerBottomNavigationRoute,
                      ),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: scale.getScaledWidth(18),
                      ),
                      tooltip: "Continue as guest",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyContent extends StatefulWidget {
  const _BodyContent({required this.scale});
  final ScalingUtility scale;
  @override
  State<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends State<_BodyContent> {

  /// -- Auth Controller instance
  final AuthController controller = AuthController.instance;

  /// -- Tap Gestures
  final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  BoxDecoration _fieldDecoration(ScalingUtility scale, {double radius = 12}) {
    return BoxDecoration(
      color: AppColors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.4),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index, ScalingUtility scale) {
    return Container(
      height: scale.getScaledHeight(46),
      width: scale.getScaledWidth(44),
      decoration: _fieldDecoration(scale, radius: 8),
      alignment: Alignment.center,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.85),
          fontSize: scale.getScaledFont(16),
          fontWeight: FontWeight.w600,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: "",
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < controller.otpFocusNodes.length - 1) {
              controller.otpFocusNodes[index + 1].requestFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          } else if (index > 0) {
            controller.otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// -- Login Screen Title and Description
        Text(AppStrings.loginTitle, style: TextStyle(fontSize: scale.getScaledFont(20), color: AppColors.white, fontWeight: FontWeight.bold,),),
        SizedBox(height: scale.getScaledHeight(6)),
        Text(AppStrings.loginDescription, textAlign: TextAlign.center, style: TextStyle(fontSize: scale.getScaledFont(13), color: AppColors.descriptionColor,),),
        SizedBox(height: scale.getScaledHeight(18)),

        /// -- Phone input textfield
        Row(
          children: [
            Container(
              height: scale.getScaledHeight(48),
              width: scale.getScaledWidth(64),
              alignment: Alignment.center,
              decoration: _fieldDecoration(scale),
              child: Text("+91", style: TextStyle(color: AppColors.white, fontSize: scale.getScaledFont(13),),),
            ),
            SizedBox(width: scale.getScaledWidth(8)),
            Expanded(
              child: Container(
                height: scale.getScaledHeight(48),
                decoration: _fieldDecoration(scale),
                padding: EdgeInsets.symmetric(
                  horizontal: scale.getScaledWidth(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.white.withValues(alpha: 0.6), size: scale.getScaledWidth(18),),
                    SizedBox(width: scale.getScaledWidth(8)),
                    Expanded(
                      child: TextField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: scale.getScaledFont(14),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter phone number",
                          hintStyle: TextStyle(
                            fontSize: scale.getScaledFont(13),
                            color: AppColors.descriptionColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: scale.getScaledHeight(12)),
        Obx(() {
          final showOtp = controller.showOtp.value;
          return Column(
            children: [
              if (!showOtp)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        controller.isLoading.value ? null : controller.requestOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.purple3,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: scale.getScaledHeight(12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: scale.getScaledHeight(18),
                            width: scale.getScaledWidth(18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.purple3),
                            ),
                          )
                        : Text(
                            "Request OTP",
                            style: TextStyle(
                              fontSize: scale.getScaledFont(14),
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple3,
                            ),
                          ),
                  ),
                ),

              /// -- OTP Input Textfield
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showOtp
                    ? Column(
                        key: const ValueKey("otp-section"),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Enter OTP",
                              style: TextStyle(
                                fontSize: scale.getScaledFont(12),
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: scale.getScaledHeight(8)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => _buildOtpBox(index, scale),
                            ),
                          ),
                          SizedBox(height: scale.getScaledHeight(12)),

                          /// -- Verify OTP Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.purple3,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: scale.getScaledHeight(12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: controller.isLoading.value
                                  ? SizedBox(
                                      height: scale.getScaledHeight(18),
                                      width: scale.getScaledWidth(18),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.purple3,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Verify OTP",
                                      style: TextStyle(
                                        fontSize: scale.getScaledFont(14),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.purple3,
                                      ),
                                    ),
                            ),
                          ),

                          /// -- Resend OTP Section
                          SizedBox(height: scale.getScaledHeight(8)),
                          Align(
                            alignment: Alignment.center,
                            child: controller.secondsLeft.value > 0
                                ? RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: scale.getScaledFont(11),
                                        color: AppColors.descriptionColor,
                                      ),
                                      children: [
                                        const TextSpan(text: "Resend OTP in "),
                                        TextSpan(
                                          text:
                                              "${controller.secondsLeft.value}s",
                                          style: TextStyle(
                                            color: AppColors.purple1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    height: scale.getScaledHeight(34),
                                    child: TextButton(
                                      onPressed: controller.resendOtp,
                                      child: Text(
                                        "Resend OTP",
                                        style: TextStyle(
                                          fontSize: scale.getScaledFont(11),
                                          color: AppColors.purple1,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }),

        SizedBox(height: scale.getScaledHeight(8)),

        /// -- Terms & Condition and Privacy Policy
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: scale.getScaledFont(11),
              color: AppColors.descriptionColor,
            ),
            children: [
              const TextSpan(text: "By continuing, you agree to our "),
              TextSpan(
                text: "Terms & Condition",
                style: TextStyle(color: AppColors.blue),
                recognizer: _termsRecognizer
                  ..onTap = () {
                    Get.snackbar(
                      "Terms & Condition",
                      "Terms & Condition tapped.",
                    );
                  },
              ),
              const TextSpan(text: " and "),
              TextSpan(
                text: "Privacy policy",
                style: TextStyle(color: AppColors.blue),
                recognizer: _privacyRecognizer
                  ..onTap = () {
                    Get.snackbar("Privacy policy", "Privacy policy tapped.");
                  },
              ),
              const TextSpan(text: "."),
            ],
          ),
        ),

        /// -- Register as Professional Section
        SizedBox(height: scale.getScaledHeight(18)),
        Obx(() {
          if (!controller.showProfessionalSection.value) {
            return const SizedBox.shrink();
          }
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: scale.getScaledWidth(14),
              vertical: scale.getScaledHeight(14),
            ),
            decoration: BoxDecoration(
              color: Color(0xff0B0A12).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xff1E2939)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple2.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.purple1,
                      size: scale.getScaledWidth(18),
                    ),
                    SizedBox(width: scale.getScaledWidth(6)),
                    Text(
                      "Register as professional",
                      style: TextStyle(
                        fontSize: scale.getScaledFont(12),
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: scale.getScaledHeight(6)),
                Text(
                  "Offer your services, connect with customers, and grow your professional network. Complete a quick verification using your phone number and Aadhaar details to create your professional account and start receiving bookings.",
                  style: TextStyle(
                    fontSize: scale.getScaledFont(11),
                    color: AppColors.descriptionColor,
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(12)),

                /// -- Start as Professional Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.startProfessionalFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.purple3,
                      padding: EdgeInsets.symmetric(
                        vertical: scale.getScaledHeight(10),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Start as Professional",
                      style: TextStyle(
                        fontSize: scale.getScaledFont(13),
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        SizedBox(height: scale.getScaledHeight(12)),
      ],
    );
  }
}
