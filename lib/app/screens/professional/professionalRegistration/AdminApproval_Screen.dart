import 'package:clicknow_version2/app/screens/professional/getx/admin_approval_controller.dart';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Admin Approval Controller
    final controller = Get.put(AdminApprovalController());

    return Container(
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// SUCCESS ICON
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                    const RadialGradient(
                      colors: [
                        Colors.purpleAccent,
                        Colors.deepPurple
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),

                /// TITLE
                const Text(
                  "Profile Submitted Successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your professional profile is under admin review. Our team is currently reviewing your professional credentials. This usually takes 24-48 hours. You will get notified as we proceed. ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70),
                ),
                const SizedBox(height: 30),

                /// PROGRESS CARD
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.all(16),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(0xff1C1736),
                      borderRadius:
                      BorderRadius
                          .circular(16),
                      border: Border.all(
                          color:
                          const Color(
                              0xff1E2939)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [

                        const Text(
                          "Application Progress",
                          style: TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .bold),
                        ),

                        const SizedBox(
                            height: 20),

                        Expanded(
                          child: _buildStepper(controller),
                        ),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// BUTTONS
                SizedBox(
                  width: double.infinity,
                  child: Obx(() {
                    final isApproved =
                        controller.currentStage.value ==
                            ApplicationStage.approved ||
                        controller.currentStage.value ==
                            ApplicationStage.welcomed;
                    return ElevatedButton(
                      onPressed: isApproved
                          ? () => Get.offAllNamed(
                                AppRoutes.professionalBottomNavigationRoute,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.purple3,
                                ),
                              ),
                            )
                          : Text(
                              "Go to Professional Dashboard",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purple3,
                              ),
                            ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton
                        .styleFrom(
                      side: const BorderSide(
                          color:
                          Colors.white24),
                      padding:
                      const EdgeInsets
                          .symmetric(
                          vertical: 16),
                    ),
                    child: const Text(
                      "Track Application Status",
                      style: TextStyle(
                          color:
                          Colors.white),
                    ),
                  ),
                ),
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

  Widget _buildStepper(AdminApprovalController controller) {
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
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isActive
                          ? Colors.purpleAccent
                          : Colors.grey.shade700,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),

                  if (index != stages.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.white24,
                    ),
                ],
              ),

              const SizedBox(width: 12),

              /// TEXT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(stage),
                        style: TextStyle(
                          color: isCompleted || isActive
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitle(stage, controller),
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.orange
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              )
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
      AdminApprovalController controller) {

    final isCompleted = controller.isCompleted(stage);
    final isActive = controller.isActive(stage);

    switch (stage) {
      case ApplicationStage.phoneVerified:
        return isCompleted || isActive
            ? "Completed"
            : "Pending";

      case ApplicationStage.profileSubmitted:
        return isCompleted || isActive
            ? "Completed"
            : "Pending";

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
