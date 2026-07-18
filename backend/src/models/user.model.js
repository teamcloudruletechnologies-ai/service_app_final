const db = require("../config/db");
const { paged } = require("../utils/pagination");

const publicFields = "id, name, email, phone, state, address, status, credits, created_at, updated_at";

async function create(user) {
  const result = await db.query(
    `INSERT INTO users (name, email, phone, password_hash, state, address, status, credits)
     VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, 'active'), 0)
     RETURNING ${publicFields}`,
    [user.name || '', user.email || null, user.phone || null, user.passwordHash || null, user.state || null, user.address || null, user.status]
  );
  return result.rows[0];
}

async function findByEmailOrPhone(login) {
  const result = await db.query("SELECT * FROM users WHERE email = $1 OR phone = $1", [login]);
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(
    `SELECT u.id, u.name, u.email, u.phone, u.status, u.credits, u.created_at, u.updated_at,
            COUNT(b.id)::int as total_bookings,
            COALESCE(SUM(b.amount), 0)::float as total_spent
     FROM users u
     LEFT JOIN bookings b ON u.id = b.user_id
     WHERE u.id = $1
     GROUP BY u.id`,
    [id]
  );
  return result.rows[0];
}

async function list({ search, status, page, limit, offset, sortBy, sortOrder, created_after, created_before }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`(name ILIKE $${params.length} OR email ILIKE $${params.length} OR phone ILIKE $${params.length})`);
  }

  if (status) {
    params.push(status);
    where.push(`status = $${params.length}`);
  }

  if (created_after) {
    params.push(created_after);
    where.push(`created_at >= $${params.length}`);
  }

  if (created_before) {
    params.push(created_before);
    where.push(`created_at <= $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM users ${clause}`, params);

  const allowedSortFields = ["name", "email", "created_at", "status"];
  const sortField = allowedSortFields.includes(sortBy) ? sortBy : "created_at";
  const order = sortOrder === "ASC" ? "ASC" : "DESC";

  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${publicFields} FROM users ${clause} ORDER BY ${sortField} ${order} LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const allowed = ["name", "email", "phone", "status", "state", "address"];
  const sets = [];
  const params = [];

  for (const key of allowed) {
    if (values[key] !== undefined) {
      params.push(values[key]);
      sets.push(`${key} = $${params.length}`);
    }
  }

  if (!sets.length) return findById(id);

  params.push(id);
  const result = await db.query(
    `UPDATE users SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING ${publicFields}`,
    params
  );
  return result.rows[0];
}

async function remove(id) {
  const result = await db.query(`DELETE FROM users WHERE id = $1 RETURNING ${publicFields}`, [id]);
  return result.rows[0];
}

async function getBookings(userId) {
  const result = await db.query(
    `SELECT b.id, b.status, b.amount::float as amount, b.created_at,
            w.name as worker_name, w.service_type
     FROM bookings b
     LEFT JOIN workers w ON b.worker_id = w.id
     WHERE b.user_id = $1
     ORDER BY b.created_at DESC`,
    [userId]
  );
  return result.rows;
}

async function logActivity(userId, action, details) {
  const result = await db.query(
    `INSERT INTO activity_logs (user_id, action, details)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, action, details]
  );
  return result.rows[0];
}

async function getActivityLogs(userId, { limit = 100, offset = 0 } = {}) {
  const result = await db.query(
    `SELECT * FROM activity_logs
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );
  return result.rows;
}

async function awardCredits(userId, amount) {
  const result = await db.query(
    "UPDATE users SET credits = COALESCE(credits, 0) + $1 WHERE id = $2 RETURNING credits",
    [amount, userId]
  );
  return result.rows[0]?.credits || 0;
}

module.exports = { create, findByEmailOrPhone, findById, list, update, remove, getBookings, logActivity, getActivityLogs, awardCredits };
