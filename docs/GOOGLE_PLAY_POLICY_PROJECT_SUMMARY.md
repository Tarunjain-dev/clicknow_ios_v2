# ClickNow Google Play Policy Project Summary

Current workspace review date: 2026-06-19

This document summarizes the current ClickNow Flutter/Firebase project for Google Play listing, Data safety, app review, and policy preparation. It is based on the current repository implementation, including Flutter screens/services, Firebase Cloud Functions, and `android/app/src/main/AndroidManifest.xml`.

## 1. App Category And Purpose

ClickNow is an event-service booking marketplace app. Customers can browse and book event professionals/vendors such as photo and videography, music/live performance, DJ, anchor, magician, wedding planner/management, and related event services.

The app has three major panels:

- Customer panel: service discovery, cart/booking checkout, booking management, payments, invoices, notifications, support, and profile/address management.
- Professional/vendor panel: onboarding, document verification, availability, booking acceptance/service workflow, earnings, payout history, payroll slip access, notifications, and profile management.
- Admin panel: operational management for bookings, professionals, customers, payments, refunds, payrolls, support, notifications, portfolio/content, services, and account controls.

Primary app category suggestion: Events / Lifestyle / Business services marketplace.

## 2. Complete Functionality And Feature List

Core implemented areas:

- Phone OTP authentication and role-based routing for customer, professional, and admin users.
- Customer service catalog and service detail pages.
- Booking draft creation and booking lifecycle management.
- Add-to-cart / booking summary / checkout flow.
- Razorpay payment gateway integration for customer payments.
- 20 percent advance and full payment options.
- Coupon quote/application support in payment quoting.
- Customer booking list and booking details.
- Professional booking list, details, OTP start flow, service progress, and completion flow.
- Admin booking review, assignment, status tracking, and operational dashboards.
- Manual and auto professional assignment support.
- Payment, refund, commission, payout, invoice, payroll, and finance ledger related flows.
- Customer invoice PDF generation/preview.
- Professional payroll/stipend slip PDF generation/preview.
- Professional onboarding with KYC/document collection.
- Admin document verification and request re-upload flow.
- Professional document re-upload flow for requested fields.
- Admin customer/professional suspend, block, reactivate, unblock, feature, verify, and re-upload actions.
- Firebase FCM notification support.
- Admin custom notification campaign feature.
- Help/support ticketing and chat-like ticket screens.
- Admin content and portfolio management for images/videos/text shown to customers.
- Customer portfolio browsing.
- Saved address/profile management.
- Location search, map picking, reverse geocoding, and current-location use.
- Network guard / connectivity awareness.
- Reports/dashboard style charts for admin revenue/payout and professional earnings.

## 3. Customer Features

Customer-facing features currently present:

- Login/signup using Firebase phone authentication and OTP.
- Browse home dashboard and service categories.
- View service detail pages for supported event-service categories.
- Select event type, professional type/plan, duration, event date/time, venue/address details, and booking information.
- Add one or more services to cart / booking summary.
- Proceed to checkout and pay using Razorpay.
- Choose payment mode: 20 percent advance or full payment.
- Apply coupon code during checkout where available.
- View booking status and booking history.
- View booking details, assigned professional details, event details, service information, and payment status.
- Pay remaining booking amount when applicable.
- View invoices / invoice history.
- Receive notifications.
- Manage profile and personal information.
- Manage saved addresses.
- Use location search/current location for address selection.
- Raise support tickets and view support conversations.
- View customer portfolio content managed by admin.

Customer data used:

- Phone number for login, booking communication, and security.
- Name/email where available for payment prefill and invoice records.
- Address/location/venue details for service delivery.
- Booking and payment details for transaction records and invoices.
- FCM token for notifications.
- Optional profile image through image picker.

## 4. Professional / Vendor Features

Professional-facing features currently present:

- Phone OTP authentication.
- Multi-step professional onboarding.
- Personal information: name, phone, gender, date of birth, language, address/location.
- Service/work information: selected service type, service specialities, professional type, team size, working days, working locations, secondary/travel locations, and profile/additional service questions.
- KYC uploads: Aadhaar PDF, PAN PDF, bank passbook PDF.
- Business/social fields: Google work drive URL and Instagram profile URL.
- Bank/payout details collection.
- Admin approval waiting screen.
- Document status screen.
- Requested document re-upload flow.
- Professional dashboard.
- Assigned/new/active/completed booking lists and booking detail screens.
- Accept/reject/handle assigned bookings.
- Booking start workflow using service OTP.
- Booking completion workflow.
- Earnings dashboard with KPI cards:
  - Net earnings till date.
  - Monthly earnings for current month.
  - Pending payout.
  - Settled payout.
- 12-month earnings bar chart.
- Payment/payout history and payout detail screen.
- Confirm released payout or raise payout dispute.
- View payroll/stipend slip PDF.
- Manage profile, availability schedule, working calendar, work days, locations, bank details, and account settings.
- Receive notifications.

Professional/vendor data used:

- Phone number and Firebase UID for login/account identity.
- Personal profile information.
- Location/address and working locations for matching/assignment.
- KYC identifiers and document uploads.
- Bank/UPI payout details.
- Service/pricing/availability data.
- Booking workflow activity.
- Payout confirmation/dispute activity.
- FCM token for notifications.

## 5. Admin Panel Features

Admin-facing features currently present:

- Admin dashboard with operational and financial KPIs.
- 12-month revenue/payout chart.
- Booking management and booking assignment.
- Customer management:
  - View customer records.
  - Suspend/reactivate customer.
  - Block/unblock customer.
  - Mark/unmark verified.
- Professional management:
  - View professional onboarding/profile records.
  - Approve/review professionals.
  - Verify documents.
  - Request document re-upload.
  - Request bank update.
  - Mark/remove featured professional.
  - Suspend/reactivate professional.
  - Block/unblock professional.
- Payments tab:
  - View revenue/payment records.
  - View customer invoice.
  - View refunds.
  - Approve/reject/complete refunds.
  - View/generate/reconcile payroll records.
  - Release professional payout.
  - View stipend/payroll slip.
  - View payment analytics.
- Notifications:
  - Send custom FCM notifications to customers, professionals, selected users, or broad recipient groups.
  - Track campaign result counts.
- Content and portfolio management:
  - Edit about/mission/why-choose text.
  - Upload/manage portfolio images and videos by service.
  - Control visibility/order/caption/media metadata.
- Service catalog management.
- Support/dispute management.
- Settings and finance configuration support.

Admin-sensitive actions are routed through backend Cloud Functions with Firebase Auth token checks and role enforcement.

## 6. Payment Flow

Payment gateway: Razorpay.

Customer initial checkout flow:

1. Customer creates/uses a booking draft.
2. App requests a payment quote from backend (`quoteCheckoutPayment`) for selected service, duration, plan, event type, payment mode, and optional coupon.
3. Backend calculates gross amount, discount, taxable amount, GST, final amount, payable amount, remaining amount, commission, and professional payout amount.
4. Customer creates Razorpay order through backend (`createPaymentOrder`).
5. App opens Razorpay checkout using `razorpay_flutter`.
6. On successful Razorpay payment, app sends payment ID/order ID/signature to backend (`verifyPayment`).
7. Backend verifies payment with Razorpay and updates:
   - Booking payment status.
   - Payment document.
   - Payment transaction record.
   - Finance ledger.
   - Coupon usage if applicable.
   - Admin visibility/lifecycle status.
8. Customer can see booking and payment status in customer screens.

Remaining payment flow:

1. If a booking was initially paid with advance, remaining amount is kept on the payment/booking record.
2. Customer can create remaining payment order (`createRemainingPaymentOrder`).
3. Razorpay checkout and backend verification run again.
4. Once fully paid, booking/payment status is updated accordingly.

Supported customer payment modes:

- `ADVANCE_20`: customer pays 20 percent advance; remaining amount is collected later.
- `FULL`: customer pays full booking amount.

Important payment identifiers:

- Booking ID/business code uses backend generated `BKG-YYYYMMDD-######`.
- Payment document uses booking document ID as payment ID in current implementation.
- Razorpay order ID is stored as gateway order ID.
- App/backend generated payment order code uses `ORD-YYYYMMDD-######`.
- Payment transaction code uses `TXN-YYYYMMDD-######`.

## 7. Wallet, Coupon, Refund, Commission, Payout Features

Wallet:

- No stored-value in-app wallet feature was found.
- Razorpay external wallet events are explicitly not supported in the current app flow.
- The app should not be described as a prepaid wallet, digital wallet, bank, or stored-value account unless a separate compliant wallet module is added.

Coupons:

- Coupon code can be entered during checkout.
- Backend quote/payment flow supports coupon code, coupon discount amount, coupon usage, and coupon application state.
- Coupon usage is associated with customer/payment/booking records.

Refunds:

- Refund records exist in backend/admin payment flows.
- Admin can approve, reject, and mark refund as completed.
- Refund policy copy in admin UI references:
  - More than 72 hours: full refund.
  - Less than 72 hours: up to 80 percent refund.
  - Less than 48 hours: up to 50 percent refund.
  - Less than 24 hours: no refund.
- Customer-facing refund visibility should remain clear in booking/payment details where refund status is shown.

Commission:

- Backend calculates platform commission during payment/payroll calculations.
- Commission percent defaults/settings are used for professional payout calculation.
- Commission amount is stored in finance/payment/payroll records.

Payout:

- Professional payout is generated after completed and fully paid bookings.
- Payroll records include gross booking amount, GST, commission percent, commission amount, other charges, and net payout amount.
- Admin releases payout manually by entering a transaction reference.
- Professional can view payout history and confirm receipt or report a dispute.
- Payout slip/stipend PDF can be generated/viewed.

## 8. KYC / Document Verification Features

Professional KYC/document features:

- Aadhaar number collection.
- Aadhaar card PDF upload.
- PAN number collection.
- PAN card PDF upload.
- Bank passbook PDF upload.
- Bank account and UPI fields for payout.
- Google work drive URL.
- Instagram profile URL.
- Admin document verification status.
- Admin request re-upload flow for selected fields.
- Professional re-upload screen/service for requested documents or URL fields.

Request re-upload fields currently intended/supported:

- Aadhaar card.
- PAN card.
- Bank passbook.
- Google work drive URL.
- Instagram profile URL.

Upload handling:

- Document uploads use Firebase Storage.
- Professional re-upload size limit is 5 MB per file.
- Re-upload service accepts PDF by default and can also infer image content types for JPG/PNG where selected.

Policy note:

- Aadhaar and PAN are government-issued identity information. Google Play Data safety declarations should treat these as sensitive personal information / government ID information where applicable.
- The app should clearly explain why these are collected: professional verification, fraud prevention, payout compliance, and marketplace trust/safety.

## 9. Bank / UPI / PAN / Aadhaar Details Collected

Current implementation indicates collection/storage/display of the following professional data:

- Aadhaar number: yes.
- Aadhaar PDF upload: yes.
- PAN number: yes.
- PAN PDF upload: yes.
- Bank account number: yes.
- Bank name: yes.
- Bank branch name: yes.
- IFSC code: yes.
- UPI ID: yes.
- Bank passbook PDF upload: yes.
- Google work drive URL: yes.
- Instagram profile URL: yes.

Customer side:

- No customer Aadhaar/PAN/bank-account KYC collection was found.
- Customer payment card/bank/UPI details are handled by Razorpay checkout, not directly collected by the app UI.

Admin side:

- Admin can view/manage professional document and bank verification/update statuses.
- Admin can request bank update or document re-upload.

## 10. Invoice And Payroll Slip Features

Customer invoice:

- Customer invoice PDF generation/preview exists.
- Invoice data includes customer details, booking ID, payment ID, order ID, transaction ID, service details, event details, venue/address details, subtotal, discount, taxable amount, GST, total amount, paid amount, remaining amount, payment option, and payment status.
- Backend creates invoice records after booking completion/financial reconciliation.
- Invoice business ID uses generated `INV-CUS-YYYYMMDD-######` where backend-generated data is available.

Professional payroll/stipend slip:

- Professional payroll PDF generation/preview exists.
- Payroll data includes payroll ID, booking ID, professional ID, professional details, event/service details, gross booking amount, GST, commission, net payout, payout status, release date, release admin, transaction reference, and professional confirmation/dispute status.
- Backend creates payroll records after completed and fully paid bookings.
- Payroll business ID uses generated `PAY-PRO-YYYYMMDD-######` where backend-generated data is available.
- Admin can view payroll slip from payment/payroll tab.
- Professional can view payout history/detail and payroll slip.

## 11. Health, Government, Finance, Loan, Wallet, Insurance, Crypto, VPN Related Features

Health:

- No health, medical diagnosis, health tracking, medicine, or hospital-service functionality was found.
- Event venue address examples may mention hospitals as landmarks/locations, but the app is not a healthcare app.

Government:

- The app collects professional Aadhaar and PAN information for KYC/document verification.
- The app is not a government app and should not imply government affiliation.

Finance:

- The app processes customer booking payments through Razorpay.
- The app calculates GST/taxable amount, commission, refunds, and professional payouts.
- The app generates invoices and payroll/stipend slips.
- The app is not a bank, NBFC, lending app, investment app, crypto app, or insurance provider.

Loan:

- No loan, credit, BNPL, lending, EMI underwriting, or credit scoring feature was found.

Wallet:

- No app-managed stored-value wallet was found.
- Razorpay external wallet callbacks are not supported by current app logic.

Insurance:

- No insurance product or claim management feature was found.

Crypto:

- No cryptocurrency, token, exchange, wallet, trading, or mining feature was found.

VPN:

- No VPN, proxy, network tunneling, device traffic interception, or VpnService usage was found.

## 12. Android Permissions Used

Source: `android/app/src/main/AndroidManifest.xml`

| Permission | Declared | Purpose in app |
| --- | --- | --- |
| `android.permission.ACCESS_FINE_LOCATION` | Yes | Used for current location, map picker, address selection, location-based service/booking fields, and professional working/location setup. |
| `android.permission.ACCESS_COARSE_LOCATION` | Yes | Used as approximate location fallback for address/location features. |
| `android.permission.INTERNET` | Yes | Required for Firebase, Firestore, Firebase Storage, Cloud Functions, Razorpay, Google Maps/Places, notifications, media loading, and network APIs. |
| `android.permission.POST_NOTIFICATIONS` | Yes | Required on Android 13+ for FCM push notifications to customers, professionals, and admins. |
| `android.permission.CAMERA` | No | Not declared in main manifest. Some UI uses `image_picker` with camera option for profile photos. If camera capture is retained, verify runtime behavior and Play declaration requirements. |
| `android.permission.READ_EXTERNAL_STORAGE` | No | Not declared in main manifest. File/media selection appears to use system/file picker plugins. |
| `android.permission.WRITE_EXTERNAL_STORAGE` | No | Not declared in main manifest. |
| `android.permission.READ_MEDIA_IMAGES` | No | Not declared in main manifest. |
| `android.permission.READ_MEDIA_VIDEO` | No | Not declared in main manifest. |
| `android.permission.READ_MEDIA_AUDIO` | No | Not declared in main manifest. |
| `android.permission.MANAGE_EXTERNAL_STORAGE` | No | Not used. |
| `android.permission.SEND_SMS` | No | Not used. App uses Firebase phone auth and OTP autofill packages, not direct SMS sending. |
| `android.permission.READ_SMS` | No | Not declared. |
| `android.permission.RECEIVE_SMS` | No | Not declared. |
| `android.permission.READ_PHONE_STATE` | No | Not used. |
| `android.permission.CALL_PHONE` | No | Not used. |
| `android.permission.BIND_VPN_SERVICE` / VPN service | No | Not used. |

Other Android manifest details:

- Google Maps API key metadata is configured with `${googleMapsApiKey}`.
- Main activity is exported for launcher use.
- Text processing query exists because Flutter adds `PROCESS_TEXT` query support.
- Debug/profile manifests declare `INTERNET` for development builds.

Permission/data safety notes:

- Location permission should be declared as used for user-requested address/venue/location selection and professional service-area setup.
- Notification permission should be declared for booking updates, payment/refund/payout updates, admin custom notifications, and service lifecycle alerts.
- No SMS/phone permission should be declared in Play Console unless added later.
- No broad storage permission should be declared unless added later.
- If camera capture remains available in profile screens, confirm whether the final Android build requires camera permission. If `CAMERA` is added later, explain it as user-initiated profile photo capture only.

## Data Safety / Policy Checklist

Recommended Play Console Data safety areas to review:

- Personal info:
  - Name.
  - Phone number.
  - Email address where available.
  - Address/location/venue details.
  - Date of birth/gender/languages for professionals.
- Financial info:
  - Customer payment records and transaction identifiers.
  - Professional bank account/IFSC/UPI details.
  - Payout records.
  - Refund records.
  - Invoices/payroll slips.
- Government IDs:
  - Professional Aadhaar number/document.
  - Professional PAN number/document.
- Photos/videos/files:
  - Profile images.
  - Portfolio media.
  - Professional KYC PDFs.
  - Support attachments if used.
- Location:
  - Precise/approximate location for address and map selection.
- App activity:
  - Booking actions, service status, payment status, support tickets, notifications.
- Device or other IDs:
  - Firebase UID.
  - FCM token.
  - Razorpay transaction/order identifiers.

Recommended privacy policy explanations:

- Why professional KYC is required.
- How Aadhaar/PAN/bank details are used and protected.
- That customer payment instrument details are processed by Razorpay, not stored directly by ClickNow app UI.
- How location is used for service address selection and professional matching.
- How notifications are used for booking/payment/support/marketing updates.
- How users can contact support for deletion/correction/account issues.

## Implementation Notes For Play Store Review

- App label in manifest is currently `clicknow_version2`; update to the production app name before release if needed.
- Because government ID and financial payout data are collected for professionals, privacy policy and Data safety answers must be explicit.
- Do not market the app as a wallet, loan, investment, insurance, crypto, VPN, healthcare, or government app.
- If offers/festival/admin custom notifications are used for marketing, ensure notification opt-in/permission behavior and privacy policy language cover promotional notifications.
- If profile photo camera capture is kept, verify final manifest/permission behavior before Play submission.
- For Play review, keep test credentials/instructions ready for all three panels if reviewers need to access customer, professional, and admin flows.
