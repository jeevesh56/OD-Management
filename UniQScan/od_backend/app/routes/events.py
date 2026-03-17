from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from datetime import date
from app import db
from app.models import Event
from app.models import ODRequest, StudentProfile
from app.services.helpers import role_required, current_user_id, current_role

events_bp = Blueprint("events", __name__)


@events_bp.route("", methods=["GET"])
@role_required("student", "mentor", "event_coordinator", "hod")
def list_events():
    events = Event.query.order_by(Event.start_date.desc()).all()
    return jsonify({"events": [e.to_dict() for e in events]}), 200


@events_bp.route("", methods=["POST"])
@role_required("event_coordinator")
def create_event():
    data  = request.get_json() or {}
    ec_id = current_user_id()

    required = ["event_name", "organiser_body", "venue", "start_date", "end_date"]
    missing  = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing: {missing}"}), 400

    try:
        start = date.fromisoformat(data["start_date"])
        end   = date.fromisoformat(data["end_date"])
    except ValueError:
        return jsonify({"error": "Dates must be YYYY-MM-DD"}), 422

    if end < start:
        return jsonify({"error": "end_date cannot be before start_date"}), 422

    ev = Event(
        event_name=data["event_name"],
        organiser_body=data["organiser_body"],
        coordinator_id=ec_id,
        venue=data["venue"],
        start_date=start,
        end_date=end,
        description=data.get("description"),
    )
    db.session.add(ev)
    db.session.commit()
    return jsonify({"message": "Event created", "event": ev.to_dict()}), 201


@events_bp.route("/<event_id>", methods=["GET"])
@role_required("student", "mentor", "event_coordinator", "hod")
def get_event(event_id):
    ev = Event.query.get_or_404(event_id)
    return jsonify(ev.to_dict()), 200


@events_bp.route("/<event_id>/registrations", methods=["GET"])
@role_required("event_coordinator", "hod", "mentor")
def registrations(event_id):
    ev = Event.query.get_or_404(event_id)

    # Event coordinators can only view their own events.
    if current_role() == "event_coordinator":
        if ev.coordinator_id != current_user_id():
            return jsonify({"error": "This event does not belong to you"}), 403

    ods = (
        ODRequest.query.filter_by(event_id=event_id)
        .order_by(ODRequest.submitted_at.desc())
        .all()
    )

    out = []
    for od in ods:
        d = od.to_dict(include_approvals=False)
        if od.student and od.student.student_profile:
            d["roll_number"] = od.student.student_profile.roll_number
            d["unique_id_number"] = od.student.student_profile.unique_id_number
        out.append(d)

    return jsonify({"event": ev.to_dict(), "registrations": out, "count": len(out)}), 200
