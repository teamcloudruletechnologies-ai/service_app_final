import math
from app.services.geoutils import calculate_haversine_distance
from app.schemas.calculation import (
    DistanceRequest, DistanceResponse,
    FareRequest, FareResponse,
    ETARequest, ETAResponse,
    ServiceChargeRequest, ServiceChargeResponse,
    TaxRequest, TaxResponse,
    DiscountRequest, CouponRequest, DiscountResponse,
    PriceBreakdownRequest, PriceBreakdownResponse
)


class CalculationEngine:

    @staticmethod
    def compute_distance(req: DistanceRequest) -> DistanceResponse:
        dist_km = calculate_haversine_distance(
            req.origin.lat, req.origin.lng,
            req.destination.lat, req.destination.lng
        )
        dist_m = round(dist_km * 1000.0, 2)
        return DistanceResponse(
            distance_km=dist_km,
            distance_meters=dist_m,
            formatted_distance=f"{dist_km} km"
        )

    @staticmethod
    def compute_fare(req: FareRequest) -> FareResponse:
        distance_charge = round(req.distance_km * req.per_km_rate, 2)
        time_charge = round(req.duration_minutes * req.per_minute_rate, 2)
        subtotal = round(req.base_fare + distance_charge + time_charge, 2)
        total_fare = round(subtotal * req.surge_multiplier, 2)

        return FareResponse(
            base_fare=req.base_fare,
            distance_charge=distance_charge,
            time_charge=time_charge,
            surge_multiplier=req.surge_multiplier,
            subtotal_fare=subtotal,
            total_fare=total_fare
        )

    @staticmethod
    def compute_eta(req: ETARequest) -> ETAResponse:
        travel_hours = req.distance_km / req.avg_speed_kmh
        travel_minutes = round(travel_hours * 60.0, 2)
        total_eta = round(travel_minutes + req.traffic_delay_minutes, 2)
        
        display_mins = int(math.ceil(total_eta))
        return ETAResponse(
            distance_km=req.distance_km,
            travel_minutes=travel_minutes,
            traffic_delay_minutes=req.traffic_delay_minutes,
            total_eta_minutes=total_eta,
            formatted_eta=f"{display_mins} mins"
        )

    @staticmethod
    def compute_service_charge(req: ServiceChargeRequest) -> ServiceChargeResponse:
        percentage_fee = round((req.subtotal * req.service_charge_percent) / 100.0, 2)
        total_charge = round(percentage_fee + req.fixed_booking_fee, 2)

        return ServiceChargeResponse(
            subtotal=req.subtotal,
            percentage_fee=percentage_fee,
            fixed_booking_fee=req.fixed_booking_fee,
            total_service_charge=total_charge
        )

    @staticmethod
    def compute_tax(req: TaxRequest) -> TaxResponse:
        total_tax = round((req.taxable_amount * req.tax_rate_percent) / 100.0, 2)
        cgst = round(total_tax / 2.0, 2)
        sgst = round(total_tax / 2.0, 2)

        return TaxResponse(
            taxable_amount=req.taxable_amount,
            tax_rate_percent=req.tax_rate_percent,
            cgst_amount=cgst if req.include_cgst_sgst else 0.0,
            sgst_amount=sgst if req.include_cgst_sgst else 0.0,
            total_tax=total_tax
        )

    @staticmethod
    def compute_discount(req: DiscountRequest) -> DiscountResponse:
        if req.amount < req.min_spend:
            return DiscountResponse(
                original_amount=req.amount,
                discount_amount=0.0,
                final_amount=req.amount,
                applied=False,
                message=f"Minimum spend of ₹{req.min_spend} required to apply discount."
            )

        if req.discount_type.lower() == "percentage":
            discount = (req.amount * req.discount_value) / 100.0
        elif req.discount_type.lower() == "flat":
            discount = req.discount_value
        else:
            return DiscountResponse(
                original_amount=req.amount,
                discount_amount=0.0,
                final_amount=req.amount,
                applied=False,
                message="Invalid discount type. Must be 'percentage' or 'flat'."
            )

        if req.max_discount_cap is not None and discount > req.max_discount_cap:
            discount = req.max_discount_cap

        discount = round(min(discount, req.amount), 2)
        final_amt = round(req.amount - discount, 2)

        return DiscountResponse(
            original_amount=req.amount,
            discount_amount=discount,
            final_amount=final_amt,
            applied=True,
            message="Discount applied successfully."
        )

    @classmethod
    def compute_coupon(cls, req: CouponRequest) -> DiscountResponse:
        # Predefined mock coupon catalog
        coupons = {
            "WELCOME50": {"type": "percentage", "value": 50.0, "cap": 150.0, "min_spend": 200.0},
            "FLAT100": {"type": "flat", "value": 100.0, "cap": 100.0, "min_spend": 500.0},
            "FESTIVE20": {"type": "percentage", "value": 20.0, "cap": 500.0, "min_spend": 1000.0},
        }

        code_upper = req.coupon_code.upper()
        if code_upper not in coupons:
            return DiscountResponse(
                original_amount=req.cart_total,
                discount_amount=0.0,
                final_amount=req.cart_total,
                applied=False,
                message=f"Invalid or expired coupon code '{req.coupon_code}'."
            )

        rules = coupons[code_upper]
        disc_req = DiscountRequest(
            amount=req.cart_total,
            discount_type=rules["type"],
            discount_value=rules["value"],
            max_discount_cap=rules["cap"],
            min_spend=rules["min_spend"]
        )

        return cls.compute_discount(disc_req)

    @classmethod
    def compute_price_breakdown(cls, req: PriceBreakdownRequest) -> PriceBreakdownResponse:
        # 1. Distance
        dist_resp = cls.compute_distance(DistanceRequest(origin=req.origin, destination=req.destination))

        # 2. ETA
        eta_resp = cls.compute_eta(ETARequest(distance_km=dist_resp.distance_km))

        # 3. Fare
        fare_req = FareRequest(
            distance_km=dist_resp.distance_km,
            duration_minutes=eta_resp.total_eta_minutes,
            base_fare=req.base_fare,
            per_km_rate=req.per_km_rate,
            per_minute_rate=req.per_minute_rate,
            surge_multiplier=req.surge_multiplier
        )
        fare_resp = cls.compute_fare(fare_req)

        # 4. Service Charge
        svc_req = ServiceChargeRequest(
            subtotal=fare_resp.total_fare,
            service_charge_percent=req.service_charge_percent,
            fixed_booking_fee=req.fixed_booking_fee
        )
        svc_resp = cls.compute_service_charge(svc_req)

        taxable_subtotal = round(fare_resp.total_fare + svc_resp.total_service_charge, 2)

        # 5. Tax
        tax_req = TaxRequest(
            taxable_amount=taxable_subtotal,
            tax_rate_percent=req.tax_rate_percent
        )
        tax_resp = cls.compute_tax(tax_req)

        subtotal_before_discount = round(taxable_subtotal + tax_resp.total_tax, 2)

        # 6. Coupon / Discount
        if req.coupon_code:
            discount_resp = cls.compute_coupon(CouponRequest(coupon_code=req.coupon_code, cart_total=subtotal_before_discount))
        else:
            discount_resp = DiscountResponse(
                original_amount=subtotal_before_discount,
                discount_amount=0.0,
                final_amount=subtotal_before_discount,
                applied=False,
                message="No coupon code applied."
            )

        grand_total = discount_resp.final_amount

        return PriceBreakdownResponse(
            distance=dist_resp,
            eta=eta_resp,
            fare=fare_resp,
            service_charge=svc_resp,
            tax=tax_resp,
            discount=discount_resp,
            grand_total=grand_total
        )
