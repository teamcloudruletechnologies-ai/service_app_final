const db = require("../config/db");
const { success } = require("../utils/response");

async function overview(req, res, next) {
  try {
    const [users, workers, kyc, bookings, revenue, recentBookings, activity, revenueChart, todayStats, activeWorkers, topServices] = await Promise.all([
      db.query("SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'active') AS active FROM users"),
      db.query("SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE status = 'active') AS active FROM workers"),
      db.query("SELECT status, COUNT(*) AS total FROM worker_kyc GROUP BY status"),
      db.query("SELECT status, COUNT(*) AS total FROM bookings GROUP BY status"),
      db.query("SELECT COALESCE(SUM(amount), 0) AS total FROM bookings WHERE status = 'completed'"),
      db.query(`
        SELECT b.id, b.amount::float AS amount, b.status, b.created_at, 
               u.name AS user_name, w.name AS worker_name, w.service_type
        FROM bookings b
        LEFT JOIN users u ON b.user_id = u.id
        LEFT JOIN workers w ON b.worker_id = w.id
        ORDER BY b.created_at DESC
        LIMIT 5
      `),
      db.query(`
        SELECT action, details, created_at
        FROM activity_logs
        ORDER BY created_at DESC
        LIMIT 5
      `),
      db.query(`
        SELECT 
          TO_CHAR(created_at, 'Dy') AS day,
          DATE_TRUNC('day', created_at) AS date,
          COALESCE(SUM(amount), 0)::float AS revenue
        FROM bookings
        WHERE status = 'completed' AND created_at >= NOW() - INTERVAL '7 days'
        GROUP BY DATE_TRUNC('day', created_at), TO_CHAR(created_at, 'Dy')
        ORDER BY date ASC
      `),
      db.query(`
        SELECT
          COUNT(*)::int AS today_bookings,
          COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0)::float AS today_revenue,
          COUNT(*) FILTER (WHERE status = 'completed')::int AS today_completed,
          COUNT(*) FILTER (WHERE status = 'pending')::int AS today_pending,
          COUNT(*) FILTER (WHERE status = 'in_progress')::int AS today_in_progress
        FROM bookings
        WHERE DATE(created_at) = CURRENT_DATE
      `),
      db.query("SELECT COUNT(*)::int AS count FROM workers WHERE status = 'active' AND current_lat IS NOT NULL"),
      db.query(`
        SELECT s.name, COUNT(b.id)::int AS bookings, COALESCE(SUM(b.amount), 0)::float AS revenue
        FROM services s
        LEFT JOIN bookings b ON b.service_id = s.id AND b.status = 'completed'
        GROUP BY s.id, s.name
        ORDER BY bookings DESC
        LIMIT 5
      `),
    ]);

    return success(res, "Dashboard overview fetched", {
      users: users.rows[0],
      workers: workers.rows[0],
      kyc: kyc.rows,
      bookings: bookings.rows,
      revenue: revenue.rows[0].total,
      recentBookings: recentBookings.rows,
      activity: activity.rows,
      revenueChart: revenueChart.rows,
      todayStats: todayStats.rows[0],
      activeWorkers: activeWorkers.rows[0].count,
      topServices: topServices.rows,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { overview };
