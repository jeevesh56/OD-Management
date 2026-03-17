from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
from flask import jsonify
from app import db
from datetime import datetime


# ─── ROLE GUARD DECORATOR ─────────────────────────────────────────────────────
def role_required(*allowed_roles):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            identity = get_jwt_identity()
            if identity.get("role") not in allowed_roles:
                return jsonify({"error": "Forbidden — insufficient role"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def current_user_id():
    return get_jwt_identity().get("user_id")


def current_role():
    return get_jwt_identity().get("role")


# ─── OVERLAP CHECK ────────────────────────────────────────────────────────────
def has_overlap(student_id, start_date, end_date, exclude_id=None):
    from app.models import ODRequest
    terminal = ["MENTOR_REJECTED", "EC_REJECTED", "HOD_REJECTED", "EXPIRED"]
    q = ODRequest.query.filter(
        ODRequest.student_id == student_id,
        ODRequest.status.notin_(terminal),
        ODRequest.start_date <= end_date,
        ODRequest.end_date   >= start_date,
    )
    if exclude_id:
        q = q.filter(ODRequest.request_id != exclude_id)
    return q.first()


# ─── AUDIT LOG WRITER ─────────────────────────────────────────────────────────
def write_audit(actor_id, action, request_id=None, meta=None):
    from app.models import AuditLog
    log = AuditLog(
        actor_id=actor_id,
        action=action,
        request_id=request_id,
        meta=meta or {},
    )
    db.session.add(log)


# ─── OD SESSION CREATOR ───────────────────────────────────────────────────────
def create_od_session(od_request, approver_name):
    from app.models import StudentProfile, ODSession
    profile = StudentProfile.query.get(od_request.student_id)
    if not profile:
        return None

    start_dt = datetime.combine(od_request.start_date, od_request.start_time)
    end_dt   = datetime.combine(od_request.end_date,   od_request.end_time)

    # Deactivate any existing active session
    ODSession.query.filter_by(
        student_unique_id=profile.unique_id_number, is_active=True
    ).update({"is_active": False})

    session = ODSession(
        student_unique_id=profile.unique_id_number,
        request_id=od_request.request_id,
        event_name=od_request.event_name,
        start_datetime=start_dt,
        end_datetime=end_dt,
        approved_by_name=approver_name,
        is_active=True,
    )
    db.session.add(session)
    return session


# ─── FCM NOTIFICATION ─────────────────────────────────────────────────────────
def send_notification(user_id, title, body, data=None):
    """
    Stub — integrate firebase_admin.messaging here.
    Install: pip install firebase-admin
    Then initialise the SDK once in create_app() using a service account key.
    """
    from app.models import User
    user = User.query.get(user_id)
    if not user or not user.fcm_token:
        return
    # firebase_admin.messaging.send(
    #     messaging.Message(
    #         notification=messaging.Notification(title=title, body=body),
    #         data=data or {},
    #         token=user.fcm_token,
    #     )
    # )
    print(f"[FCM] → {user.full_name} | {title}: {body}")
