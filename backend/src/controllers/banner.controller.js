const Banner = require("../models/banner.model");
const { saveUpload } = require("../utils/fileUpload");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listBanners(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Banner.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
    });
    return success(res, "Banners fetched successfully", data);
  } catch (err) {
    return next(err);
  }
}

async function createBanner(req, res, next) {
  try {
    if (!req.file) {
      return error(res, "Banner image is required", 400);
    }

    // Convert file buffer to Base64 data URL
    const base64Data = req.file.buffer.toString("base64");
    const image_url = `data:${req.file.mimetype};base64,${base64Data}`;

    const banner = await Banner.create({
      title: req.body.title,
      image_url,
      link_url: req.body.link_url,
      status: req.body.status,
    });

    return success(res, "Banner created successfully", banner, 201);
  } catch (err) {
    return next(err);
  }
}

async function updateBanner(req, res, next) {
  try {
    const bannerId = req.params.id;
    const bannerExists = await Banner.findById(bannerId);
    if (!bannerExists) return error(res, "Banner not found", 404);

    const updateData = { ...req.body };

    // If new image is uploaded, convert it to Base64 data URL
    if (req.file) {
      const base64Data = req.file.buffer.toString("base64");
      updateData.image_url = `data:${req.file.mimetype};base64,${base64Data}`;
    }

    const banner = await Banner.update(bannerId, updateData);
    return success(res, "Banner updated successfully", banner);
  } catch (err) {
    return next(err);
  }
}

async function deleteBanner(req, res, next) {
  try {
    const banner = await Banner.remove(req.params.id);
    if (!banner) return error(res, "Banner not found", 404);
    return success(res, "Banner deleted successfully", banner);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listBanners,
  createBanner,
  updateBanner,
  deleteBanner,
};
