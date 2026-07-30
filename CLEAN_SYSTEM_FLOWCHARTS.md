# 📊 Service App System - Clean System Flowcharts (User, Worker & Admin)

This document provides **Clean System Flowcharts** matching your exact decision-tree flowchart style for:
1. 📱 **User Mobile App Flowchart**
2. 👷 **Worker Mobile App Flowchart**
3. 🖥️ **Admin Web Panel Flowchart**

---

## 📱 1. User Mobile App - Complete Execution Flowchart

![User Mobile App Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/user_app_flowchart_diagram_1785407341185.png)

### 🔹 User App Vector Flowchart Code (Mermaid):

```mermaid
flowchart TD
    U1[User opens app] --> U2[Login / Register]
    U2 --> U3[Select Service Category]
    U3 --> U4[Set Delivery Location & GPS Pin]
    
    U4 --> U5{Nearby Workers Available?}
    U5 -- No --> U6[Show 'No Workers Nearby' Screen]
    U6 --> U4
    
    U5 -- Yes --> U7[Select Date & Time Slot]
    U7 --> U8[Submit Booking - POST /api/app/bookings]
    U8 --> U9[Show 'Booking Pending' & Display 4-Digit OTP]
    
    U9 --> U10[Worker accepts & arrives on site]
    U10 --> U11[Worker enters 4-Digit OTP]
    U11 --> U12[Status changes to 'In Progress']
    
    U12 --> U13[Worker submits Custom Invoice]
    U13 --> U14{Choose Payment Method?}
    
    U14 -- Online Razorpay --> U15[Launch Razorpay Gateway Checkout]
    U14 -- Cash on Delivery --> U16[Confirm COD Payment Amount]
    
    U15 & U16 --> U17[Mark Booking 'Completed']
    U17 --> U18[Submit 5-Star Rating & Review]
    U18 --> U19[Redirect to Home Screen]
```

---

## 👷 2. Worker Mobile App - Complete Execution Flowchart

![Worker Mobile App Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/worker_app_flowchart_diagram_1785407363884.png)

### 🔹 Worker App Vector Flowchart Code (Mermaid):

```mermaid
flowchart TD
    W1[Worker opens app] --> W2[Login / Register]
    W2 --> W3{KYC already submitted?}
    
    W3 -- No --> W4[Worker fills KYC form: Aadhaar, PAN, Bank, Photo]
    W4 --> W5[Upload documents]
    W5 --> W6[Submit KYC - POST /api/kyc/submit]
    W6 --> W7[Show 'Under Review' screen]
    
    W3 -- Yes, Pending --> W7
    
    W7 --> W8{Admin reviews KYC}
    W8 -- Rejected --> W9[Worker notified - resubmit documents]
    W9 --> W4
    
    W8 -- Approved --> W10[Worker profile marked 'Verified']
    W3 -- Yes, Verified --> W10
    
    W10 --> W11[Redirect to Worker Dashboard]
    W11 --> W12[Switch Duty Switch to ONLINE]
    W12 --> W13[Receive Incoming Job Alert]
    
    W13 --> W14{Accept Job Request?}
    W14 -- No --> W15[Re-route job to next nearby worker]
    W14 -- Yes --> W16[Booking status marked 'Assigned']
    
    W16 --> W17[Launch GPS Navigation Map to Customer]
    W17 --> W18[Arrive at site & prompt customer for 4-Digit OTP]
    W18 --> W19[Submit OTP - PATCH /api/app/bookings/:id/status]
    
    W19 --> W20[Status marked 'In Progress']
    W20 --> W21[Worker creates Custom Invoice - Parts + Labor]
    W21 --> W22[Customer completes payment]
    W22 --> W23[Wallet balance updated with earnings]
```

---

## 🖥️ 3. Admin Web Panel - Operations & Management Flowchart

![Admin Web Panel Flowchart Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/admin_panel_flowchart_diagram_1785407385580.png)

### 🔹 Admin Panel Vector Flowchart Code (Mermaid):

```mermaid
flowchart TD
    A1[Admin opens web portal] --> A2[Enter Credentials - POST /api/auth/login]
    A2 --> A3[Dashboard Overview - Revenue & Stats]
    
    A3 --> A4{Select Admin Operation?}
    
    A4 -- KYC Management --> A5[Fetch Pending Worker KYCs]
    A5 --> A6[Preview Aadhaar, PAN & Bank Proofs]
    A6 --> A7{Approve Worker?}
    A7 -- Yes --> A8[Set status 'Verified' & Enable Duty Toggle]
    A7 -- No --> A9[Set status 'Rejected' & Send Feedback]
    
    A4 -- Booking Operations --> A10[Filter Master Orders List]
    A10 --> A11{Re-assign Worker?}
    A11 -- Yes --> A12[Manual Worker Assignment Override]
    A11 -- No --> A13[Inspect Booking Timelines & Invoices]
    
    A4 -- Financial Control --> A14[Inspect Razorpay Payments & COD Collections]
    A14 --> A15[Settle Weekly Worker Bank Payouts]
    
    A4 -- Marketing & Push --> A16[Create FCM Push Notification Broadcast]
    A16 --> A17[Dispatch Push Alert to User/Worker Apps]
    
    A8 & A9 & A12 & A13 & A15 & A17 --> A18[Dashboard Updated]
```
