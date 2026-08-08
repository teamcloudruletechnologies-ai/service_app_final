const supportModel = require("../models/support.model");
const db = require("../config/db");

// ── TICKETS ───────────────────────────────────────────────────────────────────

async function createTicket(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { bookingId, categoryId, categoryName, subject, description, priority, attachmentUrl } = req.body;

    if (!subject || !description) {
      return res.status(400).json({ success: false, message: "Subject and Description are required." });
    }

    const ticket = await supportModel.createTicket({
      userId,
      bookingId,
      categoryId,
      categoryName,
      subject,
      description,
      priority: priority || 'Medium',
      attachmentUrl
    });

    res.status(201).json({
      success: true,
      message: "Support ticket created successfully.",
      data: ticket
    });
  } catch (err) {
    next(err);
  }
}

async function listMyTickets(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { page = 1, limit = 20 } = req.query;

    const result = await supportModel.listUserTickets(userId, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10)
    });

    res.json({
      success: true,
      data: result
    });
  } catch (err) {
    next(err);
  }
}

async function getTicketDetails(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { id } = req.params;

    const ticket = await supportModel.getTicketDetails(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: "Ticket not found." });
    }

    // Auth check: User can only see their own tickets unless admin
    if (user.role !== 'admin' && ticket.user_id !== userId) {
      return res.status(403).json({ success: false, message: "Access denied." });
    }

    res.json({
      success: true,
      data: ticket
    });
  } catch (err) {
    next(err);
  }
}

async function sendTicketReply(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { id } = req.params;
    const { message, attachmentUrl } = req.body;

    if (!message) {
      return res.status(400).json({ success: false, message: "Message content is required." });
    }

    const ticket = await supportModel.getTicketDetails(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: "Ticket not found." });
    }

    if (ticket.user_id !== userId && user.role !== 'admin') {
      return res.status(403).json({ success: false, message: "Access denied." });
    }

    const reply = await supportModel.addTicketMessage({
      ticketId: id,
      senderType: 'user',
      senderId: userId,
      senderName: user.name || 'User',
      message,
      attachmentUrl
    });

    res.json({
      success: true,
      message: "Reply sent successfully.",
      data: reply
    });
  } catch (err) {
    next(err);
  }
}

// ── PROFESSIONAL REPORTS (WORKER COMPLAINTS) ──────────────────────────────────

async function reportProfessional(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { workerId, bookingId, reason, description, photoUrl } = req.body;

    if (!reason || !description) {
      return res.status(400).json({ success: false, message: "Reason and description are required." });
    }

    const report = await supportModel.createProfessionalReport({
      userId,
      workerId,
      bookingId,
      reason,
      description,
      photoUrl
    });

    res.status(201).json({
      success: true,
      message: "Complaint lodged successfully.",
      data: report
    });
  } catch (err) {
    next(err);
  }
}

// ── ACCOUNT REQUESTS ───────────────────────────────────────────────────────────

async function submitAccountRequest(req, res, next) {
  try {
    const user = req.auth || req.user || {};
    const userId = user.id;
    const { requestType, details, reason } = req.body;

    if (!requestType) {
      return res.status(400).json({ success: false, message: "Request type is required." });
    }

    if (requestType === 'logout_all_devices') {
      // Invalidate existing sessions by updating user token version or timestamp
      await db.query(`UPDATE users SET updated_at = NOW() WHERE id = $1`, [userId]);
      return res.json({
        success: true,
        message: "Successfully logged out from all other devices."
      });
    }

    const request = await supportModel.createAccountRequest({
      userId,
      requestType,
      details: details || {},
      reason
    });

    res.status(201).json({
      success: true,
      message: "Account request submitted successfully.",
      data: request
    });
  } catch (err) {
    next(err);
  }
}

// ── FAQS & POLICIES ──────────────────────────────────────────────────────────

async function getCategories(req, res, next) {
  try {
    const categories = await supportModel.listCategories();
    res.json({ success: true, data: categories });
  } catch (err) {
    next(err);
  }
}

async function getFaqs(req, res, next) {
  try {
    const { category, search } = req.query;
    const faqs = await supportModel.listFaqs({ category, search });
    res.json({ success: true, data: faqs });
  } catch (err) {
    next(err);
  }
}

async function getPolicies(req, res, next) {
  try {
    const policies = await supportModel.listPolicies();
    res.json({ success: true, data: policies });
  } catch (err) {
    next(err);
  }
}

async function getPolicyBySlug(req, res, next) {
  try {
    const { slug } = req.params;
    const policy = await supportModel.getPolicyBySlug(slug);
    if (!policy) {
      return res.status(404).json({ success: false, message: "Policy not found." });
    }
    res.json({ success: true, data: policy });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createTicket,
  listMyTickets,
  getTicketDetails,
  sendTicketReply,
  reportProfessional,
  submitAccountRequest,
  getCategories,
  getFaqs,
  getPolicies,
  getPolicyBySlug,
};
