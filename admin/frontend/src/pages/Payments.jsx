import { useState, useEffect } from 'react';
import { invoicesAPI } from '../api';

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

function StatCard({ label, value, icon, bg, fg, sub, loading }) {
  return (
    <div style={{
      background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12,
      padding: '16px 20px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="80px" h={28} /> : (
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-primary)' }}>{value}</div>
        )}
        {sub && !loading && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 3 }}>{sub}</div>}
      </div>
      <div style={{
        width: 44, height: 44, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

const STATUS_CONFIG = {
  successful: { text: '✅ Successful', bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' },
  failed:     { text: '❌ Failed',     bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' },
  pending:    { text: '⏳ Pending',    bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' },
};

export default function Payments() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const limit = 10;

  const [stats, setStats] = useState({ total: 0, successful: 0, pending: 0, failed: 0, totalAmount: 0 });

  const fetchPayments = () => {
    setLoading(true);
    setError('');
    invoicesAPI.getPayments()
      .then(res => {
        if (res && res.success) {
          const list = res.data || [];
          setPayments(list);
          calcStats(list);
        }
      })
      .catch(err => {
        console.error('Error fetching payments:', err);
        setError(err?.message || 'Failed to load payment transactions.');
      })
      .finally(() => setLoading(false));
  };

  const calcStats = (list) => {
    const successful = list.filter(p => p.status === 'successful');
    setStats({
      total: list.length,
      successful: successful.length,
      pending: list.filter(p => p.status === 'pending').length,
      failed: list.filter(p => p.status === 'failed').length,
      totalAmount: successful.reduce((acc, p) => acc + Number(p.amount || 0), 0),
    });
  };

  useEffect(() => { fetchPayments(); }, []);

  const formatDate = (d) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });

  const filtered = payments.filter(p => {
    const s = search.toLowerCase().trim();
    const matchSearch = !s || (p.user_name || '').toLowerCase().includes(s) ||
      (p.razorpay_order_id || '').toLowerCase().includes(s) ||
      String(p.booking_id || '').includes(s) ||
      (p.service_name || '').toLowerCase().includes(s);
    const matchStatus = !filterStatus || p.status === filterStatus;
    return matchSearch && matchStatus;
  });

  const totalPages = Math.ceil(filtered.length / limit) || 1;
  const paginated = filtered.slice((currentPage - 1) * limit, currentPage * limit);

  useEffect(() => setCurrentPage(1), [search, filterStatus]);

  const handleExportCSV = () => {
    const rows = [['ID', 'Booking ID', 'Customer', 'Service', 'Razorpay Order ID', 'Amount', 'Status', 'Date']];
    filtered.forEach(p => rows.push([
      p.id, p.booking_id, p.user_name || 'Customer',
      p.service_name || 'Home Service', p.razorpay_order_id,
      Number(p.amount || 0).toFixed(2), p.status,
      formatDate(p.created_at),
    ]));
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.download = 'payments.csv'; a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        .pay-row { transition: background 0.1s; }
        .pay-row:hover { background: var(--bg-app); }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Payment Transactions</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Monitor digital payment receipts, Razorpay order states, and verify customer payments.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={handleExportCSV}
            style={{ background: 'var(--bg-card)', border: '1px solid #D1D5DB', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: 6 }}
          >
            📥 Export CSV
          </button>
          <button
            onClick={fetchPayments}
            style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--bg-card)', display: 'flex', alignItems: 'center', gap: 6 }}
          >
            🔄 Refresh
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard label="Total Transactions" value={stats.total} icon="💳" bg="var(--accent-light)" fg="var(--accent-color)" loading={loading} />
        <StatCard label="Successful" value={stats.successful} icon="✅" bg="var(--status-green-bg)" fg="var(--status-green-fg)" loading={loading} />
        <StatCard label="Pending" value={stats.pending} icon="⏳" bg="var(--status-amber-bg)" fg="var(--status-amber-fg)" loading={loading} />
        <StatCard label="Failed" value={stats.failed} icon="❌" bg="#FEF2F2" fg="var(--status-red-fg)" loading={loading} />
        <StatCard label="Revenue Collected" value={formatINR(stats.totalAmount)} icon="💰" bg="var(--status-green-bg)" fg="var(--status-green-fg)" sub="from successful payments" loading={loading} />
      </div>

      {/* Table Container */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

        {/* Controls */}
        <div style={{ padding: '16px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: 240, maxWidth: 380 }}>
            <input
              type="text"
              placeholder="Search by customer, service, or order ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '8px 12px 8px 34px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', fontFamily: 'inherit', boxSizing: 'border-box' }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 14 }}>🔍</span>
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontFamily: 'inherit', fontWeight: 500 }}
          >
            <option value="">All Statuses</option>
            <option value="successful">Successful</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
          {(search || filterStatus) && (
            <button
              onClick={() => { setSearch(''); setFilterStatus(''); }}
              style={{ border: 'none', background: 'none', color: 'var(--text-secondary)', fontSize: 12, cursor: 'pointer', textDecoration: 'underline' }}
            >
              Clear filters
            </button>
          )}
          <span style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--text-secondary)' }}>
            {filtered.length} result{filtered.length !== 1 ? 's' : ''}
          </span>
        </div>

        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', margin: '16px 24px 0', borderRadius: 8, fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
            <button onClick={fetchPayments} style={{ marginLeft: 12, background: 'none', border: 'none', color: 'var(--status-red-fg)', cursor: 'pointer', textDecoration: 'underline', fontSize: 12 }}>Retry</button>
          </div>
        )}

        {/* Table */}
        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 900 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px' }}>Payment ID</th>
                <th style={{ padding: '14px 8px' }}>Booking / Service</th>
                <th style={{ padding: '14px 8px' }}>Customer</th>
                <th style={{ padding: '14px 8px' }}>Razorpay Order ID</th>
                <th style={{ padding: '14px 8px' }}>Amount</th>
                <th style={{ padding: '14px 8px', textAlign: 'center' }}>Status</th>
                <th style={{ padding: '14px 8px' }}>Date</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(5)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="50px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="140px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="110px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="160px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="70px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="80px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="120px" /></td>
                  </tr>
                ))
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '48px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 36, marginBottom: 10 }}>💳</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 4 }}>
                      {search || filterStatus ? 'No matching transactions found' : 'No payment transactions yet'}
                    </div>
                    <div style={{ fontSize: 12 }}>
                      {search || filterStatus ? 'Try adjusting your filters.' : 'Payments will appear here once bookings are initiated.'}
                    </div>
                  </td>
                </tr>
              ) : (
                paginated.map(p => {
                  const badge = STATUS_CONFIG[p.status] || STATUS_CONFIG.pending;
                  return (
                    <tr key={p.id} className="pay-row" style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                      <td style={{ padding: '14px 8px', fontWeight: 700, color: 'var(--text-primary)' }}>#{p.id}</td>
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{ fontWeight: 500, color: 'var(--text-primary)' }}>{p.service_name || 'Home Service'}</span>
                        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Booking #{p.booking_id}</div>
                      </td>
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <div style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                            {(p.user_name || 'C')[0].toUpperCase()}
                          </div>
                          <span>{p.user_name || 'Customer'}</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)', fontFamily: 'monospace', fontSize: 11 }}>
                        {p.razorpay_order_id ? (
                          <span title={p.razorpay_order_id}>
                            {p.razorpay_order_id.length > 22 ? p.razorpay_order_id.substring(0, 22) + '…' : p.razorpay_order_id}
                          </span>
                        ) : '—'}
                      </td>
                      <td style={{ padding: '14px 8px', fontWeight: 700, color: 'var(--status-green-fg)' }}>
                        {formatINR(p.amount)}
                      </td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <span style={{
                          display: 'inline-flex', alignItems: 'center', fontSize: 11, borderRadius: 20,
                          padding: '3px 10px', fontWeight: 700, backgroundColor: badge.bg, color: badge.fg,
                        }}>
                          {badge.text}
                        </span>
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)', fontSize: 12 }}>{formatDate(p.created_at)}</td>
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
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> · <strong>{filtered.length}</strong> records
            </span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)', background: 'var(--bg-card)', color: currentPage === 1 ? 'var(--text-muted)' : 'var(--text-primary)', fontSize: 12, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}>
                ◀ Prev
              </button>
              <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => p + 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid var(--border-color)', background: 'var(--bg-card)', color: currentPage === totalPages ? 'var(--text-muted)' : 'var(--text-primary)', fontSize: 12, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}>
                Next ▶
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
