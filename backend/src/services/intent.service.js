/**
 * Analyzes the customer's chat message to detect their intent.
 * Based on simple keyword matching as per Step 5 of the PDF.
 */
function detectIntent(message) {
  if (!message) return 'UNKNOWN';
  const text = message.toLowerCase();

  if (text.includes("book") || text.includes("plumber") || text.includes("ac") || text.includes("service")) {
    return 'BOOK_SERVICE';
  }
  
  if (text.includes("track") || text.includes("technician") || text.includes("where")) {
    return 'TRACK_WORKER';
  }
  
  if (text.includes("cancel")) {
    return 'CANCEL_BOOKING';
  }
  
  if (text.includes("invoice") || text.includes("payment") || text.includes("bill")) {
    return 'INVOICE';
  }

  return 'UNKNOWN';
}

module.exports = {
  detectIntent
};
