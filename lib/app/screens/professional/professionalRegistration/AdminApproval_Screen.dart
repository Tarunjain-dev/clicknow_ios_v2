import 'package:clicknow_version2/app/screens/professional/getx/admin_approval_controller.dart';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Admin Approval Controller
    final controller = Get.put(AdminApprovalController());

    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: ResponsiveUtility.all(20),
            child: Column(
              children: [
                SizedBox(height: ResponsiveUtility.height(10)),

                /// SUCCESS ICON
                Container(
                  height: ResponsiveUtility.height(100),
                  width: ResponsiveUtility.width(100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.purpleAccent, Colors.deepPurple],
                    ),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
                SizedBox(height: ResponsiveUtility.height(10)),

                /// TITLE & its description
                Text(
                  "Profile Submitted Successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: ResponsiveUtility.fontSize(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                Text(
                  "Your professional profile is under admin review. Our team is currently reviewing your professional credentials. This usually takes 24-48 hours. You will get notified as we proceed. ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(20)),

                /// PROGRESS CARD
                Expanded(
                  child: Container(
                    padding: ResponsiveUtility.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff1C1736)
                          : const Color(0xffFCFBFF).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Container(
                            margin: ResponsiveUtility.only(bottom: 10),
                            padding: ResponsiveUtility.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timeline_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                SizedBox(width: ResponsiveUtility.width(8)),
                                Expanded(
                                  child: Text(
                                    controller.statusLabel.value,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Text(
                          "Application Progress",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: ResponsiveUtility.fontSize(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: ResponsiveUtility.height(10)),
                        Obx(() {
                          final stageProgress =
                              (controller.currentStage.value.index + 1) /
                              ApplicationStage.values.length;
                          final progressPercent = (stageProgress * 100).round();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 8,
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: isDark
                                            ? Color(0xff2A2E3F)
                                            : Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                      ),
                                      AnimatedFractionallySizedBox(
                                        widthFactor: stageProgress,
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: Colors.purpleAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtility.height(8)),
                              Text(
                                "$progressPercent% completed",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: ResponsiveUtility.fontSize(12),
                                ),
                              ),
                            ],
                          );
                        }),

                        SizedBox(height: ResponsiveUtility.height(10)),

                        Expanded(child: _buildStepper(controller, isDark)),

                        Obx(() {
                          if (controller.statusLabel.value !=
                              'Document Re-upload Requested') {
                            return const SizedBox();
                          }
                          final documents = controller
                              .reuploadRequestedDocuments
                              .map((item) => item.replaceAll('_', ' '))
                              .join(', ');
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xffF39A32,
                              ).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xffF39A32),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Admin has requested document re-upload.',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please update the requested documents to continue verification.${documents.isEmpty ? '' : '\nRequested: $documents'}${controller.reuploadReason.value.isEmpty ? '' : '\nReason: ${controller.reuploadReason.value}'}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        Obx(() {
                          /// Why this block of code???
                          final comment = controller.adminComment.value.trim();
                          if (comment.isEmpty) {
                            return const SizedBox();
                          }
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xff241B47),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              "Admin Note: $comment",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(20)),

                /// BUTTONS
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final isApproved =
                        controller.currentStage.value ==
                        ApplicationStage.welcomed;
                    return ElevatedButton(
                      onPressed: isApproved
                          ? () => Get.offAllNamed(
                              AppRoutes.professionalBottomNavigationRoute,
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                              height: ResponsiveUtility.height(20),
                              width: ResponsiveUtility.width(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  isDark
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Go to Professional Dashboard",
                              style: TextStyle(
                                fontSize: ResponsiveUtility.fontSize(16),
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                    );
                  }),
                ),

                SizedBox(height: ResponsiveUtility.height(12)),

                SizedBox(
                  width: double.infinity,
                  child: Obx(
                    () => OutlinedButton(
                      onPressed: controller.isRefreshing.value
                          ? null
                          : controller.refreshStatus,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        padding: ResponsiveUtility.symmetric(vertical: 16),
                      ),
                      child: controller.isRefreshing.value
                          ? SizedBox(
                              height: ResponsiveUtility.height(18),
                              width: ResponsiveUtility.height(18),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                          : Text(
                              "Track Application Status",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(10)),
                Obx(() {
                  final lastChecked = controller.lastCheckedAt.value;
                  if (lastChecked == null) {
                    return const SizedBox();
                  }
                  final formatted = DateFormat(
                    'dd MMM, hh:mm a',
                  ).format(lastChecked);

                  return Text(
                    "Last checked: $formatted",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // VERTICAL STEPPER
  // ------------------------------------------------

  Widget _buildStepper(AdminApprovalController controller, bool isDark) {
    final stages = ApplicationStage.values;

    return ListView.builder(
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final stage = stages[index];

        return Obx(() {
          final isCompleted = controller.isCompleted(stage);
          final isActive = controller.isActive(stage);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT INDICATOR
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    height: ResponsiveUtility.height(26),
                    width: ResponsiveUtility.width(26),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isActive
                          ? Colors.purpleAccent
                          : Colors.grey.shade700,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : isActive
                            ? Icons.lock_open_rounded
                            : Icons.lock,
                        key: ValueKey('${stage.name}-$isCompleted-$isActive'),
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  if (index != stages.length - 1)
                    Container(
                      width: ResponsiveUtility.width(1),
                      height: ResponsiveUtility.height(30),
                      color: isDark
                          ? Colors.white24
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                ],
              ),

              SizedBox(width: ResponsiveUtility.width(10)),

              /// TEXT
              Expanded(
                child: Padding(
                  padding: ResponsiveUtility.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          color: isCompleted || isActive
                              ? isDark
                                    ? Colors.white
                                    : Colors.black
                              : isDark
                              ? Colors.white54
                              : Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.bold,
                        ),
                        child: Text(_getTitle(stage)),
                      ),
                      SizedBox(height: ResponsiveUtility.height(4)),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.orange
                              : isDark
                              ? Colors.white38
                              : Colors.black38,
                        ),
                        child: Text(_getSubtitle(stage, controller)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  String _getTitle(ApplicationStage stage) {
    switch (stage) {
      case ApplicationStage.phoneVerified:
        return "Phone Verified";

      case ApplicationStage.profileSubmitted:
        return "Profile Submitted";

      case ApplicationStage.underReview:
        return "Under Review";

      case ApplicationStage.approved:
        return "Approved";

      case ApplicationStage.welcomed:
        return "ClickNow welcomes you into family.";
    }
  }

  String _getSubtitle(
    ApplicationStage stage,
    AdminApprovalController controller,
  ) {
    final isCompleted = controller.isCompleted(stage);
    final isActive = controller.isActive(stage);

    switch (stage) {
      case ApplicationStage.phoneVerified:
        return isCompleted || isActive ? "Completed" : "Pending";

      case ApplicationStage.profileSubmitted:
        return isCompleted || isActive ? "Completed" : "Pending";

      case ApplicationStage.underReview:
        if (isActive) {
          return "In Progress (24-48 Hrs)";
        } else if (isCompleted) {
          return "Completed";
        } else {
          return "Pending";
        }

      case ApplicationStage.approved:
        return isCompleted
            ? "Completed"
            : isActive
            ? "Approved"
            : "Pending";

      case ApplicationStage.welcomed:
        return isCompleted
            ? "Completed"
            : isActive
            ? "Get ready to take orders."
            : "Pending";
    }
  }
}
