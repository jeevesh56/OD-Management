import os
import shutil
import uuid

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from database import Base, SessionLocal, engine, get_db
from models import ODRequest

app = FastAPI()

Base.metadata.create_all(bind=engine)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

app.mount("/uploads", StaticFiles(directory=UPLOAD_FOLDER), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ODRequestCreate(BaseModel):
    event_name: str
    datetime: str
    venue: str
    organizer: str
    reason: str
    file_url: str = ""

    @field_validator("event_name", "datetime", "venue", "organizer", "reason")
    @classmethod
    def not_blank(cls, value: str) -> str:
        clean = value.strip()
        if not clean:
            raise ValueError("Field is required")
        return clean


class RejectPayload(BaseModel):
    reason: str = Field(default="")


class ApprovalResponse(BaseModel):
    message: str
    data: dict


class BulkApprovePayload(BaseModel):
    ids: list[str] = Field(default_factory=list)


def _serialize(request: ODRequest) -> dict:
    return request.to_dict()


def _query_requests(db: Session):
    return db.query(ODRequest).order_by(ODRequest.created_at.desc()).all()


def _get_request(db: Session, request_id: str) -> ODRequest | None:
    return db.query(ODRequest).filter(ODRequest.id == request_id).first()


@app.post("/upload")
def upload_file(request: Request, file: UploadFile = File(...)):
    safe_name = os.path.basename(file.filename)
    unique_name = f"{uuid.uuid4()}_{safe_name}"
    file_path = os.path.join(UPLOAD_FOLDER, unique_name)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return {"file_url": str(request.base_url).rstrip("/") + f"/uploads/{unique_name}"}


@app.post("/od-request")
def create_request(data: ODRequestCreate, db: Session = Depends(get_db)):
    new_request = ODRequest(
        id=str(uuid.uuid4()),
        event_name=data.event_name.strip(),
        datetime=data.datetime.strip(),
        venue=data.venue.strip(),
        organizer=data.organizer.strip(),
        reason=data.reason.strip(),
        file_url=data.file_url.strip(),
        status="Pending",
        mentor_approved=False,
        hod_approved=False,
        principal_approved=False,
        rejection_reason="",
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return {
        "message": "Request saved successfully",
        "id": new_request.id,
    }


@app.get("/test")
def test():
    return {"status": "Backend working"}


@app.get("/od-requests")
def get_requests(db: Session = Depends(get_db)):
    return [_serialize(item) for item in _query_requests(db)]


@app.get("/od-requests/{role}")
def get_requests_by_role(role: str, db: Session = Depends(get_db)):
    normalized_role = role.strip().lower()
    if normalized_role not in {"mentor", "hod", "principal", "student"}:
        raise HTTPException(status_code=400, detail="Role must be student, mentor, hod, or principal")

    items = _query_requests(db)
    if normalized_role == "student":
        return [_serialize(r) for r in items]
    if normalized_role == "mentor":
        return [_serialize(r) for r in items if not r.mentor_approved and r.status != "Rejected"]
    if normalized_role == "hod":
        return [
            _serialize(r)
            for r in items
            if r.mentor_approved and not r.hod_approved and r.status != "Rejected"
        ]
    return [
        _serialize(r)
        for r in items
        if r.hod_approved and not r.principal_approved and r.status != "Rejected"
    ]


def _apply_role_approval(request: ODRequest, role: str) -> None:
    normalized_role = role.strip().lower()
    if normalized_role == "mentor":
        request.mentor_approved = True
    elif normalized_role == "hod":
        if not request.mentor_approved:
            raise HTTPException(status_code=409, detail="Mentor approval required before HoD")
        request.hod_approved = True
    elif normalized_role == "principal":
        if not request.hod_approved:
            raise HTTPException(status_code=409, detail="HoD approval required before Principal")
        request.principal_approved = True
    else:
        raise HTTPException(status_code=400, detail="Role must be mentor, hod, or principal")

    if request.mentor_approved and request.hod_approved and request.principal_approved:
        request.status = "Approved"


@app.put("/od-request/{request_id}/approve")
def approve(request_id: str, db: Session = Depends(get_db)):
    # Backward-compatible endpoint: infer next role from current approval flags.
    request = _get_request(db, request_id)
    if request is not None:
        if request.status == "Rejected":
            raise HTTPException(status_code=409, detail="Rejected request cannot be approved")
        if not request.mentor_approved:
            _apply_role_approval(request, "mentor")
        elif not request.hod_approved:
            _apply_role_approval(request, "hod")
        elif not request.principal_approved:
            _apply_role_approval(request, "principal")
        else:
            return ApprovalResponse(message="Already completed", data=_serialize(request))
        db.commit()
        db.refresh(request)
        return ApprovalResponse(message="Approved", data=_serialize(request))
    raise HTTPException(status_code=404, detail="Request not found")


@app.put("/od-request/{request_id}/approve/{role}")
def approve_by_role(request_id: str, role: str, db: Session = Depends(get_db)):
    request = _get_request(db, request_id)
    if request is not None:
        if request.status == "Rejected":
            raise HTTPException(status_code=409, detail="Rejected request cannot be approved")
        _apply_role_approval(request, role)
        db.commit()
        db.refresh(request)
        return {"message": "Approved", "data": _serialize(request)}
    raise HTTPException(status_code=404, detail="Request not found")


@app.put("/od-request/{request_id}/reject")
def reject(request_id: str, payload: RejectPayload | None = None, db: Session = Depends(get_db)):
    request = _get_request(db, request_id)
    if request is not None:
        request.status = "Rejected"
        request.rejection_reason = payload.reason.strip() if payload else ""
        db.commit()
        db.refresh(request)
        return {"message": "Rejected", "data": _serialize(request)}
    raise HTTPException(status_code=404, detail="Request not found")


@app.put("/bulk-approve")
def bulk_approve(payload: BulkApprovePayload, db: Session = Depends(get_db)):
    if not payload.ids:
        return {"message": "Bulk approved", "count": 0}

    count = 0
    for request in db.query(ODRequest).filter(ODRequest.id.in_(payload.ids)):
        if request.status == "Rejected":
            continue
        request.principal_approved = True
        if request.mentor_approved and request.hod_approved:
            request.status = "Approved"
        count += 1

    db.commit()
    return {"message": "Bulk approved", "count": count}


@app.get("/debug")
def debug(db: Session = Depends(get_db)):
    items = _query_requests(db)
    return {
        "total_requests": len(items),
        "data": [_serialize(item) for item in items],
    }
