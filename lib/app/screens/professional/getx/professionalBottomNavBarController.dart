import 'package:clicknow_version2/app/screens/professional/professionalDashboard/bookings/professionalBooking_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/professionalEarning_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/home/professionalDashboard_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/professionalProfile_Screen.dart';
import 'package:get/get.dart';

class ProfessionalBottomNavController extends GetxController {
  var index = 0.obs;

  final screens = [
    ProfessionalDashboardScreen(),
    ProfessionalEarningsScreen(),
    ProfessionalBookingsScreen(),
    ProfessionalProfileScreen(),
  ];

  void changeTab(int i) {
    index.value = i;
  }
}