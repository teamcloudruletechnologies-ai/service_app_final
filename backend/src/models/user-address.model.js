const db = require("../config/db");

async function findByUserId(userId) {
  const result = await db.query(
    `SELECT id, user_id, title, address_line, city, state, pincode, landmark,
            lat::float AS lat, lng::float AS lng, is_default, created_at, updated_at
     FROM user_addresses
     WHERE user_id = $1
     ORDER BY is_default DESC, created_at DESC`,
    [userId]
  );
  return result.rows;
}

async function findById(id, userId) {
  const result = await db.query(
    `SELECT id, user_id, title, address_line, city, state, pincode, landmark,
            lat::float AS lat, lng::float AS lng, is_default, created_at, updated_at
     FROM user_addresses
     WHERE id = $1 AND user_id = $2`,
    [id, userId]
  );
  return result.rows[0] || null;
}

async function create(userId, { title, address_line, city, state, pincode, landmark, lat, lng, is_default }) {
  if (is_default) {
    await db.query(`UPDATE user_addresses SET is_default = FALSE WHERE user_id = $1`, [userId]);
  }

  // If this is user's first address, automatically make it default
  const existing = await db.query(`SELECT COUNT(*)::int AS count FROM user_addresses WHERE user_id = $1`, [userId]);
  const shouldBeDefault = is_default || existing.rows[0].count === 0;

  const result = await db.query(
    `INSERT INTO user_addresses (user_id, title, address_line, city, state, pincode, landmark, lat, lng, is_default)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING id`,
    [
      userId,
      title || 'Home',
      address_line,
      city || null,
      state || null,
      pincode || null,
      landmark || null,
      lat || null,
      lng || null,
      shouldBeDefault,
    ]
  );

  return findById(result.rows[0].id, userId);
}

async function update(id, userId, { title, address_line, city, state, pincode, landmark, lat, lng, is_default }) {
  if (is_default) {
    await db.query(`UPDATE user_addresses SET is_default = FALSE WHERE user_id = $1`, [userId]);
  }

  const map = {
    title: 'title',
    address_line: 'address_line',
    city: 'city',
    state: 'state',
    pincode: 'pincode',
    landmark: 'landmark',
    lat: 'lat',
    lng: 'lng',
    is_default: 'is_default',
  };

  const sets = [];
  const params = [];
  const fields = { title, address_line, city, state, pincode, landmark, lat, lng, is_default };

  for (const [key, column] of Object.entries(map)) {
    if (fields[key] !== undefined) {
      params.push(fields[key]);
      sets.push(`${column} = $${params.length}`);
    }
  }

  if (sets.length > 0) {
    params.push(id, userId);
    await db.query(
      `UPDATE user_addresses
       SET ${sets.join(", ")}, updated_at = NOW()
       WHERE id = $${params.length - 1} AND user_id = $${params.length}`,
      params
    );
  }

  return findById(id, userId);
}

async function remove(id, userId) {
  const result = await db.query(
    `DELETE FROM user_addresses WHERE id = $1 AND user_id = $2 RETURNING *`,
    [id, userId]
  );
  return result.rows[0] || null;
}

async function setDefault(id, userId) {
  await db.query(`UPDATE user_addresses SET is_default = FALSE WHERE user_id = $1`, [userId]);
  const result = await db.query(
    `UPDATE user_addresses SET is_default = TRUE, updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING id`,
    [id, userId]
  );
  if (!result.rows[0]) return null;
  return findById(id, userId);
}

module.exports = {
  findByUserId,
  findById,
  create,
  update,
  remove,
  setDefault,
};
