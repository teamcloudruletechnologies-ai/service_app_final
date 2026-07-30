from fastapi import APIRouter
from app.schemas import ETARequest, ETAResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["ETA Calculation"])


@router.post(
    "/eta",
    response_model=ETAResponse,
    summary="Calculate Estimated Time of Arrival (ETA)",
    description="Estimates arrival time in minutes based on distance, average speed, and traffic delays."
)
async def calculate_eta(payload: ETARequest):
    logger.info(f"Received ETA calculation request: distance={payload.distance_km}km, speed={payload.avg_speed_kmh}km/h")
    return CalculationEngine.compute_eta(payload)
