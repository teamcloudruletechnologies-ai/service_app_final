# 📊 Service App System - Exact API Vector Flowcharts (Mermaid & Visual Images)

This document provides **Vector Mermaid Flowchart Code** and **Visual Flowchart Diagrams** where **every single box explicitly displays the exact API Endpoint and HTTP Method** directly inside the node.

---

## 📱 1. User Mobile App - Exact API Vector Flowchart

![User Mobile App API Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/user_app_api_flowchart_img_1785407893792.png)

```mermaid
flowchart TD
    U1["1. User Opens App & Auth Session<br><code>GET /api/user/profile</code>"] --> U2["2. Select Service Category<br><code>GET /api/service/categories</code>"]
    U2 --> U3["3. Set Delivery Address & GPS Pin<br><code>POST /api/user-address</code>"]
    
    U3 --> U4{"4. Search Nearby Workers<br><code>GET /api/user-locations/nearby-workers</code>"}
    U4 -- No Workers Found --> U5["Show 'No Workers Nearby'<br>Try Different Location"]
    U5 --> U3
    
    U4 -- Workers Found --> U6["5. Select Slot & Submit Booking<br><code>POST /api/app/bookings</code>"]
    U6 --> U7["6. Show Booking Pending & Display 4-Digit OTP<br><code>GET /api/app/bookings/user/:id</code>"]
    
    U7 --> U8["7. Worker Arrives & Inputs 4-Digit OTP<br><code>PATCH /api/app/bookings/:id/status</code>"]
    U8 --> U9["8. Status Changed to IN_PROGRESS<br>Real-Time Push Alert Executed"]
    
    U9 --> U10["9. Worker Submits Custom Invoice<br><code>POST /api/app/bookings/:id/invoice</code>"]
    U10 --> U11["10. Fetch & Inspect Invoice<br><code>GET /api/invoice/booking/:id</code>"]
    
    U11 --> U12{"11. Choose Payment Method"}
    U12 -- Online Razorpay --> U13["Verify Razorpay Signature<br><code>POST /api/payments/verify</code>"]
    U12 -- Cash on Delivery --> U14["Confirm COD Amount<br><code>PATCH /api/app/bookings/:id/status</code>"]
    
    U13 & U14 --> U15["12. Booking Marked COMPLETED<br><code>status: completed</code>"]
    U15 --> U16["13. Submit 5-Star Rating & Review<br><code>POST /api/dashboard/reviews</code>"]
    U16 --> U17["14. Redirect to Home Screen"]
```

---

## 👷 2. Worker Mobile App - Exact API Vector Flowchart

![Worker Mobile App API Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/worker_app_api_flowchart_img_1785407924957.png)

```mermaid
flowchart TD
    W1["1. Worker Opens App & Check Auth<br><code>GET /api/worker/profile</code>"] --> W2{"2. KYC Already Submitted?"}
    
    W2 -- No --> W3["3. Fill KYC Form & Upload Documents<br><code>POST /api/kyc/submit</code>"]
    W3 --> W4["4. Show 'Under Review' Screen"]
    
    W2 -- Yes, Pending --> W4
    
    W4 --> W5{"5. Admin Reviews KYC<br><code>PATCH /api/kyc/:id/verify</code>"}
    W5 -- Rejected --> W6["6. Worker Notified to Resubmit"]
    W6 --> W3
    
    W5 -- Approved --> W7["7. Worker Profile Marked Verified"]
    W2 -- Yes, Verified --> W7
    
    W7 --> W8["8. Redirect to Worker Dashboard"]
    W8 --> W9["9. Switch Duty Switch to ONLINE<br><code>PATCH /api/worker/:id/status</code>"]
    
    W9 --> W10["10. Receive Incoming Job Request Alert"]
    W10 --> W11{"11. Accept Job Request?"}
    
    W11 -- No --> W12["Re-route Job to Next Worker<br><code>POST /api/app/bookings/:id/reject</code>"]
    W11 -- Yes --> W13["Accept Job - Status ASSIGNED<br><code>PATCH /api/app/bookings/:id/status</code>"]
    
    W13 --> W14["12. Stream GPS Coordinates to Customer<br><code>POST /api/user-locations/update</code>"]
    W14 --> W15["13. Arrive & Submit Customer 4-Digit OTP<br><code>PATCH /api/app/bookings/:id/status</code>"]
    
    W15 --> W16["14. Status Changed to IN_PROGRESS"]
    W16 --> W17["15. Submit Custom Invoice (Parts + Labor)<br><code>POST /api/app/bookings/:id/invoice</code>"]
    W17 --> W18["16. Customer Completes Payment"]
    W18 --> W19["17. Update Wallet Balance & Earnings<br><code>GET /api/worker/:id/earnings</code>"]
```

---

## 🖥️ 3. Admin Web Panel - Exact API Vector Flowchart

![Admin Web Panel API Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/admin_panel_api_flowchart_img_1785407951935.png)

```mermaid
flowchart TD
    A1["1. Admin Opens Web Portal"] --> A2["2. Authenticate Admin Credentials<br><code>POST /api/auth/login</code>"]
    A2 --> A3["3. Dashboard Stats & Analytics Overview<br><code>GET /api/dashboard/stats</code>"]
    
    A3 --> A4{"4. Select Admin Operation Category"}
    
    A4 -- Branch A: KYC Approval --> A5["Fetch Pending Worker KYCs<br><code>GET /api/kyc/pending</code>"]
    A5 --> A6["Preview Aadhaar, PAN & Bank Docs"]
    A6 --> A7{"Approve Worker KYC?"}
    A7 -- Approve --> A8["Set Status Verified<br><code>PATCH /api/kyc/:id/verify</code>"]
    A7 -- Reject --> A9["Set Status Rejected & Send Reason<br><code>PATCH /api/kyc/:id/verify</code>"]
    
    A4 -- Branch B: Orders Manager --> A10["Filter Master Orders List<br><code>GET /api/booking/all</code>"]
    A10 --> A11{"Re-assign Technician?"}
    A11 -- Yes --> A12["Manual Worker Assignment Override<br><code>PATCH /api/booking/:id/assign</code>"]
    A11 -- No --> A13["Inspect Order Status & Invoice Logs"]
    
    A4 -- Branch C: Financial Settlement --> A14["Inspect Razorpay & COD Invoices<br><code>GET /api/invoice/all</code>"]
    A14 --> A15["Settle Worker Bank Payouts<br><code>POST /api/payment/payouts</code>"]
    
    A4 -- Branch D: Push Marketing --> A16["Broadcast FCM Push Notification<br><code>POST /api/notification/send</code>"]
    
    A8 & A9 & A12 & A13 & A15 & A16 --> A17["Admin Operation Completed<br>Dashboard Refreshed"]
```

---

## ⚙️ 4. Backend Processing Pipeline - Exact API Vector Flowchart

```mermaid
flowchart TD
    P1["1. Incoming HTTP REST Request<br>Port 5000"] --> P2["2. Express Body Parser & Security Headers<br><code>CORS Middleware</code>"]
    P2 --> P3{"3. Route Authentication Check"}
    
    P3 -- Protected Route --> P4["Verify Authorization Header<br><code>JWT Authentication Middleware</code>"]
    P4 --> P5{"Valid JWT Session Token?"}
    P5 -- Invalid --> P6["Return HTTP 401 Unauthorized JSON"]
    P5 -- Valid --> P7["Verify Sub-Admin Permissions<br><code>RBAC Authorization Guard</code>"]
    
    P3 -- Public Route --> P8["Route Controller Execution"]
    P7 --> P8
    
    P8 --> P9{"Execute Specific API Logic"}
    
    P9 -- Nearby Workers Search --> P10["Run Haversine Distance Formula<br><code>GET /api/user-locations/nearby-workers</code>"]
    P9 -- OTP Verification --> P11["Check String Match: stored_otp == input_otp<br><code>PATCH /api/app/bookings/:id/status</code>"]
    P9 -- Invoice Calculation --> P12["Sum Spare Parts + Labor + GST Tax<br><code>POST /api/app/bookings/:id/invoice</code>"]
    P9 -- Payment Signature --> P13["Verify HMAC SHA256 Crypto Hash<br><code>POST /api/payments/verify</code>"]
    
    P10 & P11 & P12 & P13 --> P14["Execute SQL Database Mutations<br><code>MySQL DB Pool (db.js)</code>"]
    P14 --> P15["Dispatch Real-Time Push Alerts<br><code>Firebase FCM SDK (fcm.service.js)</code>"]
    P15 --> P16["Return Structured HTTP 200 Success JSON<br><code>response.js Helper</code>"]
```
