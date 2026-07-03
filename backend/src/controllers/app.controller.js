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
    const data = await Category.list({
      ...paging,
      search: req.query.search,
      status: "active",
    });
    return success(res, "Categories fetched", data);
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

    await User.logActivity(userId, "booking_created", `Booked service: ${service.name}`);

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

    const { status } = req.body;

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
};
