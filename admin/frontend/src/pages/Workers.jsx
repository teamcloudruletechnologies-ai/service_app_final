import { useState, useEffect } from 'react';
import { workersAPI } from '../api';

function Skeleton({ w = '100%', h = 16, radius = 6 }) {
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: 'linear-gradient(90deg,#F3F4F6 25%,#E5E7EB 50%,#F3F4F6 75%)',
      backgroundSize: '200% 100%',
      animation: 'shimmer 1.4s infinite',
    }} />
  );
}

function StatCard({ label, value, icon, bg, fg, loading }) {
  return (
    <div style={{
      background: '#fff', border: '0.5px solid #E5E7EB', borderRadius: 12,
      padding: '16px 20px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 12, color: '#6B7280', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="60px" h={28} /> : (
          <div style={{ fontSize: 24, fontWeight: 700, color: '#111827' }}>{value}</div>
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
        <span key={i} style={{ color: i <= Math.round(r) ? '#FBBF24' : '#E5E7EB', fontSize: 12 }}>★</span>
      ))}
      <span style={{ fontSize: 11, color: '#6B7280', marginLeft: 3 }}>{r.toFixed(1)}</span>
    </div>
  );
}

const STATUS_BADGE = {
  active: { text: '🟢 Active', bg: '#D1FAE5', fg: '#065F46' },
  inactive: { text: '🟡 Inactive', bg: '#FFFBEB', fg: '#D97706' },
  suspended: { text: '🔴 Suspended', bg: '#FEE2E2', fg: '#991B1B' },
};

export default function Workers() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [performance, setPerformance] = useState(null);
  const [actionLoading, setActionLoading] = useState('');

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

  const handleAction = async (action) => {
    if (!selectedWorker) return;
    setActionLoading(action);
    try {
      if (action === 'activate') await workersAPI.activate(selectedWorker.id);
      else if (action === 'suspend') await workersAPI.suspend(selectedWorker.id);
      else if (action === 'delete') {
        if (!window.confirm(`Delete worker "${selectedWorker.name}"? This cannot be undone.`)) {
          setActionLoading('');
          return;
        }
        await workersAPI.delete(selectedWorker.id);
        closeDrawer();
      }
      await fetchWorkers();
      if (action !== 'delete') {
        setSelectedWorker(prev => ({ ...prev, status: action === 'activate' ? 'active' : 'suspended' }));
      }
    } catch (err) {
      alert(err?.message || `Failed to ${action} worker`);
    } finally {
      setActionLoading('');
    }
  };

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
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: '#F9FAFB', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        @keyframes slideIn { from { transform: translateX(100%); } to { transform: translateX(0); } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
        .wrow { transition: background 0.1s; cursor: pointer; }
        .wrow:hover { background: #F9FAFB; }
        .action-btn { border: 1px solid; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.15s; font-family: inherit; }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: '#111827', margin: 0 }}>Workers Management</h2>
          <p style={{ fontSize: 12, color: '#6B7280', margin: '4px 0 0' }}>
            Manage field workers — approve, suspend, view performance and KYC status.
          </p>
        </div>
        <button
          onClick={fetchWorkers}
          style={{ background: '#1A56DB', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
        >
          🔄 Refresh
        </button>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard label="Total Workers" value={stats.total} icon="👷" bg="#EFF4FF" fg="#1A56DB" loading={loading} />
        <StatCard label="Active" value={stats.active} icon="🟢" bg="#F0FDF4" fg="#059669" loading={loading} />
        <StatCard label="Suspended" value={stats.suspended} icon="🔴" bg="#FEF2F2" fg="#DC2626" loading={loading} />
        <StatCard label="Inactive" value={stats.inactive} icon="🟡" bg="#FFFBEB" fg="#D97706" loading={loading} />
      </div>

      {/* Table Card */}
      <div style={{ background: '#fff', border: '0.5px solid #E5E7EB', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

        {/* Controls */}
        <div style={{ padding: '16px 24px', borderBottom: '0.5px solid #E5E7EB', display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: 240, maxWidth: 380 }}>
            <input
              type="text" placeholder="Search by name, email, or service..."
              value={search} onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '8px 12px 8px 34px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', fontFamily: 'inherit', boxSizing: 'border-box' }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#9CA3AF', fontSize: 14 }}>🔍</span>
          </div>
          <select
            value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}
            style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: '#374151', outline: 'none', fontFamily: 'inherit', fontWeight: 500 }}
          >
            <option value="">All Statuses</option>
            <option value="active">Active Only</option>
            <option value="suspended">Suspended Only</option>
            <option value="inactive">Inactive Only</option>
          </select>
          {(search || filterStatus) && (
            <button onClick={() => { setSearch(''); setFilterStatus(''); }}
              style={{ border: 'none', background: 'none', color: '#6B7280', fontSize: 12, cursor: 'pointer', textDecoration: 'underline' }}>
              Clear filters
            </button>
          )}
          <span style={{ marginLeft: 'auto', fontSize: 12, color: '#6B7280' }}>{filtered.length} workers</span>
        </div>

        {error && (
          <div style={{ background: '#FEE2E2', border: '1px solid #FCA5A5', color: '#991B1B', padding: '12px 16px', margin: '16px 24px 0', borderRadius: 8, fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
            <button onClick={fetchWorkers} style={{ marginLeft: 12, background: 'none', border: 'none', color: '#991B1B', cursor: 'pointer', textDecoration: 'underline', fontSize: 12 }}>Retry</button>
          </div>
        )}

        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E5E7EB', color: '#4B5563', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
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
            <tbody style={{ fontSize: 13, color: '#374151' }}>
              {loading ? (
                [...Array(5)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid #F3F4F6' }}>
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
                  <td colSpan="8" style={{ textAlign: 'center', padding: '48px 0', color: '#9CA3AF' }}>
                    <div style={{ fontSize: 36, marginBottom: 10 }}>👷</div>
                    <div style={{ fontWeight: 600, color: '#4B5563', marginBottom: 4 }}>
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
                    ? { text: '✅ Approved', bg: '#D1FAE5', fg: '#065F46' }
                    : w.kyc_status === 'rejected'
                    ? { text: '❌ Rejected', bg: '#FEE2E2', fg: '#991B1B' }
                    : w.kyc_status === 'pending'
                    ? { text: '⏳ Pending', bg: '#FFFBEB', fg: '#D97706' }
                    : { text: '— Not Submitted', bg: '#F3F4F6', fg: '#6B7280' };
                  return (
                    <tr key={w.id} className="wrow" style={{ borderBottom: '1px solid #F3F4F6' }}>
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 34, height: 34, borderRadius: '50%', background: '#EFF4FF', color: '#1A56DB', fontWeight: 700, fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #E5E7EB', flexShrink: 0 }}>
                            {(w.name || 'W')[0].toUpperCase()}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, color: '#111827' }}>{w.name}</div>
                            <div style={{ fontSize: 11, color: '#9CA3AF' }}>ID #{w.id}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: '#4B5563' }}>
                        <div>{w.email}</div>
                        <div style={{ fontSize: 11, color: '#9CA3AF' }}>{w.phone || '—'}</div>
                      </td>
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{ fontSize: 12, background: '#F3F4F6', padding: '3px 8px', borderRadius: 6, color: '#374151', fontWeight: 500 }}>
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
                      <td style={{ padding: '14px 8px', color: '#6B7280', fontSize: 12 }}>{formatDate(w.created_at)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <button
                          onClick={() => openDrawer(w)}
                          className="action-btn"
                          style={{ borderColor: '#1A56DB', color: '#1A56DB', background: '#fff' }}
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
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '0.5px solid #F3F4F6' }}>
            <span style={{ fontSize: 12, color: '#6B7280' }}>Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> · <strong>{filtered.length}</strong> workers</span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid #E5E7EB', background: '#fff', color: currentPage === 1 ? '#9CA3AF' : '#374151', fontSize: 12, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}>◀ Prev</button>
              <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => p + 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid #E5E7EB', background: '#fff', color: currentPage === totalPages ? '#9CA3AF' : '#374151', fontSize: 12, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}>Next ▶</button>
            </div>
          </div>
        )}
      </div>

      {/* Detail Drawer */}
      {selectedWorker && (
        <div onClick={closeDrawer} style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(11,15,25,0.4)', backdropFilter: 'blur(4px)', zIndex: 1000, display: 'flex', justifyContent: 'flex-end' }}>
          <div onClick={(e) => e.stopPropagation()} style={{ width: '100%', maxWidth: 560, height: '100%', background: '#fff', borderLeft: '1px solid #E5E7EB', display: 'flex', flexDirection: 'column', boxShadow: '-4px 0 24px rgba(0,0,0,0.08)', animation: 'slideIn 0.25s ease-out' }}>

            {/* Drawer Header */}
            <div style={{ padding: '20px 24px', borderBottom: '1px solid #E5E7EB', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <span style={{ fontSize: 10, background: '#EFF4FF', color: '#1A56DB', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>WORKER PROFILE</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: '#111827', margin: '4px 0 0' }}>{selectedWorker.name}</h3>
              </div>
              <button onClick={closeDrawer} style={{ background: 'none', border: 'none', fontSize: 20, color: '#9CA3AF', cursor: 'pointer', padding: 4 }}>✕</button>
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
                  <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '16px', background: 'linear-gradient(135deg, #EFF4FF, #F0FDF4)', borderRadius: 12 }}>
                    <div style={{ width: 60, height: 60, borderRadius: '50%', background: '#1A56DB', color: '#fff', fontSize: 24, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {(selectedWorker.name || 'W')[0].toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: 18, color: '#111827' }}>{selectedWorker.name}</div>
                      <StarRating rating={selectedWorker.rating} />
                      <div style={{ fontSize: 11, color: '#6B7280', marginTop: 4 }}>{selectedWorker.service_type || 'General Service'}</div>
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
                      <div key={label} style={{ background: '#F9FAFB', borderRadius: 8, padding: '10px 14px', border: '1px solid #E5E7EB' }}>
                        <div style={{ fontSize: 11, color: '#6B7280', fontWeight: 600, marginBottom: 2 }}>{label}</div>
                        <div style={{ fontSize: 13, fontWeight: 600, color: '#111827' }}>{value}</div>
                      </div>
                    ))}
                  </div>

                  {/* Performance Stats */}
                  {performance && (
                    <div>
                      <div style={{ fontSize: 12, fontWeight: 700, color: '#4B5563', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 10 }}>Performance</div>
                      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                        {[
                          { label: 'Completed Jobs', value: performance.completed_jobs || '—' },
                          { label: 'Total Earnings', value: performance.total_earnings ? `₹${Number(performance.total_earnings).toLocaleString('en-IN')}` : '—' },
                          { label: 'Avg Rating', value: performance.avg_rating ? `${Number(performance.avg_rating).toFixed(1)} ★` : '—' },
                        ].map(({ label, value }) => (
                          <div key={label} style={{ background: '#EFF4FF', borderRadius: 8, padding: '10px', textAlign: 'center' }}>
                            <div style={{ fontSize: 11, color: '#1A56DB', fontWeight: 600, marginBottom: 4 }}>{label}</div>
                            <div style={{ fontSize: 16, fontWeight: 700, color: '#111827' }}>{value}</div>
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
                        style={{ borderColor: '#059669', color: '#059669', background: '#F0FDF4', flex: 1 }}
                      >
                        {actionLoading === 'activate' ? '⏳ Activating...' : '✅ Activate Worker'}
                      </button>
                    )}
                    {selectedWorker.status !== 'suspended' && (
                      <button
                        className="action-btn"
                        onClick={() => handleAction('suspend')}
                        disabled={!!actionLoading}
                        style={{ borderColor: '#D97706', color: '#D97706', background: '#FFFBEB', flex: 1 }}
                      >
                        {actionLoading === 'suspend' ? '⏳ Suspending...' : '⚠️ Suspend Worker'}
                      </button>
                    )}
                    <button
                      className="action-btn"
                      onClick={() => handleAction('delete')}
                      disabled={!!actionLoading}
                      style={{ borderColor: '#DC2626', color: '#DC2626', background: '#FEF2F2', flex: 1 }}
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
    </div>
  );
}
