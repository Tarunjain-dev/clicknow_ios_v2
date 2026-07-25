import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../utils/device_constants/appColors.dart' show AppColors;
import '../../getx/stepper_controller.dart' show StepperController;

class StepFourBodyScreen extends StatefulWidget {
  const StepFourBodyScreen({super.key});

  @override
  State<StepFourBodyScreen> createState() => _StepFourBodyScreenState();
}

class _StepFourBodyScreenState extends State<StepFourBodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();
  bool get _isDark => HelperFunctions.isDarkMode(context);
  Color get _textPrimary => _isDark ? Colors.white : Colors.black;
  Color get _textSecondary => _isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility instance
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: ResponsiveUtility.only(left: 16, top: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16,),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              decoration: _mainContainer(),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  /// Step 4 :  Legal & Identity Verification Title and Description
                  Padding(
                    padding: ResponsiveUtility.only(bottom: 4, right: 10, top: 10, left: 10),
                    child: Text(
                      "Legal & Identity Verification",
                      style: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(16), fontWeight: FontWeight.bold),),
                  ),
                  Padding(
                    padding: ResponsiveUtility.symmetric(horizontal: 10),
                    child: Text("Your profile will go live after admin approval.", style: TextStyle(color: _textSecondary, fontSize: ResponsiveUtility.fontSize(12)),
                    ),
                  ),
                  Divider(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),

                  Padding(
                    padding: ResponsiveUtility.all(10),
                    child: Column(
                      children: [
                        /// -- Secured & Confidential
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.5) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
                            border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
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
                                    SizedBox(width: ResponsiveUtility.width(8)),
                                    // -- Title
                                    Text("Secured & Confidential", style: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: ResponsiveUtility.only(left: 28, top: 2, right: 8, bottom: 6),
                                  child: Text(
                                    "Your documents are encrypted and stored securely. They are only used for verification purposes and will not be shared with third parties.",
                                    style: TextStyle(color: Color(0xff5B6274), fontSize: ResponsiveUtility.fontSize(12), fontWeight: FontWeight.w500),),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// -- Aadhaar Verification Section
                        SizedBox(height: ResponsiveUtility.height(8)),
                        _buildExpandable(
                          title: "Aadhaar Verification",
                          isExpanded: controller.isAadharExpanded,
                          onTap: controller.toggleAadhar,
                          child: _aadhaarSection(),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// -- PAN Card Section
                        _buildExpandable(
                          title: "PAN Verification",
                          isExpanded: controller.isPanExpanded,
                          onTap: controller.togglePan,
                          child: _panSection(),
                        ),

                        /// -- Verification Required
                        SizedBox(height: scale.getScaledHeight(8)),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.5) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
                            border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
                          ),
                          child: Padding(
                            padding: ResponsiveUtility.all(8),
                            child: Column(
                              children: [
                                /// -- Icon and Title
                                Row(
                                  children: [
                                    // -- Icon
                                    Icon(Icons.info_outline_rounded, color: Color(0xffFFAE4C), size: 22,),
                                    SizedBox(width: ResponsiveUtility.width(8),),
                                    // -- Title
                                    Text("Verification Required", style: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: ResponsiveUtility.only(left: 28, top: 2, right: 8, bottom: 6),
                                  child: Text(
                                    "Your profile will be reviewed by our admin team. You'll be notified once verification is completed (usually within 24-48 hours).",
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
                  Divider(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9), height: 2,),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)
                      ),
                      color: _isDark ? const Color(0xff101425) : const Color(0xffF6F6F6),
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
                                onPressed: ()=> stepperController.previousStep(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xff13182C) : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(10),
                                    side: BorderSide(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black54, size: 22,),
                                    SizedBox(width: scale.getScaledWidth(8),),
                                    Text("Back", style: TextStyle(color: isDark ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: scale.getScaledFont(14)),),
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
                                onPressed: () async {
                                  if (controller.validateStep4()) {
                                    await controller.saveDraftForStep(3);
                                    await stepperController.completeStepAndContinue(3);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                                ),
                                child: Text("Continue", style: TextStyle(color: isDark ? AppColors.purple3 : Colors.white, fontWeight: FontWeight.bold, fontSize: scale.getScaledFont(14)),),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------

  /// -- Expandable Container Section
  Widget _buildExpandable({
    required String title,
    required RxBool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Obx(() => Container(
      decoration: _innerContainer(),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: const Icon(
              Icons.verified_user,
              color: Color(0xff9235B1),
            ),
            title: Text(title, style: TextStyle(color: _textPrimary)),
            trailing: Icon(
              isExpanded.value
                  ? Icons.keyboard_arrow_up
                  : Icons
                  .keyboard_arrow_down,
              color: _textPrimary,
            ),
          ),
          if (isExpanded.value)
            Padding(
              padding:
              const EdgeInsets.all(12),
              child: child,
            )
        ],
      ),
    ));
  }

  /// -- Aadhaar Section
  Widget _aadhaarSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        /// -- Aadhaar number
        Text("Aadhaar Number", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(6)),
        TextFormField(
          controller: controller.aadharController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          style: TextStyle(color: _textPrimary),
          decoration: _inputDecoration("0000 0000 0000"),
        ),

        SizedBox(height: ResponsiveUtility.height(10)),

        Text("Upload Aadhaar Card", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(6)),
        Obx(() => GestureDetector(
          onTap: controller.pickAadharFile,
          child: Container(
            height: ResponsiveUtility.height(120),
            decoration: _uploadDecoration(),
            child: Center(
              child: controller.aadharFileName.value.isEmpty
                ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: _isDark ? Colors.white54 : Colors.black54),
                  SizedBox(height: ResponsiveUtility.height(6)),
                  Text("Tap to upload", style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),),
                  SizedBox(height: ResponsiveUtility.height(4)),
                  Text("Front & back Side of Aadhaar Card\nin single PDF File", textAlign: TextAlign.center, style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54),),
                  SizedBox(height: ResponsiveUtility.height(4)),
                  Text("PDF only, max 5 MB", textAlign: TextAlign.center, style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: ResponsiveUtility.fontSize(11))),
                ],
              )
                  : Text(controller.aadharFileName.value, style: const TextStyle(color: Colors.purpleAccent),),
            ),
          ),
        )),
      ],
    );
  }

  /// --  PAN Card Verification Section
  Widget _panSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Text("PAN Number", style: TextStyle(color: _textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.panController,
          textCapitalization:
          TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            LengthLimitingTextInputFormatter(10),
            _UpperCaseTextFormatter(),
          ],
          style:
          TextStyle(color: _textPrimary),
          decoration: _inputDecoration("ABCD1234F"),
        ),

        const SizedBox(height: 16),

        Text("Upload PAN Card", style: TextStyle(color: _textPrimary)),
        const SizedBox(height: 6),

        Obx(() => GestureDetector(
          onTap: controller.pickPanFile,
          child: Container(
            height: 120,
            decoration:
            _uploadDecoration(),
            child: Center(
              child: controller
                  .panFileName.value.isEmpty
                  ? Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(Icons.upload_file, color: _isDark ? Colors.white54 : Colors.black54),
                  SizedBox(height: 8),
                  Text("Tap to upload", style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),),
                  SizedBox(height: 4),
                  Text("Front & back Side of PAN Card\nin single PDF File", textAlign: TextAlign.center, style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54),),
                  SizedBox(height: ResponsiveUtility.height(4)),
                  Text("PDF only, max 5 MB", textAlign: TextAlign.center, style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: ResponsiveUtility.fontSize(11))),
                ],
              )
                  : Text(controller.panFileName.value, style: const TextStyle(color: Colors.purpleAccent),),
            ),
          ),
        )),
      ],
    );
  }

  // ------------------------------------------------

  InputDecoration _inputDecoration(
      String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      hintText: hint,
      hintStyle: TextStyle(color: _isDark ? const Color(0xff5B6274) : Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? AppColors.primaryColor : Color(0xffD9D9D9))),
    );
  }

  BoxDecoration _mainContainer() {
    return BoxDecoration(
      borderRadius:
      BorderRadius.circular(10),
      color:
      _isDark ? const Color(0xff1C1736).withValues(alpha: 0.5) : const Color(0xffFCFBFF),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }

  BoxDecoration _innerContainer() {
    return BoxDecoration(
      borderRadius:
      BorderRadius.circular(10),
      color:
      _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }

  BoxDecoration _uploadDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), style: BorderStyle.solid),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.6) : Colors.white,
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
