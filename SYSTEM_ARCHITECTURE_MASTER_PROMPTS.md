# 🎨 Service App System - Professional Master Architecture Prompts & Blueprint

This document provides **Master AI Prompts** and **Ready-to-Render Diagram Blueprints** designed to produce high-definition, professional software engineering architecture diagrams for your **Service App Platform**.

---

## 🚀 1. Master AI Image Generation Prompts (For Midjourney / DALL-E 3 / Gemini)

You can copy and paste these master prompts directly into AI image generators (such as Midjourney `v6`, DALL-E 3, or Gemini) to generate professional, ultra-crisp software architecture diagrams.

### 📱 Prompt 1: User Mobile App Architecture
```text
Ultra-professional software architecture diagram for an On-Demand Service Customer Mobile App built with Flutter. Clean isometric dark slate theme with glowing cyan and electric blue accents. Displays 4 distinct architectural layers: 1. UI Layer (Home Discovery, Location Picker, Booking Form, Live Tracking Map, Custom Invoice Viewer, Razorpay Checkout), 2. State Management Layer (AuthProvider, BookingProvider, LocationProvider), 3. Data & Local Persistence Layer (Secure Storage, SharedPreferences), 4. Network Layer (ApiService, HTTP REST Client). Connectors show clean directional arrows, API endpoint labels, and crisp typography. 8k resolution, vector UI aesthetics, tech presentation ready, no blur.
```

### 👷 Prompt 2: Worker Mobile App Architecture
```text
Professional software architecture diagram for a Field Technician Mobile App built with Flutter. Dark mode background with neon green and gold highlights. Illustrates 4 core modules: 1. Field Operations (Duty Switch Online/Offline, Incoming Dispatch Pop-up, GPS Navigation Map, 4-Digit OTP Verifier), 2. Custom Billing Module (Spare Parts Calculator, Labor Fee Input, Invoice Submission), 3. Financial Module (Earnings Wallet, Commission Deductions, Payout Logs), 4. KYC Onboarding Module (Aadhaar, PAN Card, Bank Details Verification). Clean UML component layout with sharp vector lines and high-contrast labels. 8k resolution, corporate tech diagram.
```

### 🖥️ Prompt 3: Admin Web Panel Architecture
```text
High-tech software component architecture diagram for an Enterprise Admin Portal built with React and Vite. Sleek dark charcoal background with warm amber and emerald accents. Features a multi-tiered dashboard structure: 1. Analytics & Real-Time Monitoring (Revenue Widgets, Live Order Stream, Active Worker Map), 2. User & Worker Management (KYC Verification Approval, Account Block/Unblock), 3. Order & Financial Control (Master Booking Overrides, Razorpay Settlements, Invoice Archives), 4. Configuration & Security (Services Catalog, Banner Manager, FCM Broadcast Engine, Sub-Admin RBAC Permissions). Crisp technical visual style with clean connecting nodes and clean iconography.
```

### ⚙️ Prompt 4: Backend API & Micro-Services Architecture
```text
Comprehensive backend cloud architecture diagram for a Node.js Express REST API server and MySQL Database. Cyberpunk dark blue aesthetics with vibrant orange, purple, and green glowing pipeline channels. Shows data flow from Mobile & Web Clients -> Express Security Middleware (CORS, JWT Token Auth, Sub-Admin RBAC) -> Controller Logic (Haversine Distance Calculator, 4-Digit OTP Match Engine, Razorpay HMAC Crypto Verifier) -> MySQL Database Persistence -> Firebase Cloud Messaging (FCM) Real-Time Push Dispatcher -> External Integrations (Razorpay Payment Gateway, Google Maps Geocoding). High resolution, crisp technical infographic, vector blueprint style.
```

---

## 📐 2. Ready-to-Render Vector Mermaid Diagrams (Copy & Paste Anywhere)

You can copy these Mermaid visual code blocks into any Markdown viewer, GitHub, Notion, or Mermaid Live Editor ([mermaid.live](https://mermaid.live)) to render **100% sharp, zoomable vector diagrams**.

### 📱 User App Flow Diagram
```mermaid
graph LR
    classDef ui fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#fff;
    classDef provider fill:#0f172a,stroke:#818cf8,stroke-width:2px,color:#fff;
    classDef api fill:#0284c7,stroke:#38bdf8,stroke-width:2px,color:#fff;

    subgraph User Mobile App (Flutter)
        UI1[Home Screen]:::ui --> UI2[Location Picker]:::ui
        UI2 --> UI3[Nearby Workers]:::ui
        UI3 --> UI4[Submit Booking]:::ui
        UI4 --> UI5[My Bookings & OTP 4829]:::ui
        UI5 --> UI6[Live GPS Map]:::ui
        UI6 --> UI7[Invoice & Razorpay]:::ui
    end

    subgraph State Management
        P1[AuthProvider]:::provider
        P2[BookingProvider]:::provider
    end

    subgraph Backend API
        API1[GET /api/user-locations/nearby-workers]:::api
        API2[POST /api/app/bookings]:::api
        API3[POST /api/payments/verify]:::api
    end

    UI3 --> P2 --> API1
    UI4 --> P2 --> API2
    UI7 --> P1 --> API3
```

### 👷 Worker App Flow Diagram
```mermaid
graph LR
    classDef worker fill:#14532d,stroke:#4ade80,stroke-width:2px,color:#fff;
    classDef backend fill:#064e3b,stroke:#22c55e,stroke-width:2px,color:#fff;

    subgraph Worker Mobile App (Flutter)
        W1[Duty Switch: ONLINE]:::worker --> W2[Job Alert Pop-up]:::worker
        W2 -->|Accept Job| W3[GPS Navigation]:::worker
        W3 --> W4[Verify 4-Digit OTP]:::worker
        W4 --> W5[Custom Invoice Builder]:::worker
        W5 --> W6[Earnings Wallet]:::worker
    end

    subgraph Backend Engine
        B1[PATCH /api/worker/:id/status]:::backend
        B2[PATCH /api/app/bookings/:id/status]:::backend
        B3[POST /api/app/bookings/:id/invoice]:::backend
    end

    W1 --> B1
    W4 -->|otp: 4829| B2
    W5 -->|Parts + Labor| B3
```

---

## 📄 3. Executive Architecture Presentation Blueprint

### 🌟 Project Executive Summary
* **Platform Name:** Service App (On-Demand Home Service Platform)
* **Architecture Style:** Decoupled RESTful API Client-Server Architecture
* **Frontend Tech Stack:** Flutter (User & Worker Mobile Apps) + React/Vite (Admin Web Portal)
* **Backend Tech Stack:** Node.js, Express.js, MySQL Database Pool, Firebase Admin FCM SDK, Razorpay Payment Gateway API

### 🛡️ Security & Integrity Mechanisms
1. **JWT Token Authentication:** Stateful session authorization across mobile & web.
2. **4-Digit OTP Guard:** On-site service start verification ensuring technicians cannot start jobs without customer authorization.
3. **Razorpay HMAC SHA256 Verification:** Cryptographic signature verification protecting against fraudulent payment payloads.
4. **Sub-Admin RBAC:** Granular per-module permissions safeguarding administrative operations.
