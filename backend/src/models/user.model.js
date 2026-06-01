const db = require("../config/db");
const { paged } = require("../utils/pagination");

const publicFields = "id, name, email, phone, status, created_at, updated_at";

async function create(user) {
  const result = await db.query(
    `INSERT INTO users (name, email, phone, password_hash, status)
     VALUES ($1, $2, $3, $4, COALESCE($5, 'active'))
     RETURNING ${publicFields}`,
    [user.name, user.email || null, user.phone || null, user.passwordHash || null, user.status]
  );
  return result.rows[0];
}

async function findByEmailOrPhone(login) {
  const result = await db.query("SELECT * FROM users WHERE email = $1 OR phone = $1", [login]);
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(`SELECT ${publicFields} FROM users WHERE id = $1`, [id]);
  return result.rows[0];
}

async function list({ search, status, page, limit, offset }) {
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

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM users ${clause}`, params);
  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${publicFields} FROM users ${clause} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const allowed = ["name", "email", "phone", "status"];
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

module.exports = { create, findByEmailOrPhone, findById, list, update, remove };
