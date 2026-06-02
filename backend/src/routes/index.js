const express = require("express");
const authRoutes = require("./auth.routes");
const dashboardRoutes = require("./dashboard.routes");
const userRoutes = require("./user.routes");
const workerRoutes = require("./worker.routes");
const kycRoutes = require("./kyc.routes");
const bookingRoutes = require("./booking.routes");
const invoiceRoutes = require("./invoice.routes");
const complaintRoutes = require("./complaint.routes");

const router = express.Router();

router.get("/health", (req, res) => {
  res.json({ success: true, message: "Backend is running" });
});

router.use("/auth", authRoutes);
router.use("/dashboard", dashboardRoutes);
router.use("/users", userRoutes);
router.use("/workers", workerRoutes);
router.use("/kyc", kycRoutes);
router.use("/admin/bookings", bookingRoutes);
router.use("/admin/invoices", invoiceRoutes);
router.use("/admin/complaints", complaintRoutes);

module.exports = router;
