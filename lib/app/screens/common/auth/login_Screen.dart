import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Auth Controller instance
    final authController = AuthController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Dark Mode instance
    HelperFunctions.isDarkMode(context);

    return SafeArea(
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.primaryGradient : null,
          color:  isDark ? null : Colors.white,
        ),
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          resizeToAvoidBottomInset: true,

          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: AlwaysScrollableScrollPhysics(),
            padding: ResponsiveUtility.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              children: [

                /// --  Guest Login 'X' Button
                Align(
                  alignment: Alignment.topRight,
                  child: Obx(() {
                    // -- when not to show the Guest Login 'X' button
                    if (!authController.showGuestSection.value || authController.showOtp.value) return const SizedBox();
                    return Container(
                      height: ResponsiveUtility.height(36),
                      width: ResponsiveUtility.width(36),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Color(0xff323232) : Colors.grey.shade300,),
                        shape: BoxShape.circle,
                        color: isDark ? Color(0xff2F2F2F).withValues(alpha: 0.8) : Colors.white,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: authController.continueAsGuest,
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Color(0xff7A7A7A) : Colors.grey,
                          size: ResponsiveUtility.width(18),),
                      ),
                    );
                  }),
                ),
                SizedBox(height: ResponsiveUtility.height(10),),

                /// -- Auth Screen Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
                  child: Image.asset(
                    AppImages.authImage,
                    fit: BoxFit.cover,
                    height: ResponsiveUtility.height(240),
                    width: double.infinity,
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(22),),

                /// -- body
                _BodyContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// -- Auth Screen Body
class _BodyContent extends StatefulWidget {
  const _BodyContent();

  @override
  State<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends State<_BodyContent> with CodeAutoFill{

  /// -- Auth Controller
  final controller = AuthController.instance;

  Worker? _otpVisibilityWorker;
  final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();

  static final String termsAndConditionURL = "https://docs.google.com/document/d/16U8wl3KjIGmEY_P5AzUXkNO9G650j15AvsG9Q97arMk/edit?usp=drivesdk";
  static final String privacyPolicyURL = "https://docs.google.com/document/d/1JaZfzC0gLrdzMoYRrsUezmE-SymflSUThUKh8d5u4vk/edit?usp=drivesdk";

  @override
  void initState() {
    super.initState();
    _otpVisibilityWorker = ever<bool>(controller.showOtp, (show) {
          if (show) {
            listenForCode();
          } else {
            cancel();
          }
        }
    );

    if (controller.showOtp.value) {
      listenForCode();
    }
  }

  @override
  void dispose() {
    _otpVisibilityWorker?.dispose();
    cancel();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final smsCode = code?.trim() ?? '';

    if (smsCode.isEmpty) return;

    controller.autofillOtpFromSms(smsCode);
  }

  BoxDecoration fieldDecoration({required final bool isDark}) {
    return BoxDecoration(
      color: isDark ? Color(0xff2F2F2F).withValues(alpha: 0.8) : Colors.white,
      borderRadius: BorderRadius.circular(ResponsiveUtility.radius(12)),
      border: Border.all(
        color: isDark ? Color(0xff323232).withValues(alpha: 1.0) : Color(0xffD9D9D9),
      ),
    );
  }

  Widget buildOtpBox(int index, {required bool isDark}) {

    return Container(
      height: ResponsiveUtility.height(50),
      width: ResponsiveUtility.width(45),
      alignment: Alignment.center,
      decoration: fieldDecoration(isDark: isDark),
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1)
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if(value.isNotEmpty){
            if(index<5){
              controller.otpFocusNodes[index+1].requestFocus();
            }
          }else{
            if(index>0){
              controller.otpFocusNodes[index-1].requestFocus();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Column(
      children: [

        /// -- Auth Screen Title
        Text(
          "Get in to your account",
          style: TextStyle(
            fontSize: ResponsiveUtility.fontSize(28),
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(8)),

        /// -- Auth Screen Sub-Title
        Text(
          "We need to register your phone number before getting started..",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ResponsiveUtility.fontSize(12),
            color: isDark ? AppColors.white.withValues(alpha: 0.6) : AppColors.grey,
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(25)),

        /// -- Phone number and country code input field section.
        Row(
          children: [
            // Country code
            Container(
              width: ResponsiveUtility.width(75),
              height: ResponsiveUtility.height(50),
              alignment: Alignment.center,
              decoration: fieldDecoration(isDark: isDark),
              child: const Text("+91", style: TextStyle(fontWeight: FontWeight.w500,),),
            ),
            SizedBox(width: ResponsiveUtility.height(10)),

            // Phone number input field
            Expanded(
              child: Container(
                height: ResponsiveUtility.height(50),
                decoration: fieldDecoration(isDark: isDark),
                padding: ResponsiveUtility.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 20,),
                    SizedBox(width: ResponsiveUtility.width(10)),

                    Expanded(
                      child: Obx(() {
                        final isLocked = controller.isPhoneFieldLocked;
                        return TextField(
                          controller: controller.phoneController,
                          enabled: !isLocked,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter phone number",
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),

        SizedBox(height: ResponsiveUtility.height(16)),

        Obx(() {
          final showOtp = controller.showOtp.value;
          return Column(
            children: [
              if(!showOtp)
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveUtility.height(50),
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.requestOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.white : AppColors.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtility.radius(8)),),
                    ),
                    child: controller.isLoading.value ?
                    const CircularProgressIndicator(color: Colors.white, strokeWidth: 2,):
                    Text("Request OTP", style: TextStyle(color: isDark ? AppColors.primaryColor : Colors.white, fontSize: ResponsiveUtility.fontSize(16),),),
                  ),
                ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showOtp ? Column(
                  children: [
                    SizedBox(height: ResponsiveUtility.height(20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => buildOtpBox(index, isDark: isDark),),
                    ),
                    SizedBox(height: ResponsiveUtility.height(20)),
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtility.height(50),
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                        child: controller.isLoading.value ? CircularProgressIndicator(color: AppColors.white, strokeWidth: 2,): const Text("Verify OTP", style: TextStyle(color: Colors.white,),),
                      ),
                    )
                  ],
                ) : const SizedBox(),
              )
            ],
          );
        }),
        SizedBox(height: ResponsiveUtility.height(14)),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: isDark? AppColors.white : Colors.grey, fontSize: ResponsiveUtility.fontSize(10.5),),
            children: [
              const TextSpan(text: "By continuing, you agree to our "),
              TextSpan(
                text: "Terms & Condition",
                style: TextStyle(color: isDark ? Colors.blue : AppColors.blue),
                recognizer: _termsRecognizer..onTap = () {
                  /// -- navigation to terms and condition google doc
                  HelperFunctions.launchURL(termsAndConditionURL);
                },
              ),
              const TextSpan(text: " and "),
              TextSpan(
                text: "Privacy policy",
                style: TextStyle(color: isDark ? Colors.blue : AppColors.blue),
                recognizer: _privacyRecognizer..onTap = () {
                  /// -- navigation to privacy policy google doc
                  HelperFunctions.launchURL(privacyPolicyURL);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(30)),

        Obx(() {

          if (!controller.showProfessionalSection.value || controller.showOtp.value) {
            return const SizedBox();
          }
          return Container(
            width: double.infinity,
            padding: ResponsiveUtility.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff0B0A12).withValues(alpha: 0.4): Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
              border: Border.all(color: isDark ? Color(0xff1E2939): Colors.black26,),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.primaryColor,),
                    SizedBox(width: ResponsiveUtility.width(8)),
                    Text("Register as professional", style: TextStyle(fontWeight: FontWeight.w600,),)
                  ],
                ),
                SizedBox(height: ResponsiveUtility.height(10)),

                Text(
                  "Offer your services, connect with customers, and grow your professional network. Complete a quick verification using your phone number and Aadhaar details.",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: ResponsiveUtility.fontSize(12),),
                ),
                SizedBox(height: ResponsiveUtility.height(10)),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.startProfessionalFlow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                    ),
                    child: Text("Start as Professional", style: TextStyle(color: isDark ? AppColors.primaryColor : Colors.white),),
                  ),
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}