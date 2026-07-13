const db = require("../config/db");

async function create({ bookingId, userId, razorpayOrderId, amount }) {
  const result = await db.query(
    `INSERT INTO payments (booking_id, user_id, razorpay_order_id, amount, status)
     VALUES ($1, $2, $3, $4, 'pending')
     RETURNING *`,
    [bookingId, userId, razorpayOrderId, amount]
  );
  return result.rows[0];
}

async function verify({ bookingId, razorpayPaymentId, razorpaySignature, status = 'successful' }) {
  const result = await db.query(
    `UPDATE payments
     SET razorpay_payment_id = $2, razorpay_signature = $3, status = $4, updated_at = NOW()
     WHERE booking_id = $1
     RETURNING *`,
    [bookingId, razorpayPaymentId, razorpaySignature, status]
  );
  return result.rows[0];
}

async function findByBookingId(bookingId) {
  const result = await db.query(
    `SELECT * FROM payments WHERE booking_id = $1`,
    [bookingId]
  );
  return result.rows[0];
}

async function updateStatus(bookingId, status) {
  const result = await db.query(
    `UPDATE payments
     SET status = $2, updated_at = NOW()
     WHERE booking_id = $1
     RETURNING *`,
    [bookingId, status]
  );
  return result.rows[0];
}

module.exports = {
  create,
  verify,
  findByBookingId,
  updateStatus,
};
