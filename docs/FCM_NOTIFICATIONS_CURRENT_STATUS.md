# ClickNow FCM Notifications Current Status

Date: 2026-06-16

## Purpose

This document records the current notification status before implementing Firebase Cloud Messaging for the admin, customer, and professional panels.

The next implementation phase should add:

- FCM token registration and refresh handling.
- Foreground, background, and terminated-state notification handling.
- Notification inbox/read state for customers and professionals.
- Admin-created custom push notifications for customers and professionals.
- Replacement of the admin drawer item `Reports & Analytics` with `Notifications`.

## Current Firebase Setup

Firebase is already initialized in [main.dart](../lib/main.dart).

Current startup flow:

- `Firebase.initializeApp(...)` is called.
- Firebase App Check is activated.
- `GetStorage` and network guard are initialized.
- No notification service is initialized.
- No FCM permission request is made.
- No foreground/background message handlers are registered.

Firebase options exist for Android and iOS in [firebase_options.dart](../lib/firebase_options.dart).

## Current Dependency Status

`firebase_messaging` is already present in [pubspec.yaml](../pubspec.yaml):

```yaml
firebase_messaging: ^16.0.1
```

However, code search shows no active usage of:

- `FirebaseMessaging.instance`
- `FirebaseMessaging.onMessage`
- `FirebaseMessaging.onBackgroundMessage`
- `FirebaseMessaging.onMessageOpenedApp`
- FCM token registration
- FCM token refresh handling

## Platform Configuration Status

### Android

Android Firebase config exists:

- [android/app/google-services.json](../android/app/google-services.json)
- Google services plugin is applied in [android/app/build.gradle.kts](../android/app/build.gradle.kts)

Current Android manifest:

- Has `INTERNET`
- Has location permissions
- Does not explicitly define notification permission for Android 13+:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

This permission should be added for Android 13 and newer.

### iOS

iOS Firebase options exist.

Current [Info.plist](../ios/Runner/Info.plist) has location and Google Maps config, but no visible notification permission messaging/configuration.

The current [AppDelegate.swift](../ios/Runner/AppDelegate.swift) initializes Google Maps and Flutter plugins. No explicit FCM/APNs setup is present.

## Current Frontend Notification Screens

### Customer

Existing screen:

- [customer_notifications_screen.dart](../lib/app/screens/customer/home/customer_notifications_screen.dart)

Current behavior:

- Static UI only.
- Shows `No notifications yet`.
- Does not read Firestore.
- Does not mark notifications as read.
- Does not display unread count from backend.
- Does not handle notification deep links.

Customer dashboard has a notification icon that opens this screen:

- [customerDashboard_Screen.dart](../lib/app/screens/customer/home/customerDashboard_Screen.dart)

Current issue:

- `notificationCount` exists as an observable value, but it is initialized to `0` and not bound to any notification source.

### Professional

Existing screen:

- [professional_notifications_screen.dart](../lib/app/screens/professional/professionalDashboard/home/professional_notifications_screen.dart)

Current behavior:

- Static UI only.
- Shows `No notifications yet`.
- Does not read Firestore.
- Does not mark notifications as read.
- Does not display notification records.

Professional dashboard has a notification icon:

- [professionalDashboard_Screen.dart](../lib/app/screens/professional/professionalDashboard/home/professionalDashboard_Screen.dart)

Current issue:

- Badge count is hardcoded as `"6"`.
- It is not connected to unread notification data.

### Admin

There is no dedicated admin notifications screen currently.

Admin drawer:

- [admin_drawer.dart](../lib/app/screens/admin/widgets/admin_drawer.dart)

Current drawer item:

```dart
_DrawerItem(label: "Reports & Analytics", icon: Icons.query_stats),
```

Current issue:

- `Reports & Analytics` has no route.
- It should be replaced with a routed `Notifications` item.

Routes:

- [appRoutes.dart](../lib/app/routes/appRoutes.dart)

Current issue:

- No `adminNotificationsRoute` exists.
- No `AdminNotificationsScreen` exists.

## Current Backend Notification Status

Backend file:

- [functions/index.js](../functions/index.js)

Current backend uses Firebase Admin SDK and Cloud Functions for booking, payment, refund, payroll, and admin account actions.

Current FCM status:

- No `admin.messaging().send(...)`.
- No `admin.messaging().sendEachForMulticast(...)`.
- No notification collection constants.
- No generic notification send function.
- No admin custom notification Cloud Function.
- No automatic notification triggers for booking/payment/payroll/refund events.

Existing backend functions are HTTP-based with Firebase ID token verification through `paymentRequestHandler(...)`, which can be reused for an admin-only custom notification endpoint.

## Existing API Constants

[apiConstants.dart](../lib/app/utils/device_constants/apiConstants.dart) contains older REST-style constants:

```dart
static const String fcmToken = "/users/fcm-token";
static const String notifications = "/notifications";
static const String unreadCount = "/notifications/unread-count";
static const String readAllNotifications = "/notifications/read-all";
```

Current issue:

- These constants are not connected to the current Firebase/Cloud Functions implementation.
- No matching app service was found using these endpoints.

## Missing Data Model

No consistent notification data model currently exists.

Recommended Firestore collections:

```text
notifications/{notificationId}
users/{uid}/notifications/{notificationId}
users/{uid}/fcm_tokens/{tokenId}
notification_campaigns/{campaignId}
```

Recommended fields for user notification documents:

```text
notificationId
recipientId
recipientRole
title
body
type
source
data
imageUrl
deepLinkRoute
read
createdAt
readAt
sentByAdminId
campaignId
```

Recommended fields for FCM token documents:

```text
token
platform
appVersion
role
deviceId
createdAt
updatedAt
lastSeenAt
isActive
```

## Required Implementation Areas

### 1. Shared Notification Service

Create a shared Flutter service, for example:

```text
lib/app/services/notifications/fcm_notification_service.dart
```

Responsibilities:

- Request notification permission.
- Get and store FCM token.
- Listen for token refresh.
- Register foreground listener.
- Register notification-tap listener.
- Handle initial message when app opens from terminated state.
- Route deep links safely by role.
- Clear token on logout or user switch.

### 2. Background Handler

Add a top-level background handler in or near `main.dart`:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
```

Register it before `runApp(...)`.

### 3. Token Storage

Store tokens under the logged-in user.

Important:

- Token must be scoped to UID and role.
- Token should be updated on every login/session restore.
- Token should be disabled/deleted on logout where possible.
- The same device may be used by different roles, so role must be tracked.

### 4. Customer Notification Inbox

Replace placeholder screen with Firestore-backed list:

- Stream `users/{uid}/notifications`.
- Sort by `createdAt desc`.
- Show unread/read state.
- Mark one as read.
- Mark all as read.
- Support deep-link tap.

### 5. Professional Notification Inbox

Same as customer, but professional-specific messaging and routes.

Also replace hardcoded badge `"6"` with unread count.

### 6. Admin Notification Panel

Create:

```text
lib/app/screens/admin/notifications/admin_notifications_screen.dart
lib/app/screens/admin/notifications/getx/admin_notifications_controller.dart
```

Admin features:

- Compose notification title/body.
- Select recipient group:
  - All customers
  - All professionals
  - Selected customers
  - Selected professionals
  - Optional future segment filters
- Optional image URL.
- Optional deep link route/type.
- Send notification.
- View send history/campaign logs.

### 7. Admin Drawer + Routes

Replace:

```text
Reports & Analytics
```

with:

```text
Notifications
```

Add:

```dart
static const String adminNotificationsRoute = "/adminNotifications";
```

Add a GetPage protected by `AdminMiddleware`.

### 8. Backend Send Function

Add admin-only Cloud Function, for example:

```text
sendAdminCustomNotification
```

Responsibilities:

- Verify admin role.
- Validate title/body.
- Resolve recipients.
- Read active FCM tokens.
- Create notification docs.
- Send FCM multicast batches.
- Write campaign result log.
- Handle invalid tokens and mark them inactive.

### 9. Automatic System Notifications

After generic infrastructure exists, add notification calls for important events:

- Booking created/payment successful.
- Admin approved booking.
- Professional assigned.
- Professional accepted/rejected.
- Booking confirmed.
- Booking started/completed.
- Remaining payment required.
- Refund approved/completed.
- Payroll released/confirmed.
- Document reupload requested.
- Account suspended/blocked/reactivated.

## Current Risks

1. Notification dependency exists but is unused, so users currently receive no push notifications.
2. Customer/professional notification screens are placeholders, which can mislead testers.
3. Professional dashboard badge is hardcoded as `6`.
4. Admin drawer has an unrouted `Reports & Analytics` item.
5. No backend notification audit trail exists.
6. No FCM token cleanup exists, so future implementation must handle stale tokens carefully.
7. Android 13+ notification permission is not declared.
8. Direct custom notification sending must be admin-only; never expose recipient token reads to the client.

## Recommended Next Implementation Order

1. Add shared Firestore notification paths/constants.
2. Add Flutter FCM service and initialize it after Firebase/Auth state is known.
3. Add token registration and refresh handling.
4. Add backend admin send function.
5. Replace admin drawer item and add admin notification panel.
6. Replace customer/professional placeholder inbox screens.
7. Add unread badge streams.
8. Add system event notifications one workflow at a time.
9. Test foreground/background/terminated behavior on real Android device.

## Summary

The application is Firebase-ready and already includes `firebase_messaging`, but FCM is not implemented yet.

Current notification UI is placeholder-only for customer and professional users. Admin has no notification screen, and the drawer still contains a non-functional `Reports & Analytics` item.

The next phase should introduce a shared FCM service, token storage, backend send functions, notification inboxes, unread badges, and an admin custom notification campaign screen.
