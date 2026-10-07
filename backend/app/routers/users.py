from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..dependencies import get_db
from ..models import User
from ..schemas import UserCreate, UserOut
from ..security import hash_pin

router = APIRouter(prefix="/users", tags=["users"])


@router.get("", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db)):
    return db.scalars(select(User).order_by(User.display_name)).all()


@router.post("", response_model=UserOut, status_code=201)
def create_user(body: UserCreate, db: Session = Depends(get_db)):
    taken = db.scalar(
        select(User.id).where(func.lower(User.display_name) == body.display_name.lower())
    )
    if taken:
        raise HTTPException(409, "That name is already taken")
    user = User(display_name=body.display_name, pin_hash=hash_pin(body.pin))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "That name is already taken")
    db.refresh(user)
    return user