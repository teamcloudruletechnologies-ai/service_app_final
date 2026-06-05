const db = require("../config/db");
const { error } = require("../utils/response");

function checkPermission(requiredPermission) {
  return async (req, res, next) => {
    // If not authenticated or not an admin role in token, let it pass to standard middlewares
    if (!req.auth || req.auth.role !== "admin") {
      return next();
    }

    try {
      const result = await db.query("SELECT role, status FROM admins WHERE id = $1", [req.auth.id]);
      const admin = result.rows[0];

      if (!admin) {
        return error(res, "Admin account not found", 404);
      }

      if (admin.status !== "active") {
        return error(res, "Account is not active", 403);
      }

      // SUPER_ADMIN and legacy/default admin role bypass permission checks
      if (admin.role === "super_admin" || admin.role === "admin") {
        return next();
      }

      // Check if sub-admin has the permission
      if (admin.role === "sub_admin") {
        const permResult = await db.query(
          "SELECT 1 FROM admin_permissions WHERE admin_id = $1 AND permission = $2",
          [req.auth.id, requiredPermission]
        );
        if (permResult.rowCount > 0) {
          return next();
        }
      }

      return error(res, "You do not have permission to access this resource", 403);
    } catch (err) {
      return next(err);
    }
  };
}

module.exports = checkPermission;
