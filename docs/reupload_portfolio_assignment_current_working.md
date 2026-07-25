# ClickNow - Re-upload, Portfolio, and Booking Assignment Working Notes

Last reviewed: 18 June 2026

This document explains the current implementation of three admin-controlled features and records the production-ready direction before we improve the UI and behavior.

## 1. Request Re-upload Documents

### Current purpose

Admin can ask a professional to re-submit selected verification documents when the existing uploaded data is wrong, unreadable, expired, or incomplete. The request changes the professional account into a re-upload required state, and the professional gets a frontend action to upload the requested documents again.

### Current admin frontend

Main files:

- `lib/app/screens/admin/professionals/professional_review_details_screen.dart`
- `lib/app/screens/admin/professionals/getx/admin_professionals_controller.dart`
- `lib/app/services/admin_user_management_service.dart`

Current flow:

1. Admin opens a professional review/details screen.
2. Admin clicks the re-upload action.
3. A bottom sheet opens with checkbox options.
4. Admin selects one or more document keys and enters a mandatory reason.
5. Frontend calls `AdminProfessionalsController.requestReupload`.
6. Controller calls `AdminUserManagementService.performAction` with:
   - `targetUserId`
   - `targetUserRole: professional`
   - `action: REQUEST_REUPLOAD`
   - `reason`
   - `requestedDocuments`

Current admin options are generic:

| Current key | Current label |
| --- | --- |
| `identity_proof` | Identity proof |
| `address_proof` | Address proof |
| `profile_photo` | Profile photo |
| `work_samples` | Work samples |
| `bank_document` | Bank document |
| `agreement` | Agreement |

### Current backend

Main file:

- `functions/index.js`

Backend function:

- `adminManageUserAccount`

Current validation:

- Only admin users can call the action.
- `REQUEST_REUPLOAD` is valid only for professionals.
- A reason is required.
- At least one valid document key is required.
- Allowed document keys currently match the generic list above.

When accepted, backend writes status data to both user/profile records:

- `approvalStatus: REUPLOAD_REQUIRED`
- `professionalStatus: reupload_requested`
- `status: reupload_requested` on professional profile
- `reuploadStatus: REQUESTED`
- `reuploadReason`
- `reuploadRequestedDocuments`
- `reuploadRequestedAt`
- `reuploadRequestedBy`
- `professionalAvailableForBooking: false`
- `professionalAvailabilityStatus: offline`

It also writes an admin action log and sends a notification using type `document_reupload_requested`.

### Current professional frontend

Main files:

- `lib/app/screens/professional/professionalRegistration/AdminApproval_Screen.dart`
- `lib/app/screens/professional/professionalRegistration/requested_document_reupload_sheet.dart`
- `lib/app/services/professional_document_reupload_service.dart`

Current flow:

1. Professional approval screen reads `reuploadRequestedDocuments`, `reuploadReason`, and `reuploadStatus`.
2. If status is `reupload_requested`, the screen shows a re-upload action.
3. The bottom sheet lists only the requested document keys.
4. Professional must select a file for every requested key.
5. Selected files are uploaded to Firebase Storage under:
   - `professional_documents/{uid}/reuploads/{timestamp}/{documentKey}-{safeFileName}`
6. Frontend calls Cloud Function `submitRequestedDocumentReupload` with uploaded download URLs.

Current file validation:

- Accepted extensions: `pdf`, `jpg`, `jpeg`, `png`
- Maximum file size: 5 MB

Current backend submit validation:

- Professional must be logged in.
- Submitted keys must exactly match the requested keys.
- Submitted URLs must be HTTPS URLs.
- Account/profile must still be in re-upload requested state.

On successful submit, backend writes:

- `reuploadStatus: SUBMITTED`
- `reuploadedDocuments`
- `reuploadSubmittedAt`
- status back to review state so admin can verify again.

### Production-ready target for this feature

The current implementation is functional, but its document keys do not match the professional onboarding stepper fields requested for production.

Admin should only be able to request these fields:

| Target key | Admin label | Professional input type | Source onboarding field |
| --- | --- | --- | --- |
| `aadhaar_card` | Aadhaar Card | PDF upload | Aadhaar verification |
| `pan_card` | PAN Card | PDF upload | PAN verification |
| `bank_passbook` | Bank Passbook | PDF upload | Bank information |
| `google_work_drive_url` | Google Work Drive URL | URL input | Work/profile portfolio |
| `instagram_profile_url` | Instagram Profile URL | URL input | Work/profile portfolio |

Recommended changes:

1. Replace generic admin checkbox list with the five onboarding fields above.
2. Match the new UI design from the provided reference:
   - title: `Request Re-upload`
   - helper text
   - selectable items
   - optional reason text area
   - 300 character counter
   - Cancel and Confirm buttons
3. Decide whether reason is optional or mandatory. The design says optional, but the backend currently rejects empty reasons.
4. Professional re-upload UI should show file picker only for PDF fields and text input only for URL fields.
5. Backend allowed keys must be changed to the same five keys.
6. Backend submit validation must validate:
   - PDF fields are secure Firebase Storage URLs.
   - URL fields are valid HTTPS URLs.
   - Submitted keys exactly match requested keys.
7. Admin detail screen should render re-submitted documents/URLs beside the original onboarding values for clear review.

## 2. Portfolio Management

### Current purpose

Admin manages the content, images, videos, and text that customers see in the customer Portfolio tab.

### Current admin frontend

Main files:

- `lib/app/screens/admin/content_portfolio/admin_content_portfolio_screen.dart`
- `lib/app/screens/admin/content_portfolio/getx/admin_content_portfolio_controller.dart`
- `lib/app/services/service_catalog_paths.dart`

Admin drawer route:

- Label: `Content & Portfolio`
- Route: `AppRoutes.adminContentPortfolioRoute`

Current admin-managed content:

- About ClickNow text
- Mission text
- Why Choose Us points
- Service/category media
- Images per service
- Videos per service

Current built-in portfolio service keys:

| Service key | Display title |
| --- | --- |
| `photography` | Photo & Videography |
| `musician` | Music & Live Performance |
| `dj` | Professional DJ Services |
| `wedding_planner` | Live Wedding Painter |
| `anchor` | Professional Anchor |
| `magician` | Professional Magician |

### Current Firestore and Storage structure

Firestore paths are centralized in `ServiceCatalogPaths`:

| Path constant | Firestore value | Purpose |
| --- | --- | --- |
| `portfolioContentCollection` | `portfolio_content` | Stores global text/settings |
| `portfolioSettingsDoc` | `portfolio_settings` | Single document for portfolio page content |
| `portfolioServicesCollection` | `portfolio_services` | Stores visible portfolio service categories |
| `portfolioMediaCollection` | `portfolio_media` | Stores image/video records |

Media files are uploaded to Firebase Storage under:

- `portfolio/{serviceKey}/images/{timestamp}_{fileName}`
- `portfolio/{serviceKey}/videos/{timestamp}_{fileName}`

Current media validation:

| Media type | Extensions | Max size |
| --- | --- | --- |
| Image | `png`, `jpg`, `jpeg`, `webp` | 10 MB |
| Video | `mp4`, `mov`, `avi`, `mkv` | 100 MB |

For images, admin can upload multiple files. For videos, the controller uploads one video at a time.

Each media Firestore record stores:

- `id`
- `serviceId`
- `mediaType`
- `mediaUrl`
- `thumbnailUrl`
- `displayOrder`
- `isVisible`
- `createdAt`

### Current customer frontend

Main files:

- `lib/app/screens/customer/portfolio/customer_portfolio_screen.dart`
- `lib/app/screens/customer/portfolio/getx/customer_portfolio_controller.dart`

Customer Portfolio tab listens to Firestore:

1. `portfolio_content/portfolio_settings`
2. visible docs from `portfolio_services`
3. visible docs from `portfolio_media`
4. top visible review docs for customer experience/testimonial content

The customer screen updates through Firestore streams, so admin changes become visible without requiring a new app build.

### Current gaps and production-ready target

Current implementation is usable, but needs production hardening:

1. Add admin controls for edit/delete/reorder media items, not only upload and clear featured media.
2. Store and show thumbnails for videos instead of using the video URL as thumbnail.
3. Add visibility toggles per media item.
4. Add stronger admin-only Firestore/Storage rules for portfolio writes.
5. Add empty, loading, and failed-upload states in admin UI.
6. Keep customer UI resilient when a media URL is deleted or invalid.
7. Normalize service keys with the main service catalog if portfolio services should match actual bookable services.

## 3. Manual and Auto Assign Bookings

### Current purpose

After a customer payment is successful or partially paid, admin can assign the approved booking to a professional. Admin can either let the system pick the best available professional automatically or manually choose one from a suggested list.

### Current admin frontend

Main files:

- `lib/app/screens/admin/bookings/admin_bookings_screen.dart`
- `lib/app/screens/admin/bookings/getx/admin_bookings_controller.dart`
- `lib/app/screens/admin/bookings/models/admin_booking_request.dart`
- `lib/app/services/booking/booking_service.dart`

Current admin actions on a booking card:

- Approve
- Cancel & Refund
- Auto Assign
- Manual Assign
- Reassign
- Cancel Assignment
- Approve/Reject Reschedule

Auto/manual assign buttons are shown when:

- booking status is `approved`
- booking does not have a pending reschedule request
- booking is paid or partially paid
- booking is not already in a reassignment-only state

### Manual assignment flow

1. Admin clicks `Manual Assign`.
2. Frontend loads professional suggestions using `BookingService.suggestProfessionals`.
3. If suggestions are incomplete, admin controller also reads `professional_profiles` as a fallback manual pool.
4. Candidates are scored using service, city/state/pincode, online status, and experience.
5. Admin chooses a professional from the sheet.
6. Frontend calls `BookingService.manualAssignProfessional`.
7. Service calls backend function `assignBookingByAdmin` with:
   - `bookingId`
   - `professionalId`
   - `autoAssigned: false`

### Auto assignment flow

1. Admin clicks `Auto Assign`.
2. Frontend asks `BookingService.autoAssignProfessional`.
3. Service calls `suggestProfessionals` with limit 1.
4. Top scored professional is selected.
5. Service calls backend function `assignBookingByAdmin` with:
   - `bookingId`
   - `professionalId`
   - `autoAssigned: true`
   - `score`
   - `scoreBreakdown`

Current scoring signals include:

- service match
- city/state/pincode match
- working locations
- experience years
- acceptance rate
- cancellation rate
- rating
- online/availability status
- urgent booking availability

### Current backend assignment behavior

Main file:

- `functions/index.js`

Backend function:

- `assignBookingByAdmin`

Validation:

- caller must be an active admin
- `bookingId` and `professionalId` are required
- booking must exist
- professional profile must exist
- booking must have successful payment status
- booking status must be `APPROVED` or `ASSIGNED`
- professional must not be blocked, suspended, or rejected

Backend writes assignment data through shared booking-copy writer:

- `status: ASSIGNED`
- `lifecycleStatus: assigned`
- `bookingStatus: assigned`
- `bookingStage: professional_assigned`
- `assignedProfessionalId`
- `assignedProfessionalIds`
- `professionalId`
- `assignedToProfessionalId`
- `professional` summary object
- `assignment.professionalId`
- `assignment.status: pending_professional_response`
- `assignment.assignedBy`
- `assignment.autoAssigned`
- `assignment.assignedAt`
- `assignment.score`
- `assignment.scoreBreakdown`
- `professionalDecisionStatus: pending`
- assignment timeline fields

The function also writes an admin action log and sends notifications:

- Customer notification: professional assigned.
- Professional notification: new booking assigned and waiting for response.

### Professional response flow

Backend function:

- `professionalRespondToBooking`

If professional accepts:

- booking becomes `CONFIRMED`
- `professionalDecisionStatus: accepted`
- `acceptedByProfessionalId`
- `acceptedAt`

If professional rejects:

- booking returns to `APPROVED`
- assigned professional fields are cleared
- rejected professional id is stored in `rejectedProfessionalIds`
- `lastProfessionalRejection` stores reason and timestamp
- admin can assign another professional

### Reassignment flow

Admin can cancel a pending assignment for reassignment when the booking is assigned but the professional has not accepted. The backend clears the assigned professional fields and returns the booking to an assignable state.

### Current gaps and production-ready target

1. Manual assignment should clearly show why each professional is suggested.
2. Auto assignment should show the selected professional and score before or after assignment for admin confidence.
3. Professional availability rules should become stricter if time-slot availability is modeled.
4. Rejected professionals should be excluded consistently from future auto/manual suggestions for the same booking.
5. Assignment state should remain consistent across all booking copies and all panels.
6. Notifications should deep-link customer/professional/admin to the exact booking details screen.
7. Admin audit logs should show manual vs auto assignment, reassignment, cancellation reason, and professional response.

## Cross-feature production checklist

Before implementing the UI improvements, these contracts should be finalized:

1. Stable field keys for re-upload requests.
2. Whether re-upload reason is optional or mandatory.
3. PDF-only vs mixed upload support for requested professional documents.
4. Firestore/Storage security rules for admin-only portfolio writes.
5. Portfolio media delete/reorder visibility behavior.
6. Assignment candidate filtering rules.
7. Notification and audit log requirements for every admin-triggered action.

