# ClickNow Booking Module Requirements and Workflow Document

Version: 1.0  
Document Type: Product Requirements + Workflow + Operational Design  
Audience: Product Managers, Founders, Business Analysts, System Architects, Engineering Teams, QA Teams, Operations Teams  
Purpose: Editable single source of truth for redesigning, scaling, and maintaining the ClickNow booking module

## 0. Document Scope and Assumptions

This document describes the end-to-end Booking Module for ClickNow at production scale.

It is designed to serve two purposes:

1. Reflect the current implemented workflow observed in the application codebase.
2. Define a scalable, editable future-ready workflow that can be modified later without ambiguity.

Current implementation signals observed in the codebase:

- Booking starts from customer service discovery and booking request creation.
- Initial booking status is `REQUESTED`.
- Admin approves booking before professional confirmation.
- Admin can auto-assign or manually assign a professional.
- Professional can accept or reject assigned booking.
- Professional can start and complete service.
- Customer can cancel in certain early/mid stages.
- Customer can request reschedule.
- Admin can reject or cancel bookings.
- Support ticket flow exists at booking level.
- Booking records are mirrored to customer and professional views.

Important note:

- Refund logic, payout ledgering, commission ledgering, review publication, and notification orchestration are only partially represented in code today.
- This document defines those areas in a production-grade way so they can be implemented or revised later.

## 1. Module Overview

### 1.1 Purpose of the Booking Module

The Booking Module is the operational backbone of ClickNow. It manages the complete lifecycle of a service request from customer intent through professional fulfillment, payment settlement, issue handling, and post-service feedback.

### 1.2 Key Objectives

- Convert service discovery into confirmed, fulfilled bookings.
- Ensure trust and control through admin approval and professional matching.
- Maintain a traceable status lifecycle for every booking.
- Provide visibility to customer, professional, and admin at every stage.
- Support exceptions such as rejection, cancellation, reschedule, and support escalation.
- Maintain auditability for operational, financial, and compliance reasons.
- Scale to multiple service categories and high booking volumes.

### 1.3 User Roles Involved

- Customer
- Professional
- Admin
- System / Automation Engine
- Finance / Settlement layer
- Notification layer
- Support / Operations team

## 2. User Roles

### 2.1 Customer Panel

Primary responsibilities:

- Discover services
- Create booking request
- Pay booking amount or advance amount
- Track booking status
- View assigned professional details
- Request reschedule
- Cancel booking when allowed
- Raise support ticket
- Download invoice after completion
- Submit review and rating

### 2.2 Professional Panel

Primary responsibilities:

- View assigned or available bookings
- Accept assigned booking
- Reject assigned booking with reason
- Start service on event day
- Mark service completed
- Monitor payment and payout visibility
- Handle support communication if required

### 2.3 Admin Panel

Primary responsibilities:

- Review incoming booking requests
- Approve or reject booking requests
- Match and assign professional
- Reassign if professional rejects or becomes unavailable
- Cancel booking when policy or operational need requires it
- Oversee support, dispute, reschedule, and exception handling
- Monitor SLA, fulfillment, and payment state
- Trigger manual interventions

## 3. Complete Booking Lifecycle

### 3.1 Service Discovery

- Customer browses service categories.
- Customer selects a service category such as photography, DJ, live wedding painter, anchor, magician, or music performance.
- Customer opens service request form.
- Customer chooses event type or speciality.
- Customer selects plan or pricing tier.
- Customer enters event details, venue details, address, timing, and requirements.

### 3.2 Booking Creation

- Customer clicks `Book Now` or `Add to Cart`.
- `Add to Cart` stores editable cart item.
- `Book Now` moves user to checkout flow.
- Checkout creates one or more booking requests.
- Booking record is created in:
  - master bookings collection
  - customer booking subcollection
  - admin request collection
- Initial status becomes `REQUESTED`.

### 3.3 Admin Review

- Admin sees new booking in pending queue.
- Admin validates customer details, service details, schedule, location, and fulfillment feasibility.
- Admin either:
  - approves booking
  - rejects booking with reason

### 3.4 Professional Assignment

- After admin approval, booking enters professional assignment stage.
- System may suggest professionals using service, location, experience, rating, acceptance rate, and cancellation rate.
- Admin may:
  - auto-assign recommended professional
  - manually assign professional
- Booking status becomes `ASSIGNED`.

### 3.5 Professional Response

- Assigned professional reviews booking.
- Professional may:
  - accept booking
  - reject booking with reason
- If accepted, booking becomes `CONFIRMED`.
- If rejected, booking goes back to admin-approved pool for reassignment.

### 3.6 Pre-Event Execution

- Customer sees assigned professional and booking timeline.
- Professional sees upcoming job details.
- Customer may still cancel or request reschedule within allowed policy window.
- Admin may intervene if support issue or conflict arises.

### 3.7 Service Execution

- On event date, professional starts service.
- Booking becomes `IN_PROGRESS`.
- Support flow can be raised by customer or operations during active job.

### 3.8 Service Completion

- Professional marks booking completed.
- Booking becomes `COMPLETED`.
- Completion timestamps are stored.
- Invoice and financial settlement become eligible.

### 3.9 Payment Settlement

- Customer payment is captured at booking or checkout stage depending on category policy.
- Platform commission is deducted.
- Professional payout becomes payable after settlement hold rules are satisfied.
- Refunds are processed if cancellation or dispute requires it.

### 3.10 Review and Rating

- Customer becomes eligible to rate service after `COMPLETED`.
- Review updates professional credibility and recommendation score.

### 3.11 Cancellation and Refund Handling

- Customer cancellation is allowed in early approved/assigned/confirmed stages based on policy.
- Admin cancellation is allowed at any stage subject to rule restrictions.
- Professional-initiated cancellation should be treated as rejection before confirmation or as escalation after confirmation.
- Refund and penalty policy depends on who cancelled, when, and whether professional was already committed or service was underway.

## 4. Booking Status System

### 4.1 REQUESTED

- Description: Booking request has been created by customer and awaits admin review.
- Triggered by: Customer checkout submission or resubmission after reschedule.
- Previous statuses: None, `RESCHEDULED` logical reset.
- Next statuses: `APPROVED`, `REJECTED`, `CANCELLED`.
- System actions:
  - Create booking records
  - Store customer, event, plan, location, payment, and timeline data
  - Add admin queue item
- User notifications:
  - Customer: booking request received
  - Admin: new booking pending review

### 4.2 APPROVED

- Description: Admin validated the booking and approved it for assignment.
- Triggered by: Admin
- Previous statuses: `REQUESTED`, `ASSIGNED` rollback after professional rejection
- Next statuses: `ASSIGNED`, `CANCELLED`, `RESCHEDULED`
- System actions:
  - Mark admin approval
  - Open professional matching or assignment workflow
- User notifications:
  - Customer: booking approved
  - Admin: approval logged
  - Operations: optional assignment SLA alert

### 4.3 ASSIGNED

- Description: A professional has been assigned and is expected to respond.
- Triggered by: Admin or auto-assignment engine
- Previous statuses: `APPROVED`
- Next statuses: `CONFIRMED`, `APPROVED`, `CANCELLED`, `RESCHEDULED`
- System actions:
  - Copy booking into professional request list
  - Mark assignment metadata
  - Store assignment source and match score
- User notifications:
  - Customer: professional assigned
  - Professional: new job assigned
  - Admin: assignment recorded

### 4.4 CONFIRMED

- Description: Assigned professional accepted the job.
- Triggered by: Professional
- Previous statuses: `ASSIGNED`
- Next statuses: `IN_PROGRESS`, `CANCELLED`, `RESCHEDULED`
- System actions:
  - Record professional acceptance
  - Unlock pre-event detail visibility
- User notifications:
  - Customer: booking confirmed
  - Admin: professional accepted
  - Professional: confirmation acknowledgement

### 4.5 IN_PROGRESS

- Description: Service has started on event day.
- Triggered by: Professional
- Previous statuses: `CONFIRMED`
- Next statuses: `COMPLETED`
- System actions:
  - Record service start time
  - Raise operational sensitivity for support
- User notifications:
  - Customer: service started
  - Admin: active job monitoring

### 4.6 COMPLETED

- Description: Service delivery finished.
- Triggered by: Professional
- Previous statuses: `IN_PROGRESS`
- Next statuses: Settlement, review, support closure workflows
- System actions:
  - Record completion time
  - Generate completion-ready payment and review states
- User notifications:
  - Customer: booking completed
  - Professional: completion acknowledged
  - Admin: fulfillment closed

### 4.7 REJECTED

- Description: Booking was rejected by admin before assignment or fulfillment.
- Triggered by: Admin
- Previous statuses: `REQUESTED`
- Next statuses: Terminal unless recreated manually
- System actions:
  - Record rejection reason
  - Mark booking as cancelled outcome
  - Trigger refund or payment reversal if required
- User notifications:
  - Customer: booking rejected with reason
  - Admin: rejection audit logged

### 4.8 CANCELLED

- Description: Booking was cancelled by customer or admin.
- Triggered by: Customer or Admin
- Previous statuses: `REQUESTED`, `APPROVED`, `ASSIGNED`, `CONFIRMED`
- Next statuses: Terminal unless recreated manually
- System actions:
  - Record actor, role, reason, time
  - Clear fulfillment pipeline if needed
  - Trigger refund / penalty decisioning
- User notifications:
  - Customer: booking cancelled
  - Professional: cancellation alert if assigned
  - Admin: cancellation audit

### 4.9 RESCHEDULED

- Description: Logical business event indicating the booking has been rescheduled and reset to request flow.
- Triggered by: Customer today, optionally professional or admin in future design
- Previous statuses: `REQUESTED`, `APPROVED`, `ASSIGNED`, `CONFIRMED`
- Next statuses: Internally reset to `REQUESTED`
- System actions:
  - Replace event date/time
  - Clear assignment and professional decision state
  - Reset timeline approval/assignment/execution checkpoints
- User notifications:
  - Customer: reschedule request accepted/submitted
  - Admin: booking requires re-review or reassignment
  - Professional: prior assignment invalidated

## 5. Booking Progress Timeline

### 5.1 Stage 1: Booking Request Submitted

- Description: Customer request captured successfully.
- Trigger event: Customer completes checkout.
- Visible to: Customer, Admin
- Available CTAs:
  - Customer: `View Booking`, `Raise Support`, `Cancel Booking` if policy allows
  - Admin: `Approve`, `Reject`

### 5.2 Stage 2: Booking Approved by Admin

- Description: Booking is operationally accepted.
- Trigger event: Admin approval
- Visible to: Customer, Admin
- Available CTAs:
  - Admin: `Assign Professional`
  - Customer: `Cancel`, `Request Reschedule`

### 5.3 Stage 3: Professional Assigned

- Description: Professional has been selected but not yet accepted.
- Trigger event: Admin assignment or auto-assignment
- Visible to: Customer, Admin, Assigned Professional
- Available CTAs:
  - Professional: `Accept`, `Reject`
  - Customer: `Cancel`, `Request Reschedule`
  - Admin: `Reassign`, `Cancel`

### 5.4 Stage 4: Professional Confirmed

- Description: Professional accepted and event is locked operationally.
- Trigger event: Professional acceptance
- Visible to: Customer, Admin, Professional
- Available CTAs:
  - Professional: `Start Booking`
  - Customer: `Request Reschedule`, `Cancel` if still within cutoff
  - Admin: `Cancel`, `Support Action`

### 5.5 Stage 5: Event Started

- Description: Service execution has started.
- Trigger event: Professional marks start
- Visible to: Customer, Admin, Professional
- Available CTAs:
  - Professional: `Mark Completed`
  - Customer: `Raise Support`
  - Admin: `Escalate`, `Support Action`

### 5.6 Stage 6: Completed

- Description: Job completed successfully.
- Trigger event: Professional marks completion
- Visible to: Customer, Admin, Professional
- Available CTAs:
  - Customer: `Download Invoice`, `Rate & Review`, `Raise Dispute`
  - Admin: `View Settlement`
  - Professional: `View Earnings`

### 5.7 Stage 7: Cancelled / Rejected / Rescheduled

- Description: Exception or terminal state.
- Trigger event: Cancel, reject, or reschedule action
- Visible to: Relevant stakeholders
- Available CTAs:
  - Customer: `Book Again`, `Contact Support`
  - Admin: `View Audit`
  - Professional: `View Details`

## 6. Customer Panel

### 6.1 Service Discovery Screen

- Purpose: Let customer discover and enter booking journey.
- Visible information:
  - service categories
  - media banners
  - pricing highlights
  - category descriptions
- Actions:
  - open category detail page
  - shortlist service
- CTAs:
  - `Explore`
  - `Book this service`
- Status-dependent behavior: Not applicable
- Edge cases:
  - service unavailable in region
  - no event types configured

### 6.2 Customer Request Booking Form

- Purpose: Capture all booking input fields before cart or checkout.
- Visible information:
  - event type
  - event date and time
  - duration
  - guest count
  - venue name
  - house/hall/plot details
  - landmark/direction details
  - venue address and map pin
  - plan selection
  - special requirements
  - on-site contact name and phone
  - price preview
- Actions:
  - edit fields
  - search address
  - use current location
  - pin exact venue
  - select plan
- CTAs:
  - `Book Now`
  - `Add to Cart`
- Status-dependent behavior:
  - if editing existing cart/checkout item, form loads prefilled values
- Edge cases:
  - address selected but map pin missing
  - invalid date or past date
  - invalid on-site phone
  - duration missing or zero

### 6.3 Cart / Your Bookings Screen

- Purpose: Show customer’s saved booking drafts before checkout.
- Visible information:
  - booking summary cards
  - service name
  - date
  - event type
  - plan
  - duration
  - rate
  - location
  - total amount
- Actions:
  - edit cart item
  - delete cart item
  - proceed to checkout
- CTAs:
  - `Edit`
  - `Delete`
  - `Proceed to Checkout`
- Status-dependent behavior:
  - draft/cart items are editable before checkout submission
- Edge cases:
  - stale pricing changed after item added
  - deleted service category

### 6.4 Checkout Screen

- Purpose: Confirm selected booking items before final submission.
- Visible information:
  - booking summary
  - total payable
- Actions:
  - edit item
  - delete item
  - submit checkout
- CTAs:
  - `Edit`
  - `Delete`
  - `Proceed to Checkout`
- Status-dependent behavior:
  - editing returns to same booking form with prefilled values
- Edge cases:
  - partial failure when multiple bookings submit

### 6.5 My Bookings Tab Screen

- Purpose: Show submitted bookings by status.
- Tabs:
  - All
  - Pending
  - Assigned
  - Confirmed
  - In Progress
  - Completed
  - Cancelled
  - Support
- Visible information:
  - booking code
  - service
  - event
  - location
  - amount
  - status
- Actions:
  - open booking details
- CTAs:
  - `View Details`
- Status-dependent behavior:
  - tabs filter by normalized status
- Edge cases:
  - support-open booking may also be completed or cancelled

### 6.6 Booking Details Screen

- Purpose: Provide deep visibility into one booking.
- Visible information:
  - booking ID
  - status chip
  - date and time
  - event location
  - special instructions
  - assigned professional
  - professional phone
  - service and event type
  - timeline
  - price preview
  - payment status
- Actions:
  - reschedule
  - raise support
  - cancel booking
  - download invoice after completion
- CTAs:
  - `Request Reschedule`
  - `Raise Support`
  - `Cancel Booking`
  - `Download Invoice`
- Status-dependent behavior:
  - reschedule visible in assign/confirmed window
  - cancel visible in early stages
  - invoice only after completion
- Edge cases:
  - professional unassigned after rejection
  - cancellation reason visibility
  - reschedule history visibility

### 6.7 Customer Notifications Screen

- Purpose: Surface booking updates.
- Visible information:
  - event-based notifications
  - unread/read states
- Actions:
  - open related booking
  - mark as read
- CTAs:
  - `View Booking`
- Edge cases:
  - duplicate notifications
  - delayed notifications after app offline period

## 7. Professional Panel

### 7.1 Professional Bookings Dashboard

- Purpose: Central booking inbox for professional.
- Tabs:
  - All
  - New Jobs
  - Upcoming
  - Ongoing
  - Completed
  - Cancelled
  - Support
- Visible information:
  - service name
  - customer name and phone
  - date/time
  - event type
  - location
  - payout-facing amount
  - payment label
  - status tag
- Actions:
  - open booking details
- CTAs:
  - `View Details`
- Status-dependent behavior:
  - New Jobs = assigned
  - Upcoming = confirmed
  - Ongoing = in progress
  - Completed = completed

### 7.2 Professional Booking Details Screen

- Purpose: Let professional review and act on assigned booking.
- Visible information:
  - customer details
  - location
  - special instructions
  - pricing breakdown
  - payment label
  - current status
- Actions:
  - accept
  - reject with reason
  - start booking
  - end booking
- CTAs:
  - `Accept`
  - `Reject`
  - `Start Booking`
  - `End Booking`
- Status-dependent behavior:
  - accept/reject only in `ASSIGNED`
  - start only in `CONFIRMED`
  - end only in `IN_PROGRESS`
- Edge cases:
  - booking reassigned before professional acts
  - professional offline when assignment occurs

### 7.3 Professional Earnings / Payout Views

- Purpose: Show outcome of completed jobs and payout visibility.
- Visible information:
  - completed jobs
  - gross amount
  - commission deduction
  - payout status
  - payout date
- Actions:
  - view payment details
- CTAs:
  - `View Payout Details`
- Edge cases:
  - dispute hold
  - payout delayed due to support case

### 7.4 Professional Notifications

- Purpose: Inform professional about assignments, reschedules, cancellations, payout, and support.
- Visible information:
  - new job assignment
  - acceptance required
  - job updates
  - payout updates
- Actions:
  - open booking
- CTAs:
  - `Accept Now`
  - `View Booking`

## 8. Admin Panel

### 8.1 Booking Overview Screen

- Purpose: Central operations console for booking fulfillment.
- Visible information:
  - total requests
  - pending count
  - confirmed count
  - searchable booking list
  - status tabs
- Tabs:
  - All
  - Pending Requests
  - Approved
  - Assigned
  - Active Jobs
  - Completed
  - Cancelled/Rejected
  - Support
- Actions:
  - search
  - filter
  - open booking
- CTAs:
  - `View`
  - `Approve`
  - `Reject`
  - `Assign`
  - `Cancel`

### 8.2 Admin Booking Review Screen

- Purpose: Approve or reject fresh requests.
- Visible information:
  - customer details
  - service details
  - schedule
  - venue
  - payment snapshot
- Approval workflow:
  - validate request
  - approve if fulfillable
  - reject if invalid, unsupported, risky, or unavailable
- Escalation workflow:
  - send to support if customer clarification needed
- CTAs:
  - `Approve Booking`
  - `Reject Booking`

### 8.3 Professional Matching and Assignment Screen

- Purpose: Match approved booking with best-fit professional.
- Visible information:
  - suggested professionals
  - score
  - experience
  - city/state/pincode
  - online status
  - language set
- Actions:
  - auto-assign
  - manual assign
  - reassign
- Approval workflows:
  - optional admin supervisor check for VIP jobs
- Escalation workflows:
  - no available professionals
  - repeated professional rejection
- CTAs:
  - `Assign`
  - `Reassign`
  - `View Profile`

### 8.4 Support and Escalation Queue

- Purpose: Resolve issues raised before, during, or after service.
- Visible information:
  - open support tickets
  - booking context
  - raised by
  - message
  - current status
- Actions:
  - respond
  - close
  - escalate
  - cancel booking if necessary
- CTAs:
  - `Resolve`
  - `Escalate`
  - `Cancel Booking`

### 8.5 Finance and Settlement Oversight

- Purpose: Control refunds, commissions, payout releases, and dispute holds.
- Visible information:
  - payment received
  - refund eligibility
  - commission amount
  - payout hold status
- Actions:
  - approve refund
  - hold payout
  - release payout
- CTAs:
  - `Issue Refund`
  - `Hold Payout`
  - `Release Payout`

## 9. CTA Button Matrix

| Button Name | Visible To | Appears In Which Status | Action Performed | Next Status Generated |
| --- | --- | --- | --- | --- |
| Book Now | Customer | Pre-booking form | Creates instant checkout item and opens checkout | No booking status yet |
| Add to Cart | Customer | Pre-booking form | Saves editable cart item | No booking status yet |
| Proceed to Checkout | Customer | Cart | Moves cart items into checkout flow | No booking status yet |
| Proceed to Checkout | Customer | Checkout | Submits final booking request | REQUESTED |
| Edit | Customer | Cart, Checkout | Opens booking form with prefilled data | No change until save |
| Delete | Customer | Cart, Checkout | Removes draft item | Item deleted |
| Approve Booking | Admin | REQUESTED | Approves request | APPROVED |
| Reject Booking | Admin | REQUESTED | Rejects request with reason | REJECTED |
| Assign Professional | Admin | APPROVED | Assigns professional | ASSIGNED |
| Reassign | Admin | ASSIGNED, APPROVED | Replaces professional assignment | ASSIGNED |
| Accept | Professional | ASSIGNED | Accepts booking | CONFIRMED |
| Reject | Professional | ASSIGNED | Rejects booking with reason | APPROVED |
| Start Booking | Professional | CONFIRMED | Marks event started | IN_PROGRESS |
| End Booking | Professional | IN_PROGRESS | Marks event complete | COMPLETED |
| Cancel Booking | Customer | REQUESTED, APPROVED, ASSIGNED, CONFIRMED | Cancels request | CANCELLED |
| Cancel Booking | Admin | Any non-terminal stage | Admin cancellation | CANCELLED |
| Request Reschedule | Customer | APPROVED, ASSIGNED, CONFIRMED | Resubmits with new date/time | REQUESTED |
| Raise Support | Customer | Active service stages | Opens support ticket | support_open stage, status unchanged |
| Download Invoice | Customer | COMPLETED | Downloads invoice | No status change |
| Rate & Review | Customer | COMPLETED | Submits rating/review | No status change |
| Release Payout | Admin/Finance | COMPLETED + settlement eligible | Releases professional payout | No booking status change |

## 10. Notification System

### 10.1 Booking Request Submitted

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Admin
- Trigger condition: Checkout successfully creates booking request

### 10.2 Booking Approved

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer
- Trigger condition: Admin approves booking

### 10.3 Booking Rejected

- Push: Yes
- In-app: Yes
- SMS: Recommended
- Recipient: Customer
- Trigger condition: Admin rejects booking

### 10.4 Professional Assigned

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Professional
- Trigger condition: Assignment completed

### 10.5 Professional Accepted

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Admin
- Trigger condition: Professional accepts booking

### 10.6 Professional Rejected

- Push: Yes
- In-app: Yes
- SMS: No
- Recipient: Admin
- Trigger condition: Professional rejects booking

### 10.7 Booking Started

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Admin
- Trigger condition: Professional starts service

### 10.8 Booking Completed

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Professional, Admin
- Trigger condition: Professional completes booking

### 10.9 Booking Cancelled

- Push: Yes
- In-app: Yes
- SMS: Recommended
- Recipient: Customer, Professional if assigned, Admin
- Trigger condition: Cancellation recorded

### 10.10 Booking Rescheduled

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer, Admin, Professional if previously assigned
- Trigger condition: Reschedule request accepted and state reset

### 10.11 Support Ticket Opened

- Push: Yes
- In-app: Yes
- SMS: No
- Recipient: Admin, relevant customer, relevant professional if needed
- Trigger condition: Support ticket created

### 10.12 Refund Processed

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Customer
- Trigger condition: Refund completed

### 10.13 Payout Released

- Push: Yes
- In-app: Yes
- SMS: Optional
- Recipient: Professional
- Trigger condition: Settlement payout released

## 11. Cancellation Flow

### 11.1 Customer Cancellation

- Allowed statuses:
  - REQUESTED
  - APPROVED
  - ASSIGNED
  - CONFIRMED
- Required inputs:
  - optional reason today
  - recommended mandatory reason in production
- System actions:
  - set booking to `CANCELLED`
  - store actor role `customer`
  - store timestamp and reason
  - trigger refund decisioning

### 11.2 Professional Cancellation

- Current practical behavior:
  - before confirmation, professional rejection sends booking back to `APPROVED`
- Recommended future behavior:
  - after confirmation, professional withdrawal should create escalation state requiring admin action

### 11.3 Admin Cancellation

- Allowed at all non-terminal stages.
- Reason should be mandatory.
- Common cases:
  - compliance issue
  - fraud suspicion
  - no available professional
  - severe support escalation

### 11.4 Refund Scenarios

- Full refund:
  - admin rejection
  - admin cancellation before service start
  - customer cancellation within free-cancel window
  - no professional available
- Partial refund:
  - customer cancellation after professional confirmed but before event cutoff
- No refund:
  - customer cancellation after service start
  - fraudulent usage

### 11.5 Penalty Scenarios

- Customer penalty:
  - late cancellation after professional lock-in
- Professional penalty:
  - repeated rejection after assignment
  - withdrawal after confirmation
- Admin override:
  - waive penalty for emergency or force majeure

### 11.6 Status Changes

- Customer cancel: non-terminal active state -> `CANCELLED`
- Admin cancel: non-terminal active state -> `CANCELLED`
- Admin reject: `REQUESTED` -> `REJECTED`

## 12. Reschedule Flow

### 12.1 Customer Initiated

- Current implementation:
  - customer can request reschedule
  - booking resets to `REQUESTED`
  - prior assignment is cleared
- Recommended policy:
  - allow until configurable cutoff before event start

### 12.2 Professional Initiated

- Recommended future enhancement:
  - professional proposes alternate date/time
  - customer approval required
  - admin visibility required

### 12.3 Approval Process

- Current implementation effectively re-enters admin flow after reschedule.
- Recommended process:
  - if only time changes within same professional availability and admin risk is low, fast-track re-approval
  - otherwise full approval + reassignment evaluation

### 12.4 Status Changes

- APPROVED / ASSIGNED / CONFIRMED -> reschedule requested -> reset to `REQUESTED`
- Timeline is reset for request, approval, assignment, confirmation, and completion checkpoints

## 13. Payment Flow

### 13.1 Advance Payment

- Recommended production model:
  - configurable by service category
  - 100 percent prepaid for consumer simplicity in early versions
  - advance-only model can be introduced later for premium or large-budget services

### 13.2 Full Payment

- Current implementation indicates `paymentStatus = paid` at request creation.
- Meaning:
  - customer payment is treated as captured upfront at booking creation

### 13.3 Refunds

- Triggered by cancellation, rejection, support dispute, or failed fulfillment.
- Must support:
  - full
  - partial
  - zero refund
- Recommended entities:
  - refund request
  - refund decision
  - refund transaction

### 13.4 Professional Payout

- Recommended release logic:
  - eligible only after booking completion
  - subject to dispute hold window
  - subject to refund lock checks

### 13.5 Platform Commission

- Professional onboarding already includes commission acceptance.
- Recommended payment rules:
  - commission % configurable by service category
  - commission ledger separated from payout ledger
  - gross, commission, tax, and net payout tracked independently

## 14. State Transition Diagram (Text Format)

Draft Cart Item -> Checkout Ready  
Checkout Ready -> Requested  
Requested -> Approved  
Requested -> Rejected  
Requested -> Cancelled  
Approved -> Assigned  
Approved -> Cancelled  
Approved -> Requested (reschedule reset)  
Assigned -> Confirmed  
Assigned -> Approved (professional rejected)  
Assigned -> Cancelled  
Assigned -> Requested (reschedule reset)  
Confirmed -> In Progress  
Confirmed -> Cancelled  
Confirmed -> Requested (reschedule reset)  
In Progress -> Completed  
Completed -> Settlement In Progress  
Settlement In Progress -> Payment Settled  
Completed -> Review Pending  
Review Pending -> Reviewed  

Current implementation transition subset:

Requested -> Approved  
Requested -> Rejected  
Requested -> Cancelled  
Approved -> Assigned  
Assigned -> Confirmed  
Assigned -> Approved  
Confirmed -> In Progress  
In Progress -> Completed  
Approved -> Requested (reschedule)  
Assigned -> Requested (reschedule)  
Confirmed -> Requested (reschedule)  

## 15. Database-Level Entity Overview

### 15.1 Booking Entity

Important fields:

- bookingId
- bookingCode
- requestId
- customerId
- userId
- customer
- serviceCatalogId
- serviceTitle
- eventTypeId
- eventTypeName
- planKey
- planName
- basePrice
- gstPercent
- gstAmount
- totalAmount
- eventDate
- eventTime
- eventDurationHours
- guestCount
- venueName
- venueHouseDetails
- venueLandmarkDetails
- fullAddress
- city
- state
- pincode
- latitude
- longitude
- onsiteContactName
- onsiteContactPhone
- specialRequirements
- paymentStatus
- status
- lifecycleStatus
- bookingStatus
- bookingStage
- assignedProfessionalId
- assignedProfessionalIds
- rejectedProfessionalIds
- professional
- assignment
- professionalDecisionStatus
- supportOpen
- support
- cancellation
- cancellationReason
- createdAt
- updatedAt

### 15.2 Booking Status Entity

This can remain embedded or be normalized later.

Important fields:

- bookingId
- currentStatusCode
- lifecycleStatus
- stage
- previousStatusCode
- changedBy
- changedByRole
- changedAt
- reason
- sourceAction

### 15.3 Timeline Entity

Current implementation stores timeline inside booking document.  
Recommended scalable design can split into a booking timeline collection.

Important fields:

- bookingId
- requestedAt
- approvedAt
- assignedAt
- confirmedAt
- startedAt
- completedAt
- cancelledAt
- rejectedAt
- rescheduleRequestedAt
- supportOpenedAt
- lastUpdatedAt

### 15.4 Payment Entity

Important fields:

- paymentId
- bookingId
- customerId
- grossAmount
- gstAmount
- commissionAmount
- discountAmount
- refundAmount
- netPayoutAmount
- paymentMethod
- paymentGatewayTransactionId
- captureStatus
- refundStatus
- payoutStatus
- payoutBatchId
- settledAt

### 15.5 Notification Entity

Important fields:

- notificationId
- bookingId
- recipientId
- recipientRole
- channel
- eventKey
- title
- body
- payload
- sentAt
- deliveryStatus
- readAt

## 16. Business Rules

### 16.1 Validation Rules

- Event date cannot be in the past.
- Event duration must be greater than zero.
- Plan selection is mandatory.
- Address must be selected and pinned on map.
- Venue details must be complete for on-ground services.
- On-site phone must be valid if entered.
- Rejection reason must be mandatory for admin and professional rejection.
- Cancellation reason must be mandatory for admin cancellation.

### 16.2 Permissions

- Customer cannot approve or assign bookings.
- Professional can only act on bookings assigned to them.
- Admin can override assignment and cancellation.
- Completed booking cannot be rescheduled.
- Completed, cancelled, and rejected bookings are terminal for operational flow.

### 16.3 Restrictions

- Professional cannot start booking before confirmation.
- Professional cannot end booking before start.
- Customer cannot cancel after configured cutoff unless admin override.
- Reassigned professional should not include previously rejected professional unless admin forces it.

### 16.4 Time Limits

- Admin review SLA: configurable, recommended under 30 minutes for prime bookings.
- Professional response SLA: configurable, recommended 15 to 30 minutes.
- Support response SLA: configurable by severity.
- Review submission window: recommended 7 to 14 days after completion.

### 16.5 Auto-Expiry Logic

- Unreviewed `REQUESTED` bookings may auto-escalate after SLA breach.
- Unaccepted `ASSIGNED` bookings may auto-unassign and requeue after SLA expiry.
- Stale checkout drafts may auto-expire after configurable time.

### 16.6 Auto-Cancellation Logic

- Failed payment authorization -> auto-cancel booking request.
- Event date passed without start and without admin override -> auto-escalate, not auto-complete.
- Unserviceable booking after repeated assignment failures -> admin cancellation or assisted reschedule.

## 17. Edge Cases and Exception Handling

- Customer pays but booking write partially fails.
- Multi-item checkout succeeds for some bookings and fails for others.
- Admin approves booking but no professional is available.
- Professional assigned, but account becomes inactive before response.
- Professional accepts, then becomes unavailable due to emergency.
- Customer changes event address after professional is assigned.
- Duplicate payment callback received.
- Duplicate approval or duplicate assignment action triggered.
- Customer opens multiple edit sessions on same cart item.
- Professional starts booking from stale screen after reassignment.
- Support ticket opened during in-progress booking.
- Booking completed but customer disputes quality.
- Booking cancelled after professional already travelled.
- Reschedule requested very close to event time.
- Service category deleted or disabled while draft/cart item exists.
- Notification delivery fails but status changes successfully.
- Cross-panel data mismatch between master booking and mirrored subcollections.
- Manual admin action conflicts with automation action.

Expected handling principles:

- master booking record is source of truth
- mirrored documents must be patched atomically where possible
- user-facing state should degrade gracefully
- all status-changing actions must be idempotent
- every exception should write audit trail

## 18. Improvement Suggestions

### 18.1 Workflow Improvements

- Introduce explicit `DRAFT`, `CHECKOUT_PENDING`, `PAYMENT_PENDING`, `PAYOUT_PENDING`, and `REFUNDED` statuses.
- Separate `REJECTED` from `CANCELLED` more clearly in UX and reporting.
- Add professional post-confirmation cancellation workflow with penalty engine.
- Add customer approval for professional-initiated reschedule.

### 18.2 Architecture Improvements

- Move booking mutations to backend service or serverless functions for stronger consistency.
- Replace mirrored manual patching with event-driven projection model.
- Introduce booking domain events:
  - booking.created
  - booking.approved
  - booking.assigned
  - booking.confirmed
  - booking.started
  - booking.completed
  - booking.cancelled
  - booking.rescheduled
  - support.opened
- Add notification orchestration service instead of UI-triggered side effects.

### 18.3 Data Improvements

- Normalize payment, refund, payout, and dispute into dedicated entities.
- Store immutable status history records rather than only latest embedded fields.
- Add configurable policy tables for cancellation, refund, and payout.

### 18.4 Operational Improvements

- Add SLA dashboards for:
  - pending admin approvals
  - unaccepted professional assignments
  - in-progress jobs without closure
  - unresolved support cases
- Add fraud/risk scoring for suspicious customer behavior.
- Add professional reliability scoring using:
  - acceptance rate
  - cancellation rate
  - ratings
  - punctuality

### 18.5 Scalability Improvements

- Partition bookings by region and event date for query efficiency.
- Use async queues for notifications and payout operations.
- Add search index for booking lookup by code, customer, phone, city, and professional.
- Add observability for every state transition and financial mutation.

## 19. Recommended Final Source-of-Truth Principle

For future redesign work, ClickNow should treat the Booking Module as a controlled state machine with:

- one canonical booking aggregate
- one canonical transition policy
- one policy engine for cancellation/refund/reschedule
- one notification orchestration layer
- one finance settlement layer
- one mirrored-read-model layer for customer, professional, and admin panels

This document should be updated whenever:

- a new status is introduced
- a CTA behavior changes
- a panel screen changes
- a refund or payout policy changes
- a notification trigger changes
- admin workflow changes
- assignment logic changes

