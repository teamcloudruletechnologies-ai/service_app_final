const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const controller = require("../controllers/subAdmin.controller");
const db = require("../config/db");
const { error } = require("../utils/response");

const router = express.Router();

// Middleware to restrict endpoints to SUPER_ADMIN or default admin only
async function requireSuperAdmin(req, res, next) {
  if (!req.auth || req.auth.role !== "admin") {
    return error(res, "You do not have permission to access this resource", 403);
  }

  try {
    const result = await db.query("SELECT role, status FROM admins WHERE id = $1", [req.auth.id]);
    const admin = result.rows[0];

    if (!admin) {
      return error(res, "Admin account not found", 404);
    }

    if (admin.status !== "active") {
      return error(res, "Account is not active", 403);
    }

    // Only super_admin or default/legacy admin are allowed to manage sub-admins
    if (admin.role === "super_admin" || admin.role === "admin") {
      return next();
    }

    return error(res, "You do not have permission to access this resource", 403);
  } catch (err) {
    return next(err);
  }
}

// All sub-admin management routes require authentication and super-admin privileges
router.use(auth, requireSuperAdmin);

router.post(
  "/",
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("email").isEmail().normalizeEmail().withMessage("Valid email is required"),
    body("password").isLength({ min: 6 }).withMessage("Password must be at least 6 characters"),
    body("status").optional().isIn(["active", "inactive", "suspended"]),
    body("permissions").optional().isArray().withMessage("Permissions must be an array of strings"),
  ],
  validate,
  controller.createSubAdmin
);

router.get("/", controller.listSubAdmins);

router.get("/:id", [param("id").isInt()], validate, controller.getSubAdmin);

router.patch(
  "/:id",
  [
    param("id").isInt(),
    body("name").optional().trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("password").optional().isLength({ min: 6 }),
    body("status").optional().isIn(["active", "inactive", "suspended"]),
    body("permissions").optional().isArray().withMessage("Permissions must be an array of strings"),
  ],
  validate,
  controller.updateSubAdmin
);

router.delete("/:id", [param("id").isInt()], validate, controller.deleteSubAdmin);

module.exports = router;
