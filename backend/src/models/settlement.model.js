const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function listUnsettled({ days = 3, startDate, endDate, minAmount = 500 }) {
  let dateClause = "";
  const params = [];

  if (startDate && endDate) {
    params.push(startDate, endDate);
    dateClause = `AND i.created_at >= $1::timestamptz AND i.created_at <= $2::timestamptz`;
  } else {
    params.push(days);
    dateClause = `AND i.created_at >= NOW() - ($1 || ' days')::interval`;
  }

  const query = `
    SELECT
      w.id AS worker_id,
      w.name AS worker_name,
      w.phone AS worker_phone,
      w.service_type,
      w.upi_id,
      w.bank_account_number,
      w.ifsc_code,
      w.account_holder_name,
      COUNT(i.id)::int AS total_jobs,
      COALESCE(SUM(i.amount), 0)::float AS gross_amount,
      COALESCE(SUM(i.platform_fee), 0)::float AS platform_fee,
      COALESCE(SUM(i.worker_payout), 0)::float AS net_payout,
      (COALESCE(SUM(i.worker_payout), 0) >= ${Number(minAmount) || 500}) AS is_eligible
    FROM workers w
    JOIN invoices i ON i.worker_id = w.id
    WHERE i.status NOT IN ('paid', 'cancelled')
      ${dateClause}
      AND NOT EXISTS (
        SELECT 1 FROM worker_settlements ws
        WHERE ws.worker_id = w.id
          AND ws.status = 'paid'
          AND ws.created_at >= i.created_at
      )
    GROUP BY w.id, w.name, w.phone, w.service_type, w.upi_id, w.bank_account_number, w.ifsc_code, w.account_holder_name
    ORDER BY net_payout DESC
  `;

  const result = await db.query(query, params);
  return result.rows;
}

async function createSettlement({ workerId, periodStart, periodEnd, totalJobs, grossAmount, platformFee, netPayout, paymentMethod = 'razorpay', transactionRef, notes }) {
  const result = await db.query(
    `INSERT INTO worker_settlements (
      worker_id, settlement_period_start, settlement_period_end, total_jobs,
      gross_amount, platform_fee, net_payout, status, payment_method, transaction_ref, notes, paid_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'paid', $8, $9, $10, NOW())
     RETURNING *`,
    [workerId, periodStart || null, periodEnd || null, totalJobs || 0, grossAmount || 0, platformFee || 0, netPayout || 0, paymentMethod, transactionRef || `REF-${Date.now()}`, notes || '']
  );

  // Mark all unsettled invoices for this worker as paid
  await db.query(
    `UPDATE invoices
     SET status = 'paid', paid_at = NOW(), updated_at = NOW()
     WHERE worker_id = $1 AND status IN ('approved', 'pending_approval', 'pending')`,
    [workerId]
  );

  // Mark corresponding bookings as paid
  await db.query(
    `UPDATE bookings
     SET status = 'paid', payment_status = 'paid', updated_at = NOW()
     WHERE worker_id = $1 AND status IN ('payment_pending', 'completed')`,
    [workerId]
  );

  return result.rows[0];
}

async function listHistory({ page = 1, limit = 10, offset = 0, workerId, status }) {
  const params = [];
  const where = [];

  if (workerId) {
    params.push(workerId);
    where.push(`ws.worker_id = $${params.length}`);
  }

  if (status) {
    params.push(status);
    where.push(`ws.status = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const countRes = await db.query(`SELECT COUNT(*) FROM worker_settlements ws ${clause}`, params);

  params.push(limit, offset);
  const result = await db.query(
    `SELECT
      ws.*,
      w.name AS worker_name,
      w.phone AS worker_phone,
      w.service_type
     FROM worker_settlements ws
     LEFT JOIN workers w ON w.id = ws.worker_id
     ${clause}
     ORDER BY ws.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, countRes.rows[0].count, page, limit);
}

async function getFinanceSummary() {
  const result = await db.query(`
    SELECT
      COALESCE((SELECT SUM(amount) FROM invoices WHERE status != 'cancelled'), 0)::float AS total_gross_revenue,
      COALESCE((SELECT SUM(platform_fee) FROM invoices WHERE status != 'cancelled'), 0)::float AS total_platform_commission,
      COALESCE((SELECT SUM(net_payout) FROM worker_settlements WHERE status = 'paid'), 0)::float AS total_settled_payout,
      COALESCE((
        SELECT SUM(i.worker_payout)
        FROM invoices i
        WHERE i.status != 'cancelled'
          AND NOT EXISTS (
            SELECT 1 FROM worker_settlements ws
            WHERE ws.worker_id = i.worker_id AND ws.status = 'paid' AND ws.created_at >= i.created_at
          )
      ), 0)::float AS total_pending_payout
  `);

  return result.rows[0];
}

async function getCategoryServiceRevenueBreakdown() {
  const [breakdownRes, trendRes] = await Promise.all([
    db.query(`
      SELECT
        COALESCE(sc.id, 0) AS category_id,
        COALESCE(sc.name, 'General Services') AS category_name,
        COALESCE(sc.icon_url, '') AS category_icon,
        COALESCE(s.id, 0) AS service_id,
        COALESCE(s.name, 'Direct Service') AS service_name,
        w.id AS worker_id,
        w.name AS worker_name,
        w.phone AS worker_phone,
        COUNT(i.id)::int AS jobs_completed,
        COALESCE(SUM(i.amount), 0)::float AS gross_revenue,
        COALESCE(SUM(i.platform_fee), 0)::float AS platform_fee,
        COALESCE(SUM(i.worker_payout), 0)::float AS net_payout
      FROM invoices i
      LEFT JOIN bookings b ON b.id = i.booking_id
      LEFT JOIN services s ON s.id = b.service_id
      LEFT JOIN service_categories sc ON sc.id = s.category_id
      LEFT JOIN workers w ON w.id = i.worker_id
      WHERE i.status != 'cancelled'
      GROUP BY sc.id, sc.name, sc.icon_url, s.id, s.name, w.id, w.name, w.phone
      ORDER BY sc.name ASC, s.name ASC, gross_revenue DESC
    `),
    db.query(`
      SELECT
        TO_CHAR(created_at, 'Mon YYYY') AS month_label,
        DATE_TRUNC('month', created_at)::date AS month_date,
        COALESCE(SUM(amount), 0)::float AS gross_amount,
        COALESCE(SUM(platform_fee), 0)::float AS platform_fee
      FROM invoices
      WHERE status != 'cancelled'
      GROUP BY DATE_TRUNC('month', created_at), TO_CHAR(created_at, 'Mon YYYY')
      ORDER BY month_date ASC
      LIMIT 12
    `)
  ]);

  return {
    rows: breakdownRes.rows,
    monthlyTrend: trendRes.rows
  };
}

module.exports = {
  listUnsettled,
  createSettlement,
  listHistory,
  getFinanceSummary,
  getCategoryServiceRevenueBreakdown
};
