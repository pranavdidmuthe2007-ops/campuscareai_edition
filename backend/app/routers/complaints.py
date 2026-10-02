from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.complaint import Complaint
from app.models.complaint_history import ComplaintHistory
from app.models.location import Location
from app.models.staff import Staff
from app.models.user import User
from app.schemas.complaint import ComplaintCreate, ComplaintHistoryResponse, ComplaintResponse, ComplaintUpdate
from app.services.ai_service import analyze_complaint
from app.services.auth_service import get_current_user
from app.services.notification_service import create_notification
from app.config import settings

router = APIRouter(prefix="/complaints", tags=["Complaints"])


def save_uploaded_file(file: UploadFile) -> str:
    allowed = {"image/jpeg", "image/jpg", "image/png"}
    if file.content_type not in allowed:
        raise HTTPException(status_code=400, detail="Unsupported image type. Use JPG or PNG.")

    if file.size and file.size > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image is too large. Maximum size is 5 MB.")

    filename = f"{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S%f')}_{file.filename.replace(' ', '_')}"
    target_path = settings.upload_path / filename
    with target_path.open("wb") as buffer:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            buffer.write(chunk)
    return f"/uploads/{filename}"


@router.post("", response_model=ComplaintResponse, status_code=status.HTTP_201_CREATED)
async def create_complaint(
    category: str,
    description: str,
    location_id: Optional[int] = None,
    priority: str = "Medium",
    ai_category: Optional[str] = None,
    ai_priority: Optional[str] = None,
    ai_confidence: Optional[str] = None,
    file: UploadFile = File(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not category or not description:
        raise HTTPException(status_code=400, detail="Category and description are required")

    if file is not None:
        image_path = save_uploaded_file(file)
    else:
        image_path = None

    complaint = Complaint(
        complaint_number=f"CC{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}{current_user.id}",
        student_id=current_user.id,
        category=category,
        description=description,
        location_id=location_id,
        priority=priority,
        ai_category=ai_category,
        ai_priority=ai_priority,
        ai_confidence=ai_confidence,
        image_path=image_path,
        status="Reported",
    )

    db.add(complaint)
    db.commit()
    db.refresh(complaint)

    db.add(ComplaintHistory(
        complaint_id=complaint.id,
        old_status=None,
        new_status="Reported",
        changed_by=current_user.id,
        note="Complaint created",
    ))

    create_notification(
        db,
        user_id=current_user.id,
        complaint_id=complaint.id,
        title="Complaint Submitted",
        message=f"Your complaint #{complaint.complaint_number} has been submitted successfully.",
    )

    return complaint


@router.get("", response_model=list[ComplaintResponse])
async def list_complaints(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    complaints = db.query(Complaint).filter(Complaint.student_id == current_user.id).order_by(Complaint.created_at.desc()).all()
    return complaints


@router.get("/{complaint_id}/history", response_model=list[ComplaintHistoryResponse])
async def list_complaint_history(
    complaint_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    if current_user.role == "student" and complaint.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="You are not allowed to view this complaint")

    return (
        db.query(ComplaintHistory)
        .filter(ComplaintHistory.complaint_id == complaint_id)
        .order_by(ComplaintHistory.created_at.asc(), ComplaintHistory.id.asc())
        .all()
    )


@router.get("/{complaint_id}", response_model=ComplaintResponse)
async def get_complaint(complaint_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    if current_user.role == "student" and complaint.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="You are not allowed to view this complaint")
    return complaint


@router.put("/{complaint_id}")
async def update_complaint(
    complaint_id: int,
    payload: ComplaintUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    if current_user.role == "student" and complaint.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="You can only update your own complaints")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(complaint, field, value)

    complaint.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Complaint updated successfully"}


@router.delete("/{complaint_id}")
async def delete_complaint(complaint_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    if current_user.role == "student" and complaint.student_id != current_user.id:
        raise HTTPException(status_code=403, detail="You are not allowed to delete this complaint")

    db.delete(complaint)
    db.commit()
    return {"message": "Complaint deleted"}


@router.get("/student/complaints")
async def student_complaints(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "student":
        raise HTTPException(status_code=403, detail="This endpoint is for students only")
    return db.query(Complaint).filter(Complaint.student_id == current_user.id).order_by(Complaint.created_at.desc()).all()
