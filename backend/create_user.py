"""Create a real user (e.g. in production). Usage: python create_user.py "Name" 4821"""
import re
import sys

from app.database import SessionLocal
from app.models import User
from app.security import hash_pin

if len(sys.argv) != 3 or not re.fullmatch(r"\d{4}", sys.argv[2]):
    sys.exit('Usage: python create_user.py "Display Name" <4-digit-pin>')

with SessionLocal() as db:
    db.add(User(display_name=sys.argv[1].strip(), pin_hash=hash_pin(sys.argv[2])))
    db.commit()
    print(f"created: {sys.argv[1]}")
