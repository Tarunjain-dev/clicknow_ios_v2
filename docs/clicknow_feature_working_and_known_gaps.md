# ClickNow Feature Working, Frontend Behavior, Backend Flow, and Known Gaps

## Purpose

This document explains the current implementation and expected behavior of:

1. Add to Cart, Your Bookings/Cart, and Checkout
2. Admin suspend/block CTAs
3. Professional payroll release and customer refunds
4. Professional document re-upload requests
5. Consistent IDs across the application
6. Booking and payment date-time validation
7. Dialog and bottom-sheet red error screen/crash causes

The descriptions are based on the current Flutter and Firebase Functions implementation.

---

## 1. Add to Cart, Your Bookings, and Proceed to Checkout

### Current frontend flow

1. A customer fills the service booking form and selects:
   - Service and event type
   - Pricing plan
   - Event date and time
   - Duration
   - Venue and contact details
2. `customer_service_detail_template.dart` validates the form and creates a `CustomerBookingItem`.
3. Selecting **Add to cart** stores the item under:

   ```text
   users/{customerUid}/cart/{cartItemId}
   ```

4. `CustomerBookingController` listens to the cart collection and updates the **Your Bookings** cart screen.
5. The customer can edit or delete cart items before checkout.
6. Selecting **Proceed to checkout** copies the current cart items into checkout state and requests an authoritative backend quote.

Important files:

- `lib/app/screens/customer/home/services/widgets/customer_service_detail_template.dart`
- `lib/app/screens/customer/getx/customer_booking_controller.dart`
- `lib/app/screens/customer/home/customer_bookings_screen.dart`
- `lib/app/services/booking/booking_service.dart`
- `lib/app/services/payments/razorpay_payment_service.dart`

### Current multi-service limitation

The cart supports one or more services, but payment checkout currently supports only one service at a time.

`submitCheckoutBookings()` explicitly blocks grouped checkout:

```text
One Booking Per Checkout
Please pay for one booking at a time until grouped checkout is enabled.
```

Therefore:

- Multiple items can exist in the cart.
- The current **Proceed to checkout** action copies all items.
- Checkout then rejects submission when more than one item exists.

### Required target behavior for multiple services

The frontend should provide one of these explicit experiences:

#### Recommended: individual booking checkout

- Cart allows multiple items.
- Each item has a **Checkout this service** CTA.
- The main **Proceed to checkout** CTA requires the customer to select one item.
- Each service creates its own booking, payment order, transaction, refund, invoice, and payroll records.

This is the safest implementation because different services may have different professionals, event dates, refund states, and payouts.

#### Alternative: grouped checkout

Grouped checkout requires a parent checkout/order entity:

```text
checkout_groups/{groupId}
  bookingIds: [...]
  totalAmount
  paidAmount
  paymentStatus
```

The backend must atomically create one booking per service and distribute the captured payment across those bookings. This is not currently implemented.

### Authoritative pricing behavior

Checkout does not trust cart totals. The backend `quoteCheckoutPayment` function recalculates pricing using:

- `serviceCatalogId`
- `eventTypeId`
- `planKey`
- `eventDurationHours`
- Coupon
- GST and commission settings

The checkout frontend now:

- Displays the backend quote.
- Shows a retryable error instead of loading forever.
- Prevents booking creation without a valid quote.
- Uses the authoritative quote as the displayed checkout total.

### Booking creation behavior

After a valid quote:

1. `createBookingDraft` creates a hidden `DRAFT`/`UNPAID` canonical booking.
2. `createPaymentOrder` creates the Razorpay order.
3. Razorpay checkout opens.
4. `verifyPayment` validates signature, order, captured amount, and currency.
5. Only after capture is the booking activated and made visible to Admin.

---

## 2. Suspend/Block Professional and Customer CTAs

### Frontend behavior

Admin account actions are available in:

- Professional review details screen
- Customer details screen

The available CTAs depend on `accountStatus`:

| Current status | Available actions |
|---|---|
| `ACTIVE` | Suspend, Block |
| `SUSPENDED` | Reactivate, Block |
| `BLOCKED` | No further action button currently shown |

Suspend and block actions require a mandatory reason dialog. Reactivate uses a confirmation dialog.

Important files:

- `lib/app/screens/admin/professionals/professional_review_details_screen.dart`
- `lib/app/screens/admin/customers/customer_details_screen.dart`
- `lib/app/services/admin_user_management_service.dart`

### Backend behavior

All actions call the backend function:

```text
adminManageUserAccount
```

The backend:

1. Verifies that the caller is an Admin.
2. Validates the target user ID and expected role.
3. Validates that the requested action is allowed for that role.
4. Requires a reason for suspend/block actions.
5. Updates `users/{uid}`.
6. For professionals, also updates `professional_profiles/{uid}`.
7. Writes an immutable Admin action log.

### Suspend behavior

Suspend sets:

```text
accountStatus: SUSPENDED
suspensionReason
suspendedAt
suspendedBy
professionalAvailableForBooking: false
professionalAvailabilityStatus: offline
```

A suspended user cannot perform protected backend actions because `requireActiveAccount()` rejects suspended accounts.

### Block behavior

Block sets:

```text
accountStatus: BLOCKED
blockedReason
blockedAt
blockedBy
professionalAvailableForBooking: false
professionalAvailabilityStatus: offline
```

A blocked user is rejected from protected backend actions with permission denied.

### Suspend versus block

- **Suspend** is intended to be temporary and can be reactivated.
- **Block** is intended as a stronger restriction.
- The backend does support `UNBLOCK_*`, but the current Admin detail screens hide all actions for blocked users. Therefore, the frontend currently has no visible unblock CTA.

### Frontend response requirement

After an action succeeds:

- The Admin screen should update from the Firestore stream.
- The status badge and available CTAs should change.
- The affected user should see a clear suspended/blocked message.
- Protected APIs must remain the final enforcement layer; hiding frontend buttons alone is insufficient.

---

## 3. Payroll Release to Professionals and Refund Visibility for Customers

## 3.1 Professional payroll

### Payroll generation

A payroll record is generated after booking completion only when the booking is fully paid.

The payroll document contains:

```text
payrollId
payrollDocumentId
bookingId
professionalId
bookingAmount
commissionAmount
gstAmount
netPayoutAmount
payoutStatus: PENDING
```

The payroll document ID is currently the booking document ID. The human-readable payroll ID uses the `PAY-PRO-*` format.

### Admin release flow

Admin opens:

```text
Admin > Payments > Payroll
```

For a pending payroll:

1. Admin selects **Release Payout**.
2. Frontend asks for a mandatory transaction reference.
3. Frontend calls `releaseProfessionalPayout`.
4. Backend verifies:
   - Caller is Admin.
   - Payroll exists.
   - Payroll is not already released.
   - Customer payment is fully paid.
5. Backend updates:

   ```text
   payoutStatus: RELEASED
   releasedAt
   releasedBy
   transactionReference
   stipendSlipId
   ```

6. Backend creates a stipend-slip record and finance-ledger entry.

Important files:

- `lib/app/screens/admin/payments/admin_payments_screen.dart`
- `lib/app/services/payments/razorpay_payment_service.dart`
- `functions/index.js` → `releaseProfessionalPayout`

### Professional frontend response

`ProfessionalEarningsController` streams payroll documents filtered by `professionalId`.

When Admin releases a payout:

- Status changes from `PENDING` to `RELEASED`.
- Pending payout decreases.
- Settled/released amount increases.
- Payment history shows transaction reference and payout date.
- Professional can open payment details/history.

Important files:

- `lib/app/screens/professional/professionalDashboard/earnings/getx/professionalEarnings_Controller.dart`
- `professional_payment_history_screen.dart`
- `professional_payment_details_screen.dart`

### Current gap

There is no explicit professional **Confirm payout received** action. The current source of truth is the Admin release record.

If confirmation is required, add:

```text
professionalConfirmationStatus: PENDING | CONFIRMED | DISPUTED
professionalConfirmedAt
professionalConfirmationComment
```

and a backend command that allows only the payroll's professional to confirm/dispute.

## 3.2 Customer refund

### Refund backend flow

Refunds can be created after cancellation or through `processRefund`.

The backend:

1. Calculates eligible captured amount.
2. Subtracts already completed refunds.
3. Applies the refund policy.
4. Requests a Razorpay refund when possible, otherwise marks it for manual review.
5. Creates a refund record and ledger entry.
6. Updates booking/payment status.

Typical statuses:

```text
REQUESTED
APPROVED
PROCESSING
UNDER_REVIEW
COMPLETED
REFUNDED
REJECTED
PROVIDER_FAILED
```

Admin can approve, reject, or complete a refund from the Refunds tab.

### Customer frontend response

The customer booking details screen currently displays:

- Refund eligibility
- Refund percentage
- Booking payment status

The recent customer financial normalization ensures paid, remaining, and payment status remain consistent.

### Current refund frontend gap

The customer screen does not yet provide a complete refund-status card with:

- Refund ID
- Refund amount
- Refund status
- Requested date
- Processed/completed date
- Refund mode
- Provider/reference ID

Recommended frontend:

```text
Refund Status
Refund ID: REF-YYYYMMDD-XXXXXX
Amount: Rs.X
Status: Processing / Completed
Expected destination: Original payment method
Processed on: ...
Reference: ...
```

The customer UI should stream the refund record associated with the booking and update automatically.

---

## 4. Request Re-upload Document

### Admin frontend

Admin opens a professional review screen and selects **Request Re-upload**.

The bottom sheet requires:

- At least one requested document
- Mandatory reason

Allowed document keys:

```text
identity_proof
address_proof
profile_photo
work_samples
bank_document
agreement
```

The frontend calls `adminManageUserAccount` with:

```json
{
  "action": "REQUEST_REUPLOAD",
  "targetUserRole": "professional",
  "reason": "...",
  "requestedDocuments": ["identity_proof"]
}
```

### Backend behavior

The backend validates Admin access, reason, and requested document keys. It updates both the user and professional profile:

```text
approvalStatus: REUPLOAD_REQUIRED
professionalStatus/status: reupload_requested
reuploadStatus: REQUESTED
reuploadReason
reuploadRequestedDocuments
reuploadRequestedAt
reuploadRequestedBy
professionalAvailableForBooking: false
professionalAvailabilityStatus: offline
```

It also writes an Admin action audit log.

### Professional frontend

The professional approval screen already shows:

- “Admin has requested document re-upload.”
- Requested document names
- Admin reason

### Can the professional re-upload?

The professional registration controller supports uploading and resubmitting profile documents. Submitting the profile changes the approval state back to pending/under review.

However, the current approval screen only clearly displays the request. It does not expose a focused **Re-upload requested documents** CTA that opens directly to the required document inputs.

### Recommended target behavior

Add a CTA on the approval screen:

```text
Re-upload Requested Documents
```

The CTA should:

1. Open a document-upload screen filtered to requested document keys.
2. Require every requested document to be replaced.
3. Upload new files.
4. Call a backend `submitRequestedDocumentReupload` command.
5. Backend validates requested items and changes:

   ```text
   reuploadStatus: SUBMITTED
   approvalStatus: pending
   professionalStatus: under_review
   reuploadSubmittedAt
   ```

This should be backend-controlled rather than relying only on direct client profile writes.

---

## 5. Constant IDs Across the Application

### ID types

The system uses two kinds of IDs:

1. **Document/internal ID**: Firestore document ID or Firebase Auth UID.
2. **Business/human-readable ID**: stable ID displayed to users and Admin.

Examples:

| Object | Internal ID | Business ID |
|---|---|---|
| Customer | Firebase Auth UID | Customer code, not yet centrally generated |
| Professional | Firebase Auth UID | Professional code, not yet centrally generated |
| Booking | Firestore booking document ID | `BKG-YYYYMMDD-XXXXXX` |
| Order | Razorpay/backend order record | `ORD-YYYYMMDD-XXXXXX` |
| Transaction | Payment transaction document | `TXN-YYYYMMDD-XXXXXX` |
| Refund | Refund document ID | `REF-YYYYMMDD-XXXXXX` |
| Invoice | Booking/invoice document ID | `INV-CUS-YYYYMMDD-XXXXXX` |
| Payroll | Booking/payroll document ID | `PAY-PRO-YYYYMMDD-XXXXXX` |

### Current backend behavior

`nextHumanId()` generates business IDs using a transactional daily counter. This prevents duplicate IDs during concurrent backend requests.

Booking/payment/refund/invoice/payroll business IDs are stored when created and should never be regenerated for the same object.

### Current ID bug

Some frontend screens derive customer IDs locally from the UID:

```text
CU + first/last six sanitized UID characters
```

Different screens use different first/last substring logic. Therefore, the same customer can appear with different customer IDs in different Admin screens.

Some models also fall back to generated display strings such as:

```text
BID-{documentId}
```

These fallbacks can make one booking appear to have multiple IDs.

### Required ID contract

Every object must have:

```text
documentId: internal immutable reference
businessId: immutable display identifier
```

Recommended canonical fields:

```text
users/{uid}.customerCode = CUS-YYYYMMDD-XXXXXX
users/{uid}.professionalCode = PRO-YYYYMMDD-XXXXXX
bookings/{id}.bookingCode = BKG-YYYYMMDD-XXXXXX
payments/{id}.paymentCode/orderCode
payment_transactions/{id}.transactionCode
refunds/{id}.refundId
invoices/{id}.invoiceId
payrolls/{id}.payrollId
```

Rules:

- Generate once on the backend.
- Persist on the canonical object.
- Copy the same value into read models.
- Never create display IDs in Flutter.
- Admin commands should accept internal document IDs, while the UI displays business IDs.
- Search should support both internal ID and business ID.
- Never use a Razorpay payment/order ID as the ClickNow business transaction ID.

### Required migration

Existing users without codes need a reconciliation/migration script that:

1. Assigns one customer/professional code.
2. Writes it to the user/profile.
3. Updates dependent read models if needed.
4. Reports duplicates and missing IDs.

---

## 6. Date-Time Working and Validation

## 6.1 Booking frontend

The service form uses Flutter date and time pickers.

Current date picker validation:

- First date is today.
- Last date is approximately two years in the future.
- Event date and event time are mandatory.
- Duration must be greater than zero.

Current duration/pricing behavior:

```text
service subtotal = rate per hour × duration hours
GST = subtotal × GST rate
final amount = subtotal + GST - applicable discount adjustment
```

### Current date-time gaps

1. Selecting today with a time already in the past is not explicitly blocked.
2. Date and time are stored separately, which makes timezone and comparison logic harder.
3. Backend `timestampFromInput()` validates date syntax but does not currently reject past event dates.
4. Event duration is limited to 24 hours by authoritative pricing, but frontend validation only checks greater than zero.
5. Professional availability/day matching is performed separately and may not validate time-slot overlap precisely.

### Recommended booking date-time contract

Store:

```text
eventStartAt: UTC Firestore Timestamp
eventEndAt: UTC Firestore Timestamp
eventTimezone: Asia/Kolkata
durationMinutes
```

Validate on both frontend and backend:

- Start must be sufficiently in the future.
- End must be after start.
- Duration must be within configured limits.
- Professional must be available for the complete interval.
- No overlapping confirmed/in-progress booking.
- Reschedule must pass the same validation.

The backend must be authoritative because device clocks can be incorrect.

## 6.2 Payment/refund/payroll date-time

Financial timestamps must always use backend server timestamps:

```text
createdAt
paidAt
capturedAt
refundRequestedAt
refundCompletedAt
releasedAt
updatedAt
```

The backend currently uses Firestore server timestamps for key financial transitions. Frontend device time should be used only for display or temporary UI state.

Refund policy timing is calculated from the booking event date and current backend time. This prevents customers from changing device time to affect eligibility.

---

## 7. Dialog and Bottom-Sheet Red Error Screen/Crash

A Flutter red error screen means an uncaught framework/runtime exception occurred. Dialogs and bottom sheets commonly expose lifecycle and layout issues because they create temporary routes and contexts.

### Main likely causes in this application

#### 1. Using a disposed context after `await`

Example pattern:

```dart
final result = await showDialog(...);
await someAsyncAction();
Navigator.pop(context);
```

If the parent screen or dialog was closed while waiting, `context` may no longer be mounted.

Fix:

```dart
if (!context.mounted) return;
```

before navigation, `setState`, snackbar, or opening another route.

#### 2. Calling `setState()` after a widget is disposed

An async callback may finish after the dialog/bottom sheet or screen has closed.

Fix:

```dart
if (!mounted) return;
setState(() {});
```

For `StatefulBuilder`, verify the sheet/dialog context is still mounted before calling its setter.

#### 3. Mixing `Get.back()` and `Navigator.pop(context)`

Using both navigation systems without controlling which route/context owns the dialog can pop the wrong route or attempt to pop an already-closed route.

Fix:

- Use `Navigator.pop(dialogContext, result)` for `showDialog`.
- Use `Navigator.pop(sheetContext, result)` for `showModalBottomSheet`.
- Use `Get.back()` only for overlays opened through GetX.
- Prevent double taps while an action is running.

#### 4. Double submission/double pop

A CTA can be tapped twice before it becomes disabled, resulting in:

- Two API calls
- Two `Navigator.pop()` calls
- State updates after the overlay closes

Fix:

- Keep an `isSubmitting` flag.
- Disable all dialog actions while submitting.
- Pop once only after success.

#### 5. Dialog/bottom-sheet overflow when keyboard opens

Bottom sheets with text fields can overflow when the keyboard reduces available height.

Fix:

- Use `isScrollControlled: true`.
- Add bottom padding using `MediaQuery.viewInsetsOf(context).bottom`.
- Wrap content with `SingleChildScrollView`.
- Avoid fixed-height content that exceeds the viewport.

#### 6. Controller lifecycle problems

Locally-created `TextEditingController`, `FocusNode`, animation controller, or stream must be disposed after the overlay closes. Conversely, it must not be disposed while the overlay is still using it.

#### 7. Null assertions and invalid route context

Using `child!`, `Get.context!`, or another forced-null assertion inside an overlay can create a red screen when the value is unexpectedly null.

### Debugging procedure

When a red screen appears:

1. Capture the first exception line and full stack trace from the debug console.
2. Identify the first project file/line in the trace.
3. Check for:
   - `setState() called after dispose`
   - `Looking up a deactivated widget's ancestor`
   - `Navigator operation requested with a context that does not include a Navigator`
   - `A TextEditingController was used after being disposed`
   - `RenderFlex overflowed`
   - Null check operator used on a null value
4. Reproduce with slow network and rapid double taps.
5. Add mounted checks and action loading guards at the exact failing path.

### Recommended reusable overlay standard

Create shared dialog/bottom-sheet helpers that enforce:

- Correct owning context
- Scroll-safe keyboard layout
- Loading state and double-tap prevention
- Mounted checks after awaits
- Standard error display
- Controller disposal

---

## Implementation Status Summary

| Feature | Current status |
|---|---|
| Add one service to cart and checkout | Implemented |
| Multiple services in cart | Implemented |
| Grouped/multi-service payment checkout | Not implemented; currently blocked |
| Authoritative backend checkout pricing | Implemented |
| Suspend/block professional/customer | Implemented frontend and backend |
| Unblock CTA | Backend supported; frontend CTA currently missing for blocked users |
| Admin payroll release | Implemented |
| Professional sees released payroll | Implemented through payroll stream |
| Professional confirms receipt | Not implemented |
| Backend refund lifecycle | Implemented |
| Customer detailed refund tracking card | Partially implemented; needs dedicated frontend |
| Admin requests professional document re-upload | Implemented |
| Professional sees request/reason/documents | Implemented |
| Focused requested-document re-upload CTA/command | Not fully implemented |
| Stable booking/payment/refund/payroll IDs | Mostly implemented on backend |
| Stable customer/professional business IDs | Not implemented centrally; frontend derivation is inconsistent |
| Booking date/time frontend validation | Partially implemented |
| Authoritative backend past-time/slot validation | Needs improvement |
| Dialog/bottom-sheet lifecycle safety | Applied inconsistently; needs shared standard and targeted fixes |

