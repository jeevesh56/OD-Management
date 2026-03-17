from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from datetime import date, time
from app import db
from app.models import ODRequest, StudentProfile, ODSession
from app.services.helpers import (
    role_required, current_user_id,
    has_overlap, write_audit, send_notification
)
from datetime import datetime

student_bp = Blueprint("student", __name__)


@student_bp.route("/od-requests", methods=["POST"])
@role_required("student")
def submit_od():
    data       = request.get_json() or {}
    student_id = current_user_id()

    required = ["event_name", "organiser", "start_date", "end_date",
                "start_time", "end_time", "reason"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing: {missing}"}), 400

    try:
        start_date = date.fromisoformat(data["start_date"])
        end_date   = date.fromisoformat(data["end_date"])
        start_time = time.fromisoformat(data["start_time"])
        end_time   = time.fromisoformat(data["end_time"])
    except ValueError as e:
        return jsonify({"error": f"Invalid date/time: {e}"}), 422

    if end_date < start_date:
        return jsonify({"error": "end_date cannot be before start_date"}), 422

    conflict = has_overlap(student_id, start_date, end_date)
    if conflict:
        return jsonify({
            "error": "You already have an OD for overlapping dates",
            "conflicting_request_id": conflict.request_id,
        }), 409

    od = ODRequest(
        student_id=student_id,
        event_id=data.get("event_id"),
        event_name=data["event_name"],
        organiser=data["organiser"],
        venue=data.get("venue", ""),
        start_date=start_date,
        end_date=end_date,
        start_time=start_time,
        end_time=end_time,
        reason=data["reason"],
        attachment_name=data.get("attachment_name"),
        attachment_mime=data.get("attachment_mime"),
        attachment_base64=data.get("attachment_base64"),
    )
    db.session.add(od)
    db.session.flush()
    write_audit(student_id, "SUBMITTED", od.request_id)
    db.session.commit()

    # Notify mentor
    profile = StudentProfile.query.get(student_id)
    if profile:
        send_notification(profile.mentor_id, "New OD Request",
            f"{od.student.full_name} needs OD approval for {od.event_name}",
            {"type": "od_pending_mentor", "request_id": od.request_id})

    return jsonify({"request_id": od.request_id, "status": "PENDING"}), 201


@student_bp.route("/od-requests", methods=["GET"])
@role_required("student")
def my_requests():
    student_id = current_user_id()
    ods = (ODRequest.query
           .filter_by(student_id=student_id)
           .order_by(ODRequest.submitted_at.desc()).all())
    return jsonify({"requests": [r.to_dict(include_approvals=True) for r in ods]}), 200


@student_bp.route("/od-requests/<request_id>", methods=["GET"])
@role_required("student")
def get_request(request_id):
    od = ODRequest.query.filter_by(
        request_id=request_id, student_id=current_user_id()
    ).first_or_404()
    return jsonify(od.to_dict(include_approvals=True)), 200


@student_bp.route("/check-overlap", methods=["GET"])
@role_required("student")
def check_overlap():
    start_str = request.args.get("start_date")
    end_str   = request.args.get("end_date")
    if not start_str or not end_str:
        return jsonify({"error": "start_date and end_date required"}), 400
    try:
        start_date = date.fromisoformat(start_str)
        end_date   = date.fromisoformat(end_str)
    except ValueError:
        return jsonify({"error": "Use YYYY-MM-DD format"}), 422

    conflict = has_overlap(current_user_id(), start_date, end_date)
    return jsonify({
        "has_overlap":            bool(conflict),
        "conflicting_event_name": conflict.event_name if conflict else None,
    }), 200


@student_bp.route("/active-session", methods=["GET"])
@role_required("student")
def active_session():
    profile = StudentProfile.query.get(current_user_id())
    if not profile:
        return jsonify({"active": False}), 200

    now = datetime.utcnow()
    s   = (ODSession.query
           .filter_by(student_unique_id=profile.unique_id_number, is_active=True)
           .filter(ODSession.start_datetime <= now, ODSession.end_datetime >= now)
           .first())
    return jsonify({"active": bool(s), "session": s.to_dict() if s else None}), 200
