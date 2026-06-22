const Kyc = require("../models/kyc.model");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function submitKyc(req, res, next) {
  try {
    const workerId = req.auth.role === "worker" ? req.auth.id : req.body.workerId;
    const kyc = await Kyc.submit({ ...req.body, workerId });
    return success(res, "KYC submitted", kyc, 201);
  } catch (err) {
    return next(err);
  }
}

async function listKyc(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const workerId = req.auth.role === "worker" ? req.auth.id : req.query.workerId;
    const data = await Kyc.list({
      ...paging,
      status: req.query.status,
      workerId,
    });
    return success(res, "KYC records fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getKyc(req, res, next) {
  try {
    const kyc = await Kyc.findById(req.params.id);
    if (!kyc) return error(res, "KYC record not found", 404);
    return success(res, "KYC record fetched", kyc);
  } catch (err) {
    return next(err);
  }
}

async function reviewKyc(req, res, next) {
  try {
    const kyc = await Kyc.review(req.params.id, {
      aadhaarStatus: req.body.aadhaarStatus,
      panStatus: req.body.panStatus,
      bankPassbookStatus: req.body.bankPassbookStatus,
      selfieStatus: req.body.selfieStatus,
      rejectionReason: req.body.rejectionReason,
      reviewedBy: req.auth.id,
    });
    if (!kyc) return error(res, "KYC record not found", 404);
    return success(res, "KYC reviewed", kyc);
  } catch (err) {
    return next(err);
  }
}

module.exports = { submitKyc, listKyc, getKyc, reviewKyc };
