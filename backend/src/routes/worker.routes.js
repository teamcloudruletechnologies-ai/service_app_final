const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/worker.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));

router.get("/", controller.listWorkers);
router.get("/:id", [param("id").isInt()], validate, controller.getWorker);
router.post(
  "/",
  [
    body("name").trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("phone").trim().notEmpty(),
    body("password").optional().isLength({ min: 6 }),
    body("experienceYears").optional().isInt({ min: 0 }),
    body("status").optional().isIn(["active", "inactive", "pending", "suspended"]),
  ],
  validate,
  controller.createWorker
);
router.patch(
  "/:id",
  [
    param("id").isInt(),
    body("email").optional().isEmail().normalizeEmail(),
    body("experienceYears").optional().isInt({ min: 0 }),
    body("status").optional().isIn(["active", "inactive", "pending", "suspended"]),
    body("kycStatus").optional().isIn(["not_submitted", "pending", "approved", "rejected"]),
  ],
  validate,
  controller.updateWorker
);
router.delete("/:id", [param("id").isInt()], validate, controller.deleteWorker);
router.patch("/:id/activate", [param("id").isInt()], validate, controller.activateWorker);
router.patch("/:id/suspend", [param("id").isInt()], validate, controller.suspendWorker);
router.get("/:id/performance", [param("id").isInt()], validate, controller.getWorkerPerformance);

module.exports = router;
