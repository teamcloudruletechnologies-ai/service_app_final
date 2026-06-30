const express = require("express");
const { query, body } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/user-location.controller");

const router = express.Router();

// PUBLIC: Get all active serviceable pincodes/zones (no auth needed)
// Used by user & worker apps to show available service areas
router.get("/serviceable", controller.getServiceableLocations);

// All routes below require authentication
router.use(auth);

router.get(
  "/nearby",
  [
    query("lat").isNumeric(),
    query("lng").isNumeric(),
    query("service_type").optional().isString(),
    query("radius").optional().isNumeric(),
  ],
  validate,
  controller.findNearbyWorkers
);

router.get(
  "/by-pincode",
  [
    query("pincode").isString().notEmpty(),
    query("service_type").optional().isString(),
    query("radius").optional().isNumeric(),
  ],
  validate,
  controller.findWorkersByPincode
);

router.post(
  "/update-my-location",
  allowRoles(roles.WORKER),
  [
    body("lat").isNumeric(),
    body("lng").isNumeric(),
    body("pincode").optional().isString(),
  ],
  validate,
  controller.updateMyLocation
);

module.exports = router;
