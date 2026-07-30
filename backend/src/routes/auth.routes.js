const express = require("express");
const { body } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { authLimiter } = require("../middlewares/rateLimit.middleware");
const controller = require("../controllers/auth.controller");

const router = express.Router();

router.post(
  "/admin/register",
  [
    body("name").trim().notEmpty(),
    body("email").isEmail().normalizeEmail(),
    body("password").isLength({ min: 6 }),
  ],
  validate,
  controller.registerAdmin
);

router.post(
  "/user/register",
  [
    body("name").trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("phone").optional().trim().notEmpty(),
    body("password").optional().isLength({ min: 6 }),
  ],
  validate,
  controller.registerUser
);

router.post(
  "/worker/register",
  [
    body("name").trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("phone").trim().notEmpty(),
    body("password").optional().isLength({ min: 6 }),
  ],
  validate,
  controller.registerWorker
);

router.post(
  "/login",
  authLimiter,
  [
    body("login").trim().notEmpty(),
    body("password").notEmpty(),
    body("role").isIn(["admin", "user", "worker"]),
  ],
  validate,
  controller.login
);

router.post(
  "/phone-login",
  [
    body("phone").trim().notEmpty().withMessage("Phone number is required"),
    body("role").isIn(["user", "worker"]).withMessage("Invalid role"),
  ],
  validate,
  controller.phoneLogin
);

router.get("/me", auth, controller.me);

module.exports = router;
