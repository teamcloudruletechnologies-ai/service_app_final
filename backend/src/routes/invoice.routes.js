const express = require("express");
const { param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/invoice.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));



router.get(
  "/",
  [
    query("status").optional().isIn(["pending_approval", "pending", "approved", "paid", "failed", "refunded", "cancelled"]),
    query("userId").optional().isInt(),
    query("workerId").optional().isInt(),
  ],
  validate,
  controller.listInvoices
);

router.get("/payments", controller.listPayments);
router.get("/reports", controller.getInvoiceReports);
router.get("/payouts", controller.getInvoicePayouts);
router.patch("/:id/status", [param("id").isInt()], validate, controller.updateInvoiceStatus);
router.get("/:id", [param("id").isInt()], validate, controller.getInvoice);

module.exports = router;
