const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function create({ category_id, name, description, image_url, status, icon, price, estimated_time }) {
  const result = await db.query(
    `INSERT INTO services (category_id, name, description, image_url, status, icon, price, estimated_time)
     VALUES ($1, $2, $3, $4, COALESCE($5, 'active'), $6, $7, $8)
     RETURNING *`,
    [category_id || null, name, description || null, image_url || null, status, icon || null, price || 0, estimated_time || 60]
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

async function list({ page, limit, offset, search, category_id, status }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`(s.name ILIKE $${params.length} OR s.description ILIKE $${params.length})`);
  }

  if (category_id) {
    params.push(category_id);
    where.push(`s.category_id = $${params.length}`);
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
    `SELECT s.*, c.name AS category_name,
       COALESCE(avg_r.avg_rating, 4.5)::float AS avg_rating,
       COALESCE(avg_r.total_reviews, 0)::int AS total_reviews,
       COALESCE(bk_count.total_bookings, 0)::int AS total_bookings
     FROM services s
     LEFT JOIN service_categories c ON s.category_id = c.id
     LEFT JOIN (
       SELECT bk.service_id, AVG(r.rating)::numeric(3,2) AS avg_rating, COUNT(*)::int AS total_reviews
       FROM reviews r
       JOIN bookings bk ON r.booking_id = bk.id
       GROUP BY bk.service_id
     ) avg_r ON avg_r.service_id = s.id
     LEFT JOIN (
       SELECT service_id, COUNT(*)::int AS total_bookings
       FROM bookings
       WHERE status = 'completed'
       GROUP BY service_id
     ) bk_count ON bk_count.service_id = s.id
     ${clause}
     ORDER BY s.name ASC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const allowed = ["category_id", "name", "description", "image_url", "status", "icon", "price", "estimated_time"];
  const sets = [];
  const params = [];

  for (const key of allowed) {
    if (values[key] !== undefined) {
      params.push(values[key]);
      sets.push(`${key === 'category_id' ? 'category_id' : key} = $${params.length}`);
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
