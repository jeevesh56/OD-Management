import re
from flask import Blueprint, request, jsonify
from datetime import datetime
from app import db
from app.models import ODSession, StudentProfile
from app.services.helpers import role_required, current_user_id, write_audit

verify_bp = Blueprint("verify", __name__)


@verify_bp.route("/<unique_id>", methods=["GET"])
@role_required("mentor", "event_coordinator", "hod", "verifier")
def verify(unique_id):
    if not re.match(r"^[a-zA-Z0-9]{4,25}$", unique_id):
        return jsonify({"error": "Invalid unique ID format"}), 400

    actor_id = current_user_id()
    now      = datetime.utcnow()

    session = (ODSession.query
               .filter_by(student_unique_id=unique_id, is_active=True)
               .filter(ODSession.start_datetime <= now,
                       ODSession.end_datetime   >= now)
               .first())

    if session:
        profile      = StudentProfile.query.filter_by(unique_id_number=unique_id).first()
        student_name = profile.user.full_name if profile and profile.user else "Unknown"
        write_audit(actor_id, "SCAN_ACTIVE", session.request_id,
                    {"student_unique_id": unique_id})
        db.session.commit()
        return jsonify({
            "status":         "active",
            "unique_id":      unique_id,
            "student_name":   student_name,
            "event_name":     session.event_name,
            "start_datetime": session.start_datetime.isoformat(),
            "end_datetime":   session.end_datetime.isoformat(),
            "approved_by":    session.approved_by_name,
        }), 200

    out_of_window = ODSession.query.filter_by(
        student_unique_id=unique_id, is_active=True).first()

    write_audit(actor_id, "SCAN_INACTIVE",
                meta={"student_unique_id": unique_id})
    db.session.commit()

    if out_of_window:
        return jsonify({
            "status":         "out_of_window",
            "unique_id":      unique_id,
            "event_name":     out_of_window.event_name,
            "start_datetime": out_of_window.start_datetime.isoformat(),
            "end_datetime":   out_of_window.end_datetime.isoformat(),
        }), 200

    return jsonify({"status": "inactive", "unique_id": unique_id}), 200
