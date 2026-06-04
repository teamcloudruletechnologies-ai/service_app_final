const subAdminModel = require("../models/subAdmin.model");
const Admin = require("../models/admin.model");
const { hashPassword } = require("../utils/hash");
const { success, error } = require("../utils/response");

async function createSubAdmin(req, res, next) {
  try {
    const { name, email, password, status, permissions } = req.body;

    // Check if email already exists
    const existing = await Admin.findByEmail(email);
    if (existing) {
      return error(res, "Admin email already exists", 499 || 409); // using 409 Conflict
    }

    const passwordHash = await hashPassword(password);
    const subAdmin = await subAdminModel.createSubAdmin({
      name,
      email,
      passwordHash,
      status,
      permissions,
    });

    return success(res, "Sub-Admin created successfully", subAdmin, 201);
  } catch (err) {
    if (err.code === "23505") {
      return error(res, "Admin email already exists", 409);
    }
    return next(err);
  }
}

async function listSubAdmins(req, res, next) {
  try {
    const list = await subAdminModel.listSubAdmins();
    return success(res, "Sub-Admins list retrieved successfully", list);
  } catch (err) {
    return next(err);
  }
}

async function getSubAdmin(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const subAdmin = await subAdminModel.getSubAdminById(id);

    if (!subAdmin) {
      return error(res, "Sub-Admin not found", 404);
    }

    return success(res, "Sub-Admin details retrieved successfully", subAdmin);
  } catch (err) {
    return next(err);
  }
}

async function updateSubAdmin(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const { name, email, password, status, permissions } = req.body;

    // Check if sub-admin exists
    const existingSubAdmin = await subAdminModel.getSubAdminById(id);
    if (!existingSubAdmin) {
      return error(res, "Sub-Admin not found", 404);
    }

    // Check email uniqueness if email is changing
    if (email && email.toLowerCase() !== existingSubAdmin.email.toLowerCase()) {
      const existingEmail = await Admin.findByEmail(email);
      if (existingEmail) {
        return error(res, "Email is already taken by another admin", 409);
      }
    }

    let passwordHash = null;
    if (password) {
      passwordHash = await hashPassword(password);
    }

    const updated = await subAdminModel.updateSubAdmin(id, {
      name: name || existingSubAdmin.name,
      email: email || existingSubAdmin.email,
      passwordHash,
      status: status || existingSubAdmin.status,
      permissions,
    });

    return success(res, "Sub-Admin updated successfully", updated);
  } catch (err) {
    if (err.code === "23505") {
      return error(res, "Email is already taken by another admin", 409);
    }
    return next(err);
  }
}

async function deleteSubAdmin(req, res, next) {
  try {
    const id = parseInt(req.params.id, 10);
    const deleted = await subAdminModel.deleteSubAdmin(id);

    if (!deleted) {
      return error(res, "Sub-Admin not found", 404);
    }

    return success(res, "Sub-Admin deleted successfully");
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createSubAdmin,
  listSubAdmins,
  getSubAdmin,
  updateSubAdmin,
  deleteSubAdmin,
};
