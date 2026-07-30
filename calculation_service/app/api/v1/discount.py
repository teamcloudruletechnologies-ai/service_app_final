from fastapi import APIRouter
from app.schemas import DiscountRequest, CouponRequest, DiscountResponse
from app.services.calc_engine import CalculationEngine
from app.core.logging import logger

router = APIRouter(prefix="/calculate", tags=["Discount & Coupon Calculation"])


@router.post(
    "/discount",
    response_model=DiscountResponse,
    summary="Calculate Direct Discount",
    description="Calculates percentage or flat discount with optional cap limit and minimum spend requirements."
)
async def calculate_discount(payload: DiscountRequest):
    logger.info(f"Received discount calculation request: type={payload.discount_type}, value={payload.discount_value}")
    return CalculationEngine.compute_discount(payload)


@router.post(
    "/coupon",
    response_model=DiscountResponse,
    summary="Validate and Calculate Coupon Code Discount",
    description="Evaluates promo code rules against order subtotal and computes discount."
)
async def calculate_coupon(payload: CouponRequest):
    logger.info(f"Received coupon request: code={payload.coupon_code}, cart_total={payload.cart_total}")
    return CalculationEngine.compute_coupon(payload)
