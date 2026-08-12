import { useState, useEffect } from 'react';
import { invoicesAPI, settlementsAPI } from '../api';

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
      padding: '18px 22px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="80px" h={28} /> : (
          <div style={{ fontSize: 26, fontWeight: 800, color: 'var(--text-primary)' }}>{value}</div>
        )}
        {sub && !loading && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 3 }}>{sub}</div>}
      </div>
      <div style={{
        width: 46, height: 46, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

const RAINBOW_PALETTES = [
  { front: '#3562D6', top: '#6B93F7', side: '#2345A1', glow: 'rgba(53,98,214,0.35)' },
  { front: '#BA46D6', top: '#E388F7', side: '#8B24A3', glow: 'rgba(186,70,214,0.35)' },
  { front: '#3FB5F2', top: '#82D7FF', side: '#1E83B8', glow: 'rgba(63,181,242,0.35)' },
  { front: '#14B8A6', top: '#5EEAD4', side: '#0F766E', glow: 'rgba(20,184,166,0.35)' },
  { front: '#84CC16', top: '#BEF264', side: '#4D7C0F', glow: 'rgba(132,204,22,0.35)' },
  { front: '#F59E0B', top: '#FCD34D', side: '#B45309', glow: 'rgba(245,158,11,0.35)' },
  { front: '#F43F5E', top: '#FDA4AF', side: '#BE123C', glow: 'rgba(244,63,94,0.35)' },
  { front: '#EAB308', top: '#FEF08A', side: '#A16207', glow: 'rgba(234,179,8,0.35)' },
];

function ThreeDBarChart({ title, data = [], height = 220 }) {
  const maxVal = Math.max(...data.map(d => Number(d.value || 0)), 100);

  return (
    <div style={{ background: 'var(--bg-card)', padding: '24px 28px', borderRadius: 16, border: '1px solid var(--border-color)', marginTop: 24, boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
      <h4 style={{ fontSize: 16, fontWeight: 800, margin: '0 0 20px', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: 8 }}>
        📊 {title}
      </h4>

      {data.length === 0 ? (
        <div style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)', fontSize: 13 }}>No chart data available for visualization.</div>
      ) : (
        <div style={{ display: 'flex', gap: 24, alignItems: 'flex-end', height: height, paddingTop: 30, paddingBottom: 16, overflowX: 'auto' }}>
          {data.map((d, idx) => {
            const pct = Math.max((Number(d.value || 0) / maxVal) * 100, 12);
            const palette = RAINBOW_PALETTES[idx % RAINBOW_PALETTES.length];

            return (
              <div key={idx} style={{ flex: 1, minWidth: 68, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%', justifyContent: 'flex-end' }}>
                <div style={{ fontSize: 12, fontWeight: 800, color: palette.front, marginBottom: 8 }}>
                  ₹{Math.round(d.value || 0).toLocaleString()}
                </div>

                {/* 3D Glossy Pillar Element matching reference image */}
                <div style={{
                  position: 'relative',
                  width: '52%',
                  maxWidth: 42,
                  height: `${pct}%`,
                  transition: 'height 0.7s cubic-bezier(0.34, 1.56, 0.64, 1)',
                  filter: `drop-shadow(0 8px 14px ${palette.glow})`
                }}>
                  {/* Top Face */}
                  <div style={{
                    position: 'absolute', top: -8, left: 0, right: 0, height: 12,
                    background: `linear-gradient(135deg, #FFFFFF 0%, ${palette.top} 80%)`,
                    borderRadius: '8px 8px 0 0',
                    transform: 'skewX(-18deg)', transformOrigin: 'bottom left',
                    boxShadow: 'inset 0 1px 2px rgba(255,255,255,0.8)'
                  }} />
                  {/* Front Face with Specular Gloss Overlay */}
                  <div style={{
                    position: 'absolute', inset: 0,
                    background: `linear-gradient(180deg, ${palette.top} 0%, ${palette.front} 100%)`,
                    borderRadius: '3px 3px 6px 6px',
                    overflow: 'hidden'
                  }}>
                    {/* Gloss Specular Highlight Line */}
                    <div style={{
                      position: 'absolute', top: 0, left: 0, width: '40%', height: '100%',
                      background: 'linear-gradient(90deg, rgba(255,255,255,0.45) 0%, rgba(255,255,255,0) 100%)'
                    }} />
                  </div>
                  {/* Side Face (Isometric Shadow Depth) */}
                  <div style={{
                    position: 'absolute', top: -8, bottom: 0, right: -8, width: 8,
                    background: `linear-gradient(180deg, ${palette.side} 0%, rgba(0,0,0,0.4) 100%)`,
                    borderRadius: '0 8px 8px 0',
                    transform: 'skewY(-18deg)', transformOrigin: 'top left'
                  }} />
                </div>

                <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 12, fontWeight: 700, textAlign: 'center', maxWidth: 85, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {d.label}
                </div>
              </div>
            );
          })}
        </div>
      )}
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
  const [loadingPay, setLoadingPay] = useState(true);
  const [payError, setPayError] = useState('');
  const [searchPay, setSearchPay] = useState('');
  const [filterStatusPay, setFilterStatusPay] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const limit = 10;

  // Active Section View inside Revenue Breakdown: 'category' | 'service' | 'worker'
  const [breakdownView, setBreakdownView] = useState('category');

  // Revenue Breakdown State
  const [breakdownData, setBreakdownData] = useState({ rows: [], monthlyTrend: [] });
  const [loadingBreakdown, setLoadingBreakdown] = useState(true);
  const [summary, setSummary] = useState(null);

  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });
  const formatDate = (d) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  const fetchPayments = () => {
    setLoadingPay(true);
    setPayError('');
    invoicesAPI.getPayments()
      .then(res => {
        if (res && res.success) {
          setPayments(res.data || []);
        }
      })
      .catch(err => {
        console.error('Error fetching payments:', err);
        setPayError(err?.message || 'Failed to load payment transactions.');
      })
      .finally(() => setLoadingPay(false));
  };

  const fetchBreakdown = () => {
    setLoadingBreakdown(true);
    settlementsAPI.getRevenueBreakdown()
      .then(res => {
        if (res && res.success) {
          setBreakdownData(res.data || { rows: [], monthlyTrend: [] });
        }
      })
      .catch(console.error)
      .finally(() => setLoadingBreakdown(false));
  };

  const fetchSummary = () => {
    settlementsAPI.getSummary()
      .then(res => {
        if (res && res.success) setSummary(res.data);
      })
      .catch(console.error);
  };

  useEffect(() => {
    fetchPayments();
    fetchBreakdown();
    fetchSummary();
  }, []);

  // Filtered Payments
  const filteredPayments = payments.filter(p => {
    const s = searchPay.toLowerCase().trim();
    const matchSearch = !s || (p.user_name || '').toLowerCase().includes(s) ||
      (p.razorpay_order_id || '').toLowerCase().includes(s) ||
      String(p.booking_id || '').includes(s) ||
      (p.service_name || '').toLowerCase().includes(s);
    const matchStatus = !filterStatusPay || p.status === filterStatusPay;
    return matchSearch && matchStatus;
  });

  const totalPayPages = Math.ceil(filteredPayments.length / limit) || 1;
  const paginatedPayments = filteredPayments.slice((currentPage - 1) * limit, currentPage * limit);

  // Group raw rows into Categories
  const categoryMap = (breakdownData.rows || []).reduce((acc, row) => {
    const cat = row.category_name || 'General Services';
    if (!acc[cat]) {
      acc[cat] = { name: cat, icon: row.category_icon, totalJobs: 0, grossRevenue: 0 };
    }
    acc[cat].totalJobs += Number(row.jobs_completed || 0);
    acc[cat].grossRevenue += Number(row.gross_revenue || 0);
    return acc;
  }, {});
  const categoryList = Object.values(categoryMap);

  // Group raw rows into Services
  const serviceMap = (breakdownData.rows || []).reduce((acc, row) => {
    const srv = row.service_name || 'Direct Service';
    if (!acc[srv]) {
      acc[srv] = { name: srv, category: row.category_name, totalJobs: 0, grossRevenue: 0, workers: [] };
    }
    acc[srv].totalJobs += Number(row.jobs_completed || 0);
    acc[srv].grossRevenue += Number(row.gross_revenue || 0);
    acc[srv].workers.push(row);
    return acc;
  }, {});
  const serviceList = Object.values(serviceMap);

  // Raw Workers List
  const workerList = breakdownData.rows || [];

  const handleExportServiceCSV = (serviceName, workers) => {
    const rows = [['Worker Name', 'Phone', 'Service', 'Completed Jobs', 'Gross Revenue', 'Platform Fee (10%)', 'Net Worker Share']];
    workers.forEach(w => rows.push([
      w.worker_name || 'Technician',
      w.worker_phone || '—',
      serviceName,
      w.jobs_completed,
      Number(w.gross_revenue || 0).toFixed(2),
      Number(w.platform_fee || 0).toFixed(2),
      Number(w.net_payout || 0).toFixed(2),
    ]));
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = `${serviceName.replace(/\s+/g, '_')}_revenue.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleExportFullCSV = () => {
    const rows = [['ID', 'Booking ID', 'Customer', 'Service', 'Razorpay Order ID', 'Amount', 'Status', 'Date']];
    filteredPayments.forEach(p => rows.push([
      p.id, p.booking_id, p.user_name || 'Customer',
      p.service_name || 'Home Service', p.razorpay_order_id,
      Number(p.amount || 0).toFixed(2), p.status,
      formatDate(p.created_at),
    ]));
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url;
    a.download = 'full_master_revenue_report.csv';
    a.click();
    URL.revokeObjectURL(url);
  };

  // Monthly trend data for bottom 3D chart
  const monthlyTrendData = (breakdownData.monthlyTrend || []).map(t => ({
    label: t.month_label,
    value: Number(t.gross_amount || 0)
  }));

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        .pay-row:hover { background: var(--bg-app); }
        .sec-tab { padding: 9px 16px; font-size: 13px; font-weight: 600; border-radius: 8px; cursor: pointer; border: 1px solid transparent; transition: all 0.2s; }
        .sec-tab.active { background: var(--accent-color); color: #fff; border-color: var(--accent-color); }
        .sec-tab.inactive { background: var(--bg-card); color: var(--text-secondary); border-color: var(--border-color); }
      `}</style>

      {/* TOP HEADER */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>Total Revenue & Financial Overview</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Master financial transactions, Category/Service breakdown sections, and interactive 3D visual graphs.
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={handleExportFullCSV}
            style={{ background: 'var(--bg-card)', border: '1px solid #D1D5DB', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--text-primary)' }}
          >
            📥 Export Master CSV
          </button>
          <button
            onClick={() => { fetchPayments(); fetchBreakdown(); fetchSummary(); }}
            style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
          >
            🔄 Refresh Revenue
          </button>
        </div>
      </div>

      {/* TOP KPI CARDS */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Total Revenue Collected"
          value={formatINR(summary?.total_gross_revenue || 0)}
          icon="💰" bg="rgba(59,130,246,0.1)" fg="#3B82F6"
          loading={loadingBreakdown}
        />
        <StatCard
          label="Platform Revenue (10%)"
          value={formatINR(summary?.total_platform_commission || 0)}
          icon="📈" bg="rgba(16,185,129,0.1)" fg="#10B981"
          loading={loadingBreakdown}
        />
        <StatCard
          label="Worker Net Share (90%)"
          value={formatINR((summary?.total_gross_revenue || 0) * 0.9)}
          icon="🤝" bg="rgba(99,102,241,0.1)" fg="#6366F1"
          loading={loadingBreakdown}
        />
        <StatCard
          label="Active Categories"
          value={categoryList.length}
          icon="📁" bg="rgba(245,158,11,0.1)" fg="#F59E0B"
          loading={loadingBreakdown}
        />
      </div>

      {/* SECTION 1 (IMAGE 1): MASTER CUSTOMER PAYMENT TRANSACTIONS LOG TABLE */}
      <div style={{ background: 'var(--bg-card)', padding: 20, borderRadius: 14, border: '1px solid var(--border-color)', marginBottom: 28 }}>
        <h3 style={{ fontSize: 16, fontWeight: 700, margin: '0 0 16px', color: 'var(--text-primary)', display: 'flex', alignItems: 'center', gap: 8 }}>
          💳 Master Customer Payment Transactions Log
        </h3>

        {/* Controls */}
        <div style={{ display: 'flex', gap: 16, justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <input
            type="text"
            placeholder="Search customer name, Razorpay Order ID..."
            value={searchPay}
            onChange={e => setSearchPay(e.target.value)}
            style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 14px', fontSize: 13, color: 'var(--text-primary)', width: 320 }}
          />
          <select
            value={filterStatusPay}
            onChange={e => setFilterStatusPay(e.target.value)}
            style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 14px', fontSize: 13, color: 'var(--text-primary)' }}
          >
            <option value="">All Statuses</option>
            <option value="successful">Successful</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
        </div>

        {/* Error */}
        {payError && (
          <div style={{ background: '#FEE2E2', border: '1px solid #EF4444', color: '#991B1B', padding: '10px 14px', borderRadius: 8, fontSize: 12, marginBottom: 14 }}>
            ⚠️ {payError}
          </div>
        )}

        {/* Table */}
        <div style={{ borderRadius: 10, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
            <thead>
              <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                <th style={{ padding: '12px 16px' }}>Transaction ID</th>
                <th style={{ padding: '12px 16px' }}>Customer</th>
                <th style={{ padding: '12px 16px' }}>Service</th>
                <th style={{ padding: '12px 16px' }}>Razorpay Order ID</th>
                <th style={{ padding: '12px 16px' }}>Amount</th>
                <th style={{ padding: '12px 16px' }}>Status</th>
                <th style={{ padding: '12px 16px' }}>Date</th>
              </tr>
            </thead>
            <tbody>
              {loadingPay ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                    <td colSpan={7} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                  </tr>
                ))
              ) : paginatedPayments.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>
                    No payment transactions found.
                  </td>
                </tr>
              ) : (
                paginatedPayments.map(p => {
                  const st = STATUS_CONFIG[p.status] || { text: p.status, bg: '#F3F4F6', fg: '#374151' };
                  return (
                    <tr key={p.id} className="pay-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                      <td style={{ padding: '14px 16px', fontWeight: 600 }}>#{p.id}</td>
                      <td style={{ padding: '14px 16px' }}>{p.user_name || 'Customer'}</td>
                      <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{p.service_name || 'Home Service'}</td>
                      <td style={{ padding: '14px 16px', fontFamily: 'monospace', fontSize: 12 }}>{p.razorpay_order_id || '—'}</td>
                      <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>{formatINR(p.amount)}</td>
                      <td style={{ padding: '14px 16px' }}>
                        <span style={{ background: st.bg, color: st.fg, padding: '4px 10px', borderRadius: 12, fontSize: 11, fontWeight: 600 }}>
                          {st.text}
                        </span>
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--text-muted)', fontSize: 12 }}>{formatDate(p.created_at)}</td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* SECTION 2: BREAKDOWN VIEW TABS (Category vs Service vs Individual Worker) */}
      <div style={{ marginBottom: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h3 style={{ fontSize: 18, fontWeight: 800, margin: 0, color: 'var(--text-primary)' }}>
            📂 Financial Breakdown & Performance Sections
          </h3>
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              className={`sec-tab ${breakdownView === 'category' ? 'active' : 'inactive'}`}
              onClick={() => setBreakdownView('category')}
            >
              📁 Category Section
            </button>
            <button
              className={`sec-tab ${breakdownView === 'service' ? 'active' : 'inactive'}`}
              onClick={() => setBreakdownView('service')}
            >
              🔧 Service Section
            </button>
            <button
              className={`sec-tab ${breakdownView === 'worker' ? 'active' : 'inactive'}`}
              onClick={() => setBreakdownView('worker')}
            >
              👷 Individual Worker Breakdown
            </button>
          </div>
        </div>

        {/* VIEW 1: CATEGORY SECTION PAGE */}
        {breakdownView === 'category' && (
          <div>
            <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
                <thead>
                  <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                    <th style={{ padding: '12px 16px' }}>Category Name</th>
                    <th style={{ padding: '12px 16px' }}>Completed Jobs</th>
                    <th style={{ padding: '12px 16px' }}>Total Category Revenue</th>
                    <th style={{ padding: '12px 16px' }}>Platform Fee (10%)</th>
                  </tr>
                </thead>
                <tbody>
                  {loadingBreakdown ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td colSpan={4} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                      </tr>
                    ))
                  ) : categoryList.length === 0 ? (
                    <tr>
                      <td colSpan={4} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>No category data available.</td>
                    </tr>
                  ) : (
                    categoryList.map(cat => (
                      <tr key={cat.name} className="pay-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>
                          {cat.icon || '🛠️'} {cat.name}
                        </td>
                        <td style={{ padding: '14px 16px', fontWeight: 600 }}>{cat.totalJobs} Jobs</td>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: '#10B981', fontSize: 15 }}>{formatINR(cat.grossRevenue)}</td>
                        <td style={{ padding: '14px 16px', color: '#EF4444' }}>-{formatINR(cat.grossRevenue * 0.1)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* 3D Graph at bottom of Category Section */}
            <ThreeDBarChart
              title="Category Revenue Comparison"
              data={categoryList.map(c => ({ label: c.name, value: c.grossRevenue }))}
              colorScheme="blue"
            />
          </div>
        )}

        {/* VIEW 2: SERVICE SECTION */}
        {breakdownView === 'service' && (
          <div>
            <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
                <thead>
                  <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                    <th style={{ padding: '12px 16px' }}>Service Name</th>
                    <th style={{ padding: '12px 16px' }}>Category</th>
                    <th style={{ padding: '12px 16px' }}>Completed Jobs</th>
                    <th style={{ padding: '12px 16px' }}>Gross Revenue</th>
                    <th style={{ padding: '12px 16px', textAlign: 'right' }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {loadingBreakdown ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td colSpan={5} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                      </tr>
                    ))
                  ) : serviceList.length === 0 ? (
                    <tr>
                      <td colSpan={5} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>No service data available.</td>
                    </tr>
                  ) : (
                    serviceList.map(srv => (
                      <tr key={srv.name} className="pay-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>🔧 {srv.name}</td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{srv.category}</td>
                        <td style={{ padding: '14px 16px', fontWeight: 600 }}>{srv.totalJobs} Jobs</td>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: '#10B981', fontSize: 15 }}>{formatINR(srv.grossRevenue)}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                          <button
                            onClick={() => handleExportServiceCSV(srv.name, srv.workers)}
                            style={{ background: 'var(--bg-app)', border: '1px solid #D1D5DB', borderRadius: 6, padding: '6px 12px', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}
                          >
                            📥 Export CSV
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* 3D Graph at bottom of Service Section */}
            <ThreeDBarChart
              title="Service Revenue Comparison"
              data={serviceList.map(s => ({ label: s.name, value: s.grossRevenue }))}
              colorScheme="green"
            />
          </div>
        )}

        {/* VIEW 3: INDIVIDUAL WORKER BREAKDOWN */}
        {breakdownView === 'worker' && (
          <div>
            <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
                <thead>
                  <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
                    <th style={{ padding: '12px 16px' }}>Worker Name</th>
                    <th style={{ padding: '12px 16px' }}>Phone</th>
                    <th style={{ padding: '12px 16px' }}>Service</th>
                    <th style={{ padding: '12px 16px' }}>Completed Jobs</th>
                    <th style={{ padding: '12px 16px' }}>Gross Revenue</th>
                    <th style={{ padding: '12px 16px' }}>Platform Fee (10%)</th>
                    <th style={{ padding: '12px 16px' }}>Net Worker Share</th>
                  </tr>
                </thead>
                <tbody>
                  {loadingBreakdown ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td colSpan={7} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                      </tr>
                    ))
                  ) : workerList.length === 0 ? (
                    <tr>
                      <td colSpan={7} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>No worker breakdown data available.</td>
                    </tr>
                  ) : (
                    workerList.map((w, i) => (
                      <tr key={i} className="pay-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: 'var(--text-primary)' }}>{w.worker_name || 'Technician'}</td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-muted)' }}>{w.worker_phone || '—'}</td>
                        <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{w.service_name}</td>
                        <td style={{ padding: '14px 16px', fontWeight: 600 }}>{w.jobs_completed}</td>
                        <td style={{ padding: '14px 16px' }}>{formatINR(w.gross_revenue)}</td>
                        <td style={{ padding: '14px 16px', color: '#EF4444' }}>-{formatINR(w.platform_fee)}</td>
                        <td style={{ padding: '14px 16px', fontWeight: 700, color: '#10B981', fontSize: 15 }}>{formatINR(w.net_payout)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* 3D Graph at bottom of Worker Section */}
            <ThreeDBarChart
              title="Individual Worker Revenue Share"
              data={workerList.map(w => ({ label: w.worker_name || 'Worker', value: w.gross_revenue }))}
              colorScheme="purple"
            />
          </div>
        )}
      </div>

      {/* THIRD SECTION: MONTHLY REVENUE COLLECTION TREND */}
      <ThreeDBarChart
        title="Monthly Revenue Collection Trend"
        data={monthlyTrendData}
        height={180}
        colorScheme="amber"
      />
    </div>
  );
}
