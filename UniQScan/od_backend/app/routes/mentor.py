from flask import Blueprint, request, jsonify
from datetime import datetime
from app import db
from app.models import ODRequest, ApprovalRecord, StudentProfile, User
from app.services.helpers import (
    role_required, current_user_id, write_audit, send_notification
)

mentor_bp = Blueprint("mentor", __name__)


@mentor_bp.route("/queue", methods=["GET"])
@role_required("mentor")
def queue():
    mentor_id   = current_user_id()
    student_ids = [p.student_id for p in
                   StudentProfile.query.filter_by(mentor_id=mentor_id).all()]

    ods = (ODRequest.query
           .filter(ODRequest.student_id.in_(student_ids),
                   ODRequest.status == "PENDING")
           .order_by(ODRequest.submitted_at.asc()).all())

    result = []
    for od in ods:
        d = od.to_dict()
        d["elapsed_hours"] = round(
            (datetime.utcnow() - od.submitted_at).total_seconds() / 3600, 1)
        if od.student and od.student.student_profile:
            d["attendance_pct"] = float(od.student.student_profile.attendance_pct)
            d["roll_number"]    = od.student.student_profile.roll_number
        result.append(d)

    return jsonify({"queue": result, "count": len(result)}), 200


@mentor_bp.route("/request/<request_id>", methods=["GET"])
@role_required("mentor")
def detail(request_id):
    od = ODRequest.query.get_or_404(request_id)
    d  = od.to_dict(include_approvals=True)
    if od.student and od.student.student_profile:
        d["attendance_pct"] = float(od.student.student_profile.attendance_pct)
        d["roll_number"]    = od.student.student_profile.roll_number
    return jsonify(d), 200


@mentor_bp.route("/action", methods=["POST"])
@role_required("mentor")
def action():
    data       = request.get_json() or {}
    mentor_id  = current_user_id()
    request_id = data.get("request_id")
    act        = data.get("action")          # APPROVED | REJECTED
    reason     = data.get("reason")

    if not request_id or act not in ("APPROVED", "REJECTED"):
        return jsonify({"error": "request_id and action (APPROVED|REJECTED) required"}), 400
    if act == "REJECTED" and not reason:
        return jsonify({"error": "reason is required when rejecting"}), 400

    od = ODRequest.query.get_or_404(request_id)
    if od.status != "PENDING":
        return jsonify({"error": f"Request status is '{od.status}', not PENDING"}), 409

    profile = StudentProfile.query.get(od.student_id)
    if not profile or profile.mentor_id != mentor_id:
        return jsonify({"error": "This student is not in your section"}), 403

    new_status = "MENTOR_APPROVED" if act == "APPROVED" else "MENTOR_REJECTED"
    od.status  = new_status

    db.session.add(ApprovalRecord(
        request_id=request_id, approver_id=mentor_id,
        stage="MENTOR", action=act, reason=reason,
        comment=data.get("comment"),
    ))
    write_audit(mentor_id, new_status, request_id)
    db.session.commit()

    mentor = User.query.get(mentor_id)
    if act == "APPROVED":
        # Next stage: HoD approval (mentor -> HoD)
        if profile and profile.hod_id:
            send_notification(profile.hod_id, "OD Awaiting HoD Approval",
                f"{od.student.full_name}'s OD for {od.event_name} needs your approval",
                {"type": "od_pending_hod", "request_id": request_id})
    else:
        send_notification(od.student_id, "OD Rejected by Mentor",
            f"Your OD for {od.event_name} was rejected. Reason: {reason}",
            {"type": "od_status_update", "request_id": request_id})

    return jsonify({"status": new_status}), 200


@mentor_bp.route("/history", methods=["GET"])
@role_required("mentor")
def history():
    mentor_id   = current_user_id()
    student_ids = [p.student_id for p in
                   StudentProfile.query.filter_by(mentor_id=mentor_id).all()]

    ods = (ODRequest.query
           .filter(ODRequest.student_id.in_(student_ids),
                   ODRequest.status.in_(["MENTOR_APPROVED", "MENTOR_REJECTED"]))
           .order_by(ODRequest.submitted_at.desc()).limit(200).all())

    return jsonify({"items": [o.to_dict(include_approvals=True) for o in ods],
                    "count": len(ods)}), 200
