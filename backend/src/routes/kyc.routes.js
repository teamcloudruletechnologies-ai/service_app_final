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
    body("documentType").trim().notEmpty(),
    body("documentNumber").trim().notEmpty(),
    body("documentUrl").optional().isString(),
    body("selfieUrl").optional().isString(),
  ],
  validate,
  controller.submitKyc
);

router.get("/", auth, allowRoles(roles.ADMIN), controller.listKyc);
router.get("/:id", auth, allowRoles(roles.ADMIN), [param("id").isInt()], validate, controller.getKyc);
router.patch(
  "/:id/review",
  auth,
  allowRoles(roles.ADMIN),
  [
    param("id").isInt(),
    body("status").isIn(["approved", "rejected"]),
    body("rejectionReason").optional().isString(),
  ],
  validate,
  controller.reviewKyc
);

module.exports = router;
