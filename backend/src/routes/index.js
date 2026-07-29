const express = require("express");
const authRoutes = require("./auth.routes");
const dashboardRoutes = require("./dashboard.routes");
const userRoutes = require("./user.routes");
const workerRoutes = require("./worker.routes");
const kycRoutes = require("./kyc.routes");
const serviceRoutes = require("./service.routes");
const bookingRoutes = require("./booking.routes");
const invoiceRoutes = require("./invoice.routes");
const complaintRoutes = require("./complaint.routes");
const locationRoutes = require("./location.routes");
const userLocationRoutes = require("./user-location.routes");
const appRoutes = require("./app.routes");
const checkPermission = require("../middlewares/permission.middleware");
const subAdminRoutes = require("./subAdmin.routes");
const notificationRoutes = require("./notification.routes");
const bannerRoutes = require("./banner.routes");
const { adminListReviews } = require("../controllers/review.controller");
const auth = require("../middlewares/auth.middleware");

const router = express.Router();

const userAddressRoutes = require("./user-address.routes");

router.get("/health", (req, res) => {
  res.json({ success: true, message: "Backend is running" });
});

router.use("/auth", authRoutes);
router.use("/dashboard", checkPermission("dashboard"), dashboardRoutes);
router.use("/admin/users", checkPermission("users"), userRoutes);
router.use("/workers", checkPermission("workers"), workerRoutes);
router.use("/kyc", checkPermission("kyc"), kycRoutes);
router.use("/admin/services", checkPermission("services"), serviceRoutes);
router.use("/admin/bookings", checkPermission("bookings"), bookingRoutes);
router.use("/admin/invoices", checkPermission("invoices"), invoiceRoutes);
router.use("/admin/complaints", checkPermission("complaints"), complaintRoutes);
router.use("/admin/locations", checkPermission("locations"), locationRoutes);
router.use("/app/locations", userLocationRoutes);
router.use("/user-addresses", userAddressRoutes);
router.use("/app/addresses", userAddressRoutes);
router.use("/app", appRoutes);
router.use("/bookings", appRoutes); // Alias route support for mobile app endpoints
router.use("/admin/sub-admins", subAdminRoutes);
router.use("/admin/notifications", checkPermission("notifications"), notificationRoutes);
router.use("/admin/banners", checkPermission("banners"), bannerRoutes);

// Admin reviews — accessible with admin token
router.get("/admin/reviews", auth, adminListReviews);

module.exports = router;

