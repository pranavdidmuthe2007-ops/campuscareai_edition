from fastapi import APIRouter, Depends, HTTPException

from app.schemas.ai import AIAnalysisRequest, AIAnalysisResponse
from app.services.ai_service import analyze_complaint
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/ai", tags=["AI"])


@router.post("/analyze-complaint", response_model=AIAnalysisResponse)
async def analyze_complaint_endpoint(payload: AIAnalysisRequest, current_user=Depends(get_current_user)):
    if not payload.description or len(payload.description.strip()) < 10:
        raise HTTPException(status_code=400, detail="Complaint description should be at least 10 characters.")

    result = analyze_complaint(payload.description)
    return AIAnalysisResponse(**result)
