# 🌐 Complete API Endpoints Documentation (94 Endpoints)

This document provides a clean, comprehensive reference for all 94 API endpoints registered in the Service App backend server.

---

## 1. Authentication APIs (`/api/auth`)
| Method | Endpoint | Auth Required | Purpose / Request Parameters |
| :--- | :--- | :---: | :--- |
| `POST` | `/api/auth/admin/register` | No | Register new admin account |
| `POST` | `/api/auth/user/register` | No | Register new user account (`name`, `phone`, `password`, `email`) |
| `POST` | `/api/auth/worker/register` | No | Register new worker account (`name`, `phone`, `service_type`) |
| `POST` | `/api/auth/login` | No | Unified login (`login`, `password`, `role`) |
| `POST` | `/api/auth/phone-login` | No | Mobile phone login with OTP |
| `GET` | `/api/auth/me` | JWT | Fetch current profile info |

---

## 2. Customer & Worker App APIs (`/api/app`)
| Method | Endpoint | Auth Required | Purpose / Request Parameters |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/app/services/categories` | No | List main service categories |
| `GET` | `/api/app/services/categories/:id/subcategories` | No | List subcategories under parent category |
| `GET` | `/api/app/banners` | No | Fetch active promotional banners |
| `GET` | `/api/app/services` | No | List active services (`category_id`, `search`) |
| `GET` | `/api/app/services/:id` | No | Get single service details |
| `POST` | `/api/app/upload` | JWT | Generic file/KYC multipart upload |
| `PATCH` | `/api/app/worker/profile` | Worker | Update worker onboarding profile & status |
| `GET` | `/api/app/worker/earnings` | Worker | Fetch worker earnings, today stats & payout history |
| `PATCH` | `/api/app/user/profile` | User | Update user profile (`name`, `email`, `state`, `address`) |
| `POST` | `/api/app/user/fcm-token` | User | **Save/update User FCM Device Token** |
| `POST` | `/api/app/worker/fcm-token` | Worker | **Save/update Worker FCM Device Token** |
| `POST` | `/api/app/bookings` | User | Create service booking (`service_id`, `worker_id`, `address`, `notes`) |
| `PATCH` | `/api/app/bookings/:id/cancel` | User | Cancel pending/confirmed booking |
| `GET` | `/api/app/bookings` | User/Worker | List my bookings (`status` filter) |
| `GET` | `/api/app/bookings/:id` | User/Worker | Get booking details & OTP status |
| `PATCH` | `/api/app/bookings/:id/status` | User/Worker | Update status (`confirmed`, `in_progress`, `completed`, `otp`) |
| `POST` | `/api/app/bookings/:id/start-job` | Worker | Start job with photo upload & OTP verification |
| `POST` | `/api/app/bookings/:id/complete-job` | Worker | Complete job with completion photo upload |
| `POST` | `/api/app/bookings/:id/submit-invoice` | Worker | **Submit custom invoice line items (`items`, `totalAmount`)** |
| `POST` | `/api/app/payments/order` | User | Create Razorpay order (`bookingId`) |
| `POST` | `/api/app/payments/verify` | User | Verify Razorpay payment signature & update booking |
| `POST` | `/api/app/reviews` | User | Submit rating & review for completed booking |
| `GET` | `/api/app/reviews` | No | Fetch worker ratings & reviews |

---

## 3. User Address APIs (`/api/app/addresses`, `/api/user-addresses`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/app/addresses` | User | Fetch user saved addresses |
| `POST` | `/api/app/addresses` | User | Add new address (`title`, `address_line`, `city`, `pincode`) |
| `PUT` | `/api/app/addresses/:id` | User | Update address details |
| `DELETE` | `/api/app/addresses/:id` | User | Delete saved address |
| `PATCH` | `/api/app/addresses/:id/default` | User | Set primary default address |

---

## 4. Location & Tracking APIs (`/api/app/locations`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `POST` | `/api/app/locations/reverse-geocode` | No | Convert lat/lng to formatted address |
| `POST` | `/api/app/locations/nearby-workers` | No | Find active workers within radius by lat/lng |
| `POST` | `/api/app/locations/update-worker-location` | Worker | Update live GPS coordinates |
| `GET` | `/api/app/locations/worker-location/:id` | User | Get worker live GPS location for map tracking |

---

## 5. Admin User Management (`/api/admin/users`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/users` | Admin | List users with pagination, sorting & date range filters |
| `POST` | `/api/admin/users` | Admin | Create user account |
| `GET` | `/api/admin/users/:id` | Admin | Get user details |
| `PATCH` | `/api/admin/users/:id` | Admin | Update user details |
| `DELETE` | `/api/admin/users/:id` | Admin | Delete user account |
| `PATCH` | `/api/admin/users/:id/block` | Admin | Block user account |
| `PATCH` | `/api/admin/users/:id/unblock` | Admin | Unblock user account |
| `GET` | `/api/admin/users/:id/bookings` | Admin | View user booking history |
| `GET` | `/api/admin/users/:id/activity-logs` | Admin | View user activity logs |
| `GET` | `/api/admin/users/:id/activity-logs/download` | Admin | Download user activity logs as CSV |

---

## 6. Admin Worker Management (`/api/workers`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/workers` | Admin | List workers with service & status filters |
| `POST` | `/api/workers` | Admin | Create worker profile |
| `GET` | `/api/workers/:id` | Admin | Get worker details |
| `PATCH` | `/api/workers/:id` | Admin | Update worker info |
| `DELETE` | `/api/workers/:id` | Admin | Delete worker account |
| `PATCH` | `/api/workers/:id/status` | Admin | Toggle worker status (active/inactive) |

---

## 7. Worker KYC APIs (`/api/kyc`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `POST` | `/api/kyc` | Worker | Submit KYC (Aadhaar, PAN, Bank Passbook, Selfie) |
| `GET` | `/api/kyc` | Admin | List pending KYC submissions |
| `GET` | `/api/kyc/:id` | Admin | View worker KYC documents |
| `PATCH` | `/api/kyc/:id/review` | Admin | Review KYC (Approve / Reject with reason) |

---

## 8. Admin Service Catalog (`/api/admin/services`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/services/categories` | Admin | List service categories |
| `POST` | `/api/admin/services/categories` | Admin | Create service category |
| `PUT` | `/api/admin/services/categories/:id` | Admin | Update category |
| `DELETE` | `/api/admin/services/categories/:id` | Admin | Delete category |
| `GET` | `/api/admin/services` | Admin | List services |
| `POST` | `/api/admin/services` | Admin | Create service (with image upload) |
| `PUT` | `/api/admin/services/:id` | Admin | Update service |
| `DELETE` | `/api/admin/services/:id` | Admin | Delete service |
| `PATCH` | `/api/admin/services/:id/status` | Admin | Toggle service active status |

---

## 9. Admin Bookings APIs (`/api/admin/bookings`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/bookings` | Admin | List all bookings |
| `GET` | `/api/admin/bookings/analytics` | Admin | Booking analytics & revenue metrics |
| `GET` | `/api/admin/bookings/:id` | Admin | View booking details |
| `PATCH` | `/api/admin/bookings/:id` | Admin | Assign worker / update status |

---

## 10. Admin Financial & Invoices (`/api/admin/invoices`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/invoices` | Admin | List invoices |
| `GET` | `/api/admin/invoices/payments` | Admin | List Razorpay payment logs |
| `GET` | `/api/admin/invoices/reports` | Admin | Financial summary report |
| `GET` | `/api/admin/invoices/payouts` | Admin | Worker payouts report |
| `GET` | `/api/admin/invoices/:id` | Admin | View single invoice |

---

## 11. Complaints & Support (`/api/admin/complaints`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/complaints` | Admin | List customer complaints |
| `GET` | `/api/admin/complaints/:id` | Admin | View complaint details |
| `PATCH` | `/api/admin/complaints/:id` | Admin | Resolve/update complaint status |
| `POST` | `/api/admin/complaints` | User | Raise new complaint |

---

## 12. Zones & Locations (`/api/admin/locations`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/locations/zones` | Admin | List service zones |
| `POST` | `/api/admin/locations/zones` | Admin | Add service zone |
| `DELETE` | `/api/admin/locations/zones/:id` | Admin | Delete zone |
| `GET` | `/api/admin/locations/pincodes` | Admin | List pincodes |
| `POST` | `/api/admin/locations/pincodes` | Admin | Map pincode to zone |

---

## 13. Sub-Admins Management (`/api/admin/sub-admins`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/sub-admins` | Admin | List sub-admins |
| `POST` | `/api/admin/sub-admins` | Admin | Create sub-admin account |
| `GET` | `/api/admin/sub-admins/:id` | Admin | Get sub-admin details |
| `PATCH` | `/api/admin/sub-admins/:id` | Admin | Update sub-admin permissions |
| `DELETE` | `/api/admin/sub-admins/:id` | Admin | Delete sub-admin |

---

## 14. Admin Notifications & Banners (`/api/admin/notifications`, `/api/admin/banners`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/api/admin/notifications` | Admin | List system notifications |
| `PATCH` | `/api/admin/notifications/:id/read` | Admin | Mark notification as read |
| `PATCH` | `/api/admin/notifications/read-all` | Admin | Mark all as read |
| `DELETE` | `/api/admin/notifications/:id` | Admin | Delete notification |
| `GET` | `/api/admin/banners` | Admin | List all banners |
| `POST` | `/api/admin/banners` | Admin | Create banner |
| `PUT` | `/api/admin/banners/:id` | Admin | Update banner |
| `DELETE` | `/api/admin/banners/:id` | Admin | Delete banner |

---

## 15. System & Reviews (`/health`, `/admin/reviews`)
| Method | Endpoint | Auth Required | Purpose |
| :--- | :--- | :---: | :--- |
| `GET` | `/health` | No | System health check |
| `GET` | `/admin/reviews` | Admin | List user reviews |

---

### **TOTAL REGISTERED ENDPOINTS: 94 Endpoints**
