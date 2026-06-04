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

module.exports = { listInvoices, getInvoice, getInvoiceReports, getInvoicePayouts };
