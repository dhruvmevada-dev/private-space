"""Smoke tests. Run from backend/:  DATABASE_URL=sqlite:///test.db JWT_SECRET=x pytest -q"""
from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.main import app
from app.models import User
from app.security import hash_pin

client = TestClient(app)


def setup_module():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        for name, pin in [("Alice", "1234"), ("Bob", "2345")]:
            db.add(User(display_name=name, pin_hash=hash_pin(pin)))
        db.commit()


def login(uid, pin):
    r = client.post("/auth/login", json={"user_id": uid, "pin": pin})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_flow():
    assert client.post("/auth/login", json={"user_id": 1, "pin": "9999"}).status_code == 401
    assert client.post("/auth/login", json={"user_id": 1, "pin": "12"}).status_code == 422
    assert client.post("/auth/login", json={"user_id": 99, "pin": "1234"}).status_code == 404
    a, b = login(1, "1234"), login(2, "2345")

    assert client.get("/chats").status_code == 401
    assert client.post("/messages", json={"recipient_id": 2, "content": "  "}, headers=a).status_code == 422
    assert client.post("/messages", json={"recipient_id": 1, "content": "x"}, headers=a).status_code == 400
    r = client.post("/messages", json={"recipient_id": 2, "content": "hello Bob", "sender_id": 2}, headers=a)
    assert r.status_code == 201 and r.json()["sender_id"] == 1  # spoofed sender ignored

    t = client.get("/messages/2?direction=sent", headers=a).json()
    assert t["can_write"] is True and len(t["messages"]) == 1
    t = client.get("/messages/1?direction=received", headers=b).json()
    assert t["can_write"] is False and t["messages"][0]["content"] == "hello Bob"
    assert client.get("/messages/1?direction=sent", headers=b).json()["messages"] == []  # Bob wrote nothing

    chats = {c["display_name"]: c for c in client.get("/chats", headers=b).json()}
    assert chats["Alice"]["received_count"] == 1 and chats["Alice"]["unread_count"] == 0

    assert client.put("/auth/change-pin", json={"current_pin": "0000", "new_pin": "5555"}, headers=a).status_code == 400
    assert client.put("/auth/change-pin", json={"current_pin": "1234", "new_pin": "5555"}, headers=a).status_code == 204
    login(1, "5555")
    assert client.delete("/messages/1", headers=a).status_code == 405
