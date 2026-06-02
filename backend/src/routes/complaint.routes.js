const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/complaint.controller");

const router = express.Router();

// All complaint routes are admin-only in this context
router.use(auth, allowRoles(roles.ADMIN));

router.get("/", controller.listComplaints);

router.get("/:id", [param("id").isInt()], validate, controller.getComplaint);

router.patch(
  "/:id/status",
  [
    param("id").isInt(),
    body("status").isIn(["Open", "Under Review", "In Progress", "Resolved", "Closed"])
  ],
  validate,
  controller.updateComplaintStatus
);

router.post(
  "/:id/notes",
  [
    param("id").isInt(),
    body("note").trim().notEmpty()
  ],
  validate,
  controller.addComplaintNote
);

module.exports = router;
