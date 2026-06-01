const User = require("../models/user.model");
const { hashPassword } = require("../utils/hash");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listUsers(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await User.list({ ...paging, search: req.query.search, status: req.query.status });
    return success(res, "Users fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getUser(req, res, next) {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return error(res, "User not found", 404);
    return success(res, "User fetched", user);
  } catch (err) {
    return next(err);
  }
}

async function createUser(req, res, next) {
  try {
    const passwordHash = req.body.password ? await hashPassword(req.body.password) : null;
    const user = await User.create({ ...req.body, passwordHash });
    return success(res, "User created", user, 201);
  } catch (err) {
    if (err.code === "23505") return error(res, "User email or phone already exists", 409);
    return next(err);
  }
}

async function updateUser(req, res, next) {
  try {
    const user = await User.update(req.params.id, req.body);
    if (!user) return error(res, "User not found", 404);
    return success(res, "User updated", user);
  } catch (err) {
    if (err.code === "23505") return error(res, "User email or phone already exists", 409);
    return next(err);
  }
}

async function deleteUser(req, res, next) {
  try {
    const user = await User.remove(req.params.id);
    if (!user) return error(res, "User not found", 404);
    return success(res, "User deleted", user);
  } catch (err) {
    return next(err);
  }
}

module.exports = { listUsers, getUser, createUser, updateUser, deleteUser };
