# 📮 Service App - API Endpoints (Postman / Request Payload Format)

This document presents all backend API endpoints with HTTP Method, Endpoint URL, Headers, Request Body Schema, and Description.

---

## 1. AUTHENTICATION MODULE (`/api/auth`)

### 1.1 User Register
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/user/register`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "name": "John Doe",
  "phone": "9876543210",
  "email": "john@example.com",
  "password": "Password123"
}
```

### 1.2 Worker Register
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/worker/register`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "name": "Robert Smith",
  "phone": "9123456789",
  "service_type": "Electrician",
  "experience_years": 5,
  "password": "Password123"
}
```

### 1.3 Unified Login (Admin / User / Worker)
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/login`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "login": "9876543210",
  "password": "Password123",
  "role": "user"
}
```

### 1.4 Phone Login with OTP
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/auth/phone-login`
- **Headers**: `Content-Type: application/json`
- **Request Body**:
```json
{
  "phone": "9876543210",
  "role": "user"
}
```

---

## 2. APP & BOOKING MODULE (`/api/app`)

### 2.1 Update User FCM Device Token
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/user/fcm-token`
- **Headers**: `Authorization: Bearer <USER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "fcmToken": "fcm_device_token_string_here..."
}
```

### 2.2 Update Worker FCM Device Token
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/worker/fcm-token`
- **Headers**: `Authorization: Bearer <WORKER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "fcmToken": "fcm_device_token_string_here..."
}
```

### 2.3 Create Booking
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/bookings`
- **Headers**: `Authorization: Bearer <USER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "service_id": 1,
  "worker_id": 3,
  "address": "No 12, Main Street, Chennai",
  "notes": "Please bring a ladder",
  "scheduled_at": "2026-07-29T10:00:00.000Z"
}
```

### 2.4 Update Booking Status (Accept / Verify OTP)
- **Method**: `PATCH`
- **URL**: `http://localhost:5000/api/app/bookings/1/status`
- **Headers**: `Authorization: Bearer <WORKER_JWT>`, `Content-Type: application/json`
- **Request Body (Worker Start Job)**:
```json
{
  "status": "in_progress",
  "otp": "4829"
}
```

### 2.5 Submit Custom Worker Invoice
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/bookings/1/submit-invoice`
- **Headers**: `Authorization: Bearer <WORKER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "items": [
    { "description": "AC Filter Washing", "amount": 299 },
    { "description": "Capacitor Replacement", "amount": 100 }
  ],
  "totalAmount": 399
}
```

### 2.6 Create Razorpay Payment Order
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/payments/order`
- **Headers**: `Authorization: Bearer <USER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "bookingId": 1
}
```

### 2.7 Verify Razorpay Payment Signature
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/payments/verify`
- **Headers**: `Authorization: Bearer <USER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "bookingId": 1,
  "razorpayOrderId": "order_Kj98x123",
  "razorpayPaymentId": "pay_Kj98x456",
  "razorpaySignature": "3498877239088ad177..."
}
```

---

## 3. USER ADDRESSES MODULE (`/api/app/addresses`)

### 3.1 Save New Address
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/addresses`
- **Headers**: `Authorization: Bearer <USER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "title": "Home",
  "address_line": "Plot 45, Anna Nagar",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "pincode": "600040",
  "lat": 13.0827,
  "lng": 80.2707,
  "is_default": true
}
```

---

## 4. LOCATION & TRACKING MODULE (`/api/app/locations`)

### 4.1 Update Worker Live GPS Location
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/app/locations/update-worker-location`
- **Headers**: `Authorization: Bearer <WORKER_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "latitude": 13.0827,
  "longitude": 80.2707
}
```

---

## 5. ADMIN MANAGEMENT MODULES (`/api/admin`)

### 5.1 Admin Review KYC
- **Method**: `PATCH`
- **URL**: `http://localhost:5000/api/kyc/1/review`
- **Headers**: `Authorization: Bearer <ADMIN_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "status": "approved",
  "rejectionReason": ""
}
```

### 5.2 Admin Create Service
- **Method**: `POST`
- **URL**: `http://localhost:5000/api/admin/services`
- **Headers**: `Authorization: Bearer <ADMIN_JWT>`, `Content-Type: application/json`
- **Request Body**:
```json
{
  "name": "AC Full Cleaning & Service",
  "category_id": 2,
  "price": 599,
  "description": "Deep cleaning of filters, coils, and outdoor unit",
  "estimated_time": 60
}
```
