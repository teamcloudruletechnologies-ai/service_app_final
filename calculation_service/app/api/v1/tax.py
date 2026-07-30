from fastapi import APIRouter
from app.schemas import TaxRequest, TaxResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Tax Calculation"])


@router.post(
    "/tax",
    response_model=TaxResponse,
    summary="Calculate GST / Tax",
    description="Calculates total tax and CGST/SGST split based on tax rate percentage."
)
async def calculate_tax(payload: TaxRequest):
    logger.info(f"Received tax calculation request: taxable={payload.taxable_amount}, rate={payload.tax_rate_percent}%")
    return CalculationEngine.compute_tax(payload)
