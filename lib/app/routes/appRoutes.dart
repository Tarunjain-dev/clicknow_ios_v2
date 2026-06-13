import 'package:clicknow_version2/app/screens/common/onboarding/onboarding_Screen.dart';
import 'package:clicknow_version2/app/screens/common/auth/login_Screen.dart';
import 'package:clicknow_version2/app/screens/common/splash/splash_Screen.dart';
import 'package:clicknow_version2/app/screens/customer/customer_bottom_nav_bar.dart';
import 'package:clicknow_version2/app/screens/customer/profile/sub_screens/edit_personal_information_screen.dart';
import 'package:clicknow_version2/app/screens/admin/dashboard/admin_dashboard_screen.dart';
import 'package:clicknow_version2/app/screens/admin/professionals/admin_professionals_screen.dart';
import 'package:clicknow_version2/app/screens/admin/services/admin_services_screen.dart';
import 'package:clicknow_version2/app/screens/admin/customers/admin_customers_screen.dart';
import 'package:clicknow_version2/app/screens/admin/bookings/admin_bookings_screen.dart';
import 'package:clicknow_version2/app/screens/admin/payments/admin_payments_screen.dart';
import 'package:clicknow_version2/app/screens/admin/content_portfolio/admin_content_portfolio_screen.dart';
import 'package:clicknow_version2/app/screens/admin/settings/admin_settings_screen.dart';
import 'package:clicknow_version2/app/screens/admin/support/admin_support_disputes_screen.dart';
import 'package:clicknow_version2/app/screens/common/support/screens/help_support_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/AdminApproval_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/professionalRegistration_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalBottomNavBar.dart';
import 'package:clicknow_version2/app/routes/admin_middleware.dart';
import 'package:get/get.dart';

class AppRoutes {
  AppRoutes._();

  /// -- Routes
  static const String initialRoute = "/";
  static const String onBoardingRoute = "/onBoarding";
  static const String loginRoute = "/login";
  static const String customerBottomNavigationRoute = "/bottomNavigation";
  static const String professionalRegistrationRoute =
      "/professionalRegistration";
  static const String professionalBottomNavigationRoute =
      "/professionalBottomNavigation";
  static const String adminDashboardRoute = "/adminDashboard";
  static const String adminProfessionalsRoute = "/adminProfessionals";
  static const String adminCustomersRoute = "/adminCustomers";
  static const String adminBookingsRoute = "/adminBookings";
  static const String adminServicesRoute = "/adminServices";
  static const String adminPaymentsRoute = "/adminPayments";
  static const String adminContentPortfolioRoute = "/adminContentPortfolio";
  static const String adminSettingsRoute = "/adminSettings";
  static const String adminSupportDisputesRoute = "/adminSupportDisputes";
  static const String helpSupportRoute = "/helpSupport";
  static const String adminApprovalScreen = "/adminApprovalScreen";
  static const String customerProfileCompletionRoute =
      "/customerProfileCompletion";
  static const String photoAndVideographyServiceRoute =
      "/photoAndVideographyService";
  static const String musicAndLivePerformanceServiceRoute =
      "/musicAndLivePerformanceService";
  static const String professionalDjServiceServiceRoute =
      "/professionalDjService";
  static const String weddingPlannerServiceRoute = "/weddingPlannerService";
  static const String professionalAnchorServiceRoute =
      "/professionalAnchorService";
  static const String professionalMagicianServiceRoute =
      "/professionalMagicianService";
  static const String photoAndVideographyServiceFormRoute =
      "/photoAndVideographyServiceForm";
  static const String musicAndLivePerformanceServiceFormRoute =
      "/musicAndLivePerformanceServiceForm";
  static const String professionalDjServiceServiceFormRoute =
      "/professionalDjServiceForm";
  static const String weddingPlannerServiceFormRoute =
      "/weddingPlannerServiceForm";
  static const String professionalAnchorServiceFormRoute =
      "/professionalAnchorServiceForm";
  static const String professionalMagicianServiceFormRoute =
      "/professionalMagicianServiceForm";

  /// -- Pages
  static final pages = [
    GetPage(name: initialRoute, page: () => SplashScreen()),
    GetPage(name: onBoardingRoute, page: () => OnBoardingScreen()),
    GetPage(name: loginRoute, page: () => const LoginScreen()),
    GetPage(
      name: customerProfileCompletionRoute,
      page: () => const EditPersonalInformationScreen(forceCompletion: true),
    ),
    GetPage(
      name: customerBottomNavigationRoute,
      page: () => const CustomerBottomNavBar(),
    ),
    GetPage(
      name: professionalRegistrationRoute,
      page: () => const ProfessionalRegistrationScreen(),
    ),
    GetPage(
      name: professionalBottomNavigationRoute,
      page: () => ProfessionalBottomNavBar(),
    ),
    GetPage(
      name: adminDashboardRoute,
      page: () => const AdminDashboardScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminProfessionalsRoute,
      page: () => const AdminProfessionalsScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminCustomersRoute,
      page: () => const AdminCustomersScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminBookingsRoute,
      page: () => const AdminBookingsScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminServicesRoute,
      page: () => const AdminServicesScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminPaymentsRoute,
      page: () => const AdminPaymentsScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminContentPortfolioRoute,
      page: () => const AdminContentPortfolioScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminSettingsRoute,
      page: () => const AdminSettingsScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminSupportDisputesRoute,
      page: () => const AdminSupportDisputesScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: helpSupportRoute,
      page: () => HelpSupportScreen(
        role: (Get.arguments as Map?)?['role']?.toString() ?? 'customer',
      ),
    ),
    GetPage(name: adminApprovalScreen, page: () => AdminApprovalScreen()),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyScreen(),),
    // GetPage(name: musicAndLivePerformanceServiceRoute, page: () => PhotoAndVideographyScreen(),),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyServiceFormScreen(),),
    // GetPage(name: photoAndVideographyServiceRoute, page: () => PhotoAndVideographyServiceFormScreen(),),
  ];
}
