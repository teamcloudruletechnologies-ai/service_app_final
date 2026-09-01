const { detectIntent } = require("../services/intent.service");
const chatbotService = require("../services/chatbot.service");

/**
 * Controller for the Webhook POST endpoint
 */
exports.handleWebhook = async (req, res) => {
  try {
    const { userId, message, bookingId, platform } = req.body;

    if (!userId || !message) {
      return res.status(400).json({
        error: "userId and message are required"
      });
    }

    // Step 1: Intent Detection
    const intent = detectIntent(message);
    
    let reply = "";

    // Step 2: Route to specific service logic based on intent
    switch (intent) {
      case 'BOOK_SERVICE':
        reply = chatbotService.handleBooking(message);
        break;
      case 'TRACK_WORKER':
        reply = chatbotService.handleTracking(bookingId);
        break;
      case 'CANCEL_BOOKING':
        reply = chatbotService.handleCancellation(bookingId);
        break;
      case 'INVOICE':
        reply = chatbotService.handleInvoice(bookingId);
        break;
      default:
        reply = chatbotService.handleUnknown();
    }

    // Step 3: Send Webhook Response
    return res.json({
      userId,
      bookingId: bookingId || null,
      intentDetected: intent,
      reply
    });

  } catch (error) {
    console.error("Webhook Error:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};
