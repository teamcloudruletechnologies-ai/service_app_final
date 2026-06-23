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

// User profile update (online status, city, service type, experience)
router.patch(
  "/worker/profile",
  allowRoles(roles.WORKER),
  [
    body("status").optional().isIn(["active", "inactive"]),
    body("city").optional().isString(),
    body("pincode").optional().isString(),
    body("serviceType").optional().isString(),
    body("experienceYears").optional().isInt({ min: 0 }),
  ],
  validate,
  controller.updateWorkerProfile
);

// User profile update (name, email)
router.patch(
  "/user/profile",
  allowRoles(roles.USER),
  [
    body("name").optional().trim().notEmpty().withMessage("Name cannot be empty"),
    body("email").optional().isEmail().withMessage("Must be a valid email").normalizeEmail(),
  ],
  validate,
  controller.updateUserProfile
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

module.exports = router;
