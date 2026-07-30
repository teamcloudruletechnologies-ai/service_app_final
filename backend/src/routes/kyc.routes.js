const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/kyc.controller");

const router = express.Router();

router.post(
  "/",
  auth,
  allowRoles(roles.ADMIN, roles.WORKER),
  [
    body("workerId").if((value, { req }) => req.auth.role === roles.ADMIN).isInt(),
    body("aadhaarNumber").trim().notEmpty(),
    body("aadhaarUrl").trim().notEmpty().isString(),
    body("panNumber").trim().notEmpty(),
    body("panUrl").trim().notEmpty().isString(),
    body("bankAccountNumber").trim().notEmpty(),
    body("bankPassbookUrl").trim().notEmpty().isString(),
    body("selfieUrl").trim().notEmpty().isString(),
  ],
  validate,
  controller.submitKyc
);

router.get("/", auth, allowRoles(roles.ADMIN, roles.WORKER), controller.listKyc);
router.get("/:id", auth, allowRoles(roles.ADMIN), [param("id").isInt()], validate, controller.getKyc);

router.patch(
  "/:id/review",
  auth,
  allowRoles(roles.ADMIN),
  [
    param("id").isInt(),
    body("aadhaarStatus").optional().isIn(["pending", "approved", "rejected"]),
    body("panStatus").optional().isIn(["pending", "approved", "rejected"]),
    body("bankPassbookStatus").optional().isIn(["pending", "approved", "rejected"]),
    body("selfieStatus").optional().isIn(["pending", "approved", "rejected"]),
    body("rejectionReason").optional({ nullable: true }).isString(),
  ],
  validate,
  controller.reviewKyc
);

module.exports = router;
