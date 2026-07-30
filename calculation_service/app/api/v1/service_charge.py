from fastapi import APIRouter
from app.schemas import ServiceChargeRequest, ServiceChargeResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Service Charge Calculation"])


@router.post(
    "/service-charge",
    response_model=ServiceChargeResponse,
    summary="Calculate Platform Service Charge",
    description="Calculates percentage-based platform fee and fixed booking charges."
)
async def calculate_service_charge(payload: ServiceChargeRequest):
    logger.info(f"Received service charge request: subtotal={payload.subtotal}")
    return CalculationEngine.compute_service_charge(payload)
