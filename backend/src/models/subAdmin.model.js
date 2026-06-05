const db = require("../config/db");

const publicFields = "id, name, email, role, status, created_at, updated_at";

async function createSubAdmin({ name, email, passwordHash, status, permissions = [] }) {
  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    // Insert into admins
    const adminRes = await client.query(
      `INSERT INTO admins (name, email, password_hash, role, status)
       VALUES ($1, $2, $3, 'sub_admin', COALESCE($4, 'active'))
       RETURNING ${publicFields}`,
      [name, email, passwordHash, status]
    );
    const subAdmin = adminRes.rows[0];

    // Insert permissions
    if (permissions && permissions.length > 0) {
      for (const permission of permissions) {
        await client.query(
          "INSERT INTO admin_permissions (admin_id, permission) VALUES ($1, $2)",
          [subAdmin.id, permission]
        );
      }
    }

    await client.query("COMMIT");
    return { ...subAdmin, permissions };
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function listSubAdmins() {
  const result = await db.query(
    `SELECT a.id, a.name, a.email, a.role, a.status, a.created_at, a.updated_at,
            COALESCE(json_agg(p.permission) FILTER (WHERE p.permission IS NOT NULL), '[]') as permissions
     FROM admins a
     LEFT JOIN admin_permissions p ON a.id = p.admin_id
     WHERE a.role = 'sub_admin'
     GROUP BY a.id
     ORDER BY a.created_at DESC`
  );
  return result.rows;
}

async function getSubAdminById(id) {
  const result = await db.query(
    `SELECT a.id, a.name, a.email, a.role, a.status, a.created_at, a.updated_at,
            COALESCE(json_agg(p.permission) FILTER (WHERE p.permission IS NOT NULL), '[]') as permissions
     FROM admins a
     LEFT JOIN admin_permissions p ON a.id = p.admin_id
     WHERE a.id = $1 AND a.role = 'sub_admin'
     GROUP BY a.id`,
    [id]
  );
  return result.rows[0];
}

async function updateSubAdmin(id, { name, email, passwordHash, status, permissions }) {
  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    // Build dynamic update query for admin
    let queryText = "UPDATE admins SET name = $1, email = $2, status = $3, updated_at = NOW()";
    const queryParams = [name, email, status];

    if (passwordHash) {
      queryParams.push(passwordHash);
      queryText += `, password_hash = $${queryParams.length}`;
    }

    queryParams.push(id);
    queryText += ` WHERE id = $${queryParams.length} AND role = 'sub_admin' RETURNING ${publicFields}`;

    const adminRes = await client.query(queryText, queryParams);
    const subAdmin = adminRes.rows[0];

    if (!subAdmin) {
      await client.query("ROLLBACK");
      return null;
    }

    // Update permissions if provided
    if (permissions !== undefined) {
      await client.query("DELETE FROM admin_permissions WHERE admin_id = $1", [id]);
      if (permissions && permissions.length > 0) {
        for (const permission of permissions) {
          await client.query(
            "INSERT INTO admin_permissions (admin_id, permission) VALUES ($1, $2)",
            [id, permission]
          );
        }
      }
    }

    await client.query("COMMIT");

    // Fetch updated sub-admin with permissions
    return await getSubAdminById(id);
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function deleteSubAdmin(id) {
  const result = await db.query(
    "DELETE FROM admins WHERE id = $1 AND role = 'sub_admin' RETURNING id",
    [id]
  );
  return result.rowCount > 0;
}

module.exports = {
  createSubAdmin,
  listSubAdmins,
  getSubAdminById,
  updateSubAdmin,
  deleteSubAdmin,
};
