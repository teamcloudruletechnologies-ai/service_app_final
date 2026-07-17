import axios from "axios";

const getBaseURL = () => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get("api") === "local") {
    localStorage.setItem("use_local_api", "true");
    return "http://localhost:5000/api";
  } else if (urlParams.get("api") === "live") {
    localStorage.removeItem("use_local_api");
    return "https://service-app-hsu6.onrender.com/api";
  }

  if (localStorage.getItem("use_local_api") === "true") {
    return "http://localhost:5000/api";
  }
  return "https://service-app-hsu6.onrender.com/api";
};

const api = axios.create({
  baseURL: getBaseURL(),
  timeout: 15000,
  headers: {
    "Content-Type": "application/json",
  },
});




// Request interceptor — attach token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("admin_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor — handle 401
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("admin_token");
      window.location.href = "/login";
    }
    return Promise.reject(error.response?.data || error);
  }
);

// ─── Auth ────────────────────────────────────────────────────
export const authAPI = {
  login: (email, password) => api.post("/auth/login", { login: email, password, role: "admin" }),
  me: () => api.get("/auth/me"),
};

// ─── Dashboard ───────────────────────────────────────────────
export const dashboardAPI = {
  getStats: () => api.get("/dashboard/overview"), // ✅ Fixed: was /dashboard/stats
};

// ─── Users ───────────────────────────────────────────────────
export const usersAPI = {
  getAll: (params) => api.get("/admin/users", { params }),
  getById: (id) => api.get(`/admin/users/${id}`),
  update: (id, data) => api.put(`/admin/users/${id}`, data),
  delete: (id) => api.delete(`/admin/users/${id}`),
  block: (id) => api.patch(`/admin/users/${id}/block`),
  unblock: (id) => api.patch(`/admin/users/${id}/unblock`),
  getBookings: (id) => api.get(`/admin/users/${id}/bookings`),
  getActivityLogs: (id) => api.get(`/admin/users/${id}/activity-logs`),
};

// ─── Workers ─────────────────────────────────────────────────
export const workersAPI = {
  getAll: (params) => api.get("/workers", { params }),
  getById: (id) => api.get(`/workers/${id}`),
  create: (data) => api.post("/workers", data),
  update: (id, data) => api.patch(`/workers/${id}`, data),
  delete: (id) => api.delete(`/workers/${id}`),
  activate: (id) => api.patch(`/workers/${id}/activate`),
  suspend: (id) => api.patch(`/workers/${id}/suspend`),
  getPerformance: (id) => api.get(`/workers/${id}/performance`),
};

// ─── KYC ─────────────────────────────────────────────────────
export const kycAPI = {
  getAll: (params) => api.get("/kyc", { params }),
  getById: (id) => api.get(`/kyc/${id}`),
  review: (id, data) => api.patch(`/kyc/${id}/review`, data),
};

// ─── Bookings ────────────────────────────────────────────────
export const bookingsAPI = {
  getAll: (params) => api.get("/admin/bookings", { params }),
  getById: (id) => api.get(`/admin/bookings/${id}`),
  updateStatus: (id, status) => api.patch(`/admin/bookings/${id}/status`, { status }),
  getAnalytics: () => api.get("/admin/bookings/analytics"),
};

// ─── Invoices ────────────────────────────────────────────────
export const invoicesAPI = {
  getAll: (params) => api.get("/admin/invoices", { params }),
  getById: (id) => api.get(`/admin/invoices/${id}`),
  getReports: () => api.get("/admin/invoices/reports"),
  getPayouts: () => api.get("/admin/invoices/payouts"),
  getPayments: () => api.get("/admin/invoices/payments"),
};

// ─── Reviews ─────────────────────────────────────────────────
export const reviewsAPI = {
  getAll: (params) => api.get("/admin/reviews", { params }),
};

// ─── Services ────────────────────────────────────────────────
export const servicesAPI = {
  getAll: () => api.get("/admin/services"),
  create: (data) => api.post("/admin/services", data),
  update: (id, data) => api.put(`/admin/services/${id}`, data),
  delete: (id) => api.delete(`/admin/services/${id}`),
  updateStatus: (id, status) => api.patch(`/admin/services/${id}/status`, { status }),
  getCategories: () => api.get("/admin/services/categories"),
};

// ─── Banners ─────────────────────────────────────────────────
export const bannersAPI = {
  getAll: (params) => api.get("/admin/banners", { params }),
  create: (formData) => api.post("/admin/banners", formData, {
    headers: { "Content-Type": "multipart/form-data" }
  }),
  update: (id, formData) => api.put(`/admin/banners/${id}`, formData, {
    headers: { "Content-Type": "multipart/form-data" }
  }),
  delete: (id) => api.delete(`/admin/banners/${id}`),
};

// ─── Complaints ──────────────────────────────────────────────
export const complaintsAPI = {
  getAll: (params) => api.get("/admin/complaints", { params }),
  getById: (id) => api.get(`/admin/complaints/${id}`),
  updateStatus: (id, status) => api.patch(`/admin/complaints/${id}/status`, { status }),
  addNotes: (id, notes) => api.post(`/admin/complaints/${id}/notes`, { note: notes }),
};

// ─── Locations ───────────────────────────────────────────────
export const locationsAPI = {
  getZones: () => api.get("/admin/locations/zones"),
  createZone: (data) => api.post("/admin/locations/zones", data),
  updateZone: (id, data) => api.put(`/admin/locations/zones/${id}`, data),
  updateZoneStatus: (id, status) => api.patch(`/admin/locations/zones/${id}/status`, { status }),
  deleteZone: (id) => api.delete(`/admin/locations/zones/${id}`),
  getPincodes: () => api.get("/admin/locations/pincodes"),
  createPincode: (data) => api.post("/admin/locations/pincodes", data),
  deletePincode: (id) => api.delete(`/admin/locations/pincodes/${id}`),
  getWorkerLiveLocation: (workerId) => api.get(`/admin/locations/worker-live/${workerId}`),
};

// ─── Roles & Permissions (Sub-Admins) ───────────────────────
export const rolesAPI = {
  getAll: () => api.get("/admin/sub-admins"),
  getById: (id) => api.get(`/admin/sub-admins/${id}`),
  create: (data) => api.post("/admin/sub-admins", data),
  update: (id, data) => api.patch(`/admin/sub-admins/${id}`, data),
  delete: (id) => api.delete(`/admin/sub-admins/${id}`),
};

// ─── Notifications ───────────────────────────────────────────
export const notificationsAPI = {
  getAll: (params) => api.get("/admin/notifications", { params }),
  markRead: (id) => api.patch(`/admin/notifications/${id}/read`),
  markAllRead: () => api.patch("/admin/notifications/read-all"),
  delete: (id) => api.delete(`/admin/notifications/${id}`),
};

export default api;