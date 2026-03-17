from flask import Blueprint, request, jsonify
from datetime import datetime, time
from app import db
from app.models import ODRequest, ApprovalRecord, StudentProfile, User, Event
from app.services.helpers import (
    role_required, current_user_id, write_audit,
    send_notification, has_overlap
)

ec_bp = Blueprint("ec", __name__)


@ec_bp.route("/queue", methods=["GET"])
@role_required("event_coordinator")
def queue():
    ec_id     = current_user_id()
    event_ids = [e.event_id for e in Event.query.filter_by(coordinator_id=ec_id).all()]

    ods = (ODRequest.query
           .filter(ODRequest.event_id.in_(event_ids),
                   ODRequest.status == "MENTOR_APPROVED")
           .order_by(ODRequest.submitted_at.asc()).all())

    result = []
    for od in ods:
        d = od.to_dict()
        if od.student and od.student.student_profile:
            d["roll_number"] = od.student.student_profile.roll_number
        result.append(d)

    return jsonify({"queue": result, "count": len(result)}), 200


@ec_bp.route("/action", methods=["POST"])
@role_required("event_coordinator")
def action():
    data       = request.get_json() or {}
    ec_id      = current_user_id()
    request_id = data.get("request_id")
    act        = data.get("action")         # CONFIRMED | REJECTED
    reason     = data.get("reason")

    if not request_id or act not in ("CONFIRMED", "REJECTED"):
        return jsonify({"error": "request_id and action (CONFIRMED|REJECTED) required"}), 400
    if act == "REJECTED" and not reason:
        return jsonify({"error": "reason required when rejecting"}), 400

    od = ODRequest.query.get_or_404(request_id)
    if od.status != "MENTOR_APPROVED":
        return jsonify({"error": f"Status is '{od.status}', expected MENTOR_APPROVED"}), 409

    if od.event_id:
        ev = Event.query.get(od.event_id)
        if not ev or ev.coordinator_id != ec_id:
            return jsonify({"error": "This event does not belong to you"}), 403

    new_status = "EC_CONFIRMED" if act == "CONFIRMED" else "EC_REJECTED"
    od.status  = new_status

    db.session.add(ApprovalRecord(
        request_id=request_id, approver_id=ec_id,
        stage="EC", action="APPROVED" if act == "CONFIRMED" else "REJECTED",
        reason=reason,
    ))
    write_audit(ec_id, new_status, request_id)
    db.session.commit()

    if act == "CONFIRMED":
        profile = StudentProfile.query.get(od.student_id)
        if profile:
            send_notification(profile.hod_id, "OD Awaiting HoD Approval",
                f"{od.student.full_name}'s OD for {od.event_name} needs your approval",
                {"type": "od_pending_hod", "request_id": request_id})
    else:
        send_notification(od.student_id, "OD Rejected by EC",
            f"Your OD for {od.event_name} was rejected. Reason: {reason}",
            {"type": "od_status_update", "request_id": request_id})

    return jsonify({"status": new_status}), 200


@ec_bp.route("/bulk-upload", methods=["POST"])
@role_required("event_coordinator")
def bulk_upload():
    ec_id    = current_user_id()
    event_id = request.form.get("event_id")
    if not event_id:
        return jsonify({"error": "event_id required"}), 400
    if "file" not in request.files:
        return jsonify({"error": "PDF file required"}), 400

    ev = Event.query.filter_by(event_id=event_id, coordinator_id=ec_id).first()
    if not ev:
        return jsonify({"error": "Event not found or not yours"}), 404

    pdf_file = request.files["file"]
    if not pdf_file.filename.lower().endswith(".pdf"):
        return jsonify({"error": "Only PDF files accepted"}), 400

    import re
    try:
        import fitz
        text = " ".join(
            page.get_text() for page in fitz.open(stream=pdf_file.read(), filetype="pdf")
        )
        roll_numbers = list(set(re.findall(r"\b\d{10,13}\b", text)))
    except Exception as e:
        return jsonify({"error": f"PDF parse failed: {e}"}), 500

    created, unmatched = [], []
    for roll in roll_numbers:
        profile = StudentProfile.query.filter_by(roll_number=roll).first()
        if not profile:
            unmatched.append(roll)
            continue
        if has_overlap(profile.student_id, ev.start_date, ev.end_date):
            unmatched.append(f"{roll} (date conflict)")
            continue

        od = ODRequest(
            student_id=profile.student_id,
            event_id=event_id,
            event_name=ev.event_name,
            organiser=ev.organiser_body,
            venue=ev.venue,
            start_date=ev.start_date,
            end_date=ev.end_date,
            start_time=time(8, 0),
            end_time=time(18, 0),
            reason=f"Participating in {ev.event_name} (bulk upload)",
            status="EC_CONFIRMED",
        )
        db.session.add(od)
        db.session.flush()

        db.session.add(ApprovalRecord(
            request_id=od.request_id, approver_id=ec_id,
            stage="EC", action="APPROVED",
            comment="PDF bulk upload",
        ))
        write_audit(ec_id, "EC_CONFIRMED", od.request_id,
                    {"source": "pdf_bulk_upload"})
        created.append(od.request_id)

        send_notification(profile.hod_id, "OD Awaiting HoD Approval",
            f"{profile.user.full_name}'s OD for {ev.event_name} (bulk) needs approval",
            {"type": "od_pending_hod", "request_id": od.request_id})

    db.session.commit()
    return jsonify({
        "created_count":          len(created),
        "unmatched_roll_numbers": unmatched,
    }), 200
