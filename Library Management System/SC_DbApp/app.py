import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

from secrets_loader import get_db_credentials

db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__, template_folder='templates')

    # Load credentials from AWS Secrets Manager
    creds = get_db_credentials()

    DB_USER = creds["username"]
    DB_PASS = creds["password"]

    # Static (infra-defined)
    DB_HOST = os.getenv("DB_HOST")        # RDS endpoint
    DB_NAME = os.getenv("DB_NAME", "appdb")
    DB_PORT = os.getenv("DB_PORT", "5432")

    # Build PostgreSQL URI
    db_uri = (
        f"postgresql+psycopg2://"
        f"{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    app.config["SQLALCHEMY_DATABASE_URI"] = db_uri
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-secret-key")

    # Init extensions
    db.init_app(app)
    migrate.init_app(app, db)

    # Register routes
    from routes import register_routes
    register_routes(app, db)

    return app
