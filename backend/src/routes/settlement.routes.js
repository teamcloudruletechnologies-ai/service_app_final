const express = require("express");
const auth = require("../middlewares/auth.middleware");
const allowRoles = require("../middlewares/rbac.middleware");
const roles = require("../constants/roles");
const controller = require("../controllers/settlement.controller");

const router = express.Router();

router.use(auth, allowRoles(roles.ADMIN));

router.get("/unsettled", controller.getUnsettled);
router.post("/pay", controller.createPayout);
router.get("/history", controller.getHistory);
router.get("/summary", controller.getSummary);
router.get("/revenue-breakdown", controller.getRevenueBreakdown);

module.exports = router;
