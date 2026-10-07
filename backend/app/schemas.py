import re
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, field_validator

PIN_RE = re.compile(r"^\d{4}$")
MAX_MESSAGE_LENGTH = 2000


def _check_pin(value: str) -> str:
    if not PIN_RE.fullmatch(value):
        raise ValueError("PIN must be exactly 4 digits")
    return value


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    display_name: str


class LoginRequest(BaseModel):
    user_id: int
    pin: str

    _v = field_validator("pin")(_check_pin)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class ChangePinRequest(BaseModel):
    current_pin: str
    new_pin: str

    _v = field_validator("current_pin", "new_pin")(_check_pin)


class MessageCreate(BaseModel):
    recipient_id: int
    content: str

    @field_validator("content")
    @classmethod
    def _content(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Message cannot be empty")
        if len(v) > MAX_MESSAGE_LENGTH:
            raise ValueError(f"Message cannot exceed {MAX_MESSAGE_LENGTH} characters")
        return v


class MessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    sender_id: int
    recipient_id: int
    content: str
    created_at: datetime
    is_read: bool


class ThreadOut(BaseModel):
    user: UserOut
    direction: Literal["sent", "received"]
    can_write: bool
    messages: list[MessageOut]


class ChatOut(BaseModel):
    user_id: int
    display_name: str
    sent_count: int
    received_count: int
    unread_count: int
    last_sent_preview: str | None
    last_received_preview: str | None
