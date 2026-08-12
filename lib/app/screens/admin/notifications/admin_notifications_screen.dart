import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/notifications/getx/admin_notifications_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/services/notifications/notification_model.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = Get.isRegistered<AdminNotificationsController>() ? Get.find<AdminNotificationsController>() : Get.put(AdminNotificationsController());

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminNotificationsRoute,
        ),
        body: Column(
          children: <Widget>[
            _header(scale),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  scale.getScaledWidth(14),
                  scale.getScaledHeight(14),
                  scale.getScaledWidth(14),
                  scale.getScaledHeight(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _composeCard(context, scale, controller),
                    SizedBox(height: scale.getScaledHeight(16)),
                    _campaignHistory(scale, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(60),
        scale.getScaledWidth(12),
        scale.getScaledHeight(12),
      ),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: <Widget>[
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              splashRadius: 22,
              icon: Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: scale.getScaledWidth(28),
              ),
            ),
          ),
          SizedBox(width: scale.getScaledWidth(4)),
          Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: scale.getScaledFont(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composeCard(
    BuildContext context,
    ScalingUtility scale,
    AdminNotificationsController controller,
  ) {
    return _card(
      scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _title(scale, 'Push Custom Notification'),
          SizedBox(height: scale.getScaledHeight(12)),
          _textField(controller.titleController, 'Title'),
          SizedBox(height: scale.getScaledHeight(10)),
          _textField(controller.bodyController, 'Message', maxLines: 4),
          SizedBox(height: scale.getScaledHeight(10)),
          Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.recipientType.value,
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Audience'),
              style: const TextStyle(color: Colors.black54),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(
                  value: 'all_customers',
                  child: Text('All Customers'),
                ),
                DropdownMenuItem(
                  value: 'all_professionals',
                  child: Text('All Professionals'),
                ),
                DropdownMenuItem(
                  value: 'selected_users',
                  child: Text('Selected Users'),
                ),
              ],
              onChanged: (value) {
                if (value != null) controller.recipientType.value = value;
              },
            ),
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          Obx(() {
            if (controller.recipientType.value != 'selected_users') {
              return const SizedBox.shrink();
            }
            return Column(
              children: <Widget>[
                _textField(
                  controller.selectedUserIdsController,
                  'Selected user IDs, comma separated',
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserPicker(context, controller),
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Pick Users'),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(10)),
              ],
            );
          }),
          _textField(
            controller.imageUrlController,
            'Image URL (optional)',
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          _textField(
            controller.deepLinkController,
            'Deep link route (optional)',
          ),
          SizedBox(height: scale.getScaledHeight(14)),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffBF00FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: scale.getScaledHeight(13),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: controller.isSending.value ? null : controller.send,
                icon: controller.isSending.value
                    ? SizedBox(
                        width: scale.getScaledWidth(16),
                        height: scale.getScaledWidth(16),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(controller.isSending.value ? 'Sending...' : 'Send Notification'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignHistory(
    ScalingUtility scale,
    AdminNotificationsController controller,
  ) {
    return _card(
      scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _title(scale, 'Recent Campaigns'),
          SizedBox(height: scale.getScaledHeight(10)),
          StreamBuilder<List<NotificationCampaign>>(
            stream: controller.watchCampaigns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final campaigns = snapshot.data ?? const <NotificationCampaign>[];
              if (campaigns.isEmpty) {
                return const Text(
                  'No notification campaigns sent yet.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: campaigns
                    .map(
                      (campaign) => Container(
                        margin: EdgeInsets.only(bottom: scale.getScaledHeight(8)),
                        padding: EdgeInsets.all(scale.getScaledWidth(10)),
                        decoration: BoxDecoration(
                          color: Color(0xffF6F4FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Color(0xffD9D9D9)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.campaign_outlined, color: Colors.black),
                            SizedBox(width: scale.getScaledWidth(10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    campaign.title,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${campaign.recipientType} . ${campaign.status}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  if (campaign.createdAt != null)
                                    Text(
                                      DateFormat('dd MMM, hh:mm a')
                                          .format(campaign.createdAt!),
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${campaign.successCount}/${campaign.totalTokens}',
                              style: const TextStyle(
                                color: Color(0xff4AFF8F),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showUserPicker(
    BuildContext context,
    AdminNotificationsController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xff150821),
      builder: (_) => SafeArea(
        child: StreamBuilder<List<AdminNotificationUserOption>>(
          stream: controller.watchUserOptions(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? const <AdminNotificationUserOption>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (_, index) {
                final user = users[index];
                return ListTile(
                  onTap: () => controller.toggleSelectedUser(user.uid),
                  leading: const Icon(Icons.person_outline, color: Colors.white70),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${user.role}${user.phone.isEmpty ? '' : ' . ${user.phone}'}\n${user.uid}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _card(ScalingUtility scale, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.getScaledWidth(14)),
      decoration: BoxDecoration(
        color: Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _title(ScalingUtility scale, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w800,
        fontSize: scale.getScaledFont(16),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Color(0xffF6F4FF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffBF00FF)),
      ),
    );
  }
}
