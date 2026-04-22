# Frontend Integration Example

Use this base URL in Flutter:

- http://localhost:5000

## Event list (student event dropdown)

GET /api/events

Response:

{
  "events": [
    {
      "id": 1,
      "event_id": "1",
      "event_name": "Department Symposium",
      "venue": "Main Auditorium",
      "timing": "2026-04-25 09:00 - 16:00",
      "description": "CSE Department",
      "organiser_body": "CSE Department"
    }
  ]
}

## Create OD request (current Flutter-compatible JSON)

POST /api/student/od-requests

Body example:

{
  "student_name": "Jeevesh",
  "email": "jeevesh.240158@cse.ritchennai.edu.in",
  "reason": "Attending technical symposium",
  "event_id": 1,
  "event_name": "Department Symposium",
  "venue": "Main Auditorium",
  "start_date": "2026-04-25",
  "end_date": "2026-04-25",
  "start_time": "09:00",
  "end_time": "16:00",
  "attachment_base64": "...",
  "attachment_mime": "application/pdf",
  "attachment_name": "proof.pdf"
}

## Role queues

- Mentor queue: GET /api/mentor/queue
- EC queue: GET /api/ec/queue
- HoD queue: GET /api/hod/queue

## Role actions

- Mentor action: POST /api/mentor/action
  - action: APPROVED or REJECTED
- EC action: POST /api/ec/action
  - action: CONFIRMED or REJECTED
- HoD action: POST /api/hod/action
  - action: APPROVED or REJECTED
