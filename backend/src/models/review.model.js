const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function create({ bookingId, userId, workerId, rating, comment }) {
  // Insert the review
  const result = await db.query(
    `INSERT INTO reviews (booking_id, user_id, worker_id, rating, comment, created_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     RETURNING *`,
    [bookingId, userId, workerId, rating, comment]
  );

  // Recalculate average rating for the worker
  await db.query(
    `UPDATE workers
     SET rating = (SELECT COALESCE(AVG(rating), 4.5) FROM reviews WHERE worker_id = $1)
     WHERE id = $1`,
    [workerId]
  );

  return result.rows[0];
}

async function list({ workerId, rating, page = 1, limit = 10, offset = 0 }) {
  const params = [];
  const where = [];

  if (workerId) {
    params.push(workerId);
    where.push(`r.worker_id = $${params.length}`);
  }

  if (rating) {
    params.push(rating);
    where.push(`r.rating = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM reviews r ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT r.*, u.name as user_name, w.name as worker_name
     FROM reviews r
     LEFT JOIN users u ON u.id = r.user_id
     LEFT JOIN workers w ON w.id = r.worker_id
     ${clause}
     ORDER BY r.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function findByBookingId(bookingId) {
  const result = await db.query(
    `SELECT r.*, u.name as user_name FROM reviews r LEFT JOIN users u ON u.id = r.user_id WHERE r.booking_id = $1`,
    [bookingId]
  );
  return result.rows[0];
}

module.exports = {
  create,
  list,
  findByBookingId,
};
