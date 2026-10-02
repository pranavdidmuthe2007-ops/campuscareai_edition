from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ComplaintCreate(BaseModel):
    category: str = Field(..., min_length=2, max_length=100)
    description: str = Field(..., min_length=10, max_length=5000)
    location_id: Optional[int] = None
    location_name: Optional[str] = None
    priority: str = "Medium"
    ai_category: Optional[str] = None
    ai_priority: Optional[str] = None
    ai_confidence: Optional[str] = None
    image_path: Optional[str] = None


class ComplaintUpdate(BaseModel):
    category: Optional[str] = None
    description: Optional[str] = None
    location_id: Optional[int] = None
    priority: Optional[str] = None
    ai_category: Optional[str] = None
    ai_priority: Optional[str] = None
    ai_confidence: Optional[str] = None
    status: Optional[str] = None
    assigned_staff_id: Optional[int] = None


class ComplaintStatusUpdate(BaseModel):
    status: str = Field(..., min_length=2, max_length=50)
    note: Optional[str] = None


class ComplaintPriorityUpdate(BaseModel):
    priority: str = Field(..., min_length=2, max_length=50)


class ComplaintAssign(BaseModel):
    staff_id: int


class ComplaintResponse(BaseModel):
    id: int
    complaint_number: str
    student_id: int
    category: str
    description: str
    location_id: Optional[int] = None
    location_name: Optional[str] = None
    priority: str
    ai_category: Optional[str] = None
    ai_priority: Optional[str] = None
    ai_confidence: Optional[str] = None
    image_path: Optional[str] = None
    status: str
    assigned_staff_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ComplaintHistoryResponse(BaseModel):
    id: int
    complaint_id: int
    old_status: Optional[str] = None
    new_status: str
    changed_by: Optional[int] = None
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
