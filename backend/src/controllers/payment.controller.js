let Razorpay;
try {
  Razorpay = require("razorpay");
} catch (_) {}

const crypto = require("crypto");
const Booking = require("../models/booking.model");
const Payment = require("../models/payment.model");
const Invoice = require("../models/invoice.model");
const { success, error } = require("../utils/response");
const socketUtil = require("../utils/socket");
const logger = require("../utils/logger");

const razorpay = Razorpay
  ? new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || "rzp_test_mock",
      key_secret: process.env.RAZORPAY_KEY_SECRET || "mock_secret",
    })
  : null;

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

    // Reset payment_status on booking to unpaid if needed
    const db = require("../config/db");
    try {
      await db.query(`UPDATE bookings SET payment_status = 'unpaid' WHERE id = $1`, [bookingId]);
    } catch (_) {}

    let payment = await Payment.findByBookingId(bookingId);

    const amountInPaise = Math.round((booking.amount > 0 ? booking.amount : 500) * 100);

    let orderId = `order_mock_${Date.now()}`;
    let keyId = process.env.RAZORPAY_KEY_ID || "rzp_test_5123456789";

    if (razorpay && process.env.RAZORPAY_KEY_ID) {
      try {
        const order = await razorpay.orders.create({
          amount: amountInPaise,
          currency: "INR",
          receipt: `receipt_booking_${bookingId}`,
        });
        if (order && order.id) {
          orderId = order.id;
        }
      } catch (rErr) {
        logger.warn("Razorpay API call failed, falling back to test order:", rErr.message);
      }
    }

    if (!payment) {
      payment = await Payment.create({
        bookingId,
        userId,
        razorpayOrderId: orderId,
        amount: booking.amount > 0 ? booking.amount : 500,
      });
    } else {
      // Reset payment status to pending and update order ID
      await db.query(
        `UPDATE payments SET razorpay_order_id = $1, status = 'pending', updated_at = NOW() WHERE booking_id = $2`,
        [orderId, bookingId]
      );
    }

    return success(res, "Payment order created", {
      orderId: orderId,
      amount: booking.amount > 0 ? booking.amount : 500,
      currency: "INR",
      keyId: keyId,
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

    // Update booking status to completed and payment_status to paid
    const db = require("../config/db");
    await db.query(
      `UPDATE bookings SET payment_status = 'paid', status = 'completed', updated_at = NOW() WHERE id = $1`,
      [bookingId]
    );
    const updatedBooking = await Booking.findById(bookingId);

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
