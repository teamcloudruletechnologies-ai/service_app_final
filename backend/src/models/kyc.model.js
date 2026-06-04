const db = require("../config/db");
const { paged } = require("../utils/pagination");

async function submit(payload) {
  // Check if a record already exists
  const existing = await db.query(
    "SELECT * FROM worker_kyc WHERE worker_id = $1",
    [payload.workerId]
  );
  
  let result;
  const kyc = existing.rows[0];
  
  if (kyc) {
    // If it is in 'pending_correction' or 'rejected'
    if (kyc.status === 'pending_correction' || kyc.status === 'rejected') {
      const updates = [];
      const params = [];
      
      // Helper to add update fields conditionally
      const addUpdate = (colPrefix, valNum, valUrl) => {
        const statusField = `${colPrefix}_status`;
        const numField = `${colPrefix}_number`;
        const urlField = `${colPrefix}_url`;
        
        // If the record was rejected or the entire KYC was rejected, we overwrite it.
        if (kyc.status === 'rejected' || kyc[statusField] === 'rejected') {
          params.push(valNum);
          updates.push(`${numField} = $${params.length}`);
          
          params.push(valUrl);
          updates.push(`${urlField} = $${params.length}`);
          
          params.push('pending');
          updates.push(`${statusField} = $${params.length}`);
        }
      };

      addUpdate('aadhaar', payload.aadhaarNumber, payload.aadhaarUrl);
      addUpdate('pan', payload.panNumber, payload.panUrl);
      addUpdate('bank_passbook', payload.bankAccountNumber, payload.bankPassbookUrl);
      
      // Selfie doesn't have a number, handle separately
      if (kyc.status === 'rejected' || kyc.selfie_status === 'rejected') {
        params.push(payload.selfieUrl);
        updates.push(`selfie_url = $${params.length}`);
        
        params.push('pending');
        updates.push(`selfie_status = $${params.length}`);
      }
      
      // Reset global status to pending
      params.push('pending');
      updates.push(`status = $${params.length}`);
      
      // Clear rejection reason
      updates.push(`rejection_reason = NULL`);
      updates.push(`updated_at = NOW()`);
      
      // Where clause
      params.push(kyc.id);
      result = await db.query(
        `UPDATE worker_kyc SET ${updates.join(", ")} WHERE id = $${params.length} RETURNING *`,
        params
      );
    } else {
      // If it's already pending or approved, just return the existing row to prevent duplicates.
      result = { rows: [kyc] };
    }
  } else {
    // Perform initial insert
    result = await db.query(
      `INSERT INTO worker_kyc (
        worker_id, 
        aadhaar_number, aadhaar_url, aadhaar_status, 
        pan_number, pan_url, pan_status, 
        bank_account_number, bank_passbook_url, bank_passbook_status, 
        selfie_url, selfie_status, 
        status
      ) VALUES ($1, $2, $3, 'pending', $4, $5, 'pending', $6, $7, 'pending', $8, 'pending', 'pending')
      RETURNING *`,
      [
        payload.workerId,
        payload.aadhaarNumber,
        payload.aadhaarUrl,
        payload.panNumber,
        payload.panUrl,
        payload.bankAccountNumber,
        payload.bankPassbookUrl,
        payload.selfieUrl,
      ]
    );
  }

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

async function review(id, { aadhaarStatus, panStatus, bankPassbookStatus, selfieStatus, rejectionReason, reviewedBy }) {
  // Fetch existing record first
  const existing = await db.query("SELECT * FROM worker_kyc WHERE id = $1", [id]);
  const kyc = existing.rows[0];
  if (!kyc) return null;

  // Merge statuses
  const newAadhaarStatus = aadhaarStatus || kyc.aadhaar_status;
  const newPanStatus = panStatus || kyc.pan_status;
  const newBankPassbookStatus = bankPassbookStatus || kyc.bank_passbook_status;
  const newSelfieStatus = selfieStatus || kyc.selfie_status;

  // Determine global status
  let globalStatus = 'pending';
  const allApproved = 
    newAadhaarStatus === 'approved' &&
    newPanStatus === 'approved' &&
    newBankPassbookStatus === 'approved' &&
    newSelfieStatus === 'approved';

  const anyRejected = 
    newAadhaarStatus === 'rejected' ||
    newPanStatus === 'rejected' ||
    newBankPassbookStatus === 'rejected' ||
    newSelfieStatus === 'rejected';

  const allRejected = 
    newAadhaarStatus === 'rejected' &&
    newPanStatus === 'rejected' &&
    newBankPassbookStatus === 'rejected' &&
    newSelfieStatus === 'rejected';

  if (allApproved) {
    globalStatus = 'approved';
  } else if (allRejected) {
    globalStatus = 'rejected';
  } else if (anyRejected) {
    globalStatus = 'pending_correction';
  }

  // Update worker_kyc
  const result = await db.query(
    `UPDATE worker_kyc
     SET aadhaar_status = $1,
         pan_status = $2,
         bank_passbook_status = $3,
         selfie_status = $4,
         status = $5,
         rejection_reason = $6,
         reviewed_by = $7,
         reviewed_at = NOW(),
         updated_at = NOW()
     WHERE id = $8
     RETURNING *`,
    [
      newAadhaarStatus,
      newPanStatus,
      newBankPassbookStatus,
      newSelfieStatus,
      globalStatus,
      rejectionReason || null,
      reviewedBy,
      id,
    ]
  );

  const updatedKyc = result.rows[0];
  if (updatedKyc) {
    if (globalStatus === 'approved') {
      // Sync worker operational status to active AND kyc_status to approved
      await db.query(
        "UPDATE workers SET status = 'active', kyc_status = 'approved', updated_at = NOW() WHERE id = $1",
        [updatedKyc.worker_id]
      );
    } else {
      // Just sync kyc_status
      await db.query(
        "UPDATE workers SET kyc_status = $1, updated_at = NOW() WHERE id = $2",
        [globalStatus, updatedKyc.worker_id]
      );
    }
  }

  return updatedKyc;
}

async function findById(id) {
  const result = await db.query(
    `SELECT k.*, w.name AS worker_name, w.phone AS worker_phone, w.service_type
     FROM worker_kyc k
     JOIN workers w ON w.id = k.worker_id
     WHERE k.id = $1`,
    [id]
  );
  return result.rows[0];
}

module.exports = { submit, list, review, findById };
