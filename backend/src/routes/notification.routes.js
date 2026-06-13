const express = require("express");
const auth = require("../middlewares/auth.middleware");
const controller = require("../controllers/notification.controller");

const router = express.Router();

// All notification routes require authentication
router.use(auth);

router.get("/", controller.listNotifications);
router.patch("/read-all", controller.markAllNotificationsRead);
router.patch("/:id/read", controller.markNotificationRead);
router.delete("/:id", controller.deleteNotification);

module.exports = router;
