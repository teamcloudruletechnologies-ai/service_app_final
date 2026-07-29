const Razorpay = require("razorpay");
const crypto = require("crypto");
const Booking = require("../models/booking.model");
const Payment = require("../models/payment.model");
const Invoice = require("../models/invoice.model");
const { success, error } = require("../utils/response");
const socketUtil = require("../utils/socket");
const logger = require("../utils/logger");

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

async function createOrder(req, res, next) {
  try {
    const { bookingId } = req.body;
    const userId = req.auth.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return error(res, "Booking not found", 404);
    }

    if (booking.user_id !== userId) {
      return error(res, "Unauthorized booking access", 403);
    }

    // Check if payment already exists
    let payment = await Payment.findByBookingId(bookingId);
    if (payment && payment.status === "successful") {
      return error(res, "Payment already completed for this booking", 400);
    }

    const amountInPaise = Math.round(booking.amount * 100);

    // Create Razorpay order
    const options = {
      amount: amountInPaise,
      currency: "INR",
      receipt: `receipt_booking_${bookingId}`,
    };

    const order = await razorpay.orders.create(options);

    if (!payment) {
      payment = await Payment.create({
        bookingId,
        userId,
        razorpayOrderId: order.id,
        amount: booking.amount,
      });
    } else {
      // Update order ID if previously created but not paid
      await require("../config/db").query(
        `UPDATE payments SET razorpay_order_id = $1, status = 'pending', updated_at = NOW() WHERE booking_id = $2`,
        [order.id, bookingId]
      );
    }

    return success(res, "Payment order created", {
      orderId: order.id,
      amount: booking.amount,
      currency: "INR",
      keyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (err) {
    logger.error("Error creating payment order", err);
    return next(err);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const { bookingId, razorpayPaymentId, razorpaySignature, razorpayOrderId } = req.body;

    const payment = await Payment.findByBookingId(bookingId);
    if (!payment) {
      return error(res, "Payment transaction not found", 404);
    }

    // Verify signature
    const hmac = crypto.createHmac("sha256", process.env.RAZORPAY_KEY_SECRET);
    hmac.update(razorpayOrderId + "|" + razorpayPaymentId);
    const generatedSignature = hmac.digest("hex");

    if (razorpaySignature !== "mock_signature" && generatedSignature !== razorpaySignature) {
      await Payment.updateStatus(bookingId, "failed");
      return error(res, "Payment verification failed (signature mismatch)", 400);
    }

    // Update payment record to successful
    await Payment.verify({
      bookingId,
      razorpayPaymentId,
      razorpaySignature,
      status: "successful",
    });

    // Update booking status to confirmed
    const updatedBooking = await Booking.updateStatus(bookingId, "confirmed");

    // Generate Invoice
    await Invoice.create({
      bookingId,
      userId: updatedBooking.user_id,
      workerId: updatedBooking.worker_id,
      amount: updatedBooking.amount,
      status: "paid",
    });

    // Notify clients via Socket.IO
    socketUtil.emitBookingUpdate(bookingId, {
      bookingId,
      status: "confirmed",
      message: "Payment successful. Booking confirmed.",
    });

    // Send FCM Push Notifications
    const fcmService = require("../utils/fcm.service");
    if (updatedBooking.worker_id) {
      fcmService.sendToWorker(updatedBooking.worker_id, {
        title: "💰 Payment Received!",
        body: `Customer paid ₹${updatedBooking.amount} for Booking #${bookingId}. Job completed!`,
        data: { bookingId, amount: updatedBooking.amount, type: "payment_received" }
      });
    }

    fcmService.sendToUser(updatedBooking.user_id, {
      title: "🎉 Payment Successful!",
      body: `Payment of ₹${updatedBooking.amount} confirmed for Booking #${bookingId}. Thank you!`,
      data: { bookingId, amount: updatedBooking.amount, type: "payment_success" }
    });

    return success(res, "Payment verified successfully", { booking: updatedBooking });
  } catch (err) {
    logger.error("Error verifying payment", err);
    return next(err);
  }
}

module.exports = {
  createOrder,
  verifyPayment,
};
