from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies import get_current_user, get_db
from ..models import User
from ..schemas import ChatOut
from ..services import message_service

router = APIRouter(prefix="/chats", tags=["chats"])


@router.get("", response_model=list[ChatOut])
def get_chats(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return message_service.list_chats(db, user)
