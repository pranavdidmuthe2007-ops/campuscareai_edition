from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import Base, engine
from app.models import *  # noqa: F401,F403
from app.routers import admin, ai, auth, complaints, locations, notifications, staff

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="CampusCare AI complaint management system",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

upload_dir = settings.upload_path
upload_dir.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")

app.include_router(auth.router)
app.include_router(complaints.router)
app.include_router(staff.router)
app.include_router(admin.router)
app.include_router(locations.router)
app.include_router(ai.router)
app.include_router(notifications.router)


@app.get("/")
async def health_check():
    return {
        "message": "CampusCare AI API is running",
        "app": settings.app_name,
        "environment": settings.app_env,
    }
