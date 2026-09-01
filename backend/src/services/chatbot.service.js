/**
 * Chatbot Service handling the core responses to different intents.
 * Currently uses simulated responses, which can later be connected to actual DB models.
 */

function handleBooking(message) {
  return "Sure! Which service do you need and what is your location?";
}

function handleTracking(bookingId) {
  if (!bookingId) {
    return "Please provide a booking ID to track your technician.";
  }
  // Mock tracking response simulating DB fetch
  return `Let me check your technician and booking status for ID ${bookingId}. Your technician Suresh is 10 mins away. Job Start OTP: 4567.`;
}

function handleCancellation(bookingId) {
  if (!bookingId) {
    return "Please provide a booking ID to cancel.";
  }
  // Mock cancellation response
  return `I will check whether booking ${bookingId} can be cancelled. Done, your booking has been cancelled and any refund will be processed in 2-3 days.`;
}

function handleInvoice(bookingId) {
  if (!bookingId) {
    return "Please provide a booking ID to check your invoice.";
  }
  return `The total invoice amount for booking ${bookingId} is ₹500. Status: PAID.`;
}

function handleUnknown() {
  return "I can help with booking a service, tracking a technician, cancellation, invoices, and payment status. How can I assist you today?";
}

module.exports = {
  handleBooking,
  handleTracking,
  handleCancellation,
  handleInvoice,
  handleUnknown
};
