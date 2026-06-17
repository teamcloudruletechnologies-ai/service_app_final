const express = require("express");
const { body, param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/app.controller");

const router = express.Router();

router.get("/services/categories", controller.listCategories);

router.get(
  "/services",
  [query("category_id").optional().isInt()],
  validate,
  controller.listServices
);

router.get("/services/:id", [param("id").isInt()], validate, controller.getService);

router.use(auth, allowRoles(roles.USER));

router.post(
  "/bookings",
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

router.get(
  "/bookings",
  [query("status").optional().isIn(["pending", "confirmed", "in_progress", "completed", "cancelled"])],
  validate,
  controller.listMyBookings
);

router.get("/bookings/:id", [param("id").isInt()], validate, controller.getMyBooking);

router.patch("/bookings/:id/cancel", [param("id").isInt()], validate, controller.cancelBooking);

module.exports = router;
