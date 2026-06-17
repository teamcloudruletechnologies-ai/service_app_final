const Category = require("../models/category.model");
const Service = require("../models/service.model");
const Booking = require("../models/booking.model");
const User = require("../models/user.model");
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
    const data = await Booking.list({
      ...paging,
      userId: req.auth.id,
      status: req.query.status,
    });
    return success(res, "Bookings fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getMyBooking(req, res, next) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, "Booking not found", 404);
    if (booking.user_id !== req.auth.id) {
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

module.exports = {
  listCategories,
  listServices,
  getService,
  createBooking,
  listMyBookings,
  getMyBooking,
  cancelBooking,
};
