import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/getx/professionalProfile_Controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DocumentStatusScreen extends StatelessWidget {
  const DocumentStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final isDark = HelperFunctions.isDarkMode(context);

    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    final controller = ProfessionalProfileController.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _header(scale, isDark),
              Expanded(
                child: Obx(
                  () {
                    final data = controller.profile.value;
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(14),
                        scale.getScaledHeight(12),
                        scale.getScaledWidth(14),
                        scale.getScaledHeight(16),
                      ),
                      children: [
                        _documentCard(
                          scale: scale,
                          title: 'Aadhar Card',
                          subtitle: 'Identity Document',
                          imageUrl: data.aadhaarUrl,
                          number: _maskMiddle(data.aadhaarNumber),
                          isDark : isDark,
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _documentCard(
                          scale: scale,
                          title: 'PAN Card',
                          subtitle: 'Identity Document',
                          imageUrl: data.panUrl,
                          number: _maskMiddle(data.panNumber),
                          isDark : isDark,
                        ),
                        SizedBox(height: scale.getScaledHeight(10)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            scale.getScaledWidth(12),
                            scale.getScaledHeight(10),
                            scale.getScaledWidth(12),
                            scale.getScaledHeight(10),
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xffB629FF),
                                    size: 18,
                                  ),
                                  SizedBox(width: scale.getScaledWidth(8)),
                                  Text(
                                    'Document Verification',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: scale.getScaledFont(16),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: scale.getScaledHeight(8)),
                              Text(
                                'All your documents are verified and approved. If you need to update any document, please contact support.',
                                style: TextStyle(
                                  color: isDark ? Colors.white.withValues(alpha: 0.58) : Colors.black.withValues(alpha: 0.58),
                                  fontSize: scale.getScaledFont(14),
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: scale.getScaledHeight(3)),
                              Text(
                                'support@clicknow.co.in',
                                style: TextStyle(
                                  color: const Color(0xffD000FF),
                                  fontSize: scale.getScaledFont(14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(8),
        scale.getScaledHeight(8),
        scale.getScaledWidth(12),
        scale.getScaledHeight(10),
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          ),
          Expanded(
            child: Text(
              'Document Status',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: scale.getScaledFont(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentCard({
    required ScalingUtility scale,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String number,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
              scale.getScaledWidth(12),
              scale.getScaledHeight(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: Color(0xffD000FF),
                  size: 16,
                ),
                SizedBox(width: scale.getScaledWidth(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: scale.getScaledFont(16),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                          fontSize: scale.getScaledFont(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.getScaledWidth(10),
                    vertical: scale.getScaledHeight(3),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff0ADB6D).withValues(alpha: 0.15) : Color(0xffE4FFD2).withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Color(0xff0ADB6D).withValues(alpha: 0.5) : Color(0xff00A63E).withValues(alpha: 1),
                    ),
                  ),
                  child: Text(
                    'Approved',
                    style: TextStyle(
                      color: isDark ? Color(0xff00FF8A) : Color(0xff00A63E),
                      fontWeight: FontWeight.w500,
                      fontSize: scale.getScaledFont(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
              scale.getScaledWidth(12),
              scale.getScaledHeight(12),
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    height: scale.getScaledHeight(140),
                    child: imageUrl.isEmpty
                        ? _docPlaceholder(scale, number)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _docPlaceholder(scale, number),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _docPlaceholder(scale, number);
                            },
                          ),
                  ),
                ),
                Positioned(
                  top: scale.getScaledHeight(6),
                  right: scale.getScaledWidth(8),
                  child: Container(
                    height: scale.getScaledHeight(30),
                    width: scale.getScaledWidth(30),
                    decoration: const BoxDecoration(
                      color: Color(0xff0ADB6D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 19,
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

  Widget _docPlaceholder(ScalingUtility scale, String number) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffD5DBF9), Color(0xffB5C5F8), Color(0xffF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.getScaledWidth(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Government ID',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: scale.getScaledFont(13),
              ),
            ),
            const Spacer(),
            Text(
              number,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: scale.getScaledFont(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _maskMiddle(String value) {
    final source = value.trim();
    if (source.isEmpty) return 'XXXX XXXX XXXX';
    if (source.length <= 4) return source;
    final visible = source.substring(source.length - 4);
    return 'XXXX XXXX $visible';
  }
}
