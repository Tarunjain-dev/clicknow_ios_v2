import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/services/getx/admin_services_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = Get.put(AdminServicesController());

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminServicesRoute,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _topSection(scale, controller),
              _statsRow(scale, controller),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  if (controller.services.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffFCFBFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffD9D9D9)),
                        ),
                        child: const Text(
                          'No services available right now.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(12),
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(16),
                    ),
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      return Obx(() {
                        final isExpanded = controller.isExpanded(service.id);
                        return _serviceCard(
                          context: context,
                          scale: scale,
                          controller: controller,
                          service: service,
                          isExpanded: isExpanded,
                        );
                      });
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

  Widget _topSection(
    ScalingUtility scale,
    AdminServicesController controller,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(8),
        scale.getScaledWidth(12),
        scale.getScaledHeight(12),
      ),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scale.getScaledFont(20 / 1.2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Manage services, event types & pricing.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: scale.getScaledFont(12),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final gst = controller.gstPercent.value;
            return InkWell(
              onTap: () => _showGstDialog(controller, gst),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.getScaledWidth(12),
                  vertical: scale.getScaledHeight(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFEDE0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'GST ${_formatGst(gst)}%',
                  style: TextStyle(
                    color: const Color(0xffFF8C00),
                    fontWeight: FontWeight.w600,
                    fontSize: scale.getScaledFont(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statsRow(
    ScalingUtility scale,
    AdminServicesController controller,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.getScaledWidth(12),
        vertical: scale.getScaledHeight(8),
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Obx(() {
        return Row(
          children: [
            _statItem(
              scale,
              const Color(0xff00E47C),
              '${controller.activeEventTypes} active',
            ),
            SizedBox(width: scale.getScaledWidth(14)),
            _statItem(
              scale,
              const Color(0xff4B9DFF),
              '${controller.totalEventTypes} total types',
            ),
            SizedBox(width: scale.getScaledWidth(14)),
            _statItem(
              scale,
              const Color(0xffC055FF),
              '${controller.services.length} services',
            ),
          ],
        );
      }),
    );
  }

  Widget _statItem(ScalingUtility scale, Color color, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: scale.getScaledWidth(4)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.86),
                fontSize: scale.getScaledFont(13),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required BuildContext context,
    required ScalingUtility scale,
    required AdminServicesController controller,
    required AdminServiceModel service,
    required bool isExpanded,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => controller.toggleExpanded(service.id),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                scale.getScaledWidth(8),
                scale.getScaledHeight(8),
                scale.getScaledWidth(10),
                scale.getScaledHeight(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: scale.getScaledHeight(24),
                        width: scale.getScaledWidth(24),
                        decoration: BoxDecoration(
                          color: const Color(0xff1F2A58),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _serviceIconForName(service.name),
                          color: const Color(0xff68A0FF),
                          size: 15,
                        ),
                      ),
                      SizedBox(width: scale.getScaledWidth(8)),
                      Expanded(
                        child: Text(
                          service.name,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: scale.getScaledFont(16 / 1.2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale.getScaledWidth(10),
                          vertical: scale.getScaledHeight(2),
                        ),
                        decoration: BoxDecoration(
                          color: service.isActive
                              ? const Color(0xff0CDB6D).withValues(alpha: 0.16)
                              : const Color(0xffFFB300).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: service.isActive
                                ? const Color(0xff0CDB6D)
                                      .withValues(alpha: 0.58)
                                : const Color(0xffFFB300)
                                      .withValues(alpha: 0.58),
                          ),
                        ),
                        child: Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: service.isActive
                                ? const Color(0xff0CDB6D)
                                : const Color(0xffFFB300),
                            fontSize: scale.getScaledFont(11),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: scale.getScaledWidth(8)),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  SizedBox(height: scale.getScaledHeight(2)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: scale.getScaledWidth(32)),
                      child: Text(
                        '${service.events.length} types . ${service.activeEventCount} active',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.52),
                          fontSize: scale.getScaledFont(13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) Container(height: 1, color: const Color(0xffD9D9D9)),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                children: [
                  ...service.events.map(
                    (event) => _eventCard(
                      context: context,
                      scale: scale,
                      controller: controller,
                      service: service,
                      event: event,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _showAddOrEditEventDialog(
                        controller: controller,
                        service: service,
                        event: null,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Add Event type',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventCard({
    required BuildContext context,
    required ScalingUtility scale,
    required AdminServicesController controller,
    required AdminServiceModel service,
    required ServiceEventTypeModel event,
  }) {
    final toggleBusy = controller.isBusy('toggle_${event.id}');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale.getScaledFont(18 / 1.2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: toggleBusy,
                child: _eventToggle(
                  isActive: event.isActive,
                  onTap: () => controller.toggleEventTypeActive(
                    serviceId: service.id,
                    event: event,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatDate(event.updatedAt ?? event.createdAt),
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.5),
                fontSize: scale.getScaledFont(13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _showPricingBottomSheet(
                  controller: controller,
                  serviceId: service.id,
                  event: event,
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xffD7E3FF)),
                  foregroundColor: Color(0xff004FFF),
                  backgroundColor: const Color(0xffD7E3FF),
                ),
                child: const Text('Event pricing'),
              ),
              const SizedBox(width: 8),
              _smallIconButton(
                icon: Icons.edit_outlined,
                color: const Color(0xffF7B500),
                bgColor: const Color(0xffFFFAF2),
                onTap: () => _showAddOrEditEventDialog(
                  controller: controller,
                  service: service,
                  event: event,
                ),
              ),
              const SizedBox(width: 8),
              _smallIconButton(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xffFF5656),
                bgColor: const Color(0xffFFE5E5).withValues(alpha: 0.5),
                onTap: () => _showDeleteEventDialog(
                  controller: controller,
                  serviceId: service.id,
                  event: event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventToggle({required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xff000000).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xff00C950) : const Color(0xff6B6F8A),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallIconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 26,
        width: 26,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Future<void> _showAddOrEditEventDialog({
    required AdminServicesController controller,
    required AdminServiceModel service,
    required ServiceEventTypeModel? event,
  }) async {
    final isEdit = event != null;
    final textController = TextEditingController(text: event?.name ?? '');
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xffF4F6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: isEdit
                                ? const Color(0xffFFF3DE)
                                : const Color(0xffE6EEFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit : Icons.add,
                            color: isEdit
                                ? const Color(0xffF59E0B)
                                : const Color(0xff2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Event Type' : 'Add Event Type',
                            style: const TextStyle(
                              color: Color(0xff1E2233),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting ? null : Get.back,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xff7A8194),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Event Type Name',
                      style: TextStyle(
                        color: Color(0xff555E75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Color(0xff1A2230)),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Please enter event type name'
                          : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'e.g. Wedding Shoots',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffD1D9EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffD1D9EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xff7289FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use a clear and descriptive name.',
                      style: TextStyle(color: Color(0xff8A92A8), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : Get.back,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffE8EBF2),
                                foregroundColor: const Color(0xff4B566F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (context.mounted) {
                                        setState(() => isSubmitting = true);
                                      }
                                      final success = event != null
                                          ? await controller.updateEventTypeName(
                                              serviceId: service.id,
                                              eventId: event.id,
                                              nextName: textController.text,
                                              existingEvents: service.events,
                                            )
                                          : await controller.addEventType(
                                              service: service,
                                              name: textController.text,
                                            );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (success) {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                        return;
                                      }
                                      if (context.mounted) {
                                        setState(() => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEdit
                                    ? const Color(0xffF59E0B)
                                    : const Color(0xff4B6BFB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEdit ? 'Update' : 'Add Type',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
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
      barrierDismissible: false,
    );
  }

  Future<void> _showDeleteEventDialog({
    required AdminServicesController controller,
    required String serviceId,
    required ServiceEventTypeModel event,
  }) async {
    var isSubmitting = false;
    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xffF8F7FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xffFFECEF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xffFF3B4D),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Delete Event Type?',
                    style: TextStyle(
                      color: Color(0xff1E2233),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete "${event.name}"?\nThis will also remove its pricing data.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff646E84),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF2F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffFFD5DB)),
                    ),
                    child: const Text(
                      'This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xffD8202F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : Get.back,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffE8EBF2),
                              foregroundColor: const Color(0xff4B566F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (context.mounted) {
                                      setState(() => isSubmitting = true);
                                    }
                                    final success = await controller
                                        .deleteEventType(
                                          serviceId: serviceId,
                                          event: event,
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (success) {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                      return;
                                    }
                                    if (context.mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF2B45),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showGstDialog(
    AdminServicesController controller,
    double currentGst,
  ) async {
    final textController = TextEditingController(text: _formatGst(currentGst));
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xffF5F6FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF1D6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.percent_rounded,
                            color: Color(0xffDA8A00),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'GST Settings',
                            style: TextStyle(
                              color: Color(0xff1E2233),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting ? null : Get.back,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xff7A8194),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'GST Tax (%)',
                      style: TextStyle(
                        color: Color(0xff555E75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: textController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null) {
                          return 'Enter valid GST';
                        }
                        if (parsed < 0 || parsed > 100) {
                          return 'GST must be between 0 and 100';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(
                          Icons.percent,
                          color: Color(0xffB26D00),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffDADFEA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xffDADFEA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xff8E9CFF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current GST: ${_formatGst(controller.gstPercent.value)}%',
                      style: const TextStyle(
                        color: Color(0xff53607A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : Get.back,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffE8EBF2),
                                foregroundColor: const Color(0xff4B566F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (context.mounted) {
                                        setState(() => isSubmitting = true);
                                      }
                                      final success = await controller
                                          .saveGstPercent(
                                            double.parse(
                                              textController.text.trim(),
                                            ),
                                          );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (success) {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                        return;
                                      }
                                      if (context.mounted) {
                                        setState(() => isSubmitting = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffF59E0B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: isSubmitting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                isSubmitting ? 'Saving...' : 'Save GST',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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
      barrierDismissible: false,
    );
  }

  Future<void> _showPricingBottomSheet({
    required AdminServicesController controller,
    required String serviceId,
    required ServiceEventTypeModel event,
  }) async {
    final basicController = TextEditingController(
      text: event.basicPlan.price.toString(),
    );
    final basicLabelController = TextEditingController(
      text: event.basicPlan.label,
    );
    final basicDescriptionController = TextEditingController(
      text: event.basicPlan.descriptionPoints.join('\n'),
    );
    final normalController = TextEditingController(
      text: event.normalPlan.price.toString(),
    );
    final normalLabelController = TextEditingController(
      text: event.normalPlan.label,
    );
    final normalDescriptionController = TextEditingController(
      text: event.normalPlan.descriptionPoints.join('\n'),
    );
    final proController = TextEditingController(
      text: event.professionalPlan.price.toString(),
    );
    final proLabelController = TextEditingController(
      text: event.professionalPlan.label,
    );
    final proDescriptionController = TextEditingController(
      text: event.professionalPlan.descriptionPoints.join('\n'),
    );
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    await Get.bottomSheet<void>(
      StatefulBuilder(
        builder: (context, setState) {
          final gst = controller.gstPercent.value;

          List<String> descriptionPoints(TextEditingController controller) {
            return controller.text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(growable: false);
          }

          Widget planField(
            String defaultLabel,
            TextEditingController labelController,
            TextEditingController priceController,
            TextEditingController descriptionController,
          ) {
            final base = int.tryParse(priceController.text.trim()) ?? 0;
            final total = _withGst(base, gst);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffEFF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffD8DEF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    defaultLabel,
                    style: const TextStyle(
                      color: Color(0xff1F2440),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: labelController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter plan name'
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Custom plan name',
                      hintText: defaultLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff7D8EFF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter amount'
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixText: 'Rs. ',
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff7D8EFF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    validator: (_) {
                      final points = descriptionPoints(
                        descriptionController,
                      );
                      return points.length > 4
                          ? 'Add maximum 4 included points.'
                          : null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "What's included",
                      hintText: 'One point per line. Maximum 4 points.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffDADFEA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff7D8EFF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total with GST: Rs.$total',
                      style: const TextStyle(
                        color: Color(0xff4E5670),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xffF5F6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffBCC3D2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pricing Config',
                              style: const TextStyle(
                                color: Color(0xff1E2233),
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting ? null : Get.back,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xff7A8194),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            color: Color(0xff6C7491),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF5E7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xffFFE0B5)),
                        ),
                        child: Text(
                          'GST ${_formatGst(gst)}% will be applied to all plans.',
                          style: const TextStyle(
                            color: Color(0xffB35E00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      planField(
                        'Default Plan',
                        basicLabelController,
                        basicController,
                        basicDescriptionController,
                      ),
                      planField(
                        'Normal Plan',
                        normalLabelController,
                        normalController,
                        normalDescriptionController,
                      ),
                      planField(
                        'Professional Plan',
                        proLabelController,
                        proController,
                        proDescriptionController,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    if (context.mounted) {
                                      setState(() => isSubmitting = true);
                                    }
                                    final success = await controller
                                        .saveEventPricing(
                                          serviceId: serviceId,
                                          eventId: event.id,
                                          defaultLabel:
                                              basicLabelController.text.trim(),
                                          defaultPrice:
                                              int.tryParse(
                                                basicController.text.trim(),
                                              ) ??
                                              0,
                                          defaultDescriptionPoints:
                                              descriptionPoints(
                                                basicDescriptionController,
                                              ),
                                          normalLabel:
                                              normalLabelController.text.trim(),
                                          normalPrice:
                                              int.tryParse(
                                                normalController.text.trim(),
                                              ) ??
                                              0,
                                          normalDescriptionPoints:
                                              descriptionPoints(
                                                normalDescriptionController,
                                              ),
                                          professionalLabel:
                                              proLabelController.text.trim(),
                                          professionalPrice:
                                              int.tryParse(
                                                proController.text.trim(),
                                              ) ??
                                              0,
                                          professionalDescriptionPoints:
                                              descriptionPoints(
                                                proDescriptionController,
                                              ),
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (success) {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                      return;
                                    }
                                    if (context.mounted) {
                                      setState(() => isSubmitting = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2D55F5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: isSubmitting
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              isSubmitting ? 'Saving...' : 'Save Pricing',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  IconData _serviceIconForName(String name) {
    final value = name.toLowerCase();
    if (value.contains('photo') || value.contains('video')) {
      return Icons.photo_camera_outlined;
    }
    if (value.contains('music')) {
      return Icons.music_note_rounded;
    }
    if (value.contains('dj')) {
      return Icons.headphones_rounded;
    }
    if (value.contains('anchor')) {
      return Icons.mic_rounded;
    }
    if (value.contains('magician')) {
      return Icons.auto_awesome_rounded;
    }
    if (value.contains('painter')) {
      return Icons.brush_outlined;
    }
    return Icons.work_outline_rounded;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Recently updated';
    }
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}, ${dateTime.year}';
  }

  int _withGst(int basePrice, double gstPercent) {
    return (basePrice + ((basePrice * gstPercent) / 100)).round();
  }

  String _formatGst(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
