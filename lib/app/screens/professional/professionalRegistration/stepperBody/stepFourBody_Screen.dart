import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../utils/device_constants/appColors.dart' show AppColors;
import '../../getx/stepper_controller.dart' show StepperController;

class StepFourBodyScreen extends StatefulWidget {
  const StepFourBodyScreen({super.key});

  @override
  State<StepFourBodyScreen> createState() =>
      _StepFourBodyScreenState();
}

class _StepFourBodyScreenState extends State<StepFourBodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Text("Legal & Identity Verification",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Your profile will go live after admin approval.", style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Color(0xff1E2939)),

                  Padding(
                    padding:
                    const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        /// -- Secured & Confidential
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
                                    Text("Secured & Confidential", style: TextStyle(color: Colors.white, fontSize: scale.getScaledFont(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: const EdgeInsets.only(left: 28.0, right: 8.0, top: 6.0),
                                  child: Text(
                                    "Your documents are encrypted and stored securely. They are only used for verification purposes and will not be shared with third parties.",
                                    style: TextStyle(color: Color(0xff5B6274), fontSize: scale.getScaledFont(12), fontWeight: FontWeight.w500),),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// -- Aadhaar Verification Section
                        SizedBox(height: scale.getScaledHeight(8)),
                        _buildExpandable(
                          title: "Aadhaar Verification",
                          isExpanded: controller.isAadharExpanded,
                          onTap: controller.toggleAadhar,
                          child: _aadhaarSection(),
                        ),
                        const SizedBox(height: 16),

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
                                    Icon(Icons.info_outline_rounded, color: Color(0xffFFAE4C), size: 22,),
                                    SizedBox(width: scale.getScaledWidth(8),),
                                    // -- Title
                                    Text("Verification Required", style: TextStyle(color: Colors.white, fontSize: scale.getScaledFont(14), fontWeight: FontWeight.bold),),
                                  ],
                                ),

                                /// -- Description
                                Padding(
                                  padding: const EdgeInsets.only(left: 28.0, right: 8.0, top: 6.0),
                                  child: Text(
                                    "Your profile will be reviewed by our admin team. You'll be notified once verification is completed (usually within 24-48 hours).",
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
                                onPressed: ()=> stepperController.previousStep(),
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
                                  if (controller.validateStep4()) {
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
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white)),
            trailing: Icon(
              isExpanded.value
                  ? Icons.keyboard_arrow_up
                  : Icons
                  .keyboard_arrow_down,
              color: Colors.white,
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
        const Text("Aadhaar Number", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.aadharController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("0000 0000 0000"),
        ),

        const SizedBox(height: 16),

        const Text("Upload Aadhaar Card", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        Obx(() => GestureDetector(
          onTap: controller.pickAadharFile,
          child: Container(
            height: 120,
            decoration: _uploadDecoration(),
            child: Center(
              child: controller.aadharFileName.value.isEmpty
                ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: Colors.white54),
                  SizedBox(height: 8),
                  Text("Tap to upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                  SizedBox(height: 4),
                  Text("Front & back Side of Aadhaar Card\nin single PDF File", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54),),
                ],
              )
                  : Text(
                controller
                    .aadharFileName
                    .value,
                style:
                const TextStyle(
                    color: Colors
                        .purpleAccent),
              ),
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

        const Text("PAN Number", style: TextStyle(color: Colors.white)),
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
          const TextStyle(color: Colors.white),
          decoration: _inputDecoration("ABCD1234F"),
        ),

        const SizedBox(height: 16),

        const Text("Upload PAN Card", style: TextStyle(color: Colors.white)),
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
                  ? const Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(Icons.upload_file, color: Colors.white54),
                  SizedBox(height: 8),
                  Text("Tap to upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                  SizedBox(height: 4),
                  Text("Front & back Side of PAN Card\nin single PDF File", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54),),
                ],
              )
                  : Text(
                controller
                    .panFileName.value,
                style:
                const TextStyle(
                    color: Colors
                        .purpleAccent),
              ),
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
      fillColor:
      const Color(0xff1C1736).withValues(alpha: 0.8),
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xff5B6274)),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
      ),
    );
  }

  BoxDecoration _mainContainer() {
    return BoxDecoration(
      borderRadius:
      BorderRadius.circular(10),
      color:
      const Color(0xff1C1736).withValues(alpha: 0.5),
      border: Border.all(
          color: const Color(0xff1E2939)),
    );
  }

  BoxDecoration _innerContainer() {
    return BoxDecoration(
      borderRadius:
      BorderRadius.circular(10),
      color:
      const Color(0xff1C1736).withValues(alpha: 0.8),
      border: Border.all(
          color: const Color(0xff1E2939)),
    );
  }

  BoxDecoration _uploadDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xff1E2939), style: BorderStyle.solid),
      color:
      const Color(0xff1C1736).withValues(alpha: 0.6),
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
