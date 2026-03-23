import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart' ;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class StepOneBodyScreen extends StatefulWidget {
  const StepOneBodyScreen({super.key});

  @override
  State<StepOneBodyScreen> createState() => _StepOneBodyScreenState();
}

class _StepOneBodyScreenState extends State<StepOneBodyScreen> {

  final _formKey = GlobalKey<FormState>();

  /// -- professional Registration Controller
  final professionalRegController = Get.find<ProfessionalRegistrationController>();

  /// --  Stepper Controller
  final stepperController = Get.find<StepperController>();

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility Instance
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xff1C1736).withValues(alpha: 0.5),
                border: Border.all(color: const Color(0xff1E2939)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Text(
                      "Verify Your Phone Number",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "We use your phone number for booking confirmations and security.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Divider(color: Color(0xff1E2939), thickness: 2),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// PHONE LABEL
                        const Text("Phone Number", style: TextStyle(color: Colors.white)),

                        SizedBox(height: scale.getScaledHeight(6)),

                        /// PHONE INPUT
                        Row(
                          children: [
                            Container(
                              height: scale.getScaledHeight(44),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xff1C1736)
                                    .withValues(alpha: 0.5),
                                border: Border.all(
                                    color: const Color(0xff1E2939)),
                              ),
                              child: Center(
                                child: Text(
                                  "+91",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                      scale.getScaledFont(12)),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: SizedBox(
                                height: scale.getScaledHeight(44),
                                child: TextFormField(
                                  controller:
                                  professionalRegController
                                      .phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        10),
                                  ],
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(
                                        0xff1C1736)
                                        .withValues(alpha: 0.8),
                                    hintText:
                                    "Enter your phone number",
                                    hintStyle: TextStyle(
                                        color:
                                        Colors.white54,
                                        fontSize: scale
                                            .getScaledFont(12)),
                                    border:
                                    OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: scale.getScaledHeight(12)),

                        /// REQUEST OTP BUTTON (HIDDEN AFTER VERIFIED)
                        Obx(() {
                          if (professionalRegController
                              .isPhoneVerified.value) {
                            return const SizedBox();
                          }

                          return SizedBox(
                            height: scale.getScaledHeight(40),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: professionalRegController.isLoading.value
                                  ? null
                                  : professionalRegController.requestOtp,
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(10),
                                ),
                              ),
                              child: professionalRegController.isLoading.value
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
                                      professionalRegController.isOtpSent.value
                                          ? "OTP Sent"
                                          : "Request OTP",
                                      style: TextStyle(
                                        color: AppColors.purple3,
                                        fontWeight: FontWeight.bold,
                                        fontSize: scale.getScaledFont(14),
                                      ),
                                    ),
                            ),
                          );
                        }),

                        /// OTP SECTION
                        Obx(() {
                          if (professionalRegController
                              .isOtpSent.value &&
                              !professionalRegController
                                  .isPhoneVerified
                                  .value) {
                            return Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                SizedBox(
                                    height: scale
                                        .getScaledHeight(
                                        16)),

                                const Text(
                                  "Enter OTP",
                                  style: TextStyle(
                                      color:
                                      Colors.white,
                                      fontWeight:
                                      FontWeight
                                          .bold),
                                ),

                                const SizedBox(height: 10),

                                TextFormField(
                                  controller:
                                  professionalRegController
                                      .otpController,
                                  keyboardType:
                                  TextInputType
                                      .number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                      color:
                                      Colors.white),
                                  inputFormatters: [
                                    FilteringTextInputFormatter
                                        .digitsOnly,
                                  ],
                                  decoration:
                                  InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: const Color(
                                        0xff1C1736)
                                        .withValues(
                                        alpha: 0.8),
                                    hintText:
                                    "Enter 6-digit OTP",
                                    hintStyle:
                                    const TextStyle(
                                        color: Colors
                                            .white54),
                                    border:
                                    OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          10),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                SizedBox(
                                  height: scale
                                      .getScaledHeight(
                                      40),
                                  width:
                                  double.infinity,
                                  child:
                                  ElevatedButton(
                                    onPressed: professionalRegController
                                            .isLoading.value
                                        ? null
                                        : professionalRegController.verifyOtp,
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor: Colors.white,
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            10),
                                      ),
                                    ),
                                    child: professionalRegController
                                            .isLoading.value
                                        ? SizedBox(
                                            height: scale.getScaledHeight(18),
                                            width: scale.getScaledWidth(18),
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(
                                                AppColors.purple3,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            "Verify OTP",
                                            style: TextStyle(
                                              color: AppColors.purple3,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Center(
                                  child:
                                  professionalRegController
                                      .canResendOtp
                                      .value
                                      ? TextButton(
                                    onPressed:
                                    professionalRegController
                                        .resendOtp,
                                    child:
                                    const Text(
                                      "Resend OTP",
                                      style: TextStyle(
                                          color:
                                          Colors.purpleAccent),
                                    ),
                                  )
                                      : Text(
                                    "Resend OTP in ${professionalRegController.secondsRemaining.value}s",
                                    style:
                                    const TextStyle(
                                        color:
                                        Colors.grey),
                                  ),
                                ),
                              ],
                            );
                          }

                          return const SizedBox();
                        }),

                        /// SUCCESS CONTAINER
                        Obx(() {
                          if (professionalRegController.isPhoneVerified.value) {
                            return Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(12),
                              decoration:
                              BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xff192738).withValues(alpha: 0.5),
                                border: Border.all(color: Color(0xff12513E)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xff00C950)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Phone Verified Successfully.", style: const TextStyle(color: Color(0xff66FF00), fontWeight: FontWeight.bold),),
                                        Text("+91 ${professionalRegController.phoneController.text}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox();
                        }),

                        SizedBox(height: scale.getScaledHeight(12)),

                        /// -- Security Verification
                        SizedBox(height: scale.getScaledHeight(12)),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xff1C1736).withValues(alpha: 0.5),
                            border: Border.all(color: const Color(0xff1E2939)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                /// -- Icon and Title
                                Row(
                                  children: [
                                    // -- Icon
                                    Icon(Icons.shield_outlined, color: Color(0xff9235B1), size: 22,),
                                    SizedBox(width: scale.getScaledWidth(8),),
                                    // -- Title
                                    Text("Security Verification", style: TextStyle(color: Colors.white, fontSize: scale.getScaledFont(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: const EdgeInsets.only(left: 28.0, right: 8.0, top: 6.0),
                                  child: Text(
                                    "Your phone number is encrypted and used only for booking confirmations and account security.",
                                    style: TextStyle(color: Color(0xff5B6274), fontSize: scale.getScaledFont(12), fontWeight: FontWeight.w500),),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// -- back and Continue Buttons
                  const Divider(color: Color(0xff1E2939), height: 2,),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)
                      ),
                      color: const Color(0xff101425),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// -- Back Button
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(40),
                              child: ElevatedButton(
                                onPressed: ()=> Get.offAllNamed(AppRoutes.loginRoute),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff13182C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(10),
                                    side: BorderSide(color: Color(0xff1E2939)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, color: Colors.white, size: 22,),
                                    SizedBox(width: scale.getScaledWidth(8),),
                                    Text("Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: scale.getScaledFont(14)),),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// -- Continue Button
                          SizedBox(width: scale.getScaledWidth(8)),
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(40),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (professionalRegController.validateStep1()) {
                                    stepperController.nextStep();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                                ),
                                child: Text("Continue", style: TextStyle(color: AppColors.purple3, fontWeight: FontWeight.bold, fontSize: scale.getScaledFont(14)),),
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
      ),
    );
  }
}
