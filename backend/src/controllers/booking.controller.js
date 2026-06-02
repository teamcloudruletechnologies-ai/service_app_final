const Booking = require("../models/booking.model");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listBookings(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Booking.list({
      ...paging,
      status: req.query.status,
      userId: req.query.userId,
      workerId: req.query.workerId,
    });
    return success(res, "Bookings fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getBooking(req, res, next) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return error(res, "Booking not found", 404);
    return success(res, "Booking fetched", booking);
  } catch (err) {
    return next(err);
  }
}

async function updateBookingStatus(req, res, next) {
  try {
    const booking = await Booking.updateStatus(req.params.id, req.body.status);
    if (!booking) return error(res, "Booking not found", 404);
    return success(res, "Booking status updated", booking);
  } catch (err) {
    return next(err);
  }
}

async function getBookingAnalytics(req, res, next) {
  try {
    const data = await Booking.analytics();
    return success(res, "Booking analytics fetched", data);
  } catch (err) {
    return next(err);
  }
}

module.exports = { listBookings, getBooking, updateBookingStatus, getBookingAnalytics };
