const Admin = require("../models/admin.model");
const User = require("../models/user.model");
const Worker = require("../models/worker.model");
const { hashPassword, comparePassword } = require("../utils/hash");
const { signToken } = require("../utils/token");
const { success, error } = require("../utils/response");
const roles = require("../constants/roles");

const modelByRole = {
  [roles.ADMIN]: Admin,
  [roles.USER]: User,
  [roles.WORKER]: Worker,
};

function authPayload(account, role) {
  return {
    id: account.id,
    role,
    name: account.name,
    email: account.email,
    phone: account.phone,
    status: account.status,
  };
}

async function registerAdmin(req, res, next) {
  try {
    const passwordHash = await hashPassword(req.body.password);
    const admin = await Admin.create({ ...req.body, passwordHash, role: roles.ADMIN });
    return success(res, "Admin registered", admin, 201);
  } catch (err) {
    if (err.code === "23505") return error(res, "Admin email already exists", 409);
    return next(err);
  }
}

async function registerUser(req, res, next) {
  try {
    const passwordHash = req.body.password ? await hashPassword(req.body.password) : null;
    const user = await User.create({ ...req.body, passwordHash });
    
    // Log registration
    await User.logActivity(user.id, "register", "User self-registered account");
    
    return success(res, "User registered", user, 201);
  } catch (err) {
    if (err.code === "23505") return error(res, "User email or phone already exists", 409);
    return next(err);
  }
}

async function registerWorker(req, res, next) {
  try {
    const passwordHash = req.body.password ? await hashPassword(req.body.password) : null;
    const worker = await Worker.create({ ...req.body, passwordHash });
    return success(res, "Worker registered", worker, 201);
  } catch (err) {
    if (err.code === "23505") return error(res, "Worker email or phone already exists", 409);
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { login: loginId, password, role } = req.body;
    const model = modelByRole[role];

    if (!model) return error(res, "Invalid role", 400);

    const account = await model.findByEmailOrPhone?.(loginId) || await model.findByEmail?.(loginId);
    if (!account || !account.password_hash) return error(res, "Invalid login credentials", 401);

    const matches = await comparePassword(password, account.password_hash);
    if (!matches) return error(res, "Invalid login credentials", 401);
    if (account.status && account.status !== "active") return error(res, "Account is not active", 403);

    const payload = authPayload(account, role);
    if (role === roles.USER) {
      await User.logActivity(account.id, "login", "User logged in successfully");
    }

    return success(res, "Login successful", {
      token: signToken({ id: account.id, role }),
      account: payload,
    });
  } catch (err) {
    return next(err);
  }
}

async function me(req, res, next) {
  try {
    const model = modelByRole[req.auth.role];
    const account = await model.findById(req.auth.id);
    if (!account) return error(res, "Account not found", 404);

    return success(res, "Profile fetched", authPayload(account, req.auth.role));
  } catch (err) {
    return next(err);
  }
}

module.exports = { registerAdmin, registerUser, registerWorker, login, me };
