const locationModel = require("../models/location.model");

async function createZone(req, res) {
  try {
    const zone = await locationModel.createZone(req.body);
    res.status(201).json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function getZones(req, res) {
  try {
    const zones = await locationModel.getZones();
    res.json({ success: true, data: zones });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function updateZone(req, res) {
  try {
    const zone = await locationModel.updateZone(req.params.id, req.body);
    if (!zone) return res.status(404).json({ success: false, message: "Zone not found" });
    res.json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function deleteZone(req, res) {
  try {
    const zone = await locationModel.deleteZone(req.params.id);
    if (!zone) return res.status(404).json({ success: false, message: "Zone not found" });
    res.json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function updateZoneStatus(req, res) {
  try {
    const zone = await locationModel.updateZoneStatus(req.params.id, req.body.status);
    if (!zone) return res.status(404).json({ success: false, message: "Zone not found" });
    res.json({ success: true, data: zone });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function createPincode(req, res) {
  try {
    const pincode = await locationModel.createPincode(req.body);
    res.status(201).json({ success: true, data: pincode });
  } catch (error) {
    if (error.code === '23505') { // Unique constraint violation
      return res.status(400).json({ success: false, message: "Pincode already exists" });
    }
    res.status(500).json({ success: false, message: error.message });
  }
}

async function getPincodes(req, res) {
  try {
    const pincodes = await locationModel.getPincodes();
    res.json({ success: true, data: pincodes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function deletePincode(req, res) {
  try {
    const pincode = await locationModel.deletePincode(req.params.id);
    if (!pincode) return res.status(404).json({ success: false, message: "Pincode not found" });
    res.json({ success: true, data: pincode });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function getWorkerLiveLocation(req, res) {
  try {
    const worker = await locationModel.getWorkerLiveLocation(req.params.workerId);
    if (!worker) return res.status(404).json({ success: false, message: "Worker not found" });
    res.json({ success: true, data: worker });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  createZone,
  getZones,
  updateZone,
  deleteZone,
  updateZoneStatus,
  createPincode,
  getPincodes,
  deletePincode,
  getWorkerLiveLocation,
};
