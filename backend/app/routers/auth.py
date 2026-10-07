from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies import get_current_user, get_db
from ..models import User
from ..schemas import ChangePinRequest, LoginRequest, TokenOut, UserOut
from ..security import create_access_token
from ..services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenOut)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = auth_service.login(db, body.user_id, body.pin)
    return TokenOut(access_token=create_access_token(user.id), user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    """Used by the app on startup to validate a stored token."""
    return user


@router.put("/change-pin", status_code=204)
def change_pin(
    body: ChangePinRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    auth_service.change_pin(db, user, body.current_pin, body.new_pin)
