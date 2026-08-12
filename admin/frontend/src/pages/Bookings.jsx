import { useState, useEffect } from 'react';
import { bookingsAPI } from '../api';

const STATUS_BADGES = {
  pending: { bg: 'var(--accent-light)', fg: 'var(--accent-dark)', text: 'Pending' },
  matching: { bg: '#EFF6FF', fg: '#2563EB', text: 'Matching' },
  assigned: { bg: '#F5F3FF', fg: '#7C3AED', text: 'Assigned' },
  accepted: { bg: '#ECFDF5', fg: '#059669', text: 'Accepted' },
  arriving: { bg: '#FFFBEB', fg: '#D97706', text: 'Arriving' },
  otp_verified: { bg: '#E0E7FF', fg: '#4338CA', text: 'OTP Verified' },
  in_progress: { bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)', text: 'In Progress' },
  extra_cost_pending: { bg: '#FEF2F2', fg: '#DC2626', text: 'Extra Cost Pending' },
  exception_pending: { bg: '#FEE2E2', fg: '#991B1B', text: 'Exception Pending' },
  completed: { bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)', text: 'Completed' },
  payment_pending: { bg: '#FFF7ED', fg: '#EA580C', text: 'Payment Pending' },
  paid: { bg: '#D1FAE5', fg: '#065F46', text: 'Paid' },
  closed: { bg: '#F3F4F6', fg: '#374151', text: 'Closed' },
  rejected: { bg: '#FEE2E2', fg: '#991B1B', text: 'Rejected' },
  reassignment_required: { bg: '#FEF3C7', fg: '#92400E', text: 'Reassignment Required' },
  cancelled: { bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)', text: 'Cancelled' },
  confirmed: { bg: '#F5F3FF', fg: '#7C3AED', text: 'Confirmed' },
};

function Skeleton({ w = '100%', h = 16, radius = 6 }) {
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: 'linear-gradient(90deg,var(--bg-muted) 25%,var(--border-color) 50%,var(--bg-muted) 75%)',
      backgroundSize: '200% 100%',
      animation: 'shimmer 1.4s infinite',
    }} />
  );
}

function StatCard({ label, value, icon, bg, fg, loading }) {
  return (
    <div style={{
      background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12,
      padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="90px" h={24} /> : (
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 42, height: 42, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0
      }}>{icon}</div>
    </div>
  );
}

// 7-Day x 24-Hour Booking Activity Heatmap
function BookingActivityHeatmap({ data = [] }) {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const hours = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];

  const matrix = Array.from({ length: 7 }, () => Array(24).fill(0));
  let maxCount = 1;

  data.forEach(item => {
    const dow = Number(item.day_of_week);
    const hr = Number(item.hour_of_day);
    const cnt = Number(item.count || 0);
    if (dow >= 0 && dow < 7 && hr >= 0 && hr < 24) {
      matrix[dow][hr] = cnt;
      if (cnt > maxCount) maxCount = cnt;
    }
  });

  const getIntensityColor = (cnt) => {
    if (!cnt || cnt === 0) return 'var(--bg-muted)';
    const ratio = cnt / maxCount;
    if (ratio < 0.25) return '#D1FAE5';
    if (ratio < 0.5) return '#6EE7B7';
    if (ratio < 0.75) return '#10B981';
    return '#047857';
  };

  return (
    <div style={{ background: 'var(--bg-card)', padding: '20px 24px', borderRadius: 14, border: '1px solid var(--border-color)', marginBottom: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h3 style={{ fontSize: 16, fontWeight: 700, margin: 0, color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: 6 }}>
            🔥 Booking Order Activity Heatmap (Last 30 Days Density)
          </h3>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>Peak ordering hours & day-of-week demand intensity</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: 'var(--text-muted)' }}>
          <span>Low</span>
          <div style={{ display: 'flex', gap: 4 }}>
            <span style={{ width: 14, height: 14, borderRadius: 3, background: 'var(--bg-muted)' }} />
            <span style={{ width: 14, height: 14, borderRadius: 3, background: '#D1FAE5' }} />
            <span style={{ width: 14, height: 14, borderRadius: 3, background: '#6EE7B7' }} />
            <span style={{ width: 14, height: 14, borderRadius: 3, background: '#10B981' }} />
            <span style={{ width: 14, height: 14, borderRadius: 3, background: '#047857' }} />
          </div>
          <span>High Peak</span>
        </div>
      </div>

      <div style={{ overflowX: 'auto' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '50px repeat(12, 1fr)', gap: 6, minWidth: 600 }}>
          <div />
          {hours.map(h => (
            <div key={h} style={{ fontSize: 10, fontWeight: 600, color: 'var(--text-muted)', textAlign: 'center' }}>
              {h === 0 ? '12 AM' : h === 12 ? '12 PM' : h > 12 ? `${h - 12} PM` : `${h} AM`}
            </div>
          ))}

          {days.map((dayName, dIdx) => (
            <div key={dayName} style={{ display: 'contents' }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center' }}>
                {dayName}
              </div>
              {hours.map(h => {
                const cnt = matrix[dIdx][h] + matrix[dIdx][h + 1];
                return (
                  <div
                    key={h}
                    title={`${dayName} ${h}:00 - ${cnt} bookings`}
                    style={{
                      height: 26, borderRadius: 4,
                      background: getIntensityColor(cnt),
                      border: '0.5px solid var(--border-color)',
                      transition: 'transform 0.1s',
                      cursor: 'pointer'
                    }}
                  />
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default function Bookings({ initialStatus = '' }) {
  const [bookings, setBookings] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Section View Tab: 'all' | 'category' | 'service' | 'worker'
  const [activeSection, setActiveSection] = useState('all');

  // Selected Worker for Worker Breakdown Drill-down
  const [selectedWorkerId, setSelectedWorkerId] = useState(null);

  // Filters & Pagination
  const [filterStatus, setFilterStatus] = useState(initialStatus);

  useEffect(() => {
    setFilterStatus(initialStatus);
  }, [initialStatus]);

  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const limit = 10;

  // Selected booking for detail drawer
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [updatingStatus, setUpdatingStatus] = useState(false);

  const fetchStats = () => {
    setStatsLoading(true);
    bookingsAPI.getAnalytics()
      .then(res => {
        if (res && res.success) setAnalytics(res.data);
      })
      .catch(err => console.error('Failed to load booking analytics:', err))
      .finally(() => setStatsLoading(false));
  };

  const fetchBookingsList = () => {
    setLoading(true);
    setError('');
    const params = {
      page: currentPage,
      limit: limit,
    };
    if (filterStatus) params.status = filterStatus;

    bookingsAPI.getAll(params)
      .then(res => {
        if (res && res.success) {
          setBookings(res.data.rows || []);
          setTotalPages(res.data.meta?.totalPages || 1);
        }
      })
      .catch(err => {
        console.error('Error fetching bookings:', err);
        setError(err?.message || 'Failed to load bookings');
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchStats();
  }, []);

  useEffect(() => {
    fetchBookingsList();
  }, [currentPage, filterStatus]);

  const handleStatusChange = (bookingId, newStatus) => {
    setUpdatingStatus(true);
    bookingsAPI.updateStatus(bookingId, newStatus)
      .then(res => {
        if (res && res.success) {
          setSelectedBooking(res.data);
          fetchBookingsList();
          fetchStats();
        }
      })
      .catch(err => {
        alert(err?.message || 'Failed to update booking status');
      })
      .finally(() => setUpdatingStatus(false));
  };

  const formatDate = (d) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };
  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });

  const summary = analytics?.summary || {};
  const categoryBreakdown = analytics?.categoryBreakdown || [];
  const serviceBreakdown = analytics?.serviceBreakdown || [];
  const workerBreakdown = analytics?.workerBreakdown || [];
  const heatmapData = analytics?.heatmapData || [];

  const filteredBookings = bookings.filter(b => {
    const s = searchQuery.toLowerCase().trim();
    if (!s) return true;
    return (b.user_name || '').toLowerCase().includes(s) ||
      (b.worker_name || '').toLowerCase().includes(s) ||
      (b.service_name || '').toLowerCase().includes(s) ||
      String(b.id).includes(s);
  });

  // Selected Worker profile data
  const activeWorker = workerBreakdown.find(w => w.worker_id === selectedWorkerId);
  const workerBookingsList = bookings.filter(b => b.worker_id === selectedWorkerId);

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        .b-row:hover { background: var(--bg-app); }
        .sec-tab { padding: 8px 16px; font-size: 13px; font-weight: 600; border-radius: 8px; cursor: pointer; border: 1px solid transparent; transition: all 0.2s; }
        .sec-tab.active { background: var(--accent-color); color: #fff; border-color: var(--accent-color); }
        .sec-tab.inactive { background: var(--bg-card); color: var(--text-secondary); border-color: var(--border-color); }
        .worker-card:hover { transform: translateY(-2px); border-color: var(--accent-color) !important; }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
            Bookings {filterStatus ? `— ${STATUS_BADGES[filterStatus]?.text || filterStatus.replace(/_/g, ' ').toUpperCase()}` : 'Management & Analytics'}
            {filterStatus && (
              <span style={{
                background: STATUS_BADGES[filterStatus]?.bg || 'var(--accent-light)',
                color: STATUS_BADGES[filterStatus]?.fg || 'var(--accent-dark)',
                fontSize: 12, padding: '4px 12px', borderRadius: 12, fontWeight: 700
              }}>
                Dedicated Status Page
              </span>
            )}
          </h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            {filterStatus
              ? `Showing all service orders with lifecycle status: ${STATUS_BADGES[filterStatus]?.text || filterStatus}`
              : 'Track total service orders, booking activity heatmap demand, Category/Service/Worker breakdowns, and lifecycle status updates.'}
          </p>
        </div>
        <button
          onClick={() => { fetchBookingsList(); fetchStats(); }}
          style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
        >
          🔄 Refresh Bookings
        </button>
      </div>

      {/* TOP KPI OVERVIEW CARDS */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Total Orders"
          value={summary.total_bookings || 0}
          icon="📋" bg="rgba(59,130,246,0.1)" fg="#3B82F6"
          loading={statsLoading}
        />
        <StatCard
          label="Pending Assign / Matching"
          value={summary.pending_bookings || 0}
          icon="⏳" bg="rgba(245,158,11,0.1)" fg="#F59E0B"
          loading={statsLoading}
        />
        <StatCard
          label="Confirmed & Assigned"
          value={summary.confirmed_bookings || 0}
          icon="✅" bg="rgba(99,102,241,0.1)" fg="#6366F1"
          loading={statsLoading}
        />
        <StatCard
          label="Completed Tasks"
          value={summary.completed_bookings || 0}
          icon="🎉" bg="rgba(16,185,129,0.1)" fg="#10B981"
          loading={statsLoading}
        />
        <StatCard
          label="Cancelled Orders"
          value={summary.cancelled_bookings || 0}
          icon="❌" bg="rgba(239,68,68,0.1)" fg="#EF4444"
          loading={statsLoading}
        />
      </div>

      {/* ACTIVITY HEATMAP CHART */}
      <BookingActivityHeatmap data={heatmapData} />

      {/* SECTION VIEWS BAR */}
      <div style={{ background: 'var(--bg-card)', padding: '16px 20px', borderRadius: 14, border: '1px solid var(--border-color)', marginBottom: 24, display: 'flex', flexWrap: 'wrap', gap: 16, justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button
            className={`sec-tab ${activeSection === 'all' ? 'active' : 'inactive'}`}
            onClick={() => { setActiveSection('all'); setSelectedWorkerId(null); }}
          >
            📋 All Orders List
          </button>
          <button
            className={`sec-tab ${activeSection === 'category' ? 'active' : 'inactive'}`}
            onClick={() => { setActiveSection('category'); setSelectedWorkerId(null); }}
          >
            📁 Category Section
          </button>
          <button
            className={`sec-tab ${activeSection === 'service' ? 'active' : 'inactive'}`}
            onClick={() => { setActiveSection('service'); setSelectedWorkerId(null); }}
          >
            🔧 Service Section
          </button>
          <button
            className={`sec-tab ${activeSection === 'worker' ? 'active' : 'inactive'}`}
            onClick={() => setActiveSection('worker')}
          >
            👷 Individual Worker Breakdown
          </button>
        </div>
      </div>

      {/* SECTION VIEW 1: CATEGORY SECTION */}
      {activeSection === 'category' && (
        <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', overflow: 'hidden', marginBottom: 24 }}>
          <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', fontWeight: 700, fontSize: 15 }}>
            📁 Category Booking Breakdown
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
            <thead>
              <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                <th style={{ padding: '12px 16px' }}>Category</th>
                <th style={{ padding: '12px 16px' }}>Total Bookings</th>
                <th style={{ padding: '12px 16px' }}>Active In-Progress</th>
                <th style={{ padding: '12px 16px' }}>Completed</th>
                <th style={{ padding: '12px 16px' }}>Cancelled</th>
                <th style={{ padding: '12px 16px' }}>Total Revenue</th>
              </tr>
            </thead>
            <tbody>
              {categoryBreakdown.map(cat => (
                <tr key={cat.category_id} className="b-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>
                    {cat.category_icon || '🛠️'} {cat.category_name}
                  </td>
                  <td style={{ padding: '14px 16px', fontWeight: 700 }}>{cat.total_bookings}</td>
                  <td style={{ padding: '14px 16px', color: '#F59E0B', fontWeight: 600 }}>{cat.active_bookings}</td>
                  <td style={{ padding: '14px 16px', color: '#10B981', fontWeight: 600 }}>{cat.completed_bookings}</td>
                  <td style={{ padding: '14px 16px', color: '#EF4444' }}>{cat.cancelled_bookings}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700 }}>{formatINR(cat.total_revenue)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* SECTION VIEW 2: SERVICE SECTION */}
      {activeSection === 'service' && (
        <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', overflow: 'hidden', marginBottom: 24 }}>
          <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--border-color)', fontWeight: 700, fontSize: 15 }}>
            🔧 Service Booking Breakdown
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
            <thead>
              <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                <th style={{ padding: '12px 16px' }}>Service Name</th>
                <th style={{ padding: '12px 16px' }}>Category</th>
                <th style={{ padding: '12px 16px' }}>Total Bookings</th>
                <th style={{ padding: '12px 16px' }}>Completed</th>
                <th style={{ padding: '12px 16px' }}>Cancelled</th>
                <th style={{ padding: '12px 16px' }}>Total Revenue</th>
              </tr>
            </thead>
            <tbody>
              {serviceBreakdown.map(srv => (
                <tr key={srv.service_id} className="b-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>🔧 {srv.service_name}</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{srv.category_name}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700 }}>{srv.total_bookings}</td>
                  <td style={{ padding: '14px 16px', color: '#10B981', fontWeight: 600 }}>{srv.completed_bookings}</td>
                  <td style={{ padding: '14px 16px', color: '#EF4444' }}>{srv.cancelled_bookings}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700 }}>{formatINR(srv.total_revenue)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* SECTION VIEW 3: INDIVIDUAL WORKER BREAKDOWN WITH PROFILE CARDS */}
      {activeSection === 'worker' && (
        <div style={{ marginBottom: 24 }}>
          {selectedWorkerId ? (
            /* Selected Worker Detailed History Table */
            <div style={{ background: 'var(--bg-card)', padding: 20, borderRadius: 14, border: '1px solid var(--border-color)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <div>
                  <button
                    onClick={() => setSelectedWorkerId(null)}
                    style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 6, padding: '6px 12px', fontSize: 12, fontWeight: 700, cursor: 'pointer', marginBottom: 8, color: 'var(--text-primary)' }}
                  >
                    ← Back to All Workers Profile Grid
                  </button>
                  <h3 style={{ fontSize: 18, fontWeight: 800, margin: 0, color: 'var(--text-primary)' }}>
                    👷 Technician: {activeWorker?.worker_name || 'Worker'} (📞 {activeWorker?.worker_phone || '—'})
                  </h3>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>
                    Specialty: {activeWorker?.service_type || 'General'} · Total Jobs: {activeWorker?.total_bookings || 0}
                  </div>
                </div>
              </div>

              {/* Worker Orders List */}
              <div style={{ borderRadius: 10, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
                  <thead>
                    <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                      <th style={{ padding: '12px 16px' }}>Booking ID</th>
                      <th style={{ padding: '12px 16px' }}>Customer</th>
                      <th style={{ padding: '12px 16px' }}>Service</th>
                      <th style={{ padding: '12px 16px' }}>Amount</th>
                      <th style={{ padding: '12px 16px' }}>Status</th>
                      <th style={{ padding: '12px 16px' }}>Date</th>
                      <th style={{ padding: '12px 16px', textAlign: 'right' }}>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {workerBookingsList.length === 0 ? (
                      <tr>
                        <td colSpan={7} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>
                          No specific bookings found loaded for this worker.
                        </td>
                      </tr>
                    ) : (
                      workerBookingsList.map(b => {
                        const badge = STATUS_BADGES[b.status] || { bg: '#F3F4F6', fg: '#374151', text: b.status };
                        return (
                          <tr key={b.id} className="b-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                            <td style={{ padding: '14px 16px', fontWeight: 700 }}>#{b.id}</td>
                            <td style={{ padding: '14px 16px' }}>{b.user_name}</td>
                            <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{b.service_name}</td>
                            <td style={{ padding: '14px 16px', fontWeight: 700 }}>{formatINR(b.amount)}</td>
                            <td style={{ padding: '14px 16px' }}>
                              <span style={{ background: badge.bg, color: badge.fg, padding: '4px 10px', borderRadius: 12, fontSize: 11, fontWeight: 700 }}>
                                {badge.text}
                              </span>
                            </td>
                            <td style={{ padding: '14px 16px', color: 'var(--text-muted)', fontSize: 12 }}>{formatDate(b.created_at)}</td>
                            <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                              <button
                                onClick={() => setSelectedBooking(b)}
                                style={{ background: 'var(--accent-color)', color: '#fff', border: 'none', borderRadius: 6, padding: '6px 12px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
                              >
                                👁️ Details
                              </button>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            /* Worker Profiles Grid Cards */
            <div>
              <h3 style={{ fontSize: 16, fontWeight: 700, margin: '0 0 16px', color: 'var(--text-primary)' }}>
                👷 Individual Worker Profiles & Booking Performance Grid
              </h3>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16 }}>
                {workerBreakdown.map(w => {
                  const initials = (w.worker_name || 'WK').substring(0, 2).toUpperCase();
                  return (
                    <div
                      key={w.worker_id}
                      className="worker-card"
                      onClick={() => setSelectedWorkerId(w.worker_id)}
                      style={{
                        background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 14,
                        padding: 20, cursor: 'pointer', transition: 'all 0.2s', boxShadow: '0 2px 6px rgba(0,0,0,0.02)'
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 14 }}>
                        <div style={{
                          width: 46, height: 46, borderRadius: '50%', background: 'linear-gradient(135deg, #3B82F6, #1D4ED8)',
                          color: '#fff', fontSize: 16, fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
                        }}>
                          {initials}
                        </div>
                        <div>
                          <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--text-primary)' }}>{w.worker_name}</div>
                          <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>📞 {w.worker_phone || '—'}</div>
                        </div>
                      </div>

                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, background: 'var(--bg-app)', padding: 12, borderRadius: 10, marginBottom: 14, textAlign: 'center' }}>
                        <div>
                          <div style={{ fontSize: 16, fontWeight: 800, color: '#3B82F6' }}>{w.total_bookings}</div>
                          <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600 }}>Total Jobs</div>
                        </div>
                        <div>
                          <div style={{ fontSize: 16, fontWeight: 800, color: '#10B981' }}>{w.completed_bookings}</div>
                          <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600 }}>Completed</div>
                        </div>
                        <div>
                          <div style={{ fontSize: 16, fontWeight: 800, color: '#EF4444' }}>{w.cancelled_bookings}</div>
                          <div style={{ fontSize: 10, color: 'var(--text-muted)', fontWeight: 600 }}>Cancelled</div>
                        </div>
                      </div>

                      <button
                        style={{
                          width: '100%', background: 'var(--bg-app)', border: '1px solid #D1D5DB', borderRadius: 8,
                          padding: '8px 12px', fontSize: 12, fontWeight: 700, cursor: 'pointer', color: 'var(--text-primary)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6
                        }}
                      >
                        👁️ View Worker Bookings ({w.total_bookings})
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}

      {/* SECTION VIEW 4: MASTER BOOKINGS TABLE (ONLY SHOWS WHEN 'all' TAB IS ACTIVE) */}
      {activeSection === 'all' && (
        <div style={{ background: 'var(--bg-card)', padding: 20, borderRadius: 14, border: '1px solid var(--border-color)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ fontSize: 16, fontWeight: 700, margin: 0, color: 'var(--text-primary)' }}>
              📋 Master Service Orders List {filterStatus ? `(${filterStatus.toUpperCase()})` : ''}
            </h3>
            <input
              type="text"
              placeholder="Search booking ID, customer, worker..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '7px 14px', fontSize: 13, color: 'var(--text-primary)', width: 280 }}
            />
          </div>

          {error && (
            <div style={{ background: '#FEE2E2', border: '1px solid #EF4444', color: '#991B1B', padding: '10px 14px', borderRadius: 8, fontSize: 12, marginBottom: 14 }}>
              ⚠️ {error}
            </div>
          )}

          <div style={{ borderRadius: 10, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
              <thead>
                <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                  <th style={{ padding: '12px 16px' }}>Booking ID</th>
                  <th style={{ padding: '12px 16px' }}>Customer</th>
                  <th style={{ padding: '12px 16px' }}>Service Name</th>
                  <th style={{ padding: '12px 16px' }}>Technician</th>
                  <th style={{ padding: '12px 16px' }}>OTP Code</th>
                  <th style={{ padding: '12px 16px' }}>Status Badge</th>
                  <th style={{ padding: '12px 16px' }}>Created Date</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right' }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                      <td colSpan={8} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                    </tr>
                  ))
                ) : filteredBookings.length === 0 ? (
                  <tr>
                    <td colSpan={8} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>
                      No bookings found matching selected filters.
                    </td>
                  </tr>
                ) : (
                  filteredBookings.map(b => {
                    const badge = STATUS_BADGES[b.status] || { bg: '#F3F4F6', fg: '#374151', text: b.status };
                    return (
                      <tr key={b.id} className="b-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '14px 16px', fontWeight: 700 }}>#{b.id}</td>
                        <td style={{ padding: '14px 16px' }}>
                          <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{b.user_name || 'Customer'}</div>
                          <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>📞 {b.user_phone || '—'}</div>
                        </td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{b.service_name || 'Home Service'}</td>
                        <td style={{ padding: '14px 16px' }}>
                          {b.worker_name ? (
                            <div>
                              <div style={{ fontWeight: 600 }}>{b.worker_name}</div>
                              <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>📞 {b.worker_phone}</div>
                            </div>
                          ) : (
                            <span style={{ color: '#9CA3AF', fontSize: 12 }}>Unassigned</span>
                          )}
                        </td>
                        <td style={{ padding: '14px 16px' }}>
                          {b.otp ? (
                            <span style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', padding: '2px 8px', borderRadius: 4, fontFamily: 'monospace', fontWeight: 700 }}>
                              {b.otp}
                            </span>
                          ) : '—'}
                        </td>
                        <td style={{ padding: '14px 16px' }}>
                          <span style={{ background: badge.bg, color: badge.fg, padding: '4px 10px', borderRadius: 12, fontSize: 11, fontWeight: 700 }}>
                            {badge.text}
                          </span>
                        </td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-muted)', fontSize: 12 }}>{formatDate(b.created_at)}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                          <button
                            onClick={() => setSelectedBooking(b)}
                            style={{ background: 'var(--accent-color)', color: '#fff', border: 'none', borderRadius: 6, padding: '6px 12px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
                          >
                            👁️ Details
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {!loading && totalPages > 1 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 16 }}>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Page {currentPage} of {totalPages}</div>
              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage(p => p - 1)}
                  style={{ background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 6, padding: '6px 12px', fontSize: 12, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}
                >
                  Previous
                </button>
                <button
                  disabled={currentPage === totalPages}
                  onClick={() => setCurrentPage(p => p + 1)}
                  style={{ background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 6, padding: '6px 12px', fontSize: 12, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* DETAIL DRAWER / MODAL */}
      {selectedBooking && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'flex-end', zIndex: 1000 }}>
          <div style={{ background: 'var(--bg-card)', width: 480, maxWidth: '100%', height: '100%', padding: 24, overflowY: 'auto', boxShadow: '-10px 0 25px rgba(0,0,0,0.1)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h3 style={{ fontSize: 18, fontWeight: 700, margin: 0, color: 'var(--text-primary)' }}>
                Booking Details #{selectedBooking.id}
              </h3>
              <button onClick={() => setSelectedBooking(null)} style={{ background: 'transparent', border: 'none', fontSize: 20, cursor: 'pointer', color: 'var(--text-muted)' }}>✕</button>
            </div>

            <div style={{ background: 'var(--bg-app)', padding: 16, borderRadius: 12, marginBottom: 20 }}>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 4 }}>Current Lifecycle Status</div>
              <select
                value={selectedBooking.status}
                disabled={updatingStatus}
                onChange={e => handleStatusChange(selectedBooking.id, e.target.value)}
                style={{ width: '100%', background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 12px', fontSize: 14, fontWeight: 700, color: 'var(--text-primary)' }}
              >
                {Object.entries(STATUS_BADGES).map(([key, info]) => (
                  <option key={key} value={key}>{info.text}</option>
                ))}
              </select>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14, fontSize: 13 }}>
              <div><strong>Service Name:</strong> {selectedBooking.service_name || 'Home Service'}</div>
              <div><strong>Customer Name:</strong> {selectedBooking.user_name} (📞 {selectedBooking.user_phone})</div>
              <div><strong>Technician:</strong> {selectedBooking.worker_name ? `${selectedBooking.worker_name} (📞 ${selectedBooking.worker_phone})` : 'Unassigned'}</div>
              <div><strong>Service Address:</strong> {selectedBooking.address || '—'}</div>
              <div><strong>Customer Notes:</strong> {selectedBooking.notes || '—'}</div>
              <div><strong>4-Digit OTP Code:</strong> <span style={{ fontFamily: 'monospace', fontWeight: 700 }}>{selectedBooking.otp || '—'}</span></div>
              <div><strong>Created Date:</strong> {formatDate(selectedBooking.created_at)}</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
