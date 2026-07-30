const express = require("express");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/dashboard.controller");

const router = express.Router();



router.get("/overview", auth, allowRoles(roles.ADMIN), controller.overview);

module.exports = router;
