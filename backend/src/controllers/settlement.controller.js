const Settlement = require("../models/settlement.model");
const fcmService = require("../utils/fcm.service");
const { success, error } = require("../utils/response");
const { getPagination } = require("../utils/pagination");

async function getUnsettled(req, res, next) {
  try {
    const days = parseInt(req.query.days) || 3;
    const minAmount = parseFloat(req.query.minAmount) || 500;
    const { startDate, endDate } = req.query;

    const data = await Settlement.listUnsettled({ days, startDate, endDate, minAmount });
    return success(res, "Unsettled worker earnings fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function createPayout(req, res, next) {
  try {
    const { worker_id, period_start, period_end, total_jobs, gross_amount, platform_fee, net_payout, payment_method, transaction_ref, notes } = req.body;

    if (!worker_id) {
      return error(res, "Worker ID is required", 400);
    }

    const settlement = await Settlement.createSettlement({
      workerId: worker_id,
      periodStart: period_start,
      periodEnd: period_end,
      totalJobs: total_jobs,
      grossAmount: gross_amount,
      platformFee: platform_fee,
      netPayout: net_payout,
      paymentMethod: payment_method || 'razorpay',
      transactionRef: transaction_ref || `TXN-${Date.now()}`,
      notes: notes || 'Manual/Razorpay Payout Settle'
    });

    // Send FCM Notification to Worker
    try {
      fcmService.sendToWorker(worker_id, {
        title: "💳 Earnings Settled!",
        body: `Your payout of ₹${net_payout} has been processed via ${payment_method || 'Razorpay'}. Ref: ${settlement.transaction_ref}`,
        data: { type: "settlement_paid", settlementId: settlement.id }
      });
    } catch (_) {}

    return success(res, "Worker settlement processed successfully", settlement, 201);
  } catch (err) {
    return next(err);
  }
}

async function getHistory(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const filter = {
      ...paging,
      workerId: req.query.worker_id,
      status: req.query.status
    };
    const data = await Settlement.listHistory(filter);
    return success(res, "Settlement history fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getSummary(req, res, next) {
  try {
    const data = await Settlement.getFinanceSummary();
    return success(res, "Finance summary fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getRevenueBreakdown(req, res, next) {
  try {
    const data = await Settlement.getCategoryServiceRevenueBreakdown();
    return success(res, "Category and Service revenue breakdown fetched", data);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getUnsettled,
  createPayout,
  getHistory,
  getSummary,
  getRevenueBreakdown
};
