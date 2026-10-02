from __future__ import annotations

from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.database import Base


class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True, index=True)
    complaint_number = Column(String(50), unique=True, index=True, nullable=False)
    student_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    category = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    location_id = Column(Integer, ForeignKey("locations.id"), nullable=True, index=True)
    priority = Column(String(50), nullable=False, default="Medium")
    ai_category = Column(String(100), nullable=True)
    ai_priority = Column(String(50), nullable=True)
    ai_confidence = Column(String(20), nullable=True)
    image_path = Column(String(255), nullable=True)
    status = Column(String(50), nullable=False, default="Reported")
    assigned_staff_id = Column(Integer, ForeignKey("staff.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    resolved_at = Column(DateTime, nullable=True)

    student = relationship("User", foreign_keys=[student_id])
    assigned_staff = relationship("Staff", foreign_keys=[assigned_staff_id])
    location = relationship("Location")
