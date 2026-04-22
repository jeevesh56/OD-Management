# OD Management FastAPI Backend

## File Structure

- `main.py`: FastAPI app, API routes, status workflow, compatibility routes
- `models.py`: SQLAlchemy models (`events`, `od_requests`)
- `database.py`: SQLite engine/session setup
- `uploads/`: persisted uploaded proof files
- `od_management.db`: SQLite persistent DB (created on first run)

## Setup

Recommended Python version: 3.12 (tested).

```bash
cd backend
py -3.12 -m venv .venv
.venv\\Scripts\\activate
pip install -r requirements.txt
```

## Run

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 5000
```

Open docs:
- http://localhost:5000/docs

## Core APIs (requested)

### Event APIs
- `POST /create-event`
- `GET /events`

### OD APIs
- `POST /create-od` (multipart, supports `proof_file` upload)
- `GET /requests`
- `GET /requests/mentor`
- `GET /requests/ec`
- `GET /requests/hod`

### Status Update
- `PUT /update-status/{id}` with body:

```json
{
  "role": "mentor",
  "action": "APPROVED",
  "note": "Looks valid"
}
```

## Flutter compatibility APIs

To work with your current Flutter app without rewriting all frontend calls, these routes are also included:

- `GET /api/events`
- `POST /api/student/od-requests`
- `GET /api/student/od-requests`
- `GET /api/student/check-overlap`
- `GET /api/student/active-session`
- `GET /api/mentor/queue`, `POST /api/mentor/action`, `GET /api/mentor/history`
- `GET /api/ec/queue`, `POST /api/ec/action`
- `GET /api/hod/queue`, `POST /api/hod/action`, `POST /api/hod/bulk-action`, `GET /api/hod/analytics`

## Status Flow

- `PENDING` -> visible to Mentor
- Mentor approve -> `MENTOR_APPROVED` -> visible to EC
- EC approve -> `EC_CONFIRMED` -> visible to HoD
- HoD approve -> `HOD_APPROVED`
- Verifier complete -> `COMPLETED` (final)
- Reject at any stage -> `REJECTED`

Verifier API:
- `POST /api/verifier/complete` with `request_id`

## Persistence

- Events and OD requests are saved to SQLite (`od_management.db`), so data persists after backend restart.
- Uploaded files are saved under `uploads/` and persist after restart.
