const Review = require("../models/review.model");
const Booking = require("../models/booking.model");
const { success, error } = require("../utils/response");
const { getPagination } = require("../utils/pagination");

async function createReview(req, res, next) {
  try {
    const userId = req.auth.id;
    const { bookingId, rating, comment } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return error(res, "Booking not found", 404);
    }

    if (booking.user_id !== userId) {
      return error(res, "Unauthorized booking access", 403);
    }

    if (booking.status !== "completed") {
      return error(res, "Reviews can only be written for completed bookings", 400);
    }

    const existing = await Review.findByBookingId(bookingId);
    if (existing) {
      return error(res, "Review already submitted for this booking", 400);
    }

    const review = await Review.create({
      bookingId,
      userId,
      workerId: booking.worker_id,
      rating,
      comment,
    });

    return success(res, "Review submitted successfully", review, 201);
  } catch (err) {
    return next(err);
  }
}

async function listReviews(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Review.list({
      ...paging,
      workerId: req.query.workerId,
      rating: req.query.rating,
    });
    return success(res, "Reviews fetched", data);
  } catch (err) {
    return next(err);
  }
}

// Admin-specific: no user auth required, uses admin token
async function adminListReviews(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Review.list({
      ...paging,
      workerId: req.query.workerId,
      rating: req.query.rating,
    });
    return success(res, "Reviews fetched", data);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createReview,
  listReviews,
  adminListReviews,
};
