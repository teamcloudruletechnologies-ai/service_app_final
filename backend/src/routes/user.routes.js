const express = require("express");
const { body, param } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/user.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));

router.get("/", controller.listUsers);
router.get("/:id", [param("id").isInt()], validate, controller.getUser);
router.post(
  "/",
  [
    body("name").trim().notEmpty(),
    body("email").optional().isEmail().normalizeEmail(),
    body("phone").optional().trim().notEmpty(),
    body("password").optional().isLength({ min: 6 }),
    body("status").optional().isIn(["active", "inactive", "suspended"]),
  ],
  validate,
  controller.createUser
);
router.patch(
  "/:id",
  [
    param("id").isInt(),
    body("email").optional().isEmail().normalizeEmail(),
    body("status").optional().isIn(["active", "inactive", "suspended"]),
  ],
  validate,
  controller.updateUser
);
router.delete("/:id", [param("id").isInt()], validate, controller.deleteUser);

module.exports = router;
