from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.location import Location
from app.schemas.location import LocationCreate, LocationResponse
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.get("", response_model=list[LocationResponse])
async def list_locations(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(Location).all()


@router.post("", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
async def create_location(payload: LocationCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    existing = db.query(Location).filter(Location.location_code == payload.location_code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Location code already exists")

    location = Location(
        location_code=payload.location_code,
        location_name=payload.location_name,
        building=payload.building,
        floor=payload.floor,
        qr_code=payload.qr_code,
    )
    db.add(location)
    db.commit()
    db.refresh(location)
    return location


@router.get("/{location_id}", response_model=LocationResponse)
async def get_location(location_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    return location


@router.get("/code/{location_code}", response_model=LocationResponse)
async def get_location_by_code(location_code: str, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    location = db.query(Location).filter(Location.location_code == location_code).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    return location
