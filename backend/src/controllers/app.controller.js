const Category = require("../models/category.model");
const Service = require("../models/service.model");
const Booking = require("../models/booking.model");
const User = require("../models/user.model");
const Worker = require("../models/worker.model");
const Banner = require("../models/banner.model");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listCategories(req, res, next) {
  try {
    const paging = getPagination(req.query);
    // If parent_id provided → return sub-categories of that parent
    // If no parent_id → return only root (top-level) categories
    const parentId = req.query.parent_id !== undefined
      ? (req.query.parent_id === '' ? null : parseInt(req.query.parent_id))
      : null;
    const data = await Category.list({
      ...paging,
      search: req.query.search,
      status: "active",
      parent_id: parentId,
    });
    return success(res, "Categories fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function listSubCategories(req, res, next) {
  try {
    const parentId = parseInt(req.params.id);
    const rows = await Category.listSubCategories(parentId, { page: 1, limit: 50, offset: 0 });
    return success(res, "Sub-categories fetched", rows);
  } catch (err) {
    return next(err);
  }
}

async function listServices(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Service.list({
      ...paging,
      search: req.query.search,
      category_id: req.query.category_id,
      status: "active",
    });
    return success(res, "Services fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getService(req, res, next) {
  try {
    const service = await Service.findById(req.params.id);
    if (!service || service.status !== "active") {
      return error(res, "Service not found", 404);
    }
    return success(res, "Service fetched", service);
  } catch (err) {
    return next(err);
  }
}

async function createBooking(req, res, next) {
  try {
    const userId = req.auth.id;
    const { service_id, worker_id, address, notes, scheduled_at } = req.body;

    const service = await Service.findById(service_id);
    if (!service || service.status !== "active") {
      return error(res, "Service not found or unavailable", 404);
    }

    const booking = await Booking.create({
      userId,
      serviceId: service_id,
      workerId: worker_id,
      amount: service.price || 0,
      address,
      notes,
      scheduledAt: scheduled_at,
    });

    // Award 5 credits for booking
    await User.awardCredits(userId, 5);
    await User.logActivity(userId, "booking_created", `Booked service: ${service.name} (Earned 5 credits)`);

    return success(res, "Booking created successfully", booking, 201);
  } catch (err) {
    return next(err);
  }
}

async function listMyBookings(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const filter = {
      ...paging,
      status: req.query.status,
    };
    if (req.auth.role === "worker") {
      filter.workerId = req.auth.id;
    } else {
      filter.userId = req.auth.id;
    }
    const data = await Booking.list(filter);
    return success(res, "Bookings fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getMyBooking(req, res, next) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, "Booking not found", 404);
    if (req.auth.role === "worker" && booking.worker_id !== req.auth.id) {
      return error(res, "You do not have permission to access this booking", 403);
    }
    if (req.auth.role === "user" && booking.user_id !== req.auth.id) {
      return error(res, "You do not have permission to access this booking", 403);
    }
    return success(res, "Booking fetched", booking);
  } catch (err) {
    return next(err);
  }
}

async function cancelBooking(req, res, next) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, "Booking not found", 404);
    if (booking.user_id !== req.auth.id) {
      return error(res, "You do not have permission to cancel this booking", 403);
    }
    if (!["pending", "confirmed"].includes(booking.status)) {
      return error(res, "This booking cannot be cancelled", 400);
    }

    const updated = await Booking.updateStatus(req.params.id, "cancelled");
    await User.logActivity(req.auth.id, "booking_cancelled", `Cancelled booking #${booking.id}`);

    return success(res, "Booking cancelled", updated);
  } catch (err) {
    return next(err);
  }
}

async function updateWorkerProfile(req, res, next) {
  try {
    const workerId = req.auth.id;
    const updated = await Worker.update(workerId, req.body);
    if (!updated) return error(res, "Worker profile not found", 404);
    return success(res, "Worker profile updated successfully", updated);
  } catch (err) {
    return next(err);
  }
}

async function updateMyBookingStatus(req, res, next) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, "Booking not found", 404);

    const { status, otp } = req.body;

    if (req.auth.role === "worker") {
      if (booking.worker_id !== req.auth.id) {
        return error(res, "You do not have permission to update this booking", 403);
      }
      
      const valid = {
        pending: ["confirmed", "in_progress", "cancelled"],
        confirmed: ["in_progress", "cancelled"],
        in_progress: ["completed"],
        completed: [],
        cancelled: []
      };
      if (!valid[booking.status].includes(status)) {
        return error(res, `Cannot change booking status from ${booking.status} to ${status}`, 400);
      }

      if (status === "in_progress") {
        if (!otp || String(booking.otp) !== String(otp)) {
          return error(res, "Invalid Start OTP code. Please ask the customer for the correct code.", 400);
        }
      }

      if (status === "completed") {
        if (!otp || String(booking.otp) !== String(otp)) {
          return error(res, "Invalid Completion OTP code. Please ask the customer for the correct code.", 400);
        }
      }
    } else if (req.auth.role === "user") {
      if (booking.user_id !== req.auth.id) {
        return error(res, "You do not have permission to update this booking", 403);
      }
      if (status !== "cancelled") {
        return error(res, "Users are only allowed to cancel bookings", 400);
      }
      if (!["pending", "confirmed"].includes(booking.status)) {
        return error(res, "This booking cannot be cancelled", 400);
      }
    } else {
      return error(res, "Forbidden role", 403);
    }

    const updated = await Booking.updateStatus(req.params.id, status);
    
    if (req.auth.role === "user") {
      await User.logActivity(req.auth.id, "booking_cancelled", `Cancelled booking #${booking.id}`);
    }

    return success(res, "Booking status updated successfully", updated);
  } catch (err) {
    return next(err);
  }
}

async function updateUserProfile(req, res, next) {
  try {
    const userId = req.auth.id;
    const { name, email, phone, state, address } = req.body;
    const updated = await User.update(userId, { name, email, phone, state, address });
    if (!updated) return error(res, "User profile not found", 404);
    return success(res, "User profile updated successfully", updated);
  } catch (err) {
    return next(err);
  }
}

async function listActiveBanners(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Banner.list({
      ...paging,
      status: "active",
    });
    return success(res, "Active banners fetched successfully", data);
  } catch (err) {
    return next(err);
  }
}

async function getWorkerEarnings(req, res, next) {
  try {
    const workerId = req.auth.id;
    const db = require("../config/db");

    const statsResult = await db.query(
      `SELECT
        COALESCE(SUM(worker_payout), 0)::float AS total_earnings,
        COALESCE(SUM(worker_payout) FILTER (WHERE status = 'paid'), 0)::float AS paid_earnings,
        COALESCE(SUM(worker_payout) FILTER (WHERE status = 'pending'), 0)::float AS pending_earnings
       FROM invoices
       WHERE worker_id = $1`,
      [workerId]
    );

    const todayStatsResult = await db.query(
      `SELECT
        COUNT(*)::int AS today_jobs,
        COALESCE(SUM(amount) FILTER (WHERE status = 'completed'), 0)::float AS today_earnings,
        COUNT(*) FILTER (WHERE status = 'completed')::int AS today_completed,
        COUNT(*) FILTER (WHERE status = 'in_progress')::int AS today_in_progress
       FROM bookings
       WHERE worker_id = $1 AND DATE(created_at) = CURRENT_DATE`,
      [workerId]
    );

    const totalJobsResult = await db.query(
      `SELECT
        COUNT(*)::int AS total_jobs,
        COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_jobs,
        COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled_jobs
       FROM bookings
       WHERE worker_id = $1`,
      [workerId]
    );

    const historyResult = await db.query(
      `SELECT
        i.id,
        i.invoice_number,
        i.amount::float AS amount,
        i.worker_payout::float AS worker_payout,
        i.status,
        i.paid_at,
        b.created_at as booking_date,
        s.name as service_name
       FROM invoices i
       LEFT JOIN bookings b ON b.id = i.booking_id
       LEFT JOIN services s ON s.id = b.service_id
       WHERE i.worker_id = $1
       ORDER BY i.created_at DESC`,
      [workerId]
    );

    return success(res, "Worker earnings fetched successfully", {
      stats: statsResult.rows[0],
      todayStats: todayStatsResult.rows[0],
      totalJobs: totalJobsResult.rows[0],
      history: historyResult.rows,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listCategories,
  listServices,
  getService,
  createBooking,
  listMyBookings,
  getMyBooking,
  cancelBooking,
  updateWorkerProfile,
  updateMyBookingStatus,
  updateUserProfile,
  listActiveBanners,
  getWorkerEarnings,
  listSubCategories,
};
