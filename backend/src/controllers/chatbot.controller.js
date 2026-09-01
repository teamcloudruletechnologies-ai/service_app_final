const { detectIntent } = require("../services/intent.service");
const chatbotService = require("../services/chatbot.service");

/**
 * Controller for the Webhook POST endpoint
 */
exports.handleWebhook = async (req, res) => {
  try {
    const { userId, message, platform } = req.body;

    if (!userId || !message) {
      return res.status(400).json({
        error: "userId and message are required"
      });
    }

    // Step 1: Intent Detection
    const intent = detectIntent(message);
    
    let reply = "";

    // Step 2: Route to specific service logic based on intent (Now async)
    switch (intent) {
      case 'CURRENT_BOOKING':
        reply = await chatbotService.handleCurrentBooking(userId);
        break;
      case 'PAST_BOOKINGS':
        reply = await chatbotService.handlePastBookings(userId);
        break;
      case 'RESCHEDULE':
        reply = await chatbotService.handleReschedule(userId, message);
        break;
      default:
        reply = chatbotService.handleUnknown();
    }

    // Step 3: Send Webhook Response
    return res.json({
      userId,
      intentDetected: intent,
      reply
    });

  } catch (error) {
    console.error("Webhook Error:", error);
    return res.status(500).json({ error: "Internal Server Error" });
  }
};
