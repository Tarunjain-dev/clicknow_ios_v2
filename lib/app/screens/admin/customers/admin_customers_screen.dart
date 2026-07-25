import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/customers/customer_details_screen.dart';
import 'package:clicknow_version2/app/screens/admin/customers/getx/admin_customers_controller.dart';
import 'package:clicknow_version2/app/screens/admin/customers/models/admin_customer.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late final AdminCustomersController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminCustomersController>() ? Get.find<AdminCustomersController>() : Get.put(AdminCustomersController());
    searchController = TextEditingController(text: controller.searchQuery.value);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminCustomersRoute,
        ),
        body: SafeArea(
          child: Obx(
            () => RefreshIndicator(
              onRefresh: () => controller.refreshCustomers(showMessage: true),
              child: Column(
                children: [
                  /// -- app bar
                  _header(scale),

                  /// -- body
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            scale.getScaledWidth(14),
                            scale.getScaledHeight(12),
                            scale.getScaledWidth(14),
                            scale.getScaledHeight(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _summaryCards(scale),
                              SizedBox(height: scale.getScaledHeight(14)),
                              Text(
                                'Registered Customers',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: scale.getScaledFont(15),
                                ),
                              ),
                              SizedBox(height: scale.getScaledHeight(10)),
                              if (controller.isLoading.value && controller.filteredCustomers.isEmpty)
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: scale.getScaledHeight(42),
                                  ),
                                  child: const Center(child: CircularProgressIndicator()),
                                )
                              else if (controller.filteredCustomers.isEmpty)
                                _emptyState(scale)
                              else
                                ...controller.filteredCustomers.map(
                                  (customer) => _customerCard(scale, customer),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale) {
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
      child: Column(
        children: [
          Row(
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
                      'Customers',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: scale.getScaledFont(18),
                      ),
                    ),
                    Text(
                      'Manage registered customers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: scale.getScaledFont(11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(6)),
            child: TextField(
              controller: searchController,
              onChanged: controller.updateSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search customers by name, phone, city or ID',
                hintStyle: const TextStyle(color: Color(0xffD9D9D9)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xffD9D9D9),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    controller.updateSearch('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xffD9D9D9),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xffD9D9D9)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(ScalingUtility scale) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            scale: scale,
            icon: Icons.groups_2_outlined,
            iconBg: const Color(0xff5D5CFF),
            title: 'Total Customers',
            value: '${controller.totalCustomers}',
          ),
        ),
        SizedBox(width: scale.getScaledWidth(10)),
        Expanded(
          child: _metricCard(
            scale: scale,
            icon: Icons.verified_user_outlined,
            iconBg: const Color(0xff0CDB6D),
            title: 'Profile Complete',
            value: '${controller.completedProfilesCount}',
          ),
        ),
        SizedBox(width: scale.getScaledWidth(10)),
        Expanded(
          child: _metricCard(
            scale: scale,
            icon: Icons.pending_actions_outlined,
            iconBg: const Color(0xffFFB300),
            title: 'Pending Profile',
            value: '${controller.pendingProfilesCount}',
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required ScalingUtility scale,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(8)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: scale.getScaledHeight(22),
            width: scale.getScaledWidth(22),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          SizedBox(height: scale.getScaledHeight(6)),
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.7),
              fontSize: scale.getScaledFont(11),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: scale.getScaledFont(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard(ScalingUtility scale, AdminCustomer customer) {
    return InkWell(
      onTap: () => Get.to(() => CustomerDetailsScreen(customer: customer)),
      child: Container(
        margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
        decoration: BoxDecoration(
          color: const Color(0xffFCFBFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                scale.getScaledWidth(10),
                scale.getScaledHeight(10),
                scale.getScaledWidth(10),
                scale.getScaledHeight(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: scale.getScaledWidth(18),
                    backgroundColor: const Color(0xff532DD1).withValues(alpha: 0.2),
                    child: Text(
                      _avatarText(customer.fullName),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: scale.getScaledFont(13),
                      ),
                    ),
                  ),
                  SizedBox(width: scale.getScaledWidth(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: scale.getScaledFont(15),
                          ),
                        ),
                        SizedBox(height: scale.getScaledHeight(2)),
                        Text(
                          customer.phoneNumber.isEmpty ? '-' : customer.phoneNumber,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.74),
                            fontSize: scale.getScaledFont(12),
                          ),
                        ),
                        SizedBox(height: scale.getScaledHeight(2)),
                        Text(
                          customer.addressLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.64),
                            fontSize: scale.getScaledFont(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.getScaledWidth(10),
                      vertical: scale.getScaledHeight(3),
                    ),
                    decoration: BoxDecoration(
                      color: customer.profileCompleted
                          ? const Color(0xff0ADB6D).withValues(alpha: 0.14)
                          : const Color(0xffFFB300).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: customer.profileCompleted
                            ? const Color(0xff0ADB6D).withValues(alpha: 0.5)
                            : const Color(0xffFFB300).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      customer.profileCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color: customer.profileCompleted
                            ? const Color(0xff00FFA3)
                            : const Color(0xffFFB300),
                        fontSize: scale.getScaledFont(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xffD9D9D9)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                scale.getScaledWidth(12),
                scale.getScaledHeight(7),
                scale.getScaledWidth(12),
                scale.getScaledHeight(7),
              ),
              child: Row(
                children: [
                  Text(
                    'See Details',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.88),
                      fontSize: scale.getScaledFont(13),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ScalingUtility scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(scale.getScaledWidth(14)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Text(
        'No customers found.',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.74),
          fontSize: scale.getScaledFont(13),
        ),
      ),
    );
  }

  String _avatarText(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    return trimmed[0].toUpperCase();
  }
}
