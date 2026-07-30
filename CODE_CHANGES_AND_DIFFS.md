# 🛠️ Code Changes & Line-by-Line Diffs Log

This document lists every file modified or created today, including exact line locations, added code (+), and removed/deleted code (-).

---

## 1. [`user_app/lib/screens/nearby_workers_screen.dart`](file:///c:/Users/Admin/Desktop/service_app/user_app/lib/screens/nearby_workers_screen.dart)

### 📌 Purpose
Fixed bug where booking a service immediately redirected users to `PaymentScreen` (forcing upfront payment before inspection). Changed to navigate to **My Bookings** tab with a confirmation toast. Removed unused imports.

### 📝 Line Diffs

**Lines 5–12 (Updated Imports):**
```diff
 import '../providers/auth_provider.dart';
 import '../providers/booking_provider.dart';
 import '../services/api_service.dart';
+import '../theme/app_theme.dart';
-import 'payment_screen.dart';
+import 'main_shell.dart';
```

**Lines 135–150 (Navigation Flow Fix):**
```diff
       if (booking != null) {
-        Navigator.of(context).push(
-          MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
-        );
+        ScaffoldMessenger.of(context).showSnackBar(
+          const SnackBar(
+            content: Text('🎉 Service Booked Successfully! Partner assigned for inspection.'),
+            backgroundColor: AppTheme.primary,
+          ),
+        );
+        Navigator.of(context).pushAndRemoveUntil(
+          MaterialPageRoute(builder: (_) => const MainShell(initialTab: 1)),
+          (_) => false,
+        );
       } else {
```

---

## 2. [`user_app/lib/widgets/common_widgets.dart`](file:///c:/Users/Admin/Desktop/service_app/user_app/lib/widgets/common_widgets.dart)

### 📌 Purpose
Removed upfront "Pay Now" button from `pending` status cards. Added dynamic **"Pay Now (₹<amount>)"** button to `completed` status cards (rendered **only after** worker submits custom invoice).

### 📝 Line Diffs

**Lines 530–550 (Removed Upfront Pay Now Button on Pending):**
```diff
               if (booking.canCancel && onCancel != null) ...[
                 const SizedBox(height: 8),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
-                    if (booking.status == 'pending') ...[
-                      ElevatedButton(
-                        style: ElevatedButton.styleFrom(
-                          minimumSize: Size.zero,
-                          backgroundColor: AppTheme.primary,
-                          foregroundColor: Colors.white,
-                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
-                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
-                        ),
-                        onPressed: () {
-                          Navigator.push(
-                            context,
-                            MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
-                          );
-                        },
-                        child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
-                      ),
-                      const SizedBox(width: 8),
-                    ],
                     TextButton(
                       onPressed: onCancel,
                       child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 13)),
                     ),
```

**Lines 584–606 (Added Pay Now Button Post-Invoice Submission):**
```diff
               if (booking.status == 'completed') ...[
                 const SizedBox(height: 8),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
+                    if (booking.amount > 0) ...[
+                      ElevatedButton.icon(
+                        style: ElevatedButton.styleFrom(
+                          minimumSize: Size.zero,
+                          backgroundColor: Colors.green.shade700,
+                          foregroundColor: Colors.white,
+                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
+                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
+                        ),
+                        onPressed: () {
+                          Navigator.push(
+                            context,
+                            MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
+                          );
+                        },
+                        icon: const Icon(Icons.payment, size: 14),
+                        label: Text('Pay Now (₹${booking.amount.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
+                      ),
+                      const SizedBox(width: 8),
+                    ],
                     if (onRebook != null) ...[
```

---

## 3. [`backend/package.json`](file:///c:/Users/Admin/Desktop/service_app/backend/package.json)

### 📌 Purpose
Added `firebase-admin` dependency for backend FCM Push Notifications.

### 📝 Line Diffs

**Lines 19–24:**
```diff
     "express": "^5.2.1",
     "express-rate-limit": "^8.5.2",
     "express-validator": "^7.3.2",
+    "firebase-admin": "^12.0.0",
     "jsonwebtoken": "^9.0.3",
```

---

## 4. [`backend/src/config/db.js`](file:///c:/Users/Admin/Desktop/service_app/backend/src/config/db.js)

### 📌 Purpose
Added migration queries for `fcm_token` columns in `users` and `workers` tables.

### 📝 Line Diffs

**Lines 255–262:**
```diff
     -- Add address fields to users if missing
     ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
     ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(100);
     ALTER TABLE users ADD COLUMN IF NOT EXISTS credits INTEGER DEFAULT 0;
+    ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
+    ALTER TABLE workers ADD COLUMN IF NOT EXISTS fcm_token TEXT;
     ALTER TABLE bookings ADD COLUMN IF NOT EXISTS otp VARCHAR(10);
```

---

## 5. [`backend/src/utils/fcm.service.js`](file:///c:/Users/Admin/Desktop/service_app/backend/src/utils/fcm.service.js) [NEW FILE]

### 📌 Purpose
Created new service module for initializing Firebase Admin SDK, updating device tokens in DB, and sending real-time push messages with database fallback.

### 📝 Key Code Added:
```javascript
const path = require("path");
const fs = require("fs");
const db = require("../config/db");
const logger = require("./logger");

let admin = null;
let isFcmInitialized = false;

try {
  admin = require("firebase-admin");
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.join(__dirname, "../config/serviceAccountKey.json");
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    isFcmInitialized = true;
  }
} catch (err) {
  logger.warn(`Firebase Admin SDK setup skipped: ${err.message}`);
}

async function saveUserFcmToken(userId, token) {
  await db.query("UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2", [token, userId]);
}

async function saveWorkerFcmToken(workerId, token) {
  await db.query("UPDATE workers SET fcm_token = $1, updated_at = NOW() WHERE id = $2", [token, workerId]);
}

async function sendToUser(userId, { title, body, data = {} }) { /* ... */ }
async function sendToWorker(workerId, { title, body, data = {} }) { /* ... */ }

module.exports = { saveUserFcmToken, saveWorkerFcmToken, sendToUser, sendToWorker };
```

---

## 6. [`backend/src/routes/app.routes.js`](file:///c:/Users/Admin/Desktop/service_app/backend/src/routes/app.routes.js)

### 📌 Purpose
Registered `/user/fcm-token` and `/worker/fcm-token` routes.

### 📝 Line Diffs

**Lines 82–97:**
```diff
+// FCM token update routes
+router.post(
+  "/user/fcm-token",
+  allowRoles(roles.USER),
+  [body("fcmToken").trim().notEmpty()],
+  validate,
+  controller.updateUserFcmToken
+);
+
+router.post(
+  "/worker/fcm-token",
+  allowRoles(roles.WORKER),
+  [body("fcmToken").trim().notEmpty()],
+  validate,
+  controller.updateWorkerFcmToken
+);
```

---

## 7. [`backend/src/controllers/app.controller.js`](file:///c:/Users/Admin/Desktop/service_app/backend/src/controllers/app.controller.js)

### 📌 Purpose
Imported `fcmService`, added push triggers to `createBooking`, `updateMyBookingStatus`, `submitWorkerInvoice`, and exported `updateUserFcmToken` & `updateWorkerFcmToken`.

### 📝 Line Diffs

**Line 9 (Import):**
```diff
+const fcmService = require("../utils/fcm.service");
```

**Lines 90–98 (Push in `createBooking`):**
```diff
+    if (booking.worker_id) {
+      fcmService.sendToWorker(booking.worker_id, {
+        title: "🔔 New Job Assignment!",
+        body: `New ${service.name} booking #${booking.id} assigned to you. Tap to view details.`,
+        data: { bookingId: booking.id, type: "new_job" }
+      });
+    }
```

**Lines 224–245 (Push in `updateMyBookingStatus`):**
```diff
+      if (status === "confirmed") {
+        fcmService.sendToUser(booking.user_id, {
+          title: "✅ Worker Accepted!",
+          body: `Partner accepted your booking #${booking.id}. Check OTP on your booking card.`,
+          data: { bookingId: booking.id, status: "confirmed" }
+        });
+      } else if (status === "in_progress") {
+        fcmService.sendToUser(booking.user_id, {
+          title: "🛠️ Work Started!",
+          body: `Partner verified your OTP and started the service.`,
+          data: { bookingId: booking.id, status: "in_progress" }
+        });
+      }
```

**Lines 442–470 (Push in `submitWorkerInvoice` & Controller Exports):**
```diff
+    fcmService.sendToUser(booking.user_id, {
+      title: "🧾 Custom Invoice Ready!",
+      body: `Worker submitted bill of ₹${amountVal}. Tap to view & Pay Now via Razorpay.`,
+      data: { bookingId: booking.id, amount: amountVal, type: "invoice_ready" }
+    });

+async function updateUserFcmToken(req, res, next) {
+  const { fcmToken } = req.body;
+  await fcmService.saveUserFcmToken(req.auth.id, fcmToken);
+  return success(res, "User FCM Token updated successfully");
+}

+async function updateWorkerFcmToken(req, res, next) {
+  const { fcmToken } = req.body;
+  await fcmService.saveWorkerFcmToken(req.auth.id, fcmToken);
+  return success(res, "Worker FCM Token updated successfully");
+}
```

---

## 8. [`backend/src/controllers/payment.controller.js`](file:///c:/Users/Admin/Desktop/service_app/backend/src/controllers/payment.controller.js)

### 📌 Purpose
Added FCM push notifications for user and worker upon successful payment verification.

### 📝 Line Diffs

**Lines 118–134:**
```diff
+    // Send FCM Push Notifications
+    const fcmService = require("../utils/fcm.service");
+    if (updatedBooking.worker_id) {
+      fcmService.sendToWorker(updatedBooking.worker_id, {
+        title: "💰 Payment Received!",
+        body: `Customer paid ₹${updatedBooking.amount} for Booking #${bookingId}. Job completed!`,
+        data: { bookingId, amount: updatedBooking.amount, type: "payment_received" }
+      });
+    }
+    fcmService.sendToUser(updatedBooking.user_id, {
+      title: "🎉 Payment Successful!",
+      body: `Payment of ₹${updatedBooking.amount} confirmed for Booking #${bookingId}. Thank you!`,
+      data: { bookingId, amount: updatedBooking.amount, type: "payment_success" }
+    });
```

---

## 9. Flutter Mobile Apps Sync ([`user_app/lib/main.dart`](file:///c:/Users/Admin/Desktop/service_app/user_app/lib/main.dart) & [`worker_app/lib/main.dart`](file:///c:/Users/Admin/Desktop/service_app/worker_app/lib/main.dart))

### 📌 Purpose
Auto-sync FCM device token to backend upon app launch.

### 📝 Line Diffs (User App `main.dart` Lines 78–84):
```diff
     final token = await messaging.getToken();
+    if (token != null && token.isNotEmpty) {
+      await apiService.init();
+      await apiService.updateFcmToken(token);
+    }
```
