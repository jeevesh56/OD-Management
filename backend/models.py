from datetime import datetime as dt

from sqlalchemy import Boolean, Column, DateTime, String, Text

from database import Base


class ODRequest(Base):
    __tablename__ = "od_requests"

    id = Column(String, primary_key=True, index=True)
    event_name = Column(String, nullable=False, index=True)
    datetime = Column(String, nullable=False)
    venue = Column(String, nullable=False)
    organizer = Column(String, nullable=False)
    reason = Column(Text, nullable=False)
    file_url = Column(String, nullable=True)

    status = Column(String, nullable=False, default="Pending", index=True)
    mentor_approved = Column(Boolean, nullable=False, default=False)
    hod_approved = Column(Boolean, nullable=False, default=False)
    principal_approved = Column(Boolean, nullable=False, default=False)
    rejection_reason = Column(Text, nullable=False, default="")

    created_at = Column(DateTime, nullable=False, default=dt.utcnow)
    updated_at = Column(DateTime, nullable=False, default=dt.utcnow, onupdate=dt.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "event_name": self.event_name,
            "datetime": self.datetime,
            "venue": self.venue,
            "organizer": self.organizer,
            "reason": self.reason,
            "file_url": self.file_url or "",
            "status": self.status,
            "mentor_approved": self.mentor_approved,
            "hod_approved": self.hod_approved,
            "principal_approved": self.principal_approved,
            "rejection_reason": self.rejection_reason or "",
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
