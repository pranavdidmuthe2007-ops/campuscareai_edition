from __future__ import annotations

from pydantic import BaseModel, Field


class AIAnalysisRequest(BaseModel):
    description: str = Field(..., min_length=10, max_length=3000)


class AIAnalysisResponse(BaseModel):
    category: str
    priority: str
    confidence: float
