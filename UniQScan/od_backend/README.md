# RIT OD Management — Flask Backend

## Project Structure
```
od_backend/
├── app/
│   ├── __init__.py          # App factory
│   ├── models.py            # All database models
│   ├── routes/
│   │   ├── auth.py          # Login, register, refresh
│   │   ├── student.py       # Submit OD, history, overlap check
│   │   ├── mentor.py        # Mentor queue, approve/reject
│   │   ├── ec.py            # EC queue, confirm/reject, PDF upload
│   │   ├── hod.py           # HoD queue, bulk approve, analytics
│   │   └── verify.py        # QR scan verification + Events
│   └── services/
│       └── helpers.py       # Decorators, audit log, session creator
├── run.py                   # Entry point
├── seed.py                  # Creates test users
├── requirements.txt
└── .env.example
```

## Setup (Step by Step)

### 1. Install PostgreSQL and create the database
```sql
CREATE USER od_user WITH PASSWORD 'od_pass';
CREATE DATABASE od_management OWNER od_user;
```

### 2. Clone and install dependencies
```bash
cd od_backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure environment
```bash
cp .env.example .env
# Edit .env with your DATABASE_URL and a strong JWT_SECRET_KEY
```

### 4. Create tables + seed test users
```bash
python seed.py
```

### 5. Run the server
```bash
python run.py
# Server starts at http://localhost:5000
```

---

## API Reference

### Auth
| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| POST | /api/auth/register | email, password, role, full_name, phone, dept | Register user |
| POST | /api/auth/login | email, password | Get tokens |
| POST | /api/auth/refresh | — (refresh token in header) | New access token |
| GET  | /api/auth/me | — | Current user profile |
| POST | /api/auth/update-fcm-token | fcm_token | Update push token |

### Student
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/student/od-requests | Submit new OD |
| GET  | /api/student/od-requests | My OD history |
| GET  | /api/student/od-requests/:id | Single OD detail |
| GET  | /api/student/check-overlap?start_date=&end_date= | Check date conflict |
| GET  | /api/student/active-session | Current active OD session |

### Mentor
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | /api/mentor/queue | PENDING requests for my students |
| GET  | /api/mentor/request/:id | Request detail |
| POST | /api/mentor/action | {request_id, action: APPROVED\|REJECTED, reason} |

### Event Coordinator
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | /api/ec/queue | MENTOR_APPROVED requests for my events |
| POST | /api/ec/action | {request_id, action: CONFIRMED\|REJECTED, reason} |
| POST | /api/ec/bulk-upload | multipart: event_id + file (PDF) |

### HoD
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | /api/hod/queue | EC_CONFIRMED requests |
| POST | /api/hod/action | {request_id, action: APPROVED\|REJECTED, reason} |
| POST | /api/hod/bulk-action | {event_id} — approve all EC_CONFIRMED for event |
| GET  | /api/hod/analytics | Summary stats |
| GET  | /api/hod/active-sessions | All currently active OD sessions |
| GET  | /api/hod/audit-log | Last 200 audit entries |

### Verification
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | /api/verify/:unique_id | Scan result: active \| inactive \| out_of_window |

### Events
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET  | /api/events | List all events |
| POST | /api/events | Create event (EC only) |
| GET  | /api/events/:id | Event detail |

---

## Nowa / Flutter Integration

Set your Nowa API base URL to:
```
http://<your-server-ip>:5000
```

All endpoints require the Authorization header:
```
Authorization: Bearer <access_token>
```

The access_token is returned from POST /api/auth/login.

## OD Status Flow
```
PENDING → MENTOR_APPROVED → EC_CONFIRMED → HOD_APPROVED → [OD Session Created]
       ↘ MENTOR_REJECTED   ↘ EC_REJECTED  ↘ HOD_REJECTED
```

## Test Accounts (after running seed.py)
| Role | Email | Password |
|------|-------|----------|
| Student | student@rit.edu | Test@1234 |
| Mentor | mentor@rit.edu | Test@1234 |
| EC | ec@rit.edu | Test@1234 |
| HoD | hod@rit.edu | Test@1234 |
| Verifier | verifier@rit.edu | Test@1234 |

Student QR value (scan this to test verify): `2117240020160`
