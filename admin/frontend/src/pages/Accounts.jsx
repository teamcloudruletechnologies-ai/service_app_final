import { useState, useEffect } from 'react';
import { settlementsAPI, invoicesAPI } from '../api';

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
  const [passbook, setPassbook] = useState([]);
  const [loading, setLoading] = useState(true);
  const [passbookLoading, setPassbookLoading] = useState(false);
  const [passbookFilter, setPassbookFilter] = useState(''); // '' | 'CREDIT' | 'COMMISSION' | 'DEBIT'
  const [passbookSearch, setPassbookSearch] = useState('');

  const fetchAll = () => {
    setLoading(true);
    setPassbookLoading(true);
    settlementsAPI.getSummary()
      .then(res => {
        if (res && res.success) setSummary(res.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));

    invoicesAPI.getPassbook()
      .then(res => {
        if (res && res.success) setPassbook(res.data || []);
      })
      .catch(console.error)
      .finally(() => setPassbookLoading(false));
  };

  useEffect(() => { fetchAll(); }, []);

  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });

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

  const filteredPassbook = passbook.filter(row => {
    if (passbookFilter && row.txn_type !== passbookFilter) return false;
    if (passbookSearch) {
      const q = passbookSearch.toLowerCase();
      const matchParticulars = (row.particulars || '').toLowerCase().includes(q);
      const matchRef = (row.ref_no || '').toLowerCase().includes(q);
      const matchParty = (row.party_name || '').toLowerCase().includes(q);
      if (!matchParticulars && !matchRef && !matchParty) return false;
    }
    return true;
  });

  const handleExportPassbookCSV = () => {
    if (!passbook || passbook.length === 0) {
      alert('No passbook ledger records available to export.');
      return;
    }

    const headers = ["Txn Date", "Ref ID", "Txn Type", "Particulars / Description", "Party Name", "Party Role", "Credit (+ INR)", "Debit (- INR)", "Running Balance (INR)", "Status"];

    const csvRows = passbook.map(row => [
      `"${formatDate(row.txn_date)}"`,
      `"${row.ref_no || ''}"`,
      `"${row.txn_type || ''}"`,
      `"${(row.particulars || '').replace(/"/g, '""')}"`,
      `"${(row.party_name || '').replace(/"/g, '""')}"`,
      `"${row.party_role || ''}"`,
      row.credit_amount || 0,
      row.debit_amount || 0,
      row.running_balance || 0,
      `"${row.status || ''}"`
    ]);

    const csvContent = [headers.join(','), ...csvRows.map(e => e.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `Bank_Passbook_Ledger_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

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
          onClick={fetchAll}
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
      <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', padding: 24, marginBottom: 28 }}>
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

      {/* 🏛️ BANK MINI STATEMENT (PASSBOOK AUDIT LEDGER) SECTION */}
      <div style={{ background: 'var(--bg-card)', borderRadius: 14, border: '1px solid var(--border-color)', padding: 24 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '4px 12px', borderRadius: 20, backgroundColor: '#EFF6FF', color: '#1D4ED8', fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              <span>🏦</span> Corporate Escrow & Treasury Account
            </div>
            <h3 style={{ fontSize: 18, fontWeight: 800, color: 'var(--text-primary)', margin: '6px 0 0' }}>
              Bank Passbook Audit Statement & Ledger
            </h3>
          </div>
          <button
            onClick={handleExportPassbookCSV}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              padding: '10px 18px',
              borderRadius: 10,
              background: '#10B981',
              color: '#FFFFFF',
              border: 'none',
              fontWeight: 700,
              fontSize: 13,
              cursor: 'pointer',
              boxShadow: '0 3px 10px rgba(16, 185, 129, 0.25)',
              transition: 'all 0.2s',
            }}
          >
            📊 Export Mini Statement (.CSV)
          </button>
        </div>

        {/* Filter Chips & Search Bar */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {[
              { key: '', label: 'All Transactions' },
              { key: 'CREDIT', label: '🟢 Credits (+ User Payments)' },
              { key: 'COMMISSION', label: '🏢 Commission (10% Company Margin)' },
              { key: 'DEBIT', label: '🔴 Debits (- Worker Payouts)' },
            ].map(opt => (
              <button
                key={opt.key}
                onClick={() => setPassbookFilter(opt.key)}
                style={{
                  padding: '7px 15px',
                  borderRadius: 20,
                  border: '1px solid',
                  borderColor: passbookFilter === opt.key ? '#2563EB' : 'var(--border-color)',
                  backgroundColor: passbookFilter === opt.key ? '#EFF6FF' : 'var(--bg-card)',
                  color: passbookFilter === opt.key ? '#1D4ED8' : 'var(--text-secondary)',
                  fontSize: 12,
                  fontWeight: passbookFilter === opt.key ? 700 : 500,
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                }}
              >
                {opt.label}
              </button>
            ))}
          </div>

          <input
            type="text"
            placeholder="Search particulars, ref ID, party name..."
            value={passbookSearch}
            onChange={(e) => setPassbookSearch(e.target.value)}
            style={{
              padding: '8px 14px',
              borderRadius: 10,
              border: '1px solid var(--border-color)',
              fontSize: 13,
              width: 280,
              outline: 'none',
            }}
          />
        </div>

        {/* Passbook Table */}
        <div style={{ overflowX: 'auto', border: '1px solid var(--border-color)', borderRadius: 12 }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 900 }}>
            <thead>
              <tr style={{ background: '#F8FAFC', borderBottom: '1px solid var(--border-color)', fontSize: 12, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                <th style={{ padding: '14px 18px', fontWeight: 700 }}>Date & Time</th>
                <th style={{ padding: '14px 18px', fontWeight: 700 }}>Ref / Txn ID</th>
                <th style={{ padding: '14px 18px', fontWeight: 700 }}>Particulars / Remarks</th>
                <th style={{ padding: '14px 18px', fontWeight: 700 }}>Source / Party</th>
                <th style={{ padding: '14px 18px', fontWeight: 700 }}>Type</th>
                <th style={{ padding: '14px 18px', fontWeight: 700, textAlign: 'right' }}>Amount (₹)</th>
                <th style={{ padding: '14px 18px', fontWeight: 700, textAlign: 'right' }}>Running Balance</th>
              </tr>
            </thead>
            <tbody>
              {passbookLoading ? (
                <tr>
                  <td colSpan="7" style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
                    ⏳ Loading Bank Passbook Ledger...
                  </td>
                </tr>
              ) : filteredPassbook.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
                    No financial ledger transactions found matching the filter.
                  </td>
                </tr>
              ) : (
                filteredPassbook.map((row, idx) => {
                  const isCredit = row.txn_type === 'CREDIT';
                  const isComm = row.txn_type === 'COMMISSION';
                  const isDebit = row.txn_type === 'DEBIT';

                  return (
                    <tr key={row.event_id || idx} style={{ borderBottom: '1px solid var(--border-color)', fontSize: 13, background: idx % 2 === 0 ? '#FFFFFF' : '#F8FAFC' }}>
                      <td style={{ padding: '14px 18px', whiteSpace: 'nowrap', color: 'var(--text-secondary)', fontSize: 12 }}>
                        {formatDate(row.txn_date)}
                      </td>
                      <td style={{ padding: '14px 18px', fontFamily: 'monospace', fontWeight: 700, color: 'var(--text-primary)' }}>
                        {row.ref_no}
                      </td>
                      <td style={{ padding: '14px 18px', color: 'var(--text-primary)', fontWeight: 500 }}>
                        {row.particulars}
                      </td>
                      <td style={{ padding: '14px 18px', color: 'var(--text-secondary)', fontSize: 12.5 }}>
                        <strong>{row.party_name}</strong> <span style={{ opacity: 0.7 }}>({row.party_role})</span>
                      </td>
                      <td style={{ padding: '14px 18px' }}>
                        {isCredit && (
                          <span style={{ padding: '4px 10px', borderRadius: 12, background: '#DCFCE7', color: '#15803D', fontSize: 11, fontWeight: 800 }}>
                            🟢 CREDIT
                          </span>
                        )}
                        {isComm && (
                          <span style={{ padding: '4px 10px', borderRadius: 12, background: '#EFF6FF', color: '#1D4ED8', fontSize: 11, fontWeight: 800 }}>
                            🏢 COMMISSION
                          </span>
                        )}
                        {isDebit && (
                          <span style={{ padding: '4px 10px', borderRadius: 12, background: '#FEE2E2', color: '#B91C1C', fontSize: 11, fontWeight: 800 }}>
                            🔴 DEBIT
                          </span>
                        )}
                      </td>
                      <td style={{ padding: '14px 18px', textAlign: 'right', fontWeight: 900, fontSize: 14 }}>
                        {isCredit && <span style={{ color: '#16A34A' }}>+ {formatINR(row.credit_amount)}</span>}
                        {isComm && <span style={{ color: '#2563EB' }}>+ {formatINR(row.credit_amount)}</span>}
                        {isDebit && <span style={{ color: '#DC2626' }}>- {formatINR(row.debit_amount)}</span>}
                      </td>
                      <td style={{ padding: '14px 18px', textAlign: 'right', fontFamily: 'monospace', fontWeight: 800, color: '#0F172A', fontSize: 14 }}>
                        {formatINR(row.running_balance)}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
