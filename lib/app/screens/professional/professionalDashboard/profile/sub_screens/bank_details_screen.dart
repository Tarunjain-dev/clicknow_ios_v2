import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/getx/professionalProfile_Controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/models/professional_profile_data.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility instance
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
                child: Obx(() {
                  final data = controller.profile.value;
                  return ListView(
                    padding: ResponsiveUtility.only(
                      left: 12,
                      top: 10,
                      right: 12,
                      bottom: 10,
                    ),
                    children: [
                      if (data.bankDetailsUpdateRequired) ...[
                        _updateRequiredCard(data, isDark),
                        SizedBox(height: ResponsiveUtility.height(10)),
                      ],
                      _bankCard(scale, data, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _upiCard(scale, data.upiId, isDark),
                      SizedBox(height: scale.getScaledHeight(10)),
                      _securityCard(scale, isDark),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, bool isDark) {
    return Container(
      padding: ResponsiveUtility.only(left: 8, top: 8, right: 12, bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Bank Details',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankCard(
    ScalingUtility scale,
    ProfessionalProfileData data,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(scale, 'Linked Bank Account', isDark),
          Container(
            height: 1,
            color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
          ),
          Padding(
            padding: ResponsiveUtility.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bankLine(
                  scale: scale,
                  title: 'Account Number',
                  value: _maskAccount(data.bankAccountNumber),
                  isDark: isDark,
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                _bankLine(
                  scale: scale,
                  title: 'Bank Name',
                  value: data.bankName.isEmpty ? '-' : data.bankName,
                  isDark: isDark,
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                _bankLine(
                  scale: scale,
                  title: 'IFSC Code',
                  value: _maskIfsc(data.bankIfsc),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateRequiredCard(ProfessionalProfileData data, bool isDark) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF39A32).withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffF39A32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xffF39A32)),
          SizedBox(width: ResponsiveUtility.width(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank details update required',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(3)),
                Text(
                  data.bankDetailsUpdateReason.isEmpty
                      ? 'Admin has requested updated bank details. Please contact support to complete the update.'
                      : data.bankDetailsUpdateReason,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _upiCard(ScalingUtility scale, String upi, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(scale, 'UPI Details', isDark),
          Container(
            height: 1,
            color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
            ),
            child: _bankLine(
              scale: scale,
              title: 'UPI ID',
              value: upi.isEmpty ? 'No UPI Entered' : upi,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityCard(ScalingUtility scale, bool isDark) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.all(10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
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
              SizedBox(width: ResponsiveUtility.width(10)),
              Text(
                'Data Security',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtility.fontSize(16),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          Text(
            'Your bank details are encrypted and securely stored. All payouts will be sent to this account.',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.58)
                  : Colors.black.withValues(alpha: 0.58),
              fontSize: ResponsiveUtility.fontSize(12),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankLine({
    required ScalingUtility scale,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.account_balance_outlined,
          color: isDark
              ? Color(0xffD000FF)
              : Colors.black.withValues(alpha: 0.6),
          size: 16,
        ),
        SizedBox(width: ResponsiveUtility.width(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtility.fontSize(14),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.68)
                      : Colors.black.withValues(alpha: 0.68),
                  fontSize: ResponsiveUtility.fontSize(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(ScalingUtility scale, String title, bool isDark) {
    return Padding(
      padding: ResponsiveUtility.all(8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveUtility.fontSize(16),
        ),
      ),
    );
  }

  String _maskAccount(String value) {
    final source = value.trim();
    if (source.isEmpty) return '**** **** **125';
    if (source.length <= 4) return source;
    return '**** **** **${source.substring(source.length - 3)}';
  }

  String _maskIfsc(String value) {
    final source = value.trim();
    if (source.isEmpty) return '*********123';
    if (source.length <= 3) return source;
    return '${'*' * (source.length - 3)}${source.substring(source.length - 3)}';
  }
}
