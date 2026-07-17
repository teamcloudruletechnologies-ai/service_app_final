const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function create({ title, image_url, link_url, status }) {
  const result = await db.query(
    `INSERT INTO banners (title, image_url, link_url, status)
     VALUES ($1, $2, $3, COALESCE($4, 'active'))
     RETURNING *`,
    [title || null, image_url, link_url || null, status]
  );
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query("SELECT * FROM banners WHERE id = $1", [id]);
  return result.rows[0];
}

async function list({ page, limit, offset, search, status }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`(title ILIKE $${params.length})`);
  }

  if (status) {
    params.push(status);
    where.push(`status = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM banners ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT * FROM banners ${clause} ORDER BY id DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const allowed = ["title", "image_url", "link_url", "status"];
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
    `UPDATE banners SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING *`,
    params
  );
  return result.rows[0];
}

async function remove(id) {
  const result = await db.query("DELETE FROM banners WHERE id = $1 RETURNING *", [id]);
  return result.rows[0];
}

module.exports = { create, findById, list, update, remove };
