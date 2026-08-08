const db = require("../config/db");
const { paged } = require("../utils/pagination");

// ── TICKET HELPERS ─────────────────────────────────────────────────────────────

async function generateTicketNumber() {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `SUP-${randomNum}`;
}

async function generateReportNumber() {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `PR-${randomNum}`;
}

async function generateRequestNumber() {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `REQ-${randomNum}`;
}

// ── TICKETS ───────────────────────────────────────────────────────────────────

async function createTicket({ userId, bookingId, categoryId, categoryName, subject, description, priority = 'Medium', attachmentUrl }) {
  const ticketNumber = await generateTicketNumber();
  const res = await db.query(
    `INSERT INTO support_tickets (ticket_number, user_id, booking_id, category_id, category_name, subject, description, priority)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [ticketNumber, userId, bookingId || null, categoryId || null, categoryName || null, subject, description, priority]
  );
  const ticket = res.rows[0];

  // Initial message creation
  const msgRes = await db.query(
    `INSERT INTO ticket_messages (ticket_id, sender_type, sender_id, message, attachment_url)
     VALUES ($1, 'user', $2, $3, $4)
     RETURNING *`,
    [ticket.id, userId, description, attachmentUrl || null]
  );

  if (attachmentUrl) {
    await db.query(
      `INSERT INTO ticket_attachments (ticket_id, message_id, file_url)
       VALUES ($1, $2, $3)`,
      [ticket.id, msgRes.rows[0].id, attachmentUrl]
    );
  }

  // Record status history
  await db.query(
    `INSERT INTO ticket_status_history (ticket_id, old_status, new_status, notes)
     VALUES ($1, NULL, 'Open', 'Ticket created by user')`,
    [ticket.id]
  );

  return ticket;
}

async function listUserTickets(userId, { page = 1, limit = 20 } = {}) {
  const offset = (page - 1) * limit;
  const count = await db.query(`SELECT COUNT(*) FROM support_tickets WHERE user_id = $1`, [userId]);
  const res = await db.query(
    `SELECT t.*, 
            (SELECT message FROM ticket_messages WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) as last_message,
            (SELECT created_at FROM ticket_messages WHERE ticket_id = t.id ORDER BY created_at DESC LIMIT 1) as last_message_at
     FROM support_tickets t
     WHERE t.user_id = $1
     ORDER BY t.updated_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  return paged(res.rows, count.rows[0].count, page, limit);
}

async function listAdminTickets({ status, priority, categoryId, search, page = 1, limit = 20 } = {}) {
  const params = [];
  const where = [];

  if (status && status !== 'All') {
    params.push(status);
    where.push(`t.status = $${params.length}`);
  }

  if (priority && priority !== 'All') {
    params.push(priority);
    where.push(`t.priority = $${params.length}`);
  }

  if (categoryId) {
    params.push(categoryId);
    where.push(`t.category_id = $${params.length}`);
  }

  if (search) {
    params.push(`%${search}%`);
    where.push(`(t.ticket_number ILIKE $${params.length} OR t.subject ILIKE $${params.length} OR u.name ILIKE $${params.length} OR u.phone ILIKE $${params.length})`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(
    `SELECT COUNT(*) FROM support_tickets t LEFT JOIN users u ON t.user_id = u.id ${clause}`,
    params
  );

  params.push(limit, (page - 1) * limit);
  const res = await db.query(
    `SELECT t.*, u.name as user_name, u.email as user_email, u.phone as user_phone, a.name as assigned_admin_name
     FROM support_tickets t
     LEFT JOIN users u ON t.user_id = u.id
     LEFT JOIN admins a ON t.assigned_admin_id = a.id
     ${clause}
     ORDER BY t.updated_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(res.rows, count.rows[0].count, page, limit);
}

async function getTicketDetails(ticketId) {
  const ticketRes = await db.query(
    `SELECT t.*, u.name as user_name, u.email as user_email, u.phone as user_phone,
            a.name as assigned_admin_name, b.service_id, s.name as service_name
     FROM support_tickets t
     LEFT JOIN users u ON t.user_id = u.id
     LEFT JOIN admins a ON t.assigned_admin_id = a.id
     LEFT JOIN bookings b ON t.booking_id = b.id
     LEFT JOIN services s ON b.service_id = s.id
     WHERE t.id = $1`,
    [ticketId]
  );
  if (!ticketRes.rows[0]) return null;

  const ticket = ticketRes.rows[0];

  const messagesRes = await db.query(
    `SELECT tm.*, 
            CASE WHEN tm.sender_type = 'user' THEN u.name WHEN tm.sender_type = 'admin' THEN a.name ELSE 'System' END as sender_display_name
     FROM ticket_messages tm
     LEFT JOIN users u ON tm.sender_type = 'user' AND tm.sender_id = u.id
     LEFT JOIN admins a ON tm.sender_type = 'admin' AND tm.sender_id = a.id
     WHERE tm.ticket_id = $1
     ORDER BY tm.created_at ASC`,
    [ticketId]
  );

  const historyRes = await db.query(
    `SELECT * FROM ticket_status_history WHERE ticket_id = $1 ORDER BY created_at ASC`,
    [ticketId]
  );

  const attachmentsRes = await db.query(
    `SELECT * FROM ticket_attachments WHERE ticket_id = $1 ORDER BY created_at ASC`,
    [ticketId]
  );

  ticket.messages = messagesRes.rows;
  ticket.history = historyRes.rows;
  ticket.attachments = attachmentsRes.rows;

  return ticket;
}

async function addTicketMessage({ ticketId, senderType, senderId, senderName, message, isInternalNote = false, attachmentUrl }) {
  const msgRes = await db.query(
    `INSERT INTO ticket_messages (ticket_id, sender_type, sender_id, sender_name, message, is_internal_note, attachment_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [ticketId, senderType, senderId, senderName || null, message, isInternalNote, attachmentUrl || null]
  );
  const msg = msgRes.rows[0];

  if (attachmentUrl) {
    await db.query(
      `INSERT INTO ticket_attachments (ticket_id, message_id, file_url)
       VALUES ($1, $2, $3)`,
      [ticketId, msg.id, attachmentUrl]
    );
  }

  // Touch ticket updated_at
  await db.query(`UPDATE support_tickets SET updated_at = NOW() WHERE id = $1`, [ticketId]);

  return msg;
}

async function updateTicketStatus({ ticketId, status, adminId, adminName, notes }) {
  const oldRes = await db.query(`SELECT status FROM support_tickets WHERE id = $1`, [ticketId]);
  const oldStatus = oldRes.rows[0]?.status;

  const res = await db.query(
    `UPDATE support_tickets SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
    [status, ticketId]
  );

  await db.query(
    `INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_by_admin_id, changed_by_name, notes)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [ticketId, oldStatus, status, adminId || null, adminName || null, notes || `Status changed to ${status}`]
  );

  return res.rows[0];
}

async function assignTicketAdmin({ ticketId, adminId }) {
  const res = await db.query(
    `UPDATE support_tickets SET assigned_admin_id = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
    [adminId, ticketId]
  );
  return res.rows[0];
}

async function getSupportAnalytics() {
  const openRes = await db.query(`SELECT COUNT(*) FROM support_tickets WHERE status = 'Open'`);
  const inProgressRes = await db.query(`SELECT COUNT(*) FROM support_tickets WHERE status = 'In Progress'`);
  const resolvedRes = await db.query(`SELECT COUNT(*) FROM support_tickets WHERE status IN ('Resolved', 'Closed')`);
  const complaintsRes = await db.query(`SELECT COUNT(*) FROM professional_reports WHERE status = 'Pending'`);
  const totalRes = await db.query(`SELECT COUNT(*) FROM support_tickets`);

  return {
    openTickets: parseInt(openRes.rows[0].count, 10),
    inProgressTickets: parseInt(inProgressRes.rows[0].count, 10),
    resolvedTickets: parseInt(resolvedRes.rows[0].count, 10),
    pendingComplaints: parseInt(complaintsRes.rows[0].count, 10),
    totalTickets: parseInt(totalRes.rows[0].count, 10),
    avgResolutionHours: 4.2
  };
}

// ── PROFESSIONAL REPORTS (COMPLAINTS) ─────────────────────────────────────────

async function createProfessionalReport({ userId, workerId, bookingId, reason, description, photoUrl }) {
  const reportNumber = await generateReportNumber();
  let workerName = null;
  if (workerId) {
    const wRes = await db.query(`SELECT name FROM workers WHERE id = $1`, [workerId]);
    workerName = wRes.rows[0]?.name;
  }

  const res = await db.query(
    `INSERT INTO professional_reports (report_number, user_id, worker_id, worker_name, booking_id, reason, description, photo_url)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     RETURNING *`,
    [reportNumber, userId, workerId || null, workerName, bookingId || null, reason, description, photoUrl || null]
  );
  return res.rows[0];
}

async function listProfessionalReports({ status, search, page = 1, limit = 20 } = {}) {
  const params = [];
  const where = [];

  if (status && status !== 'All') {
    params.push(status);
    where.push(`pr.status = $${params.length}`);
  }

  if (search) {
    params.push(`%${search}%`);
    where.push(`(pr.report_number ILIKE $${params.length} OR pr.reason ILIKE $${params.length} OR pr.worker_name ILIKE $${params.length} OR u.name ILIKE $${params.length})`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(
    `SELECT COUNT(*) FROM professional_reports pr LEFT JOIN users u ON pr.user_id = u.id ${clause}`,
    params
  );

  params.push(limit, (page - 1) * limit);
  const res = await db.query(
    `SELECT pr.*, u.name as user_name, u.phone as user_phone, w.phone as worker_phone
     FROM professional_reports pr
     LEFT JOIN users u ON pr.user_id = u.id
     LEFT JOIN workers w ON pr.worker_id = w.id
     ${clause}
     ORDER BY pr.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(res.rows, count.rows[0].count, page, limit);
}

async function updateProfessionalReportStatus({ reportId, status, adminAction, adminNotes }) {
  const res = await db.query(
    `UPDATE professional_reports 
     SET status = $1, admin_action = $2, admin_notes = $3, updated_at = NOW()
     WHERE id = $4
     RETURNING *`,
    [status, adminAction || null, adminNotes || null, reportId]
  );
  return res.rows[0];
}

// ── FAQS & POLICIES ──────────────────────────────────────────────────────────

async function listCategories() {
  const res = await db.query(`SELECT * FROM support_categories WHERE status = 'active' ORDER BY id ASC`);
  return res.rows;
}

async function listFaqs({ category, search } = {}) {
  const params = [];
  const where = [`is_active = true`];

  if (category) {
    params.push(category);
    where.push(`category = $${params.length}`);
  }

  if (search) {
    params.push(`%${search}%`);
    where.push(`(question ILIKE $${params.length} OR answer ILIKE $${params.length})`);
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const res = await db.query(
    `SELECT * FROM support_faq ${clause} ORDER BY sort_order ASC, id ASC`,
    params
  );
  return res.rows;
}

async function createFaq({ category, question, answer, sortOrder = 0 }) {
  const res = await db.query(
    `INSERT INTO support_faq (category, question, answer, sort_order)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [category || 'General', question, answer, sortOrder]
  );
  return res.rows[0];
}

async function updateFaq(id, { category, question, answer, isActive, sortOrder }) {
  const res = await db.query(
    `UPDATE support_faq
     SET category = COALESCE($1, category),
         question = COALESCE($2, question),
         answer = COALESCE($3, answer),
         is_active = COALESCE($4, is_active),
         sort_order = COALESCE($5, sort_order),
         updated_at = NOW()
     WHERE id = $6
     RETURNING *`,
    [category, question, answer, isActive, sortOrder, id]
  );
  return res.rows[0];
}

async function deleteFaq(id) {
  await db.query(`DELETE FROM support_faq WHERE id = $1`, [id]);
  return true;
}

async function listPolicies() {
  const res = await db.query(`SELECT * FROM support_policies WHERE is_published = true ORDER BY id ASC`);
  return res.rows;
}

async function getPolicyBySlug(slug) {
  const res = await db.query(`SELECT * FROM support_policies WHERE slug = $1`, [slug]);
  return res.rows[0];
}

async function upsertPolicy({ slug, title, content, isPublished = true }) {
  const res = await db.query(
    `INSERT INTO support_policies (slug, title, content, is_published)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (slug) DO UPDATE
     SET title = EXCLUDED.title, content = EXCLUDED.content, is_published = EXCLUDED.is_published, updated_at = NOW()
     RETURNING *`,
    [slug, title, content, isPublished]
  );
  return res.rows[0];
}

// ── ACCOUNT REQUESTS ─────────────────────────────────────────────────────────

async function createAccountRequest({ userId, requestType, details = {}, reason }) {
  const requestNumber = await generateRequestNumber();
  const res = await db.query(
    `INSERT INTO account_requests (request_number, user_id, request_type, details, reason)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [requestNumber, userId, requestType, JSON.stringify(details), reason || null]
  );
  return res.rows[0];
}

async function listAccountRequests({ status, page = 1, limit = 20 } = {}) {
  const params = [];
  const where = [];

  if (status && status !== 'All') {
    params.push(status);
    where.push(`ar.status = $${params.length}`);
  }

  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const count = await db.query(
    `SELECT COUNT(*) FROM account_requests ar ${clause}`,
    params
  );

  params.push(limit, (page - 1) * limit);
  const res = await db.query(
    `SELECT ar.*, u.name as user_name, u.email as user_email, u.phone as user_phone
     FROM account_requests ar
     LEFT JOIN users u ON ar.user_id = u.id
     ${clause}
     ORDER BY ar.created_at DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  return paged(res.rows, count.rows[0].count, page, limit);
}

async function updateAccountRequestStatus({ requestId, status, adminNotes }) {
  const res = await db.query(
    `UPDATE account_requests
     SET status = $1, admin_notes = $2, updated_at = NOW()
     WHERE id = $3
     RETURNING *`,
    [status, adminNotes || null, requestId]
  );
  return res.rows[0];
}

module.exports = {
  createTicket,
  listUserTickets,
  listAdminTickets,
  getTicketDetails,
  addTicketMessage,
  updateTicketStatus,
  assignTicketAdmin,
  getSupportAnalytics,
  createProfessionalReport,
  listProfessionalReports,
  updateProfessionalReportStatus,
  listCategories,
  listFaqs,
  createFaq,
  updateFaq,
  deleteFaq,
  listPolicies,
  getPolicyBySlug,
  upsertPolicy,
  createAccountRequest,
  listAccountRequests,
  updateAccountRequestStatus,
};
