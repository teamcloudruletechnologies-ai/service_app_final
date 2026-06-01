const Worker = require("../models/worker.model");
const { hashPassword } = require("../utils/hash");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listWorkers(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Worker.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
      kycStatus: req.query.kycStatus,
    });
    return success(res, "Workers fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getWorker(req, res, next) {
  try {
    const worker = await Worker.findById(req.params.id);
    if (!worker) return error(res, "Worker not found", 404);
    return success(res, "Worker fetched", worker);
  } catch (err) {
    return next(err);
  }
}

async function createWorker(req, res, next) {
  try {
    const passwordHash = req.body.password ? await hashPassword(req.body.password) : null;
    const worker = await Worker.create({ ...req.body, passwordHash });
    return success(res, "Worker created", worker, 201);
  } catch (err) {
    if (err.code === "23505") return error(res, "Worker email or phone already exists", 409);
    return next(err);
  }
}

async function updateWorker(req, res, next) {
  try {
    const worker = await Worker.update(req.params.id, req.body);
    if (!worker) return error(res, "Worker not found", 404);
    return success(res, "Worker updated", worker);
  } catch (err) {
    if (err.code === "23505") return error(res, "Worker email or phone already exists", 409);
    return next(err);
  }
}

async function deleteWorker(req, res, next) {
  try {
    const worker = await Worker.remove(req.params.id);
    if (!worker) return error(res, "Worker not found", 404);
    return success(res, "Worker deleted", worker);
  } catch (err) {
    return next(err);
  }
}

module.exports = { listWorkers, getWorker, createWorker, updateWorker, deleteWorker };
