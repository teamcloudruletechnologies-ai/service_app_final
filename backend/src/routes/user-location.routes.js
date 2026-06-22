const express = require("express");
const { query, body } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/user-location.controller");

const router = express.Router();

// Depending on your auth strategy for users, you might want to require 'auth' and 'allowRoles(roles.USER)'
// For now, assuming these are accessible by authenticated users.
// If roles.USER doesn't exist, we just check auth.
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
