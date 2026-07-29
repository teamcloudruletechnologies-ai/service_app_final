const express = require("express");
const { body, param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/app.controller");
const upload = require("../middlewares/upload.middleware");

const router = express.Router();

router.get("/services/categories", controller.listCategories);
// GET sub-categories of a specific parent category
router.get("/services/categories/:id/subcategories", [param("id").isInt()], validate, controller.listSubCategories);
router.get("/banners", controller.listActiveBanners);

router.get(
  "/services",
  [query("category_id").optional().isInt()],
  validate,
  controller.listServices
);

router.get("/services/:id", [param("id").isInt()], validate, controller.getService);

router.use(auth);

// Generic upload endpoint for KYC files / selfies
router.post(
  "/upload",
  upload.single("file"),
  async (req, res, next) => {
    try {
      const { saveUpload } = require("../utils/fileUpload");
      if (!req.file) {
        return res.status(400).json({ success: false, message: "No file provided" });
      }
      const fileUrl = await saveUpload(req.file, "kyc");
      res.json({ success: true, data: { url: fileUrl } });
    } catch (err) {
      next(err);
    }
  }
);

// Worker profile update (onboarding details + status)
router.patch(
  "/worker/profile",
  allowRoles(roles.WORKER),
  [
    body("name").optional().trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("status").optional().isIn(["active", "inactive"]),
    body("city").optional().isString(),
    body("state").optional().isString(),
    body("address").optional().isString(),
    body("pincode").optional().isString(),
    body("serviceType").optional().isString(),
    body("experienceYears").optional().isInt({ min: 0 }),
  ],
  validate,
  controller.updateWorkerProfile
);

router.get(
  "/worker/earnings",
  allowRoles(roles.WORKER),
  controller.getWorkerEarnings
);

// User profile update (name, email, phone, state, address)
router.patch(
  "/user/profile",
  allowRoles(roles.USER),
  [
    body("name").optional().trim().notEmpty().withMessage("Name cannot be empty"),
    body("email").optional().isEmail().withMessage("Must be a valid email").normalizeEmail(),
    body("phone").optional().trim().notEmpty().withMessage("Phone cannot be empty"),
    body("state").optional().trim().notEmpty(),
    body("address").optional().trim().notEmpty(),
  ],
  validate,
  controller.updateUserProfile
// FCM token update routes
router.post(
  "/user/fcm-token",
  allowRoles(roles.USER),
  [body("fcmToken").trim().notEmpty()],
  validate,
  controller.updateUserFcmToken
);

router.post(
  "/worker/fcm-token",
  allowRoles(roles.WORKER),
  [body("fcmToken").trim().notEmpty()],
  validate,
  controller.updateWorkerFcmToken
);

// User-only routes
router.post(
  "/bookings",
  allowRoles(roles.USER),
  [
    body("service_id").isInt(),
    body("worker_id").optional().isInt(),
    body("address").trim().notEmpty(),
    body("notes").optional().trim(),
    body("scheduled_at").optional().isISO8601(),
  ],
  validate,
  controller.createBooking
);

router.patch(
  "/bookings/:id/cancel",
  allowRoles(roles.USER),
  [param("id").isInt()],
  validate,
  controller.cancelBooking
);

// Common routes (accessible by both USER and WORKER)
router.get(
  "/bookings",
  allowRoles(roles.USER, roles.WORKER),
  [query("status").optional().isIn(["pending", "confirmed", "in_progress", "completed", "cancelled"])],
  validate,
  controller.listMyBookings
);

router.get(
  "/bookings/:id",
  allowRoles(roles.USER, roles.WORKER),
  [param("id").isInt()],
  validate,
  controller.getMyBooking
);

router.patch(
  "/bookings/:id/status",
  allowRoles(roles.USER, roles.WORKER),
  [
    param("id").isInt(),
    body("status").isIn(["confirmed", "in_progress", "completed", "cancelled"]),
  ],
  validate,
  controller.updateMyBookingStatus
);

router.post(
  "/bookings/:id/start-job",
  allowRoles(roles.WORKER, roles.ADMIN),
  upload.single("photo"),
  [param("id").isInt()],
  validate,
  controller.startJobPhoto
);

router.post(
  "/bookings/:id/complete-job",
  allowRoles(roles.WORKER, roles.ADMIN),
  upload.single("photo"),
  [param("id").isInt()],
  validate,
  controller.completeJobPhoto
);

router.post(
  "/bookings/:id/submit-invoice",
  allowRoles(roles.WORKER, roles.ADMIN),
  [param("id").isInt(), body("totalAmount").isNumeric()],
  validate,
  controller.submitWorkerInvoice
);

const paymentController = require("../controllers/payment.controller");
const reviewController = require("../controllers/review.controller");

router.post(
  "/payments/order",
  allowRoles(roles.USER),
  [body("bookingId").isInt()],
  validate,
  paymentController.createOrder
);

router.post(
  "/payments/verify",
  allowRoles(roles.USER),
  [
    body("bookingId").isInt(),
    body("razorpayPaymentId").trim().notEmpty(),
    body("razorpaySignature").trim().notEmpty(),
    body("razorpayOrderId").trim().notEmpty(),
  ],
  validate,
  paymentController.verifyPayment
);

router.post(
  "/reviews",
  allowRoles(roles.USER),
  [
    body("bookingId").isInt(),
    body("rating").isInt({ min: 1, max: 5 }),
    body("comment").optional().trim(),
  ],
  validate,
  reviewController.createReview
);

router.get(
  "/reviews",
  [
    query("workerId").optional().isInt(),
    query("rating").optional().isInt({ min: 1, max: 5 }),
  ],
  validate,
  reviewController.listReviews
);

module.exports = router;
