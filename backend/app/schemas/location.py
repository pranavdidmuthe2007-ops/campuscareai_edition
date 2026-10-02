from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    location_code: str = Field(..., min_length=2, max_length=100)
    location_name: str = Field(..., min_length=2, max_length=200)
    building: Optional[str] = None
    floor: Optional[str] = None
    qr_code: Optional[str] = None


class LocationResponse(BaseModel):
    id: int
    location_code: str
    location_name: str
    building: Optional[str] = None
    floor: Optional[str] = None
    qr_code: Optional[str] = None

    class Config:
        from_attributes = True
