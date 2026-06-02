const db = require("../config/db");
const { paged } = require("../utils/pagination");

const publicFields = `
  id, subject, description, status, admin_notes, created_at, updated_at
`;

async function findById(id) {
  const result = await db.query(`SELECT ${publicFields} FROM complaints WHERE id = $1`, [id]);
  return result.rows[0];
}

async function list({ status, search, page, limit, offset }) {
  const params = [];
  const where = [];

  if (status) {
    params.push(status);
    where.push(`status = $${params.length}`);
  }

  if (search) {
    params.push(`%${search}%`);
    where.push(`(subject ILIKE $${params.length} OR description ILIKE $${params.length})`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(`SELECT COUNT(*) FROM complaints ${clause}`, params);
  params.push(limit, offset);
  const result = await db.query(
    `SELECT ${publicFields} FROM complaints ${clause} ORDER BY created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(result.rows, count.rows[0].count, page, limit);
}

async function updateStatus(id, status) {
  const result = await db.query(
    `UPDATE complaints SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING ${publicFields}`,
    [status, id]
  );
  return result.rows[0];
}

async function addNote(id, note) {
  // In a real app, this might append to an array or text column.
  // We will assume `admin_notes` is a text column, so we'll concatenate the new note.
  const result = await db.query(
    `UPDATE complaints SET admin_notes = CONCAT(admin_notes, '\n', $1::text), updated_at = NOW() WHERE id = $2 RETURNING ${publicFields}`,
    [`[${new Date().toISOString()}] ${note}`, id]
  );
  return result.rows[0];
}

module.exports = { findById, list, updateStatus, addNote };
