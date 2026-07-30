const db = require("../config/db");

const publicFields = "id, name, email, role, status, created_at, updated_at";

async function create(admin) {
  const result = await db.query(
    `INSERT INTO admins (name, email, password_hash, role, status)
     VALUES ($1, $2, $3, $4, COALESCE($5, 'active'))
     RETURNING ${publicFields}`,
    [admin.name, admin.email, admin.passwordHash, admin.role || "admin", admin.status]
  );
  return result.rows[0];
}

async function findByEmail(email) {
  const result = await db.query("SELECT * FROM admins WHERE email = $1", [email]);
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(`SELECT ${publicFields} FROM admins WHERE id = $1`, [id]);
  return result.rows[0];
}

module.exports = { create, findByEmail, findById };
