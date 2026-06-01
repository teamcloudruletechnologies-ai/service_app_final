const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function submit(payload) {
  const result = await db.query(
    `INSERT INTO worker_kyc (worker_id, document_type, document_number, document_url, selfie_url, status)
     VALUES ($1, $2, $3, $4, $5, 'pending')
     RETURNING *`,
    [
      payload.workerId,
      payload.documentType,
      payload.documentNumber,
      payload.documentUrl || null,
      payload.selfieUrl || null,
    ]
  );

  await db.query("UPDATE workers SET kyc_status = 'pending', updated_at = NOW() WHERE id = $1", [payload.workerId]);
  return result.rows[0];
}

async function list({ status, workerId, page, limit, offset }) {
  const params = [];
  const where = [];

  if (status) {
    params.push(status);
    where.push(`k.status = $${params.length}`);
  }

  if (workerId) {
    params.push(workerId);
    where.push(`k.worker_id = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM worker_kyc k ${clause}`, params);
  params.push(limit, offset);
  const result = await db.query(
    `SELECT k.*, w.name AS worker_name, w.phone AS worker_phone, w.service_type
     FROM worker_kyc k
     JOIN workers w ON w.id = k.worker_id
     ${clause}
     ORDER BY k.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function review(id, { status, rejectionReason, reviewedBy }) {
  const result = await db.query(
    `UPDATE worker_kyc
     SET status = $1, rejection_reason = $2, reviewed_by = $3, reviewed_at = NOW(), updated_at = NOW()
     WHERE id = $4
     RETURNING *`,
    [status, rejectionReason || null, reviewedBy, id]
  );

  const kyc = result.rows[0];
  if (kyc) {
    await db.query("UPDATE workers SET kyc_status = $1, updated_at = NOW() WHERE id = $2", [status, kyc.worker_id]);
  }

  return kyc;
}

async function findById(id) {
  const result = await db.query("SELECT * FROM worker_kyc WHERE id = $1", [id]);
  return result.rows[0];
}

module.exports = { submit, list, review, findById };
