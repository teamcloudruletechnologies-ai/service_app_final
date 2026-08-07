const express = require("express");
const auth = require("../middlewares/auth.middleware");
const controller = require("../controllers/app-notification.controller");

const router = express.Router();

router.use(auth);

router.get("/", controller.listMyNotifications);
router.patch("/read-all", controller.markAllMyNotificationsRead);
router.patch("/:id/read", controller.markMyNotificationRead);
router.delete("/:id", controller.deleteMyNotification);

module.exports = router;
