# Booking Reschedule — Feature Overview

This document summarizes how the booking reschedule feature works end‑to‑end: customer UI, backend endpoints, admin flows, data model changes, notifications, and verification steps.

## Purpose
- Allow customers to request a reschedule for an existing booking.
- Allow admins to approve or reject the reschedule request.
- Ensure booking read models (customer/professional/admin) reflect the reschedule lifecycle state.

## Actors
- Customer — requests reschedule from the booking details screen.
- Admin — reviews and approves/rejects reschedule requests.
- Professional — sees reschedule requests in their booking mirror and reacts if required.

## Key Backend Endpoints (Cloud Functions)
- `requestBookingReschedule` — customers request a reschedule.
  - Implementation: [functions/index.js](functions/index.js#L912)
  - Auth: requires an active `customer` account.
  - Input: `bookingId`, `newEventDate` (ISO), `newEventTime` (string), `reason`.
  - Behavior: validates booking state; writes a patch that sets `bookingStage: "reschedule_requested"` and adds `rescheduleRequest` object (`requestedBy`, `requestedAt`, `newEventDate`, `newEventTime`, `reason`, `status: "pending"`); sets `statusTimeline.rescheduleRequestedAt`.

- `adminReviewBookingReschedule` — admin approves/rejects a pending reschedule.
  - Implementation: [functions/index.js](functions/index.js#L1067)
  - Auth: requires an active `admin` account.
  - Input: `bookingId`, `action` (`APPROVE` or `REJECT`), `reason` (required for `REJECT`).
  - Behavior: validates pending request, then in a transaction:
    - On `APPROVE`: updates booking status fields (sets `status`, `lifecycleStatus`, `bookingStatus` to approved values), applies the new `eventDate`/`eventTime` from `rescheduleRequest`, clears assignment fields (`assignedProfessionalId`, etc.), marks `rescheduleRequest.status` = `approved`, records `approvedBy`/`approvedAt`.
    - On `REJECT`: writes `rescheduleRequest.status` = `rejected` and stores rejection metadata.

Notes: Both functions use `writeBookingCopies` to update the main booking document and materialized read models under `/users/*/customerBookings` and `/users/*/professionalBookingRequests`.

## Client (Flutter) — where the feature is triggered
- Customer UI: [lib/app/screens/customer/home/customer_booking_details_screen.dart](lib/app/screens/customer/home/customer_booking_details_screen.dart#L1827)
  - `_requestReschedule()` shows date/time pickers and a reason dialog, calls `BookingService.requestReschedule`.

- Booking service: [lib/app/services/booking/booking_service.dart](lib/app/services/booking/booking_service.dart#L768)
  - `rescheduleBooking` -> calls backend `requestBookingReschedule` with `newEventDate` and `newEventTime`.
  - `requestReschedule` is a small wrapper used by the UI.

- Admin UI: [lib/app/screens/admin/bookings/getx/admin_bookings_controller.dart](lib/app/screens/admin/bookings/getx/admin_bookings_controller.dart#L576)
  - `approveReschedule` and `rejectReschedule` call `BookingService.approveReschedule` / `BookingService.rejectReschedule` which invoke `adminReviewBookingReschedule`.

- Professional & other UI: dashboards and lists use the booking mirror to show `reschedule_requested` lifecycle and to protect actions while pending.
  - Examples: [lib/app/screens/professional/professionalDashboard/bookings/getx/professionalBookings_Controller.dart](lib/app/screens/professional/professionalDashboard/bookings/getx/professionalBookings_Controller.dart#L180)

## Data model — booking document fields affected
- `bookingStage` set to `reschedule_requested` on customer request.
- `rescheduleRequest` object added/updated:
  - `requestedBy`, `requestedAt` (server timestamp), `newEventDate`, `newEventTime`, `reason`, `status` (`pending`/`approved`/`rejected`), `approvedBy`/`approvedAt`, `rejectedBy`/`rejectedAt`, `rejectionReason`.
- `statusTimeline.rescheduleRequestedAt` timestamp is set.
- On admin `APPROVE` the booking's `eventDate` and `scheduledDate` are overwritten with `rescheduleRequest.newEventDate` and `eventTime`, and assignment fields are cleared so the booking is re-assigned.

Read models
- `writeBookingCopies` writes the canonical booking into:
  - `/bookings/{bookingId}` (primary)
  - `/customerBookingRequests/{bookingId}` (mirror)
  - `/users/{customerId}/customerBookings/{bookingId}` (customer view)
  - `/users/{professionalId}/professionalBookingRequests/{bookingId}` (professional view) — only when professionalId is present.

## Notifications
- Current codebase: reschedule request and admin review flows do not send explicit push notifications inside those two HTTP functions. There are many `safeCreateAndSendNotification` usages elsewhere; the helper lives in [functions/index.js](functions/index.js#L3485).
- Because `writeBookingCopies` updates read models, clients (admin/professional) see the change in real time if they listen to Firestore snapshots.

Recommendation (if desired): add explicit notifications in these places:
- After `requestBookingReschedule` completes: notify assigned professional(s) and admin group (or admin users) so they get an immediate push notification.
- After `adminReviewBookingReschedule` approve/reject: notify the customer about the outcome.

## Security & Validation
- `requestBookingReschedule` enforces `requireActiveAccount(uid, "customer")`.
- `adminReviewBookingReschedule` enforces `requireActiveAccount(uid, "admin")`.
- Both endpoints validate inputs and booking state (e.g., cannot reschedule COMPLETED/CANCELLED/REJECTED bookings).

## Verification / Testing checklist
1. Customer requests reschedule
   - On UI, pick future `newDate` and `newTime`, enter reason, submit.
   - Verify Firestore `/bookings/{id}` contains `rescheduleRequest` with `status: "pending"` and `statusTimeline.rescheduleRequestedAt` exists.
   - Verify customer booking mirror under `/users/{customerId}/customerBookings/{id}` is updated.

2. Admin reviews
   - From admin UI, click Approve or Reject.
   - Verify Firestore booking doc updates: on APPROVE, `eventDate`/`scheduledDate` updated, `rescheduleRequest.status` set to `approved`, `approvedBy`/`approvedAt` set; on REJECT, `rescheduleRequest.status` set to `rejected` and `rejectionReason` stored.

3. Professional behavior
   - If the booking had an assigned professional, verify their professional mirror is updated and any existing professional request doc is deleted when admin approves (code deletes old professional mirror if `oldProfessionalId` is present).

4. Optional push tests
   - If you add notification sends, verify tokens are delivered and check `users/{uid}/notifications` documents are created.

## Files to inspect (quick links)
- Backend functions: [functions/index.js](functions/index.js)
  - Request reschedule: [functions/index.js](functions/index.js#L912)
  - Admin review reschedule: [functions/index.js](functions/index.js#L1067)
  - Notification helper: [functions/index.js](functions/index.js#L3485)
- Client (Flutter):
  - Customer booking details & reschedule UI: [lib/app/screens/customer/home/customer_booking_details_screen.dart](lib/app/screens/customer/home/customer_booking_details_screen.dart#L1827)
  - Booking service calls: [lib/app/services/booking/booking_service.dart](lib/app/services/booking/booking_service.dart#L768)
  - Admin bookings controller (approve/reject): [lib/app/screens/admin/bookings/getx/admin_bookings_controller.dart](lib/app/screens/admin/bookings/getx/admin_bookings_controller.dart#L576)

## Suggested next changes (if you want enhancements)
- Send explicit notifications on request and on admin decision (add `safeCreateAndSendNotification` calls after each transaction).
- Add audit logs for reschedule events (if not already covered by adminActionLogs).
- Add unit/integration tests for `requestBookingReschedule` and `adminReviewBookingReschedule` (mock Firestore transaction assertions).

## Short summary
- The reschedule flow is implemented as two secured Cloud Functions and client calls from Flutter. The functions update booking documents and materialized mirrors; clients observe Firestore changes in real time. The system currently relies on Firestore real‑time updates to inform admin/professional UIs; there are no explicit push notifications in these functions by default.

---
If you want, I can: (A) add push notifications to these functions, (B) add unit tests for the flows, or (C) implement a small audit entry when reschedule actions happen — which do you prefer next?
