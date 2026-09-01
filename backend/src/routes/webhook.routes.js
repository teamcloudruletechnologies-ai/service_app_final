const express = require("express");
const chatbotController = require("../controllers/chatbot.controller");

const router = express.Router();

/**
 * @route POST /webhook/urban
 * @description Core webhook endpoint for the Urban App Chatbot
 */
router.post("/urban", chatbotController.handleWebhook);

module.exports = router;
