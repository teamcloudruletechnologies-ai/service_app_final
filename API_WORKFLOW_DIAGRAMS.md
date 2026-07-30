# 📊 Service App System - API Architecture & Workflow Diagrams

This document visually illustrates the **4 Core End-to-End API Workflows** of the Service App platform, explaining the exact API endpoints called, request payloads, backend business logic, database mutations, and JSON responses.

---

## 🖼️ 1. User Booking & Nearby Worker Discovery API Flow

![User Booking & Worker Discovery API Flow](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/user_booking_flow_diagram_1785402035366.png)

### 🛠️ Technical Workflow Explanation
1. **API Endpoint Hit:** `POST /api/app/bookings`
2. **Request Payload (JSON):**
   ```json
   {
     "user_id": 42,
     "service_id": 5,
     "service_date": "2026-07-31",
     "time_slot": "10:00 AM",
     "address": "123 Anna Nagar, Chennai",
     "lat": 13.0827,
     "lng": 80.2707,
     "notes": "Leaking kitchen tap"
   }
   ```
3. **What Happens Behind the Scenes:**
   * **Location Distance Matrix:** The backend computes distances between the customer's coordinates (`13.0827, 80.2707`) and active technicians using the **Haversine Formula**.
   * **Status Check:** Filters technicians who are `online`, `active`, and within the maximum operating radius (e.g., 10 km).
   * **Database Insert:** Inserts a new booking record into the `bookings` table with status `pending`.
4. **API Response (JSON):**
   ```json
   {
     "success": true,
     "message": "Booking created successfully",
     "booking": {
       "id": 101,
       "status": "pending",
       "user_id": 42,
       "otp": "4829"
     },
     "nearby_workers": [
       { "id": 7, "name": "Rajesh Kumar", "rating": 4.8, "distance_km": 1.2 }
     ]
   }
   ```

---

## 🖼️ 2. Worker Job Acceptance & 4-Digit OTP Verification Flow

![Worker OTP Verification & Job Start API Flow](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/otp_verification_flow_diagram_1785402048409.png)

### 🛠️ Technical Workflow Explanation
1. **API Endpoint Hit:** `PATCH /api/app/bookings/101/status`
2. **Request Payload (JSON):**
   ```json
   {
     "status": "in_progress",
     "worker_id": 7,
     "otp": "4829"
   }
   ```
3. **What Happens Behind the Scenes:**
   * **OTP Match Check:** Backend queries `bookings` table for `id: 101` and compares string inputs:
     ```js
     if (String(booking.otp) !== String(input_otp)) {
       return res.status(400).json({ error: "Invalid OTP code" });
     }
     ```
   * **State Transition:** Updates `bookings` status from `assigned` to `in_progress`.
   * **Real-time Event:** Triggers FCM Push Notification service to alert the user that work has started.
4. **API Response (JSON):**
   ```json
   {
     "success": true,
     "message": "OTP verified successfully. Job in progress.",
     "status": "in_progress",
     "updated_at": "2026-07-30T14:30:00Z"
   }
   ```

---

## 🖼️ 3. Custom Invoice Creation & Razorpay Payment Verification Flow

![Custom Invoice & Razorpay Payment API Flow](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/invoice_payment_flow_diagram_1785402066911.png)

### 🛠️ Technical Workflow Explanation
1. **API Endpoint Hit:**  
   * Step 1: `POST /api/app/bookings/101/invoice` (Worker submits bill)  
   * Step 2: `POST /api/payments/verify` (User completes payment)
2. **Request Payload (Worker Invoice Creation):**
   ```json
   {
     "items": [
       { "description": "Pipe Replacement", "amount": 250 },
       { "description": "Labor Charge", "amount": 149 }
     ]
   }
   ```
3. **What Happens Behind the Scenes:**
   * **Invoice Calculation:** Backend sums line items ($250 + 149 = 399$), applies platform tax/fees, and inserts invoice into `invoices` table.
   * **Razorpay Signature Verification:** Once the user pays via Razorpay, backend verifies HMAC signature:
     ```js
     const expectedSignature = crypto
       .createHmac('sha256', secret)
       .update(order_id + '|' + payment_id)
       .digest('hex');
     ```
   * **Status Completion:** Updates booking status to `completed` and invoice state to `paid`.
4. **API Response (Payment Verified JSON):**
   ```json
   {
     "success": true,
     "message": "Payment verified and booking completed!",
     "payment_status": "paid",
     "receipt_id": "rcpt_101_9942"
   }
   ```

---

## 🖼️ 4. System Architecture & FCM Push Notification Event Flow

![FCM Push Notification Architecture Flow](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/fcm_push_architecture_diagram_1785402082950.png)

### 🛠️ Technical Workflow Explanation
1. **API Endpoint Hit:** `POST /api/app/user/fcm-token` & `POST /api/app/worker/fcm-token`
2. **Token Registration Payload:**
   ```json
   {
     "user_id": 42,
     "fcm_token": "eK3x9LqZ0M1:APA91bH..."
   }
   ```
3. **What Happens Behind the Scenes:**
   * **Device Token Sync:** Saves device registration tokens in `users` and `workers` MySQL tables.
   * **Automated Event Triggers:** Upon state transitions (New Booking, Worker Accepts, Invoice Ready, Payment Completed), backend triggers `fcm.service.js`:
     ```js
     await admin.messaging().send({
       token: userFcmToken,
       notification: { title: "Work Started!", body: "Technician verified OTP." }
     });
     ```
4. **API Response & Delivery:**
   * Instant push banner delivered to target device tray + logged in `notifications` DB table.
