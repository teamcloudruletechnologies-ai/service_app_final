import { useState, useEffect } from 'react';
import { bookingsAPI } from '../api';
import { toast } from 'react-toastify';

const STATUS_BADGES = {
  pending: { bg: 'var(--accent-light)', fg: 'var(--accent-dark)', text: 'Pending' },
  confirmed: { bg: '#F5F3FF', fg: '#7C3AED', text: 'Confirmed' },
  in_progress: { bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)', text: 'In Progress' },
  completed: { bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)', text: 'Completed' },
  cancelled: { bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)', text: 'Cancelled' },
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
      background: 'var(--bg-card)',
      border: '0.5px solid var(--border-color)',
      borderRadius: 12,
      padding: '16px 20px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? (
          <Skeleton w="90px" h={24} />
        ) : (
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 42, height: 42, borderRadius: 10,
        backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 20, flexShrink: 0
      }}>
        {icon}
      </div>
    </div>
  );
}

export default function Bookings() {
  const [bookings, setBookings] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Filters & Pagination
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const limit = 8;

  // Selected booking for detail drawer
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [updatingStatus, setUpdatingStatus] = useState(false);

  // Fetch Booking Stats
  const fetchStats = () => {
    setStatsLoading(true);
    bookingsAPI.getAnalytics()
      .then(res => {
        if (res && res.success) {
          setAnalytics(res.data);
        }
      })
      .catch(err => console.error('Failed to load booking analytics:', err))
      .finally(() => setStatsLoading(false));
  };

  // Fetch Booking List
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

  // Handle status update
  const handleStatusChange = (bookingId, newStatus) => {
    setUpdatingStatus(true);
    bookingsAPI.updateStatus(bookingId, newStatus)
      .then(res => {
        if (res && res.success) {
          // Update local state in drawer
          setSelectedBooking(res.data);
          toast.success(`Booking status updated to ${newStatus}`);
          // Refresh list and stats
          fetchBookingsList();
          fetchStats();
        }
      })
      .catch(err => {
        console.error('Failed to update status:', err);
        toast.error(err?.message || 'Failed to update booking status');
      })
      .finally(() => setUpdatingStatus(false));
  };

  // Helper Formats
  const formatCurrency = (val) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0
    }).format(Number(val) || 0);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const summary = analytics?.summary || {};

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      {/* CSS Animations */}
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideIn {
          from { transform: translateX(100%); }
          to { transform: translateX(0); }
        }
        .animate-fade {
          animation: fadeIn 0.2s ease-out forwards;
        }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Bookings Management</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Track customer service orders, assign jobs, and manage task lifecycles.</p>
        </div>
      </div>

      {/* Booking Statistics Dashboard */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total Orders"
          value={summary.total_bookings?.toLocaleString()}
          icon="📅"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={statsLoading}
        />
        <StatCard
          label="Pending Assign"
          value={summary.pending_bookings?.toLocaleString()}
          icon="⏳"
          bg="var(--status-amber-bg)"
          fg="var(--status-amber-fg)"
          loading={statsLoading}
        />
        <StatCard
          label="Confirmed"
          value={summary.confirmed_bookings?.toLocaleString()}
          icon="✅"
          bg="#F5F3FF"
          fg="#7C3AED"
          loading={statsLoading}
        />
        <StatCard
          label="Completed Tasks"
          value={summary.completed_bookings?.toLocaleString()}
          icon="🎉"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={statsLoading}
        />
        <StatCard
          label="Cancelled Orders"
          value={summary.cancelled_bookings?.toLocaleString()}
          icon="❌"
          bg="var(--status-red-bg)"
          fg="var(--status-red-fg)"
          loading={statsLoading}
        />
      </div>

      {/* Table Container Card */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        
        {/* Filters and List view padding */}
        <div style={{ padding: '20px 24px' }}>
          
          {/* Status filter pills */}
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
            {[
              { key: '', label: 'All Bookings' },
              { key: 'pending', label: 'Pending' },
              { key: 'confirmed', label: 'Confirmed' },
              { key: 'in_progress', label: 'In Progress' },
              { key: 'completed', label: 'Completed' },
              { key: 'cancelled', label: 'Cancelled' }
            ].map(opt => (
              <button
                key={opt.key}
                onClick={() => { setFilterStatus(opt.key); setCurrentPage(1); }}
                style={{
                  padding: '6px 14px',
                  borderRadius: 20,
                  border: '1px solid',
                  borderColor: filterStatus === opt.key ? 'var(--accent-color)' : 'var(--border-color)',
                  backgroundColor: filterStatus === opt.key ? 'var(--accent-light)' : 'var(--bg-card)',
                  color: filterStatus === opt.key ? 'var(--accent-color)' : 'var(--text-secondary)',
                  fontSize: 12,
                  fontWeight: 500,
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                }}
              >
                {opt.label}
              </button>
            ))}
          </div>

          {error && (
            <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, marginBottom: 16, fontSize: 13 }}>
              ⚠️ <strong>Error loading bookings:</strong> {error}
            </div>
          )}

          {/* Table */}
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  <th style={{ padding: '12px 16px', fontWeight: 600 }}>Booking ID</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600 }}>Customer</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600 }}>Professional</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600 }}>Category</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Price</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'center' }}>Status</th>
                  <th style={{ padding: '12px 16px', fontWeight: 600 }}>Order Date</th>
                  <th style={{ padding: '12px 16px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
                </tr>
              </thead>
              <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
                {loading ? (
                  [...Array(limit)].map((_, idx) => (
                    <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="60px" /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="120px" /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="120px" /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="100px" /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="60px" /></td>
                      <td style={{ padding: '14px 16px', textAlign: 'center' }}><Skeleton w="80px" radius={12} /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="100px" /></td>
                      <td style={{ padding: '14px 16px' }}><Skeleton w="65px" /></td>
                    </tr>
                  ))
                ) : bookings.length === 0 ? (
                  <tr>
                    <td colSpan="8" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                      <div style={{ fontSize: 32, marginBottom: 8 }}>🔍</div>
                      <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No bookings found</div>
                      <div style={{ fontSize: 12 }}>Check your filters or add new bookings.</div>
                    </td>
                  </tr>
                ) : (
                  bookings.map(book => {
                    const badge = STATUS_BADGES[book.status.toLowerCase()] || { bg: 'var(--border-color)', fg: 'var(--text-primary)', text: book.status };
                    return (
                      <tr key={book.id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                        <td style={{ padding: '14px 16px', fontWeight: 600, color: 'var(--text-primary)' }}>#{book.id}</td>
                        <td style={{ padding: '14px 16px' }}>{book.user_name || `Customer #${book.user_id}`}</td>
                        <td style={{ padding: '14px 16px' }}>{book.worker_name || 'Unassigned ⏳'}</td>
                        <td style={{ padding: '14px 16px', textTransform: 'capitalize' }}>{book.service_type || '—'}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'right', fontWeight: 600 }}>
                          {(book.status === 'completed' && Number(book.amount) > 0)
                            ? formatCurrency(book.amount)
                            : <span style={{ color: 'var(--text-secondary)', fontSize: 11, fontStyle: 'italic' }}>Price after inspection</span>}
                        </td>
                        <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                          <span style={{
                            display: 'inline-flex',
                            fontSize: 11,
                            borderRadius: 12,
                            padding: '2px 8px',
                            fontWeight: 600,
                            backgroundColor: badge.bg,
                            color: badge.fg
                          }}>
                            {badge.text}
                          </span>
                        </td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{formatDate(book.created_at)}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                          <button
                            onClick={() => setSelectedBooking(book)}
                            style={{
                              background: 'var(--accent-light)',
                              border: 'none',
                              borderRadius: 6,
                              padding: '4px 10px',
                              color: 'var(--accent-color)',
                              fontSize: 11,
                              fontWeight: 600,
                              cursor: 'pointer',
                              transition: 'all 0.15s'
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.background = 'var(--accent-color)';
                              e.currentTarget.style.color = 'var(--bg-card)';
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.background = 'var(--accent-light)';
                              e.currentTarget.style.color = 'var(--accent-color)';
                            }}
                          >
                            Manage
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
          {!loading && bookings.length > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 20, paddingTop: 16, borderTop: '0.5px solid var(--bg-muted)' }}>
              <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
                Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong>
              </span>
              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                  style={{
                    padding: '6px 12px',
                    borderRadius: 6,
                    border: '1px solid var(--border-color)',
                    background: 'var(--bg-card)',
                    color: currentPage === 1 ? 'var(--text-muted)' : 'var(--text-primary)',
                    fontSize: 12,
                    fontWeight: 500,
                    cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                  }}
                >
                  ◀ Prev
                </button>
                <button
                  disabled={currentPage === totalPages}
                  onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                  style={{
                    padding: '6px 12px',
                    borderRadius: 6,
                    border: '1px solid var(--border-color)',
                    background: 'var(--bg-card)',
                    color: currentPage === totalPages ? 'var(--text-muted)' : 'var(--text-primary)',
                    fontSize: 12,
                    fontWeight: 500,
                    cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
                  }}
                >
                  Next ▶
                </button>
              </div>
            </div>
          )}

        </div>
      </div>

      {/* Booking Status Update Modal */}
      {selectedBooking && (
        <div
          onClick={() => setSelectedBooking(null)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(11, 15, 25, 0.4)',
            backdropFilter: 'blur(4px)',
            zIndex: 1000,
            display: 'flex',
            justifyContent: 'flex-end',
          }}
        >
          {/* Slider content */}
          <div
            onClick={(e) => e.stopPropagation()}
            className="animate-fade"
            style={{
              width: '100%',
              maxWidth: 480,
              height: '100%',
              background: 'var(--bg-card)',
              borderLeft: '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '-4px 0 24px rgba(0,0,0,0.08)',
              animation: 'slideIn 0.25s ease-out forwards',
            }}
          >
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--border-color)' }}>
              <div>
                <span style={{ fontSize: 11, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>BOOKING OVERVIEW</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>Order ID: #{selectedBooking.id}</h3>
              </div>
              <button
                onClick={() => setSelectedBooking(null)}
                style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >
                ✕
              </button>
            </div>

            {/* Scroll Container */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
              
              {/* Dynamic Status Dropdown Control */}
              <div style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 12, padding: 16, marginBottom: 24 }}>
                <label style={{ block: 'block', fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 8, display: 'block' }}>
                  Update Action Status
                </label>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <select
                    disabled={updatingStatus}
                    value={selectedBooking.status.toLowerCase()}
                    onChange={(e) => handleStatusChange(selectedBooking.id, e.target.value)}
                    style={{
                      flex: 1,
                      padding: '10px 12px',
                      borderRadius: 8,
                      border: '1px solid #D1D5DB',
                      backgroundColor: 'var(--bg-card)',
                      fontSize: 13,
                      fontWeight: 600,
                      color: 'var(--text-primary)',
                      outline: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    <option value="pending">Pending Assignment</option>
                    <option value="confirmed">Confirmed</option>
                    <option value="in_progress">In Progress</option>
                    <option value="completed">Completed</option>
                    <option value="cancelled">Cancelled</option>
                  </select>
                  {updatingStatus && <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Saving...</span>}
                </div>
              </div>

              {/* Section 1: Customer Details */}
              <div style={{ borderBottom: '1px dashed var(--border-color)', paddingBottom: 18, marginBottom: 18 }}>
                <h4 style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>👤 Customer Node Details</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                  <div style={{ fontSize: 13 }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Name:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedBooking.user_name || 'Customer'}</strong>
                  </div>
                  <div style={{ fontSize: 13 }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Phone No:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedBooking.user_phone || '—'}</strong>
                  </div>
                  <div style={{ fontSize: 13 }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Customer Node ID:</span> <strong style={{ color: 'var(--text-primary)' }}>#{selectedBooking.user_id}</strong>
                  </div>
                </div>
              </div>

              {/* Section 2: Worker Details */}
              <div style={{ borderBottom: '1px dashed var(--border-color)', paddingBottom: 18, marginBottom: 18 }}>
                <h4 style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>💼 Professional Service Node</h4>
                {selectedBooking.worker_id ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <div style={{ fontSize: 13 }}>
                      <span style={{ color: 'var(--text-secondary)' }}>Name:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedBooking.worker_name}</strong>
                    </div>
                    <div style={{ fontSize: 13 }}>
                      <span style={{ color: 'var(--text-secondary)' }}>Phone No:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedBooking.worker_phone}</strong>
                    </div>
                    <div style={{ fontSize: 13 }}>
                      <span style={{ color: 'var(--text-secondary)' }}>Specialization:</span> <strong style={{ color: 'var(--text-primary)', textTransform: 'capitalize' }}>{selectedBooking.service_type}</strong>
                    </div>
                    <div style={{ fontSize: 13 }}>
                      <span style={{ color: 'var(--text-secondary)' }}>Worker Node ID:</span> <strong style={{ color: 'var(--text-primary)' }}>#{selectedBooking.worker_id}</strong>
                    </div>
                  </div>
                ) : (
                  <div style={{ fontSize: 13, color: 'var(--status-red-fg)', backgroundColor: 'var(--status-red-bg)', padding: '10px 14px', borderRadius: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span>⏳</span>
                    <span>No professional has been assigned yet. Waiting to assign.</span>
                  </div>
                )}
              </div>

              {/* Section 3: Financial Overview */}
              <div>
                <h4 style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>💰 Financial breakdown</h4>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: 'var(--accent-light)', padding: '12px 16px', borderRadius: 8 }}>
                  <span style={{ fontSize: 13, color: 'var(--accent-dark)', fontWeight: 500 }}>Total Service Charge</span>
                  <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--accent-dark)' }}>
                    {(selectedBooking.status === 'completed' && Number(selectedBooking.amount) > 0)
                      ? formatCurrency(selectedBooking.amount)
                      : 'Price after inspection'}
                  </span>
                </div>
              </div>

            </div>

            {/* Footer */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '16px 24px', backgroundColor: '#FAFAFB', display: 'flex', gap: 10 }}>
              <button
                onClick={() => setSelectedBooking(null)}
                style={{
                  flex: 1,
                  padding: '10px 14px',
                  borderRadius: 8,
                  border: 'none',
                  background: 'var(--accent-color)',
                  color: 'var(--bg-card)',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Done
              </button>
            </div>

          </div>
        </div>
      )}
    </div>
  );
}
