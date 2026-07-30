const env = require("../config/env");

/**
 * Helper client to perform calculation calls from Node.js Express to FastAPI Calculation Microservice
 */
class CalculationClient {
  static get baseUrl() {
    return env.fastapiServiceUrl || "http://localhost:8000";
  }

  static async _request(endpoint, data) {
    const url = `${this.baseUrl}/api/v1/calculate${endpoint}`;
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(`FastAPI Calculation Error (${response.status}): ${errText}`);
      }

      return await response.json();
    } catch (error) {
      console.error(`[CalculationClient Error] Failed to call ${url}:`, error.message);
      throw error;
    }
  }

  static async calculateDistance(origin, destination) {
    return this._request("/distance", { origin, destination });
  }

  static async calculateFare(params) {
    return this._request("/fare", params);
  }

  static async calculateETA(params) {
    return this._request("/eta", params);
  }

  static async calculateServiceCharge(params) {
    return this._request("/service-charge", params);
  }

  static async calculateTax(params) {
    return this._request("/tax", params);
  }

  static async calculateDiscount(params) {
    return this._request("/discount", params);
  }

  static async calculateCoupon(couponCode, cartTotal) {
    return this._request("/coupon", { coupon_code: couponCode, cart_total: cartTotal });
  }

  static async calculatePriceBreakdown(payload) {
    return this._request("/price-breakdown", payload);
  }
}

module.exports = CalculationClient;
