from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.complaint import Complaint
from app.models.complaint_history import ComplaintHistory
from app.models.location import Location
from app.models.staff import Staff
from app.models.user import User
from app.schemas.complaint import ComplaintAssign, ComplaintPriorityUpdate, ComplaintStatusUpdate
from app.services.auth_service import get_current_user, require_roles
from app.services.notification_service import create_notification

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/complaints")
async def list_admin_complaints(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("admin")),
):
    return db.query(Complaint).order_by(Complaint.created_at.desc()).all()


@router.put("/complaints/{complaint_id}/assign")
async def assign_staff_to_complaint(
    complaint_id: int,
    payload: ComplaintAssign,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("admin")),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    complaint.assigned_staff_id = payload.staff_id
    complaint.status = "Assigned"
    complaint.updated_at = complaint.updated_at
    db.add(ComplaintHistory(
        complaint_id=complaint.id,
        old_status=complaint.status,
        new_status="Assigned",
        changed_by=current_user.id,
        note="Assigned by admin",
    ))
    db.commit()
    return {"message": "Complaint assigned successfully"}


@router.put("/complaints/{complaint_id}/status")
async def update_admin_status(
    complaint_id: int,
    payload: ComplaintStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("admin")),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    status_value = payload.status.strip()
    allowed = ["Reported", "Assigned", "In Progress", "Resolved", "Rejected", "Closed"]
    if status_value not in allowed:
        raise HTTPException(status_code=400, detail="Invalid complaint status")

    old_status = complaint.status
    complaint.status = status_value
    if status_value == "Resolved":
        complaint.resolved_at = complaint.updated_at
    db.add(ComplaintHistory(
        complaint_id=complaint.id,
        old_status=old_status,
        new_status=status_value,
        changed_by=current_user.id,
        note=payload.note or "Updated by admin",
    ))
    db.commit()
    return {"message": "Complaint status updated"}


@router.put("/complaints/{complaint_id}/priority")
async def update_admin_priority(
    complaint_id: int,
    payload: ComplaintPriorityUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("admin")),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    complaint.priority = payload.priority
    db.commit()
    return {"message": "Complaint priority updated"}


@router.get("/dashboard")
async def admin_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles("admin")),
):
    complaints = db.query(Complaint).all()
    total = len(complaints)
    new_complaints = sum(1 for c in complaints if c.status == "Reported")
    assigned = sum(1 for c in complaints if c.status == "Assigned")
    in_progress = sum(1 for c in complaints if c.status == "In Progress")
    resolved = sum(1 for c in complaints if c.status == "Resolved")
    high_priority = sum(1 for c in complaints if c.priority == "High" or c.priority == "Emergency")

    by_category = {}
    by_status = {}
    by_location = {}

    for c in complaints:
        by_category[c.category] = by_category.get(c.category, 0) + 1
        by_status[c.status] = by_status.get(c.status, 0) + 1
        loc_name = c.location.location_name if c.location else "Unknown"
        by_location[loc_name] = by_location.get(loc_name, 0) + 1

    return {
        "summary": {
            "total_complaints": total,
            "new_complaints": new_complaints,
            "assigned": assigned,
            "in_progress": in_progress,
            "resolved": resolved,
            "high_priority": high_priority,
        },
        "complaints_by_category": by_category,
        "complaints_by_status": by_status,
        "complaints_by_location": by_location,
        "recent_complaints": complaints[:10],
    }
