from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import auth, chats, messages, users

app = FastAPI(title="Private Space API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Native Android app; tighten if you add a web client.
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(chats.router)
app.include_router(messages.router)


@app.get("/health")
def health():
    return {"status": "ok"}
