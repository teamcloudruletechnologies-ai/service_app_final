const db = require("../config/db");
const { success } = require("../utils/response");

async function overview(req, res, next) {
  try {
    const [users, workers, kyc, bookings, revenue] = await Promise.all([
      db.query("SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'active') AS active FROM users"),
      db.query("SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'active') AS active FROM workers"),
      db.query("SELECT status, COUNT(*) AS total FROM worker_kyc GROUP BY status"),
      db.query("SELECT status, COUNT(*) AS total FROM bookings GROUP BY status"),
      db.query("SELECT COALESCE(SUM(amount), 0) AS total FROM bookings WHERE status = 'completed'"),
    ]);

    return success(res, "Dashboard overview fetched", {
      users: users.rows[0],
      workers: workers.rows[0],
      kyc: kyc.rows,
      bookings: bookings.rows,
      revenue: revenue.rows[0].total,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { overview };
