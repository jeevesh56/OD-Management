"""
Run this ONCE after creating the database to populate test users.
Usage: python seed.py
"""
from run import app
from app import db, bcrypt
from app.models import User, StudentProfile

PASS = "Test@1234"   # same password for all test accounts

def seed():
    with app.app_context():
        db.create_all()

        if User.query.filter_by(email="hod@rit.edu").first():
            print("Already seeded — skipping.")
            return

        # ── HoD ──────────────────────────────────────────────────────
        hod = User(
            email="hod@rit.edu",
            password=bcrypt.generate_password_hash(PASS).decode(),
            role="hod",
            full_name="Dr. R. Kumar",
            phone="9876543210",
            dept="CSE",
        )

        # ── Mentor ───────────────────────────────────────────────────
        mentor = User(
            email="mentor@rit.edu",
            password=bcrypt.generate_password_hash(PASS).decode(),
            role="mentor",
            full_name="Dr. Ramesh K.",
            phone="9876543211",
            dept="CSE",
        )

        # ── Event Coordinator ─────────────────────────────────────────
        ec = User(
            email="ec@rit.edu",
            password=bcrypt.generate_password_hash(PASS).decode(),
            role="event_coordinator",
            full_name="Prof. Anita Nair",
            phone="9876543212",
            dept="CSE",
        )

        # ── Verifier ─────────────────────────────────────────────────
        verifier = User(
            email="verifier@rit.edu",
            password=bcrypt.generate_password_hash(PASS).decode(),
            role="verifier",
            full_name="Gate Security Staff",
            phone="9876543213",
            dept="ADMIN",
        )

        db.session.add_all([hod, mentor, ec, verifier])
        db.session.flush()

        # ── Student ──────────────────────────────────────────────────
        student = User(
            email="student@rit.edu",
            password=bcrypt.generate_password_hash(PASS).decode(),
            role="student",
            full_name="Arjun Kumar",
            phone="9876543214",
            dept="CSE",
        )
        db.session.add(student)
        db.session.flush()

        profile = StudentProfile(
            student_id=student.user_id,
            unique_id_number="2117240020160",   # QR value on printed ID card
            roll_number="21114101001",
            section="CS-A",
            semester=7,
            mentor_id=mentor.user_id,
            hod_id=hod.user_id,
            batch_year=2021,
            attendance_pct=78.50,
        )
        db.session.add(profile)
        db.session.commit()

        print("✅ Seed complete. Test accounts:")
        print(f"   Student          : student@rit.edu  / {PASS}")
        print(f"   Mentor           : mentor@rit.edu   / {PASS}")
        print(f"   Event Coordinator: ec@rit.edu       / {PASS}")
        print(f"   HoD              : hod@rit.edu      / {PASS}")
        print(f"   Verifier         : verifier@rit.edu / {PASS}")
        print(f"\n   Student unique ID (scan this QR): 2117240020160")

if __name__ == "__main__":
    seed()
