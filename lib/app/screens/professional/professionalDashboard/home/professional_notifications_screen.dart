import 'package:clicknow_version2/app/services/notifications/fcm_notification_service.dart';
import 'package:clicknow_version2/app/services/notifications/notification_model.dart';
import 'package:clicknow_version2/app/services/notifications/notification_repository.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfessionalNotificationsScreen extends StatelessWidget {
  const ProfessionalNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final repo = NotificationRepository.instance;

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
              Padding(
                padding: ResponsiveUtility.only(
                  right: 14,
                  bottom: 8,
                  top: 10,
                  left: 10,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: ResponsiveUtility.all(6),
                        child: Icon(
                          Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtility.height(6)),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveUtility.fontSize(16),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: repo.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              Container(
                height: ResponsiveUtility.height(1),
                color: isDark ? const Color(0xFF2A3363) : const Color(0xffD9D9D9),
              ),
              Expanded(
                child: StreamBuilder<List<ClickNowNotification>>(
                  stream: repo.watchCurrentUserNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data ?? const <ClickNowNotification>[];
                    if (items.isEmpty) {
                      return _emptyState(isDark);
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: ResponsiveUtility.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: ResponsiveUtility.height(10)),
                      itemBuilder: (_, index) => _tile(items[index], isDark, repo),
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

  Widget _tile(
    ClickNowNotification item,
    bool isDark,
    NotificationRepository repo,
  ) {
    final accent = item.read ? Colors.grey : const Color(0xffBF00FF);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await repo.markRead(item.id);
        await FcmNotificationService.instance.handleNotificationData(
          <String, dynamic>{
            ...item.data,
            'type': item.type,
            'deepLinkRoute': item.deepLinkRoute,
            'notificationId': item.id,
            'campaignId': item.campaignId,
          },
        );
      },
      child: Container(
        padding: ResponsiveUtility.all(12),
        decoration: BoxDecoration(
          color: item.read
              ? (isDark ? const Color(0xff15142C) : Colors.white)
              : (isDark ? const Color(0xff25144A) : const Color(0xfffff4ff)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.read
                ? (isDark ? const Color(0xff2A3363) : const Color(0xffD9D9D9))
                : accent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.16),
              child: Icon(_iconFor(item.type), color: accent, size: 20),
            ),
            SizedBox(width: ResponsiveUtility.width(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title.isEmpty ? item.displayType : item.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight:
                                item.read ? FontWeight.w600 : FontWeight.w800,
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xffBF00FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtility.height(4)),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: ResponsiveUtility.fontSize(12),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtility.height(8)),
                  Text(
                    item.createdAt == null
                        ? ''
                        : DateFormat('dd MMM, hh:mm a').format(item.createdAt!),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: ResponsiveUtility.fontSize(11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: ResponsiveUtility.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveUtility.width(86),
              height: ResponsiveUtility.height(86),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A1149) : const Color(0xffBF00FF),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                AppImages.bellIcon,
                width: ResponsiveUtility.width(32),
                height: ResponsiveUtility.height(32),
              ),
            ),
            SizedBox(height: ResponsiveUtility.height(20)),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
            SizedBox(height: ResponsiveUtility.height(8)),
            Text(
              'We will notify you here about bookings, status and payout updates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                fontSize: ResponsiveUtility.fontSize(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('payroll') || type.startsWith('payout')) {
      return Icons.payments_rounded;
    }
    if (type.startsWith('booking')) return Icons.event_available_rounded;
    if (type.startsWith('account')) return Icons.admin_panel_settings_rounded;
    return Icons.notifications_active_rounded;
  }
}
