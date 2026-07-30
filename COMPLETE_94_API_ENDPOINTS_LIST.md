# 🌐 Service App System - Master 94 API Endpoints Documentation

This document provides the complete, exhaustive master list of all **94 REST API Endpoints** implemented in the **Service App Backend API Engine** (`backend/src/routes` and `backend/src/controllers`), organized into 15 operational categories.

---

## 📊 Summary Table of API Categories

| Category No. | Operational Module | Route Prefix | Total Endpoints |
| :---: | :--- | :--- | :---: |
| **01** | Authentication & Auth Sessions | `/api/auth` | **6** |
| **02** | Customer App & Core Bookings | `/api/app` | **23** |
| **03** | User Saved Delivery Addresses | `/api/app/addresses` | **5** |
| **04** | Geocoding & Nearby Worker Location | `/api/app/locations` | **4** |
| **05** | Admin Customer User Management | `/api/admin/users` | **10** |
| **06** | Admin Worker Partner Management | `/api/workers` | **6** |
| **07** | Worker KYC Document Verification | `/api/kyc` | **4** |
| **08** | Admin Service Catalog & Pricing | `/api/admin/services` | **10** |
| **09** | Admin Master Orders Management | `/api/admin/bookings` | **4** |
| **10** | Admin Invoices, Reports & Payouts | `/api/admin/invoices` | **5** |
| **11** | Customer & Worker Helpdesk Complaints | `/api/admin/complaints` | **4** |
| **12** | Coverage Cities & Operational Zones | `/api/admin/locations` | **5** |
| **13** | Sub-Admin Access & RBAC Permissions | `/api/admin/sub-admins` | **5** |
| **14** | Admin Notifications & Offer Banners | `/api/admin/notifications`, `/banners` | **8** |
| **15** | System Health & Ratings Audit | `/health`, `/admin/reviews` | **2** |
| **TOTAL**| **FULL-STACK BACKEND API ENGINE** | | **94 ENDPOINTS** |

---

## 🔐 Category 01: Authentication & Auth Sessions (`/api/auth`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 1 | `POST` | `/api/auth/admin/register` | Register new super admin account with hashed password. |
| 2 | `POST` | `/api/auth/user/register` | Register new customer account with phone & email. |
| 3 | `POST` | `/api/auth/worker/register` | Register new service technician account with primary skill. |
| 4 | `POST` | `/api/auth/login` | Unified authentication endpoint issuing JWT session token. |
| 5 | `POST` | `/api/auth/phone-login` | Mobile phone login with SMS OTP verification. |
| 6 | `GET` | `/api/auth/me` | Fetch profile details of current authenticated account session. |

---

## 📱 Category 02: Customer App & Core Bookings (`/api/app`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 7 | `GET` | `/api/app/services/categories` | List top-level active service categories. |
| 8 | `GET` | `/api/app/services/categories/:id/subcategories` | List sub-categories of parent category. |
| 9 | `GET` | `/api/app/banners` | List active promotional banners for home slider. |
| 10 | `GET` | `/api/app/services` | List service catalog with category & price filters. |
| 11 | `GET` | `/api/app/services/:id` | Get single service details, inclusions, & pricing. |
| 12 | `POST` | `/api/app/upload` | Multipart file upload endpoint for user/worker images. |
| 13 | `PATCH` | `/api/app/worker/profile` | Update worker profile details & onboarding skills. |
| 14 | `GET` | `/api/app/worker/earnings` | Fetch worker completed jobs history & wallet balance. |
| 15 | `PATCH` | `/api/app/user/profile` | Update customer user profile & contact info. |
| 16 | `POST` | `/api/app/user/fcm-token` | Save/sync customer FCM device push token. |
| 17 | `POST` | `/api/app/worker/fcm-token` | Save/sync worker FCM device push token. |
| 18 | `POST` | `/api/app/bookings` | Create new service booking (`status: pending`, auto-generate 4-digit OTP). |
| 19 | `PATCH` | `/api/app/bookings/:id/cancel` | Cancel pending or confirmed booking request. |
| 20 | `GET` | `/api/app/bookings` | List active & past bookings for user or worker. |
| 21 | `GET` | `/api/app/bookings/:id` | Get single booking details & status timeline. |
| 22 | `PATCH` | `/api/app/bookings/:id/status` | Update booking status (`assigned`, `in_progress` via OTP check). |
| 23 | `POST` | `/api/app/bookings/:id/start-job` | Verify start-job photo & 4-digit OTP code. |
| 24 | `POST` | `/api/app/bookings/:id/complete-job` | Complete job with post-service inspection photo. |
| 25 | `POST` | `/api/app/bookings/:id/submit-invoice` | Worker submits custom invoice (spare parts + labor fees). |
| 26 | `POST` | `/api/app/payments/order` | Create Razorpay Order ID for checkout. |
| 27 | `POST` | `/api/app/payments/verify` | Verify Razorpay HMAC SHA256 payment signature. |
| 28 | `POST` | `/api/app/reviews` | Submit 1-to-5 star rating and text review. |
| 29 | `GET` | `/api/app/reviews` | List customer reviews for a service/worker. |

---

## 📍 Category 03: User Saved Addresses (`/api/app/addresses`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 30 | `GET` | `/api/app/addresses` | Fetch saved delivery addresses for logged-in user. |
| 31 | `POST` | `/api/app/addresses` | Add new delivery address (Home, Work, Other) with lat/lng. |
| 32 | `PUT` | `/api/app/addresses/:id` | Update existing address details or pin coordinates. |
| 33 | `DELETE` | `/api/app/addresses/:id` | Delete saved address entry. |
| 34 | `PATCH` | `/api/app/addresses/:id/default` | Set primary default delivery address. |

---

## 🗺️ Category 04: Geocoding & Worker Discovery (`/api/app/locations`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 35 | `POST` | `/api/app/locations/reverse-geocode` | Convert lat/lng coordinates to formatted address string. |
| 36 | `POST` | `/api/app/locations/nearby-workers` | Search nearby active workers within 10km using Haversine formula. |
| 37 | `POST` | `/api/app/locations/update-worker-location` | Stream live GPS coordinates from worker mobile app. |
| 38 | `GET` | `/api/app/locations/worker-location/:id` | Get technician's current GPS location for map pin tracking. |

---

## 👥 Category 05: Admin Customer User Management (`/api/admin/users`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 39 | `GET` | `/api/admin/users` | List registered customers with search, sort, and pagination. |
| 40 | `POST` | `/api/admin/users` | Create customer account manually via admin portal. |
| 41 | `GET` | `/api/admin/users/:id` | Get customer profile details and account stats. |
| 42 | `PATCH` | `/api/admin/users/:id` | Update customer user details. |
| 43 | `DELETE` | `/api/admin/users/:id` | Delete customer account from database. |
| 44 | `PATCH` | `/api/admin/users/:id/block` | Block user account for policy violations. |
| 45 | `PATCH` | `/api/admin/users/:id/unblock` | Restore and unblock user account access. |
| 46 | `GET` | `/api/admin/users/:id/bookings` | View full order history for specific customer. |
| 47 | `GET` | `/api/admin/users/:id/activity-logs` | Fetch user login and action activity logs. |
| 48 | `GET` | `/api/admin/users/:id/activity-logs/download` | Export customer activity logs to CSV format. |

---

## 👷 Category 06: Admin Worker Management (`/api/workers`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 49 | `GET` | `/api/workers` | List all service workers with status and skill category filters. |
| 50 | `POST` | `/api/workers` | Onboard new service worker manually. |
| 51 | `GET` | `/api/workers/:id` | View technician profile, skill list, and ratings audit. |
| 52 | `PATCH` | `/api/workers/:id` | Update worker skills, phone number, or details. |
| 53 | `DELETE` | `/api/workers/:id` | Remove worker account from platform. |
| 54 | `PATCH` | `/api/workers/:id/status` | Toggle worker account status (Active / Inactive). |

---

## 🪪 Category 07: Worker KYC Verification (`/api/kyc`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 55 | `POST` | `/api/kyc` | Worker submits identity documents (Aadhaar, PAN, Bank). |
| 56 | `GET` | `/api/kyc` | Admin lists pending and reviewed KYC submissions. |
| 57 | `GET` | `/api/kyc/:id` | Get single KYC document submission details. |
| 58 | `PATCH` | `/api/kyc/:id/review` | Admin approves or rejects worker KYC with feedback reason. |

---

## 🧰 Category 08: Admin Service Catalog & Pricing (`/api/admin/services`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 59 | `GET` | `/api/admin/services/categories` | List all service categories. |
| 60 | `POST` | `/api/admin/services/categories` | Create new service category with icon upload. |
| 61 | `PUT` | `/api/admin/services/categories/:id` | Update service category details or icon. |
| 62 | `DELETE` | `/api/admin/services/categories/:id` | Delete service category. |
| 63 | `GET` | `/api/admin/services` | List all services in catalog. |
| 64 | `POST` | `/api/admin/services` | Add new service item with base price and image. |
| 65 | `PUT` | `/api/admin/services/:id` | Update service description, price, or duration. |
| 66 | `DELETE` | `/api/admin/services/:id` | Delete service item from catalog. |
| 67 | `PATCH` | `/api/admin/services/:id/status` | Toggle service availability status (Active / Disabled). |

---

## 📋 Category 09: Admin Bookings Management (`/api/admin/bookings`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 68 | `GET` | `/api/admin/bookings` | List all system bookings with date range & status filters. |
| 69 | `GET` | `/api/admin/bookings/analytics` | Fetch booking metrics, completed job ratios, & trends. |
| 70 | `GET` | `/api/admin/bookings/:id` | View booking timeline, customer/worker info, & OTP log. |
| 71 | `PATCH` | `/api/admin/bookings/:id` | Admin update booking status or override worker assignment. |

---

## 🧾 Category 10: Admin Invoices & Payouts (`/api/admin/invoices`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 72 | `GET` | `/api/admin/invoices` | List generated job invoices and spare parts breakdowns. |
| 73 | `GET` | `/api/admin/invoices/payments` | List online Razorpay and Cash payment transaction logs. |
| 74 | `GET` | `/api/admin/invoices/reports` | Financial summary report of revenue and platform taxes. |
| 75 | `GET` | `/api/admin/invoices/payouts` | Summary of worker earnings and platform commission splits. |
| 76 | `GET` | `/api/admin/invoices/:id` | Get detailed invoice record with itemized billing lines. |

---

## 🎧 Category 11: Admin Complaints & Helpdesk (`/api/admin/complaints`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 77 | `GET` | `/api/admin/complaints` | List customer & worker support tickets. |
| 78 | `GET` | `/api/admin/complaints/:id` | Get single complaint ticket details and chat log. |
| 79 | `PATCH` | `/api/admin/complaints/:id` | Update complaint resolution status (`Open`, `In-Progress`, `Resolved`). |
| 80 | `POST` | `/api/admin/complaints` | Create new support complaint ticket manually. |

---

## 📍 Category 12: Admin Locations & Zones (`/api/admin/locations`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 81 | `GET` | `/api/admin/locations/zones` | List active service coverage zones & cities. |
| 82 | `POST` | `/api/admin/locations/zones` | Add new operational service zone. |
| 83 | `DELETE` | `/api/admin/locations/zones/:id` | Delete service zone. |
| 84 | `GET` | `/api/admin/locations/pincodes` | List serviceable postal pincodes. |
| 85 | `POST` | `/api/admin/locations/pincodes` | Map new pincode to service zone. |

---

## 🔐 Category 13: Sub-Admin RBAC Management (`/api/admin/sub-admins`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 86 | `GET` | `/api/admin/sub-admins` | List sub-admin staff accounts and assigned roles. |
| 87 | `POST` | `/api/admin/sub-admins` | Create sub-admin staff account with login credentials. |
| 88 | `GET` | `/api/admin/sub-admins/:id` | View sub-admin profile and permission matrix. |
| 89 | `PATCH` | `/api/admin/sub-admins/:id` | Update sub-admin access control permissions (RBAC). |
| 90 | `DELETE` | `/api/admin/sub-admins/:id` | Delete sub-admin staff account. |

---

## 🔔 Category 14: Admin Notifications & Banners (`/api/admin/notifications`, `/banners`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 91 | `GET` | `/api/admin/notifications` | List system notifications and FCM broadcast logs. |
| 92 | `PATCH` | `/api/admin/notifications/:id/read` | Mark single notification as read. |
| 93 | `PATCH` | `/api/admin/notifications/read-all` | Mark all admin notifications as read. |
| 94 | `DELETE` | `/api/admin/notifications/:id` | Delete notification log. |
| 95 | `GET` | `/api/admin/banners` | List home screen promotional banners. |
| 96 | `POST` | `/api/admin/banners` | Upload & create new home screen banner. |
| 97 | `PUT` | `/api/admin/banners/:id` | Update banner image, display sequence, or redirect link. |
| 98 | `DELETE` | `/api/admin/banners/:id` | Delete banner from slider. |

---

## 🏥 Category 15: System Health & Reviews (`/health`, `/admin/reviews`)

| # | HTTP Method | Endpoint Path | Description & Functional Purpose |
| :---: | :---: | :--- | :--- |
| 99 | `GET` | `/health` | Server health check endpoint (DB connectivity, uptime). |
| 100| `GET` | `/admin/reviews` | List all user reviews & ratings for moderation. |
