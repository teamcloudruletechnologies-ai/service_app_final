from typing import Optional, List
from pydantic import BaseModel, Field, model_validator


# --- Coordinates & Distance ---
class Coordinates(BaseModel):
    lat: float = Field(..., example=13.0827, description="Latitude degree")
    lng: float = Field(..., example=80.2707, description="Longitude degree")


class DistanceRequest(BaseModel):
    origin: Coordinates
    destination: Coordinates


class DistanceResponse(BaseModel):
    distance_km: float = Field(..., example=12.45, description="Distance in kilometers")
    distance_meters: float = Field(..., example=12450.0, description="Distance in meters")
    formatted_distance: str = Field(..., example="12.45 km", description="Human-readable distance")


# --- Fare ---
class FareRequest(BaseModel):
    distance_km: float = Field(..., ge=0, example=12.45, description="Distance in kilometers")
    duration_minutes: float = Field(default=0.0, ge=0, example=25.0, description="Duration in minutes")
    base_fare: float = Field(default=50.0, ge=0, example=50.0, description="Base fare in INR")
    per_km_rate: float = Field(default=12.0, ge=0, example=12.0, description="Rate per kilometer")
    per_minute_rate: float = Field(default=2.0, ge=0, example=2.0, description="Rate per minute")
    surge_multiplier: float = Field(default=1.0, ge=1.0, example=1.2, description="Surge multiplier rate")


class FareResponse(BaseModel):
    base_fare: float = Field(..., example=50.0)
    distance_charge: float = Field(..., example=149.4)
    time_charge: float = Field(..., example=50.0)
    surge_multiplier: float = Field(..., example=1.2)
    subtotal_fare: float = Field(..., example=249.4)
    total_fare: float = Field(..., example=299.28)


# --- ETA ---
class ETARequest(BaseModel):
    distance_km: float = Field(..., ge=0, example=12.45)
    avg_speed_kmh: float = Field(default=30.0, gt=0, example=30.0, description="Average speed in km/h")
    traffic_delay_minutes: float = Field(default=0.0, ge=0, example=5.0, description="Extra traffic delay in mins")


class ETAResponse(BaseModel):
    distance_km: float = Field(..., example=12.45)
    travel_minutes: float = Field(..., example=24.9)
    traffic_delay_minutes: float = Field(..., example=5.0)
    total_eta_minutes: float = Field(..., example=29.9)
    formatted_eta: str = Field(..., example="30 mins")


# --- Service Charge ---
class ServiceChargeRequest(BaseModel):
    subtotal: float = Field(..., ge=0, example=500.0)
    service_charge_percent: float = Field(default=5.0, ge=0, example=5.0)
    fixed_booking_fee: float = Field(default=20.0, ge=0, example=20.0)


class ServiceChargeResponse(BaseModel):
    subtotal: float = Field(..., example=500.0)
    percentage_fee: float = Field(..., example=25.0)
    fixed_booking_fee: float = Field(..., example=20.0)
    total_service_charge: float = Field(..., example=45.0)


# --- Tax ---
class TaxRequest(BaseModel):
    taxable_amount: float = Field(..., ge=0, example=545.0)
    tax_rate_percent: float = Field(default=18.0, ge=0, example=18.0)
    include_cgst_sgst: bool = Field(default=True, example=True)


class TaxResponse(BaseModel):
    taxable_amount: float = Field(..., example=545.0)
    tax_rate_percent: float = Field(..., example=18.0)
    cgst_amount: float = Field(..., example=49.05)
    sgst_amount: float = Field(..., example=49.05)
    total_tax: float = Field(..., example=98.1)


# --- Discount & Coupon ---
class DiscountRequest(BaseModel):
    amount: float = Field(..., ge=0, example=1000.0)
    discount_type: str = Field(..., example="percentage", description="'percentage' or 'flat'")
    discount_value: float = Field(..., ge=0, example=10.0, description="Percentage (e.g., 10%) or flat INR amount")
    max_discount_cap: Optional[float] = Field(default=None, ge=0, example=150.0, description="Max discount limit")
    min_spend: float = Field(default=0.0, ge=0, example=300.0, description="Minimum order total required")


class CouponRequest(BaseModel):
    coupon_code: str = Field(..., example="WELCOME50")
    cart_total: float = Field(..., ge=0, example=600.0)


class DiscountResponse(BaseModel):
    original_amount: float = Field(..., example=1000.0)
    discount_amount: float = Field(..., example=100.0)
    final_amount: float = Field(..., example=900.0)
    applied: bool = Field(..., example=True)
    message: str = Field(..., example="Discount applied successfully")


# --- Price Breakdown ---
class PriceBreakdownRequest(BaseModel):
    origin: Coordinates
    destination: Coordinates
    base_fare: float = Field(default=50.0, ge=0)
    per_km_rate: float = Field(default=12.0, ge=0)
    per_minute_rate: float = Field(default=2.0, ge=0)
    surge_multiplier: float = Field(default=1.0, ge=1.0)
    service_charge_percent: float = Field(default=5.0, ge=0)
    fixed_booking_fee: float = Field(default=20.0, ge=0)
    tax_rate_percent: float = Field(default=18.0, ge=0)
    coupon_code: Optional[str] = Field(default=None, example="WELCOME50")


class PriceBreakdownResponse(BaseModel):
    distance: DistanceResponse
    eta: ETAResponse
    fare: FareResponse
    service_charge: ServiceChargeResponse
    tax: TaxResponse
    discount: DiscountResponse
    grand_total: float = Field(..., example=385.5)
