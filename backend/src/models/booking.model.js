const db = require("../config/db");
const { paged } = require("../utils/pagination");

const listFields = `
  b.id,
  b.user_id,
  u.name AS user_name,
  u.phone AS user_phone,
  b.worker_id,
  w.name AS worker_name,
  w.phone AS worker_phone,
  w.service_type,
  b.status,
  b.amount::float AS amount,
  b.created_at,
  b.updated_at
`;

async function list({ status, userId, workerId, page, limit, offset }) {
  const params = [];
  const where = [];

  if (status) {
    params.push(status);
    where.push(`b.status = $${params.length}`);
  }

  if (userId) {
    params.push(userId);
    where.push(`b.user_id = $${params.length}`);
  }

  if (workerId) {
    params.push(workerId);
    where.push(`b.worker_id = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM bookings b ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${listFields}
     FROM bookings b
     LEFT JOIN users u ON u.id = b.user_id
     LEFT JOIN workers w ON w.id = b.worker_id
     ${clause}
     ORDER BY b.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function findById(id) {
  const result = await db.query(
    `SELECT ${listFields}
     FROM bookings b
     LEFT JOIN users u ON u.id = b.user_id
     LEFT JOIN workers w ON w.id = b.worker_id
     WHERE b.id = $1`,
    [id]
  );
  return result.rows[0];
}

async function updateStatus(id, status) {
  const result = await db.query(
    `UPDATE bookings
     SET status = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING id`,
    [status, id]
  );

  if (!result.rows[0]) return null;
  return findById(result.rows[0].id);
}

async function analytics() {
  const [summary, byStatus, revenueByStatus, recent] = await Promise.all([
    db.query(
      `SELECT
        COUNT(*)::int AS total_bookings,
        COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_bookings,
        COUNT(*) FILTER (WHERE status = 'confirmed')::int AS confirmed_bookings,
        COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_bookings,
        COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_bookings,
        COALESCE(SUM(amount), 0)::float AS total_amount,
        COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0)::float AS completed_amount
       FROM bookings`
    ),
    db.query("SELECT status, COUNT(*)::int AS total FROM bookings GROUP BY status ORDER BY total DESC"),
    db.query(
      `SELECT status, COALESCE(SUM(amount), 0)::float AS amount
       FROM bookings
       GROUP BY status
       ORDER BY amount DESC`
    ),
    db.query(
      `SELECT DATE(created_at) AS date, COUNT(*)::int AS total, COALESCE(SUM(amount), 0)::float AS amount
       FROM bookings
       WHERE created_at >= NOW() - INTERVAL '30 days'
       GROUP BY DATE(created_at)
       ORDER BY date DESC`
    ),
  ]);

  return {
    summary: summary.rows[0],
    byStatus: byStatus.rows,
    revenueByStatus: revenueByStatus.rows,
    recent: recent.rows,
  };
}

module.exports = { list, findById, updateStatus, analytics };
