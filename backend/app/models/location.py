from __future__ import annotations

from sqlalchemy import Column, Integer, String

from app.database import Base


class Location(Base):
    __tablename__ = "locations"

    id = Column(Integer, primary_key=True, index=True)
    location_code = Column(String(100), unique=True, index=True, nullable=False)
    location_name = Column(String(200), nullable=False)
    building = Column(String(150), nullable=True)
    floor = Column(String(50), nullable=True)
    qr_code = Column(String(255), nullable=True)
