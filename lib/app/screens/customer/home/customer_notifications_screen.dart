import 'package:clicknow_version2/app/services/notifications/fcm_notification_service.dart';
import 'package:clicknow_version2/app/services/notifications/notification_model.dart';
import 'package:clicknow_version2/app/services/notifications/notification_repository.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final isDark = HelperFunctions.isDarkMode(context);
    final repo = NotificationRepository.instance;

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
            children: [
              _header(scale, isDark, repo),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF2A3363) : const Color(0xFFD9D9D9),
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
                      return _emptyState(scale, isDark);
                    }
                    return RefreshIndicator(
                      onRefresh: () async {},
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: ResponsiveUtility.all(12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: ResponsiveUtility.height(10)),
                        itemBuilder: (context, index) => _notificationTile(
                          context,
                          items[index],
                          isDark,
                          repo,
                        ),
                      ),
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

  Widget _header(
    ScalingUtility scale,
    bool isDark,
    NotificationRepository repo,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(10),
        scale.getScaledWidth(14),
        scale.getScaledHeight(8),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : AppColors.black,
              ),
            ),
          ),
          SizedBox(width: scale.getScaledWidth(6)),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
          ),
          TextButton(
            onPressed: repo.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
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
          _dataFromNotification(item),
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
                            fontWeight: item.read
                                ? FontWeight.w600
                                : FontWeight.w800,
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
                    _formatDate(item.createdAt),
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

  Widget _emptyState(ScalingUtility scale, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white54 : const Color(0xffBF00FF),
              size: scale.getScaledWidth(72),
            ),
            SizedBox(height: scale.getScaledHeight(16)),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: scale.getScaledFont(18),
              ),
            ),
            SizedBox(height: scale.getScaledHeight(6)),
            Text(
              'Updates about your bookings, payments, refunds, and offers will appear here.',
              textAlign: TextAlign.center,
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
    );
  }

  IconData _iconFor(String type) {
    if (type.startsWith('booking')) return Icons.event_available_rounded;
    if (type.startsWith('refund')) return Icons.currency_rupee_rounded;
    if (type.startsWith('account')) return Icons.admin_panel_settings_rounded;
    return Icons.notifications_active_rounded;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('dd MMM, hh:mm a').format(value);
  }

  Map<String, dynamic> _dataFromNotification(ClickNowNotification item) {
    return <String, dynamic>{
      ...item.data,
      'type': item.type,
      'deepLinkRoute': item.deepLinkRoute,
      'notificationId': item.id,
      'campaignId': item.campaignId,
    };
  }
}
