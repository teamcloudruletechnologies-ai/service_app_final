import axios from "axios";

const api = axios.create({
  baseURL: "http://localhost:5000/api",
  timeout: 10000,
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
  logout: () => api.post("/auth/logout"),
  me: () => api.get("/auth/me"),
};

// ─── Dashboard ───────────────────────────────────────────────
export const dashboardAPI = {
  getStats: () => api.get("/dashboard/overview"), // ✅ Fixed: was /dashboard/stats
  getRecentBookings: () => api.get("/dashboard/recent-bookings"),
  getRevenueChart: () => api.get("/dashboard/revenue-chart"),
  getActivity: () => api.get("/dashboard/activity"),
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
  update: (id, data) => api.put(`/workers/${id}`, data),
  delete: (id) => api.delete(`/workers/${id}`),
};

// ─── KYC ─────────────────────────────────────────────────────
export const kycAPI = {
  getAll: (params) => api.get("/kyc", { params }),
  getById: (id) => api.get(`/kyc/${id}`),
  approve: (id) => api.post(`/kyc/${id}/approve`),
  reject: (id, reason) => api.post(`/kyc/${id}/reject`, { reason }),
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

// ─── Complaints ──────────────────────────────────────────────
export const complaintsAPI = {
  getAll: (params) => api.get("/admin/complaints", { params }),
  getById: (id) => api.get(`/admin/complaints/${id}`),
  update: (id, data) => api.put(`/admin/complaints/${id}`, data),
};

// ─── Locations ───────────────────────────────────────────────
export const locationsAPI = {
  getAll: () => api.get("/admin/locations"),
  create: (data) => api.post("/admin/locations", data),
  update: (id, data) => api.put(`/admin/locations/${id}`, data),
  delete: (id) => api.delete(`/admin/locations/${id}`),
};

export default api;