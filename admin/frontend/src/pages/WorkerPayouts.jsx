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

function StatCard({ label, value, icon, bg, fg, loading }) {
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
      </div>
      <div style={{
        width: 44, height: 44, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

export default function WorkerPayouts() {
  const [unsettled, setUnsettled] = useState([]);
  const [loadingSet, setLoadingSet] = useState(true);
  const [setError, setSetError] = useState('');
  const [daysFilter, setDaysFilter] = useState('3'); // '3', '7', '14', '30', 'custom'
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [minAmountFilter, setMinAmountFilter] = useState('500');
  const [searchWorker, setSearchWorker] = useState('');
  const [onlyEligible, setOnlyEligible] = useState(true);

  // Payout Modal State
  const [settleModal, setSettleModal] = useState(null);
  const [payMethod, setPayMethod] = useState('razorpay');
  const [txnRef, setTxnRef] = useState('');
  const [payNotes, setPayNotes] = useState('');
  const [submittingPayout, setSubmittingPayout] = useState(false);

  // Summary State
  const [summary, setSummary] = useState(null);

  const fetchUnsettled = () => {
    setLoadingSet(true);
    setSetError('');
    const params = {
      minAmount: minAmountFilter || 500,
    };
    if (daysFilter === 'custom' && startDate && endDate) {
      params.startDate = startDate;
      params.endDate = endDate;
    } else {
      params.days = daysFilter === 'custom' ? 3 : daysFilter;
    }

    settlementsAPI.getUnsettled(params)
      .then(res => {
        if (res && res.success) {
          setUnsettled(res.data || []);
        }
      })
      .catch(err => {
        console.error('Error fetching unsettled workers:', err);
        setSetError(err?.message || 'Failed to load unsettled worker earnings.');
      })
      .finally(() => setLoadingSet(false));
  };

  const fetchSummary = () => {
    settlementsAPI.getSummary()
      .then(res => {
        if (res && res.success) setSummary(res.data);
      })
      .catch(console.error);
  };

  useEffect(() => {
    fetchUnsettled();
    fetchSummary();
  }, []);

  useEffect(() => {
    fetchUnsettled();
  }, [daysFilter, startDate, endDate, minAmountFilter]);

  const formatINR = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 });

  const filteredWorkers = unsettled.filter(w => {
    const s = searchWorker.toLowerCase().trim();
    const matchSearch = !s || (w.worker_name || '').toLowerCase().includes(s) ||
      (w.worker_phone || '').includes(s) ||
      (w.service_type || '').toLowerCase().includes(s);
    const matchEligible = !onlyEligible || w.is_eligible;
    return matchSearch && matchEligible;
  });

  const handleProcessPayout = (e) => {
    e.preventDefault();
    if (!settleModal) return;

    setSubmittingPayout(true);
    settlementsAPI.createPayout({
      worker_id: settleModal.worker_id,
      total_jobs: settleModal.total_jobs,
      gross_amount: settleModal.gross_amount,
      platform_fee: settleModal.platform_fee,
      net_payout: settleModal.net_payout,
      payment_method: payMethod,
      transaction_ref: txnRef || `PAY-${Date.now()}`,
      notes: payNotes,
    })
      .then(res => {
        if (res && res.success) {
          alert(`✅ Payout of ${formatINR(settleModal.net_payout)} successfully processed for ${settleModal.worker_name}!`);
          setSettleModal(null);
          setTxnRef('');
          setPayNotes('');
          fetchUnsettled();
          fetchSummary();
        }
      })
      .catch(err => {
        alert(err?.message || 'Failed to process payout.');
      })
      .finally(() => setSubmittingPayout(false));
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        .pay-row:hover { background: var(--bg-app); }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Worker Settlements & Payouts</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
            Manage technician payout thresholds (≥₹500), minimum 3-day settlement periods, and process payments via Razorpay / Direct UPI.
          </p>
        </div>
        <button
          onClick={() => { fetchUnsettled(); fetchSummary(); }}
          style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
        >
          🔄 Refresh Payouts
        </button>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Pending Unsettled Balance"
          value={formatINR(summary?.total_pending_payout || 0)}
          icon="⏳" bg="rgba(245,158,11,0.1)" fg="#F59E0B"
          loading={loadingSet}
        />
        <StatCard
          label="Eligible Workers (≥ ₹500)"
          value={unsettled.filter(w => w.is_eligible).length}
          icon="👥" bg="rgba(16,185,129,0.1)" fg="#10B981"
          loading={loadingSet}
        />
        <StatCard
          label="Total Settled to Date"
          value={formatINR(summary?.total_settled_payout || 0)}
          icon="✅" bg="rgba(99,102,241,0.1)" fg="#6366F1"
          loading={loadingSet}
        />
      </div>

      {/* Controls Bar */}
      <div style={{ background: 'var(--bg-card)', padding: '16px 20px', borderRadius: 12, border: '1px solid var(--border-color)', marginBottom: 20, display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div>
            <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 4 }}>Settlement Period</label>
            <select
              value={daysFilter}
              onChange={e => setDaysFilter(e.target.value)}
              style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '7px 12px', fontSize: 13, color: 'var(--text-primary)', cursor: 'pointer' }}
            >
              <option value="3">Min 3 Days Window</option>
              <option value="7">Last 7 Days (Weekly)</option>
              <option value="14">Last 14 Days</option>
              <option value="30">Last 30 Days</option>
              <option value="custom">Custom Date Range...</option>
            </select>
          </div>

          {daysFilter === 'custom' && (
            <>
              <div>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 4 }}>Start Date</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={e => setStartDate(e.target.value)}
                  style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '6px 12px', fontSize: 13, color: 'var(--text-primary)' }}
                />
              </div>
              <div>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 4 }}>End Date</label>
                <input
                  type="date"
                  value={endDate}
                  onChange={e => setEndDate(e.target.value)}
                  style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '6px 12px', fontSize: 13, color: 'var(--text-primary)' }}
                />
              </div>
            </>
          )}

          <div>
            <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', display: 'block', marginBottom: 4 }}>Min Payout Threshold</label>
            <select
              value={minAmountFilter}
              onChange={e => setMinAmountFilter(e.target.value)}
              style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '7px 12px', fontSize: 13, color: 'var(--text-primary)' }}
            >
              <option value="500">≥ ₹500 (Standard)</option>
              <option value="1000">≥ ₹1,000</option>
              <option value="0">All Amounts (₹0+)</option>
            </select>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Search worker name, phone..."
            value={searchWorker}
            onChange={e => setSearchWorker(e.target.value)}
            style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '7px 14px', fontSize: 13, color: 'var(--text-primary)', width: 220 }}
          />

          <label style={{ fontSize: 12, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={onlyEligible}
              onChange={e => setOnlyEligible(e.target.checked)}
            />
            Show Eligible Only (≥ ₹{minAmountFilter})
          </label>
        </div>
      </div>

      {/* Error Message */}
      {setError && (
        <div style={{ background: '#FEE2E2', border: '1px solid #EF4444', color: '#991B1B', padding: '12px 16px', borderRadius: 8, fontSize: 13, marginBottom: 16 }}>
          ⚠️ {setError}
        </div>
      )}

      {/* Table */}
      <div style={{ background: 'var(--bg-card)', borderRadius: 12, border: '1px solid var(--border-color)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, textAlign: 'left' }}>
          <thead>
            <tr style={{ background: 'var(--bg-muted)', color: 'var(--text-secondary)', borderBottom: '1px solid var(--border-color)', fontSize: 12, fontWeight: 600 }}>
              <th style={{ padding: '12px 16px' }}>Worker Info</th>
              <th style={{ padding: '12px 16px' }}>Category</th>
              <th style={{ padding: '12px 16px' }}>Completed Jobs</th>
              <th style={{ padding: '12px 16px' }}>Gross Revenue</th>
              <th style={{ padding: '12px 16px' }}>Platform Fee (10%)</th>
              <th style={{ padding: '12px 16px' }}>Net Payable (90%)</th>
              <th style={{ padding: '12px 16px' }}>Status / Threshold</th>
              <th style={{ padding: '12px 16px', textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {loadingSet ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td colSpan={8} style={{ padding: '14px 16px' }}><Skeleton h={20} /></td>
                </tr>
              ))
            ) : filteredWorkers.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ padding: 36, textAlign: 'center', color: 'var(--text-muted)' }}>
                  No workers found for payout in this period.
                </td>
              </tr>
            ) : (
              filteredWorkers.map(w => (
                <tr key={w.worker_id} className="pay-row" style={{ borderBottom: '1px solid var(--border-color)' }}>
                  <td style={{ padding: '14px 16px' }}>
                    <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{w.worker_name}</div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>📞 {w.worker_phone}</div>
                    {w.upi_id && <div style={{ fontSize: 11, color: '#3B82F6' }}>💳 UPI: {w.upi_id}</div>}
                  </td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{w.service_type || 'Service Partner'}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 600 }}>{w.total_jobs} Jobs</td>
                  <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{formatINR(w.gross_amount)}</td>
                  <td style={{ padding: '14px 16px', color: '#EF4444' }}>-{formatINR(w.platform_fee)}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700, color: '#10B981', fontSize: 15 }}>{formatINR(w.net_payout)}</td>
                  <td style={{ padding: '14px 16px' }}>
                    {w.is_eligible ? (
                      <span style={{ background: '#D1FAE5', color: '#065F46', padding: '4px 10px', borderRadius: 12, fontSize: 11, fontWeight: 700 }}>
                        ✅ Eligible (≥ ₹{minAmountFilter})
                      </span>
                    ) : (
                      <span style={{ background: '#FEF3C7', color: '#92400E', padding: '4px 10px', borderRadius: 12, fontSize: 11, fontWeight: 600 }}>
                        ⏳ Below ₹{minAmountFilter} Threshold
                      </span>
                    )}
                  </td>
                  <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                    <button
                      onClick={() => {
                        setSettleModal(w);
                        setTxnRef(`PAY-${w.worker_id}-${Date.now().toString().slice(-6)}`);
                      }}
                      style={{
                        background: w.is_eligible ? '#10B981' : '#6B7280',
                        color: '#fff', border: 'none', borderRadius: 8, padding: '7px 14px',
                        fontSize: 12, fontWeight: 700, cursor: 'pointer'
                      }}
                    >
                      💳 Pay Worker
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* MODAL: PAY WORKER */}
      {settleModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: 20 }}>
          <div style={{ background: 'var(--bg-card)', borderRadius: 14, width: 440, maxWidth: '100%', padding: 24, boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)' }}>
            <h3 style={{ fontSize: 18, fontWeight: 700, margin: '0 0 16px', color: 'var(--text-primary)' }}>
              💳 Process Payout to {settleModal.worker_name}
            </h3>

            <div style={{ background: 'var(--bg-app)', padding: 14, borderRadius: 10, marginBottom: 16, fontSize: 13 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <span style={{ color: 'var(--text-secondary)' }}>Completed Jobs:</span>
                <strong style={{ color: 'var(--text-primary)' }}>{settleModal.total_jobs} Jobs</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <span style={{ color: 'var(--text-secondary)' }}>Gross Earnings:</span>
                <span>{formatINR(settleModal.gross_amount)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                <span style={{ color: 'var(--text-secondary)' }}>Platform Fee (10%):</span>
                <span style={{ color: '#EF4444' }}>-{formatINR(settleModal.platform_fee)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid var(--border-color)', pt: 8, mt: 8, fontSize: 15, fontWeight: 800 }}>
                <span>Net Payable Amount:</span>
                <span style={{ color: '#10B981' }}>{formatINR(settleModal.net_payout)}</span>
              </div>
            </div>

            <form onSubmit={handleProcessPayout}>
              <div style={{ marginBottom: 14 }}>
                <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Payment Method</label>
                <select
                  value={payMethod}
                  onChange={e => setPayMethod(e.target.value)}
                  style={{ width: '100%', background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 12px', fontSize: 13 }}
                >
                  <option value="razorpay">Razorpay Direct Payout API</option>
                  <option value="upi">Direct UPI / GPay / PhonePe Transfer</option>
                  <option value="bank_transfer">IMPS / NEFT Bank Transfer</option>
                </select>
              </div>

              <div style={{ marginBottom: 14 }}>
                <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Transaction Ref ID / UTR Number</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. UTR123456789 or Razorpay Payout ID"
                  value={txnRef}
                  onChange={e => setTxnRef(e.target.value)}
                  style={{ width: '100%', background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 12px', fontSize: 13 }}
                />
              </div>

              <div style={{ marginBottom: 20 }}>
                <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Admin Notes / Remarks</label>
                <textarea
                  placeholder="Optional settlement notes..."
                  value={payNotes}
                  onChange={e => setPayNotes(e.target.value)}
                  style={{ width: '100%', background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 12px', fontSize: 13, height: 60 }}
                />
              </div>

              <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
                <button
                  type="button"
                  onClick={() => setSettleModal(null)}
                  style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8, padding: '8px 16px', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingPayout}
                  style={{ background: '#10B981', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 20px', fontSize: 13, fontWeight: 700, cursor: 'pointer' }}
                >
                  {submittingPayout ? 'Processing...' : 'Confirm & Mark as Paid'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
