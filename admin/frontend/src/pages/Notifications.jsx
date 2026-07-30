import { useState, useEffect } from 'react';
import { notificationsAPI } from '../api';
import { toast } from 'react-toastify';
import ConfirmModal from '../components/ConfirmModal';

/* ─── Reusable Skeleton loader (same as KYC) ─── */
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

/* ─── Stat Card (same pattern as KYC) ─── */
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
      boxShadow: '0 1px 3px rgba(0,0,0,0.02)'
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? (
          <Skeleton w="60px" h={24} />
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

/* ─── NOTIFICATION TYPE CONFIG ─── */
const TYPE_CONFIG = {
  booking:  { label: 'Booking',      bg: 'var(--accent-light)', fg: 'var(--accent-color)', icon: '📅' },
  kyc:      { label: 'KYC',          bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)', icon: '🪪' },
  complaint:{ label: 'Complaint',    bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)', icon: '💬' },
  payment:  { label: 'Payment',      bg: '#F5F3FF', fg: '#7C3AED', icon: '💳' },
  system:   { label: 'System',       bg: 'var(--bg-app)', fg: 'var(--text-primary)', icon: '⚙️' },
};

function getTypeBadge(type = 'system') {
  return TYPE_CONFIG[type] || TYPE_CONFIG.system;
}

function getPriorityBadge(priority = 'normal') {
  switch (priority) {
    case 'high':   return { text: '🔴 High',   bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' };
    case 'low':    return { text: '⚪ Low',    bg: 'var(--bg-app)', fg: 'var(--text-secondary)' };
    default:       return { text: '🟡 Normal', bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' };
  }
}

/* ─── MAIN COMPONENT ─── */
export default function Notifications() {
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Pagination & Filters
  const [filterRead, setFilterRead] = useState('');          // '' | 'unread' | 'read'
  const [filterType, setFilterType] = useState('');          // '' | 'booking' | 'kyc' | ...
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalDocs, setTotalDocs] = useState(0);
  const limit = 10;

  // Stats
  const [stats, setStats] = useState({ total: 0, unread: 0, high: 0, read: 0 });

  // Drawer
  const [selectedNotif, setSelectedNotif] = useState(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [markingRead, setMarkingRead] = useState(false);
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });

  /* ── Fetch list ── */
  const fetchList = () => {
    setLoading(true);
    setError('');
    const params = { page: currentPage, limit };
    if (filterRead)  params.read  = filterRead;
    if (filterType)  params.type  = filterType;

    notificationsAPI.getAll(params)
      .then(res => {
        if (res && res.success && res.data) {
          const rows = res.data.rows || [];
          setNotifications(rows);
          setTotalDocs(res.data.meta?.total || rows.length);
          setTotalPages(res.data.meta?.totalPages || 1);
        }
      })
      .catch(err => {
        console.error('Error fetching notifications:', err);
        setError(err?.message || 'Failed to load notifications.');
      })
      .finally(() => setLoading(false));
  };

  /* ── Fetch stats ── */
  const fetchStats = () => {
    notificationsAPI.getAll({ limit: 1000 })
      .then(res => {
        if (res && res.success && res.data) {
          const rows = res.data.rows || [];
          const total  = Number(res.data.meta?.total || rows.length);
          const unread = rows.filter(r => !r.read).length;
          const high   = rows.filter(r => r.priority === 'high').length;
          const read   = rows.filter(r => r.read).length;
          setStats({ total, unread, high, read });
        }
      })
      .catch(err => console.error('Stats error:', err));
  };

  useEffect(() => { fetchList(); }, [currentPage, filterRead, filterType]);
  useEffect(() => { fetchStats(); }, [notifications]);

  /* ── Open detail drawer ── */
  const handleOpenDetail = (notif) => {
    setSelectedNotif(notif);
  };

  /* ── Mark as Read ── */
  const handleMarkRead = (id) => {
    setMarkingRead(true);
    notificationsAPI.markRead(id)
      .then(res => {
        if (res && res.success) {
          setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
          if (selectedNotif?.id === id) {
            setSelectedNotif(prev => ({ ...prev, read: true }));
          }
          toast.success('Marked as read');
          fetchStats();
        }
      })
      .catch(err => {
        console.error('Mark read error:', err);
        toast.error('Failed to mark notification as read');
      })
      .finally(() => setMarkingRead(false));
  };

  /* ── Mark all as Read ── */
  const handleMarkAllRead = () => {
    notificationsAPI.markAllRead()
      .then(res => {
        if (res && res.success) {
          setNotifications(prev => prev.map(n => ({ ...n, read: true })));
          toast.success('All notifications marked as read!');
          fetchStats();
        }
      })
      .catch(err => {
        console.error('Mark all read error:', err);
        toast.error('Failed to mark all as read');
      });
  };

  /* ── Delete ── */
  const handleDelete = (id) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Delete Notification',
      message: 'Are you sure you want to delete this notification?',
      confirmText: 'Delete Notification',
      variant: 'danger',
      onConfirm: () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        notificationsAPI.delete(id)
          .then(res => {
            if (res && res.success) {
              setNotifications(prev => prev.filter(n => n.id !== id));
              if (selectedNotif?.id === id) setSelectedNotif(null);
              toast.success('Notification deleted');
              fetchStats();
            }
          })
          .catch(err => {
            console.error('Delete error:', err);
            toast.error('Failed to delete notification');
          });
      }
    });
  };

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  /* ── Local search filter ── */
  const filteredNotifs = notifications.filter(n => {
    const term = search.toLowerCase().trim();
    if (!term) return true;
    return (
      (n.title   || '').toLowerCase().includes(term) ||
      (n.message || '').toLowerCase().includes(term) ||
      (n.type    || '').toLowerCase().includes(term)
    );
  });

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideIn {
          from { transform: translateX(100%); }
          to   { transform: translateX(0); }
        }
        .notif-row:hover {
          background: var(--bg-app) !important;
        }
        .animate-fade { animation: fadeIn 0.2s ease-out forwards; }
        .action-btn {
          border: 1px solid var(--border-color);
          background: var(--bg-card);
          border-radius: 6px;
          padding: 4px 10px;
          font-size: 11px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.15s;
        }
        .action-btn:hover { background: var(--bg-muted); }
        .action-btn.danger:hover { background: var(--status-red-bg); color: var(--status-red-fg); border-color: #FCA5A5; }
        .action-btn.primary { color: var(--accent-color); }
        .action-btn.primary:hover { background: var(--accent-light); border-color: var(--accent-border); }
      `}</style>

      {/* ── Page Header ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Notifications</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Manage and review all system, booking, KYC, and complaint alerts.
          </p>
        </div>
        {stats.unread > 0 && (
          <button
            onClick={handleMarkAllRead}
            style={{
              padding: '8px 14px',
              borderRadius: 8,
              border: '1px solid #D1D5DB',
              background: 'var(--bg-card)',
              fontSize: 12,
              fontWeight: 600,
              color: 'var(--text-primary)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 6,
            }}
          >
            ✅ Mark All as Read
          </button>
        )}
      </div>

      {/* ── Stat Cards (4 columns, same as KYC) ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard label="Total Notifications" value={stats.total}  icon="🔔" bg="var(--accent-light)" fg="var(--accent-color)" loading={loading} />
        <StatCard label="Unread"              value={stats.unread} icon="📭" bg="var(--status-amber-bg)" fg="var(--status-amber-fg)" loading={loading} />
        <StatCard label="High Priority"       value={stats.high}   icon="🔴" bg="var(--status-red-bg)" fg="var(--status-red-fg)" loading={loading} />
        <StatCard label="Read / Resolved"     value={stats.read}   icon="✅" bg="var(--status-green-bg)" fg="var(--status-green-fg)" loading={loading} />
      </div>

      {/* ── Table Card ── */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

        {/* Controls */}
        <div style={{ padding: '20px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          {/* Search */}
          <div style={{ position: 'relative', flex: 1, minWidth: 260, maxWidth: 400 }}>
            <input
              type="text"
              placeholder="Search by title, message or type..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px 8px 34px',
                border: '1px solid #D1D5DB',
                borderRadius: 8,
                fontSize: 13,
                outline: 'none',
                fontFamily: "'DM Sans', sans-serif",
                boxSizing: 'border-box',
              }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 15 }}>🔍</span>
          </div>

          {/* Filters */}
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <select
              value={filterRead}
              onChange={(e) => { setFilterRead(e.target.value); setCurrentPage(1); }}
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500, fontFamily: 'inherit' }}
            >
              <option value="">All Status</option>
              <option value="unread">Unread</option>
              <option value="read">Read</option>
            </select>

            <select
              value={filterType}
              onChange={(e) => { setFilterType(e.target.value); setCurrentPage(1); }}
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500, fontFamily: 'inherit' }}
            >
              <option value="">All Types</option>
              <option value="booking">Booking</option>
              <option value="kyc">KYC</option>
              <option value="complaint">Complaint</option>
              <option value="payment">Payment</option>
              <option value="system">System</option>
            </select>
          </div>
        </div>

        {/* Error banner */}
        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, margin: '20px 24px 0', fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
          </div>
        )}

        {/* Table */}
        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 760 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Title</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Type</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Priority</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Date</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Status</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(6)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <Skeleton w="30px" h="30px" radius={15} />
                        <Skeleton w="160px" />
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="70px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="60px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="100px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="55px" radius={12} /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="80px" /></td>
                  </tr>
                ))
              ) : filteredNotifs.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '48px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 36, marginBottom: 10 }}>🔕</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 4 }}>No notifications found</div>
                    <div style={{ fontSize: 12 }}>Try adjusting your filters or wait for new system events.</div>
                  </td>
                </tr>
              ) : (
                filteredNotifs.map(n => {
                  const typeBadge = getTypeBadge(n.type);
                  const priorityBadge = getPriorityBadge(n.priority);
                  return (
                    <tr
                      key={n.id}
                      className="notif-row"
                      style={{
                        borderBottom: '1px solid var(--bg-muted)',
                        background: !n.read ? '#FEFCE8' : 'transparent',
                        transition: 'background 0.15s',
                        cursor: 'pointer',
                      }}
                    >
                      {/* Title + message preview */}
                      <td style={{ padding: '14px 8px' }} onClick={() => handleOpenDetail(n)}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{
                            width: 34, height: 34, borderRadius: '50%',
                            background: typeBadge.bg, color: typeBadge.fg,
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: 16, flexShrink: 0,
                            border: '1px solid var(--border-color)',
                          }}>
                            {typeBadge.icon}
                          </div>
                          <div>
                            <span style={{ fontWeight: !n.read ? 700 : 500, color: 'var(--text-primary)', display: 'block' }}>
                              {n.title || 'Untitled'}
                            </span>
                            <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>
                              {(n.message || '').length > 60
                                ? n.message.substring(0, 60) + '…'
                                : n.message || '—'}
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Type badge */}
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{
                          fontSize: 10, fontWeight: 700, borderRadius: 12,
                          padding: '2px 8px',
                          background: typeBadge.bg,
                          color: typeBadge.fg,
                        }}>
                          {typeBadge.icon} {typeBadge.label}
                        </span>
                      </td>

                      {/* Priority */}
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{
                          fontSize: 10, fontWeight: 700, borderRadius: 12,
                          padding: '2px 8px',
                          background: priorityBadge.bg,
                          color: priorityBadge.fg,
                        }}>
                          {priorityBadge.text}
                        </span>
                      </td>

                      {/* Date */}
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>
                        {formatDate(n.created_at)}
                      </td>

                      {/* Read/Unread badge */}
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <span style={{
                          fontSize: 10, fontWeight: 700, borderRadius: 12,
                          padding: '2px 8px',
                          background: n.read ? 'var(--status-green-bg)' : 'var(--status-amber-bg)',
                          color: n.read ? 'var(--status-green-fg)' : 'var(--status-amber-fg)',
                        }}>
                          {n.read ? '✅ Read' : '📭 Unread'}
                        </span>
                      </td>

                      {/* Actions */}
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
                          <button className="action-btn primary" onClick={() => handleOpenDetail(n)}>
                            View
                          </button>
                          {!n.read && (
                            <button className="action-btn" onClick={() => handleMarkRead(n.id)} disabled={markingRead}>
                              Mark Read
                            </button>
                          )}
                          <button className="action-btn danger" onClick={() => handleDelete(n.id)}>
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {!loading && filteredNotifs.length > 0 && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', borderTop: '0.5px solid var(--bg-muted)' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> (<strong>{totalDocs}</strong> notifications)
            </span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(p => Math.max(p - 1, 1))}
                style={{
                  padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)',
                  background: 'var(--bg-card)', fontSize: 12, fontWeight: 500,
                  color: currentPage === 1 ? 'var(--text-muted)' : 'var(--text-primary)',
                  cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                }}
              >◀ Prev</button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(p => Math.min(p + 1, totalPages))}
                style={{
                  padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)',
                  background: 'var(--bg-card)', fontSize: 12, fontWeight: 500,
                  color: currentPage === totalPages ? 'var(--text-muted)' : 'var(--text-primary)',
                  cursor: currentPage === totalPages ? 'not-allowed' : 'pointer',
                }}
              >Next ▶</button>
            </div>
          </div>
        )}
      </div>

      {/* ── Detail Drawer (same slide-in pattern as KYC) ── */}
      {selectedNotif && (
        <div
          onClick={() => setSelectedNotif(null)}
          style={{
            position: 'fixed', inset: 0,
            backgroundColor: 'rgba(11,15,25,0.4)',
            backdropFilter: 'blur(4px)',
            zIndex: 1000,
            display: 'flex',
            justifyContent: 'flex-end',
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: '100%', maxWidth: 520, height: '100%',
              background: 'var(--bg-card)', borderLeft: '1px solid var(--border-color)',
              display: 'flex', flexDirection: 'column',
              boxShadow: '-4px 0 24px rgba(0,0,0,0.08)',
              animation: 'slideIn 0.25s ease-out forwards',
            }}
          >
            {/* Drawer Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--border-color)' }}>
              <div>
                <span style={{ fontSize: 10, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>
                  NOTIFICATION DETAIL
                </span>
                <h3 style={{ fontSize: 17, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>
                  {selectedNotif.title || 'Untitled Notification'}
                </h3>
              </div>
              <button
                onClick={() => setSelectedNotif(null)}
                style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >✕</button>
            </div>

            {/* Drawer Body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }} className="animate-fade">
              {/* Meta chips */}
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
                {/* Type chip */}
                <span style={{
                  fontSize: 11, fontWeight: 700, borderRadius: 12, padding: '3px 10px',
                  background: getTypeBadge(selectedNotif.type).bg,
                  color: getTypeBadge(selectedNotif.type).fg,
                }}>
                  {getTypeBadge(selectedNotif.type).icon} {getTypeBadge(selectedNotif.type).label}
                </span>
                {/* Priority chip */}
                <span style={{
                  fontSize: 11, fontWeight: 700, borderRadius: 12, padding: '3px 10px',
                  background: getPriorityBadge(selectedNotif.priority).bg,
                  color: getPriorityBadge(selectedNotif.priority).fg,
                }}>
                  {getPriorityBadge(selectedNotif.priority).text}
                </span>
                {/* Read/Unread chip */}
                <span style={{
                  fontSize: 11, fontWeight: 700, borderRadius: 12, padding: '3px 10px',
                  background: selectedNotif.read ? 'var(--status-green-bg)' : 'var(--status-amber-bg)',
                  color: selectedNotif.read ? 'var(--status-green-fg)' : 'var(--status-amber-fg)',
                }}>
                  {selectedNotif.read ? '✅ Read' : '📭 Unread'}
                </span>
              </div>

              {/* Date */}
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 20 }}>
                🕐 Received: <strong>{formatDate(selectedNotif.created_at)}</strong>
              </div>

              {/* Full message */}
              <div style={{
                background: 'var(--bg-app)', border: '1px solid var(--border-color)',
                borderRadius: 12, padding: '16px 18px',
                fontSize: 14, color: 'var(--text-primary)', lineHeight: 1.7,
              }}>
                {selectedNotif.message || 'No message content.'}
              </div>

              {/* Linked entity (if any) */}
              {selectedNotif.entity_id && (
                <div style={{
                  marginTop: 16, background: 'var(--accent-light)', border: '1px solid var(--accent-border)',
                  borderRadius: 10, padding: '12px 16px', fontSize: 13
                }}>
                  <span style={{ color: 'var(--accent-color)', fontWeight: 600 }}>🔗 Linked Record ID:</span>{' '}
                  <strong>#{selectedNotif.entity_id}</strong>
                </div>
              )}
            </div>

            {/* Drawer Footer */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '16px 24px', backgroundColor: '#FAFAFB', display: 'flex', gap: 12 }}>
              <button
                onClick={() => setSelectedNotif(null)}
                style={{
                  flex: 1, padding: '10px 14px', borderRadius: 8,
                  border: '1px solid #D1D5DB', background: 'var(--bg-card)',
                  color: 'var(--text-secondary)', fontSize: 13, fontWeight: 600, cursor: 'pointer',
                }}
              >
                Close
              </button>
              {!selectedNotif.read && (
                <button
                  onClick={() => handleMarkRead(selectedNotif.id)}
                  disabled={markingRead}
                  style={{
                    flex: 2, padding: '10px 14px', borderRadius: 8,
                    border: 'none',
                    background: markingRead ? 'var(--text-muted)' : 'var(--accent-color)',
                    color: 'var(--bg-card)', fontSize: 13, fontWeight: 600,
                    cursor: markingRead ? 'not-allowed' : 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
                  }}
                >
                  {markingRead ? (
                    <>
                      <div style={{ border: '2px solid var(--bg-card)', borderTop: '2px solid transparent', borderRadius: '50%', width: 12, height: 12, animation: 'spin 1s linear infinite' }} />
                      Marking...
                    </>
                  ) : '✅ Mark as Read'}
                </button>
              )}
              <button
                onClick={() => handleDelete(selectedNotif.id)}
                style={{
                  padding: '10px 14px', borderRadius: 8,
                  border: '1px solid #FCA5A5', background: 'var(--status-red-bg)',
                  color: 'var(--status-red-fg)', fontSize: 13, fontWeight: 600, cursor: 'pointer',
                }}
              >
                🗑️ Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmConfig.isOpen}
        title={confirmConfig.title}
        message={confirmConfig.message}
        confirmText={confirmConfig.confirmText}
        variant={confirmConfig.variant}
        onConfirm={confirmConfig.onConfirm}
        onClose={() => setConfirmConfig(prev => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
}
