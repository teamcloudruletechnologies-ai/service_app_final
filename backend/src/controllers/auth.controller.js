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

async function authPayload(account, role) {
  const payload = {
    id: account.id,
    role: account.role || role,
    name: account.name,
    email: account.email,
    phone: account.phone,
    state: account.state,
    address: account.address,
    status: account.status,
    permissions: account.permissions || [],
  };
  if (role === "worker") {
    payload.kyc_status = account.kyc_status;
    payload.service_type = account.service_type;
    payload.experience_years = account.experience_years;
    payload.city = account.city;
    payload.pincode = account.pincode;

    try {
      const db = require("../config/db");
      const settlementStatsResult = await db.query(
        `SELECT COALESCE(SUM(net_payout), 0)::float AS total_settled
         FROM worker_settlements
         WHERE worker_id = $1 AND status = 'paid'`,
        [account.id]
      );
      const totalPaid = settlementStatsResult.rows[0]?.total_settled || 0;

      const totalJobsResult = await db.query(
        `SELECT COUNT(*) FILTER (WHERE status = 'completed')::int AS completed_jobs
         FROM bookings
         WHERE worker_id = $1`,
        [account.id]
      );
      const completedCount = totalJobsResult.rows[0]?.completed_jobs || 0;

      payload.wallet_balance = totalPaid;
      payload.walletBalance = totalPaid;
      payload.total_earnings = totalPaid;
      payload.earnings = totalPaid;
      payload.today_earnings = totalPaid;
      payload.todayEarnings = totalPaid;
      payload.jobs_completed = completedCount;
      payload.today_completed = completedCount;
      payload.completed_jobs = completedCount;
      payload.completedJobs = completedCount;
    } catch (_) {}
  }
  return payload;
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

    const payload = await authPayload(account, role);
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

    const payload = await authPayload(account, req.auth.role);
    return success(res, "Profile fetched", payload);
  } catch (err) {
    return next(err);
  }
}

async function phoneLogin(req, res, next) {
  try {
    const { phone, role } = req.body;
    const model = modelByRole[role];

    if (!model) return error(res, "Invalid role", 400);

    let account = await model.findByEmailOrPhone?.(phone);
    let isNew = false;

    if (!account) {
      // Auto-create minimal account — name/details filled in onboarding step
      if (role === roles.WORKER) {
        account = await model.create({
          name: "",          // filled during onboarding
          phone,
          passwordHash: null,
          serviceType: null,
          experienceYears: 0,
          city: null,
          state: null,
          address: null,
          status: "pending",
        });
      } else if (role === roles.USER) {
        account = await model.create({
          name: "",          // filled during onboarding
          phone,
          passwordHash: null,
          status: "active",
        });
        await model.logActivity?.(account.id, "register", "User auto-created via phone login");
      } else {
        return error(res, "Cannot auto-register this role", 400);
      }
      isNew = true;
    }

    if (account.status && !["active", "pending"].includes(account.status)) {
      return error(res, "Account is suspended. Contact support.", 403);
    }

    const payload = await authPayload(account, role);
    if (role === roles.USER && !isNew) {
      await User.logActivity(account.id, "login", "User logged in via phone/OTP");
    }

    if (!isNew && account.id) {
      try {
        const fcmService = require("../utils/fcm.service");
        if (role === roles.USER) {
          fcmService.sendToUser(account.id, {
            title: "⚠️ Security Alert: New Login Attempt",
            body: "Someone is attempting to log in to your account from a new device.",
            data: { type: "login_alert" }
          });
        } else if (role === roles.WORKER) {
          fcmService.sendToWorker(account.id, {
            title: "⚠️ Security Alert: New Login Attempt",
            body: "Someone is attempting to log in to your account from a new device.",
            data: { type: "login_alert" }
          });
        }
      } catch (_) {}
    }

    return success(res, isNew ? "Account created" : "Login successful", {
      token: signToken({ id: account.id, role }),
      account: payload,
      is_new: isNew,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { registerAdmin, registerUser, registerWorker, login, me, phoneLogin };

