from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_bcrypt import Bcrypt
from datetime import timedelta
import os
from dotenv import load_dotenv

load_dotenv()

db      = SQLAlchemy()
jwt     = JWTManager()
bcrypt  = Bcrypt()


def create_app():
    app = Flask(__name__)
    CORS(app)
    app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:5607@localhost:5432/od_management"
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["JWT_SECRET_KEY"]            = os.getenv("JWT_SECRET_KEY", "dev-secret")
    app.config["JWT_ACCESS_TOKEN_EXPIRES"]  = timedelta(hours=1)
    app.config["JWT_REFRESH_TOKEN_EXPIRES"] = timedelta(days=30)
    app.config["MAX_CONTENT_LENGTH"]        = 5 * 1024 * 1024

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    from app.routes.auth    import auth_bp
    from app.routes.student import student_bp
    from app.routes.mentor  import mentor_bp
    from app.routes.ec      import ec_bp
    from app.routes.hod     import hod_bp
    from app.routes.verify  import verify_bp
    from app.routes.events  import events_bp

    app.register_blueprint(auth_bp,    url_prefix="/api/auth")
    app.register_blueprint(student_bp, url_prefix="/api/student")
    app.register_blueprint(mentor_bp,  url_prefix="/api/mentor")
    app.register_blueprint(ec_bp,      url_prefix="/api/ec")
    app.register_blueprint(hod_bp,     url_prefix="/api/hod")
    app.register_blueprint(verify_bp,  url_prefix="/api/verify")
    app.register_blueprint(events_bp,  url_prefix="/api/events")

    @app.route("/health")
    def health():
        return {"status": "ok", "version": "1.0.0"}

    return app
