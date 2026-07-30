import { useState, useEffect } from 'react';
import { kycAPI } from '../api';
import { toast } from 'react-toastify';

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

export default function Kyc() {
  const [kycRecords, setKycRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Pagination & Filtering
  const [filterStatus, setFilterStatus] = useState('');
  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalDocs, setTotalDocs] = useState(0);
  const limit = 8;

  // Stats
  const [stats, setStats] = useState({ total: 0, pending: 0, pendingCorrection: 0, approved: 0 });

  // Detail Drawer
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [submittingReview, setSubmittingReview] = useState(false);

  // Document states inside Drawer
  const [aadhaarState, setAadhaarState] = useState('pending');
  const [panState, setPanState] = useState('pending');
  const [bankPassbookState, setBankPassbookState] = useState('pending');
  const [selfieState, setSelfieState] = useState('pending');
  const [rejectionReason, setRejectionReason] = useState('');

  // Image zoom Lightbox Modal
  const [activeLightboxImage, setActiveLightboxImage] = useState(null);

  // Fetch KYC list and compute counts
  const fetchKycList = () => {
    setLoading(true);
    setError('');

    const params = {
      page: currentPage,
      limit: limit
    };
    if (filterStatus) params.status = filterStatus;

    kycAPI.getAll(params)
      .then(res => {
        if (res && res.success && res.data) {
          const rows = res.data.rows || [];
          setKycRecords(rows);
          setTotalDocs(res.data.meta?.total || rows.length);
          setTotalPages(res.data.meta?.totalPages || 1);
        }
      })
      .catch(err => {
        console.error('Error fetching KYC records:', err);
        setError(err?.message || 'Failed to load KYC submissions.');
      })
      .finally(() => setLoading(false));
  };

  // Fetch statistics summary (all records at once to count statuses)
  const fetchStats = () => {
    kycAPI.getAll({ limit: 1000 })
      .then(res => {
        if (res && res.success && res.data) {
          // list returns paged: { rows, meta } stored under res.data
          const rows = res.data.rows || [];
          const total = Number(res.data.meta?.total || rows.length);
          const pending = rows.filter(r => r.status === 'pending').length;
          const pendingCorrection = rows.filter(r => r.status === 'pending_correction').length;
          const approved = rows.filter(r => r.status === 'approved').length;
          setStats({ total, pending, pendingCorrection, approved });
        }
      })
      .catch(err => console.error('Error fetching KYC statistics:', err));
  };

  useEffect(() => {
    fetchKycList();
  }, [currentPage, filterStatus]);

  useEffect(() => {
    fetchStats();
  }, [kycRecords]);

  // Open detailed record view
  const handleOpenReview = (recordId) => {
    setDrawerLoading(true);
    setSelectedRecord({ id: recordId }); // Open drawer stub
    setRejectionReason('');

    kycAPI.getById(recordId)
      .then(res => {
        // backend: success(res, msg, kyc) => { success, message, data: kyc }
        if (res && res.success && res.data) {
          const kyc = res.data;
          setSelectedRecord(kyc);
          setAadhaarState(kyc.aadhaar_status || 'pending');
          setPanState(kyc.pan_status || 'pending');
          setBankPassbookState(kyc.bank_passbook_status || 'pending');
          setSelfieState(kyc.selfie_status || 'pending');
          setRejectionReason(kyc.rejection_reason || '');
        }
      })
      .catch(err => {
        console.error('Error loading KYC details:', err);
        toast.error('Failed to load KYC document details.');
        setSelectedRecord(null);
      })
      .finally(() => setDrawerLoading(false));
  };

  // Submit Review handlers
  const handleSubmitReview = () => {
    const isAnyRejected = 
      aadhaarState === 'rejected' || 
      panState === 'rejected' || 
      bankPassbookState === 'rejected' || 
      selfieState === 'rejected';

    if (isAnyRejected && !rejectionReason.trim()) {
      toast.warning('Please specify a rejection reason for the rejected document(s).');
      return;
    }

    setSubmittingReview(true);

    const payload = {
      aadhaarStatus: aadhaarState,
      panStatus: panState,
      bankPassbookStatus: bankPassbookState,
      selfieStatus: selfieState,
      ...(isAnyRejected ? { rejectionReason: rejectionReason.trim() } : {}),
    };

    kycAPI.review(selectedRecord.id, payload)
      .then(res => {
        // backend: success(res, 'KYC reviewed', kyc) => { success: true, message, data }
        if (res && res.success) {
          toast.success(`KYC review submitted! Status updated to: ${res.data?.status || 'updated'}`);
          setSelectedRecord(null);
          fetchKycList();
          fetchStats();
        }
      })
      .catch(err => {
        console.error('Error submitting review:', err);
        toast.error(err?.message || 'Failed to submit KYC review.');
      })
      .finally(() => setSubmittingReview(false));
  };

  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'approved':
        return { text: '🟢 Approved', bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' };
      case 'rejected':
        return { text: '🔴 Rejected', bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' };
      case 'pending_correction':
        return { text: '🔵 Pending Fixes', bg: '#E0F2FE', fg: '#0369A1' };
      default:
        return { text: '🟡 Pending Review', bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' };
    }
  };

  const getDocStatusIcon = (status) => {
    switch (status) {
      case 'approved':
        return <span style={{ color: '#10B981', fontSize: 13 }} title="Approved">✅</span>;
      case 'rejected':
        return <span style={{ color: '#EF4444', fontSize: 13 }} title="Rejected">❌</span>;
      default:
        return <span style={{ color: '#F59E0B', fontSize: 13 }} title="Pending Review">⏳</span>;
    }
  };

  // Filter local rows matching search (worker name/service type)
  const filteredRecords = kycRecords.filter(r => {
    const term = search.toLowerCase().trim();
    if (!term) return true;
    return (
      (r.worker_name || '').toLowerCase().includes(term) ||
      (r.worker_phone || '').includes(term) ||
      (r.service_type || '').toLowerCase().includes(term)
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
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes slideIn {
          from { transform: translateX(100%); }
          to { transform: translateX(0); }
        }
        .animate-fade {
          animation: fadeIn 0.2s ease-out forwards;
        }
        .doc-card {
          border: 1.5px solid var(--bg-muted);
          border-radius: 12px;
          padding: 16px;
          background: var(--bg-card);
          transition: all 0.2s ease;
        }
        .doc-card:hover {
          border-color: var(--border-color);
          box-shadow: 0 4px 12px rgba(0,0,0,0.02);
        }
        .toggle-btn {
          flex: 1;
          padding: 8px 12px;
          font-size: 12px;
          font-weight: 600;
          border-radius: 8px;
          border: 1px solid var(--border-color);
          background: var(--bg-card);
          color: var(--text-secondary);
          cursor: pointer;
          transition: all 0.15s ease;
        }
        .toggle-btn.approve-active {
          background: var(--status-green-bg);
          color: var(--status-green-fg);
          border-color: #A7F3D0;
        }
        .toggle-btn.reject-active {
          background: var(--status-red-bg);
          color: var(--status-red-fg);
          border-color: #FCA5A5;
        }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>KYC Document Verifications</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Review worker identity credentials, bank details, and selfies to activate operational profiles.</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total KYC Submissions"
          value={stats.total}
          icon="🪪"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={loading}
        />
        <StatCard
          label="Pending Review"
          value={stats.pending}
          icon="⏳"
          bg="var(--status-amber-bg)"
          fg="var(--status-amber-fg)"
          loading={loading}
        />
        <StatCard
          label="Pending Corrections"
          value={stats.pendingCorrection}
          icon="🔵"
          bg="#E0F2FE"
          fg="#0369A1"
          loading={loading}
        />
        <StatCard
          label="Approved Profiles"
          value={stats.approved}
          icon="✅"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={loading}
        />
      </div>

      {/* Controls Container */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        
        {/* Top Controls */}
        <div style={{ padding: '20px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          {/* Search bar */}
          <div style={{ position: 'relative', flex: 1, minWidth: 260, maxWidth: 400 }}>
            <input
              type="text"
              placeholder="Search by worker name, phone or service..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px 8px 34px',
                border: '1px solid #D1D5DB',
                borderRadius: 8,
                fontSize: 13,
                outline: 'none',
                fontFamily: "'DM Sans', sans-serif"
              }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)', fontSize: 15 }}>🔍</span>
          </div>

          {/* Filters */}
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <select
              value={filterStatus}
              onChange={(e) => { setFilterStatus(e.target.value); setCurrentPage(1); }}
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500, fontFamily: 'inherit' }}
            >
              <option value="">All Statuses</option>
              <option value="pending">Pending Review</option>
              <option value="pending_correction">Pending Corrections</option>
              <option value="approved">Approved Submissions</option>
              <option value="rejected">Rejected Submissions</option>
            </select>
          </div>
        </div>

        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, margin: '20px 24px 0', fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
          </div>
        )}

        {/* Table representation */}
        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 850 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Worker Name</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Service Type</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Submitted Date</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Aadhaar</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>PAN</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Passbook</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Selfie</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Global Status</th>
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
                        <Skeleton w="100px" />
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="80px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="20px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="20px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="20px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="20px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="80px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="60px" /></td>
                  </tr>
                ))
              ) : filteredRecords.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 32, marginBottom: 8 }}>📁</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No KYC submissions found</div>
                    <div style={{ fontSize: 12 }}>Check your filters or try a different status search.</div>
                  </td>
                </tr>
              ) : (
                filteredRecords.map(r => {
                  const badge = getStatusBadge(r.status);
                  return (
                    <tr key={r.id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 32, height: 32, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, border: '1px solid var(--border-color)' }}>
                            {r.worker_name ? r.worker_name.substring(0, 2).toUpperCase() : 'W'}
                          </div>
                          <div>
                            <span style={{ fontWeight: 600, color: 'var(--text-primary)', display: 'block' }}>{r.worker_name || 'Worker'}</span>
                            <span style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{r.worker_phone || 'No phone'}</span>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-primary)', fontWeight: 500 }}>
                        {r.service_type ? r.service_type.charAt(0).toUpperCase() + r.service_type.slice(1) : '—'}
                      </td>
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>{formatDate(r.created_at)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>{getDocStatusIcon(r.aadhaar_status)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>{getDocStatusIcon(r.pan_status)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>{getDocStatusIcon(r.bank_passbook_status)}</td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>{getDocStatusIcon(r.selfie_status)}</td>
                      <td style={{ padding: '14px 8px' }}>
                        <span style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          fontSize: 10,
                          borderRadius: 12,
                          padding: '1px 8px',
                          fontWeight: 700,
                          backgroundColor: badge.bg,
                          color: badge.fg
                        }}>
                          {badge.text}
                        </span>
                      </td>
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <button
                          onClick={() => handleOpenReview(r.id)}
                          style={{
                            border: '1px solid var(--border-color)',
                            background: 'var(--bg-card)',
                            borderRadius: 6,
                            padding: '4px 10px',
                            fontSize: 11,
                            fontWeight: 600,
                            color: 'var(--accent-color)',
                            cursor: 'pointer',
                            transition: 'all 0.1s'
                          }}
                        >
                          Review
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination bar */}
        {!loading && filteredRecords.length > 0 && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', borderTop: '0.5px solid var(--bg-muted)' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> (<strong>{totalDocs}</strong> submissions)
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

      {/* Review Drawer Overlay */}
      {selectedRecord && (
        <div
          onClick={() => { if (!submittingReview) setSelectedRecord(null); }}
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
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: '100%',
              maxWidth: 600,
              height: '100%',
              background: 'var(--bg-card)',
              borderLeft: '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '-4px 0 24px rgba(0,0,0,0.08)',
              animation: 'slideIn 0.25s ease-out forwards',
            }}
          >
            {/* Drawer Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--border-color)' }}>
              <div>
                <span style={{ fontSize: 10, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>KYC DOCUMENT VERIFIER</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>Review Submission</h3>
              </div>
              <button
                disabled={submittingReview}
                onClick={() => setSelectedRecord(null)}
                style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >
                ✕
              </button>
            </div>

            {/* Scroll Content Body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
              {drawerLoading ? (
                <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
                  <div style={{ border: '3px solid #f3f3f3', borderTop: '3px solid var(--accent-color)', borderRadius: '50%', width: 24, height: 24, animation: 'spin 1s linear infinite', margin: '0 auto 10px' }} />
                  <span>Loading full submission files...</span>
                  <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
                </div>
              ) : !selectedRecord.worker_name ? (
                <div style={{ color: '#EF4444' }}>Failed to retrieve verification file. Please try again.</div>
              ) : (
                <div className="animate-fade">
                  {/* Worker Metadata summary */}
                  <div style={{ background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 12, padding: 16, marginBottom: 24, display: 'flex', gap: 12, alignItems: 'center' }}>
                    <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'var(--accent-color)', color: 'var(--bg-card)', fontSize: 16, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      {selectedRecord.worker_name.substring(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <strong style={{ fontSize: 15, color: 'var(--text-primary)', display: 'block' }}>{selectedRecord.worker_name}</strong>
                      <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
                        {selectedRecord.service_type ? selectedRecord.service_type.charAt(0).toUpperCase() + selectedRecord.service_type.slice(1) : 'General'} Worker • Phone: {selectedRecord.worker_phone}
                      </span>
                    </div>
                  </div>

                  {/* Documents Grid */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                    {/* 1. Aadhaar Card */}
                    <div className="doc-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>1. Aadhaar Card Detail</span>
                        <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>Number: <strong>{selectedRecord.aadhaar_number}</strong></span>
                      </div>
                      
                      {selectedRecord.aadhaar_url && (
                        <div style={{ width: '100%', height: 160, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-muted)', border: '1px solid var(--border-color)', position: 'relative', marginBottom: 12, cursor: 'pointer' }}
                             onClick={() => setActiveLightboxImage(selectedRecord.aadhaar_url)}>
                          <img src={selectedRecord.aadhaar_url} alt="Aadhaar Scan" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.2)', opacity: 0, transition: 'opacity 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--bg-card)', fontSize: 12, fontWeight: 600 }}
                               onMouseEnter={(e) => e.currentTarget.style.opacity = 1}
                               onMouseLeave={(e) => e.currentTarget.style.opacity = 0}>
                            🔍 Click to Zoom
                          </div>
                        </div>
                      )}
                      
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button className={`toggle-btn ${aadhaarState === 'approved' ? 'approve-active' : ''}`}
                                onClick={() => setAadhaarState('approved')}>
                          Approve ✅
                        </button>
                        <button className={`toggle-btn ${aadhaarState === 'rejected' ? 'reject-active' : ''}`}
                                onClick={() => setAadhaarState('rejected')}>
                          Reject ❌
                        </button>
                      </div>
                    </div>

                    {/* 2. PAN Card */}
                    <div className="doc-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>2. PAN Card Detail</span>
                        <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>Number: <strong>{selectedRecord.pan_number}</strong></span>
                      </div>

                      {selectedRecord.pan_url && (
                        <div style={{ width: '100%', height: 160, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-muted)', border: '1px solid var(--border-color)', position: 'relative', marginBottom: 12, cursor: 'pointer' }}
                             onClick={() => setActiveLightboxImage(selectedRecord.pan_url)}>
                          <img src={selectedRecord.pan_url} alt="PAN Scan" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.2)', opacity: 0, transition: 'opacity 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--bg-card)', fontSize: 12, fontWeight: 600 }}
                               onMouseEnter={(e) => e.currentTarget.style.opacity = 1}
                               onMouseLeave={(e) => e.currentTarget.style.opacity = 0}>
                            🔍 Click to Zoom
                          </div>
                        </div>
                      )}

                      <div style={{ display: 'flex', gap: 8 }}>
                        <button className={`toggle-btn ${panState === 'approved' ? 'approve-active' : ''}`}
                                onClick={() => setPanState('approved')}>
                          Approve ✅
                        </button>
                        <button className={`toggle-btn ${panState === 'rejected' ? 'reject-active' : ''}`}
                                onClick={() => setPanState('rejected')}>
                          Reject ❌
                        </button>
                      </div>
                    </div>

                    {/* 3. Bank Passbook */}
                    <div className="doc-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>3. Bank Passbook Detail</span>
                        <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>Account No: <strong>{selectedRecord.bank_account_number}</strong></span>
                      </div>

                      {selectedRecord.bank_passbook_url && (
                        <div style={{ width: '100%', height: 160, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-muted)', border: '1px solid var(--border-color)', position: 'relative', marginBottom: 12, cursor: 'pointer' }}
                             onClick={() => setActiveLightboxImage(selectedRecord.bank_passbook_url)}>
                          <img src={selectedRecord.bank_passbook_url} alt="Passbook Scan" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.2)', opacity: 0, transition: 'opacity 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--bg-card)', fontSize: 12, fontWeight: 600 }}
                               onMouseEnter={(e) => e.currentTarget.style.opacity = 1}
                               onMouseLeave={(e) => e.currentTarget.style.opacity = 0}>
                            🔍 Click to Zoom
                          </div>
                        </div>
                      )}

                      <div style={{ display: 'flex', gap: 8 }}>
                        <button className={`toggle-btn ${bankPassbookState === 'approved' ? 'approve-active' : ''}`}
                                onClick={() => setBankPassbookState('approved')}>
                          Approve ✅
                        </button>
                        <button className={`toggle-btn ${bankPassbookState === 'rejected' ? 'reject-active' : ''}`}
                                onClick={() => setBankPassbookState('rejected')}>
                          Reject ❌
                        </button>
                      </div>
                    </div>

                    {/* 4. Selfie */}
                    <div className="doc-card">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--text-primary)' }}>4. Selfie Picture</span>
                      </div>

                      {selectedRecord.selfie_url && (
                        <div style={{ width: '100%', height: 160, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-muted)', border: '1px solid var(--border-color)', position: 'relative', marginBottom: 12, cursor: 'pointer' }}
                             onClick={() => setActiveLightboxImage(selectedRecord.selfie_url)}>
                          <img src={selectedRecord.selfie_url} alt="Selfie Scan" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.2)', opacity: 0, transition: 'opacity 0.2s', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--bg-card)', fontSize: 12, fontWeight: 600 }}
                               onMouseEnter={(e) => e.currentTarget.style.opacity = 1}
                               onMouseLeave={(e) => e.currentTarget.style.opacity = 0}>
                            🔍 Click to Zoom
                          </div>
                        </div>
                      )}

                      <div style={{ display: 'flex', gap: 8 }}>
                        <button className={`toggle-btn ${selfieState === 'approved' ? 'approve-active' : ''}`}
                                onClick={() => setSelfieState('approved')}>
                          Approve ✅
                        </button>
                        <button className={`toggle-btn ${selfieState === 'rejected' ? 'reject-active' : ''}`}
                                onClick={() => setSelfieState('rejected')}>
                          Reject ❌
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Rejection Reason textarea (only displayed if any document is rejected) */}
                  {(aadhaarState === 'rejected' || panState === 'rejected' || bankPassbookState === 'rejected' || selfieState === 'rejected') && (
                    <div style={{ marginTop: 24, animation: 'fadeIn 0.2s ease-out' }}>
                      <label style={{ display: 'block', fontSize: 12, fontWeight: 700, color: '#E11D48', marginBottom: 6 }}>Rejection Reason (Required) ⚠️</label>
                      <textarea
                        rows="3"
                        placeholder="Explain to the worker what needs to be uploaded or corrected (e.g. Blurry photo, mismatched names, invalid bank details)..."
                        value={rejectionReason}
                        onChange={(e) => setRejectionReason(e.target.value)}
                        style={{
                          width: '100%',
                          padding: '10px 12px',
                          border: '1.5px solid #FCA5A5',
                          borderRadius: 8,
                          fontSize: 13,
                          outline: 'none',
                          color: 'var(--text-primary)',
                          fontFamily: "inherit"
                        }}
                      />
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Drawer Footer Actions */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '16px 24px', backgroundColor: '#FAFAFB', display: 'flex', gap: 12 }}>
              <button
                disabled={submittingReview || drawerLoading}
                onClick={() => setSelectedRecord(null)}
                style={{
                  flex: 1,
                  padding: '10px 14px',
                  borderRadius: 8,
                  border: '1px solid #D1D5DB',
                  background: 'var(--bg-card)',
                  color: 'var(--text-secondary)',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: submittingReview || drawerLoading ? 'not-allowed' : 'pointer',
                }}
              >
                Cancel
              </button>
              <button
                disabled={submittingReview || drawerLoading}
                onClick={handleSubmitReview}
                style={{
                  flex: 2,
                  padding: '10px 14px',
                  borderRadius: 8,
                  border: 'none',
                  background: submittingReview || drawerLoading ? 'var(--text-muted)' : 'var(--accent-color)',
                  color: 'var(--bg-card)',
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: submittingReview || drawerLoading ? 'not-allowed' : 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 6
                }}
              >
                {submittingReview ? (
                  <>
                    <div style={{ border: '2px solid var(--bg-card)', borderTop: '2px solid transparent', borderRadius: '50%', width: 12, height: 12, animation: 'spin 1s linear infinite' }} />
                    Submitting...
                  </>
                ) : 'Submit Review Decisions'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Lightbox Zoom Overlay Modal */}
      {activeLightboxImage && (
        <div
          onClick={() => setActiveLightboxImage(null)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.85)',
            backdropFilter: 'blur(8px)',
            zIndex: 2000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 30,
            cursor: 'zoom-out'
          }}
        >
          <button
            onClick={() => setActiveLightboxImage(null)}
            style={{
              position: 'absolute',
              top: 24,
              right: 24,
              background: 'rgba(255,255,255,0.1)',
              border: 'none',
              borderRadius: '50%',
              width: 40,
              height: 40,
              color: 'var(--bg-card)',
              fontSize: 20,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transition: 'background 0.2s'
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.2)'}
            onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.1)'}
          >
            ✕
          </button>
          <img
            src={activeLightboxImage}
            alt="Enlarged Scan Proof"
            onClick={(e) => e.stopPropagation()}
            style={{
              maxWidth: '90%',
              maxHeight: '90%',
              borderRadius: 12,
              boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
              objectFit: 'contain',
              cursor: 'default'
            }}
          />
        </div>
      )}
    </div>
  );
}
