const Category = require("../models/category.model");
const Service = require("../models/service.model");
const { saveUpload } = require("../utils/fileUpload");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

// ==========================================
// CATEGORIES CONTROLLERS
// ==========================================

async function listCategories(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Category.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
    });
    return success(res, "Categories fetched successfully", data);
  } catch (err) {
    return next(err);
  }
}

async function createCategory(req, res, next) {
  try {
    // Check if duplicate name exists
    const existing = await Category.findByName(req.body.name);
    if (existing) return error(res, "Category with this name already exists", 409);

    // Save icon file if uploaded
    let icon_url = null;
    if (req.file) {
      icon_url = await saveUpload(req.file, "categories");
    }

    const category = await Category.create({
      ...req.body,
      icon_url,
    });
    return success(res, "Category created successfully", category, 201);
  } catch (err) {
    return next(err);
  }
}

async function updateCategory(req, res, next) {
  try {
    const categoryId = req.params.id;
    const categoryExists = await Category.findById(categoryId);
    if (!categoryExists) return error(res, "Category not found", 404);

    if (req.body.name) {
      const existing = await Category.findByName(req.body.name);
      if (existing && existing.id !== parseInt(categoryId)) {
        return error(res, "Category with this name already exists", 409);
      }
    }

    // Save icon file if new one is uploaded
    const updateData = { ...req.body };
    if (req.file) {
      updateData.icon_url = await saveUpload(req.file, "categories");
    }

    const category = await Category.update(categoryId, updateData);
    return success(res, "Category updated successfully", category);
  } catch (err) {
    return next(err);
  }
}

async function deleteCategory(req, res, next) {
  try {
    const category = await Category.remove(req.params.id);
    if (!category) return error(res, "Category not found", 404);
    return success(res, "Category deleted successfully", category);
  } catch (err) {
    return next(err);
  }
}

// ==========================================
// SERVICES CONTROLLERS
// ==========================================

async function listServices(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Service.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
    });
    return success(res, "Services fetched successfully", data);
  } catch (err) {
    return next(err);
  }
}

async function createService(req, res, next) {
  try {
    // Check duplicate service name
    const existing = await Service.findByName(req.body.name);
    if (existing) return error(res, "Service with this name already exists", 409);

    // Save image file if uploaded
    let image_url = req.body.image || null;
    if (req.file) {
      image_url = await saveUpload(req.file, "services");
    }

    const service = await Service.create({
      name: req.body.name,
      description: req.body.description || null,
      image_url,
      status: req.body.status,
    });
    return success(res, "Service created successfully", service, 201);
  } catch (err) {
    return next(err);
  }
}

async function updateService(req, res, next) {
  try {
    const serviceId = req.params.id;
    const serviceExists = await Service.findById(serviceId);
    if (!serviceExists) return error(res, "Service not found", 404);

    if (req.body.name) {
      const existing = await Service.findByName(req.body.name);
      if (existing && existing.id !== parseInt(serviceId)) {
        return error(res, "Service with this name already exists", 409);
      }
    }

    // Build update data
    const updateData = {};
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.status !== undefined) updateData.status = req.body.status;
    if (req.body.image !== undefined) updateData.image_url = req.body.image;
    if (req.file) {
      updateData.image_url = await saveUpload(req.file, "services");
    }

    const service = await Service.update(serviceId, updateData);
    return success(res, "Service updated successfully", service);
  } catch (err) {
    return next(err);
  }
}

async function deleteService(req, res, next) {
  try {
    const service = await Service.remove(req.params.id);
    if (!service) return error(res, "Service not found", 404);
    return success(res, "Service deleted successfully", service);
  } catch (err) {
    return next(err);
  }
}

async function updateServiceStatus(req, res, next) {
  try {
    const service = await Service.update(req.params.id, { status: req.body.status });
    if (!service) return error(res, "Service not found", 404);
    return success(res, "Service status updated successfully", service);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  listServices,
  createService,
  updateService,
  deleteService,
  updateServiceStatus,
};
