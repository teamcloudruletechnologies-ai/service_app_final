const express = require("express");
const { body, param, query } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/banner.controller");
const upload = require("../middlewares/upload.middleware");

const router = express.Router();

// Restrict all routes in this file to ADMIN role
router.use(auth, allowRoles(roles.ADMIN));

router.get("/", controller.listBanners);

router.post(
  "/",
  upload.single("image"),
  [
    body("title").optional().trim(),
    body("link_url").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.createBanner
);

router.put(
  "/:id",
  upload.single("image"),
  [
    param("id").isInt().withMessage("Valid banner ID is required"),
    body("title").optional().trim(),
    body("link_url").optional().trim(),
    body("status").optional().isIn(["active", "inactive"]),
  ],
  validate,
  controller.updateBanner
);

router.delete(
  "/:id",
  [param("id").isInt().withMessage("Valid banner ID is required")],
  validate,
  controller.deleteBanner
);

module.exports = router;
