import { useState, useEffect } from 'react';
import { settlementsAPI } from '../api';

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
      padding: '20px 24px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="100px" h={32} /> : (
          <div style={{ fontSize: 28, fontWeight: 800, color: 'var(--text-primary)' }}>{value}</div>
        )}
        {sub && !loading && <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>{sub}</div>}
      </div>
      <div style={{
        width: 52, height: 52, borderRadius: 12, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

export default function Accounts() {
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);

  const fetchSummary = () => {
    setLoading(true);
    settlementsAPI.getSummary()
      .then(res => {
        if (res && res.success) setSummary(res.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchSummary(); }, []);

  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Financial Accounts & Revenue</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Complete platform income statement, company commission earnings (10%), and worker payout distribution metrics.
          </p>
        </div>
        <button
          onClick={fetchSummary}
          style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
        >
          🔄 Refresh Financials
        </button>
      </div>

      {/* Main KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: 20, marginBottom: 28 }}>
        <StatCard
          label="Total Gross Income"
          value={formatINR(summary?.total_gross_revenue || 0)}
          sub="All payments collected from users"
          icon="💰" bg="rgba(59,130,246,0.1)" fg="#3B82F6"
          loading={loading}
        />
        <StatCard
          label="Platform Revenue (10%)"
          value={formatINR(summary?.total_platform_commission || 0)}
          sub="Net platform commission profit"
          icon="📈" bg="rgba(16,185,129,0.1)" fg="#10B981"
          loading={loading}
        />
        <StatCard
          label="Settled Worker Payouts"
          value={formatINR(summary?.total_settled_payout || 0)}
          sub="Disbursed earnings to technicians"
          icon="✅" bg="rgba(99,102,241,0.1)" fg="#6366F1"
          loading={loading}
        />
        <StatCard
          label="Pending Worker Payouts"
          value={formatINR(summary?.total_pending_payout || 0)}
          sub="Unsettled balance in queue"
          icon="⏳" bg="rgba(245,158,11,0.1)" fg="#F59E0B"
          loading={loading}
        />
      </div>

      {/* Detailed Flow Breakdown */}
      <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', padding: 24, marginBottom: 24 }}>
        <h3 style={{ fontSize: 16, fontWeight: 700, margin: '0 0 16px', color: 'var(--text-primary)' }}>
          💳 Revenue Distribution & Accounting Model
        </h3>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 20 }}>
          <div style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 12, padding: 20 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6 }}>1. Customer Payments (100%)</div>
            <div style={{ fontSize: 24, fontWeight: 800, color: '#3B82F6', marginBottom: 8 }}>{formatINR(summary?.total_gross_revenue || 0)}</div>
            <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0, lineHeight: 1.5 }}>
              Total value of inspection, service fees, and extra costs paid by customers via Razorpay or Cash.
            </p>
          </div>

          <div style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 12, padding: 20 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6 }}>2. Company Service Fee (10%)</div>
            <div style={{ fontSize: 24, fontWeight: 800, color: '#10B981', marginBottom: 8 }}>{formatINR(summary?.total_platform_commission || 0)}</div>
            <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0, lineHeight: 1.5 }}>
              Deducted platform margin retained by company for operating app marketplace software.
            </p>
          </div>

          <div style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 12, padding: 20 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6 }}>3. Technician Share (90%)</div>
            <div style={{ fontSize: 24, fontWeight: 800, color: '#6366F1', marginBottom: 8 }}>{formatINR((summary?.total_gross_revenue || 0) * 0.9)}</div>
            <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: 0, lineHeight: 1.5 }}>
              Total net earnings allocated to active service partners for completing booked services.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
