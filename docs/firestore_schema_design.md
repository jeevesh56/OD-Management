# Firestore Schema Design

## Collection: `users`
### Fields
- `uid` (string, doc id)
- `email` (string, unique)
- `full_name` (string)
- `role` (string: student|mentor|hod|principal|ec|admin)
- `department` (string)
- `section` (string, nullable)
- `mentor_id` (string, nullable)
- `class_advisor_id` (string, nullable)
- `requires_password_change` (bool)
- `is_active` (bool)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Example
```json
{
  "uid": "u_student_001",
  "email": "jeevesh.240158@cse.ritchennai.edu.in",
  "full_name": "Jeevesh R",
  "role": "student",
  "department": "CSE",
  "section": "A",
  "mentor_id": "u_mentor_cse_a",
  "requires_password_change": true,
  "is_active": true,
  "created_at": "2026-04-25T12:00:00Z",
  "updated_at": "2026-04-25T12:00:00Z"
}
```

## Collection: `od_requests`
### Fields
- `request_id` (string, doc id)
- `student_id` (ref: users.uid)
- `department` (string, denormalized)
- `section` (string, denormalized)
- `event_name` (string)
- `event_type` (string)
- `organizer` (string)
- `venue` (string)
- `start_datetime` (timestamp)
- `end_datetime` (timestamp)
- `is_multi_day` (bool)
- `reason` (string)
- `proof_url` (string)
- `status` (string)
- `current_approver_role` (string)
- `affected_periods` (array of map)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Example
```json
{
  "request_id": "od_20260425_001",
  "student_id": "u_student_001",
  "department": "CSE",
  "section": "A",
  "event_name": "Hackathon Finals",
  "event_type": "competition",
  "organizer": "IEEE Chennai",
  "venue": "Anna University",
  "start_datetime": "2026-04-28T09:00:00Z",
  "end_datetime": "2026-04-28T16:00:00Z",
  "is_multi_day": false,
  "reason": "Selected finalist",
  "proof_url": "gs://od/proofs/od_20260425_001.pdf",
  "status": "PENDING",
  "current_approver_role": "mentor",
  "affected_periods": [
    {"day": "Tuesday", "period": 2, "subject": "DSA"}
  ],
  "created_at": "2026-04-25T12:10:00Z",
  "updated_at": "2026-04-25T12:10:00Z"
}
```

## Collection: `approvals`
### Fields
- `approval_id` (string, doc id)
- `request_id` (ref: od_requests.request_id)
- `approver_id` (ref: users.uid)
- `approver_role` (string)
- `decision` (string: approved|rejected)
- `reason` (string, mandatory for reject)
- `created_at` (timestamp)

### Example
```json
{
  "approval_id": "apr_001",
  "request_id": "od_20260425_001",
  "approver_id": "u_mentor_cse_a",
  "approver_role": "mentor",
  "decision": "approved",
  "reason": "Valid participation proof attached.",
  "created_at": "2026-04-25T13:00:00Z"
}
```

## Collection: `timetable`
### Fields
- `timetable_id` (string, doc id)
- `department` (string)
- `section` (string)
- `semester` (number)
- `day` (string)
- `periods` (array of maps: period_no, start, end, subject, faculty_id)
- `updated_at` (timestamp)

### Example
```json
{
  "timetable_id": "CSE_A_TUE",
  "department": "CSE",
  "section": "A",
  "semester": 4,
  "day": "Tuesday",
  "periods": [
    {"period_no": 1, "start": "08:00", "end": "08:50", "subject": "CN", "faculty_id": "u_mentor_cse_a"},
    {"period_no": 2, "start": "09:00", "end": "09:50", "subject": "DSA", "faculty_id": "u_mentor_cse_a"}
  ],
  "updated_at": "2026-04-25T11:00:00Z"
}
```

## Collection: `notifications`
### Fields
- `notification_id` (string, doc id)
- `to_user_id` (ref: users.uid)
- `type` (string)
- `title` (string)
- `body` (string)
- `request_id` (string, nullable)
- `is_read` (bool)
- `created_at` (timestamp)

### Example
```json
{
  "notification_id": "n_001",
  "to_user_id": "u_mentor_cse_a",
  "type": "od_pending_review",
  "title": "OD Request Pending",
  "body": "1 request requires your approval.",
  "request_id": "od_20260425_001",
  "is_read": false,
  "created_at": "2026-04-25T12:12:00Z"
}
```

## Collection: `logs`
### Fields
- `log_id` (string, doc id)
- `actor_id` (ref: users.uid)
- `actor_role` (string)
- `action` (string)
- `entity_type` (string)
- `entity_id` (string)
- `metadata` (map)
- `created_at` (timestamp)

### Example
```json
{
  "log_id": "log_001",
  "actor_id": "u_hod_cse",
  "actor_role": "hod",
  "action": "OD_APPROVED",
  "entity_type": "od_request",
  "entity_id": "od_20260425_001",
  "metadata": {"comment": "Approved for academics"},
  "created_at": "2026-04-25T14:00:00Z"
}
```

## Collection: `ec_requests`
### Fields
- `ec_request_id` (string, doc id)
- `created_by` (ref: users.uid, role ec)
- `request_type` (string: bulk|long_term|inter_department)
- `title` (string)
- `description` (string)
- `student_ids` (array of user refs)
- `start_date` (date)
- `end_date` (date)
- `target_departments` (array of string)
- `status` (string)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Example
```json
{
  "ec_request_id": "ec_001",
  "created_by": "u_ec_01",
  "request_type": "bulk",
  "title": "SAE Workshop Participants",
  "description": "Bulk OD request for zonal event",
  "student_ids": ["u_student_001", "u_student_002"],
  "start_date": "2026-05-10",
  "end_date": "2026-05-10",
  "target_departments": ["CSE", "ECE"],
  "status": "PENDING_HOD",
  "created_at": "2026-04-25T12:30:00Z",
  "updated_at": "2026-04-25T12:30:00Z"
}
```

## Relationships
- `users.uid` -> `od_requests.student_id`
- `users.uid` -> `approvals.approver_id`
- `od_requests.request_id` -> `approvals.request_id`
- `users.uid` -> `notifications.to_user_id`
- `od_requests.request_id` -> `notifications.request_id`
- `users.uid` -> `logs.actor_id`
- `users.uid` -> `ec_requests.created_by`
- `users.uid` -> `ec_requests.student_ids[]`

## Collection: `scan_logs`
### Fields
- `scan_log_id` (string, doc id)
- `request_id` (ref: od_requests.request_id)
- `student_register_number` (string)
- `scanned_by` (ref: users.uid)
- `scanner_role` (string)
- `result` (string: valid|invalid|expired)
- `created_at` (timestamp)

### Example
```json
{
  "scan_log_id": "scan_001",
  "request_id": "od_20260425_001",
  "student_register_number": "2117240020158",
  "scanned_by": "u_mentor_cse_a",
  "scanner_role": "mentor",
  "result": "valid",
  "created_at": "2026-04-25T15:10:00Z"
}
```

## Collection: `pdf_exports`
### Fields
- `pdf_export_id` (string, doc id)
- `request_id` (ref: od_requests.request_id)
- `generated_by` (ref: users.uid, optional system user)
- `storage_path` (string)
- `status` (string: generated|failed)
- `created_at` (timestamp)

### Example
```json
{
  "pdf_export_id": "pdf_001",
  "request_id": "od_20260425_001",
  "generated_by": "system",
  "storage_path": "gs://od/pdfs/od_20260425_001.pdf",
  "status": "generated",
  "created_at": "2026-04-25T16:00:00Z"
}
```

## Collection: `fcm_tokens`
### Fields
- `fcm_token_id` (string, doc id)
- `user_id` (ref: users.uid)
- `token` (string)
- `platform` (string)
- `is_active` (bool)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Example
```json
{
  "fcm_token_id": "tok_001",
  "user_id": "u_mentor_cse_a",
  "token": "dummytokenvalue",
  "platform": "android",
  "is_active": true,
  "created_at": "2026-04-25T12:12:00Z",
  "updated_at": "2026-04-25T12:12:00Z"
}
```
