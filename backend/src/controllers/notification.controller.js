const notificationModel = require("../models/notification.model");
const { success, error } = require("../utils/response");

async function listNotifications(req, res, next) {
  try {
    const { page, limit, read, type } = req.query;
    const result = await notificationModel.listNotifications({
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 10,
      read,
      type
    });
    return success(res, "Notifications retrieved successfully", result);
  } catch (err) {
    return next(err);
  }
}

async function markNotificationRead(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const updated = await notificationModel.markNotificationRead(id);
    if (!updated) {
      return error(res, "Notification not found", 404);
    }
    return success(res, "Notification marked as read successfully", updated);
  } catch (err) {
    return next(err);
  }
}

async function markAllNotificationsRead(req, res, next) {
  try {
    const count = await notificationModel.markAllNotificationsRead();
    return success(res, `Successfully marked all notifications as read (${count} updated)`);
  } catch (err) {
    return next(err);
  }
}

async function deleteNotification(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const deleted = await notificationModel.deleteNotification(id);
    if (!deleted) {
      return error(res, "Notification not found", 404);
    }
    return success(res, "Notification deleted successfully");
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  deleteNotification
};
