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
        COALESCE(SUM(amount) FILTER (WHERE status != 'cancelled'), 0)::float AS paid_amount,
        COALESCE(SUM(platform_fee) FILTER (WHERE status != 'cancelled'), 0)::float AS platform_fee,
        COALESCE(SUM(worker_payout) FILTER (WHERE status != 'cancelled'), 0)::float AS worker_payout
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
     WHERE i.status != 'cancelled'
     GROUP BY i.worker_id, w.name, w.phone
     ORDER BY payout_amount DESC`
  );

  return result.rows;
}

async function passbookLedger() {
  const result = await db.query(
    `WITH ledger_events AS (
       -- 1. Credit Deposits (User Payments)
       SELECT
         ('CR-INV-' || i.id) AS event_id,
         i.created_at AS txn_date,
         'CREDIT' AS txn_type,
         ('Customer Payment for Booking #US' || i.booking_id) AS particulars,
         COALESCE(u.name, 'Customer') AS party_name,
         'Customer' AS party_role,
         i.invoice_number AS ref_no,
         i.amount::float AS credit_amount,
         0::float AS debit_amount,
         i.amount::float AS net_flow,
         'CREDITED' AS status
       FROM invoices i
       LEFT JOIN users u ON u.id = i.user_id
       WHERE i.status != 'cancelled'

       UNION ALL

       -- 2. Platform 10% Revenue Retained
       SELECT
         ('FEE-INV-' || i.id) AS event_id,
         i.created_at AS txn_date,
         'COMMISSION' AS txn_type,
         ('10% Platform Service Margin (Inv #' || i.invoice_number || ')') AS particulars,
         'Platform Treasury' AS party_name,
         'Company' AS party_role,
         ('MARGIN-' || i.invoice_number) AS ref_no,
         i.platform_fee::float AS credit_amount,
         0::float AS debit_amount,
         i.platform_fee::float AS net_flow,
         'RETAINED' AS status
       FROM invoices i
       WHERE i.status != 'cancelled'

       UNION ALL

       -- 3. Debit Disbursed Payouts to Workers
       SELECT
         ('DB-SETTLE-' || ws.id) AS event_id,
         COALESCE(ws.paid_at, ws.created_at) AS txn_date,
         'DEBIT' AS txn_type,
         ('Technician Settlement Payout (' || ws.total_jobs || ' jobs)') AS particulars,
         COALESCE(w.name, 'Technician Partner') AS party_name,
         'Technician' AS party_role,
         ('SETTLE-' || ws.id) AS ref_no,
         0::float AS credit_amount,
         ws.net_payout::float AS debit_amount,
         (-1 * ws.net_payout)::float AS net_flow,
         'DISBURSED' AS status
       FROM worker_settlements ws
       LEFT JOIN workers w ON w.id = ws.worker_id
       WHERE ws.status = 'paid'
     )
     SELECT
       event_id,
       txn_date,
       txn_type,
       particulars,
       party_name,
       party_role,
       ref_no,
       credit_amount,
       debit_amount,
       net_flow,
       status,
       SUM(net_flow) OVER (ORDER BY txn_date ASC, event_id ASC)::float AS running_balance
     FROM ledger_events
     ORDER BY txn_date DESC, event_id DESC`
  );
  return result.rows;
}

module.exports = { list, findById, reports, payouts, create, passbookLedger };
