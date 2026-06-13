import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';

class StepOneBodyScreen extends StatefulWidget {
  const StepOneBodyScreen({super.key});

  @override
  State<StepOneBodyScreen> createState() => _StepOneBodyScreenState();
}

class _StepOneBodyScreenState extends State<StepOneBodyScreen> with CodeAutoFill {

  final _formKey = GlobalKey<FormState>();

  /// -- professional Registration Controller
  final professionalRegController = Get.find<ProfessionalRegistrationController>();

  /// --  Stepper Controller
  final stepperController = Get.find<StepperController>();
  Worker? _otpListenerWorker;

  @override
  void initState() {
    super.initState();
    _otpListenerWorker = ever<bool>(professionalRegController.isOtpSent, (
      sent,
    ) {
      if (sent && !professionalRegController.isPhoneVerified.value) {
        listenForCode();
      } else {
        cancel();
      }
    });
    if (professionalRegController.isOtpSent.value &&
        !professionalRegController.isPhoneVerified.value) {
      listenForCode();
    }
  }

  @override
  void codeUpdated() {
    final raw = code?.trim() ?? '';
    if (raw.isEmpty || professionalRegController.isLoading.value) {
      return;
    }
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6) {
      return;
    }
    professionalRegController.otpController.text = digits.substring(0, 6);
    professionalRegController.verifyOtp();
  }

  @override
  void dispose() {
    _otpListenerWorker?.dispose();
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: ResponsiveUtility.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
                color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffFCFBFF),
                border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Padding(
                    padding: ResponsiveUtility.only(bottom: 4, top: 10, right: 10, left: 10),
                    child: Text(
                      "Verify Your Phone Number",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: ResponsiveUtility.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: ResponsiveUtility.symmetric(horizontal: 10),
                    child: Text(
                      "We use your phone number for booking confirmations and security.",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6),
                        fontSize: ResponsiveUtility.fontSize(12),
                      ),
                    ),
                  ),

                  Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), thickness: 1),

                  Padding(
                    padding: ResponsiveUtility.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// PHONE LABEL
                        Text("Phone Number", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        SizedBox(height: ResponsiveUtility.height(6)),

                        /// PHONE INPUT
                        Row(
                          children: [
                            Container(
                              height: ResponsiveUtility.height(44),
                              padding: ResponsiveUtility.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
                                color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffF6F4FF).withValues(alpha: 0.8),
                                border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                              ),
                              child: Center(
                                child: Text("+91", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: ResponsiveUtility.fontSize(12)),),
                              ),
                            ),

                            SizedBox(width: ResponsiveUtility.width(8)),

                            Expanded(
                              child: Obx(() {
                                final lockPhoneField = professionalRegController.isOtpSent.value || professionalRegController.isPhoneVerified.value;
                                return SizedBox(
                                  height: ResponsiveUtility.height(44),
                                  child: TextFormField(
                                    controller: professionalRegController.phoneController,
                                    enabled: !lockPhoneField,
                                    readOnly: lockPhoneField,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    style: TextStyle(
                                      color: lockPhoneField ?
                                      isDark ? Colors.white70 : Colors.black :
                                      isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                    ),
                                    decoration: InputDecoration(
                                    filled: true,
                                    fillColor: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffF6F4FF).withValues(alpha: 0.8),
                                    hintText: "Enter your phone number",
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),
                                      fontSize: ResponsiveUtility.fontSize(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.5,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),

                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// REQUEST OTP BUTTON (HIDDEN AFTER VERIFIED)
                        Obx(() {
                          if (professionalRegController.isOtpSent.value || professionalRegController.isPhoneVerified.value) {
                            return const SizedBox();
                          }

                          return SizedBox(
                            height: ResponsiveUtility.height(44),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: professionalRegController.isLoading.value ? null : professionalRegController.requestOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: professionalRegController.isLoading.value ?
                              SizedBox(
                                height: ResponsiveUtility.height(18),
                                width: ResponsiveUtility.width(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    isDark ? AppColors.primaryColor : Colors.white,
                                  ),
                                ),
                              ) :
                              Text(
                                professionalRegController.isOtpSent.value ? "OTP Sent" : "Request OTP",
                                style: TextStyle(
                                  color: isDark? AppColors.purple3 : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtility.fontSize(14),
                                ),
                              ),
                            ),
                          );
                        }),

                        /// OTP SECTION
                        Obx(() {
                          if (professionalRegController.isOtpSent.value && !professionalRegController.isPhoneVerified.value) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: ResponsiveUtility.height(6)),
                                Text("Enter OTP", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),),
                                SizedBox(height: ResponsiveUtility.height(10)),
                                TextFormField(
                                  controller: professionalRegController.otpController,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffF6F4FF).withValues(alpha: 0.8),
                                    hintText: "Enter 6-digit OTP",
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),
                                      fontSize: ResponsiveUtility.fontSize(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.5,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                        width: 1.2,
                                      ),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    height: ResponsiveUtility.height(30),
                                    child: TextButton(
                                      onPressed: professionalRegController.isLoading.value ? null : ()=> professionalRegController.enablePhoneNumberEdit(),
                                      child: const Text("Change Number", style: TextStyle(color: Color(0xffBF00FF), fontWeight: FontWeight.w600,),),
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: ResponsiveUtility.height(40),
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: professionalRegController.isLoading.value ? null : professionalRegController.verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: professionalRegController.isLoading.value
                                        ? SizedBox(
                                            height: ResponsiveUtility.height(18),
                                            width: ResponsiveUtility.width(18),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(isDark ? AppColors.primaryColor : AppColors.white,),
                                            ),
                                          )
                                        : Text("Verify OTP", style: TextStyle(color: isDark ? AppColors.primaryColor : Colors.white, fontWeight: FontWeight.bold,),),
                                  ),
                                ),

                                SizedBox(height: ResponsiveUtility.height(2),),

                                Center(
                                  child: professionalRegController.canResendOtp.value ?
                                  SizedBox(
                                    height: ResponsiveUtility.height(30),
                                      child: TextButton(onPressed: professionalRegController.resendOtp, child: Text("Resend OTP", style: TextStyle(color: Color(0xffBF00FF)),),)):
                                  Text("Resend OTP in ${professionalRegController.secondsRemaining.value}s", style: TextStyle(color: Colors.black.withValues(alpha: 0.8)),),),
                              ],
                            );
                          }

                          return const SizedBox();
                        }),

                        /// SUCCESS CONTAINER
                        Obx(() {
                          if (professionalRegController.isPhoneVerified.value) {
                            return Container(
                              padding: ResponsiveUtility.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isDark ? Color(0xff192738).withValues(alpha: 0.5) : Color(0xffE0FFEC).withValues(alpha: 1.0),
                                border: Border.all(color: isDark ? Color(0xff12513E) : Color(0xff00A63E)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: isDark ? Color(0xff66FF00).withValues(alpha: 0.5) : Color(0xff00712A).withValues(alpha: 1.0)),
                                  SizedBox(width: ResponsiveUtility.width(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Phone Verified Successfully.", style: TextStyle(color: isDark ? Color(0xff66FF00).withValues(alpha: 0.5) : Color(0xff00712A).withValues(alpha: 1.0), fontWeight: FontWeight.bold),),
                                        Text("+91 ${professionalRegController.phoneController.text}", style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.bold),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox();
                        }),

                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// -- Security Verification
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                            border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                          ),
                          child: Padding(
                            padding: ResponsiveUtility.all(8),
                            child: Column(
                              children: [
                                /// -- Icon and Title
                                Row(
                                  children: [
                                    // -- Icon
                                    Icon(Icons.shield_outlined, color: Color(0xff9235B1), size: 22,),
                                    SizedBox(width: ResponsiveUtility.width(8),),
                                    // -- Title
                                    Text("Security Verification", style: TextStyle(color: isDark ? Colors.white :Colors.black, fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: ResponsiveUtility.only(left: 28, right: 8, top: 2),
                                  child: Text(
                                    "Your phone number is encrypted and used only for booking confirmations and account security.",
                                    style: TextStyle(color: Color(0xff5B6274), fontSize: ResponsiveUtility.fontSize(12), fontWeight: FontWeight.w500),),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// -- back and Continue Buttons
                  Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), height: 2,),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)
                      ),
                      color: isDark ? Color(0xff101425) : Color(0xffF6F6F6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// -- Back Button
                          Obx(
                            () => Expanded(
                              child: SizedBox(
                                height: ResponsiveUtility.height(40),
                                child: ElevatedButton(
                                  onPressed: professionalRegController.isLoading.value || professionalRegController.isPhoneVerified.value || (professionalRegController.isOtpSent.value && !professionalRegController.isPhoneVerified.value)
                                      ? null : () {
                                          AuthController.instance.restoreProfessionalStarterSectionBeforeVerification();
                                          Get.offAllNamed(AppRoutes.loginRoute,);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Color(0xff13182C) : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(10),
                                      side: BorderSide(
                                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6), size: 16,),
                                      SizedBox(width: ResponsiveUtility.width(4)),
                                      Text(
                                        "Back",
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: ResponsiveUtility.fontSize(14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// -- Continue Button
                          SizedBox(width: ResponsiveUtility.width(8)),
                          Expanded(
                            child: SizedBox(
                              height: ResponsiveUtility.height(40),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (professionalRegController.validateStep1()) {
                                    await professionalRegController.saveDraftForStep(0);
                                    await stepperController.completeStepAndContinue(0);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                                ),
                                child: Text("Continue", style: TextStyle(color: isDark ? AppColors.purple3 : Colors.white, fontWeight: FontWeight.bold, fontSize: ResponsiveUtility.fontSize(14)),),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
