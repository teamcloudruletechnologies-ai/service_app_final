const express = require("express");
const auth = require("../middlewares/auth.middleware");
const supportController = require("../controllers/support.controller");

const router = express.Router();

// Public routes for FAQs and Policies
router.get("/faqs", supportController.getFaqs);
router.get("/policies", supportController.getPolicies);
router.get("/policies/:slug", supportController.getPolicyBySlug);
router.get("/categories", supportController.getCategories);

// Authenticated user support routes
router.use(auth);

router.post("/tickets", supportController.createTicket);
router.get("/tickets", supportController.listMyTickets);
router.get("/tickets/:id", supportController.getTicketDetails);
router.post("/tickets/:id/reply", supportController.sendTicketReply);

router.post("/report-professional", supportController.reportProfessional);
router.post("/account-request", supportController.submitAccountRequest);

module.exports = router;
