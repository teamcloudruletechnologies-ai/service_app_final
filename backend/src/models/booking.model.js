const db = require("../config/db");
const { paged } = require("../utils/pagination");

const listFields = `
  b.id,
  b.user_id,
  u.name AS user_name,
  u.phone AS user_phone,
  b.worker_id,
  w.name AS worker_name,
  w.phone AS worker_phone,
  w.service_type,
  w.current_lat::float AS worker_lat,
  w.current_lng::float AS worker_lng,
  b.service_id,
  s.name AS service_name,
  s.image_url AS service_image,
  b.address,
  b.notes,
  b.scheduled_at,
  b.status,
  b.amount::float AS amount,
  b.otp,
  b.start_photo_url,
  b.completion_photo_url,
  b.start_notes,
  b.completion_notes,
  b.job_started_at,
  b.job_completed_at,
  b.created_at,
  b.updated_at
`;

async function list({ status, userId, workerId, page, limit, offset }) {
  const params = [];
  const where = [];

  if (status) {
    params.push(status);
    where.push(`b.status = $${params.length}`);
  }

  if (userId) {
    params.push(userId);
    where.push(`b.user_id = $${params.length}`);
  }

  if (workerId) {
    params.push(workerId);
    where.push(`(b.worker_id = $${params.length} OR (b.worker_id IS NULL AND b.status = 'pending'))`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM bookings b ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${listFields}
     FROM bookings b
     LEFT JOIN users u ON u.id = b.user_id
     LEFT JOIN workers w ON w.id = b.worker_id
     LEFT JOIN services s ON s.id = b.service_id
     ${clause}
     ORDER BY b.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function findById(id) {
  const result = await db.query(
    `SELECT ${listFields}
     FROM bookings b
     LEFT JOIN users u ON u.id = b.user_id
     LEFT JOIN workers w ON w.id = b.worker_id
     LEFT JOIN services s ON s.id = b.service_id
     WHERE b.id = $1`,
    [id]
  );
  return result.rows[0];
}

async function create({ userId, serviceId, workerId, amount, address, notes, scheduledAt }) {
  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  const result = await db.query(
    `INSERT INTO bookings (user_id, service_id, worker_id, amount, address, notes, scheduled_at, status, otp)
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending', $8)
     RETURNING id`,
    [userId, serviceId, workerId || null, amount, address || null, notes || null, scheduledAt || null, otp]
  );
  return findById(result.rows[0].id);
}

async function updateStatus(id, status, workerId = null) {
  let otpQuery = "";
  let workerQuery = "";
  let params = [status, id];
  
  if (status === 'in_progress') {
    const nextOtp = Math.floor(1000 + Math.random() * 9000).toString();
    otpQuery = ", otp = $3";
    params.push(nextOtp);
  }

  if (workerId) {
    params.push(workerId);
    workerQuery = `, worker_id = $${params.length}`;
  }

  const result = await db.query(
    `UPDATE bookings
     SET status = $1, updated_at = NOW()${otpQuery}${workerQuery}
     WHERE id = $2
     RETURNING id`,
    params
  );

  if (!result.rows[0]) return null;
  return findById(result.rows[0].id);
}

async function startJobWithPhoto(id, workerId, { photoUrl, notes }) {
  const nextOtp = Math.floor(1000 + Math.random() * 9000).toString();
  const result = await db.query(
    `UPDATE bookings
     SET status = 'in_progress',
         start_photo_url = COALESCE($1, start_photo_url),
         start_notes = COALESCE($2, start_notes),
         job_started_at = NOW(),
         otp = $3,
         updated_at = NOW()
     WHERE id = $4 AND (worker_id = $5 OR worker_id IS NULL)
     RETURNING id`,
    [photoUrl || null, notes || null, nextOtp, id, workerId]
  );
  if (!result.rows[0]) return null;
  return findById(result.rows[0].id);
}

async function completeJobWithPhoto(id, workerId, { photoUrl, notes }) {
  const result = await db.query(
    `UPDATE bookings
     SET status = 'completed',
         completion_photo_url = COALESCE($1, completion_photo_url),
         completion_notes = COALESCE($2, completion_notes),
         job_completed_at = NOW(),
         updated_at = NOW()
     WHERE id = $3 AND (worker_id = $4 OR worker_id IS NULL)
     RETURNING id`,
    [photoUrl || null, notes || null, id, workerId]
  );
  if (!result.rows[0]) return null;
  return findById(result.rows[0].id);
}

async function analytics() {
  const [summary, byStatus, revenueByStatus, recent] = await Promise.all([
    db.query(
      `SELECT
        COUNT(*)::int AS total_bookings,
        COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_bookings,
        COUNT(*) FILTER (WHERE status = 'confirmed')::int AS confirmed_bookings,
        COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_bookings,
        COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_bookings,
        COALESCE(SUM(amount), 0)::float AS total_amount,
        COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0)::float AS completed_amount
       FROM bookings`
    ),
    db.query("SELECT status, COUNT(*)::int AS total FROM bookings GROUP BY status ORDER BY total DESC"),
    db.query(
      `SELECT status, COALESCE(SUM(amount), 0)::float AS amount
       FROM bookings
       GROUP BY status
       ORDER BY amount DESC`
    ),
    db.query(
      `SELECT DATE(created_at) AS date, COUNT(*)::int AS total, COALESCE(SUM(amount), 0)::float AS amount
       FROM bookings
       WHERE created_at >= NOW() - INTERVAL '30 days'
       GROUP BY DATE(created_at)
       ORDER BY date DESC`
    ),
  ]);

  return {
    summary: summary.rows[0],
    byStatus: byStatus.rows,
    revenueByStatus: revenueByStatus.rows,
    recent: recent.rows,
  };
}

module.exports = { list, findById, create, updateStatus, startJobWithPhoto, completeJobWithPhoto, analytics };
