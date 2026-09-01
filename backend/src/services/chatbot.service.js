const db = require("../config/db");

/**
 * Chatbot Service handling the core responses to different intents.
 * Connected to actual Postgres DB.
 */

async function handleCurrentBooking(userId) {
  try {
    // Query active bookings for the user
    const result = await db.query(
      `SELECT b.id, s.name as service_name, b.status, b.scheduled_at 
       FROM bookings b 
       JOIN services s ON b.service_id = s.id 
       WHERE b.user_id = $1 AND b.status NOT IN ('completed', 'cancelled')
       ORDER BY b.scheduled_at ASC LIMIT 1`, 
      [userId]
    );

    if (result.rows.length === 0) {
      return "You don't have any current or upcoming bookings.";
    }

    const booking = result.rows[0];
    const date = new Date(booking.scheduled_at).toLocaleString();
    return `You have an active booking (ID: ${booking.id}) for ${booking.service_name} scheduled at ${date}. Current status: ${booking.status}.`;
  } catch (err) {
    console.error("DB Error in handleCurrentBooking:", err);
    return "Sorry, I couldn't fetch your current bookings due to a system error.";
  }
}

async function handlePastBookings(userId) {
  try {
    const result = await db.query(
      `SELECT b.id, s.name as service_name, b.scheduled_at 
       FROM bookings b 
       JOIN services s ON b.service_id = s.id 
       WHERE b.user_id = $1 AND b.status = 'completed'
       ORDER BY b.scheduled_at DESC LIMIT 3`, 
      [userId]
    );

    if (result.rows.length === 0) {
      return "You don't have any past completed bookings yet.";
    }

    let reply = "Here are your recent past bookings:\n";
    result.rows.forEach(b => {
      reply += `- ${b.service_name} on ${new Date(b.scheduled_at).toLocaleDateString()}\n`;
    });
    return reply;
  } catch (err) {
    console.error("DB Error in handlePastBookings:", err);
    return "Sorry, I couldn't fetch your booking history.";
  }
}

async function handleReschedule(userId, message) {
  try {
    // For demo purposes, we will find the user's latest active booking and push it by 1 day.
    // In a full NLP bot, we would parse the exact requested time from 'message'.
    const result = await db.query(
      `SELECT id, scheduled_at FROM bookings 
       WHERE user_id = $1 AND status NOT IN ('completed', 'cancelled')
       ORDER BY scheduled_at ASC LIMIT 1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return "You don't have any active bookings to reschedule.";
    }

    const booking = result.rows[0];
    const newDate = new Date(booking.scheduled_at);
    newDate.setDate(newDate.getDate() + 1); // Postpone by 1 day for this logic

    await db.query(
      `UPDATE bookings SET scheduled_at = $1, updated_at = NOW() WHERE id = $2`,
      [newDate, booking.id]
    );

    return `Your booking (ID: ${booking.id}) has been successfully rescheduled to ${newDate.toLocaleString()}.`;
  } catch (err) {
    console.error("DB Error in handleReschedule:", err);
    return "Sorry, I couldn't reschedule your booking.";
  }
}

function handleUnknown() {
  return "I can help you check your current bookings, past history, or reschedule an upcoming service. Just tap one of the options below!";
}

module.exports = {
  handleCurrentBooking,
  handlePastBookings,
  handleReschedule,
  handleUnknown
};
