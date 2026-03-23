import 'package:clicknow_version2/app/screens/common/onboarding/onboarding_Screen.dart';
import 'package:clicknow_version2/app/screens/common/auth/login_Screen.dart';
import 'package:clicknow_version2/app/screens/common/splash/splash_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/customer_bottom_nav_bar.dart';
import 'package:clicknow_version2/app/screens/admin/dashboard/admin_dashboard_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/AdminApproval_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/professionalRegistration_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalBottomNavBar.dart';
import 'package:clicknow_version2/app/routes/admin_middleware.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AppRoutes {
  AppRoutes._();

  /// -- Routes
  static const String initialRoute = "/";
  static const String onBoardingRoute = "/onBoarding";
  static const String loginRoute = "/login";
  static const String customerBottomNavigationRoute = "/bottomNavigation";
  static const String professionalRegistrationRoute = "/professionalRegistration";
  static const String professionalBottomNavigationRoute = "/professionalBottomNavigation";
  static const String adminDashboardRoute = "/adminDashboard";
  static const String adminApprovalScreen = "/adminApprovalScreen";
  static const String photoAndVideographyServiceRoute = "/photoAndVideographyService";
  static const String musicAndLivePerformanceServiceRoute = "/musicAndLivePerformanceService";
  static const String professionalDjServiceServiceRoute = "/professionalDjService";
  static const String weddingPlannerServiceRoute = "/weddingPlannerService";
  static const String professionalAnchorServiceRoute = "/professionalAnchorService";
  static const String professionalMagicianServiceRoute = "/professionalMagicianService";
  static const String photoAndVideographyServiceFormRoute = "/photoAndVideographyServiceForm";
  static const String musicAndLivePerformanceServiceFormRoute = "/musicAndLivePerformanceServiceForm";
  static const String professionalDjServiceServiceFormRoute = "/professionalDjServiceForm";
  static const String weddingPlannerServiceFormRoute = "/weddingPlannerServiceForm";
  static const String professionalAnchorServiceFormRoute = "/professionalAnchorServiceForm";
  static const String professionalMagicianServiceFormRoute = "/professionalMagicianServiceForm";

  /// -- Pages
  static final pages = [
    GetPage(name: initialRoute, page: () => SplashScreen()),
    GetPage(name: onBoardingRoute, page: () => OnBoardingScreen()),
    GetPage(name: loginRoute, page: () => const LoginScreen()),
    GetPage(name: customerBottomNavigationRoute, page: () => const CustomerBottomNavBar(),),
    GetPage(name: professionalRegistrationRoute, page: () => const ProfessionalRegistrationScreen()),
    GetPage(name: professionalBottomNavigationRoute, page: () => ProfessionalBottomNavBar()),
    GetPage(
      name: adminDashboardRoute,
      page: () => const AdminDashboardScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(name: adminApprovalScreen, page: () => AdminApprovalScreen()),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyScreen(),),
    // GetPage(name: musicAndLivePerformanceServiceRoute, page: () => PhotoAndVideographyScreen(),),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyServiceFormScreen(),),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyServiceFormScreen(),),
  ];
}
