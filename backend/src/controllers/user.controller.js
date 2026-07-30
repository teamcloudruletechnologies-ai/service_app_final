const User = require("../models/user.model");
const { hashPassword } = require("../utils/hash");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listUsers(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await User.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
      sortBy: req.query.sortBy,
      sortOrder: req.query.sortOrder,
      created_after: req.query.created_after,
      created_before: req.query.created_before,
    });
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

    // Log update
    await User.logActivity(req.params.id, "update_profile", `Profile updated by Admin ID ${req.auth.id}`);

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

async function blockUser(req, res, next) {
  try {
    const user = await User.update(req.params.id, { status: "suspended" });
    if (!user) return error(res, "User not found", 404);

    // Log block
    await User.logActivity(req.params.id, "block", `Account suspended by Admin ID ${req.auth.id}`);

    return success(res, "User account blocked successfully", user);
  } catch (err) {
    return next(err);
  }
}

async function unblockUser(req, res, next) {
  try {
    const user = await User.update(req.params.id, { status: "active" });
    if (!user) return error(res, "User not found", 404);

    // Log unblock
    await User.logActivity(req.params.id, "unblock", `Account activated by Admin ID ${req.auth.id}`);

    return success(res, "User account unblocked successfully", user);
  } catch (err) {
    return next(err);
  }
}

async function getUserBookings(req, res, next) {
  try {
    const bookings = await User.getBookings(req.params.id);
    return success(res, "User bookings fetched", bookings);
  } catch (err) {
    return next(err);
  }
}

async function getUserActivityLogs(req, res, next) {
  try {
    const userId = req.params.id;
    const user = await User.findById(userId);
    if (!user) return error(res, "User not found", 404);

    const logs = await User.getActivityLogs(userId);
    return success(res, "User activity logs fetched", logs);
  } catch (err) {
    return next(err);
  }
}

async function downloadUserActivityLogs(req, res, next) {
  try {
    const userId = req.params.id;
    const user = await User.findById(userId);
    if (!user) return error(res, "User not found", 404);

    const logs = await User.getActivityLogs(userId);

    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", `attachment; filename=user_${userId}_activity_logs.csv`);

    let csvContent = "ID,Action,Details,Timestamp\n";
    for (const log of logs) {
      const escapedDetails = log.details ? log.details.replace(/"/g, '""') : "";
      const timestamp = log.created_at ? new Date(log.created_at).toISOString() : "";
      csvContent += `${log.id},"${log.action}","${escapedDetails}","${timestamp}"\n`;
    }

    return res.status(200).send(csvContent);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listUsers,
  getUser,
  createUser,
  updateUser,
  deleteUser,
  blockUser,
  unblockUser,
  getUserBookings,
  getUserActivityLogs,
  downloadUserActivityLogs,
};
