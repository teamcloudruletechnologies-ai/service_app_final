const supportModel = require("../models/support.model");
const db = require("../config/db");

// Helper to push notification to user
async function notifyUser(userId, title, message, entityId) {
  try {
    await db.query(
      `INSERT INTO notifications (title, message, type, entity_id)
       VALUES ($1, $2, 'support', $3)`,
      [title, message, String(entityId)]
    );
  } catch (e) {
    console.error("Failed to insert DB notification for user:", e.message);
  }
}

// ── SUPPORT DASHBOARD ANALYTICS ──────────────────────────────────────────────

async function getAnalytics(req, res, next) {
  try {
    const stats = await supportModel.getSupportAnalytics();
    res.json({ success: true, data: stats });
  } catch (err) {
    next(err);
  }
}

// ── TICKET MANAGEMENT ────────────────────────────────────────────────────────

async function listTickets(req, res, next) {
  try {
    const { status, priority, categoryId, search, page = 1, limit = 20 } = req.query;
    const result = await supportModel.listAdminTickets({
      status,
      priority,
      categoryId,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10)
    });
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function getTicketDetails(req, res, next) {
  try {
    const { id } = req.params;
    const ticket = await supportModel.getTicketDetails(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: "Ticket not found." });
    }
    res.json({ success: true, data: ticket });
  } catch (err) {
    next(err);
  }
}

async function updateTicketStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const user = req.auth || req.user || {};
    const adminId = user.id;
    const adminName = user.name || 'Admin';

    if (!status) {
      return res.status(400).json({ success: false, message: "Status is required." });
    }

    const ticket = await supportModel.updateTicketStatus({
      ticketId: id,
      status,
      adminId,
      adminName,
      notes
    });

    // Notify user
    await notifyUser(
      ticket.user_id,
      `Ticket #${ticket.ticket_number} Updated`,
      `Your support ticket status has been updated to "${status}".`,
      ticket.id
    );

    res.json({
      success: true,
      message: `Ticket status updated to ${status}`,
      data: ticket
    });
  } catch (err) {
    next(err);
  }
}

async function assignTicket(req, res, next) {
  try {
    const { id } = req.params;
    const { adminId } = req.body;

    const ticket = await supportModel.assignTicketAdmin({ ticketId: id, adminId });
    res.json({
      success: true,
      message: "Ticket assigned successfully.",
      data: ticket
    });
  } catch (err) {
    next(err);
  }
}

async function addAdminReply(req, res, next) {
  try {
    const { id } = req.params;
    const { message, isInternalNote = false, attachmentUrl } = req.body;
    const user = req.auth || req.user || {};
    const adminId = user.id;
    const adminName = user.name || 'Admin Support';

    if (!message) {
      return res.status(400).json({ success: false, message: "Message is required." });
    }

    const ticket = await supportModel.getTicketDetails(id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: "Ticket not found." });
    }

    const reply = await supportModel.addTicketMessage({
      ticketId: id,
      senderType: 'admin',
      senderId: adminId,
      senderName: adminName,
      message,
      isInternalNote: !!isInternalNote,
      attachmentUrl
    });

    if (!isInternalNote) {
      // Notify user of admin reply
      await notifyUser(
        ticket.user_id,
        `New reply on Ticket #${ticket.ticket_number}`,
        `Support Team: "${message.length > 60 ? message.substring(0, 60) + '...' : message}"`,
        ticket.id
      );
    }

    res.json({
      success: true,
      message: isInternalNote ? "Internal note saved." : "Reply sent to user.",
      data: reply
    });
  } catch (err) {
    next(err);
  }
}

// ── PROFESSIONAL REPORTS (COMPLAINTS) MANAGEMENT ─────────────────────────────

async function listProfessionalReports(req, res, next) {
  try {
    const { status, search, page = 1, limit = 20 } = req.query;
    const reports = await supportModel.listProfessionalReports({
      status,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10)
    });
    res.json({ success: true, data: reports });
  } catch (err) {
    next(err);
  }
}

async function updateProfessionalReport(req, res, next) {
  try {
    const { id } = req.params;
    const { status, adminAction, adminNotes } = req.body;

    const report = await supportModel.updateProfessionalReportStatus({
      reportId: id,
      status: status || 'Resolved',
      adminAction,
      adminNotes
    });

    // If disciplinary action is taken on worker (e.g. suspend or blacklist)
    if (adminAction && report.worker_id) {
      if (adminAction.toLowerCase().includes('suspend')) {
        await db.query(`UPDATE workers SET status = 'suspended' WHERE id = $1`, [report.worker_id]);
      } else if (adminAction.toLowerCase().includes('blacklist')) {
        await db.query(`UPDATE workers SET status = 'blacklisted' WHERE id = $1`, [report.worker_id]);
      }
    }

    res.json({
      success: true,
      message: "Worker complaint updated successfully.",
      data: report
    });
  } catch (err) {
    next(err);
  }
}

// ── ACCOUNT REQUESTS MANAGEMENT ───────────────────────────────────────────────

async function listAccountRequests(req, res, next) {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const requests = await supportModel.listAccountRequests({
      status,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10)
    });
    res.json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
}

async function updateAccountRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { status, adminNotes } = req.body;

    const request = await supportModel.updateAccountRequestStatus({
      requestId: id,
      status: status || 'Approved',
      adminNotes
    });

    // If request was approved and type is account deletion
    if (status === 'Approved' && request.request_type === 'deletion' && request.user_id) {
      await db.query(`UPDATE users SET status = 'deleted' WHERE id = $1`, [request.user_id]);
    }

    res.json({
      success: true,
      message: `Account request ${status.toLowerCase()} successfully.`,
      data: request
    });
  } catch (err) {
    next(err);
  }
}

// ── FAQ CRUD ───────────────────────────────────────────────────────────────────

async function createFaq(req, res, next) {
  try {
    const { category, question, answer, sortOrder } = req.body;
    if (!question || !answer) {
      return res.status(400).json({ success: false, message: "Question and Answer are required." });
    }
    const faq = await supportModel.createFaq({ category, question, answer, sortOrder });
    res.status(201).json({ success: true, message: "FAQ created successfully.", data: faq });
  } catch (err) {
    next(err);
  }
}

async function updateFaq(req, res, next) {
  try {
    const { id } = req.params;
    const faq = await supportModel.updateFaq(id, req.body);
    res.json({ success: true, message: "FAQ updated successfully.", data: faq });
  } catch (err) {
    next(err);
  }
}

async function deleteFaq(req, res, next) {
  try {
    const { id } = req.params;
    await supportModel.deleteFaq(id);
    res.json({ success: true, message: "FAQ deleted successfully." });
  } catch (err) {
    next(err);
  }
}

// ── POLICY MANAGEMENT ──────────────────────────────────────────────────────────

async function updatePolicy(req, res, next) {
  try {
    const { slug } = req.params;
    const { title, content, isPublished } = req.body;

    if (!title || !content) {
      return res.status(400).json({ success: false, message: "Title and Content are required." });
    }

    const policy = await supportModel.upsertPolicy({ slug, title, content, isPublished });
    res.json({ success: true, message: "Policy saved successfully.", data: policy });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getAnalytics,
  listTickets,
  getTicketDetails,
  updateTicketStatus,
  assignTicket,
  addAdminReply,
  listProfessionalReports,
  updateProfessionalReport,
  listAccountRequests,
  updateAccountRequest,
  createFaq,
  updateFaq,
  deleteFaq,
  updatePolicy,
};
