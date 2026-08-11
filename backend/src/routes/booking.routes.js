const express = require("express");
const { body, param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/booking.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));

router.get(
  "/",
  [
    query("status").optional().isIn(["pending", "matching", "assigned", "accepted", "arriving", "otp_verified", "in_progress", "extra_cost_pending", "exception_pending", "completed", "payment_pending", "paid", "closed", "rejected", "reassignment_required", "cancelled", "confirmed"]),
    query("userId").optional().isInt(),
    query("workerId").optional().isInt(),
  ],
  validate,
  controller.listBookings
);

router.get("/analytics", controller.getBookingAnalytics);
router.get("/:id", [param("id").isInt()], validate, controller.getBooking);

router.patch(
  "/:id/status",
  [
    param("id").isInt(),
    body("status").isIn(["pending", "matching", "assigned", "accepted", "arriving", "otp_verified", "in_progress", "extra_cost_pending", "exception_pending", "completed", "payment_pending", "paid", "closed", "rejected", "reassignment_required", "cancelled", "confirmed"]),
  ],
  validate,
  controller.updateBookingStatus
);

module.exports = router;
