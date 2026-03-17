from flask import Blueprint, request, jsonify
from datetime import datetime
from app import db
from app.models import (ODRequest, ApprovalRecord, StudentProfile,
                        User, ODSession, AuditLog)
from app.services.helpers import (
    role_required, current_user_id, write_audit,
    send_notification, create_od_session
)

hod_bp = Blueprint("hod", __name__)


def _student_ids(hod_id):
    return [p.student_id for p in
            StudentProfile.query.filter_by(hod_id=hod_id).all()]


@hod_bp.route("/queue", methods=["GET"])
@role_required("hod")
def queue():
    hod_id = current_user_id()
    ods    = (ODRequest.query
              .filter(ODRequest.student_id.in_(_student_ids(hod_id)),
                      ODRequest.status.in_(["EC_CONFIRMED", "MENTOR_APPROVED"]))
              .order_by(ODRequest.submitted_at.asc()).all())

    result = []
    for od in ods:
        d = od.to_dict(include_approvals=True)
        if od.student and od.student.student_profile:
            d["section"]     = od.student.student_profile.section
            d["roll_number"] = od.student.student_profile.roll_number
        result.append(d)

    return jsonify({"queue": result, "count": len(result)}), 200


@hod_bp.route("/action", methods=["POST"])
@role_required("hod")
def action():
    data       = request.get_json() or {}
    hod_id     = current_user_id()
    request_id = data.get("request_id")
    act        = data.get("action")         # APPROVED | REJECTED
    reason     = data.get("reason")

    if not request_id or act not in ("APPROVED", "REJECTED"):
        return jsonify({"error": "request_id and action required"}), 400

    od = ODRequest.query.get_or_404(request_id)
    if od.status not in ("EC_CONFIRMED", "MENTOR_APPROVED"):
        return jsonify({"error": f"Status is '{od.status}', expected EC_CONFIRMED or MENTOR_APPROVED"}), 409

    new_status = "HOD_APPROVED" if act == "APPROVED" else "HOD_REJECTED"
    od.status  = new_status
    hod        = User.query.get(hod_id)

    db.session.add(ApprovalRecord(
        request_id=request_id, approver_id=hod_id,
        stage="HOD", action=act, reason=reason,
    ))
    write_audit(hod_id, new_status, request_id)

    session_id = None
    if act == "APPROVED":
        sess = create_od_session(od, hod.full_name if hod else "HoD")
        if sess:
            db.session.flush()
            session_id = sess.session_id
            write_audit(hod_id, "SESSION_CREATED", request_id,
                        {"session_id": session_id})
        send_notification(od.student_id, "OD Approved! ✅",
            f"Your OD for {od.event_name} has been approved. You're all set!",
            {"type": "od_status_update", "request_id": request_id})
    else:
        send_notification(od.student_id, "OD Rejected by HoD",
            f"Your OD for {od.event_name} was rejected. Reason: {reason}",
            {"type": "od_status_update", "request_id": request_id})

    db.session.commit()
    return jsonify({"status": new_status, "session_id": session_id}), 200


@hod_bp.route("/bulk-action", methods=["POST"])
@role_required("hod")
def bulk_action():
    data     = request.get_json() or {}
    hod_id   = current_user_id()
    event_id = data.get("event_id")
    if not event_id:
        return jsonify({"error": "event_id required"}), 400

    hod = User.query.get(hod_id)
    q = ODRequest.query.filter(
        ODRequest.student_id.in_(_student_ids(hod_id)),
        ODRequest.status.in_(["EC_CONFIRMED", "MENTOR_APPROVED"]),
    )
    if event_id != "all":
        q = q.filter(ODRequest.event_id == event_id)
    ods = q.all()

    approved_count, session_ids = 0, []
    for od in ods:
        od.status = "HOD_APPROVED"
        db.session.add(ApprovalRecord(
            request_id=od.request_id, approver_id=hod_id,
            stage="HOD", action="APPROVED", comment="Bulk approved",
        ))
        write_audit(hod_id, "HOD_APPROVED", od.request_id, {"bulk": True})

        sess = create_od_session(od, hod.full_name if hod else "HoD")
        if sess:
            db.session.flush()
            session_ids.append(sess.session_id)
            write_audit(hod_id, "SESSION_CREATED", od.request_id)

        send_notification(od.student_id, "OD Approved! ✅",
            f"Your OD for {od.event_name} has been approved.",
            {"type": "od_status_update", "request_id": od.request_id})
        approved_count += 1

    db.session.commit()
    return jsonify({"approved_count": approved_count,
                    "session_ids": session_ids}), 200


@hod_bp.route("/analytics", methods=["GET"])
@role_required("hod")
def analytics():
    hod_id  = current_user_id()
    ids     = _student_ids(hod_id)
    now     = datetime.utcnow()

    total    = ODRequest.query.filter(ODRequest.student_id.in_(ids)).count()
    approved = ODRequest.query.filter(ODRequest.student_id.in_(ids),
                    ODRequest.status == "HOD_APPROVED").count()
    pending  = ODRequest.query.filter(ODRequest.student_id.in_(ids),
                    ODRequest.status.in_(["PENDING","MENTOR_APPROVED","EC_CONFIRMED"])).count()
    rejected = ODRequest.query.filter(ODRequest.student_id.in_(ids),
                    ODRequest.status.in_(["MENTOR_REJECTED","EC_REJECTED","HOD_REJECTED"])).count()
    active   = (ODSession.query.filter_by(is_active=True)
                .filter(ODSession.start_datetime <= now,
                        ODSession.end_datetime   >= now).count())

    return jsonify({
        "total": total, "approved": approved,
        "pending": pending, "rejected": rejected, "active_now": active,
    }), 200


@hod_bp.route("/active-sessions", methods=["GET"])
@role_required("hod")
def active_sessions():
    now      = datetime.utcnow()
    sessions = (ODSession.query.filter_by(is_active=True)
                .filter(ODSession.start_datetime <= now,
                        ODSession.end_datetime   >= now).all())
    return jsonify({"sessions": [s.to_dict() for s in sessions],
                    "count": len(sessions)}), 200


@hod_bp.route("/history", methods=["GET"])
@role_required("hod")
def history():
    hod_id = current_user_id()
    ods = (ODRequest.query
           .filter(ODRequest.student_id.in_(_student_ids(hod_id)),
                   ODRequest.status.in_(["HOD_APPROVED", "HOD_REJECTED"]))
           .order_by(ODRequest.submitted_at.desc()).limit(200).all())
    return jsonify({"items": [o.to_dict(include_approvals=True) for o in ods],
                    "count": len(ods)}), 200


@hod_bp.route("/audit-log", methods=["GET"])
@role_required("hod")
def audit_log():
    logs = (AuditLog.query.order_by(AuditLog.logged_at.desc()).limit(200).all())
    return jsonify({"logs": [l.to_dict() for l in logs]}), 200
