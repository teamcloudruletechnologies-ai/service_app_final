const userAddressModel = require("../models/user-address.model");
const { success, error } = require("../utils/response");

function getUserId(req) {
  return req.auth ? req.auth.id : (req.user ? req.user.id : null);
}

async function listMyAddresses(req, res, next) {
  try {
    const userId = getUserId(req);
    const addresses = await userAddressModel.findByUserId(userId);
    return success(res, "Saved addresses retrieved successfully", addresses);
  } catch (err) {
    return next(err);
  }
}

async function getAddressById(req, res, next) {
  try {
    const userId = getUserId(req);
    const address = await userAddressModel.findById(req.params.id, userId);
    if (!address) {
      return error(res, "Address not found", 404);
    }
    return success(res, "Address retrieved successfully", address);
  } catch (err) {
    return next(err);
  }
}

async function createAddress(req, res, next) {
  try {
    const userId = getUserId(req);
    const address = await userAddressModel.create(userId, req.body);
    return success(res, "Address created successfully", address, 201);
  } catch (err) {
    return next(err);
  }
}

async function updateAddress(req, res, next) {
  try {
    const userId = getUserId(req);
    const existing = await userAddressModel.findById(req.params.id, userId);
    if (!existing) {
      return error(res, "Address not found", 404);
    }
    const updated = await userAddressModel.update(req.params.id, userId, req.body);
    return success(res, "Address updated successfully", updated);
  } catch (err) {
    return next(err);
  }
}

async function deleteAddress(req, res, next) {
  try {
    const userId = getUserId(req);
    const deleted = await userAddressModel.remove(req.params.id, userId);
    if (!deleted) {
      return error(res, "Address not found", 404);
    }
    return success(res, "Address deleted successfully", null);
  } catch (err) {
    return next(err);
  }
}

async function setDefaultAddress(req, res, next) {
  try {
    const userId = getUserId(req);
    const updated = await userAddressModel.setDefault(req.params.id, userId);
    if (!updated) {
      return error(res, "Address not found", 404);
    }
    return success(res, "Default address set successfully", updated);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listMyAddresses,
  getAddressById,
  createAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress,
};
