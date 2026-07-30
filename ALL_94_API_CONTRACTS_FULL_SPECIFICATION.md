# 🌐 Service App System - All 94 API Endpoints Full Specification Contract

This document provides the complete, exhaustive Postman-Style API Contract detailing the **Request Headers**, **Request Payloads (JSON)**, and **Response Payloads (JSON)** for all **94 REST API Endpoints** in the Service App Platform.

---

## 🔑 Global Request Headers Standard

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <JWT_TOKEN>
```

---

## 🔐 CATEGORY 01: AUTHENTICATION APIs (`/api/auth`)

### 1. Register Admin Account
* **Endpoint:** `POST /api/auth/admin/register`
* **Headers:** `Content-Type: application/json`
* **Request Body (JSON):**
  ```json
  { "name": "Super Admin", "email": "admin@serviceapp.com", "password": "AdminPassword@123" }
  ```
* **Response Body (201 Created):**
  ```json
  { "success": true, "message": "Admin registered successfully", "admin_id": 1 }
  ```

### 2. Register User Account
* **Endpoint:** `POST /api/auth/user/register`
* **Headers:** `Content-Type: application/json`
* **Request Body (JSON):**
  ```json
  { "name": "Arun Kumar", "email": "arun@example.com", "phone": "+919876543210", "password": "UserPassword@123" }
  ```
* **Response Body (201 Created):**
  ```json
  { "success": true, "message": "User registered successfully", "user_id": 42 }
  ```

### 3. Register Worker Account
* **Endpoint:** `POST /api/auth/worker/register`
* **Headers:** `Content-Type: application/json`
* **Request Body (JSON):**
  ```json
  { "name": "Rajesh Kumar", "email": "rajesh@example.com", "phone": "+919123456789", "password": "WorkerPassword@123", "service_category_id": 5 }
  ```
* **Response Body (201 Created):**
  ```json
  { "success": true, "message": "Worker registered successfully", "worker_id": 7 }
  ```

### 4. Unified Account Login
* **Endpoint:** `POST /api/auth/login`
* **Headers:** `Content-Type: application/json`
* **Request Body (JSON):**
  ```json
  { "email": "arun@example.com", "password": "UserPassword@123", "role": "user" }
  ```
* **Response Body (200 OK):**
  ```json
  { "success": true, "token": "eyJhbGciOiJIUzI1Ni...", "user": { "id": 42, "name": "Arun Kumar", "role": "user" } }
  ```

### 5. Phone OTP Login
* **Endpoint:** `POST /api/auth/phone-login`
* **Headers:** `Content-Type: application/json`
* **Request Body (JSON):**
  ```json
  { "phone": "+919876543210", "otp": "1234" }
  ```
* **Response Body (200 OK):**
  ```json
  { "success": true, "token": "eyJhbGciOiJIUzI1Ni...", "user": { "id": 42, "phone": "+919876543210" } }
  ```

### 6. Get Current Auth Profile
* **Endpoint:** `GET /api/auth/me`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "user": { "id": 42, "name": "Arun Kumar", "email": "arun@example.com", "role": "user" } }
  ```

---

## 📱 CATEGORY 02: APP & BOOKING APIs (`/api/app`)

### 7. List Categories
* **Endpoint:** `GET /api/app/services/categories`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "categories": [{ "id": 1, "name": "Plumbing", "image_url": "/uploads/plumbing.png" }] }
  ```

### 8. List Sub-Categories
* **Endpoint:** `GET /api/app/services/categories/1/subcategories`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "subcategories": [{ "id": 10, "name": "Tap Repair", "category_id": 1 }] }
  ```

### 9. List Banners
* **Endpoint:** `GET /api/app/banners`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "banners": [{ "id": 1, "title": "50% Off Plumbing", "image_url": "/uploads/banner1.png" }] }
  ```

### 10. List Services Catalog
* **Endpoint:** `GET /api/app/services`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "services": [{ "id": 5, "name": "Leak Repair", "price": "299.00" }] }
  ```

### 11. Get Service Details
* **Endpoint:** `GET /api/app/services/5`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "service": { "id": 5, "name": "Leak Repair", "price": "299.00", "description": "Fix pipe leaks" } }
  ```

### 12. Upload File / Image
* **Endpoint:** `POST /api/app/upload`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`, `Content-Type: multipart/form-data`
* **Response Body (201 Created):**
  ```json
  { "success": true, "file_url": "/uploads/img_9912.png" }
  ```

### 13. Update Worker Profile
* **Endpoint:** `PATCH /api/app/worker/profile`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "bio": "Expert Plumber 10 yrs exp", "experience_years": 10 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker profile updated" }
  ```

### 14. Get Worker Earnings
* **Endpoint:** `GET /api/app/worker/earnings`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "wallet_balance": 4500.00, "total_jobs_completed": 48 }
  ```

### 15. Update User Profile
* **Endpoint:** `PATCH /api/app/user/profile`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "name": "Arun K.", "phone": "+919876543210" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User profile updated" }
  ```

### 16. Save User FCM Device Token
* **Endpoint:** `POST /api/app/user/fcm-token`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "user_id": 42, "fcm_token": "fcm_token_string_123" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User FCM token saved" }
  ```

### 17. Save Worker FCM Device Token
* **Endpoint:** `POST /api/app/worker/fcm-token`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "worker_id": 7, "fcm_token": "fcm_token_string_456" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker FCM token saved" }
  ```

### 18. Create Service Booking
* **Endpoint:** `POST /api/app/bookings`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "user_id": 42, "service_id": 5, "service_date": "2026-07-31", "time_slot": "10:00 AM", "address": "123 Street", "lat": 13.08, "lng": 80.27 }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "booking": { "id": 101, "status": "pending", "otp": "4829" } }
  ```

### 19. Cancel Booking
* **Endpoint:** `PATCH /api/app/bookings/101/cancel`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "reason": "Changed my plan" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Booking cancelled successfully" }
  ```

### 20. List Bookings
* **Endpoint:** `GET /api/app/bookings`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "bookings": [{ "id": 101, "status": "pending", "otp": "4829" }] }
  ```

### 21. Get Booking Details
* **Endpoint:** `GET /api/app/bookings/101`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "booking": { "id": 101, "service_name": "Tap Repair", "otp": "4829", "status": "pending" } }
  ```

### 22. Update Booking Status / Verify OTP
* **Endpoint:** `PATCH /api/app/bookings/101/status`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "status": "in_progress", "otp": "4829", "worker_id": 7 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "OTP verified. Status updated to in_progress" }
  ```

### 23. Start Job Photo Verification
* **Endpoint:** `POST /api/app/bookings/101/start-job`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "before_photo_url": "/uploads/before.jpg" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Job started with before photo" }
  ```

### 24. Complete Job Photo Verification
* **Endpoint:** `POST /api/app/bookings/101/complete-job`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "after_photo_url": "/uploads/after.jpg" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Job marked finished with photo proof" }
  ```

### 25. Submit Worker Custom Invoice
* **Endpoint:** `POST /api/app/bookings/101/submit-invoice`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "worker_id": 7, "labor_fee": 149.00, "items": [{ "description": "Pipe Valve", "amount": 250.00 }] }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "invoice": { "id": 88, "total_amount": 399.00, "status": "unpaid" } }
  ```

### 26. Create Razorpay Payment Order
* **Endpoint:** `POST /api/app/payments/order`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "booking_id": 101, "amount": 399.00 }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "razorpay_order_id": "order_Px9LmZ0148", "amount": 399.00 }
  ```

### 27. Verify Razorpay Payment Signature
* **Endpoint:** `POST /api/app/payments/verify`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "booking_id": 101, "razorpay_order_id": "order_Px9LmZ0148", "razorpay_payment_id": "pay_Px9NqW9921", "razorpay_signature": "a1b2c3d4..." }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Payment verified", "payment_status": "paid", "booking_status": "completed" }
  ```

### 28. Submit Service Review
* **Endpoint:** `POST /api/app/reviews`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "booking_id": 101, "worker_id": 7, "rating": 5, "comment": "Excellent work!" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "message": "Review submitted successfully" }
  ```

### 29. List Service Reviews
* **Endpoint:** `GET /api/app/reviews?service_id=5`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "reviews": [{ "id": 12, "rating": 5, "comment": "Excellent work!" }] }
  ```

---

## 📍 CATEGORY 03: USER ADDRESSES (`/api/app/addresses`)

### 30. Get Saved Addresses
* **Endpoint:** `GET /api/app/addresses`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "addresses": [{ "id": 1, "label": "Home", "address": "123 Anna Nagar", "lat": 13.08, "lng": 80.27 }] }
  ```

### 31. Add Saved Address
* **Endpoint:** `POST /api/app/addresses`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "label": "Home", "address": "123 Anna Nagar", "lat": 13.08, "lng": 80.27 }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "address_id": 1, "message": "Address saved" }
  ```

### 32. Update Saved Address
* **Endpoint:** `PUT /api/app/addresses/1`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "label": "Office", "address": "456 T Nagar", "lat": 13.04, "lng": 80.23 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Address updated" }
  ```

### 33. Delete Saved Address
* **Endpoint:** `DELETE /api/app/addresses/1`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Address deleted" }
  ```

### 34. Set Default Address
* **Endpoint:** `PATCH /api/app/addresses/1/default`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Default address updated" }
  ```

---

## 🗺️ CATEGORY 04: LOCATION & GEOCODING (`/api/app/locations`)

### 35. Reverse Geocode Lat/Lng
* **Endpoint:** `POST /api/app/locations/reverse-geocode`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Request Body:** `{ "lat": 13.0827, "lng": 80.2707 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "address": "123 Anna Nagar, Chennai, Tamil Nadu" }
  ```

### 36. Find Nearby Workers
* **Endpoint:** `POST /api/app/locations/nearby-workers`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Request Body:** `{ "lat": 13.0827, "lng": 80.2707, "service_id": 5, "radius_km": 10 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "nearby_workers": [{ "id": 7, "name": "Rajesh Kumar", "distance_km": 1.25 }] }
  ```

### 37. Update Worker Live Location
* **Endpoint:** `POST /api/app/locations/update-worker-location`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`
* **Request Body:** `{ "worker_id": 7, "lat": 13.0850, "lng": 80.2730 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker live GPS location updated" }
  ```

### 38. Get Worker Live Tracking Coordinates
* **Endpoint:** `GET /api/app/locations/worker-location/7`
* **Headers:** `Authorization: Bearer <JWT_USER_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "worker_id": 7, "lat": 13.0850, "lng": 80.2730, "updated_at": "2026-07-30T16:17:00Z" }
  ```

---

## 👥 CATEGORY 05: ADMIN USER MANAGEMENT (`/api/admin/users`)

### 39. List All Users
* **Endpoint:** `GET /api/admin/users?page=1&limit=10&search=Arun`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "users": [{ "id": 42, "name": "Arun Kumar", "email": "arun@example.com", "status": "active" }] }
  ```

### 40. Create User Manually
* **Endpoint:** `POST /api/admin/users`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Suresh", "email": "suresh@example.com", "phone": "+919876000000" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "user_id": 43, "message": "User created manually" }
  ```

### 41. Get User Profile Details
* **Endpoint:** `GET /api/admin/users/42`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "user": { "id": 42, "name": "Arun Kumar", "total_bookings": 12, "status": "active" } }
  ```

### 42. Update User Details
* **Endpoint:** `PATCH /api/admin/users/42`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Arun K. Updated" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User profile updated by admin" }
  ```

### 43. Delete User Account
* **Endpoint:** `DELETE /api/admin/users/42`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User account deleted" }
  ```

### 44. Block User Account
* **Endpoint:** `PATCH /api/admin/users/42/block`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "reason": "Violation of policy" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User account blocked" }
  ```

### 45. Unblock User Account
* **Endpoint:** `PATCH /api/admin/users/42/unblock`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "User account unblocked" }
  ```

### 46. Get User Booking History
* **Endpoint:** `GET /api/admin/users/42/bookings`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "bookings": [{ "id": 101, "status": "completed", "amount": 399.00 }] }
  ```

### 47. View User Activity Logs
* **Endpoint:** `GET /api/admin/users/42/activity-logs`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "logs": [{ "action": "LOGIN", "timestamp": "2026-07-30T10:00:00Z" }] }
  ```

### 48. Download User Activity Logs CSV
* **Endpoint:** `GET /api/admin/users/42/activity-logs/download`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):** *(Binary CSV File Stream)*

---

## 👷 CATEGORY 06: ADMIN WORKER MANAGEMENT (`/api/workers`)

### 49. List Workers
* **Endpoint:** `GET /api/workers?status=active&service_id=5`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "workers": [{ "id": 7, "name": "Rajesh Kumar", "is_online": 1, "kyc_status": "approved" }] }
  ```

### 50. Create Worker Manually
* **Endpoint:** `POST /api/workers`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Ramesh", "phone": "+919998887770", "service_category_id": 1 }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "worker_id": 15, "message": "Worker account created" }
  ```

### 51. Get Worker Details
* **Endpoint:** `GET /api/workers/7`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "worker": { "id": 7, "name": "Rajesh Kumar", "rating": 4.8, "kyc_status": "approved" } }
  ```

### 52. Update Worker Details
* **Endpoint:** `PATCH /api/workers/7`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "skills": "Plumbing, AC Repair" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker details updated" }
  ```

### 53. Delete Worker Account
* **Endpoint:** `DELETE /api/workers/7`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker account deleted" }
  ```

### 54. Toggle Worker Status (Active / Inactive)
* **Endpoint:** `PATCH /api/workers/7/status`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "is_active": false }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker status updated to inactive" }
  ```

---

## 🪪 CATEGORY 07: WORKER KYC MANAGEMENT (`/api/kyc`)

### 55. Submit Worker KYC
* **Endpoint:** `POST /api/kyc`
* **Headers:** `Authorization: Bearer <JWT_WORKER_TOKEN>`, `Content-Type: multipart/form-data`
* **Form-Data:** `aadhaar_number: 1234-5678-9012`, `pan_number: ABCDE1234F`, `aadhaar_front: [file]`
* **Response Body (201 Created):**
  ```json
  { "success": true, "kyc_id": 14, "status": "pending" }
  ```

### 56. List Pending KYC Submissions
* **Endpoint:** `GET /api/kyc?status=pending`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "submissions": [{ "id": 14, "worker_name": "Rajesh Kumar", "status": "pending" }] }
  ```

### 57. Get Single KYC Submission
* **Endpoint:** `GET /api/kyc/14`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "kyc": { "id": 14, "worker_id": 7, "aadhaar_number": "1234-5678-9012", "aadhaar_url": "/uploads/aadhaar.png" } }
  ```

### 58. Admin Review KYC (Approve / Reject)
* **Endpoint:** `PATCH /api/kyc/14/review`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "status": "approved", "admin_notes": "All proofs clean" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "KYC approved successfully", "kyc_status": "approved" }
  ```

---

## 🧰 CATEGORY 08: ADMIN SERVICE CATALOG (`/api/admin/services`)

### 59. List Categories CRUD
* **Endpoint:** `GET /api/admin/services/categories`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "categories": [{ "id": 1, "name": "Plumbing", "is_active": 1 }] }
  ```

### 60. Create Category
* **Endpoint:** `POST /api/admin/services/categories`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Carpentry", "image_url": "/uploads/carpentry.png" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "category_id": 4, "message": "Category created" }
  ```

### 61. Update Category
* **Endpoint:** `PUT /api/admin/services/categories/1`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Advanced Plumbing" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Category updated" }
  ```

### 62. Delete Category
* **Endpoint:** `DELETE /api/admin/services/categories/1`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Category deleted" }
  ```

### 63. List All Services
* **Endpoint:** `GET /api/admin/services`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "services": [{ "id": 5, "name": "Tap Repair", "price": 299.00 }] }
  ```

### 64. Create Service
* **Endpoint:** `POST /api/admin/services`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "category_id": 1, "name": "Pipe Fitting", "price": 499.00, "description": "Fix main pipe line" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "service_id": 18, "message": "Service created" }
  ```

### 65. Update Service
* **Endpoint:** `PUT /api/admin/services/5`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "price": 349.00 }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Service price updated" }
  ```

### 66. Delete Service
* **Endpoint:** `DELETE /api/admin/services/5`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Service deleted" }
  ```

### 67. Toggle Service Availability Status
* **Endpoint:** `PATCH /api/admin/services/5/status`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "is_active": false }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Service status updated to inactive" }
  ```

---

## 📋 CATEGORY 09: ADMIN BOOKINGS MANAGEMENT (`/api/admin/bookings`)

### 68. List All System Bookings
* **Endpoint:** `GET /api/admin/bookings?status=pending`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "bookings": [{ "id": 101, "customer_name": "Arun", "status": "pending" }] }
  ```

### 69. Get Booking Analytics
* **Endpoint:** `GET /api/admin/bookings/analytics`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "analytics": { "total_orders": 542, "completed": 482, "cancelled": 25 } }
  ```

### 70. Get Booking Details (Admin View)
* **Endpoint:** `GET /api/admin/bookings/101`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "booking": { "id": 101, "otp": "4829", "user_phone": "+919876543210", "status": "pending" } }
  ```

### 71. Admin Update Booking / Manual Worker Assign
* **Endpoint:** `PATCH /api/admin/bookings/101`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "worker_id": 12, "status": "assigned" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Worker manually assigned by admin" }
  ```

---

## 🧾 CATEGORY 10: ADMIN INVOICES & PAYOUTS (`/api/admin/invoices`)

### 72. List Invoices
* **Endpoint:** `GET /api/admin/invoices`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "invoices": [{ "id": 88, "booking_id": 101, "amount": 399.00, "status": "paid" }] }
  ```

### 73. List Payment Transactions
* **Endpoint:** `GET /api/admin/invoices/payments`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "payments": [{ "id": 401, "razorpay_payment_id": "pay_Px9NqW9921", "amount": 399.00 }] }
  ```

### 74. Get Invoice Financial Summary Report
* **Endpoint:** `GET /api/admin/invoices/reports`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "report": { "total_sales": 148920.00, "platform_commission": 22338.00 } }
  ```

### 75. Get Worker Payout Summary
* **Endpoint:** `GET /api/admin/invoices/payouts`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "payouts": [{ "worker_id": 7, "pending_payout": 3400.00 }] }
  ```

### 76. Get Single Invoice Details
* **Endpoint:** `GET /api/admin/invoices/88`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "invoice": { "id": 88, "labor_fee": 149.00, "spare_parts": [{ "desc": "Valve", "cost": 250.00 }] } }
  ```

---

## 🎧 CATEGORY 11: HELPDESK COMPLAINTS (`/api/admin/complaints`)

### 77. List Support Complaints
* **Endpoint:** `GET /api/admin/complaints`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "complaints": [{ "id": 5, "subject": "Late worker arrival", "status": "open" }] }
  ```

### 78. Get Complaint Ticket Details
* **Endpoint:** `GET /api/admin/complaints/5`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "complaint": { "id": 5, "user_id": 42, "subject": "Late arrival", "status": "open" } }
  ```

### 79. Update Complaint Status & Resolution
* **Endpoint:** `PATCH /api/admin/complaints/5`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "status": "resolved", "resolution_notes": "Issued ₹50 refund coupon" }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Complaint ticket resolved" }
  ```

### 80. Create Support Ticket
* **Endpoint:** `POST /api/admin/complaints`
* **Headers:** `Authorization: Bearer <JWT_TOKEN>`
* **Request Body:** `{ "user_id": 42, "booking_id": 101, "subject": "Billing query" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "complaint_id": 6, "message": "Ticket created" }
  ```

---

## 📍 CATEGORY 12: COVERAGE ZONES & LOCATIONS (`/api/admin/locations`)

### 81. List Operational Service Zones
* **Endpoint:** `GET /api/admin/locations/zones`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "zones": [{ "id": 1, "city": "Chennai", "zone_name": "Anna Nagar" }] }
  ```

### 82. Add New Service Zone
* **Endpoint:** `POST /api/admin/locations/zones`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "city": "Chennai", "zone_name": "Velachery" }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "zone_id": 2, "message": "Service zone added" }
  ```

### 83. Delete Service Zone
* **Endpoint:** `DELETE /api/admin/locations/zones/2`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Zone deleted" }
  ```

### 84. List Serviceable Pincodes
* **Endpoint:** `GET /api/admin/locations/pincodes`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "pincodes": [{ "id": 10, "pincode": "600040", "city": "Chennai" }] }
  ```

### 85. Map New Pincode
* **Endpoint:** `POST /api/admin/locations/pincodes`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "pincode": "600042", "zone_id": 1 }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "message": "Pincode mapped" }
  ```

---

## 🔐 CATEGORY 13: SUB-ADMIN RBAC MANAGEMENT (`/api/admin/sub-admins`)

### 86. List Sub-Admin Accounts
* **Endpoint:** `GET /api/admin/sub-admins`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "sub_admins": [{ "id": 3, "name": "Manager 1", "role": "sub_admin" }] }
  ```

### 87. Create Sub-Admin Account
* **Endpoint:** `POST /api/admin/sub-admins`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "name": "Manager 1", "email": "manager1@app.com", "password": "Pass@123", "permissions": ["users", "bookings"] }`
* **Response Body (201 Created):**
  ```json
  { "success": true, "sub_admin_id": 3, "message": "Sub-admin created" }
  ```

### 88. Get Sub-Admin Details
* **Endpoint:** `GET /api/admin/sub-admins/3`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "sub_admin": { "id": 3, "name": "Manager 1", "permissions": ["users", "bookings"] } }
  ```

### 89. Update Sub-Admin Permissions
* **Endpoint:** `PATCH /api/admin/sub-admins/3`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Request Body:** `{ "permissions": ["users", "bookings", "invoices"] }`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Sub-admin permissions updated" }
  ```

### 90. Delete Sub-Admin Account
* **Endpoint:** `DELETE /api/admin/sub-admins/3`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Sub-admin account deleted" }
  ```

---

## 🔔 CATEGORY 14: NOTIFICATIONS & BANNERS (`/api/admin/notifications`, `/banners`)

### 91. List Notifications Log
* **Endpoint:** `GET /api/admin/notifications`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "notifications": [{ "id": 1, "title": "New Booking", "is_read": 0 }] }
  ```

### 92. Mark Single Notification Read
* **Endpoint:** `PATCH /api/admin/notifications/1/read`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Notification marked read" }
  ```

### 93. Mark All Notifications Read
* **Endpoint:** `PATCH /api/admin/notifications/read-all`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "All notifications marked read" }
  ```

### 94. Delete Notification Entry
* **Endpoint:** `DELETE /api/admin/notifications/1`
* **Headers:** `Authorization: Bearer <JWT_ADMIN_TOKEN>`
* **Response Body (200 OK):**
  ```json
  { "success": true, "message": "Notification deleted" }
  ```
