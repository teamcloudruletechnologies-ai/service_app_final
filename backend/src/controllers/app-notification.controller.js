const notificationModel = require("../models/notification.model");
const { success, error } = require("../utils/response");
const db = require("../config/db");

async function listMyNotifications(req, res, next) {
  try {
    const { page, limit, read } = req.query;
    const entityId = req.auth.id;
    const type = req.auth.role === 'worker' ? 'worker_push' : 'user_push';

    const result = await notificationModel.listNotifications({
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 10,
      read,
      type,
      entityId
    });
    return success(res, "Notifications retrieved successfully", result);
  } catch (err) {
    return next(err);
  }
}

async function markMyNotificationRead(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const entityId = req.auth.id;
    const type = req.auth.role === 'worker' ? 'worker_push' : 'user_push';

    // Verify ownership
    const check = await db.query("SELECT id FROM notifications WHERE id = $1 AND entity_id = $2 AND type = $3", [id, entityId, type]);
    if (check.rowCount === 0) {
      return error(res, "Notification not found", 404);
    }

    const updated = await notificationModel.markNotificationRead(id);
    return success(res, "Notification marked as read", updated);
  } catch (err) {
    return next(err);
  }
}

async function markAllMyNotificationsRead(req, res, next) {
  try {
    const entityId = req.auth.id;
    const type = req.auth.role === 'worker' ? 'worker_push' : 'user_push';

    const result = await db.query(
      "UPDATE notifications SET read = TRUE, updated_at = NOW() WHERE entity_id = $1 AND type = $2 AND read = FALSE RETURNING id",
      [entityId, type]
    );
    return success(res, `Successfully marked all notifications as read (${result.rowCount} updated)`);
  } catch (err) {
    return next(err);
  }
}

async function deleteMyNotification(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const entityId = req.auth.id;
    const type = req.auth.role === 'worker' ? 'worker_push' : 'user_push';

    // Verify ownership
    const check = await db.query("SELECT id FROM notifications WHERE id = $1 AND entity_id = $2 AND type = $3", [id, entityId, type]);
    if (check.rowCount === 0) {
      return error(res, "Notification not found", 404);
    }

    const deleted = await notificationModel.deleteNotification(id);
    return success(res, "Notification deleted successfully");
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listMyNotifications,
  markMyNotificationRead,
  markAllMyNotificationsRead,
  deleteMyNotification
};
