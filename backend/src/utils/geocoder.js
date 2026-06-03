const winston = require("winston");

async function geocodeAddress(address) {
  try {
    // OpenStreetMap (Nominatim) requires NO API key.
    // It requires a User-Agent header to identify the application.
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)}&format=json&limit=1`;
    
    const response = await fetch(url, {
      headers: {
        "User-Agent": "ServiceAppWorkerDiscovery/1.0"
      }
    });
    const data = await response.json();

    if (data && data.length > 0) {
      return {
        lat: parseFloat(data[0].lat),
        lng: parseFloat(data[0].lon)
      };
    } else {
      winston.warn(`Geocoding found no results for address: ${address}`);
      return null;
    }
  } catch (error) {
    winston.error(`Geocoding error: ${error.message}`);
    return null;
  }
}

module.exports = {
  geocodeAddress
};
