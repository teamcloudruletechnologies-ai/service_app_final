# 🛠️ Service App System - Core 40 Modules Documentation

This document provides a detailed breakdown and functional description of the **40 Core Modules** powering the **Service App Platform** across the User Mobile App, Worker Mobile App, Admin Web Portal, and Backend REST API Engine.

---

## 📱 PART 1: User Mobile App Modules (Modules 01 – 10)

### 01. Home Screen & Category Grid
* **Layer:** User Mobile App (`user_app/lib/screens/home_screen.dart`)
* **Description:** The primary landing experience for customers. It features a real-time location header displaying the delivery address, a search bar to instantly query services, promotional offer banners and carousels, a grid of main service categories (e.g., Electrician, Plumbing, AC Service), popular service recommendations, and quick rebooking shortcuts.

### 02. Location Picker & Address Management
* **Layer:** User Mobile App (`user_app/lib/screens/location_picker_screen.dart`)
* **Description:** An interactive map integration (Google Maps) allowing users to set precise delivery coordinates via pin-drop or GPS auto-detection. It manages saved customer addresses (labeled as Home, Work, or Other), checks operational zone coverage, and calculates delivery metrics.

### 03. Service Catalog & Detail View
* **Layer:** User Mobile App (`user_app/lib/screens/service_detail_screen.dart`)
* **Description:** Displays in-depth information about selected services. It includes itemized pricing, inclusions and exclusions, safety guidelines, average completion time, and verified customer star ratings and reviews for the service.

### 04. Nearby Worker Discovery & Assignment
* **Layer:** User Mobile App (`user_app/lib/screens/nearby_workers_screen.dart`)
* **Description:** A real-time search engine that locates active service technicians operating within the customer's geographic radius. It displays worker profiles, distance (in km), star ratings, and completed job counts, allowing users to pick a technician or auto-assign the nearest available partner.

### 05. Booking Form & Slot Scheduler
* **Layer:** User Mobile App (`user_app/lib/screens/booking_form_screen.dart`)
* **Description:** Configures service requests by allowing customers to pick preferred service dates, time slots, saved addresses, and add custom problem descriptions or photo attachments. Initiates instant booking confirmation without requiring upfront payment.

### 06. My Bookings & OTP Generator
* **Layer:** User Mobile App (`user_app/lib/screens/bookings_screen.dart`)
* **Description:** A centralized order dashboard organized into Active, Scheduled, and Past orders. It tracks real-time status badges (*Pending*, *Assigned*, *In-Progress*, *Completed*) and generates a unique **4-digit Job Start OTP** for the customer to share with the technician upon arrival.

### 07. Live Worker Tracking Map
* **Layer:** User Mobile App (`user_app/lib/screens/worker_tracking_map_screen.dart`)
* **Description:** A real-time GPS tracking interface that visualizes the assigned technician's movement towards the customer's address on a live map. Provides dynamic Estimated Time of Arrival (ETA) updates and direct one-tap Call/SMS action buttons.

### 08. Digital Invoice Inspection
* **Layer:** User Mobile App (`user_app/lib/screens/invoice_screen.dart`)
* **Description:** Presents itemized invoices submitted by the worker after on-site inspection. Displays cost breakdowns (inspection fees, spare parts, extra labor, taxes, and promotional discounts) along with a "Pay Now" trigger.

### 09. Razorpay & COD Checkout
* **Layer:** User Mobile App (`user_app/lib/screens/payment_screen.dart`)
* **Description:** A secure checkout gateway supporting online payments via Razorpay (UPI, Cards, NetBanking) and Cash on Delivery (COD). Validates payment signatures, issues digital receipts, and updates booking statuses instantly.

### 10. Post-Service Ratings & Reviews
* **Layer:** User Mobile App (`user_app/lib/screens/rating_screen.dart`)
* **Description:** A post-service feedback screen where customers submit 1-to-5 star ratings, evaluate technician punctuality and behavior, and write text reviews to maintain platform quality standards.

---

## 👷 PART 2: Worker Mobile App Modules (Modules 11 – 20)

### 11. Worker Duty Toggle & Dashboard
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_dashboard_screen.dart`)
* **Description:** The technician's operational control center. Includes an **Online/Offline Duty Toggle** switch, daily earnings metrics, job completion counts, performance ratings, and incoming job request alerts.

### 12. Incoming Job Request & Acceptance
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_dashboard_screen.dart`)
* **Description:** Displays incoming service dispatch pop-ups with customer location, service type, and estimated earnings. Allows workers to **Accept** or **Reject** job offers in real time.

### 13. Customer Location GPS Navigation
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_in_app_navigation_screen.dart`)
* **Description:** Provides turn-by-turn map directions to the customer's doorstep using integrated GPS mapping, displaying live ETA, distance, and direct customer contact shortcuts.

### 14. Job Start OTP Verification
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_booking_detail_screen.dart`)
* **Description:** Prompts the technician to enter the customer's **4-digit Job Start OTP** upon arrival. Validates the code via backend API before transitioning the job status to *In-Progress*.

### 15. Custom Invoice & Spare Parts Builder
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_create_invoice_screen.dart`)
* **Description:** A dynamic billing tool used after job inspection. Enables workers to add spare parts, extra labor charges, calculate totals, and submit the final invoice directly to the customer's app.

### 16. Today's Work Schedule & History
* **Layer:** Worker Mobile App (`worker_app/lib/screens/work_history_screen.dart`)
* **Description:** A chronological timeline of today's assigned jobs and an archive of past completed jobs, including earning payouts, customer notes, and service dates.

### 17. KYC Document Upload Portal
* **Layer:** Worker Mobile App (`worker_app/lib/screens/worker_kyc_screen.dart`)
* **Description:** An onboarding module for submitting government identity documents (Aadhaar, PAN Card, Driving License), bank account details, and trade certificates, while tracking real-time verification status.

### 18. Earnings & Payout Wallet
* **Layer:** Worker Mobile App (`worker_app/lib/screens/earnings_screen.dart`)
* **Description:** A financial portal detailing daily, weekly, and monthly earnings, platform commission deductions, tips, wallet balance, and bank transfer settlement histories.

### 19. Customer Reviews & Feedback
* **Layer:** Worker Mobile App (`worker_app/lib/screens/reviews_screen.dart`)
* **Description:** Displays customer ratings, star breakdowns, and written feedback received by the worker after service completions to encourage quality performance.

### 20. Technician Profile & Skill Settings
* **Layer:** Worker Mobile App (`worker_app/lib/screens/profile_screen.dart`)
* **Description:** Manages technician account details, assigned primary service categories (Electrician, Plumber, etc.), operational radius settings, working hours, and app configurations.

---

## 🖥️ PART 3: Admin Web Panel Modules (Modules 21 – 30)

### 21. Admin Analytics Dashboard
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Dashboard.jsx`)
* **Description:** The central administrative command center displaying high-level platform revenue, total bookings, active workers, customer counts, real-time booking feeds, and monthly growth charts.

### 22. Customer User Management
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Users.jsx`)
* **Description:** Manages all registered customer profiles, contact info, booking histories, and account status toggles (**Block/Unblock**) for policy enforcement.

### 23. Worker Partner Management
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Workers.jsx`)
* **Description:** Audits service partner accounts, assigned skills, active working statuses, customer ratings, and account activation/deactivation controls.

### 24. KYC Approval & Rejection Center
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Kyc.jsx`)
* **Description:** A compliance module for reviewing uploaded identity proofs (Aadhaar, PAN, certificates). Allows admins to approve or reject applications with specific feedback.

### 25. Master Booking Manager
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Bookings.jsx`)
* **Description:** Oversees all system orders across statuses (*Pending*, *Assigned*, *In-Progress*, *Completed*, *Cancelled*). Features manual worker assignment overrides and cancellation auditing.

### 26. Invoice & Billing Archives
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Invoices.jsx`)
* **Description:** Archives generated billing receipts, itemized spare parts breakdowns, taxes, and platform fees. Supports invoice viewing and PDF downloads.

### 27. Financial Payments & Payout Tracker
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Payments.jsx`)
* **Description:** Tracks online (Razorpay) and Cash transactions, transaction IDs, platform commission revenues, and manages worker payout settlements.

### 28. Review & Rating Moderation
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Reviews.jsx`)
* **Description:** Moderates customer reviews and star ratings. Allows admins to inspect feedback and delete inappropriate or abusive reviews.

### 29. Service Category & Pricing Configurator
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Services.jsx`)
* **Description:** Configures service categories and sub-services, setting base prices, estimated durations, descriptions, category images, and active states.

### 30. Banners & Marketing Manager
* **Layer:** Admin Web Panel (`admin/frontend/src/pages/Banners.jsx`)
* **Description:** Manages home screen promotional banners and offer sliders, controlling banner images, display sequence, and click redirection links.

---

## ⚙️ PART 4: Backend API & System Modules (Modules 31 – 40)

### 31. Multi-Role Auth & OTP Engine
* **Layer:** Backend REST API (`backend/src/routes/auth.routes.js`)
* **Description:** Provides multi-role authentication for Users, Workers, and Admins. Manages phone OTP verification, password hashing, and issues secure JWT tokens.

### 32. Core Booking Lifecycle Engine
* **Layer:** Backend REST API (`backend/src/routes/app.routes.js`)
* **Description:** Executes booking state transitions (`pending` → `assigned` → `in_progress` → `completed`), OTP verification checks, and automated worker notification triggers.

### 33. Worker Distance Matrix & Search Engine
* **Layer:** Backend REST API (`backend/src/controllers/user-location.controller.js`)
* **Description:** Calculates geographical distances between customers and active workers using Haversine formulas and geocoding to find nearby technicians.

### 34. Custom Billing & Tax Calculation Engine
* **Layer:** Backend REST API (`backend/src/controllers/invoice.controller.js`)
* **Description:** Computes itemized invoice totals, adding spare parts, extra labor, platform commission rates, and GST taxes.

### 35. Razorpay Webhook & Signature Verification
* **Layer:** Backend REST API (`backend/src/controllers/payment.controller.js`)
* **Description:** Integrates Razorpay API for order creation, payment signature verification, webhook handling, and transaction logging.

### 36. FCM Push Notification Broadcast Engine
* **Layer:** Backend REST API (`backend/src/utils/fcm.service.js`)
* **Description:** A Firebase Cloud Messaging (FCM) push notification engine that sends real-time job alerts, OTP notifications, and promotional broadcasts.

### 37. Sub-Admin Role-Based Access Control (RBAC)
* **Layer:** Backend REST API (`backend/src/routes/subAdmin.routes.js`)
* **Description:** Implements Role-Based Access Control for admin panel staff, assigning per-module permissions (Read, Write, Delete).

### 38. Customer & Worker Support Ticket Engine
* **Layer:** Backend REST API (`backend/src/routes/complaint.routes.js`)
* **Description:** Manages support ticket creation, status tracking (`Open`, `In-Progress`, `Resolved`), resolution comments, and helpdesk management.

### 39. Operational Coverage Zones & Pincode Engine
* **Layer:** Backend REST API (`backend/src/routes/location.routes.js`)
* **Description:** Restricts service booking availability to active cities and pincode zones, mapping regional service availability.

### 40. Global System Configuration Engine
* **Layer:** Backend REST API (`backend/src/routes/dashboard.routes.js`)
* **Description:** Manages global app settings including commission percentages, GST rates, app maintenance mode toggles, and system analytics.
