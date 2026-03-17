from app import db
from datetime import datetime
import uuid


def gen_uuid():
    return str(uuid.uuid4())


# ─── USERS ────────────────────────────────────────────────────────────────────
class User(db.Model):
    __tablename__ = "users"

    user_id    = db.Column(db.String(36),  primary_key=True, default=gen_uuid)
    email      = db.Column(db.String(120), unique=True, nullable=False)
    password   = db.Column(db.String(255), nullable=False)
    role       = db.Column(db.String(30),  nullable=False)
    # student | mentor | event_coordinator | hod | verifier
    full_name  = db.Column(db.String(150), nullable=False)
    phone      = db.Column(db.String(15),  nullable=False)
    dept       = db.Column(db.String(80),  nullable=False)
    fcm_token  = db.Column(db.String(512), nullable=True)
    created_at = db.Column(db.DateTime,    default=datetime.utcnow)
    is_active  = db.Column(db.Boolean,     default=True)

    student_profile = db.relationship(
        "StudentProfile", backref="user", uselist=False,
        foreign_keys="StudentProfile.student_id"
    )

    def to_dict(self):
        return {
            "user_id":   self.user_id,
            "email":     self.email,
            "role":      self.role,
            "full_name": self.full_name,
            "phone":     self.phone,
            "dept":      self.dept,
        }


# ─── STUDENT PROFILES ─────────────────────────────────────────────────────────
class StudentProfile(db.Model):
    __tablename__ = "student_profiles"

    student_id       = db.Column(db.String(36), db.ForeignKey("users.user_id"),
                                 primary_key=True)
    unique_id_number = db.Column(db.String(25),  unique=True, nullable=False)
    roll_number      = db.Column(db.String(20),  unique=True, nullable=False)
    section          = db.Column(db.String(10),  nullable=False)
    semester         = db.Column(db.SmallInteger, nullable=False)
    mentor_id        = db.Column(db.String(36),  db.ForeignKey("users.user_id"),
                                 nullable=False)
    hod_id           = db.Column(db.String(36),  db.ForeignKey("users.user_id"),
                                 nullable=False)
    batch_year       = db.Column(db.SmallInteger, nullable=False)
    attendance_pct   = db.Column(db.Numeric(5, 2), default=0.00)

    mentor = db.relationship("User", foreign_keys=[mentor_id])
    hod    = db.relationship("User", foreign_keys=[hod_id])

    def to_dict(self):
        return {
            "student_id":       self.student_id,
            "unique_id_number": self.unique_id_number,
            "roll_number":      self.roll_number,
            "section":          self.section,
            "semester":         self.semester,
            "mentor_name":      self.mentor.full_name if self.mentor else None,
            "batch_year":       self.batch_year,
            "attendance_pct":   float(self.attendance_pct),
        }


# ─── EVENTS ───────────────────────────────────────────────────────────────────
class Event(db.Model):
    __tablename__ = "events"

    event_id       = db.Column(db.String(36),  primary_key=True, default=gen_uuid)
    event_name     = db.Column(db.String(200), nullable=False)
    organiser_body = db.Column(db.String(200), nullable=False)
    coordinator_id = db.Column(db.String(36),  db.ForeignKey("users.user_id"),
                               nullable=False)
    venue          = db.Column(db.String(200), nullable=False)
    start_date     = db.Column(db.Date,        nullable=False)
    end_date       = db.Column(db.Date,        nullable=False)
    description    = db.Column(db.Text,        nullable=True)
    created_at     = db.Column(db.DateTime,    default=datetime.utcnow)

    coordinator = db.relationship("User", foreign_keys=[coordinator_id])

    def to_dict(self):
        return {
            "event_id":         self.event_id,
            "event_name":       self.event_name,
            "organiser_body":   self.organiser_body,
            "coordinator_name": self.coordinator.full_name if self.coordinator else None,
            "venue":            self.venue,
            "start_date":       self.start_date.isoformat(),
            "end_date":         self.end_date.isoformat(),
            "description":      self.description,
        }


# ─── OD REQUESTS ──────────────────────────────────────────────────────────────
class ODRequest(db.Model):
    __tablename__ = "od_requests"

    request_id   = db.Column(db.String(36),  primary_key=True, default=gen_uuid)
    student_id   = db.Column(db.String(36),  db.ForeignKey("users.user_id"),
                             nullable=False)
    event_id     = db.Column(db.String(36),  db.ForeignKey("events.event_id"),
                             nullable=True)
    event_name   = db.Column(db.String(200), nullable=False)
    organiser    = db.Column(db.String(200), nullable=False)
    venue        = db.Column(db.String(200), nullable=False, default="")
    start_date   = db.Column(db.Date,        nullable=False)
    end_date     = db.Column(db.Date,        nullable=False)
    start_time   = db.Column(db.Time,        nullable=False)
    end_time     = db.Column(db.Time,        nullable=False)
    reason       = db.Column(db.Text,        nullable=False)
    attachment_name   = db.Column(db.String(255), nullable=True)
    attachment_mime   = db.Column(db.String(100), nullable=True)
    attachment_base64 = db.Column(db.Text,        nullable=True)
    status       = db.Column(db.String(25),  nullable=False, default="PENDING")
    submitted_at = db.Column(db.DateTime,    default=datetime.utcnow)

    student          = db.relationship("User", foreign_keys=[student_id])
    event            = db.relationship("Event", foreign_keys=[event_id])
    approval_records = db.relationship("ApprovalRecord", backref="od_request",
                                       lazy=True,
                                       order_by="ApprovalRecord.acted_at")

    def to_dict(self, include_approvals=False):
        d = {
            "request_id":      self.request_id,
            "student_id":      self.student_id,
            "student_name":    self.student.full_name if self.student else None,
            "student_section": (self.student.student_profile.section
                                if self.student and self.student.student_profile
                                else None),
            "event_id":        self.event_id,
            "event_name":      self.event_name,
            "organiser":       self.organiser,
            "venue":           self.venue,
            "start_date":      self.start_date.isoformat(),
            "end_date":        self.end_date.isoformat(),
            "start_time":      self.start_time.strftime("%H:%M"),
            "end_time":        self.end_time.strftime("%H:%M"),
            "reason":          self.reason,
            "attachment_name": self.attachment_name,
            "attachment_mime": self.attachment_mime,
            "attachment_base64": self.attachment_base64,
            "status":          self.status,
            "submitted_at":    self.submitted_at.isoformat(),
        }
        if include_approvals:
            d["approval_history"] = [r.to_dict() for r in self.approval_records]
        return d


# ─── APPROVAL RECORDS ─────────────────────────────────────────────────────────
class ApprovalRecord(db.Model):
    __tablename__ = "approval_records"

    record_id   = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    request_id  = db.Column(db.String(36), db.ForeignKey("od_requests.request_id"),
                            nullable=False)
    approver_id = db.Column(db.String(36), db.ForeignKey("users.user_id"),
                            nullable=False)
    stage       = db.Column(db.String(20), nullable=False)   # MENTOR | EC | HOD
    action      = db.Column(db.String(10), nullable=False)   # APPROVED | REJECTED
    comment     = db.Column(db.Text,       nullable=True)
    reason      = db.Column(db.Text,       nullable=True)
    acted_at    = db.Column(db.DateTime,   default=datetime.utcnow)

    approver = db.relationship("User", foreign_keys=[approver_id])

    def to_dict(self):
        return {
            "record_id":    self.record_id,
            "approver_name":self.approver.full_name if self.approver else None,
            "stage":        self.stage,
            "action":       self.action,
            "comment":      self.comment,
            "reason":       self.reason,
            "acted_at":     self.acted_at.isoformat(),
        }


# ─── OD SESSIONS ──────────────────────────────────────────────────────────────
class ODSession(db.Model):
    __tablename__ = "od_sessions"

    session_id        = db.Column(db.String(36),  primary_key=True, default=gen_uuid)
    student_unique_id = db.Column(db.String(25),  nullable=False, index=True)
    request_id        = db.Column(db.String(36),  db.ForeignKey("od_requests.request_id"),
                                  nullable=False)
    event_name        = db.Column(db.String(200), nullable=False)
    start_datetime    = db.Column(db.DateTime,    nullable=False)
    end_datetime      = db.Column(db.DateTime,    nullable=False)
    approved_by_name  = db.Column(db.String(150), nullable=False)
    is_active         = db.Column(db.Boolean,     default=True)
    created_at        = db.Column(db.DateTime,    default=datetime.utcnow)

    def to_dict(self):
        return {
            "session_id":        self.session_id,
            "student_unique_id": self.student_unique_id,
            "event_name":        self.event_name,
            "start_datetime":    self.start_datetime.isoformat(),
            "end_datetime":      self.end_datetime.isoformat(),
            "approved_by_name":  self.approved_by_name,
            "is_active":         self.is_active,
        }


# ─── AUDIT LOG ────────────────────────────────────────────────────────────────
class AuditLog(db.Model):
    __tablename__ = "audit_log"

    log_id     = db.Column(db.String(36), primary_key=True, default=gen_uuid)
    request_id = db.Column(db.String(36), db.ForeignKey("od_requests.request_id"),
                           nullable=True)
    actor_id   = db.Column(db.String(36), db.ForeignKey("users.user_id"),
                           nullable=False)
    action     = db.Column(db.String(50), nullable=False)
    meta       = db.Column(db.JSON,       default=dict)
    logged_at  = db.Column(db.DateTime,   default=datetime.utcnow)

    def to_dict(self):
        return {
            "log_id":     self.log_id,
            "request_id": self.request_id,
            "actor_id":   self.actor_id,
            "action":     self.action,
            "meta":       self.meta,
            "logged_at":  self.logged_at.isoformat(),
        }
