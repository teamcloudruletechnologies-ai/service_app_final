const express = require("express");
const auth = require("../middlewares/auth.middleware");
const checkPermission = require("../middlewares/permission.middleware");
const adminSupportController = require("../controllers/admin_support.controller");

const router = express.Router();

router.use(auth);

// Support Analytics
router.get("/analytics", adminSupportController.getAnalytics);

// Tickets Management
router.get("/tickets", adminSupportController.listTickets);
router.get("/tickets/:id", adminSupportController.getTicketDetails);
router.patch("/tickets/:id/status", adminSupportController.updateTicketStatus);
router.patch("/tickets/:id/assign", adminSupportController.assignTicket);
router.post("/tickets/:id/reply", adminSupportController.addAdminReply);

// Worker Complaints
router.get("/complaints", adminSupportController.listProfessionalReports);
router.patch("/complaints/:id", adminSupportController.updateProfessionalReport);

// Account Requests
router.get("/account-requests", adminSupportController.listAccountRequests);
router.patch("/account-requests/:id", adminSupportController.updateAccountRequest);

// FAQ Management
router.post("/faqs", adminSupportController.createFaq);
router.put("/faqs/:id", adminSupportController.updateFaq);
router.delete("/faqs/:id", adminSupportController.deleteFaq);

// Policy Management
router.put("/policies/:slug", adminSupportController.updatePolicy);

module.exports = router;
