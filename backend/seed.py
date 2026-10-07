"""Development-only seed script. Refuses to run when APP_ENV=production.

Usage (from backend/):  python seed.py
"""
import os
import sys

from sqlalchemy import select

from app.database import SessionLocal
from app.models import User
from app.security import hash_pin

# DEVELOPMENT-ONLY CREDENTIALS. Never use these in production.
DEV_USERS = {"Alice": "1234", "Bob": "2345", "John": "3456", "Sarah": "4567"}


def main() -> None:
    if os.environ.get("APP_ENV", "development").lower() == "production":
        sys.exit("Refusing to seed development users in production.")

    with SessionLocal() as db:
        for name, pin in DEV_USERS.items():
            if db.scalar(select(User).where(User.display_name == name)):
                print(f"exists:  {name}")
                continue
            db.add(User(display_name=name, pin_hash=hash_pin(pin)))
            print(f"created: {name} (dev PIN {pin})")
        db.commit()


if __name__ == "__main__":
    main()
