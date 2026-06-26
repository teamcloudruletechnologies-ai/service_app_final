const db = require("../config/db");
const { paged } = require("../utils/pagination");

const publicFields = `
  id, name, email, phone, service_type, experience_years, city, state, address, pincode,
  status, kyc_status, created_at, updated_at
`;

async function create(worker) {
  const result = await db.query(
    `INSERT INTO workers (name, email, phone, password_hash, service_type, experience_years, city, state, address, pincode, status)
     VALUES ($1, $2, $3, $4, $5, COALESCE($6, 0), $7, $8, $9, $10, COALESCE($11, 'pending'))
     RETURNING ${publicFields}`,
    [
      worker.name || '',
      worker.email || null,
      worker.phone,
      worker.passwordHash || null,
      worker.serviceType || null,
      worker.experienceYears || 0,
      worker.city || null,
      worker.state || null,
      worker.address || null,
      worker.pincode || null,
      worker.status,
    ]
  );
  return result.rows[0];
}

async function findByEmailOrPhone(login) {
  const result = await db.query("SELECT * FROM workers WHERE email = $1 OR phone = $1", [login]);
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(`SELECT ${publicFields} FROM workers WHERE id = $1`, [id]);
  return result.rows[0];
}

async function list({ search, status, kycStatus, page, limit, offset }) {
  const params = [];
  const where = [];

  if (search) {
    params.push(`%${search}%`);
    where.push(`(name ILIKE $${params.length} OR email ILIKE $${params.length} OR phone ILIKE $${params.length} OR service_type ILIKE $${params.length})`);
  }

  if (status) {
    params.push(status);
    where.push(`status = $${params.length}`);
  }

  if (kycStatus) {
    params.push(kycStatus);
    where.push(`kyc_status = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM workers ${clause}`, params);
  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${publicFields} FROM workers ${clause} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function update(id, values) {
  const map = {
    name: "name",
    email: "email",
    phone: "phone",
    serviceType: "service_type",
    experienceYears: "experience_years",
    city: "city",
    state: "state",
    address: "address",
    pincode: "pincode",
    status: "status",
    kycStatus: "kyc_status",
  };
  const sets = [];
  const params = [];

  for (const [key, column] of Object.entries(map)) {
    if (values[key] !== undefined) {
      params.push(values[key]);
      sets.push(`${column} = $${params.length}`);
    }
  }

  if (!sets.length) return findById(id);

  params.push(id);
  const result = await db.query(
    `UPDATE workers SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING ${publicFields}`,
    params
  );
  return result.rows[0];
}

async function remove(id) {
  const result = await db.query(`DELETE FROM workers WHERE id = $1 RETURNING ${publicFields}`, [id]);
  return result.rows[0];
}

async function findNearbyWorkers(lat, lng, radiusKm = 10, serviceType = null) {
  const params = [lat, lng, radiusKm];
  let where = "status = 'active' AND kyc_status = 'approved' AND current_lat IS NOT NULL AND current_lng IS NOT NULL";
  
  if (serviceType) {
    params.push(serviceType);
    where += ` AND service_type = $${params.length}`;
  }

  // Haversine formula for distance in kilometers
  const query = `
    SELECT ${publicFields}, current_lat, current_lng, last_location_update,
    (6371 * acos(cos(radians($1)) * cos(radians(current_lat)) * cos(radians(current_lng) - radians($2)) + sin(radians($1)) * sin(radians(current_lat)))) AS distance
    FROM workers
    WHERE ${where}
    HAVING (6371 * acos(cos(radians($1)) * cos(radians(current_lat)) * cos(radians(current_lng) - radians($2)) + sin(radians($1)) * sin(radians(current_lat)))) <= $3
    ORDER BY distance ASC
  `;
  
  // Note: HAVING requires GROUP BY or aggregate in Postgres if not using subquery.
  // We'll use a subquery to make it standard and clean.
  const properQuery = `
    SELECT * FROM (
      SELECT ${publicFields}, current_lat, current_lng, last_location_update,
      (6371 * acos(cos(radians($1)) * cos(radians(current_lat)) * cos(radians(current_lng) - radians($2)) + sin(radians($1)) * sin(radians(current_lat)))) AS distance
      FROM workers
      WHERE ${where}
    ) AS nearby_workers
    WHERE distance <= $3
    ORDER BY distance ASC
  `;

  const result = await db.query(properQuery, params);
  return result.rows;
}

module.exports = { create, findByEmailOrPhone, findById, list, update, remove, findNearbyWorkers };
