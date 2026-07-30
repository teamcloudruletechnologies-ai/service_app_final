# 📋 Service App System - Complete API Endpoints & Internal Flows Guide

This standalone documentation file provides a complete technical guide detailing the **Step-by-Step Internal Execution Flows**, **Exact API Endpoints**, **HTTP Methods**, **Request Payloads**, and **Behind-the-Scenes Backend Logic** for all 4 core components of the platform:
1. 📱 **User Mobile App**
2. 👷 **Worker Mobile App**
3. 🖥️ **Admin Web Panel**
4. ⚙️ **Backend REST API Engine**

---

## 📱 1. User Mobile App - Internal Execution Flow & API Reference Table

```
+---------------------------------------------------------------------------------------------------+
|                                  USER APP DETAILED INTERNAL FLOW                                  |
+---------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
                                      [ 1. Launch & Auth Check ]
                                                  |
                                                  v
                                     [ 2. Home Screen & Discovery ]
                                                  |
                                                  v
                                     [ 3. Location & Worker Search ]
                                                  |
                                                  v
                                    [ 4. Configure & Submit Booking ]
                                                  |
                                                  v
                                    [ 5. My Bookings & OTP Display ]
                                                  |
                                                  v
                                     [ 6. Live Map Tracking (GPS) ]
                                                  |
                                                  v
                                   [ 7. Custom Invoice & Pay Now Checkout ]
                                                  |
                                                  v
                                     [ 8. Post-Service Review ]
```

### 💻 User App Complete API Execution Table:

| Step | User App Feature Screen | Exact API Endpoint Hit | HTTP Method | Request Payload / Query Params | What Happens Behind the Scenes (Backend Logic) |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **1** | App Launch & Session | `/api/user/profile` | `GET` | `Header: Bearer <JWT_Token>` | Decodes JWT token in Authorization Header to restore user session. Redirects to Login if expired. |
| **2a**| Home Service Categories| `/api/service/categories` | `GET` | *None* | Fetches active service categories, category icons, and display ordering. |
| **2b**| Home Offer Banners | `/api/banner` | `GET` | *None* | Retrieves active promotional offer banners for the home screen slider. |
| **2c**| Popular Services | `/api/service` | `GET` | *None* | Fetches featured service catalog items with base prices & descriptions. |
| **3a**| Location Pin Drop | `/api/user-address` | `POST` | `{ label, address, lat, lng }` | Saves customer delivery address and geocoded coordinates in `user_addresses` table. |
| **3b**| Nearby Worker Search | `/api/user-locations/nearby-workers` | `GET` | `?lat=13.08&lng=80.27&service_id=5` | Runs **Haversine formula**, filters online workers (`is_online=1`) within 10km operating radius. |
| **4** | Submit Booking | `/api/app/bookings` | `POST` | `{ user_id, service_id, date, slot, lat, lng, notes }` | Generates random **4-digit OTP**, inserts booking (`status: pending`), dispatches FCM push alerts to nearby workers. |
| **5a**| My Bookings Dashboard | `/api/app/bookings/user/:id` | `GET` | `userId` in URL path | Fetches active and past orders, displays status badges (*Pending*, *Assigned*, *In-Progress*, *Completed*) & 4-digit OTP. |
| **5b**| FCM Token Sync | `/api/app/user/fcm-token` | `POST` | `{ user_id, fcm_token }` | Saves device token in `users` table for real-time push notification alerts. |
| **6** | Live GPS Worker Map | `/api/app/bookings/:id` | `GET` | `bookingId` in URL path | Fetches assigned worker's live GPS coordinates for map pin marker animation. |
| **7a**| View Custom Invoice | `/api/invoice/booking/:id` | `GET` | `bookingId` in URL path | Retrieves custom invoice (spare parts list + extra labor fees + GST) submitted by technician. |
| **7b**| Razorpay Create Order | `/api/payments/create-order` | `POST` | `{ booking_id, amount }` | Calls Razorpay SDK to generate a unique `razorpay_order_id` for checkout. |
| **7c**| Verify Payment | `/api/payments/verify` | `POST` | `{ order_id, payment_id, signature }` | Verifies HMAC SHA256 signature, updates `invoice.status = 'paid'` & `booking.status = 'completed'`. |
| **8** | Submit Star Rating | `/api/dashboard/reviews` | `POST` | `{ booking_id, worker_id, rating, comment }` | Saves review, recalculates worker's average star rating score in `workers` table. |

---

## 👷 PART 2: Worker Mobile App - Internal Execution Flow & API Reference Table

```
+---------------------------------------------------------------------------------------------------+
|                                 WORKER APP DETAILED INTERNAL FLOW                                 |
+---------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
                                      [ 1. Launch & Auth Check ]
                                                  |
                                                  v
                                      [ 2. Duty Switch: ONLINE ]
                                                  |
                                                  v
                                   [ 3. Incoming Job Request Alert ]
                                                  |
                                                  v
                                   [ 4. GPS Navigation to Customer ]
                                                  |
                                                  v
                                    [ 5. On-Site OTP Verification ]
                                                  |
                                                  v
                                    [ 6. Custom Invoice Generation ]
                                                  |
                                                  v
                                    [ 7. Completion & Wallet Balance ]
```

### 👷 Worker App Complete API Execution Table:

| Step | Worker App Feature Screen | Exact API Endpoint Hit | HTTP Method | Request Payload / Query Params | What Happens Behind the Scenes (Backend Logic) |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **1a**| App Launch & Auth | `/api/worker/profile` | `GET` | `Header: Bearer <Worker_JWT>` | Validates worker JWT session and checks KYC verification status. |
| **1b**| Upload KYC Documents | `/api/kyc/submit` | `POST` | `FormData: { aadhaar, pan, bank_details }` | Saves uploaded document files for admin review (`kyc_status: pending`). |
| **2** | Duty Switch (ONLINE) | `/api/worker/:id/status` | `PATCH` | `{ is_online: true }` | Updates `workers.is_online = 1`, enabling backend dispatch engine to route jobs. |
| **3a**| Accept Job Request | `/api/app/bookings/:id/status` | `PATCH` | `{ status: "assigned", worker_id: 7 }` | Binds worker to booking (`status: assigned`), sends FCM push alert to customer. |
| **3b**| Reject Job Request | `/api/app/bookings/:id/reject` | `POST` | `{ worker_id: 7 }` | Re-routes booking dispatch request to the next nearest active worker. |
| **4** | Stream GPS Location | `/api/user-locations/update` | `POST` | `{ worker_id: 7, lat, lng }` | Updates live technician coordinates every 10s for customer map tracking. |
| **5** | Verify 4-Digit OTP | `/api/app/bookings/:id/status` | `PATCH` | `{ status: "in_progress", otp: "4829" }` | Validates `String(stored_otp) === String(input_otp)`. If match -> `status: in_progress`, triggers FCM "Work Started!". |
| **6** | Create Custom Invoice | `/api/app/bookings/:id/invoice` | `POST` | `{ items: [{ description, amount }], labor }` | Calculates total (Parts + Labor), creates `invoices` DB record, sends FCM alert to user. |
| **7a**| Wallet & Earnings | `/api/worker/:id/earnings` | `GET` | `workerId` in URL path | Calculates total completed job payouts, platform commission deductions, and wallet balance. |
| **7b**| View Customer Reviews | `/api/dashboard/reviews/worker/:id` | `GET` | `workerId` in URL path | Retrieves customer ratings, star breakdowns, and written feedback logs. |

---

## 🖥️ PART 3: Admin Web Panel - Internal Execution Flow & API Reference Table

```
+---------------------------------------------------------------------------------------------------+
|                                 ADMIN PANEL DETAILED INTERNAL FLOW                                |
+---------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
                                       [ 1. Admin Authentication ]
                                                  |
                                                  v
                                     [ 2. Real-Time Dashboard View ]
                                                  |
                                                  v
                                    [ 3. KYC Verification Approval ]
                                                  |
                                                  v
                                    [ 4. Master Booking Operations ]
                                                  |
                                                  v
                                    [ 5. Services & Pricing Config ]
                                                  |
                                                  v
                                    [ 6. Financial Payouts & Refunds ]
                                                  |
                                                  v
                                     [ 7. FCM Notification Broadcast ]
```

### 🖥️ Admin Panel Complete API Execution Table:

| Step | Admin Web Module View | Exact API Endpoint Hit | HTTP Method | Request Payload / Query Params | What Happens Behind the Scenes (Backend Logic) |
| :---: | :--- | :--- | :---: | :--- | :--- |
| **1** | Admin Sign In | `/api/auth/login` | `POST` | `{ email, password }` | Authenticates admin credentials, issues admin JWT token & RBAC permissions. |
| **2** | Dashboard Analytics | `/api/dashboard/stats` | `GET` | *None* | Aggregates platform revenue, total bookings, active workers & monthly growth charts. |
| **3a**| Pending KYC List | `/api/kyc/pending` | `GET` | *None* | Fetches submitted worker KYC identity documents awaiting verification. |
| **3b**| Approve/Reject KYC | `/api/kyc/:id/verify` | `PATCH` | `{ status: "approved" \| "rejected", reason }` | Updates worker `kyc_status`. Approval permits worker to go online and take jobs. |
| **4a**| Master Orders List | `/api/booking/all` | `GET` | `?status=pending&date=2026-07-30` | Fetches all system bookings with advanced filters & status badges. |
| **4b**| Re-assign Worker | `/api/booking/:id/assign` | `PATCH` | `{ worker_id: 12 }` | Manual admin override to assign a specific worker to a booking. |
| **5** | Services Catalog | `/api/service` | `POST` / `PUT` | `{ category_id, name, base_price, desc }` | Creates or updates service catalog items, base pricing, and duration. |
| **6a**| Invoices Archive | `/api/invoice/all` | `GET` | *None* | Retrieves all job invoices, spare parts breakdowns, and tax receipts. |
| **6b**| Worker Payouts | `/api/payment/payouts` | `GET` / `POST` | `{ worker_id, amount }` | Tracks platform commission revenue and settles periodic bank payouts to workers. |
| **7** | FCM Push Broadcast | `/api/notification/send` | `POST` | `{ target: "all_users", title, body }` | Dispatches push notification alerts to mobile apps via Firebase Admin SDK. |

---

## ⚙️ PART 4: Backend REST API Processing Pipeline Reference Table

```
+---------------------------------------------------------------------------------------------------+
|                                BACKEND INTERNAL PROCESSING PIPELINE                               |
+---------------------------------------------------------------------------------------------------+
                                                  |
                                                  v
                                     [ 1. HTTP Request Arrival ]
                                                  |
                                                  v
                                     [ 2. CORS & JSON Body Parser ]
                                                  |
                                                  v
                                     [ 3. JWT & RBAC Middleware ]
                                                  |
                                                  v
                                     [ 4. Controller Business Logic ]
                                                  |
                                                  v
                                     [ 5. MySQL Database Execution ]
                                                  |
                                                  v
                                     [ 6. Firebase FCM Event Dispatch ]
                                                  |
                                                  v
                                     [ 7. HTTP JSON Response ]
```

### ⚙️ Backend API Internal Pipeline Complete Table:

| Stage | Pipeline Layer | Internal Helper / Module | Primary Task Executed | Error Handling & Safeguards |
| :---: | :--- | :--- | :--- | :--- |
| **1** | Gateway Entry | Express App (`index.js`) | Receives incoming HTTP REST requests on port 5000. | Returns 404 for invalid API routes. |
| **2** | Security Headers | CORS & Body Parser | Parses JSON bodies, enables cross-origin requests. | Rejects malformed JSON bodies. |
| **3** | Authentication | `token.js` / JWT Middleware | Verifies `Authorization: Bearer <token>` in headers. | Returns 401 Unauthorized if token invalid/expired. |
| **4** | Authorization | Sub-Admin RBAC Guard | Checks user role permissions for requested resource. | Returns 403 Forbidden if permission insufficient. |
| **5a**| Distance Calculation | `geocoder.js` / Haversine | Computes spherical distance between customer & workers. | Filters out workers > max radius (10km). |
| **5b**| OTP Guard | `app.controller.js` | Validates `String(booking.otp) === String(input_otp)`. | Returns 400 Bad Request on OTP mismatch. |
| **5c**| Invoice Calculator | `invoice.controller.js` | Sums line items + labor fee + GST tax + platform commission. | Ensures numeric values; rolls back on error. |
| **5d**| Razorpay Crypto Check| `payment.controller.js` | Verifies HMAC SHA256 hash matching `order_id|payment_id`. | Rejects forged signatures. |
| **6** | Database Mutation | `db.js` (MySQL Pool) | Executes SQL queries (`INSERT`, `UPDATE`, `SELECT`). | Database transactions with automatic rollback on error. |
| **7** | Event Dispatch | `fcm.service.js` | Triggers push alerts via Firebase Admin SDK. | Fallback: logs notification in DB if SDK unavailable. |
| **8** | Response Delivery | `response.js` Helper | Sends structured JSON payload `{ success: true, data }`. | Returns HTTP 200 / 201 / 400 / 500 status codes. |
