# 📋 Service App System - Full API Contract (Headers, Request & Response Payloads)

This document provides a comprehensive **Postman-Style API Specification Contract** detailing the exact **Request Headers**, **Request Body Payloads (JSON)**, and **Response Body Payloads (JSON)** for all key REST API endpoints.

---

## 🔑 Common Request Headers Reference

### 1. Public Endpoints (Unauthenticated)
```http
Content-Type: application/json
Accept: application/json
```

### 2. Protected Endpoints (Authenticated User / Worker / Admin)
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <JWT_SESSION_TOKEN>
```

---

## 🔐 1. AUTHENTICATION APIs (`/api/auth`)

### 1.1 User / Worker / Admin Login
* **Endpoint:** `POST /api/auth/login`
* **Request Headers:**
  ```http
  Content-Type: application/json
  ```
* **Request Body (JSON):**
  ```json
  {
    "email": "user@example.com",
    "password": "Password@123",
    "role": "user"
  }
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 42,
      "name": "Arun Kumar",
      "email": "user@example.com",
      "phone": "+919876543210",
      "role": "user"
    }
  }
  ```
* **Error Response Body (401 Unauthorized):**
  ```json
  {
    "success": false,
    "error": "Invalid email or password credentials"
  }
  ```

---

## 📱 2. USER & BOOKING APIs (`/api/app`)

### 2.1 Search Nearby Workers
* **Endpoint:** `GET /api/user-locations/nearby-workers?lat=13.0827&lng=80.2707&service_id=5`
* **Request Headers:**
  ```http
  Authorization: Bearer <JWT_USER_TOKEN>
  ```
* **Request Query Parameters:**
  `lat=13.0827&lng=80.2707&service_id=5&radius=10`
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "count": 2,
    "nearby_workers": [
      {
        "id": 7,
        "name": "Rajesh Kumar",
        "phone": "+919123456789",
        "rating": 4.8,
        "total_jobs": 142,
        "distance_km": 1.25,
        "is_online": 1,
        "lat": 13.0850,
        "lng": 80.2730
      },
      {
        "id": 12,
        "name": "Suresh P.",
        "phone": "+919876123456",
        "rating": 4.6,
        "total_jobs": 89,
        "distance_km": 3.10,
        "is_online": 1,
        "lat": 13.0910,
        "lng": 80.2650
      }
    ]
  }
  ```

---

### 2.2 Create Service Booking
* **Endpoint:** `POST /api/app/bookings`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_USER_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "user_id": 42,
    "service_id": 5,
    "service_date": "2026-07-31",
    "time_slot": "10:00 AM",
    "address": "123 Anna Nagar 2nd Street, Chennai",
    "lat": 13.0827,
    "lng": 80.2707,
    "notes": "Leaking kitchen sink pipe needs replacement"
  }
  ```
* **Success Response Body (201 Created):**
  ```json
  {
    "success": true,
    "message": "Booking created successfully",
    "booking": {
      "id": 101,
      "user_id": 42,
      "service_id": 5,
      "status": "pending",
      "otp": "4829",
      "service_date": "2026-07-31",
      "time_slot": "10:00 AM",
      "amount": "0.00",
      "created_at": "2026-07-30T16:13:00Z"
    }
  }
  ```

---

### 2.3 Worker Accepts Job Assignment
* **Endpoint:** `PATCH /api/app/bookings/101/status`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_WORKER_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "status": "assigned",
    "worker_id": 7
  }
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "message": "Job accepted successfully",
    "booking_id": 101,
    "status": "assigned",
    "worker_id": 7
  }
  ```

---

### 2.4 Worker OTP Verification (Job Start)
* **Endpoint:** `PATCH /api/app/bookings/101/status`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_WORKER_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "status": "in_progress",
    "worker_id": 7,
    "otp": "4829"
  }
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "message": "OTP verified successfully. Job in progress.",
    "status": "in_progress",
    "verified_at": "2026-07-30T16:15:00Z"
  }
  ```
* **Error Response Body (400 Bad Request - OTP Mismatch):**
  ```json
  {
    "success": false,
    "error": "Invalid 4-digit OTP code provided. Please check with customer."
  }
  ```

---

### 2.5 Worker Custom Invoice Submission
* **Endpoint:** `POST /api/app/bookings/101/submit-invoice`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_WORKER_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "worker_id": 7,
    "labor_fee": 149.00,
    "items": [
      { "description": "PVC Kitchen Pipe Connector", "amount": 180.00 },
      { "description": "Teflon Thread Tape", "amount": 70.00 }
    ]
  }
  ```
* **Success Response Body (201 Created):**
  ```json
  {
    "success": true,
    "message": "Custom invoice submitted successfully",
    "invoice": {
      "id": 88,
      "booking_id": 101,
      "labor_fee": 149.00,
      "parts_total": 250.00,
      "tax_gst": 0.00,
      "total_amount": 399.00,
      "status": "unpaid"
    }
  }
  ```

---

### 2.6 Razorpay Payment Signature Verification
* **Endpoint:** `POST /api/app/payments/verify`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_USER_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "booking_id": 101,
    "razorpay_order_id": "order_Px9LmZ0148",
    "razorpay_payment_id": "pay_Px9NqW9921",
    "razorpay_signature": "a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890"
  }
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "message": "Payment verified successfully",
    "payment_status": "paid",
    "booking_status": "completed",
    "receipt_number": "RCPT-101-9942",
    "amount_paid": 399.00
  }
  ```

---

## 👷 3. WORKER & KYC APIs (`/api/kyc`, `/api/worker`)

### 3.1 Submit Worker KYC Documents
* **Endpoint:** `POST /api/kyc`
* **Request Headers:**
  ```http
  Authorization: Bearer <JWT_WORKER_TOKEN>
  Content-Type: multipart/form-data
  ```
* **Form-Data Payload:**
  ```text
  worker_id: 7
  aadhaar_number: 1234-5678-9012
  pan_number: ABCDE1234F
  bank_name: HDFC Bank
  account_number: 50100234567890
  ifsc_code: HDFC0001234
  aadhaar_front: [Binary File]
  pan_card: [Binary File]
  ```
* **Success Response Body (201 Created):**
  ```json
  {
    "success": true,
    "message": "KYC documents submitted successfully. Pending admin review.",
    "kyc_id": 14,
    "status": "pending"
  }
  ```

---

## 🖥️ 4. ADMIN & DASHBOARD APIs (`/api/admin`)

### 4.1 Admin Approve / Reject Worker KYC
* **Endpoint:** `PATCH /api/kyc/14/review`
* **Request Headers:**
  ```http
  Content-Type: application/json
  Authorization: Bearer <JWT_ADMIN_TOKEN>
  ```
* **Request Body (JSON):**
  ```json
  {
    "status": "approved",
    "admin_notes": "Identity and bank documents verified clean."
  }
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "message": "Worker KYC status updated to approved",
    "worker_id": 7,
    "kyc_status": "approved"
  }
  ```

---

### 4.2 Admin Real-Time Dashboard Stats
* **Endpoint:** `GET /api/admin/bookings/analytics`
* **Request Headers:**
  ```http
  Authorization: Bearer <JWT_ADMIN_TOKEN>
  ```
* **Success Response Body (200 OK):**
  ```json
  {
    "success": true,
    "stats": {
      "total_revenue": 148920.00,
      "total_bookings": 542,
      "active_workers": 38,
      "pending_kyc_count": 5,
      "booking_status_counts": {
        "pending": 12,
        "assigned": 8,
        "in_progress": 15,
        "completed": 482,
        "cancelled": 25
      }
    }
  }
  ```
