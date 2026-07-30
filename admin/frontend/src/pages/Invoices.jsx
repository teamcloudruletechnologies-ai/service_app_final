import { useState, useEffect } from 'react';
import { invoicesAPI } from '../api';
import { toast } from 'react-toastify';

const STATUS_BADGES = {
  paid: { bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)', text: 'Paid' },
  pending: { bg: 'var(--accent-light)', fg: 'var(--accent-dark)', text: 'Pending' },
  failed: { bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)', text: 'Failed' },
  cancelled: { bg: 'var(--bg-muted)', fg: 'var(--text-primary)', text: 'Cancelled' },
  refunded: { bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)', text: 'Refunded' },
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
          <Skeleton w="110px" h={24} />
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

export default function Invoices() {
  const [invoices, setInvoices] = useState([]);
  const [reports, setReports] = useState(null);
  const [payouts, setPayouts] = useState([]);
  const [activeTab, setActiveTab] = useState('invoices'); // 'invoices' | 'payouts'
  const [loading, setLoading] = useState(true);
  const [reportsLoading, setReportsLoading] = useState(true);
  const [payoutsLoading, setPayoutsLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Filters and Pagination
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const limit = 8;

  // Selected invoice for detail modal
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // Fetch stats and reports on mount
  useEffect(() => {
    setReportsLoading(true);
    invoicesAPI.getReports()
      .then(res => {
        if (res && res.success) {
          setReports(res.data);
        }
      })
      .catch(err => console.error('Failed to load invoice reports:', err))
      .finally(() => setReportsLoading(false));
  }, []);

  // Fetch invoices list on filter/page change
  useEffect(() => {
    if (activeTab !== 'invoices') return;
    setLoading(true);
    setError('');
    
    const params = {
      page: currentPage,
      limit: limit,
    };
    if (filterStatus) params.status = filterStatus;

    invoicesAPI.getAll(params)
      .then(res => {
        if (res && res.success) {
          // backend lists are structure: { success: true, data: { rows: [...], meta } }
          const payload = res.data;
          setInvoices(payload.rows || []);
          setTotalPages(payload.meta?.totalPages || 1);
        }
      })
      .catch(err => {
        console.error('Error fetching invoices:', err);
        setError(err?.message || 'Failed to load invoices');
      })
      .finally(() => setLoading(false));
  }, [currentPage, filterStatus, activeTab]);

  // Fetch payouts list when payouts tab becomes active
  useEffect(() => {
    if (activeTab !== 'payouts') return;
    setPayoutsLoading(true);
    invoicesAPI.getPayouts()
      .then(res => {
        if (res && res.success) {
          setPayouts(res.data || []);
        }
      })
      .catch(err => console.error('Error fetching payouts:', err))
      .finally(() => setPayoutsLoading(false));
  }, [activeTab]);

  // Fetch individual invoice details
  const handleViewInvoice = (id) => {
    setDetailLoading(true);
    invoicesAPI.getById(id)
      .then(res => {
        if (res && res.success) {
          setSelectedInvoice(res.data);
        }
      })
      .catch(err => {
        console.error('Error fetching invoice details:', err);
        toast.error('Failed to load invoice details');
      })
      .finally(() => setDetailLoading(false));
  };

  const handleStatusFilterChange = (status) => {
    setFilterStatus(status);
    setCurrentPage(1); // reset to page 1
  };

  // Helper formats
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

  // Parsing stats from backend report summary
  const summary = reports?.summary || {};
  const totalAmount = summary.total_amount || 0;
  const paidAmount = summary.paid_amount || 0;
  const platformFee = summary.platform_fee || 0;
  const workerPayout = summary.worker_payout || 0;
  const totalInvoicesCount = summary.total_invoices || 0;

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      {/* Keyframe animation injected inline */}
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

      {/* Header and Page Actions */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Invoice Ledger</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Monitor transactions, compute commissions, and manage worker payouts.</p>
        </div>
      </div>

      {/* Statistics Cards Row */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 24 }}>
        <StatCard
          label="Gross Transactions (Paid)"
          value={formatCurrency(paidAmount)}
          icon="💳"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={reportsLoading}
        />
        <StatCard
          label="Net Commission Revenue"
          value={formatCurrency(platformFee)}
          icon="📈"
          bg="#F5F3FF"
          fg="#7C3AED"
          loading={reportsLoading}
        />
        <StatCard
          label="Professional Payouts"
          value={formatCurrency(workerPayout)}
          icon="💼"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={reportsLoading}
        />
        <StatCard
          label="Ledger Volume"
          value={reportsLoading ? '—' : `${totalInvoicesCount.toLocaleString()} Invoices`}
          icon="🧾"
          bg="var(--status-amber-bg)"
          fg="var(--status-amber-fg)"
          loading={reportsLoading}
        />
      </div>

      {/* Primary Container card */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        
        {/* Navigation Tabs */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--border-color)', background: '#FAFAFB', padding: '0 20px' }}>
          <button
            onClick={() => setActiveTab('invoices')}
            style={{
              padding: '16px 20px',
              background: 'none',
              border: 'none',
              borderBottom: activeTab === 'invoices' ? '2.5px solid var(--accent-color)' : '2.5px solid transparent',
              color: activeTab === 'invoices' ? 'var(--accent-color)' : 'var(--text-secondary)',
              fontWeight: activeTab === 'invoices' ? 600 : 500,
              fontSize: 13,
              cursor: 'pointer',
              transition: 'all 0.15s',
            }}
          >
            📋 Invoices List
          </button>
          <button
            onClick={() => setActiveTab('payouts')}
            style={{
              padding: '16px 20px',
              background: 'none',
              border: 'none',
              borderBottom: activeTab === 'payouts' ? '2.5px solid var(--accent-color)' : '2.5px solid transparent',
              color: activeTab === 'payouts' ? 'var(--accent-color)' : 'var(--text-secondary)',
              fontWeight: activeTab === 'payouts' ? 600 : 500,
              fontSize: 13,
              cursor: 'pointer',
              transition: 'all 0.15s',
            }}
          >
            💰 Professional Payouts Summary
          </button>
        </div>

        {/* Tab 1: INVOICES PANEL */}
        {activeTab === 'invoices' && (
          <div style={{ padding: '20px 24px' }}>
            
            {/* Filter Row */}
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
              {[
                { key: '', label: 'All Statuses' },
                { key: 'paid', label: 'Paid' },
                { key: 'pending', label: 'Pending' },
                { key: 'failed', label: 'Failed' },
                { key: 'cancelled', label: 'Cancelled' }
              ].map(opt => (
                <button
                  key={opt.key}
                  onClick={() => handleStatusFilterChange(opt.key)}
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

            {/* Error Message */}
            {error && (
              <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, marginBottom: 16, fontSize: 13 }}>
                ⚠️ <strong>Error loading data:</strong> {error}
              </div>
            )}

            {/* Invoices List Table */}
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Invoice Code</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Client</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Professional</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Total Fee</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Commission</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Payout</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'center' }}>Status</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Issued Date</th>
                    <th style={{ padding: '12px 16px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
                  </tr>
                </thead>
                <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
                  {loading ? (
                    [...Array(limit)].map((_, index) => (
                      <tr key={index} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="80px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="120px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="120px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="60px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="60px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="60px" /></td>
                        <td style={{ padding: '14px 16px', textAlign: 'center' }}><Skeleton w="70px" radius={12} /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="100px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="50px" /></td>
                      </tr>
                    ))
                  ) : invoices.length === 0 ? (
                    <tr>
                      <td colSpan="9" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                        <div style={{ fontSize: 32, marginBottom: 8 }}>🔍</div>
                        <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No invoices found</div>
                        <div style={{ fontSize: 12 }}>Try adjusting your filters.</div>
                      </td>
                    </tr>
                  ) : (
                    invoices.map((inv) => {
                      const badge = STATUS_BADGES[inv.status.toLowerCase()] || { bg: 'var(--border-color)', fg: 'var(--text-primary)', text: inv.status };
                      return (
                        <tr key={inv.id} style={{ borderBottom: '1px solid var(--bg-muted)', transition: 'background-color 0.15s' }} className="hover:bg-gray-50/50">
                          <td style={{ padding: '14px 16px', fontWeight: 600, color: 'var(--text-primary)' }}>{inv.invoice_number}</td>
                          <td style={{ padding: '14px 16px' }}>{inv.user_name || `Client #${inv.user_id}`}</td>
                          <td style={{ padding: '14px 16px' }}>{inv.worker_name || `Pro #${inv.worker_id}`}</td>
                          <td style={{ padding: '14px 16px', textAlign: 'right', fontWeight: 600 }}>{formatCurrency(inv.amount)}</td>
                          <td style={{ padding: '14px 16px', textAlign: 'right', color: 'var(--text-secondary)' }}>{formatCurrency(inv.platform_fee)}</td>
                          <td style={{ padding: '14px 16px', textAlign: 'right', color: 'var(--status-green-fg)', fontWeight: 500 }}>{formatCurrency(inv.worker_payout)}</td>
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
                          <td style={{ padding: '14px 16px', color: 'var(--text-secondary)' }}>{formatDate(inv.created_at)}</td>
                          <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                            <button
                              onClick={() => handleViewInvoice(inv.id)}
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
                              Details
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination Row */}
            {!loading && invoices.length > 0 && (
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
        )}

        {/* Tab 2: PAYOUTS PANEL */}
        {activeTab === 'payouts' && (
          <div style={{ padding: '20px 24px' }}>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Professional ID</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Name</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600 }}>Phone</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'center' }}>Jobs Completed</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Total Commission Paid</th>
                    <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Total Net Payout</th>
                  </tr>
                </thead>
                <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
                  {payoutsLoading ? (
                    [...Array(4)].map((_, idx) => (
                      <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="80px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="150px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="100px" /></td>
                        <td style={{ padding: '14px 16px', textAlign: 'center' }}><Skeleton w="40px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="80px" /></td>
                        <td style={{ padding: '14px 16px' }}><Skeleton w="80px" /></td>
                      </tr>
                    ))
                  ) : payouts.length === 0 ? (
                    <tr>
                      <td colSpan="6" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                        <div style={{ fontSize: 32, marginBottom: 8 }}>💼</div>
                        <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No payouts registered</div>
                        <div style={{ fontSize: 12 }}>Completed paid jobs populate this list.</div>
                      </td>
                    </tr>
                  ) : (
                    payouts.map((p) => (
                      <tr key={p.worker_id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                        <td style={{ padding: '14px 16px', color: 'var(--text-secondary)', fontWeight: 600 }}>#{p.worker_id}</td>
                        <td style={{ padding: '14px 16px', fontWeight: 600, color: 'var(--text-primary)' }}>{p.worker_name || 'Professional'}</td>
                        <td style={{ padding: '14px 16px' }}>{p.worker_phone || '—'}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'center', fontWeight: 600 }}>{p.invoice_count}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'right', color: '#7C3AED' }}>{formatCurrency(p.platform_fee)}</td>
                        <td style={{ padding: '14px 16px', textAlign: 'right', color: 'var(--status-green-fg)', fontWeight: 700 }}>{formatCurrency(p.payout_amount)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Invoice Detail Slide-over / Modal Overlay */}
      {selectedInvoice && (
        <div
          onClick={() => setSelectedInvoice(null)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(11, 15, 25, 0.4)',
            backdropFilter: 'blur(4px)',
            zIndex: 1000,
            display: 'flex',
            justifyContent: 'flex-end',
            transition: 'opacity 0.2s',
          }}
        >
          {/* Drawer Body */}
          <div
            onClick={(e) => e.stopPropagation()}
            className="animate-fade"
            style={{
              width: '100%',
              maxWidth: 500,
              height: '100%',
              background: 'var(--bg-card)',
              borderLeft: '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '-4px 0 24px rgba(0,0,0,0.08)',
              animation: 'slideIn 0.25s ease-out forwards',
            }}
          >
            {/* Modal Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--border-color)' }}>
              <div>
                <span style={{ fontSize: 11, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>INVOICE TRANSACTION</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>{selectedInvoice.invoice_number}</h3>
              </div>
              <button
                onClick={() => setSelectedInvoice(null)}
                style={{
                  background: 'none',
                  border: 'none',
                  fontSize: 20,
                  color: 'var(--text-muted)',
                  cursor: 'pointer',
                  padding: 4,
                  lineHeight: '1',
                }}
              >
                ✕
              </button>
            </div>

            {/* Modal Scrollable Contents */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
              
              {/* Status Banner */}
              <div style={{
                borderRadius: 12,
                padding: 16,
                backgroundColor: (STATUS_BADGES[selectedInvoice.status.toLowerCase()] || STATUS_BADGES.pending).bg,
                color: (STATUS_BADGES[selectedInvoice.status.toLowerCase()] || STATUS_BADGES.pending).fg,
                textAlign: 'center',
                marginBottom: 24,
              }}>
                <div style={{ fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600 }}>Ledger Transaction Status</div>
                <div style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>
                  {(STATUS_BADGES[selectedInvoice.status.toLowerCase()] || STATUS_BADGES.pending).text}
                </div>
              </div>

              {/* Transaction Metadata Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 28, borderBottom: '1px dashed var(--border-color)', paddingBottom: 24 }}>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 500, letterSpacing: '0.02em' }}>Client (User)</div>
                  <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-primary)', marginTop: 4 }}>{selectedInvoice.user_name || `User ID #${selectedInvoice.user_id}`}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>Consumer Node ID: #{selectedInvoice.user_id}</div>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 500, letterSpacing: '0.02em' }}>Professional (Worker)</div>
                  <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--text-primary)', marginTop: 4 }}>{selectedInvoice.worker_name || `Worker ID #${selectedInvoice.worker_id}`}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>Provider Node ID: #{selectedInvoice.worker_id}</div>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 500, letterSpacing: '0.02em' }}>Booking Reference</div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', marginTop: 4 }}>Booking Ref: #{selectedInvoice.booking_id}</div>
                </div>
                <div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 500, letterSpacing: '0.02em' }}>Issued Date</div>
                  <div style={{ fontSize: 13, color: 'var(--text-primary)', marginTop: 4 }}>{formatDate(selectedInvoice.created_at)}</div>
                </div>
              </div>

              {/* Fee breakdown list */}
              <div style={{ marginBottom: 28 }}>
                <h4 style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-primary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>Receipt Ledger Breakdown</h4>
                
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Service Charge (Gross)</span>
                    <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{formatCurrency(selectedInvoice.amount)}</span>
                  </div>
                  
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                    <span style={{ color: 'var(--text-secondary)' }}>Platform Commission (deducted)</span>
                    <span style={{ fontWeight: 600, color: '#7C3AED' }}>— {formatCurrency(selectedInvoice.platform_fee)}</span>
                  </div>
                  
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, borderBottom: '1px solid var(--border-color)', paddingBottom: 12 }}>
                    <span style={{ color: 'var(--status-green-fg)' }}>Net Payout to Professional</span>
                    <span style={{ fontWeight: 700, color: 'var(--status-green-fg)' }}>{formatCurrency(selectedInvoice.worker_payout)}</span>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 15, paddingTop: 4 }}>
                    <span style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Total Billing Value</span>
                    <span style={{ fontWeight: 800, color: 'var(--accent-color)' }}>{formatCurrency(selectedInvoice.amount)}</span>
                  </div>
                </div>
              </div>

              {/* Paid date indicator if paid */}
              {selectedInvoice.paid_at && (
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  backgroundColor: '#ECFDF5',
                  border: '0.5px solid #A7F3D0',
                  borderRadius: 10,
                  padding: 12,
                  fontSize: 12,
                  color: '#047857',
                }}>
                  <span>✓</span>
                  <span>Payment settled on <strong>{formatDate(selectedInvoice.paid_at)}</strong> via platform integrated gateway.</span>
                </div>
              )}

            </div>

            {/* Modal Footer */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '16px 24px', backgroundColor: '#FAFAFB', display: 'flex', gap: 10 }}>
              <button
                onClick={() => window.print()}
                style={{
                  flex: 1,
                  padding: '10px 14px',
                  borderRadius: 8,
                  border: '1px solid var(--border-color)',
                  background: 'var(--bg-card)',
                  color: 'var(--text-primary)',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                🖨️ Print Receipt
              </button>
              <button
                onClick={() => setSelectedInvoice(null)}
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
                Close Details
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
