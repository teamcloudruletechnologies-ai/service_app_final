import { useState, useEffect } from 'react';
import { usersAPI } from '../api';
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
          <Skeleton w="70px" h={24} />
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

export default function Users() {
  const [users, setUsers] = useState([]);
  const [allUsers, setAllUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // Pagination & Filtering
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [sortOrder, setSortOrder] = useState('ASC');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalDocs, setTotalDocs] = useState(0);
  const limit = 8;

  // Drawer status
  const [selectedUser, setSelectedUser] = useState(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });

  // Fetch Users List
  const fetchUsersList = () => {
    setLoading(true);
    setError('');
    
    const params = {
      sortBy,
      sortOrder
    };
    if (search.trim()) params.search = search.trim();
    if (filterStatus) params.status = filterStatus;

    usersAPI.getAll(params)
      .then(res => {
        if (res && res.success) {
          const rawUsers = res.data?.rows || res.data || [];
          const mapped = rawUsers.map(u => ({
            ...u,
            status: u.status
          }));
          setAllUsers(mapped);

          const totalDocs = mapped.length;
          const totalPages = Math.max(1, Math.ceil(totalDocs / limit));
          setTotalDocs(totalDocs);
          setTotalPages(totalPages);

          const startIndex = (currentPage - 1) * limit;
          setUsers(mapped.slice(startIndex, startIndex + limit));
        }
      })
      .catch(err => {
        console.error('Error fetching users:', err);
        setError(err?.message || 'Failed to load users database.');
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchUsersList();
  }, [currentPage, filterStatus, sortBy, sortOrder]);

  // Debounced search trigger
  useEffect(() => {
    const handler = setTimeout(() => {
      setCurrentPage(1);
      fetchUsersList();
    }, 300);
    return () => clearTimeout(handler);
  }, [search]);

  // Open detailed user view in drawer
  const handleViewDetails = (userId) => {
    setDrawerLoading(true);
    setSelectedUser({ id: userId }); // temporarily set ID to show drawer outline
    
    usersAPI.getById(userId)
      .then(res => {
        if (res && res.success && res.data) {
          const user = res.data;
          setSelectedUser(user);
        }
      })
      .catch(err => {
        console.error('Error fetching user detail:', err);
        toast.error('Failed to load customer profile details.');
        setSelectedUser(null);
      })
      .finally(() => setDrawerLoading(false));
  };

  // Toggle Block/Unblock (uses suspended/active status matching backend)
  const handleToggleBlock = (user) => {
    const isCurrentlySuspended = user.status === 'suspended';
    const action = isCurrentlySuspended ? 'unblock' : 'block';
    
    setConfirmConfig({
      isOpen: true,
      title: `${action === 'block' ? 'Block' : 'Unblock'} Customer Account`,
      message: `Are you sure you want to ${action} account for ${user.name}?`,
      confirmText: action === 'block' ? 'Block User' : 'Unblock User',
      variant: action === 'block' ? 'danger' : 'warning',
      onConfirm: () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        const apiCall = isCurrentlySuspended ? usersAPI.unblock : usersAPI.block;
        apiCall(user.id)
          .then(res => {
            if (res && res.success) {
              toast.success(`User ${user.name} ${action}ed successfully!`);
              fetchUsersList();
              if (selectedUser && selectedUser.id === user.id) {
                handleViewDetails(user.id);
              }
            }
          })
          .catch(err => {
            console.error(`Failed to ${action} user:`, err);
            toast.error(err?.message || `Failed to update status.`);
          });
      }
    });
  };

  // Delete User
  const handleDeleteUser = (user) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Delete Customer Account',
      message: `WARNING: Are you sure you want to permanently delete ${user.name}?\nAll their booking records and activity logs will be cascade deleted. This cannot be undone.`,
      confirmText: 'Delete Account',
      variant: 'danger',
      onConfirm: () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        usersAPI.delete(user.id)
          .then(res => {
            if (res && res.success) {
              toast.success(`User ${user.name} deleted successfully!`);
              fetchUsersList();
              if (selectedUser && selectedUser.id === user.id) {
                setSelectedUser(null);
              }
            }
          })
          .catch(err => {
            console.error('Failed to delete user:', err);
            toast.error(err?.message || 'Failed to delete user account.');
          });
      }
    });
  };

  // Stats calculation relative to total data
  const totalUsersCount = totalDocs;
  const activeCount = allUsers.filter(u => u.status === 'active').length; 
  const blockedCount = allUsers.filter(u => u.status === 'suspended').length;

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
      day: 'numeric'
    });
  };

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
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Customer Accounts Management</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Search customer profiles, track service requests history, and flag or delete security accounts.</p>
        </div>
      </div>

      {/* Statistics */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total Customers"
          value={totalUsersCount}
          icon="👥"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={loading}
        />
        <StatCard
          label="Active Accounts"
          value={activeCount}
          icon="🟢"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={loading}
        />
        <StatCard
          label="Suspended Accounts"
          value={blockedCount}
          icon="🔴"
          bg="var(--status-red-bg)"
          fg="var(--status-red-fg)"
          loading={loading}
        />
      </div>

      {/* Table Card */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        
        {/* Controls */}
        <div style={{ padding: '20px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          
          {/* Search bar */}
          <div style={{ position: 'relative', flex: 1, minWidth: 260, maxWidth: 400 }}>
            <input
              type="text"
              placeholder="Search by name, email or phone..."
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
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500 }}
            >
              <option value="">All Statuses</option>
              <option value="active">Active Accounts</option>
              <option value="suspended">Suspended Accounts</option>
            </select>

            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500 }}
            >
              <option value="name">Sort by Name</option>
              <option value="email">Sort by Email</option>
              <option value="created_at">Sort by Joined Date</option>
            </select>

            <button
              onClick={() => setSortOrder(prev => prev === 'ASC' ? 'DESC' : 'ASC')}
              style={{
                padding: '6px 10px',
                borderRadius: 8,
                border: '1px solid #D1D5DB',
                backgroundColor: 'var(--bg-card)',
                cursor: 'pointer',
                fontSize: 14,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                transition: 'all 0.1s'
              }}
              title="Toggle Sort Direction"
            >
              {sortOrder === 'ASC' ? '🔼' : '🔽'}
            </button>
          </div>
        </div>

        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, margin: '20px 24px 0', fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
          </div>
        )}

        {/* Table list */}
        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Customer Info</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Email Address</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Phone Number</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Joined Date</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Status</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(6)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <Skeleton w="32px" h="32px" radius={16} />
                        <Skeleton w="100px" />
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="140px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="100px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="60px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="140px" /></td>
                  </tr>
                ))
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 32, marginBottom: 8 }}>🔍</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No customers found</div>
                    <div style={{ fontSize: 12 }}>Try adjusting your search query or status filter.</div>
                  </td>
                </tr>
              ) : (
                users.map(u => (
                  <tr key={u.id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                        <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, border: '1px solid var(--border-color)' }}>
                          {u.name.substring(0,2).toUpperCase()}
                        </div>
                        <span style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{u.name}</span>
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px', color: 'var(--text-primary)' }}>{u.email || '—'}</td>
                    <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>{u.phone || '—'}</td>
                    <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>{formatDate(u.created_at)}</td>
                    <td style={{ padding: '14px 8px' }}>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        fontSize: 10,
                        borderRadius: 12,
                        padding: '1px 8px',
                        fontWeight: 700,
                        backgroundColor: u.status === 'suspended' ? 'var(--status-red-bg)' : 'var(--status-green-bg)',
                        color: u.status === 'suspended' ? 'var(--status-red-fg)' : 'var(--status-green-fg)'
                      }}>
                        {u.status === 'suspended' ? '🔴 Suspended' : '🟢 Active'}
                      </span>
                    </td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                      <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
                        <button
                          onClick={() => handleViewDetails(u.id)}
                          style={{ border: '1px solid var(--border-color)', background: 'var(--bg-card)', borderRadius: 6, padding: '4px 8px', fontSize: 11, fontWeight: 500, color: 'var(--text-primary)', cursor: 'pointer' }}
                        >
                          👁️ View
                        </button>
                        <button
                          onClick={() => handleToggleBlock(u)}
                          style={{
                            border: '1px solid',
                            borderColor: u.status === 'suspended' ? 'var(--status-green-fg)' : 'var(--status-amber-fg)',
                            background: u.status === 'suspended' ? '#EFFDF5' : 'var(--status-amber-bg)',
                            borderRadius: 6,
                            padding: '4px 8px',
                            fontSize: 11,
                            fontWeight: 600,
                            color: u.status === 'suspended' ? 'var(--status-green-fg)' : 'var(--status-amber-fg)',
                            cursor: 'pointer'
                          }}
                        >
                          {u.status === 'suspended' ? '🔓 Unblock' : '🚫 Suspend'}
                        </button>
                        <button
                          onClick={() => handleDeleteUser(u)}
                          style={{ border: '1px solid #FCA5A5', background: 'var(--status-red-bg)', borderRadius: 6, padding: '4px 8px', fontSize: 11, fontWeight: 600, color: 'var(--status-red-fg)', cursor: 'pointer' }}
                        >
                          🗑️ Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Controls */}
        {!loading && users.length > 0 && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', borderTop: '0.5px solid var(--bg-muted)' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> (<strong>{totalDocs}</strong> total accounts)
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

      {/* Sliding detail drawer */}
      {selectedUser && (
        <div
          onClick={() => setSelectedUser(null)}
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
              maxWidth: 520,
              height: '100%',
              background: 'var(--bg-card)',
              borderLeft: '1px solid var(--border-color)',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '-4px 0 24px rgba(0,0,0,0.08)',
              animation: 'slideIn 0.25s ease-out forwards',
            }}
          >
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 24px', borderBottom: '1px solid var(--border-color)' }}>
              <div>
                <span style={{ fontSize: 11, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>CUSTOMER OVERVIEW</span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>Profile details</h3>
              </div>
              <button
                onClick={() => setSelectedUser(null)}
                style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >
                ✕
              </button>
            </div>

            {/* Scroll Body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
              {drawerLoading ? (
                <div style={{ padding: 20, textAlign: 'center', color: 'var(--text-secondary)' }}>
                  <div style={{ border: '3px solid #f3f3f3', borderTop: '3px solid var(--accent-color)', borderRadius: '50%', width: 24, height: 24, animation: 'spin 1s linear infinite', margin: '0 auto 10px' }} />
                  <span>Loading full profiles...</span>
                  <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
                </div>
              ) : !selectedUser.name ? (
                <div style={{ color: '#EF4444' }}>Failed to load data. Close and try again.</div>
              ) : (
                <div className="animate-fade">
                  {/* Avatar Profile Grid */}
                  <div style={{ display: 'flex', gap: 16, alignItems: 'center', marginBottom: 24, paddingBottom: 20, borderBottom: '1px solid var(--border-color)' }}>
                    <div style={{ width: 64, height: 64, borderRadius: 16, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, border: '2px solid var(--accent-color)' }}>
                      {selectedUser.name.substring(0,2).toUpperCase()}
                    </div>
                    <div>
                      <h4 style={{ fontSize: 16, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>{selectedUser.name}</h4>
                      <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 6px' }}>Joined on {formatDate(selectedUser.created_at)}</p>
                      <span style={{
                        display: 'inline-flex',
                        fontSize: 9,
                        borderRadius: 10,
                        padding: '1px 6px',
                        fontWeight: 700,
                        backgroundColor: selectedUser.status === 'suspended' ? 'var(--status-red-bg)' : 'var(--status-green-bg)',
                        color: selectedUser.status === 'suspended' ? 'var(--status-red-fg)' : 'var(--status-green-fg)'
                      }}>
                        {selectedUser.status === 'suspended' ? '🔴 Suspended' : '🟢 Active'}
                      </span>
                    </div>
                  </div>

                  {/* Core details list */}
                  <div style={{ marginBottom: 28 }}>
                    <h5 style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>Contact details</h5>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 13 }}>
                      <div><span style={{ color: 'var(--text-secondary)' }}>Email Address:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedUser.email || '—'}</strong></div>
                      <div><span style={{ color: 'var(--text-secondary)' }}>Phone Number:</span> <strong style={{ color: 'var(--text-primary)' }}>{selectedUser.phone || '—'}</strong></div>
                      <div><span style={{ color: 'var(--text-secondary)' }}>Database User ID:</span> <strong style={{ color: 'var(--text-primary)', fontFamily: 'monospace' }}>#{selectedUser.id}</strong></div>
                    </div>
                  </div>

                  {/* Booking list */}
                  <div style={{ marginBottom: 28 }}>
                    <h5 style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>Booking list history</h5>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                      {selectedUser.bookings && selectedUser.bookings.length > 0 ? (
                        selectedUser.bookings.map(b => (
                          <div key={b.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: 'var(--bg-app)', border: '1px solid var(--border-color)', borderRadius: 8 }}>
                            <div>
                              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>{b.service_name || 'Service Booking'}</div>
                              <div style={{ fontSize: 11, color: 'var(--text-secondary)' }}>ID: #{b.id.substring(0,8)} • {formatDate(b.booking_date)}</div>
                            </div>
                            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4 }}>
                              <strong style={{ fontSize: 13, color: 'var(--text-primary)' }}>{formatCurrency(b.amount)}</strong>
                              <span style={{ fontSize: 9, textTransform: 'uppercase', fontWeight: 700, color: b.status === 'completed' ? 'var(--status-green-fg)' : 'var(--status-amber-fg)' }}>{b.status}</span>
                            </div>
                          </div>
                        ))
                      ) : (
                        <div style={{ border: '1px dashed var(--border-color)', borderRadius: 8, padding: 16, textAlign: 'center', fontSize: 12, color: 'var(--text-muted)' }}>No bookings found.</div>
                      )}
                    </div>
                  </div>

                  {/* System activity logs */}
                  <div>
                    <h5 style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 12 }}>System Activity log</h5>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12, paddingLeft: 12, borderLeft: '1px solid var(--border-color)', marginLeft: 6 }}>
                      {selectedUser.activity_logs && selectedUser.activity_logs.length > 0 ? (
                        selectedUser.activity_logs.map(l => (
                          <div key={l.id} style={{ position: 'relative' }}>
                            <div style={{ position: 'absolute', left: -16, top: 4, width: 7, height: 7, borderRadius: '50%', backgroundColor: 'var(--accent-color)' }} />
                            <div style={{ fontSize: 13, color: 'var(--text-primary)', fontWeight: 500 }}>{l.action}</div>
                            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>IP: {l.ip_address || '—'} • {new Date(l.timestamp).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}</div>
                          </div>
                        ))
                      ) : (
                        <div style={{ fontSize: 12, color: 'var(--text-muted)', fontStyle: 'italic' }}>No activity records found.</div>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Footer */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '16px 24px', backgroundColor: '#FAFAFB', display: 'flex', gap: 10 }}>
              <button
                onClick={() => setSelectedUser(null)}
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
                Close Drawer
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
