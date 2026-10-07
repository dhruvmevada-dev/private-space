from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..models import User
from ..security import hash_pin, verify_pin

MAX_FAILED_ATTEMPTS = 5
LOCK_MINUTES = 5


def _now() -> datetime:
    return datetime.now(timezone.utc)


def check_pin(
    db: Session,
    user: User,
    pin: str,
    wrong_status: int = 401,
    wrong_message: str = "Incorrect PIN",
) -> None:
    """Verify a PIN with brute-force lockout (a 4-digit PIN has only 10,000 combinations)."""
    now = _now()
    locked = user.locked_until
    if locked is not None:
        if locked.tzinfo is None:
            locked = locked.replace(tzinfo=timezone.utc)
        if locked > now:
            raise HTTPException(429, "Too many attempts. Please try again in a few minutes.")

    if not verify_pin(pin, user.pin_hash):
        user.failed_attempts += 1
        if user.failed_attempts >= MAX_FAILED_ATTEMPTS:
            user.locked_until = now + timedelta(minutes=LOCK_MINUTES)
            user.failed_attempts = 0
        db.commit()
        raise HTTPException(wrong_status, wrong_message)

    if user.failed_attempts or user.locked_until:
        user.failed_attempts = 0
        user.locked_until = None
        db.commit()


def login(db: Session, user_id: int, pin: str) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(404, "User not found")
    check_pin(db, user, pin)
    return user


def change_pin(db: Session, user: User, current_pin: str, new_pin: str) -> None:
    # 400 (not 401) so the client does not mistake a wrong current PIN for an expired session.
    check_pin(db, user, current_pin, 400, "Current PIN is incorrect")
    if current_pin == new_pin:
        raise HTTPException(400, "New PIN must be different from the current PIN")
    user.pin_hash = hash_pin(new_pin)
    db.commit()
