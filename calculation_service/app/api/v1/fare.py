from fastapi import APIRouter
from app.schemas import FareRequest, FareResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Fare Calculation"])


@router.post(
    "/fare",
    response_model=FareResponse,
    summary="Calculate Trip/Service Fare",
    description="Calculates total fare based on base fare, per km rate, duration, and surge pricing multiplier."
)
async def calculate_fare(payload: FareRequest):
    logger.info(f"Received fare calculation request: distance={payload.distance_km}km, surge={payload.surge_multiplier}")
    return CalculationEngine.compute_fare(payload)
