const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function create({ name, image_url, status }) {
  const result = await db.query(
    `INSERT INTO services (name, image_url, status)
     VALUES ($1, $2, COALESCE($3, 'active'))
     RETURNING *`,
    [name, image_url || null, status]
  );
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(
    `SELECT s.*, c.name AS category_name
     FROM services s
     LEFT JOIN service_categories c ON s.category_id = c.id
     WHERE s.id = $1`,
    [id]
  );
  return result.rows[0];
}

async function findByName(name) {
  const result = await db.query("SELECT * FROM services WHERE name = $1", [name]);
  return result.rows[0];
}

async function list({ page, limit, offset, search, status }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`s.name ILIKE $${params.length}`);
  }

  if (status) {
    params.push(status);
    where.push(`s.status = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(
    `SELECT COUNT(*) FROM services s ${clause}`,
    params
  );

  params.push(limit, offset);
  const result = await db.query(
    `SELECT s.id, s.name, s.image_url, s.status, s.created_at, s.updated_at
     FROM services s
     ${clause}
     ORDER BY s.name ASC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const allowed = ["name", "image_url", "status"];
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
    `UPDATE services SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING *`,
    params
  );
  return result.rows[0];
}

async function remove(id) {
  const result = await db.query("DELETE FROM services WHERE id = $1 RETURNING *", [id]);
  return result.rows[0];
}

module.exports = { create, findById, findByName, list, update, remove };
