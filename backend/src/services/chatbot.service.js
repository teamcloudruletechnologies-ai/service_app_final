const db = require("../config/db");

// Simple Memory (State Management) for Multi-turn Conversation
const activeSessions = new Map();

async function handleCurrentBooking(userId) {
  try {
    const result = await db.query(
      `SELECT b.id, s.name as service_name, b.status, b.scheduled_at 
       FROM bookings b JOIN services s ON b.service_id = s.id 
       WHERE b.user_id = $1 AND b.status NOT IN ('completed', 'cancelled')
       ORDER BY b.scheduled_at ASC LIMIT 1`, [userId]
    );

    if (result.rows.length === 0) return "You don't have any current or upcoming bookings.";

    const booking = result.rows[0];
    const date = new Date(booking.scheduled_at).toLocaleString();
    return `You have an active booking (ID: ${booking.id}) for ${booking.service_name} scheduled at ${date}. Status: ${booking.status}.`;
  } catch (err) {
    console.error("DB Error in handleCurrentBooking:", err);
    return "Sorry, I couldn't fetch your current bookings due to a system error.";
  }
}

async function handlePastBookingsInit(userId) {
  // Set session to wait for timeframe
  activeSessions.set(userId, { step: 'WAITING_FOR_PAST_TIMEFRAME' });
  return "Which past bookings would you like to see? Please reply with a number:\n1️⃣ Today\n2️⃣ Yesterday\n3️⃣ Last 1 Week";
}

async function processPastBookingsTimeframe(userId, message) {
  const session = activeSessions.get(userId);
  if (!session) return handleUnknown();

  const choice = message.trim();
  let dateQuery = "";

  if (choice === "1" || choice.toLowerCase().includes("today")) {
    dateQuery = "b.scheduled_at >= CURRENT_DATE";
  } else if (choice === "2" || choice.toLowerCase().includes("yesterday")) {
    dateQuery = "b.scheduled_at >= CURRENT_DATE - INTERVAL '1 day' AND b.scheduled_at < CURRENT_DATE";
  } else if (choice === "3" || choice.toLowerCase().includes("week")) {
    dateQuery = "b.scheduled_at >= CURRENT_DATE - INTERVAL '7 days'";
  } else {
    return "Invalid choice. Please reply with 1, 2, or 3.";
  }

  try {
    const result = await db.query(
      `SELECT b.id, s.name as service_name, b.scheduled_at 
       FROM bookings b JOIN services s ON b.service_id = s.id 
       WHERE b.user_id = $1 AND b.status = 'completed' AND ${dateQuery}
       ORDER BY b.scheduled_at DESC LIMIT 5`, [userId]
    );

    activeSessions.delete(userId); // Clear session

    if (result.rows.length === 0) return "You don't have any completed bookings in this timeframe.";

    let reply = "Here are your past bookings for the selected timeframe:\n";
    result.rows.forEach(b => {
      reply += `- ${b.service_name} on ${new Date(b.scheduled_at).toLocaleDateString()}\n`;
    });
    return reply;
  } catch (err) {
    console.error("DB Error in processPastBookingsTimeframe:", err);
    return "Sorry, I couldn't fetch your booking history.";
  }
}

async function handleRescheduleInit(userId) {
  try {
    const result = await db.query(
      `SELECT id, scheduled_at FROM bookings 
       WHERE user_id = $1 AND status NOT IN ('completed', 'cancelled')
       ORDER BY scheduled_at ASC LIMIT 1`, [userId]
    );

    if (result.rows.length === 0) return "You don't have any active bookings to reschedule.";

    const booking = result.rows[0];
    
    // Save state in memory
    activeSessions.set(userId, { step: 'WAITING_FOR_DATE', bookingId: booking.id });
    
    return `I found your active booking (ID: ${booking.id}). What date and time do you want to reschedule it to? (Format: YYYY-MM-DD HH:MM)`;
  } catch (err) {
    console.error("DB Error in handleRescheduleInit:", err);
    return "Sorry, I couldn't initiate reschedule.";
  }
}

async function processRescheduleDate(userId, message) {
  const session = activeSessions.get(userId);
  if (!session) return handleUnknown();

  try {
    const newDate = new Date(message);
    if (isNaN(newDate.getTime())) {
      return "That doesn't look like a valid date. Please reply with a valid date and time (e.g., 2026-09-10 10:30 AM).";
    }

    await db.query(
      `UPDATE bookings SET scheduled_at = $1, updated_at = NOW() WHERE id = $2`,
      [newDate, session.bookingId]
    );

    activeSessions.delete(userId);

    return `Done! Your booking (ID: ${session.bookingId}) has been successfully rescheduled to ${newDate.toLocaleString()}.`;
  } catch (err) {
    console.error("DB Error in processRescheduleDate:", err);
    return "Sorry, there was an error saving your new date.";
  }
}

function handleUnknown() {
  return "I can help you check your current bookings, past history, or reschedule an upcoming service. Just tap one of the options below!";
}

function getSession(userId) {
  return activeSessions.get(userId);
}

function clearSession(userId) {
  activeSessions.delete(userId);
}

module.exports = {
  handleCurrentBooking,
  handlePastBookingsInit,
  processPastBookingsTimeframe,
  handleRescheduleInit,
  processRescheduleDate,
  handleUnknown,
  getSession,
  clearSession
};
