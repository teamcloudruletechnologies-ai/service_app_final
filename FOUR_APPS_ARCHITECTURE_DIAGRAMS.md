# 🏛️ Service App System - 4 Main Components Architecture Diagrams

This document provides dedicated software architecture diagrams and detailed component breakdowns for the 4 core applications of the platform:
1. 📱 **User Mobile App Architecture** (Flutter)
2. 👷 **Worker Mobile App Architecture** (Flutter)
3. 🖥️ **Admin Web Panel Architecture** (React / Vite)
4. ⚙️ **Backend REST API & Infrastructure Architecture** (Node.js / Express / MySQL / FCM / Razorpay)

---

## 📱 1. User Mobile App Architecture (Flutter)

The User Mobile App is structured using Flutter Provider for state management, HTTP service layer for API communication, and modular screens.

```mermaid
graph TD
    subgraph UI & Navigation Layer
        A1[Main Shell & Bottom Navbar]
        A2[Home Screen & Service Search]
        A3[Location Picker & Address Manager]
        A4[Service Detail View]
        A5[Nearby Worker Discovery]
        A6[Booking Form & Time Slot Selector]
        A7[My Bookings & OTP Display Badge]
        A8[Live GPS Worker Tracker]
        A9[Custom Invoice Viewer]
        A10[Razorpay Payment Checkout]
        A11[Rating & Review Modal]
        A12[Helpdesk & Support Center]
    end

    subgraph State Management & Controllers (Provider)
        B1[AuthProvider - JWT & User Session]
        B2[BookingProvider - Active & Past Orders]
        B3[LocationProvider - Map Coordinates & Saved Addresses]
        B4[NotificationProvider - FCM Push Tokens]
    end

    subgraph Data & Network Layer
        C1[ApiService - HTTP Request Client]
        C2[ApiConfig - Base URL & Headers]
        C3[LocalStorage - Secure Token Storage]
    end

    A2 & A3 & A5 & A6 & A7 --> B1 & B2 & B3 & B4
    B1 & B2 & B3 & B4 --> C1
    C1 --> C2 & C3
    C1 -->|REST API Requests| API[Backend Node.js API]
```

### 🔹 Key Responsibilities & Data Flow:
* **Service Discovery:** Queries backend for categories, services, pricing, and active banners.
* **Geocoding & Location:** Integrates Google Maps API for coordinate pin-drop and saved address selection.
* **Order Lifecycle & OTP:** Displays real-time booking status updates and presents a **4-digit Job Start OTP** to give to the technician.
* **Payment Integration:** Launches Razorpay Checkout SDK for online transactions or confirms Cash on Delivery (COD).

---

## 👷 2. Worker Mobile App Architecture (Flutter)

The Worker Mobile App enables field technicians to manage duty availability, accept jobs, verify start OTPs, generate custom invoices, and navigate to customer locations.

```mermaid
graph TD
    subgraph UI & Navigation Layer
        W1[Main Navigation Shell]
        W2[Worker Dashboard & Duty Toggle Switch]
        W3[Incoming Job Alert Dialog]
        W4[Job Detail Screen & OTP Input Modal]
        W5[In-App GPS Navigation & Route Map]
        W6[Custom Invoice Builder]
        W7[Today's Schedule & Work History]
        W8[KYC Document Upload Portal]
        W9[Earnings Wallet & Payout Settlement]
        W10[Customer Reviews & Ratings]
        W11[Worker Profile & Skill Category Settings]
    end

    subgraph State Management & Providers
        WB1[WorkerAuthProvider - Session & Duty Toggle]
        WB2[WorkerBookingProvider - Active Jobs & Status Pipeline]
        WB3[InvoiceProvider - Line Items & Spare Parts Calculations]
        WB4[KycProvider - Document Upload Status]
    end

    subgraph Data & Services Layer
        WC1[WorkerApiService - HTTP Engine]
        WC2[FcmService - Background Push Listener]
        WC3[LocationService - Real-Time GPS Tracking]
    end

    W2 & W3 & W4 & W5 & W6 & W8 --> WB1 & WB2 & WB3 & WB4
    WB1 & WB2 & WB3 & WB4 --> WC1 & WC2 & WC3
    WC1 & WC3 -->|REST API & Geolocation| API[Backend Node.js API]
```

### 🔹 Key Responsibilities & Data Flow:
* **Duty Status Management:** Toggles worker availability (`online` / `offline`) to start or stop receiving job dispatches.
* **Job Execution & OTP:** Receives push job alerts, accepts assignments, and inputs the customer's 4-digit OTP to start the job.
* **Custom Billing:** Allows technicians to add extra labor fees and spare part line items to calculate and submit final invoices.
* **Field Navigation:** Streams GPS coordinates for live customer tracking and turn-by-turn route directions.

---

## 🖥️ 3. Admin Web Panel Architecture (React / Vite)

The Admin Web Panel is a single-page web app (SPA) built with React and CSS design tokens, providing complete platform administration.

```mermaid
graph TD
    subgraph Web UI Components & Views
        M1[Sidebar Navigation Bar]
        M2[Topbar & Admin Header]
        M3[Analytics Dashboard View]
        M4[Users Management View]
        M5[Workers Management View]
        M6[KYC Document Verification View]
        M7[Master Bookings Manager]
        M8[Invoices Archive View]
        M9[Financial Payments & Payouts View]
        M10[Service Catalog & Pricing View]
        M11[Banners & Offer Slider View]
        M12[Notifications & FCM Broadcast View]
        M13[Roles & RBAC Access Control]
        M14[Global Settings & Maintenance View]
        M15[Locations & Zone Coverage View]
    end

    subgraph Frontend Logic Layer
        F1[State Hooks & Tab Routers]
        F2[API Service Layer - Axios / Fetch]
        F3[Polling & Real-time Booking Toast Alert]
        F4[Local Token Session Manager]
    end

    M3 & M4 & M5 & M6 & M7 & M8 & M9 & M10 & M11 & M12 & M13 & M14 & M15 --> F1
    F1 --> F2 & F3 & F4
    F2 -->|Admin REST API Requests| API[Backend Node.js API]
```

### 🔹 Key Responsibilities & Data Flow:
* **Platform Operations:** Full oversight of users, workers, KYC approvals, service categories, and promotional banners.
* **Live Monitoring:** Real-time polling and toast alerts for incoming bookings and system activity.
* **Financial & Settlement Oversight:** Tracking Razorpay payment transactions, COD collections, platform commissions, and worker payouts.
* **Security & Access:** Role-Based Access Control (RBAC) to configure sub-admin staff permissions.

---

## ⚙️ 4. Backend REST API & Infrastructure Architecture

The Backend API is built on Node.js and Express with modular routing, MySQL relational database storage, Firebase Cloud Messaging (FCM) integration, and Razorpay payment handling.

```mermaid
graph TD
    subgraph Client Entry Points
        E1[User Mobile App]
        E2[Worker Mobile App]
        E3[Admin Web Portal]
    end

    subgraph Express Middleware Layer
        MW1[CORS & Body Parser Middleware]
        MW2[JWT Token Authentication Middleware]
        MW3[Role-Based Authorization Middleware]
        MW4[Error Handler & Logger Middleware]
    end

    subgraph Controller & Route Modules
        R1[auth.routes - Login, Register, OTP]
        R2[app.routes - Core Booking & Worker Jobs]
        R3[user.routes & worker.routes - Account CRUD]
        R4[kyc.routes - Document Verification]
        R5[invoice.routes & payment.routes - Billing & Razorpay]
        R6[service.routes & banner.routes - Catalog & Banners]
        R7[notification.routes - Push Alerts]
        R8[subAdmin.routes - Staff Permissions]
        R9[location.routes - Coverage Zones & Distance Matrix]
    end

    subgraph Service & Utility Modules
        S1[fcm.service.js - Firebase Admin Push SDK]
        S2[payment.controller.js - Razorpay SDK & HMAC Verification]
        S3[geocoder.js - Haversine Distance & Google Geocoding]
        S4[fileUpload.js - Multer File Upload Helper]
    end

    subgraph Database & Cloud Infrastructure
        DB[(MySQL Database)]
        FCM[Firebase Cloud Messaging Engine]
        RP[Razorpay Payment Gateway API]
    end

    E1 & E2 & E3 -->|HTTP Requests| MW1
    MW1 --> MW2 & MW3 --> R1 & R2 & R3 & R4 & R5 & R6 & R7 & R8 & R9
    R1 & R2 & R3 & R4 & R5 & R6 & R7 & R8 & R9 --> S1 & S2 & S3 & S4
    R1 & R2 & R3 & R4 & R5 & R6 & R7 & R8 & R9 -->|SQL Queries| DB
    S1 -->|Push Alerts| FCM
    S2 -->|Orders & Verification| RP
```

### 🔹 Key Responsibilities & Data Flow:
* **Multi-Role Authentication:** Phone OTP validation, bcrypt password hashing, and JWT token issue.
* **Distance Matrix Engine:** Computes distance in kilometers using Haversine equations to find nearby active workers.
* **Billing & Tax Calculator:** Formulates custom invoice totals with line items, labor fees, platform commissions, and GST taxes.
* **FCM Push Notification Dispatch:** Triggers real-time push alerts to mobile devices upon state transitions.
