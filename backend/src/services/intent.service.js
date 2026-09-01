/**
 * Analyzes the customer's chat message to detect their intent.
 * Updated for Customer Support (Version 2.0).
 */
function detectIntent(message) {
  if (!message) return 'UNKNOWN';
  const text = message.toLowerCase();

  if (text.includes("current") || text.includes("active") || text.includes("today") || text.includes("upcoming") || text.includes("now")) {
    return 'CURRENT_BOOKING';
  }
  
  if (text.includes("past") || text.includes("history") || text.includes("previous") || text.includes("completed")) {
    return 'PAST_BOOKINGS';
  }
  
  if (text.includes("reschedule") || text.includes("change time") || text.includes("postpone") || text.includes("delay")) {
    return 'RESCHEDULE';
  }

  return 'UNKNOWN';
}

module.exports = {
  detectIntent
};

