from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.complaint import Complaint
from app.models.complaint_history import ComplaintHistory
from app.models.staff import Staff
from app.models.user import User
from app.schemas.complaint import ComplaintStatusUpdate
from app.services.auth_service import require_roles

router = APIRouter(prefix="/staff", tags=["Staff"])


@router.get("/complaints")
async def list_staff_complaints(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("staff")),
):
    staff_profile = db.query(Staff).filter(Staff.user_id == current_user.id).first()
    if not staff_profile:
        raise HTTPException(status_code=404, detail="Staff profile not found")

    return db.query(Complaint).filter(Complaint.assigned_staff_id == staff_profile.id).order_by(Complaint.created_at.desc()).all()


@router.put("/complaints/{complaint_id}/status")
async def update_staff_status(
    complaint_id: int,
    payload: ComplaintStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("staff")),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    staff_profile = db.query(Staff).filter(Staff.user_id == current_user.id).first()
    if not staff_profile or complaint.assigned_staff_id != staff_profile.id:
        raise HTTPException(status_code=403, detail="This complaint is not assigned to you")

    status_value = payload.status.strip()
    valid_status = ["Assigned", "In Progress", "Resolved", "Closed"]
    if status_value not in valid_status:
        raise HTTPException(status_code=400, detail="Invalid status transition")

    old_status = complaint.status
    complaint.status = status_value
    if status_value == "Resolved":
        complaint.resolved_at = complaint.updated_at

    db.add(ComplaintHistory(
        complaint_id=complaint.id,
        old_status=old_status,
        new_status=status_value,
        changed_by=current_user.id,
        note=payload.note or "Updated by staff",
    ))
    db.commit()
    return {"message": "Complaint status updated"}


@router.post("/complaints/{complaint_id}/resolution")
async def add_resolution(
    complaint_id: int,
    resolution_note: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("staff")),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    staff_profile = db.query(Staff).filter(Staff.user_id == current_user.id).first()
    if not staff_profile or complaint.assigned_staff_id != staff_profile.id:
        raise HTTPException(status_code=403, detail="This complaint is not assigned to you")

    complaint.status = "Resolved"
    complaint.resolved_at = complaint.updated_at
    db.add(ComplaintHistory(
        complaint_id=complaint.id,
        old_status="In Progress",
        new_status="Resolved",
        changed_by=current_user.id,
        note=resolution_note,
    ))
    db.commit()
    return {"message": "Resolution note added"}
