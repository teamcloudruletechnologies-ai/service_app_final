# 🚀 FastAPI Calculation Microservice

Standalone high-performance Calculation Service for the Service App ecosystem built with **FastAPI**, **Pydantic v2**, and **Uvicorn**.

## 📌 Features
- **Fare Calculation**: Base fare, per km rate, duration, and surge multiplier.
- **Distance Calculation**: Haversine formula calculation between lat/lng coordinates.
- **ETA Calculation**: Travel time estimation based on distance, speed, and traffic delays.
- **Service Charge Calculation**: Percentage-based platform fee + fixed booking fee.
- **Tax Calculation**: GST calculation (18% default) with CGST/SGST breakdown.
- **Discount & Coupon Calculation**: Percentage and flat discounts with caps and promo codes.
- **Price Breakdown**: Itemized pricing invoice aggregation.
- **Swagger Documentation**: Interactive OpenAPI UI at `/docs`.

---

## 🛠️ Local Setup & Running

### 1. Install Dependencies
```bash
cd calculation_service
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Run Application
```bash
uvicorn app.main:app --reload --port 8000
```
Open [http://localhost:8000/docs](http://localhost:8000/docs) in your browser to view the interactive Swagger UI documentation.

---

## 🐳 Docker Setup
```bash
docker build -t calculation-service .
docker run -p 8000:8000 calculation-service
```
