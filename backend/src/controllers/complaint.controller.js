const Complaint = require("../models/complaint.model");
const { getPagination } = require("../utils/pagination");
const { success, error } = require("../utils/response");

async function listComplaints(req, res, next) {
  try {
    const paging = getPagination(req.query);
    const data = await Complaint.list({
      ...paging,
      search: req.query.search,
      status: req.query.status,
    });
    return success(res, "Complaints fetched", data);
  } catch (err) {
    return next(err);
  }
}

async function getComplaint(req, res, next) {
  try {
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return error(res, "Complaint not found", 404);
    return success(res, "Complaint fetched", complaint);
  } catch (err) {
    return next(err);
  }
}

async function updateComplaintStatus(req, res, next) {
  try {
    const { status } = req.body;
    const complaint = await Complaint.updateStatus(req.params.id, status);
    if (!complaint) return error(res, "Complaint not found", 404);
    return success(res, "Complaint status updated", complaint);
  } catch (err) {
    return next(err);
  }
}

async function addComplaintNote(req, res, next) {
  try {
    const { note } = req.body;
    const complaint = await Complaint.addNote(req.params.id, note);
    if (!complaint) return error(res, "Complaint not found", 404);
    return success(res, "Note added to complaint", complaint);
  } catch (err) {
    return next(err);
  }
}

module.exports = { listComplaints, getComplaint, updateComplaintStatus, addComplaintNote };
