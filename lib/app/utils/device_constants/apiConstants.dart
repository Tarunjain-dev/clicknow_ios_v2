class ApiConstants {
  ApiConstants._();

  /// -- Google Maps Platform (replace with your real key before release)
  static const String googleMapsApiKey = "AIzaSyB-dQl3IfZ7gFQBSoEKPqi6NZtH7ZHNLAw";

  /// -- Base URL
  static const String baseUrl = "https://clicknow.onrender.com/api/v1";

  /// -- Health
  static const String health = "/health";

  /// -- Authentication
  static const String sendOtp = "/auth/send-otp";
  static const String verifyOtp = "/auth/verify-otp";
  static const String authMe = "/auth/me";
  static const String authFirebase = "/auth/firebase";
  static const String refreshToken = "/auth/refresh";
  static const String logout = "/auth/logout";

  /// -- User Profile
  static const String userProfile = "/users/profile";
  static const String fcmToken = "/users/fcm-token";

  /// -- Professionals
  static const String professionals = "/professionals";

  /// -- Bookings
  static const String bookings = "/bookings";
  static const String clientBookings = "/bookings/client";

  /// -- Reviews
  static const String reviews = "/reviews";

  /// -- Notifications
  static const String notifications = "/notifications";
  static const String unreadCount = "/notifications/unread-count";
  static const String readAllNotifications = "/notifications/read-all";
}
