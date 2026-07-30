from fastapi import APIRouter
from app.api.v1 import (
    distance,
    fare,
    eta,
    service_charge,
    tax,
    discount,
    breakdown,
)

api_router = APIRouter()

api_router.include_router(distance.router)
api_router.include_router(fare.router)
api_router.include_router(eta.router)
api_router.include_router(service_charge.router)
api_router.include_router(tax.router)
api_router.include_router(discount.router)
api_router.include_router(breakdown.router)
