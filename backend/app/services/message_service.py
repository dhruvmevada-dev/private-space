from fastapi import HTTPException
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from ..models import Message, User
from ..schemas import ChatOut

THREAD_LIMIT = 500
PREVIEW_LENGTH = 80


def _preview(text: str | None) -> str | None:
    if text is None:
        return None
    text = " ".join(text.split())
    return text if len(text) <= PREVIEW_LENGTH else text[: PREVIEW_LENGTH - 1] + "…"


def send_message(db: Session, sender: User, recipient_id: int, content: str) -> Message:
    # sender is ALWAYS the authenticated user; the client cannot choose it.
    if recipient_id == sender.id:
        raise HTTPException(400, "You cannot write to yourself")
    if db.get(User, recipient_id) is None:
        raise HTTPException(404, "User not found")
    msg = Message(sender_id=sender.id, recipient_id=recipient_id, content=content)
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


def get_thread(db: Session, me: User, other_id: int, direction: str):
    """
    direction="sent":     messages I wrote to `other`   -> I may write more (can_write=True)
    direction="received": messages `other` wrote to me  -> read-only (can_write=False)
    """
    other = db.get(User, other_id)
    if other is None:
        raise HTTPException(404, "User not found")
    if other.id == me.id:
        raise HTTPException(400, "You cannot open a space with yourself")

    if direction == "sent":
        sender_id, recipient_id, can_write = me.id, other.id, True
    else:
        sender_id, recipient_id, can_write = other.id, me.id, False

    rows = db.scalars(
        select(Message)
        .where(Message.sender_id == sender_id, Message.recipient_id == recipient_id)
        .order_by(Message.created_at.desc(), Message.id.desc())
        .limit(THREAD_LIMIT)
    ).all()
    messages = list(reversed(rows))

    if direction == "received" and any(not m.is_read for m in messages):
        # Return the pre-update is_read values so the client can show what was new.
        snapshot = [
            {"id": m.id, "sender_id": m.sender_id, "recipient_id": m.recipient_id,
             "content": m.content, "created_at": m.created_at, "is_read": m.is_read}
            for m in messages
        ]
        db.execute(
            update(Message)
            .where(Message.sender_id == other.id, Message.recipient_id == me.id,
                   Message.is_read.is_(False))
            .values(is_read=True, updated_at=Message.updated_at)
        )
        db.commit()
        messages = snapshot

    return other, can_write, messages


def list_chats(db: Session, me: User) -> list[ChatOut]:
    people = db.scalars(select(User).where(User.id != me.id).order_by(User.display_name)).all()
    chats: list[ChatOut] = []
    for p in people:
        sent = (Message.sender_id == me.id, Message.recipient_id == p.id)
        recv = (Message.sender_id == p.id, Message.recipient_id == me.id)
        sent_count = db.scalar(select(func.count()).select_from(Message).where(*sent)) or 0
        recv_count = db.scalar(select(func.count()).select_from(Message).where(*recv)) or 0
        unread = db.scalar(
            select(func.count()).select_from(Message).where(*recv, Message.is_read.is_(False))
        ) or 0
        order = (Message.created_at.desc(), Message.id.desc())
        last_sent = db.scalar(select(Message.content).where(*sent).order_by(*order).limit(1))
        last_recv = db.scalar(select(Message.content).where(*recv).order_by(*order).limit(1))
        chats.append(ChatOut(
            user_id=p.id, display_name=p.display_name,
            sent_count=sent_count, received_count=recv_count, unread_count=unread,
            last_sent_preview=_preview(last_sent), last_received_preview=_preview(last_recv),
        ))
    return chats
