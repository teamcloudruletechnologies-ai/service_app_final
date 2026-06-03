const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/location.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));

// Zones
router.get("/zones", controller.getZones);
router.post(
  "/zones",
  [
    body("name").trim().notEmpty(),
    body("city").trim().optional(),
    body("radius_km").optional().isNumeric(),
    body("center_lat").optional().isNumeric(),
    body("center_lng").optional().isNumeric(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.createZone
);
router.put(
  "/zones/:id",
  [
    param("id").isInt(),
    body("name").trim().optional(),
    body("city").trim().optional(),
    body("radius_km").optional().isNumeric(),
    body("center_lat").optional().isNumeric(),
    body("center_lng").optional().isNumeric(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.updateZone
);
router.delete("/zones/:id", [param("id").isInt()], validate, controller.deleteZone);
router.patch(
  "/zones/:id/status",
  [param("id").isInt(), body("status").isIn(["active", "inactive"])],
  validate,
  controller.updateZoneStatus
);

// Pincodes
router.get("/pincodes", controller.getPincodes);
router.post(
  "/pincodes",
  [
    body("code").trim().notEmpty(),
    body("zone_id").optional().isInt(),
    body("lat").optional().isNumeric(),
    body("lng").optional().isNumeric(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.createPincode
);
router.delete("/pincodes/:id", [param("id").isInt()], validate, controller.deletePincode);

// Worker Live Location
router.get("/worker-live/:workerId", [param("workerId").isInt()], validate, controller.getWorkerLiveLocation);

module.exports = router;
