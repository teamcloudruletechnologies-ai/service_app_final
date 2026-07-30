# 📐 Service App System - Professional Software Engineering Diagrams

This document contains standard, professional UML software engineering diagrams for the Service App system:
1. **Booking Lifecycle State Machine Diagram** (UML State Diagram)
2. **Database Class & Entity-Relationship Diagram** (UML Class/ERD Diagram)
3. **End-to-End Inter-Component Sequence Diagram** (UML Sequence Diagram)
4. **Full-Stack System Component Architecture Diagram** (UML Component Architecture)

---

## 🔄 1. Booking Lifecycle State Machine Diagram (UML State Diagram)

This state machine models the lifecycle transitions of a booking from creation to completion or cancellation.

![Booking Lifecycle State Machine Diagram](C:/Users/Admin/.gemini/antigravity/brain/d8d82b34-4fba-4235-9833-e186777d75dc/booking_lifecycle_state_diagram_1785402169225.png)

```mermaid
stateDiagram-v2
    [*] --> Pending : User Creates Booking
    
    state Pending {
        [*] --> SearchingWorker
        SearchingWorker --> WorkerNotified : Nearby Worker Found (Haversine Matrix)
    }

    Pending --> Assigned : Worker Accepts Job Offer
    Pending --> Cancelled : User Cancels / No Worker Available

    state Assigned {
        [*] --> WorkerEnRoute
        WorkerEnRoute --> ArrivedAtLocation : GPS Navigation
    }

    Assigned --> InProgress : Worker Inputs Correct 4-Digit OTP
    Assigned --> Cancelled : User/Worker Cancels Before Start

    state InProgress {
        [*] --> ServiceInspection
        ServiceInspection --> RepairWork
        RepairWork --> InvoiceGenerated : Worker Submits Custom Invoice (Spare Parts + Labor)
    }

    InvoiceGenerated --> Completed : User Pays via Razorpay / Cash on Delivery
    
    Completed --> [*]
    Cancelled --> [*]
```

---

## 🗄️ 2. Database Class & Entity-Relationship Diagram (UML Class/ERD)

This class diagram defines the data models, attributes, primary/foreign keys, and 1:N / N:M relationships across MySQL tables.

```mermaid
classDiagram
    class User {
        +int id PK
        +string name
        +string phone
        +string email
        +double lat
        +double lng
        +string fcm_token
        +string status
        +createBooking()
        +makePayment()
    }

    class Worker {
        +int id PK
        +string name
        +string phone
        +string skills
        +boolean is_online
        +double rating
        +string kyc_status
        +string fcm_token
        +acceptJob()
        +verifyOtp()
        +submitInvoice()
    }

    class ServiceCategory {
        +int id PK
        +string name
        +string image_url
        +boolean is_active
    }

    class Service {
        +int id PK
        +int category_id FK
        +string name
        +double base_price
        +string description
    }

    class Booking {
        +int id PK
        +int user_id FK
        +int worker_id FK
        +int service_id FK
        +string status
        +string otp
        +string address
        +double lat
        +double lng
        +datetime booking_date
    }

    class Invoice {
        +int id PK
        +int booking_id FK
        +double amount
        +json spare_parts_json
        +string status
    }

    class Payment {
        +int id PK
        +int invoice_id FK
        +string razorpay_order_id
        +string razorpay_payment_id
        +double amount
        +string method
        +string status
    }

    class Review {
        +int id PK
        +int booking_id FK
        +int user_id FK
        +int worker_id FK
        +int rating
        +string comment
    }

    User "1" -- "0..*" Booking : places
    Worker "1" -- "0..*" Booking : handles
    ServiceCategory "1" -- "1..*" Service : contains
    Service "1" -- "0..*" Booking : fulfills
    Booking "1" -- "0..1" Invoice : generates
    Invoice "1" -- "0..1" Payment : settles
    Booking "1" -- "0..1" Review : evaluates
    User "1" -- "0..*" Review : writes
    Worker "1" -- "0..*" Review : receives
```

---

## ⏱️ 3. End-to-End Inter-Component Sequence Diagram (UML Sequence)

This sequence diagram depicts the chronological interaction between the User App, Worker App, Backend API, Database, Razorpay Gateway, and Firebase FCM.

```mermaid
sequenceDiagram
    autonumber
    actor User as User Mobile App
    participant API as Backend Node.js API
    participant DB as MySQL Database
    participant FCM as Firebase FCM Service
    actor Worker as Worker Mobile App
    participant Pay as Razorpay Gateway

    User->>API: POST /api/app/bookings (Service, Location)
    API->>DB: Calculate Distance & Insert Booking (Status: pending)
    DB-->>API: Booking ID: 101, OTP: 4829
    API->>FCM: Dispatch Push Alert ("New Job Offer!")
    FCM-->>Worker: Alert Notification
    
    Worker->>API: PATCH /api/app/bookings/101/status (status: assigned)
    API->>DB: Update Worker Assignment
    API->>FCM: Push Alert to User ("Worker Accepted!")
    
    Worker->>Worker: Arrives on Site & Prompts for OTP
    User-->>Worker: Communicates 4-digit OTP (4829)
    Worker->>API: PATCH /api/app/bookings/101/status (otp: 4829)
    API->>DB: Validate OTP (String Match) & Update status: in_progress
    API->>FCM: Push Alert to User ("Work Started!")
    
    Worker->>API: POST /api/app/bookings/101/invoice (Spare Parts + Labor)
    API->>DB: Insert Invoice Record & Calculate Total (₹399)
    API->>FCM: Push Alert to User ("Invoice Ready: ₹399")
    
    User->>Pay: Launch Razorpay Checkout (₹399)
    Pay-->>User: Payment Signature Success
    User->>API: POST /api/payments/verify (Signature Payload)
    API->>API: Verify HMAC Signature
    API->>DB: Update Booking (status: completed) & Invoice (status: paid)
    API-->>User: Success Response & Receipt
```

---

## 🏗️ 4. Full-Stack System Component Architecture Diagram

This component diagram displays the system boundaries, frontend client apps, API layer, database, and 3rd party external services.

```mermaid
graph TD
    subgraph Client Layer (Frontend & Mobile)
        A1[User Flutter Mobile App]
        A2[Worker Flutter Mobile App]
        A3[Admin Web Portal - React/Vite]
    end

    subgraph API & Backend Gateway Layer
        B1[Node.js / Express REST API]
        B2[JWT Authentication & RBAC Middleware]
        B3[Haversine Distance Matrix Engine]
        B4[Billing & GST Calculation Engine]
    end

    subgraph Persistence Layer
        C1[(MySQL Relational Database)]
    end

    subgraph External Cloud Services
        D1[Razorpay Payment Gateway]
        D2[Firebase Cloud Messaging - FCM]
        D3[Google Maps Geocoding API]
    end

    A1 -->|REST HTTP / JSON| B1
    A2 -->|REST HTTP / JSON| B1
    A3 -->|REST HTTP / JSON| B1

    B1 --> B2
    B1 --> B3
    B1 --> B4

    B1 -->|SQL Queries| C1
    
    B1 -->|SDK Payments| D1
    B1 -->|Push Dispatch| D2
    B1 -->|Geocoding| D3
```
