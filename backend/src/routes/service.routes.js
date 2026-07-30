const express = require("express");
const { body, param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/service.controller");
const upload = require("../middlewares/upload.middleware");

const router = express.Router();

// Restrict all routes in this file to ADMIN role
router.use(auth, allowRoles(roles.ADMIN));

// ==========================================
// CATEGORIES ROUTES
// ==========================================

router.get("/categories", controller.listCategories);

router.post(
  "/categories",
  upload.single("icon"),
  [
    body("name").trim().notEmpty().withMessage("Category name is required"),
    body("description").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.createCategory
);

router.put(
  "/categories/:id",
  upload.single("icon"),
  [
    param("id").isInt().withMessage("Valid category ID is required"),
    body("name").optional().trim().notEmpty().withMessage("Category name cannot be empty"),
    body("description").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.updateCategory
);

router.delete(
  "/categories/:id",
  [param("id").isInt().withMessage("Valid category ID is required")],
  validate,
  controller.deleteCategory
);

// ==========================================
// SERVICES ROUTES
// ==========================================

router.get(
  "/",
  [
    query("category_id").optional().isInt().withMessage("Category ID must be an integer"),
    query("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.listServices
);

router.post(
  "/",
  upload.single("image"),
  [
    body("name").trim().notEmpty().withMessage("Service name is required"),
    body("description").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.createService
);

router.put(
  "/:id",
  upload.single("image"),
  [
    param("id").isInt().withMessage("Valid service ID is required"),
    body("name").optional().trim().notEmpty().withMessage("Service name cannot be empty"),
    body("description").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.updateService
);

router.delete(
  "/:id",
  [param("id").isInt().withMessage("Valid service ID is required")],
  validate,
  controller.deleteService
);

router.patch(
  "/:id/status",
  [
    param("id").isInt().withMessage("Valid service ID is required"),
    body("status").isIn(["active", "inactive"]).withMessage("Status must be active or inactive"),
  ],
  validate,
  controller.updateServiceStatus
);

module.exports = router;
