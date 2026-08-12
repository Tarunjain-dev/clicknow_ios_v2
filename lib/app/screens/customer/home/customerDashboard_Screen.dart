import 'dart:async';
import 'package:clicknow_version2/app/screens/customer/getx/customer_booking_controller.dart';
import 'package:clicknow_version2/app/screens/customer/getx/customer_bookings_tab_controller.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_booking_details_screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_checkout_screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_notifications_screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/anchor/professionalAnchorServices_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/dj/professionalDjService_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/magicians/professionalMagicianServices_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/music/musicAndLivePerformance_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/photoAndVideography/photoAndVideoGraphy_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/services/weddingPlanner/weddingPlannerAndManagement_Screen.dart';
import 'package:clicknow_version2/app/services/notifications/notification_repository.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/screens/customer/profile/getx/customer_profile_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Customer dashboard controller instance
    final controller = Get.isRegistered<CustomerDashboardController>() ? Get.find<CustomerDashboardController>() : Get.put(CustomerDashboardController());
    controller.ensureActiveBookingsListener();

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveUtility.only(
              left: 14,
              top: 14,
              right: 14,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- Dashboard Header
                _DashboardHeader(
                  controller: controller,
                  scale: scale,
                  isDark: isDark,
                ),
                SizedBox(height: ResponsiveUtility.height(10)),
                _sectionTitle(scale, 'Features Services', isDark),
                SizedBox(height: ResponsiveUtility.height(6)),
                _featuredBanner(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _sectionTitle(scale, 'Services At ClickNow', isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _serviceGrid(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _sectionTitle(scale, 'Active Bookings', isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                Obx(() {
                  if (controller.isActiveBookingsLoading.value &&
                      controller.activeBookings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: CircularProgressIndicator(
                          color: Color(0xffC500FF),
                        ),
                      ),
                    );
                  }
                  if (controller.activeBookings.isEmpty) {
                    return _emptyActiveBookings(scale, isDark);
                  }
                  return Column(
                    children: controller.activeBookings
                        .map(
                          (booking) => Padding(
                            padding: ResponsiveUtility.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  controller.openActiveBooking(booking),
                              child: _activeBookingCard(scale, booking, isDark),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ScalingUtility scale, String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveUtility.fontSize(14),
      ),
    );
  }

  Widget _featuredBanner(
    ScalingUtility scale,
    CustomerDashboardController controller,
    bool isDark,
  ) {
    return Column(
      children: [
        SizedBox(
          height: ResponsiveUtility.height(126),
          child: PageView.builder(
            itemCount: controller.banners.length,
            onPageChanged: controller.onBannerChanged,
            itemBuilder: (_, index) {
              final banner = controller.banners[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.onServiceTap(banner.serviceId),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(banner.imagePath, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Color(0x5F000000).withValues(alpha: 0.0),
                                      Color(0xCC000000).withValues(alpha: 0.6),
                                    ]
                                  : [
                                      Color(0x5F000000).withValues(alpha: 0.0),
                                      Color(0xCC000000).withValues(alpha: 0.3),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: ResponsiveUtility.width(10),
                          right: ResponsiveUtility.width(10),
                          bottom: ResponsiveUtility.height(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: ResponsiveUtility.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Color(
                                          0xFF1E1C2F,
                                        ).withValues(alpha: 0.85)
                                      : Color(
                                          0xFF1E1C2F,
                                        ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      AppImages.fire,
                                      width: ResponsiveUtility.width(12),
                                      height: ResponsiveUtility.height(12),
                                    ),
                                    SizedBox(width: ResponsiveUtility.width(4)),
                                    Text(
                                      'Most Booked',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontSize: ResponsiveUtility.fontSize(
                                          12,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtility.height(2)),
                              Text(
                                banner.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: ResponsiveUtility.fontSize(16),
                                ),
                              ),
                              Text(
                                banner.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: ResponsiveUtility.fontSize(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(8)),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              controller.banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.symmetric(
                  horizontal: scale.getScaledWidth(2),
                ),
                width: controller.currentBannerIndex.value == index
                    ? ResponsiveUtility.width(24)
                    : ResponsiveUtility.width(7),
                height: ResponsiveUtility.height(7),
                decoration: BoxDecoration(
                  color: controller.currentBannerIndex.value == index
                      ? isDark
                            ? const Color(0xFFD100FF)
                            : const Color(0xFF700095)
                      : isDark
                      ? Colors.white54
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _serviceGrid(
    ScalingUtility scale,
    CustomerDashboardController controller,
    bool isDark,
  ) {
    return GridView.builder(
      itemCount: controller.services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ResponsiveUtility.width(8),
        mainAxisSpacing: ResponsiveUtility.height(8),
        childAspectRatio: 0.56,
      ),
      itemBuilder: (_, index) {
        final service = controller.services[index];
        return InkWell(
          onTap: () => controller.onServiceTap(service.id),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Color(0xFF111225).withValues(alpha: 0.95)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Color(0xFF222B4B) : Color(0xFFD9D9D9),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          child: Image.asset(
                            service.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: ResponsiveUtility.height(4),
                        right: ResponsiveUtility.width(4),
                        child: Container(
                          padding: ResponsiveUtility.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2A2B3E,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: const Color(0xFFFFC400),
                                size: scale.getScaledWidth(10),
                              ),
                              SizedBox(width: scale.getScaledWidth(2)),
                              Obx(
                                () => Text(
                                  controller.ratingForService(
                                    service.catalogServiceId,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: scale.getScaledFont(10),
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
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: ResponsiveUtility.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: ResponsiveUtility.fontSize(12),
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          service.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.58)
                                : Colors.black.withValues(alpha: 0.58),
                            fontSize: ResponsiveUtility.fontSize(10),
                            height: 1.0,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(() {
                                final lowestPrice = controller
                                    .getLowestPriceForService(service.id);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Starting from',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.55,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.55,
                                              ),
                                        fontSize: ResponsiveUtility.fontSize(
                                          8.8,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Rs.${controller.formatAmount(lowestPrice)}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: ResponsiveUtility.fontSize(
                                          11,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.7),
                              size: scale.getScaledWidth(16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _activeBookingCard(
    ScalingUtility scale,
    DashboardBooking booking,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xFF151233).withValues(alpha: 0.95)
            : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: ResponsiveUtility.only(
              left: 10,
              top: 9,
              right: 10,
              bottom: 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(16),
                    ),
                  ),
                ),
                Container(
                  padding: ResponsiveUtility.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF143B1F) : Color(0xffE4FFD2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Color(0xFF2ED669) : Color(0xff00A63E),
                    ),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: isDark ? Color(0xFF61FF9A) : Color(0xff00A63E),
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: ResponsiveUtility.symmetric(horizontal: 10),
            child: Text(
              'Booking ID: ${booking.bookingId}',
              style: TextStyle(
                color: isDark ? Color(0xFF2ED669) : Color(0xff00A63E),
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtility.fontSize(12),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtility.width(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bookingLine(scale, 'Event : ${booking.eventName}', isDark),
                _bookingLine(
                  scale,
                  'Professional type : ${booking.professionalType}',
                  isDark,
                ),
                _bookingLine(scale, 'Location : ${booking.location}', isDark),
                _bookingLine(
                  scale,
                  'Date & Time : ${booking.dateTime}',
                  isDark,
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          Container(
            height: 1,
            color: isDark
                ? Color(0xFF2A3363).withValues(alpha: 0.8)
                : Color(0xffD9D9D9),
          ),
          Padding(
            padding: ResponsiveUtility.only(
              left: 10,
              top: 8,
              right: 10,
              bottom: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking.amount} inc.GST',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.black.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDark ? Colors.white : AppColors.black,
                  size: scale.getScaledWidth(18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingLine(ScalingUtility scale, String text, bool isDark) {
    return Text(
      '- $text',
      style: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.66)
            : Colors.black.withValues(alpha: 0.66),
        fontSize: ResponsiveUtility.fontSize(12),
      ),
    );
  }

  Widget _emptyActiveBookings(ScalingUtility scale, bool isDark) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151233).withValues(alpha: 0.95)
            : const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3363) : const Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: isDark ? Colors.white70 : Colors.black45,
            size: ResponsiveUtility.width(30),
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          Text(
            'No active bookings yet',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtility.fontSize(14),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          Text(
            'Your live booking requests and upcoming confirmed bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.controller,
    required this.scale,
    required this.isDark,
  });

  final CustomerDashboardController controller;
  final ScalingUtility scale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final profileController = CustomerProfileController.instance;
    return Row(
      children: [
        Obx(
          () => Container(
            width: ResponsiveUtility.width(46),
            height: ResponsiveUtility.height(46),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF5C86A),
                width: ResponsiveUtility.width(2),
              ),
            ),
            child: ClipOval(
              child: _HeaderProfileImage(
                imageUrl: profileController.profileImageUrl.value,
                scale: scale,
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtility.width(10)),
        Expanded(
          child: Obx(() {
            final isGuest = profileController.isGuestUser.value;
            final resolvedName = isGuest
                ? 'Guest User'
                : (profileController.fullName.value.trim().isEmpty
                      ? 'Customer'
                      : profileController.fullName.value.trim());
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black.withValues(alpha: 0.72),
                    fontSize: ResponsiveUtility.fontSize(10),
                  ),
                ),
                Text(
                  resolvedName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
              ],
            );
          }),
        ),
        Obx(
          () => _HeaderActionIcon(
            scale: scale,
            imagePath: AppImages.cart,
            badgeCount: controller.cartCount.value,
            onTap: () {
              controller.onCartTap();
            },
          ),
        ),
        SizedBox(width: ResponsiveUtility.width(8)),
        Obx(
          () => _HeaderActionIcon(
            scale: scale,
            imagePath: AppImages.bellIcon,
            badgeCount: controller.notificationCount.value,
            onTap: controller.onNotificationTap,
          ),
        ),
      ],
    );
  }
}

class _HeaderProfileImage extends StatelessWidget {
  const _HeaderProfileImage({required this.imageUrl, required this.scale});

  final String imageUrl;
  final ScalingUtility scale;

  @override
  Widget build(BuildContext context) {
    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Image.asset(AppImages.avtar2, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: isDark ? AppColors.primaryColor : Colors.black26,
          alignment: Alignment.center,
          child: SizedBox(
            width: ResponsiveUtility.width(14),
            height: ResponsiveUtility.height(14),
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        return Image.asset(AppImages.avtar2, fit: BoxFit.cover);
      },
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.scale,
    required this.imagePath,
    required this.badgeCount,
    required this.onTap,
  });

  final ScalingUtility scale;
  final String imagePath;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: ResponsiveUtility.width(38),
            height: ResponsiveUtility.height(38),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Color(0xFF202330)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              imagePath,
              width: ResponsiveUtility.width(18),
              height: ResponsiveUtility.height(18),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -ResponsiveUtility.height(4),
              right: -ResponsiveUtility.width(4),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: ResponsiveUtility.width(16),
                  minHeight: ResponsiveUtility.height(16),
                ),
                padding: ResponsiveUtility.symmetric(
                  horizontal: 4,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF6E16E5) : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomerDashboardController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxInt cartCount = 0.obs;
  final RxInt notificationCount = 0.obs;
  final RxInt currentBannerIndex = 0.obs;
  final RxMap<String, int> lowestServicePriceMap = <String, int>{}.obs;
  final RxMap<String, double> serviceRatingMap = <String, double>{}.obs;
  final RxBool isActiveBookingsLoading = true.obs;
  final RxList<DashboardBooking> activeBookings = <DashboardBooking>[].obs;
  final CustomerBookingController _bookingController =
      CustomerBookingController.instance;
  final CustomerBookingsTabController _bookingsTabController =
      CustomerBookingsTabController.instance;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _servicePriceSubscriptions =
      <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _serviceStatsSubscriptions =
      <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];
  Worker? _cartCountWorker;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _activeBookingSubs =
      <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
  final Map<String, List<DashboardBooking>> _activeBookingSourceCache =
      <String, List<DashboardBooking>>{};
  StreamSubscription<User?>? _authSub;
  StreamSubscription<int>? _notificationCountSub;
  Timer? _activeBookingsTimeoutTimer;
  int _activeBookingsRequestId = 0;
  Worker? _bookingsTabWorker;
  Worker? _bookingsTabLoadingWorker;

  @override
  void onInit() {
    super.onInit();
    cartCount.value = _bookingController.cartCount.value;
    _cartCountWorker = ever<int>(_bookingController.cartCount, (count) {
      cartCount.value = count;
    });
    for (final service in services) {
      lowestServicePriceMap[service.id] = 0;
    }
    _listenServiceLowestPrices();
    _listenServiceStats();
    _bindActiveBookings();
    _bindNotificationCount();
    _authSub = _auth.authStateChanges().listen((_) {
      _bindActiveBookings();
      _bindNotificationCount();
    });
    _bookingsTabWorker = ever<List<CustomerBookingStatusItem>>(
      _bookingsTabController.bookings,
      (_) => _syncActiveBookingsFromCustomerBookingTab(),
    );
    _bookingsTabLoadingWorker = ever<bool>(
      _bookingsTabController.isLoading,
      (_) => _syncActiveBookingsFromCustomerBookingTab(),
    );
    _syncActiveBookingsFromCustomerBookingTab();
  }

  final List<DashboardBanner> banners = const [
    DashboardBanner(
      serviceId: 'photo',
      title: 'Photography & Videography',
      subtitle: 'capture your timeless memories',
      imagePath: AppImages.banner1,
    ),
    DashboardBanner(
      serviceId: 'music',
      title: 'Music & Live Performance',
      subtitle: 'keep the party going all night',
      imagePath: AppImages.banner2,
    ),
    DashboardBanner(
      serviceId: 'dj',
      title: 'Professional DJ Services',
      subtitle: 'high-energy vibe for every event',
      imagePath: AppImages.banner3,
    ),
  ];

  final List<DashboardService> services = const [
    DashboardService(
      id: 'photo',
      catalogServiceId: 'photo_videography',
      title: 'Photography & Videography',
      subtitle: 'Professional Photo and video Coverage',
      imagePath: AppImages.photographer,
      rating: '4.9',
    ),
    DashboardService(
      id: 'music',
      catalogServiceId: 'music_live_performance',
      title: 'Music & Live Performance',
      subtitle: 'Live Music and Performance for Every Occasion',
      imagePath: AppImages.musician,
      rating: '4.9',
    ),
    DashboardService(
      id: 'dj',
      catalogServiceId: 'professional_dj',
      title: 'Professional DJ Services',
      subtitle: 'High-Energy DJ Music and Event Entertainment',
      imagePath: AppImages.dj,
      rating: '4.9',
    ),
    DashboardService(
      id: 'wedding',
      catalogServiceId: 'live_wedding_painter',
      title: 'Live wedding painter',
      subtitle: 'Live Artistic Wedding Moments on Canvas',
      imagePath: AppImages.weddingPlanner,
      rating: '4.9',
    ),
    DashboardService(
      id: 'anchor',
      catalogServiceId: 'professional_anchor',
      title: 'Professional Anchor Services',
      subtitle: 'Engaging Event Hosting and Stage Management',
      imagePath: AppImages.anchor,
      rating: '4.9',
    ),
    DashboardService(
      id: 'magician',
      catalogServiceId: 'professional_magician',
      title: 'Professional Magician Services',
      subtitle: 'Interactive Magic Shows and Fun Entertainment',
      imagePath: AppImages.magician,
      rating: '4.9',
    ),
  ];

  void _listenServiceLowestPrices() {
    for (final service in services) {
      final subscription = _db
          .collection(ServiceCatalogPaths.servicesCollection)
          .doc(service.catalogServiceId)
          .collection(ServiceCatalogPaths.eventTypesSubcollection)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen(
            (snapshot) {
              final lowestPrice = _lowestPriceFromSnapshot(snapshot);
              lowestServicePriceMap[service.id] = lowestPrice;
            },
            onError: (_) {
              lowestServicePriceMap[service.id] = 0;
            },
          );
      _servicePriceSubscriptions.add(subscription);
    }
  }

  void _listenServiceStats() {
    for (final service in services) {
      serviceRatingMap[service.catalogServiceId] = 0;
      final subscription = _db
          .collection(ServiceCatalogPaths.serviceStatsCollection)
          .doc(service.catalogServiceId)
          .snapshots()
          .listen(
            (snapshot) {
              serviceRatingMap[service.catalogServiceId] =
                  (snapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0;
            },
            onError: (_) {
              serviceRatingMap[service.catalogServiceId] = 0;
            },
          );
      _serviceStatsSubscriptions.add(subscription);
    }
  }

  String ratingForService(String serviceCatalogId) {
    return (serviceRatingMap[serviceCatalogId] ?? 0).toStringAsFixed(1);
  }

  int _lowestPriceFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    var lowest = 0;
    var hasPrice = false;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final prices = _extractPlanPrices(data);
      for (final price in prices) {
        if (price <= 0) {
          continue;
        }
        if (!hasPrice || price < lowest) {
          lowest = price;
          hasPrice = true;
        }
      }
    }
    return hasPrice ? lowest : 0;
  }

  List<int> _extractPlanPrices(Map<String, dynamic> data) {
    final prices = <int>[];

    final pricingPlansRaw = data['pricingPlans'];
    if (pricingPlansRaw is Map) {
      final pricingPlans = Map<String, dynamic>.from(pricingPlansRaw);
      for (final value in pricingPlans.values) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final amount = _asInt(map['price']);
          if (amount > 0) {
            prices.add(amount);
          }
        } else {
          final amount = _asInt(value);
          if (amount > 0) {
            prices.add(amount);
          }
        }
      }
    }

    // Backward-compatible parser in case plans are stored as list format.
    final plansRaw = data['plans'];
    if (plansRaw is List) {
      for (final item in plansRaw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final amount = _asInt(map['price']);
          if (amount > 0) {
            prices.add(amount);
          }
        }
      }
    }

    return prices;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  int getLowestPriceForService(String serviceId) {
    return lowestServicePriceMap[serviceId] ?? 0;
  }

  String formatAmount(int value) {
    return NumberFormat('#,##0', 'en_IN').format(value);
  }

  void _bindActiveBookings() {
    for (final sub in _activeBookingSubs) {
      sub.cancel();
    }
    _activeBookingSubs.clear();
    _activeBookingSourceCache.clear();
    _activeBookingsTimeoutTimer?.cancel();
    final requestId = ++_activeBookingsRequestId;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      activeBookings.clear();
      isActiveBookingsLoading.value = false;
      return;
    }
    isActiveBookingsLoading.value = true;
    _activeBookingsTimeoutTimer = Timer(const Duration(seconds: 2), () {
      if (requestId == _activeBookingsRequestId) {
        isActiveBookingsLoading.value = false;
      }
    });

    _listenActiveBookingSource(
      sourceKey: 'user_customer_bookings',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.usersCollection)
          .doc(uid)
          .collection(ServiceCatalogPaths.customerBookingsSubcollection),
    );
    _listenActiveBookingSource(
      sourceKey: 'bookings_customerId',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.bookingsCollection)
          .where('customerId', isEqualTo: uid),
    );
    _listenActiveBookingSource(
      sourceKey: 'bookings_userId',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.bookingsCollection)
          .where('userId', isEqualTo: uid),
    );
    _listenActiveBookingSource(
      sourceKey: 'bookings_customer_id',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.bookingsCollection)
          .where('customer.id', isEqualTo: uid),
    );
    _listenActiveBookingSource(
      sourceKey: 'requests_customerId',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('customerId', isEqualTo: uid),
    );
    _listenActiveBookingSource(
      sourceKey: 'requests_userId',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('userId', isEqualTo: uid),
    );
    _listenActiveBookingSource(
      sourceKey: 'requests_customer_id',
      requestId: requestId,
      query: _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('customer.id', isEqualTo: uid),
    );
  }

  void _syncActiveBookingsFromCustomerBookingTab() {
    final inProgress = _bookingsTabController.bookings
        .where((item) => _isCustomerStatusItemInProgress(item))
        .map(DashboardBooking.fromCustomerStatusItem)
        .toList(growable: false);
    _activeBookingSourceCache['customer_bookings_tab'] = inProgress;
    _applyMergedActiveBookings();
    if (!_bookingsTabController.isLoading.value) {
      isActiveBookingsLoading.value = false;
    }
  }

  bool _isCustomerStatusItemInProgress(CustomerBookingStatusItem item) {
    if (item.statusCode.trim().toUpperCase() == 'IN_PROGRESS') {
      return true;
    }
    final stage = item.stage.trim().toLowerCase().replaceAll(' ', '_');
    return stage == 'event_started' ||
        stage == 'service_started' ||
        stage == 'booking_started' ||
        stage == 'in_progress';
  }

  void _listenActiveBookingSource({
    required String sourceKey,
    required int requestId,
    required Query<Map<String, dynamic>> query,
  }) {
    try {
      final sub = query.snapshots().listen(
        (snapshot) {
          if (requestId != _activeBookingsRequestId) {
            return;
          }
          _activeBookingSourceCache[sourceKey] = _activeBookingsFromSnapshot(
            snapshot,
          );
          _applyMergedActiveBookings();
        },
        onError: (_) {
          if (requestId != _activeBookingsRequestId) {
            return;
          }
          _activeBookingSourceCache[sourceKey] = <DashboardBooking>[];
          _applyMergedActiveBookings();
        },
      );
      _activeBookingSubs.add(sub);
    } catch (_) {
      _activeBookingSourceCache[sourceKey] = <DashboardBooking>[];
      _applyMergedActiveBookings();
    }
  }

  List<DashboardBooking> _activeBookingsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final mapped = <DashboardBooking>[];
    for (final doc in snapshot.docs) {
      try {
        final booking = DashboardBooking.fromDoc(doc);
        if (_activeStatusCodes.contains(booking.statusCode)) {
          mapped.add(booking);
        }
      } catch (_) {
        // Ignore malformed legacy booking docs instead of blocking dashboard.
      }
    }
    mapped.sort((left, right) {
      final leftDate = left.eventDate ?? DateTime(9999);
      final rightDate = right.eventDate ?? DateTime(9999);
      return leftDate.compareTo(rightDate);
    });
    return mapped;
  }

  void _applyActiveBookings(List<DashboardBooking> mapped) {
    activeBookings.assignAll(mapped);
    isActiveBookingsLoading.value = false;
  }

  void _applyMergedActiveBookings() {
    final byId = <String, DashboardBooking>{};
    for (final bookings in _activeBookingSourceCache.values) {
      for (final booking in bookings) {
        byId[booking.mergeKey] = booking;
      }
    }
    final merged = byId.values.toList(growable: false)
      ..sort((left, right) {
        final leftDate = left.eventDate ?? DateTime(9999);
        final rightDate = right.eventDate ?? DateTime(9999);
        return leftDate.compareTo(rightDate);
      });
    _applyActiveBookings(merged);
  }

  void ensureActiveBookingsListener() {
    if (_activeBookingSubs.isEmpty) {
      _bindActiveBookings();
    }
  }

  static const Set<String> _activeStatusCodes = <String>{'IN_PROGRESS'};

  void onBannerChanged(int index) {
    currentBannerIndex.value = index;
  }

  Future<void> onCartTap() async {
    if (AuthController.isGuestModeActive) {
      await AuthController.instance.showLoginRequiredSheet();
      return;
    }
    Get.to(() => const CustomerBookingsScreen());
  }

  void onNotificationTap() {
    Get.to(() => const CustomerNotificationsScreen());
  }

  void _bindNotificationCount() {
    _notificationCountSub?.cancel();
    if (_auth.currentUser == null || AuthController.isGuestModeActive) {
      notificationCount.value = 0;
      return;
    }
    _notificationCountSub = NotificationRepository.instance
        .watchCurrentUserUnreadCount()
        .listen(
          (count) => notificationCount.value = count,
          onError: (_) => notificationCount.value = 0,
        );
  }

  void onServiceTap(String serviceId) {
    switch (serviceId) {
      case 'photo':
        Get.to(() => const PhotoAndVideographyScreen());
        break;
      case 'music':
        Get.to(() => const MusicAndLivePerformanceScreen());
        break;
      case 'dj':
        Get.to(() => const ProfessionalDjServiceScreen());
        break;
      case 'wedding':
        Get.to(() => const WeddingPlannerAndManagementScreen());
        break;
      case 'anchor':
        Get.to(() => const ProfessionalAnchorServicesScreen());
        break;
      case 'magician':
        Get.to(() => const ProfessionalMagicianServicesScreen());
        break;
      default:
        break;
    }
  }

  void openActiveBooking(DashboardBooking booking) {
    Get.to(
      () => CustomerBookingStatusScreen(
        bookingId: booking.bookingDocId,
        bookingCode: booking.bookingId,
        serviceTitle: booking.serviceName,
      ),
    );
  }

  @override
  void onClose() {
    _cartCountWorker?.dispose();
    _bookingsTabWorker?.dispose();
    _bookingsTabLoadingWorker?.dispose();
    for (final sub in _activeBookingSubs) {
      sub.cancel();
    }
    _activeBookingsTimeoutTimer?.cancel();
    _authSub?.cancel();
    _notificationCountSub?.cancel();
    for (final subscription in _servicePriceSubscriptions) {
      subscription.cancel();
    }
    for (final subscription in _serviceStatsSubscriptions) {
      subscription.cancel();
    }
    super.onClose();
  }
}

class DashboardBanner {
  const DashboardBanner({
    required this.serviceId,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String serviceId;
  final String title;
  final String subtitle;
  final String imagePath;
}

class DashboardService {
  const DashboardService({
    required this.id,
    required this.catalogServiceId,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.rating,
  });

  final String id;
  final String catalogServiceId;
  final String title;
  final String subtitle;
  final String imagePath;
  final String rating;
}

class DashboardBooking {
  const DashboardBooking({
    required this.bookingDocId,
    required this.serviceName,
    required this.bookingId,
    required this.eventName,
    required this.professionalType,
    required this.location,
    required this.dateTime,
    required this.amount,
    required this.status,
    required this.statusCode,
    required this.eventDate,
  });

  final String bookingDocId;
  final String serviceName;
  final String bookingId;
  final String eventName;
  final String professionalType;
  final String location;
  final String dateTime;
  final String amount;
  final String status;
  final String statusCode;
  final DateTime? eventDate;
  String get mergeKey =>
      bookingId.trim().isNotEmpty ? bookingId.trim() : bookingDocId.trim();

  factory DashboardBooking.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final statusCode = _statusCodeFromData(data);
    final eventDate = _asDateTime(data['eventDate']);
    final eventTime = _string(data['eventTime']);
    final city = _string(data['city']);
    final state = _string(data['state']);
    final address = _string(data['fullAddress']);
    final location = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (city.isEmpty && state.isEmpty && address.isNotEmpty) address,
    ].join(', ');
    final bookingCode = _firstNonEmptyString(<dynamic>[
      data['bookingCode'],
      data['bookingId'],
      data['requestId'],
    ]);
    return DashboardBooking(
      bookingDocId: doc.id,
      serviceName: _string(data['serviceTitle']).isEmpty
          ? 'Booking'
          : _string(data['serviceTitle']),
      bookingId: bookingCode.isEmpty
          ? 'BID-${doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length).toUpperCase()}'
          : bookingCode,
      eventName: _string(data['eventTypeName']).isEmpty
          ? '-'
          : _string(data['eventTypeName']),
      professionalType: _string(data['planName']).isEmpty
          ? '-'
          : _string(data['planName']),
      location: location.isEmpty ? '-' : location,
      dateTime: _dateTimeLabel(eventDate, eventTime),
      amount:
          'Rs. ${NumberFormat('#,##0', 'en_IN').format(_customerFinalAmount(data))}',
      status: _statusLabel(statusCode),
      statusCode: statusCode,
      eventDate: eventDate,
    );
  }

  factory DashboardBooking.fromCustomerStatusItem(
    CustomerBookingStatusItem item,
  ) {
    return DashboardBooking(
      bookingDocId: item.id,
      serviceName: item.serviceName.trim().isEmpty
          ? 'Booking'
          : item.serviceName.trim(),
      bookingId: item.bookingCode.trim().isEmpty ? item.id : item.bookingCode,
      eventName: item.eventName.trim().isEmpty ? '-' : item.eventName.trim(),
      professionalType: item.professionalType.trim().isEmpty
          ? '-'
          : item.professionalType.trim(),
      location: item.location.trim().isEmpty ? '-' : item.location.trim(),
      dateTime: item.dateTime.trim().isEmpty ? '-' : item.dateTime.trim(),
      amount: item.amount.trim().isEmpty ? 'Rs.0' : item.amount.trim(),
      status: item.status.trim().isEmpty ? 'In Progress' : item.status.trim(),
      statusCode: item.statusCode.trim().isEmpty
          ? 'IN_PROGRESS'
          : item.statusCode.trim().toUpperCase(),
      eventDate: null,
    );
  }

  static String _statusCodeFromData(Map<String, dynamic> data) {
    final stage = _normalizeStatusCode(data['bookingStage']);
    switch (stage) {
      case 'EVENT_STARTED':
      case 'SERVICE_STARTED':
      case 'BOOKING_STARTED':
      case 'IN_PROGRESS':
      case 'STARTED':
        return 'IN_PROGRESS';
    }
    final request = _asMap(data['request']);
    final requestStatus = _normalizeStatusCode(request['status']);
    switch (requestStatus) {
      case 'IN_PROGRESS':
      case 'EVENT_STARTED':
      case 'SERVICE_STARTED':
      case 'BOOKING_STARTED':
      case 'STARTED':
        return 'IN_PROGRESS';
    }
    final direct = _normalizeStatusCode(data['status']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final lifecycle = _normalizeStatusCode(data['lifecycleStatus']);
    switch (lifecycle) {
      case 'REQUESTED':
        return 'REQUESTED';
      case 'APPROVED':
      case 'ASSIGNMENT_PENDING':
      case 'RESCHEDULE_REQUESTED':
        return 'APPROVED';
      case 'ASSIGNED':
        return 'ASSIGNED';
      case 'CONFIRMED':
        return 'CONFIRMED';
      case 'IN_PROGRESS':
      case 'EVENT_STARTED':
      case 'SERVICE_STARTED':
      case 'STARTED':
        return 'IN_PROGRESS';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'REJECTED':
        return 'REJECTED';
      case 'CANCELLED':
        return 'CANCELLED';
    }
    final bookingStatus = _normalizeStatusCode(data['bookingStatus']);
    switch (bookingStatus) {
      case 'REQUESTED':
        return 'REQUESTED';
      case 'APPROVED':
        return 'APPROVED';
      case 'ASSIGNED':
        return 'ASSIGNED';
      case 'CONFIRMED':
        return 'CONFIRMED';
      case 'IN_PROGRESS':
      case 'EVENT_STARTED':
      case 'SERVICE_STARTED':
      case 'STARTED':
        return 'IN_PROGRESS';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'REJECTED':
        return 'REJECTED';
      case 'CANCELLED':
        return 'CANCELLED';
    }
    return 'REQUESTED';
  }

  static String _normalizeStatusCode(dynamic value) {
    final raw = _string(value);
    if (raw.isEmpty) {
      return '';
    }
    final normalized = raw.trim().toUpperCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    return normalized == 'CANCELED' ? 'CANCELLED' : normalized;
  }

  static String _statusLabel(String statusCode) {
    switch (statusCode) {
      case 'REQUESTED':
        return 'Requested';
      case 'APPROVED':
        return 'Approved';
      case 'ASSIGNED':
        return 'Assigned';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'IN_PROGRESS':
        return 'In Progress';
      default:
        return 'Active';
    }
  }

  static String _dateTimeLabel(DateTime? date, String time) {
    if (date == null) {
      return time.isEmpty ? '-' : time;
    }
    final dateText = DateFormat('MMM d, yyyy', 'en_IN').format(date);
    return time.trim().isEmpty ? dateText : '$dateText - ${time.trim()}';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(
          (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9-]'), ''),
        ) ??
        0;
  }

  static int _customerFinalAmount(Map<String, dynamic> data) {
    final payment = _asMap(data['payment']);
    final breakdown = _asMap(
      data['financialBreakdown'] ??
          data['pricingSnapshot'] ??
          payment['financialBreakdown'],
    );
    for (final value in <dynamic>[
      data['finalAmount'],
      data['finalCustomerPayable'],
      breakdown['finalAmount'],
      breakdown['finalCustomerPayable'],
      payment['finalAmount'],
      payment['finalPayableAmount'],
      data['totalAmount'],
      breakdown['totalAmount'],
    ]) {
      final parsed = _asInt(value);
      if (parsed > 0) {
        return parsed;
      }
    }
    return 0;
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
