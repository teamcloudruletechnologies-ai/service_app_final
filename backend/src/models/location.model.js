const db = require("../config/db");

// --- ZONES ---
async function createZone(zone) {
  const result = await db.query(
    `INSERT INTO zones (name, city, status, radius_km, center_lat, center_lng)
     VALUES ($1, $2, COALESCE($3, 'active'), COALESCE($4, 10), $5, $6)
     RETURNING *`,
    [zone.name, zone.city, zone.status, zone.radius_km, zone.center_lat, zone.center_lng]
  );
  return result.rows[0];
}

async function getZones() {
  const result = await db.query(`SELECT * FROM zones ORDER BY created_at DESC`);
  return result.rows;
}

async function updateZone(id, zone) {
  const map = {
    name: "name",
    city: "city",
    status: "status",
    radius_km: "radius_km",
    center_lat: "center_lat",
    center_lng: "center_lng",
  };
  const sets = [];
  const params = [];

  for (const [key, column] of Object.entries(map)) {
    if (zone[key] !== undefined) {
      params.push(zone[key]);
      sets.push(`${column} = $${params.length}`);
    }
  }

  if (!sets.length) return getZoneById(id);

  params.push(id);
  const result = await db.query(
    `UPDATE zones SET ${sets.join(", ")}, updated_at = NOW() WHERE id = $${params.length} RETURNING *`,
    params
  );
  return result.rows[0];
}

async function getZoneById(id) {
  const result = await db.query(`SELECT * FROM zones WHERE id = $1`, [id]);
  return result.rows[0];
}

async function deleteZone(id) {
  const result = await db.query(`DELETE FROM zones WHERE id = $1 RETURNING *`, [id]);
  return result.rows[0];
}

async function updateZoneStatus(id, status) {
  const result = await db.query(
    `UPDATE zones SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
    [status, id]
  );
  return result.rows[0];
}

// --- PINCODES ---
async function createPincode(pincode) {
  const result = await db.query(
    `INSERT INTO pincodes (code, zone_id, lat, lng, status)
     VALUES ($1, $2, $3, $4, COALESCE($5, 'active'))
     RETURNING *`,
    [pincode.code, pincode.zone_id, pincode.lat, pincode.lng, pincode.status]
  );
  return result.rows[0];
}

async function getPincodes() {
  const result = await db.query(`
    SELECT p.*, z.name as zone_name 
    FROM pincodes p 
    LEFT JOIN zones z ON p.zone_id = z.id 
    ORDER BY p.created_at DESC
  `);
  return result.rows;
}

async function getPincodeByCode(code) {
  const result = await db.query(`SELECT * FROM pincodes WHERE code = $1`, [code]);
  return result.rows[0];
}

async function deletePincode(id) {
  const result = await db.query(`DELETE FROM pincodes WHERE id = $1 RETURNING *`, [id]);
  return result.rows[0];
}

// --- WORKER LOCATIONS ---
async function getWorkerLiveLocation(workerId) {
  const result = await db.query(
    `SELECT id, name, phone, current_lat, current_lng, last_location_update, status 
     FROM workers WHERE id = $1`,
    [workerId]
  );
  return result.rows[0];
}

// Helper to update worker location
async function updateWorkerLocation(workerId, lat, lng, pincode = null) {
  const result = await db.query(
    `UPDATE workers 
     SET current_lat = $1, current_lng = $2, pincode = COALESCE($3, pincode), last_location_update = NOW() 
     WHERE id = $4 RETURNING *`,
    [lat, lng, pincode, workerId]
  );
  return result.rows[0];
}

// --- PUBLIC: Active serviceable locations for apps ---
async function getActiveLocations() {
  const result = await db.query(`
    SELECT p.id, p.code, p.lat, p.lng,
           z.id as zone_id, z.name as zone_name, z.city
    FROM pincodes p
    LEFT JOIN zones z ON p.zone_id = z.id
    WHERE p.status = 'active'
      AND (z.status IS NULL OR z.status = 'active')
    ORDER BY z.city, p.code
  `);
  return result.rows;
}

module.exports = {
  createZone,
  getZones,
  updateZone,
  getZoneById,
  deleteZone,
  updateZoneStatus,
  createPincode,
  getPincodes,
  getPincodeByCode,
  deletePincode,
  getWorkerLiveLocation,
  updateWorkerLocation,
  getActiveLocations,
};

