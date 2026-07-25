import 'package:clicknow_version2/app/screens/customer/home/customerDashboard_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_bookings_tab_screen.dart';
import 'package:clicknow_version2/app/screens/customer/portfolio/customer_portfolio_screen.dart';
import 'package:clicknow_version2/app/screens/customer/profile/customer_profile_screen.dart';
import 'package:get/get.dart';

class CustomerBottomNavController extends GetxController {
  var index = 0.obs;

  final screens = const [
    CustomerDashboardScreen(),
    CustomerPortfolioScreen(),
    CustomerBookingsTabScreen(),
    CustomerProfileScreen(),
  ];

  void changeTab(int i) {
    index.value = i;
  }
}
