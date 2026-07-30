const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function create({ name, description, icon_url, status, parent_id }) {
  const result = await db.query(
    `INSERT INTO service_categories (name, description, icon_url, status, parent_id)
     VALUES ($1, $2, $3, COALESCE($4, 'active'), $5)
     RETURNING *`,
    [name, description, icon_url || null, status, parent_id || null]
  );
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query("SELECT * FROM service_categories WHERE id = $1", [id]);
  return result.rows[0];
}

async function findByName(name) {
  const result = await db.query("SELECT * FROM service_categories WHERE name = $1", [name]);
  return result.rows[0];
}

async function list({ page, limit, offset, search, status, parent_id, include_root = true }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`(name ILIKE $${params.length} OR description ILIKE $${params.length})`);
  }

  if (status) {
    params.push(status);
    where.push(`status = $${params.length}`);
  }

  if (parent_id !== undefined) {
    if (parent_id === null) {
      where.push(`parent_id IS NULL`);
    } else {
      params.push(parent_id);
      where.push(`parent_id = $${params.length}`);
    }
  } else if (!include_root) {
    where.push(`parent_id IS NOT NULL`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM service_categories ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT * FROM service_categories ${clause} ORDER BY name ASC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function listSubCategories(parent_id, options = {}) {
  return list({ ...options, parent_id });
}

async function update(id, values) {
  const allowed = ["name", "description", "icon_url", "status", "parent_id"];
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
    `UPDATE service_categories SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING *`,
    params
  );
  return result.rows[0];
}

async function remove(id) {
  const result = await db.query("DELETE FROM service_categories WHERE id = $1 RETURNING *", [id]);
  return result.rows[0];
}

module.exports = { create, findById, findByName, list, listSubCategories, update, remove };
