const db = require("../config/db");

async function listNotifications({ page = 1, limit = 10, read, type } = {}) {
  const offset = (page - 1) * limit;
  const queryParams = [];
  let whereClauses = [];

  if (read !== undefined && read !== "") {
    queryParams.push(read === "read" || read === "true");
    whereClauses.push(`read = $${queryParams.length}`);
  }

  if (type !== undefined && type !== "") {
    queryParams.push(type);
    whereClauses.push(`type = $${queryParams.length}`);
  }

  const whereSql = whereClauses.length > 0 ? "WHERE " + whereClauses.join(" AND ") : "";

  // Get total count
  const countRes = await db.query(
    `SELECT COUNT(*) as total FROM notifications ${whereSql}`,
    queryParams
  );
  const total = parseInt(countRes.rows[0].total, 10);
  const totalPages = Math.ceil(total / limit) || 1;

  // Get paginated rows
  const limitIndex = queryParams.length + 1;
  const offsetIndex = queryParams.length + 2;
  const selectParams = [...queryParams, limit, offset];

  const rowsRes = await db.query(
    `SELECT * FROM notifications ${whereSql} ORDER BY created_at DESC LIMIT $${limitIndex} OFFSET $${offsetIndex}`,
    selectParams
  );

  return {
    rows: rowsRes.rows,
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages
    }
  };
}

async function markNotificationRead(id) {
  const result = await db.query(
    "UPDATE notifications SET read = TRUE, updated_at = NOW() WHERE id = $1 RETURNING *",
    [id]
  );
  return result.rows[0];
}

async function markAllNotificationsRead() {
  const result = await db.query(
    "UPDATE notifications SET read = TRUE, updated_at = NOW() WHERE read = FALSE RETURNING id"
  );
  return result.rowCount;
}

async function deleteNotification(id) {
  const result = await db.query(
    "DELETE FROM notifications WHERE id = $1 RETURNING id",
    [id]
  );
  return result.rowCount > 0;
}

module.exports = {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  deleteNotification
};
