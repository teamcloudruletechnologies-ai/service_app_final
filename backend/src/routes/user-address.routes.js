const express = require("express");
const { body } = require("express-validator");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const validate = require("../middlewares/validate.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/user-address.controller");

const router = express.Router();

// All routes require authentication as USER
router.use(auth);
router.use(allowRoles(roles.USER, roles.ADMIN));

router.get("/", controller.listMyAddresses);

router.get("/:id", controller.getAddressById);

router.post(
  "/",
  [
    body("address_line").isString().notEmpty().withMessage("Address line is required"),
    body("title").optional().isString(),
    body("city").optional().isString(),
    body("state").optional().isString(),
    body("pincode").optional().isString(),
    body("landmark").optional().isString(),
    body("lat").optional().isNumeric(),
    body("lng").optional().isNumeric(),
    body("is_default").optional().isBoolean(),
  ],
  validate,
  controller.createAddress
);

router.put(
  "/:id",
  [
    body("address_line").optional().isString().notEmpty(),
    body("title").optional().isString(),
    body("city").optional().isString(),
    body("state").optional().isString(),
    body("pincode").optional().isString(),
    body("landmark").optional().isString(),
    body("lat").optional().isNumeric(),
    body("lng").optional().isNumeric(),
    body("is_default").optional().isBoolean(),
  ],
  validate,
  controller.updateAddress
);

router.delete("/:id", controller.deleteAddress);

router.patch("/:id/default", controller.setDefaultAddress);

module.exports = router;
