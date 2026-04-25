# OD Management Production Roadmap

## 1) Firebase Auth + Role system
1. Configure Firebase project per environment (dev/stage/prod).
2. Add Email/Password auth and enforce verified email.
3. Persist role profile in `users/{uid}` and mirror critical claims via custom claims.
4. Enforce first-login password change with `requires_password_change`.
5. Build auth guard + role guard in app navigation.

## 2) Firestore database schema
1. Create collections: `users`, `od_requests`, `approvals`, `timetable`, `notifications`, `logs`, `ec_requests`.
2. Add composite indexes for role queue filtering and timeline queries.
3. Add created/updated timestamps and immutable audit fields.
4. Document denormalized fields for read performance.

## 3) Backend rule validation (OD logic)
1. Move validation to trusted backend (Cloud Functions/Cloud Run).
2. Enforce no past date, time window, multi-day constraints.
3. Enforce state machine transitions (mentor -> hod -> principal).
4. Require rejection reason and write audit logs.

## 4) Role-based data access
1. Firestore Security Rules per role + department + class scope.
2. Restrict mentor reads to assigned class.
3. Restrict HoD reads/writes to department.
4. Restrict principal/admin to global access.

## 5) Timetable engine
1. Model period timetable by class/section/day.
2. Compute affected periods from OD date/time.
3. Store impacted subject/period snapshots inside OD request.
4. Trigger mentor alerts for class-time overlap.

## 6) Notification system
1. Add FCM tokens collection and token rotation handling.
2. Publish notifications on each approval/rejection transition.
3. Add in-app notification inbox with read/unread state.
4. Add mentor alert notifications for period conflict.

## 7) EC module
1. Build EC bulk request flow for selected students.
2. Add long-term OD support with date ranges and checkpoints.
3. Add inter-department routing logic.
4. Add dedicated EC review panels for HoD and principal.

## 8) QR verification system
1. Use signed QR payload (requestId, studentId, expiry, signature).
2. Build scanner screen + verify API endpoint.
3. Write scan logs with verifier identity and timestamp.
4. Show real-time OD validity status and expiry.

## 9) PDF export system
1. Generate PDF only after final principal approval.
2. Include signed metadata + QR hash + approval chain.
3. Upload PDFs to secure storage path.
4. Track download events in logs.
