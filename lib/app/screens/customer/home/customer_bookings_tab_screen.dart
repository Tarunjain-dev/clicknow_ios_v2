import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/getx/customer_bookings_tab_controller.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_booking_status_screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerBookingsTabScreen extends StatelessWidget {
  const CustomerBookingsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = CustomerBookingsTabController.instance;
    final authController = AuthController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  scale.getScaledWidth(16),
                  scale.getScaledHeight(18),
                  scale.getScaledWidth(16),
                  scale.getScaledHeight(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: scale.getScaledFont(19),
                      ),
                    ),
                    SizedBox(height: scale.getScaledHeight(4)),
                    Text(
                      'View and manage your event bookings',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.68)
                            : Colors.black.withValues(alpha: 0.68),
                        fontSize: scale.getScaledFont(13),
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
              SizedBox(height: scale.getScaledHeight(10)),
              SizedBox(
                height: scale.getScaledHeight(50),
                child: Obx(() {
                  final selectedTabIndex = controller.selectedTabIndex.value;
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.getScaledWidth(10),
                      vertical: scale.getScaledHeight(6),
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.tabs.length,
                    separatorBuilder: (context, separatorIndex) =>
                        SizedBox(width: scale.getScaledWidth(8)),
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
                                horizontal: scale.getScaledWidth(14),
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? isDark
                                          ? Color(0xFFB33CF1)
                                          : Color(0xff700095)
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
                                      : Colors.black.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: scale.getScaledFont(15),
                                ),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: -scale.getScaledWidth(6),
                                top: -scale.getScaledHeight(6),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: scale.getScaledWidth(16),
                                    minHeight: scale.getScaledHeight(16),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale.getScaledWidth(4),
                                    vertical: scale.getScaledHeight(1),
                                  ),
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffFF2F43),
                                    shape: BoxShape.circle,
                                  ),
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
                  if (authController.isGuestUser.value) {
                    return _guestLockState(scale);
                  }
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: scale.getScaledWidth(44),
                            height: scale.getScaledHeight(44),
                            decoration: BoxDecoration(
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
                            'No ${controller.tabs[selectedTabIndex]} bookings.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : Colors.black.withValues(alpha: 0.72),
                              fontSize: scale.getScaledFont(14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      scale.getScaledWidth(12),
                      0,
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(12),
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, separatorIndex) =>
                        SizedBox(height: scale.getScaledHeight(10)),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return InkWell(
                        onTap: () {
                          Get.to(
                            () => CustomerBookingStatusScreen(
                              bookingId: item.id,
                              bookingCode: item.bookingCode,
                              serviceTitle: item.serviceName,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: _bookingCard(scale, item, isDark),
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

  Widget _guestLockState(ScalingUtility scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: const Color(0xFFD000FF),
              size: scale.getScaledWidth(30),
            ),
            SizedBox(height: scale.getScaledHeight(10)),
            Text(
              'Please login to continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: scale.getScaledFont(16),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: scale.getScaledHeight(6)),
            Text(
              'Bookings are available only for logged-in users.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: scale.getScaledFont(13),
              ),
            ),
            SizedBox(height: scale.getScaledHeight(12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    AuthController.instance.showLoginRequiredSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4B176F),
                ),
                child: const Text('Continue with Phone'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(
    ScalingUtility scale,
    CustomerBookingStatusItem item,
    bool isDark,
  ) {
    final statusColor = _statusColor(item.status);

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
              scale.getScaledWidth(10),
              scale.getScaledHeight(10),
              scale.getScaledWidth(10),
              scale.getScaledHeight(2),
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
                    horizontal: scale.getScaledWidth(12),
                    vertical: scale.getScaledHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(10),
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
                _point(scale, 'Price plan : ${item.professionalType}', isDark,),
                _point(scale, 'Venue : ${item.venueName.isEmpty ? 'Not provided' : item.venueName}', isDark,),
                _point(scale, 'Venue location : ${item.location}', isDark),
                _point(scale, 'Date & Time : ${item.dateTime}', isDark),
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
                    '${item.amount} inc.GST',
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
      '- $text',
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.65),
        fontSize: scale.getScaledFont(14),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return const Color(0xFFC98A2D);
      case 'approved':
        return const Color(0xFF6D8BFF);
      case 'assigned':
        return const Color(0xFF3EA7FF);
      case 'confirmed':
        return const Color(0xFF23D658);
      case 'in progress':
        return const Color(0xFF00A9FF);
      case 'completed':
        return const Color(0xFFB31CFF);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFF2F2F);
      default:
        return Colors.white70;
    }
  }
}
