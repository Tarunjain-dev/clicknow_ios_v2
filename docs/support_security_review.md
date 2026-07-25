# Support Security Review

The support feature currently uses direct Firestore and Firebase Storage writes
for its MVP implementation.

The prototype rules in this folder are intentionally not connected to
`firebase.json` because deploying a support-only rules file would deny access to
all existing ClickNow collections.

## Important Finding

The client service must update ticket metadata, unread counters, and audit logs
while sending messages. A strict production policy should move these mutations
behind authenticated Cloud Functions. The prototype rules therefore represent
the desired least-privilege direction, but do not yet support every direct
client mutation in the MVP.

## Required Before Production

1. Merge support rules into the complete application Firestore and Storage rules.
2. Move ticket metadata, status, priority, assignment, unread counters, system
   messages, and audit-log writes behind Cloud Functions.
3. Verify admin authority from custom claims or a protected admin collection.
4. Test rules with the Firebase Emulator Suite for owner, other user,
   professional, and admin identities.
5. Deploy the required composite indexes only after the final query strategy is
   confirmed.

## Red-Team Assessment

- Score: 3/5 for the prototype.
- Strong points: default deny, ownership checks, admin checks from Firestore,
  type/length validation, no deletes, and support-image size/content validation.
- Remaining risk: authority depends on the integrity of role fields in `users`;
  direct client metadata updates conflict with least privilege; full project
  rules are not available for cross-collection review.
