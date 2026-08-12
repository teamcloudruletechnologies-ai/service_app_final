const Invoice = require("../models/invoice.model");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listInvoices(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Invoice.list({
      ...paging,
      status: req.query.status,
      userId: req.query.userId,
      workerId: req.query.workerId,
    });
    return success(res, "Invoices fetched", data);
  } catch (err) {
    return next(err);
  }
}




async function getInvoice(req, res, next) {
  try {
    const invoice = await Invoice.findById(req.params.id);
    if (!invoice) return error(res, "Invoice not found", 404);
    return success(res, "Invoice fetched", invoice);
  } catch (err) {
    return next(err);
  }
}

async function getInvoiceReports(req, res, next) {
  try {
    const data = await Invoice.reports();
    return success(res, "Invoice reports fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getInvoicePayouts(req, res, next) {
  try {
    const data = await Invoice.payouts();
    return success(res, "Invoice payouts fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function listPayments(req, res, next) {
  try {
    const db = require("../config/db");
    const result = await db.query(
      `SELECT p.*, u.name as user_name, b.status as booking_status, s.name as service_name
       FROM payments p
       LEFT JOIN users u ON u.id = p.user_id
       LEFT JOIN bookings b ON b.id = p.booking_id
       ORDER BY p.created_at DESC`
    );
    return success(res, "Payments fetched successfully", result.rows);
  } catch (err) {
    return next(err);
  }
}
async function updateInvoiceStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const db = require("../config/db");
    const fcmService = require("../utils/fcm.service");

    const result = await db.query(
      `UPDATE invoices SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );
    if (!result.rows[0]) return error(res, "Invoice not found", 404);

    const inv = result.rows[0];

    if (status === 'approved' || status === 'pending') {
      fcmService.sendToUser(inv.user_id, {
        title: "🧾 Invoice Approved!",
        body: `Admin approved your technician bill of ₹${inv.amount}. Tap to view & Pay Now.`,
        data: { bookingId: inv.booking_id, invoiceId: inv.id, amount: inv.amount, type: "invoice_approved" }
      });
    }

    return success(res, `Invoice status updated to ${status}`, inv);
  } catch (err) {
    return next(err);
  }
}

module.exports = { listInvoices, getInvoice, getInvoiceReports, getInvoicePayouts, listPayments, updateInvoiceStatus };
