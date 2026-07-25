import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/customers/getx/admin_customers_controller.dart';
import 'package:clicknow_version2/app/screens/admin/customers/models/admin_customer.dart';
import 'package:clicknow_version2/app/screens/admin/shared/admin_user_summary.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key, required this.customer});

  final AdminCustomer customer;

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = Get.find<AdminCustomersController>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? const Color(0xff0D0718) : const Color(0xffF6F4FA),
      appBar: AppBar(
        title: Text('Customer Details', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xff6F18A8),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(customer.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('Customer not found.'));
          }
          final current = AdminCustomer.fromDoc(doc);
          return SingleChildScrollView(
            padding: EdgeInsets.all(scale.getScaledWidth(14)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    _profileCard(context, current, scale),
                    const SizedBox(height: 12),
                    _detailsCard(
                      context,
                      title: 'Customer Information',
                      icon: Icons.person_outline,
                      rows: <_InfoRow>[
                        _InfoRow('Phone Number', _value(current.phoneNumber)),
                        _InfoRow('Address', current.addressLine),
                        _InfoRow(
                          'Profile Completion',
                          current.profileCompleted ? 'Completed' : 'Pending',
                        ),
                        _InfoRow('Account Status', current.accountStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _actionSection(
                      context,
                      title: 'Account Control',
                      subtitle:
                          'Control access without deleting booking history.',
                      children: _accountActions(context, controller, current),
                    ),
                    const SizedBox(height: 12),
                    _summarySection(context, current.uid),
                    const SizedBox(height: 12),
                    _actionSection(
                      context,
                      title: 'Related Records',
                      subtitle: 'Open records associated with this customer.',
                      children: <Widget>[
                        _routeButton(
                          'View Customer Bookings',
                          Icons.event_note,
                          AppRoutes.adminBookingsRoute,
                          current.uid,
                        ),
                        _routeButton(
                          'View Support Tickets',
                          Icons.support_agent,
                          AppRoutes.adminSupportDisputesRoute,
                          current.uid,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _accountActions(
    BuildContext context,
    AdminCustomersController controller,
    AdminCustomer current,
  ) {
    if (current.accountStatus == 'BLOCKED') {
      return <Widget>[
        _customerActionButton(
          controller: controller,
          customer: current,
          action: AdminCustomerAction.unblock,
          label: 'Unblock / Reactivate Customer',
          icon: Icons.lock_open_rounded,
          color: const Color(0xff20A464),
          onTap: () => _confirmAndRun(
            context,
            title: 'Unblock Customer',
            message: 'Unblock and restore access for this customer?',
            run: () => controller.manageCustomer(
              customer: current,
              action: AdminCustomerAction.unblock,
            ),
          ),
        ),
      ];
    }
    if (current.accountStatus == 'SUSPENDED') {
      return <Widget>[
        _customerActionButton(
          controller: controller,
          customer: current,
          action: AdminCustomerAction.reactivate,
          label: 'Reactivate Customer',
          icon: Icons.play_circle_outline,
          color: const Color(0xff20A464),
          onTap: () => _confirmAndRun(
            context,
            title: 'Reactivate Customer',
            message: 'Restore access for this customer?',
            run: () => controller.manageCustomer(
              customer: current,
              action: AdminCustomerAction.reactivate,
            ),
          ),
        ),
        _reasonAction(
          context,
          controller,
          current,
          AdminCustomerAction.block,
          'Block Customer',
          Icons.block,
          const Color(0xffD83545),
        ),
      ];
    }
    return <Widget>[
      _reasonAction(
        context,
        controller,
        current,
        AdminCustomerAction.suspend,
        'Suspend Customer',
        Icons.pause_circle_outline,
        const Color(0xffE58A00),
      ),
      _reasonAction(
        context,
        controller,
        current,
        AdminCustomerAction.block,
        'Block Customer',
        Icons.block,
        const Color(0xffD83545),
      ),
    ];
  }

  Widget _summarySection(BuildContext context, String uid) {
    return _actionSection(
      context,
      title: 'Activity Summary',
      subtitle: 'Bookings and support context at a glance.',
      children: <Widget>[
        FutureBuilder<AdminUserSummary>(
          future: AdminUserSummaryService.instance.load(
            userId: uid,
            role: 'customer',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 220,
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final summary = snapshot.data;
            if (summary == null) {
              return const Text('Summary is temporarily unavailable.');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric(context, 'Bookings', summary.totalBookings),
                _metric(context, 'Active', summary.activeBookings),
                _metric(context, 'Completed', summary.completedBookings),
                _metric(context, 'Rejected', summary.rejectedBookings),
                _metric(context, 'Open Tickets', summary.openSupportTickets),
                _metric(context, 'Resolved', summary.resolvedSupportTickets),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _metric(BuildContext context, String label, int value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 130,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _reasonAction(
    BuildContext context,
    AdminCustomersController controller,
    AdminCustomer customer,
    AdminCustomerAction action,
    String label,
    IconData icon,
    Color color,
  ) {
    return _customerActionButton(
      controller: controller,
      customer: customer,
      action: action,
      label: label,
      icon: icon,
      color: color,
      onTap: () async {
        final reason = await _askReason(context, label);
        if (reason == null) return;
        await controller.manageCustomer(
          customer: customer,
          action: action,
          reason: reason,
        );
      },
    );
  }

  Widget _customerActionButton({
    required AdminCustomersController controller,
    required AdminCustomer customer,
    required AdminCustomerAction action,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Obx(
      () => _actionButton(
        label: label,
        icon: icon,
        color: color,
        loading: controller.isActionLoading(customer.uid, action),
        onTap: onTap,
      ),
    );
  }

  Widget _routeButton(
    String label,
    IconData icon,
    String route,
    String uid, {
    String? tab,
  }) {
    return _actionButton(
      label: label,
      icon: icon,
      color: const Color(0xff6746D7),
      loading: false,
      onTap: () => Get.toNamed(
        route,
        arguments: <String, dynamic>{
          'targetUserId': uid,
          if (tab != null) 'tab': tab,
        },
      ),
    );
  }

  Widget _actionSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 245,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: color.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _profileCard(
    BuildContext context,
    AdminCustomer current,
    ScalingUtility scale,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: scale.getScaledWidth(24),
            backgroundColor: const Color(0xff6746D7),
            child: Text(
              current.fullName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _customerCode(current.uid),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _statusChip(current.accountStatus),
        ],
      ),
    );
  }

  Widget _detailsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'ACTIVE'
        ? const Color(0xff20A464)
        : status == 'SUSPENDED'
        ? const Color(0xffE58A00)
        : const Color(0xffD83545);
    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }

  Future<String?> _askReason(BuildContext context, String title) async {
    final text = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mandatory reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = text.text.trim();
              if (reason.isNotEmpty) Navigator.pop(context, reason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    text.dispose();
    return result;
  }

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function() run,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) await run();
  }

  String _customerCode(String uid) =>
      'CU${uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase().padLeft(6, '0').substring(0, 6)}';
  String _value(String value) => value.trim().isEmpty ? '-' : value.trim();
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}
