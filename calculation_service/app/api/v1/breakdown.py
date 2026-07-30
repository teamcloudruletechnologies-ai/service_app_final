from fastapi import APIRouter
from app.schemas import PriceBreakdownRequest, PriceBreakdownResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Price Breakdown"])


@router.post(
    "/price-breakdown",
    response_model=PriceBreakdownResponse,
    summary="Compute Comprehensive Itemized Price Breakdown",
    description="Aggregates distance, ETA, base fare, surge, platform service charge, GST taxes, and coupons into a single itemized pricing invoice response."
)
async def calculate_price_breakdown(payload: PriceBreakdownRequest):
    logger.info(f"Received price breakdown request for route from {payload.origin} to {payload.destination}")
    return CalculationEngine.compute_price_breakdown(payload)
