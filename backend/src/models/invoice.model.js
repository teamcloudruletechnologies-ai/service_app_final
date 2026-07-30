const db = require("../config/db");
const { paged } = require("../utils/pagination");

const listFields = `
  i.id,
  i.booking_id,
  i.user_id,
  u.name AS user_name,
  i.worker_id,
  w.name AS worker_name,
  i.invoice_number,
  i.status,
  i.amount::float AS amount,
  i.platform_fee::float AS platform_fee,
  i.worker_payout::float AS worker_payout,
  i.paid_at,
  i.created_at,
  i.updated_at
`;

async function list({ status, userId, workerId, page, limit, offset }) {
  const params = [];
  const where = [];

  if (status) {
    params.push(status);
    where.push(`i.status = $${params.length}`);
  }

  if (userId) {
    params.push(userId);
    where.push(`i.user_id = $${params.length}`);
  }

  if (workerId) {
    params.push(workerId);
    where.push(`i.worker_id = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM invoices i ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${listFields}
     FROM invoices i
     LEFT JOIN users u ON u.id = i.user_id
     LEFT JOIN workers w ON w.id = i.worker_id
     ${clause}
     ORDER BY i.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function findById(id) {
  const result = await db.query(
    `SELECT ${listFields}
     FROM invoices i
     LEFT JOIN users u ON u.id = i.user_id
     LEFT JOIN workers w ON w.id = i.worker_id
     WHERE i.id = $1`,
    [id]
  );
  return result.rows[0];
}

async function reports() {
  const [summary, byStatus, monthly] = await Promise.all([
    db.query(
      `SELECT
        COUNT(*)::int AS total_invoices,
        COUNT(*) FILTER (WHERE status = 'paid')::int AS paid_invoices,
        COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_invoices,
        COUNT(*) FILTER (WHERE status = 'failed')::int AS failed_invoices,
        COALESCE(SUM(amount), 0)::float AS total_amount,
        COALESCE(SUM(amount) FILTER (WHERE status = 'paid'), 0)::float AS paid_amount,
        COALESCE(SUM(platform_fee) FILTER (WHERE status = 'paid'), 0)::float AS platform_fee,
        COALESCE(SUM(worker_payout) FILTER (WHERE status = 'paid'), 0)::float AS worker_payout
       FROM invoices`
    ),
    db.query("SELECT status, COUNT(*)::int AS total, COALESCE(SUM(amount), 0)::float AS amount FROM invoices GROUP BY status"),
    db.query(
      `SELECT DATE_TRUNC('month', created_at)::date AS month,
              COUNT(*)::int AS total,
              COALESCE(SUM(amount), 0)::float AS amount
       FROM invoices
       GROUP BY DATE_TRUNC('month', created_at)
       ORDER BY month DESC`
    ),
  ]);

  return {
    summary: summary.rows[0],
    byStatus: byStatus.rows,
    monthly: monthly.rows,
  };
}

async function payouts() {
  const result = await db.query(
    `SELECT
      i.worker_id,
      w.name AS worker_name,
      w.phone AS worker_phone,
      COUNT(i.id)::int AS invoice_count,
      COALESCE(SUM(i.worker_payout), 0)::float AS payout_amount,
      COALESCE(SUM(i.platform_fee), 0)::float AS platform_fee
     FROM invoices i
     LEFT JOIN workers w ON w.id = i.worker_id
     WHERE i.status = 'paid'
     GROUP BY i.worker_id, w.name, w.phone
     ORDER BY payout_amount DESC`
  );

  return result.rows;
}

async function create({ bookingId, userId, workerId, amount, status = 'paid' }) {
  const invoiceNumber = `INV-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
  const platformFee = amount * 0.1; // 10% platform fee
  const workerPayout = amount - platformFee;

  const result = await db.query(
    `INSERT INTO invoices (booking_id, user_id, worker_id, invoice_number, status, amount, platform_fee, worker_payout, paid_at, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW(), NOW())
     RETURNING *`,
    [bookingId, userId, workerId, invoiceNumber, status, amount, platformFee, workerPayout]
  );
  return result.rows[0];
}

module.exports = { list, findById, reports, payouts, create };
