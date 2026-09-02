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

    let reply = "";
    let intent = detectIntent(message);

    // Escape Hatch: If user typed a core intent, clear any active session so they don't get trapped.
    if (intent !== 'UNKNOWN') {
      chatbotService.clearSession(userId);
    } 
    // Multi-turn Session Routing
    else {
      const session = chatbotService.getSession(userId);
      if (session) {
        if (session.step === 'WAITING_FOR_DATE') {
          reply = await chatbotService.processRescheduleDate(userId, message);
        } else if (session.step === 'WAITING_FOR_PAST_TIMEFRAME') {
          reply = await chatbotService.processPastBookingsTimeframe(userId, message);
        }
        return res.json({ userId, intentDetected: 'SESSION_CONTINUE', reply });
      }
    }

    // Step 2: Route to specific service logic based on new intent
    switch (intent) {
      case 'CURRENT_BOOKING':
        reply = await chatbotService.handleCurrentBooking(userId);
        break;
      case 'PAST_BOOKINGS':
        reply = await chatbotService.handlePastBookingsInit(userId);
        break;
      case 'RESCHEDULE':
        reply = await chatbotService.handleRescheduleInit(userId);
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
