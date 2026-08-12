import 'package:clicknow_version2/app/screens/professional/professionalDashboard/bookings/getx/professionalBookings_Controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/bookings/professional_booking_details_screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalBookingsScreen extends StatelessWidget {
  const ProfessionalBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Prof. Booking Controller
    final controller = ProfessionalBookingsController.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: ResponsiveUtility.only(
                  left: 16,
                  top: 18,
                  right: 16,
                  bottom: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtility.fontSize(18),
                      ),
                    ),
                    // SizedBox(height: ResponsiveUtility.height(8)),
                    Text(
                      'View and manage your event bookings',
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
              Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
              ),
              SizedBox(height: ResponsiveUtility.height(10)),
              SizedBox(
                height: ResponsiveUtility.height(36),
                child: Obx(() {
                  final selectedTabIndex = controller.selectedTabIndex.value;
                  return ListView.separated(
                    padding: ResponsiveUtility.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.tabs.length,
                    separatorBuilder: (context, separatorIndex) => SizedBox(width: ResponsiveUtility.width(8)),
                    itemBuilder: (_, index) {
                      final selected = selectedTabIndex == index;
                      final count = controller.countForTabIndex(index);
                      return GestureDetector(
                        onTap: () => controller.changeTab(index),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtility.width(12),
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? isDark
                                          ? Color(0xFFB33CF1)
                                          : Color(0xFF700095)
                                    : isDark
                                    ? Color(0xFF3A3A3F)
                                    : Color(0xFFE3E3E3).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                controller.tabs[index],
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white
                                      : Colors.black.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveUtility.fontSize(12),
                                ),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: -scale.getScaledWidth(4.5),
                                top: -scale.getScaledHeight(4.5),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: scale.getScaledWidth(16),
                                    minHeight: scale.getScaledHeight(16),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale.getScaledWidth(4),
                                    vertical: scale.getScaledHeight(6),
                                  ),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffFF2F43),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: scale.getScaledFont(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: scale.getScaledHeight(10)),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD000FF),
                      ),
                    );
                  }

                  final selectedTabIndex = controller.selectedTabIndex.value;
                  final items = controller.filteredBookingsForTab(
                    selectedTabIndex,
                  );
                  if (items.isEmpty) {
                    return _emptyState(scale, isDark);
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      scale.getScaledWidth(12),
                      0,
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(12),
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, separatorIndex) => SizedBox(height: scale.getScaledHeight(10)),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: () {
                          Get.to(
                            () => ProfessionalBookingDetailsScreen(
                              bookingItem: item,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: _bookingCard(scale, controller, item, isDark),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ScalingUtility scale, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: scale.getScaledWidth(44),
            height: scale.getScaledHeight(44),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3A91D),
            ),
            child: Icon(
              Icons.hourglass_bottom_rounded,
              color: Colors.white,
              size: scale.getScaledWidth(24),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          Text(
            'No bookings yet',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.75),
              fontSize: scale.getScaledFont(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(
    ScalingUtility scale,
    ProfessionalBookingsController controller,
    ProfessionalBookingItem item,
    bool isDark,
  ) {
    final statusColor = controller.statusColor(item.status);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF141337).withValues(alpha: 0.96)
            : Color(0xFFFCFBFF).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xFF2C2F63) : Color(0xFFD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(8),
              scale.getScaledHeight(8),
              scale.getScaledWidth(8),
              scale.getScaledHeight(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.serviceName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(12),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.getScaledWidth(10),
                    vertical: scale.getScaledHeight(2),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    controller.statusLabel(item.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(10)),
            child: Text(
              'Booking ID: ${item.bookingCode}',
              style: TextStyle(
                color: isDark ? Color(0xFF2ED669) : Color(0xFF00A63E),
                fontWeight: FontWeight.w600,
                fontSize: scale.getScaledFont(12),
              ),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _point(scale, 'Event type : ${item.eventName}', isDark),
                _point(scale, 'Price plan: ${item.professionalType}', isDark),
                _point(scale, 'Venue : ${item.venueName.isEmpty ? 'Not provided' : item.venueName}', isDark,),
                _point(scale, 'Venue Location : ${item.location}', isDark),
                _point(scale, 'Date & Time : ${item.dateAndTime}', isDark),
              ],
            ),
          ),
          SizedBox(height: scale.getScaledHeight(8)),
          Container(
            height: 1,
            color: isDark
                ? Color(0xFF2A3363).withValues(alpha: 0.8)
                : Color(0xFFD9D9D9).withValues(alpha: 1.0),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(8),
              scale.getScaledWidth(10),
              scale.getScaledHeight(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.amountWithGst,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.black.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(12),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDark ? Colors.white : Colors.black,
                  size: scale.getScaledWidth(18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(ScalingUtility scale, String text, bool isDark) {
    return Text(
      '☉ $text',
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.65),
        fontSize: scale.getScaledFont(12),
      ),
    );
  }
}
