const workerModel = require("../models/worker.model");
const locationModel = require("../models/location.model");
const geocoder = require("../utils/geocoder");

async function findNearbyWorkers(req, res) {
  try {
    const { lat, lng, service_type, radius } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ success: false, message: "Latitude and Longitude are required" });
    }

    const radiusKm = radius ? parseFloat(radius) : 10;
    const workers = await workerModel.findNearbyWorkers(parseFloat(lat), parseFloat(lng), radiusKm, service_type);
    
    res.json({ success: true, count: workers.length, data: workers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

async function findWorkersByPincode(req, res) {
  try {
    const { pincode, service_type, radius } = req.query;
    
    if (!pincode) {
      return res.status(400).json({ success: false, message: "Pincode is required" });
    }

    // Find pincode in db
    let pinData = await locationModel.getPincodeByCode(pincode);
    
    // If not found in DB, try to geocode it and save it
    if (!pinData || !pinData.lat || !pinData.lng) {
      const geoResult = await geocoder.geocodeAddress(pincode);
      
      if (geoResult) {
        // Save to database for future use
        pinData = await locationModel.createPincode({
          code: pincode,
          lat: geoResult.lat,
          lng: geoResult.lng,
          status: 'active'
        });
      } else {
        return res.status(404).json({ success: false, message: "Pincode not found or lacks coordinates" });
      }
    }

    const radiusKm = radius ? parseFloat(radius) : 10;
    const workers = await workerModel.findNearbyWorkers(parseFloat(pinData.lat), parseFloat(pinData.lng), radiusKm, service_type);
    
    res.json({ success: true, count: workers.length, data: workers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  findNearbyWorkers,
  findWorkersByPincode,
};
