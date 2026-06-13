import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'getx/professionalDashboard_Controller.dart';
import 'professional_notifications_screen.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Controller instance
    final controller = Get.isRegistered<ProfessionalDashboardController>()
        ? Get.find<ProfessionalDashboardController>()
        : Get.put(ProfessionalDashboardController());

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Obx(
            () {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xffB629FF),
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// -- Header Section
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 10, top: 12, right: 12, left: 12),
                      child: _header(scale, controller, isDark),
                    ),
                    Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), thickness: 1,),

                    /// -- Visibility Card & Toggle
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 10, top: 10, right: 12, left: 12),
                      child: _visibilityCard(scale, controller, isDark),
                    ),

                    /// -- Professional Overview dashboard
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 10, top: 10, right: 12, left: 12),
                      child: Text(
                        "Professional Overview Dashboard",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: ResponsiveUtility.fontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 0, top: 0, right: 12, left: 12),
                      child: _overviewGrid(scale, controller, isDark),
                    ),
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 10, top: 10, right: 12, left: 12),
                      child: Text(
                        "Current Active Bookings",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: ResponsiveUtility.fontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: ResponsiveUtility.only(bottom: 0, top: 0, right: 12, left: 12),
                      child: _activeBookingCard(scale, controller, isDark),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, ProfessionalDashboardController controller, bool isDark) {
    final approvedLabel = controller.isApproved ? 'Approved Professional' : 'Profile Under Review';
    final approvedColor = controller.isApproved ? const Color(0xff00A63E) : const Color(0xffFFB300);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hey, ${controller.professionalName.value}",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtility.fontSize(16),
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(4)),
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: approvedColor,
                    size: ResponsiveUtility.width(14),
                  ),
                  SizedBox(width: ResponsiveUtility.width(4)),
                  Text(
                    approvedLabel,
                    style: TextStyle(
                      color: approvedColor,
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Get.to(() => const ProfessionalNotificationsScreen()),
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: ResponsiveUtility.height(42),
                width: ResponsiveUtility.width(42),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff202020) : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    AppImages.bellIcon,
                    width: ResponsiveUtility.width(22),
                    height: ResponsiveUtility.height(22),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                right: -ResponsiveUtility.width(2),
                top: -ResponsiveUtility.height(4),
                child: Container(
                  height: ResponsiveUtility.height(16),
                  width: ResponsiveUtility.width(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff6C3DFF) : Color(0xff700095),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "6",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtility.fontSize(8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _visibilityCard(ScalingUtility scale, ProfessionalDashboardController controller, bool isDark) {
    final toggleEnabled = controller.isAvailableForBooking.value;
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(left: 12, right: 12, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1C1841) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, color: isDark ? Color(0xffD000FF) : Colors.black.withValues(alpha: 0.6), size: 18,),
              SizedBox(width: ResponsiveUtility.width(8)),
              Expanded(
                child: Text(
                  "Visibility & Available For Booking.",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveUtility.height(28),
                child: AbsorbPointer(
                  absorbing: controller.isToggleUpdating.value,
                  child: Switch(
                    value: toggleEnabled,
                    onChanged: (value) => controller.toggleVisibility(value),
                    activeThumbColor: isDark ? Color(0xff7CFC00) : Color(0xff00C950),
                    activeTrackColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                    inactiveThumbColor: isDark ? Color(0xff9F9F9F) : Color(0xff8E8E8E),
                    inactiveTrackColor: isDark ? Color(0xff2A2A2A).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(2)),
          Padding(
            padding: ResponsiveUtility.only(right: 40),
            child: Text(
              controller.isApproved
                  ? "When enabled, your profile is visible for admin booking allotment. Turn it off anytime to stay offline."
                  : "Your professional profile is under admin review. Our team is currently reviewing your professional credentials. This usually takes 24-48 hours. You will get notified as we proceed.",
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.62) : Colors.black.withValues(alpha: 0.6),
                fontSize: ResponsiveUtility.fontSize(12),
                height: 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewGrid(
    ScalingUtility scale,
    ProfessionalDashboardController controller,
    bool isDark
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: ResponsiveUtility.height(8),
      crossAxisSpacing: ResponsiveUtility.width(8),
      childAspectRatio: 2.4,
      children: [
        _metricCard(scale, "Today's Booking.", controller.todaysBookings.value.toString(), "bookings", isDark),
        _metricCard(scale, "Upcoming Bookings.", controller.upcomingBookings.value.toString(), "bookings", isDark),
        _metricCard(scale, "Pending Acceptance.", controller.pendingAcceptance.value.toString(), "bookings", isDark),
        _metricCard(scale, "Monthly Revenue.", _formatCurrency(controller.monthlyRevenue.value), "Rs.", isDark),
      ],
    );
  }

  Widget _metricCard(
    ScalingUtility scale,
    String title,
    String value,
    String suffix,
    bool isDark,
  ) {
    return Container(
      padding: ResponsiveUtility.only(right: 10, bottom: 8, top: 8, left: 10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: isDark ? Color(0xffD000FF) : Colors.black.withValues(alpha: 0.6), size: 16,),
              SizedBox(width: ResponsiveUtility.width(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: ResponsiveUtility.fontSize(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtility.fontSize(20),
                ),
              ),
              SizedBox(width: scale.getScaledWidth(4)),
              Text(
                suffix,
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                  fontSize: ResponsiveUtility.fontSize(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeBookingCard(ScalingUtility scale, ProfessionalDashboardController controller, bool isDark) {
    final bookings = controller.currentActiveBookings;
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(left: 12, top: 12, bottom: 12, right: 12),
      decoration: BoxDecoration(
        color:  isDark ? Color(0xff1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        children: bookings.isEmpty
            ? [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xffF2A616),
                  child: const Icon(Icons.hourglass_top, color: Colors.white, size: 20),
                ),
                SizedBox(height: ResponsiveUtility.height(8)),
                Text(
                  'No Running Bookings',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                Text(
                  'Assigned, confirmed, and in-progress bookings will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                    fontSize: ResponsiveUtility.fontSize(12),
                    height: 1.4,
                  ),
                ),
              ]
            : bookings
                .map(
                  (booking) => Padding(
                    padding: EdgeInsets.only(
                      bottom: booking == bookings.last ? 0 : ResponsiveUtility.height(10),
                    ),
                    child: _professionalActiveBookingTile(scale, booking, isDark),
                  ),
                )
                .toList(growable: false),
      ),
    );
  }

  Widget _professionalActiveBookingTile(
    ScalingUtility scale,
    ProfessionalDashboardBooking booking,
    bool isDark,
  ) {
    final statusColor = Color(booking.statusColor);
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff12102B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xff2A3363) : const Color(0xffE1E1E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
              ),
              Container(
                padding: ResponsiveUtility.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(10),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(3)),
          Text(
            'Booking ID: ${booking.bookingCode}',
            style: TextStyle(
              color: isDark ? const Color(0xff61FF9A) : const Color(0xff00A63E),
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtility.fontSize(11),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(6)),
          _activeBookingLine('Event', booking.eventName, isDark),
          _activeBookingLine('Location', booking.location, isDark),
          _activeBookingLine('Date & Time', booking.dateAndTime, isDark),
          SizedBox(height: ResponsiveUtility.height(6)),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.amount} inc.GST',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
                size: scale.getScaledWidth(18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeBookingLine(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtility.height(2)),
      child: Text(
        '- $label : $value',
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.68) : Colors.black.withValues(alpha: 0.64),
          fontSize: ResponsiveUtility.fontSize(12),
          height: 1.25,
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    return NumberFormat.decimalPattern('en_IN').format(value);
  }
}
