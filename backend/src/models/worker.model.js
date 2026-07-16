const db = require("../config/db");
const { paged } = require("../utils/pagination");

const publicFields = `
  id, name, email, phone, service_type, experience_years, city, state, address, pincode,
  status, kyc_status, photo_url, rating, created_at, updated_at
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
  // ── Stage 1: GPS-based radius query ────────────────────────────────────────
  const params1 = [lat, lng, radiusKm];
  let where1 = "status = 'active' AND kyc_status = 'approved' AND current_lat IS NOT NULL AND current_lng IS NOT NULL";

  if (serviceType) {
    params1.push(serviceType);
    where1 += ` AND service_type = $${params1.length}`;
  }

  const gpsQuery = `
    SELECT * FROM (
      SELECT ${publicFields}, current_lat, current_lng, last_location_update,
      (6371 * acos(LEAST(1.0, cos(radians($1)) * cos(radians(current_lat)) * cos(radians(current_lng) - radians($2)) + sin(radians($1)) * sin(radians(current_lat))))) AS distance
      FROM workers
      WHERE ${where1}
    ) AS sub
    WHERE distance <= $3
    ORDER BY distance ASC
  `;

  const gpsResult = await db.query(gpsQuery, params1);

  // ── Stage 2: City-name fallback ─────────────────────────────────────────────
  // Detect nearest known city from query coordinates (within 100 km)
  const knownCities = [
    { name: 'chennai',   lat: 13.0827, lng: 80.2707 },
    { name: 'bangalore', lat: 12.9716, lng: 77.5946 },
    { name: 'mumbai',    lat: 19.0760, lng: 72.8777 },
    { name: 'delhi',     lat: 28.6139, lng: 77.2090 },
    { name: 'hyderabad', lat: 17.3850, lng: 78.4867 },
    { name: 'kolkata',   lat: 22.5726, lng: 88.3639 },
    { name: 'pune',      lat: 18.5204, lng: 73.8567 },
  ];

  const toRad = (d) => (d * Math.PI) / 180;
  let nearestCity = null;
  let minDist = Infinity;
  for (const c of knownCities) {
    const dLat = toRad(lat - c.lat);
    const dLng = toRad(lng - c.lng);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat)) * Math.cos(toRad(c.lat)) * Math.sin(dLng / 2) ** 2;
    const d = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    if (d < minDist) { minDist = d; nearestCity = c.name; }
  }

  let allWorkers = [...gpsResult.rows];

  if (nearestCity && minDist <= 100) {
    // Fetch active+approved workers whose registered city matches the detected city
    const params2 = [nearestCity.toLowerCase()];
    let where2 = "status = 'active' AND kyc_status = 'approved' AND LOWER(city) = $1";

    if (serviceType) {
      params2.push(serviceType);
      where2 += ` AND service_type = $${params2.length}`;
    }

    const cityQuery = `
      SELECT ${publicFields}, current_lat, current_lng, last_location_update,
             NULL::numeric AS distance
      FROM workers
      WHERE ${where2}
    `;

    const cityResult = await db.query(cityQuery, params2);

    // Merge — de-duplicate by id (GPS-matched workers take priority)
    const existingIds = new Set(allWorkers.map((r) => r.id));
    for (const w of cityResult.rows) {
      if (!existingIds.has(w.id)) {
        allWorkers.push(w);
      }
    }
  }

  return allWorkers;
}


module.exports = { create, findByEmailOrPhone, findById, list, update, remove, findNearbyWorkers };
