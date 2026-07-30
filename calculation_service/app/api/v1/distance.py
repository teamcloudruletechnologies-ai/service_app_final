from fastapi import APIRouter
from app.schemas import DistanceRequest, DistanceResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Distance Calculation"])


@router.post(
    "/distance",
    response_model=DistanceResponse,
    summary="Calculate Haversine Distance",
    description="Calculates the distance between origin and destination coordinates in kilometers and meters using Haversine formula."
)
async def calculate_distance(payload: DistanceRequest):
    logger.info(f"Received distance calculation request from {payload.origin} to {payload.destination}")
    return CalculationEngine.compute_distance(payload)
