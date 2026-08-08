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
  const result = await db.query(
    `SELECT a.*, 
            COALESCE(json_agg(p.permission) FILTER (WHERE p.permission IS NOT NULL), '[]') as permissions
     FROM admins a
     LEFT JOIN admin_permissions p ON a.id = p.admin_id
     WHERE a.email = $1
     GROUP BY a.id`,
    [email]
  );
  return result.rows[0];
}

async function findById(id) {
  const result = await db.query(
    `SELECT a.id, a.name, a.email, a.role, a.status, a.created_at, a.updated_at,
            COALESCE(json_agg(p.permission) FILTER (WHERE p.permission IS NOT NULL), '[]') as permissions
     FROM admins a
     LEFT JOIN admin_permissions p ON a.id = p.admin_id
     WHERE a.id = $1
     GROUP BY a.id`,
    [id]
  );
  return result.rows[0];
}

module.exports = { create, findByEmail, findById };
