from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, create_refresh_token,
    jwt_required, get_jwt_identity
)
from app import db, bcrypt
from app.models import User, StudentProfile
from app.services.helpers import current_user_id

auth_bp = Blueprint("auth", __name__)

VALID_ROLES = ["student", "mentor", "event_coordinator", "hod", "verifier"]


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}

    required = ["email", "password", "role", "full_name", "phone", "dept"]
    missing  = [f for f in required if not data.get(f)]
    if missing:
        return jsonify({"error": f"Missing fields: {missing}"}), 400

    if data["role"] not in VALID_ROLES:
        return jsonify({"error": f"role must be one of {VALID_ROLES}"}), 400

    if User.query.filter_by(email=data["email"].lower()).first():
        return jsonify({"error": "Email already registered"}), 409

    hashed = bcrypt.generate_password_hash(data["password"]).decode("utf-8")
    user = User(
        email=data["email"].lower(),
        password=hashed,
        role=data["role"],
        full_name=data["full_name"],
        phone=data["phone"],
        dept=data["dept"],
    )
    db.session.add(user)
    db.session.flush()

    if data["role"] == "student":
        sp = data.get("student_profile", {})
        sp_required = ["unique_id_number", "roll_number", "section",
                       "semester", "mentor_id", "hod_id", "batch_year"]
        sp_missing = [f for f in sp_required if not sp.get(f)]
        if sp_missing:
            db.session.rollback()
            return jsonify({"error": f"student_profile missing: {sp_missing}"}), 400

        profile = StudentProfile(
            student_id=user.user_id,
            unique_id_number=sp["unique_id_number"],
            roll_number=sp["roll_number"],
            section=sp["section"],
            semester=int(sp["semester"]),
            mentor_id=sp["mentor_id"],
            hod_id=sp["hod_id"],
            batch_year=int(sp["batch_year"]),
            attendance_pct=float(sp.get("attendance_pct", 0)),
        )
        db.session.add(profile)

    db.session.commit()
    return jsonify({"message": "Registered", "user_id": user.user_id}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    data     = request.get_json() or {}
    email    = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "email and password required"}), 400

    user = User.query.filter_by(email=email, is_active=True).first()
    if not user or not bcrypt.check_password_hash(user.password, password):
        return jsonify({"error": "Invalid credentials"}), 401

    identity      = {"user_id": user.user_id, "role": user.role}
    access_token  = create_access_token(identity=identity)
    refresh_token = create_refresh_token(identity=identity)

    resp = {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "user":          user.to_dict(),
    }
    if user.role == "student" and user.student_profile:
        resp["student_profile"] = user.student_profile.to_dict()

    return jsonify(resp), 200


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity     = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify({"access_token": access_token}), 200


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    user = User.query.get(current_user_id())
    if not user:
        return jsonify({"error": "Not found"}), 404
    resp = user.to_dict()
    if user.role == "student" and user.student_profile:
        resp["student_profile"] = user.student_profile.to_dict()
    return jsonify(resp), 200


@auth_bp.route("/update-fcm-token", methods=["POST"])
@jwt_required()
def update_fcm():
    token = (request.get_json() or {}).get("fcm_token")
    if not token:
        return jsonify({"error": "fcm_token required"}), 400
    user = User.query.get(current_user_id())
    if user:
        user.fcm_token = token
        db.session.commit()
    return jsonify({"message": "Updated"}), 200
