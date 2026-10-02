from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: int
    user_id: int
    complaint_id: int | None = None
    title: str
    message: str
    is_read: bool = False
    created_at: datetime

    class Config:
        from_attributes = True
