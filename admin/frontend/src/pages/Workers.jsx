import { useState, useEffect } from 'react';
import { workersAPI } from '../api';
import { toast } from 'react-toastify';
import ConfirmModal from '../components/ConfirmModal';

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
      padding: '16px 20px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="60px" h={28} /> : (
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 44, height: 44, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

function StarRating({ rating }) {
  const r = parseFloat(rating) || 0;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
      {[1, 2, 3, 4, 5].map(i => (
        <span key={i} style={{ color: i <= Math.round(r) ? '#FBBF24' : 'var(--border-color)', fontSize: 12 }}>★</span>
      ))}
      <span style={{ fontSize: 11, color: 'var(--text-secondary)', marginLeft: 3 }}>{r.toFixed(1)}</span>
    </div>
  );
}

const STATUS_BADGE = {
  active: { text: '🟢 Active', bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' },
  inactive: { text: '🟡 Inactive', bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' },
  suspended: { text: '🔴 Suspended', bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' },
};

export default function Workers() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [performance, setPerformance] = useState(null);
  const [actionLoading, setActionLoading] = useState('');
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });

  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const limit = 10;

  const [stats, setStats] = useState({ total: 0, active: 0, suspended: 0, inactive: 0 });

  const fetchWorkers = () => {
    setLoading(true);
    setError('');
    workersAPI.getAll()
      .then(res => {
        const list = res?.data?.rows || res?.data?.data || res?.data || [];
        setWorkers(list);
        calcStats(list);
      })
      .catch(err => {
        console.error('Failed to fetch workers', err);
        setError(err?.message || 'Failed to load workers.');
      })
      .finally(() => setLoading(false));
  };

  const calcStats = (list) => {
    setStats({
      total: list.length,
      active: list.filter(w => w.status === 'active').length,
      suspended: list.filter(w => w.status === 'suspended').length,
      inactive: list.filter(w => w.status === 'inactive').length,
    });
  };

  useEffect(() => { fetchWorkers(); }, []);

  const openDrawer = (worker) => {
    setSelectedWorker(worker);
    setPerformance(null);
    setDrawerLoading(true);
    workersAPI.getById(worker.id)
      .then(res => {
        if (res?.success && res?.data) setSelectedWorker(res.data);
      })
      .catch(console.error)
      .finally(() => setDrawerLoading(false));
    workersAPI.getPerformance(worker.id)
      .then(res => setPerformance(res?.data || null))
      .catch(() => setPerformance(null));
  };

  const closeDrawer = () => {
    setSelectedWorker(null);
    setPerformance(null);
  };

  const executeWorkerAction = async (action) => {
    setActionLoading(action);
    try {
      if (action === 'activate') await workersAPI.activate(selectedWorker.id);
      else if (action === 'suspend') await workersAPI.suspend(selectedWorker.id);
      else if (action === 'delete') {
        await workersAPI.delete(selectedWorker.id);
        closeDrawer();
      }
      await fetchWorkers();
      if (action !== 'delete') {
        setSelectedWorker(prev => ({ ...prev, status: action === 'activate' ? 'active' : 'suspended' }));
        toast.success(`Worker ${action}d successfully!`);
      } else {
        toast.success('Worker deleted successfully!');
      }
    } catch (err) {
      toast.error(err?.message || `Failed to ${action} worker`);
    } finally {
      setActionLoading('');
    }
  };

  const handleWorkerAction = (action) => {
    if (!selectedWorker) return;
    if (action === 'delete') {
      setConfirmConfig({
        isOpen: true,
        title: 'Delete Service Provider Account',
        message: `Delete worker "${selectedWorker.name}"? This cannot be undone.`,
        confirmText: 'Delete Worker',
        variant: 'danger',
        onConfirm: () => {
          setConfirmConfig(prev => ({ ...prev, isOpen: false }));
          executeWorkerAction(action);
        }
      });
    } else {
      executeWorkerAction(action);
    }
  };

  const handleAction = handleWorkerAction;

  const filtered = workers.filter(w => {
    const s = search.toLowerCase().trim();
    const matchSearch = !s ||
      (w.name || '').toLowerCase().includes(s) ||
      (w.email || '').toLowerCase().includes(s) ||
      (w.phone || '').toLowerCase().includes(s) ||
      (w.service_type || '').toLowerCase().includes(s);
    const matchStatus = !filterStatus || w.status === filterStatus;
    return matchSearch && matchStatus;
  });

  const totalPages = Math.ceil(filtered.length / limit) || 1;
  const paginated = filtered.slice((currentPage - 1) * limit, currentPage * limit);
  useEffect(() => setCurrentPage(1), [search, filterStatus]);

  const formatDate = (d) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        @keyframes slideIn { from { transform: translateX(100%); } to { transform: translateX(0); } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
        .wrow { transition: background 0.1s; cursor: pointer; }
        .wrow:hover { background: var(--bg-app); }
        .action-btn { border: 1px solid; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.15s; font-family: inherit; }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Workers Management</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Manage field workers — approve, suspend, view performance and KYC status.
          </p>
        </div>
        <button
          onClick={fetchWorkers}
          style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--bg-card)' }}
        >
          🔄 Refresh
        </button>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard label="Total Workers" value={stats.total} icon="👷" bg="var(--accent-light)" fg="var(--accent-color)" loading={loading} />
        <StatCard label="Active" value={stats.active} icon="🟢" bg="var(--status-green-bg)" fg="var(--status-green-fg)" loading={loading} />
        <StatCard label="Suspended" value={stats.suspended} icon="🔴" bg="#FEF2F2" fg="var(--status-red-fg)" loading={loading} />
        <StatCard label="Inactive" value={stats.inactive} icon="🟡" bg="var(--status-amber-bg)" fg="var(--status-amber-fg)" loading={loading} />
      </div>

      {/* Table Card */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

        {/* Controls */}
        <div style={{ padding: '16px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: 240, maxWidth: 380 }}>
            <input
              type="text" placeholder="Search by name, email, or service..."
              value={search} onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '8px 12px 8px 34px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', fontFamily: 'inherit', boxSizing: 'border-box' }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14 }}>🔍</span>
          </div>
          <select
            value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}
            style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontFamily: 'inherit', fontWeight: 500 }}
          >
            <option value="">All Statuses</option>
            <option value="active">Active Only</option>
            <option value="suspended">Suspended Only</option>
            <option value="inactive">Inactive Only</option>
          </select>
          {(search || filterStatus) && (
            <button onClick={() => { setSearch(''); setFilterStatus(''); }}
              style={{ border: 'none', background: 'none', color: 'var(--text-secondary)', fontSize: 12, cursor: 'pointer', textDecoration: 'underline' }}>
              Clear filters
            </button>
          )}
          <span style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--text-secondary)' }}>{filtered.length} workers</span>
        </div>

        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', margin: '16px 24px 0', borderRadius: 8, fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
            <button onClick={fetchWorkers} style={{ marginLeft: 12, background: 'none', border: 'none', color: 'var(--status-red-fg)', cursor: 'pointer', textDecoration: 'underline', fontSize: 12 }}>Retry</button>
          </div>
        )}

        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px' }}>Worker</th>
                <th style={{ padding: '14px 8px' }}>Contact</th>
                <th style={{ padding: '14px 8px' }}>Service Type</th>
                <th style={{ padding: '14px 8px' }}>Rating</th>
                <th style={{ padding: '14px 8px' }}>KYC</th>
                <th style={{ padding: '14px 8px', textAlign: 'center' }}>Status</th>
                <th style={{ padding: '14px 8px' }}>Joined</th>
                <th style={{ padding: '14px 8px', textAlign: 'center' }}>Actions</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(5)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="150px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="130px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="100px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="70px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="80px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="80px" /></td>
                  </tr>
                ))
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '48px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 36, marginBottom: 10 }}>👷</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 4 }}>
                      {search || filterStatus ? 'No matching workers' : 'No workers registered yet'}
                    </div>
                    <div style={{ fontSize: 12 }}>
                      {search || filterStatus ? 'Try adjusting your filters.' : 'Workers will appear here once they register.'}
                    </div>
                  </td>
                </tr>
              ) : (
                paginated.map(w => {
                  const badge = STATUS_BADGE[w.status] || STATUS_BADGE.inactive;
                  const kycBadge = w.kyc_status === 'approved'
                    ? { text: '✅ Approved', bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' }
                    : w.kyc_status === 'rejected'
                    ? { text: '❌ Rejected', bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' }
                    : w.kyc_status === 'pending'
                    ? { text: '⏳ Pending', bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' }
                    : { text: '— Not Submitted', bg: 'var(--bg-muted)', fg: 'var(--text-secondary)' };
                  return (
                    <tr key={w.id} className="wrow" style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border-color)', flexShrink: 0 }}>
                            {(w.name || 'W')[0].toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{w.name}</div>
                            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>ID #{w.id}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>
                        <div>{w.email}</div>
                        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{w.phone || '—'}</div>
                      </td>
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{ fontSize: 12, background: 'var(--bg-muted)', padding: '3px 8px', borderRadius: 6, color: 'var(--text-primary)', fontWeight: 500 }}>
                          {w.service_type || '—'}
                        </span>
                      </td>
                      <td style={{ padding: '14px 8px' }}><StarRating rating={w.rating} /></td>
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{ fontSize: 11, borderRadius: 12, padding: '2px 8px', fontWeight: 700, backgroundColor: kycBadge.bg, color: kycBadge.fg }}>
                          {kycBadge.text}
                        </span>
                      </td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <span style={{ fontSize: 11, borderRadius: 20, padding: '3px 10px', fontWeight: 700, backgroundColor: badge.bg, color: badge.fg }}>
                          {badge.text}
                        </span>
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)', fontSize: 12 }}>{formatDate(w.created_at)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <button
                          onClick={() => openDrawer(w)}
                          className="action-btn"
                          style={{ borderColor: 'var(--accent-color)', color: 'var(--accent-color)', background: 'var(--bg-card)' }}
                        >
                          View
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
        {!loading && filtered.length > limit && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '0.5px solid var(--bg-muted)' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> · <strong>{filtered.length}</strong> workers</span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)', background: 'var(--bg-card)', color: currentPage === 1 ? 'var(--text-muted)' : 'var(--text-primary)', fontSize: 12, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}>◀ Prev</button>
              <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => p + 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)', background: 'var(--bg-card)', color: currentPage === totalPages ? 'var(--text-muted)' : 'var(--text-primary)', fontSize: 12, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}>Next ▶</button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Drawer */}
      {selectedWorker && (
        <div onClick={closeDrawer} style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(11,15,25,0.4)', backdropFilter: 'blur(4px)', zIndex: 1000, display: 'flex', justifyContent: 'flex-end' }}>
          <div onClick={(e) => e.stopPropagation()} style={{ width: '100%', maxWidth: 560, height: '100%', background: 'var(--bg-card)', borderLeft: '1px solid var(--border-color)', display: 'flex', flexDirection: 'column', boxShadow: '-4px 0 24px rgba(0,0,0,0.08)', animation: 'slideIn 0.25s ease-out' }}>

            {/* Drawer Header */}
            <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <span style={{ fontSize: 10, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>WORKER PROFILE</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>{selectedWorker.name}</h3>
              </div>
              <button onClick={closeDrawer} style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}>✕</button>
            </div>

            {/* Drawer Body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
              {drawerLoading ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {[...Array(6)].map((_, i) => <Skeleton key={i} h={20} />)}
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16, animation: 'fadeIn 0.2s ease-out' }}>
                  {/* Avatar + Name */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '16px', background: 'linear-gradient(135deg, var(--accent-light), var(--status-green-bg))', borderRadius: 12 }}>
                    <div style={{ width: 60, height: 60, borderRadius: '50%', background: 'var(--accent-color)', color: 'var(--bg-card)', fontSize: 24, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {(selectedWorker.name || 'W')[0].toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 18, color: 'var(--text-primary)' }}>{selectedWorker.name}</div>
                      <StarRating rating={selectedWorker.rating} />
                      <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 4 }}>{selectedWorker.service_type || 'General Service'}</div>
                    </div>
                  </div>

                  {/* Info Grid */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                    {[
                      { label: '📧 Email', value: selectedWorker.email },
                      { label: '📞 Phone', value: selectedWorker.phone || '—' },
                      { label: '🏙️ City', value: selectedWorker.city || '—' },
                      { label: '📍 State', value: selectedWorker.state || '—' },
                      { label: '📮 Pincode', value: selectedWorker.pincode || '—' },
                      { label: '🔧 Experience', value: selectedWorker.experience_years ? `${selectedWorker.experience_years} yrs` : '—' },
                    ].map(({ label, value }) => (
                      <div key={label} style={{ background: 'var(--bg-app)', borderRadius: 8, padding: '10px 14px', border: '1px solid var(--border-color)' }}>
                        <div style={{ fontSize: 11, color: 'var(--text-secondary)', fontWeight: 600, marginBottom: 2 }}>{label}</div>
                        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>{value}</div>
                      </div>
                    ))}
                  </div>

                  {/* Performance Stats */}
                  {performance && (
                    <div>
                      <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 10 }}>Performance</div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                        {[
                          { label: 'Completed Jobs', value: performance.completed_jobs || '—' },
                          { label: 'Total Earnings', value: performance.total_earnings ? `₹${Number(performance.total_earnings).toLocaleString('en-IN')}` : '—' },
                          { label: 'Avg Rating', value: performance.avg_rating ? `${Number(performance.avg_rating).toFixed(1)} ★` : '—' },
                        ].map(({ label, value }) => (
                          <div key={label} style={{ background: 'var(--accent-light)', borderRadius: 8, padding: '10px', textAlign: 'center' }}>
                            <div style={{ fontSize: 11, color: 'var(--accent-color)', fontWeight: 600, marginBottom: 4 }}>{label}</div>
                            <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--text-primary)' }}>{value}</div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', paddingTop: 8 }}>
                    {selectedWorker.status !== 'active' && (
                      <button
                        className="action-btn"
                        onClick={() => handleAction('activate')}
                        disabled={!!actionLoading}
                        style={{ borderColor: 'var(--status-green-fg)', color: 'var(--status-green-fg)', background: 'var(--status-green-bg)', flex: 1 }}
                      >
                        {actionLoading === 'activate' ? '⏳ Activating...' : '✅ Activate Worker'}
                      </button>
                    )}
                    {selectedWorker.status !== 'suspended' && (
                      <button
                        className="action-btn"
                        onClick={() => handleAction('suspend')}
                        disabled={!!actionLoading}
                        style={{ borderColor: 'var(--status-amber-fg)', color: 'var(--status-amber-fg)', background: 'var(--status-amber-bg)', flex: 1 }}
                      >
                        {actionLoading === 'suspend' ? '⏳ Suspending...' : '⚠️ Suspend Worker'}
                      </button>
                    )}
                    <button
                      className="action-btn"
                      onClick={() => handleAction('delete')}
                      disabled={!!actionLoading}
                      style={{ borderColor: 'var(--status-red-fg)', color: 'var(--status-red-fg)', background: '#FEF2F2', flex: 1 }}
                    >
                      {actionLoading === 'delete' ? '⏳ Deleting...' : '🗑️ Delete Worker'}
                    </button>
                  </div>
                </div>
              )}
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
