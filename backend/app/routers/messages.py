from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..dependencies import get_current_user, get_db
from ..models import User
from ..schemas import MessageCreate, MessageOut, ThreadOut, UserOut
from ..services import message_service

router = APIRouter(prefix="/messages", tags=["messages"])


@router.get("/{user_id}", response_model=ThreadOut)
def get_messages(
    user_id: int,
    direction: Literal["sent", "received"] = Query("sent"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    other, can_write, messages = message_service.get_thread(db, user, user_id, direction)
    return ThreadOut(
        user=UserOut.model_validate(other),
        direction=direction,
        can_write=can_write,
        messages=messages,
    )


@router.post("", response_model=MessageOut, status_code=201)
def post_message(
    body: MessageCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # No sender field in the body: sender_id is always the authenticated user.
    return message_service.send_message(db, user, body.recipient_id, body.content)


# Intentionally no PUT/PATCH/DELETE endpoints: messages cannot be edited or deleted in v1.
