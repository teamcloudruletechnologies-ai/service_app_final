import { useState, useEffect } from 'react';
import { rolesAPI } from '../api';
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

const AVAILABLE_PERMISSIONS = [
  { key: 'users', label: 'Manage Users', desc: 'Edit, block/unblock, and delete platform users' },
  { key: 'workers', label: 'Manage Workers', desc: 'Approve, suspend, and view performance of workers' },
  { key: 'kyc', label: 'Manage KYC', desc: 'Approve and reject identity verification submissions' },
  { key: 'bookings', label: 'Manage Bookings', desc: 'Monitor and modify booking states & assignments' },
  { key: 'invoices', label: 'Manage Invoices', desc: 'Process and view invoice details and payouts' },
  { key: 'services', label: 'Manage Services', desc: 'Create/update services, categories, and adjust service states' },
  { key: 'banners', label: 'Manage Banners', desc: 'Create, edit and delete promotion/marketing banners' },
  { key: 'complaints', label: 'Manage Support', desc: 'Resolve client complaints and add admin notes' },
  { key: 'locations', label: 'Manage Locations', desc: 'Edit operational zones, pincodes, and tracking' },
  { key: 'dashboard', label: 'View Dashboard', desc: 'Access high-level overview metrics and stats charts' },
  { key: 'notifications', label: 'Manage Notifications', desc: 'View, read, and delete system notifications' },
];

export default function Roles() {
  const [subAdmins, setSubAdmins] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Search, filter, pagination
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const limit = 8;

  // Stats
  const [stats, setStats] = useState({ total: 0, active: 0, inactive: 0, suspended: 0 });

  // Drawer State
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState(null); // null = Create, otherwise Admin object
  const [saving, setSaving] = useState(false);
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });

  // Form states
  const [formName, setFormName] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formPassword, setFormPassword] = useState('');
  const [formStatus, setFormStatus] = useState('active');
  const [formPermissions, setFormPermissions] = useState([]);

  // Fetch Sub-Admins
  const fetchSubAdmins = () => {
    setLoading(true);
    setError('');
    rolesAPI.getAll()
      .then(res => {
        if (res && res.success && res.data) {
          setSubAdmins(res.data);
          calculateStats(res.data);
        } else {
          setError('Invalid API response structure');
        }
      })
      .catch(err => {
        console.error('Error fetching sub-admins:', err);
        setError(err?.message || 'Failed to load Roles & Permissions data.');
      })
      .finally(() => setLoading(false));
  };

  const calculateStats = (list) => {
    const total = list.length;
    const active = list.filter(a => a.status === 'active').length;
    const inactive = list.filter(a => a.status === 'inactive').length;
    const suspended = list.filter(a => a.status === 'suspended').length;
    setStats({ total, active, inactive, suspended });
  };

  useEffect(() => {
    fetchSubAdmins();
  }, []);

  // Open Create Drawer
  const handleOpenCreate = () => {
    setEditingAdmin(null);
    setFormName('');
    setFormEmail('');
    setFormPassword('');
    setFormStatus('active');
    setFormPermissions([]);
    setDrawerOpen(true);
  };

  // Open Edit Drawer
  const handleOpenEdit = (adminId) => {
    setDrawerLoading(true);
    setDrawerOpen(true);
    setEditingAdmin({ id: adminId }); // placeholder with id
    setFormName('');
    setFormEmail('');
    setFormPassword('');
    setFormStatus('active');
    setFormPermissions([]);

    rolesAPI.getById(adminId)
      .then(res => {
        if (res && res.success && res.data) {
          const admin = res.data;
          setEditingAdmin(admin);
          setFormName(admin.name || '');
          setFormEmail(admin.email || '');
          setFormStatus(admin.status || 'active');
          // Parse permissions (sometimes backend aggregates as array, sometimes stringified json string)
          let perms = admin.permissions || [];
          if (typeof perms === 'string') {
            try { perms = JSON.parse(perms); } catch (e) { perms = []; }
          }
          setFormPermissions(perms);
        } else {
          toast.error('Failed to load sub-admin details.');
          setDrawerOpen(false);
        }
      })
      .catch(err => {
        console.error('Error fetching sub-admin details:', err);
        toast.error(err?.message || 'Failed to load sub-admin details.');
        setDrawerOpen(false);
      })
      .finally(() => setDrawerLoading(false));
  };

  // Delete Sub-Admin
  const handleDelete = (adminId, name) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Delete Sub-Admin',
      message: `Are you sure you want to delete sub-admin "${name}"? This action cannot be undone.`,
      confirmText: 'Delete Sub-Admin',
      variant: 'danger',
      onConfirm: () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        setLoading(true);
        rolesAPI.delete(adminId)
          .then(res => {
            if (res && res.success) {
              toast.success('Sub-admin deleted successfully!');
              fetchSubAdmins();
            }
          })
          .catch(err => {
            console.error('Error deleting sub-admin:', err);
            toast.error(err?.message || 'Failed to delete sub-admin');
            setLoading(false);
          });
      }
    });
  };

  // Toggle permission checkbox
  const handlePermissionToggle = (permissionKey) => {
    if (formPermissions.includes(permissionKey)) {
      setFormPermissions(prev => prev.filter(k => k !== permissionKey));
    } else {
      setFormPermissions(prev => [...prev, permissionKey]);
    }
  };

  // Toggle select all permissions
  const handleSelectAll = () => {
    if (formPermissions.length === AVAILABLE_PERMISSIONS.length) {
      setFormPermissions([]);
    } else {
      setFormPermissions(AVAILABLE_PERMISSIONS.map(p => p.key));
    }
  };

  // Submit form
  const handleSave = (e) => {
    e.preventDefault();
    if (!formName.trim() || !formEmail.trim() || (!editingAdmin && !formPassword)) {
      toast.warning('Please fill out all required fields.');
      return;
    }

    setSaving(true);
    const payload = {
      name: formName.trim(),
      email: formEmail.trim(),
      status: formStatus,
      permissions: formPermissions,
    };

    if (formPassword) {
      payload.password = formPassword;
    }

    const request = editingAdmin 
      ? rolesAPI.update(editingAdmin.id, payload)
      : rolesAPI.create(payload);

    request
      .then(res => {
        if (res && res.success) {
          toast.success(`Sub-admin ${editingAdmin ? 'updated' : 'created'} successfully!`);
          setDrawerOpen(false);
          fetchSubAdmins();
        }
      })
      .catch(err => {
        console.error('Error saving sub-admin:', err);
        toast.error(err?.message || 'Failed to save sub-admin.');
      })
      .finally(() => setSaving(false));
  };

  // Date Formatting Helper
  const formatDate = (dateString) => {
    if (!dateString) return '—';
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  // Status Badge Helper
  const getStatusBadge = (status) => {
    switch (status) {
      case 'active':
        return { text: '🟢 Active', bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' };
      case 'inactive':
        return { text: '🟡 Inactive', bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' };
      case 'suspended':
        return { text: '🔴 Suspended', bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' };
      default:
        return { text: status || 'Unknown', bg: 'var(--border-color)', fg: 'var(--text-primary)' };
    }
  };

  // Filtering list locally
  const filteredSubAdmins = subAdmins.filter(admin => {
    const searchVal = search.toLowerCase().trim();
    const matchesSearch = !searchVal || 
      admin.name.toLowerCase().includes(searchVal) || 
      admin.email.toLowerCase().includes(searchVal);

    const matchesStatus = !filterStatus || admin.status === filterStatus;

    return matchesSearch && matchesStatus;
  });

  // Local Pagination
  const totalDocs = filteredSubAdmins.length;
  const totalPages = Math.ceil(totalDocs / limit) || 1;
  const paginatedAdmins = filteredSubAdmins.slice((currentPage - 1) * limit, currentPage * limit);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [search, filterStatus]);

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
        .perm-chip {
          display: inline-flex;
          align-items: center;
          font-size: 10px;
          border-radius: 4px;
          padding: 1px 6px;
          background: var(--accent-light);
          color: var(--accent-color);
          font-weight: 600;
          margin-right: 4px;
          margin-bottom: 4px;
          border: 0.5px solid #D1E2FF;
        }
        .perm-card {
          border: 1px solid var(--border-color);
          border-radius: 8px;
          padding: 10px 12px;
          background: var(--bg-app);
          cursor: pointer;
          transition: all 0.15s ease;
          display: flex;
          align-items: flex-start;
          gap: 10px;
          user-select: none;
        }
        .perm-card:hover {
          border-color: var(--accent-color);
          background: #EFF6FF;
        }
        .perm-card.active {
          border-color: var(--accent-color);
          background: var(--accent-light);
        }
        .action-btn {
          border: 1px solid var(--border-color);
          background: var(--bg-card);
          border-radius: 6px;
          padding: 4px 10px;
          fontSize: 11px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.1s;
        }
        .action-btn.edit {
          color: var(--accent-color);
        }
        .action-btn.edit:hover {
          background: var(--accent-light);
          border-color: var(--accent-color);
        }
        .action-btn.delete {
          color: var(--status-red-fg);
          margin-left: 6px;
        }
        .action-btn.delete:hover {
          background: #FEF2F2;
          border-color: #F87171;
        }
        .form-input {
          width: 100%;
          padding: 8px 12px;
          border: 1px solid #D1D5DB;
          border-radius: 8px;
          font-size: 13px;
          outline: none;
          font-family: inherit;
          margin-top: 4px;
          box-sizing: border-box;
          transition: border-color 0.15s;
        }
        .form-input:focus {
          border-color: var(--accent-color);
          box-shadow: 0 0 0 3px rgba(37,99,235,0.15);
        }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Roles & Permissions</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Configure administration access, allocate operational scopes, and create sub-admins.</p>
        </div>
        <button
          onClick={handleOpenCreate}
          style={{
            background: 'var(--accent-color)',
            color: 'var(--bg-card)',
            border: 'none',
            borderRadius: 8,
            padding: '8px 16px',
            fontSize: 13,
            fontWeight: 600,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            transition: 'background 0.15s',
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = 'var(--accent-dark)'}
          onMouseLeave={(e) => e.currentTarget.style.background = 'var(--accent-color)'}
        >
          <span>➕</span> Add Sub-Admin
        </button>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total Sub-Admins"
          value={stats.total}
          icon="🔐"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={loading}
        />
        <StatCard
          label="Active Accounts"
          value={stats.active}
          icon="🟢"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={loading}
        />
        <StatCard
          label="Inactive Accounts"
          value={stats.inactive}
          icon="🟡"
          bg="var(--status-amber-bg)"
          fg="var(--status-amber-fg)"
          loading={loading}
        />
        <StatCard
          label="Suspended Accounts"
          value={stats.suspended}
          icon="🔴"
          bg="var(--status-red-bg)"
          fg="var(--status-red-fg)"
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
              placeholder="Search sub-admin by name or email..."
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
              onChange={(e) => setFilterStatus(e.target.value)}
              style={{ padding: '7px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: 'var(--text-primary)', outline: 'none', fontWeight: 500, fontFamily: 'inherit' }}
            >
              <option value="">All Statuses</option>
              <option value="active">Active Only</option>
              <option value="inactive">Inactive Only</option>
              <option value="suspended">Suspended Only</option>
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
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Sub-Admin Details</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Active Scopes / Permissions</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Global Status</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Allocated Date</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(4)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <Skeleton w="30px" h="30px" radius={15} />
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                          <Skeleton w="120px" />
                          <Skeleton w="150px" h={12} />
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ display: 'flex', gap: 4 }}>
                        <Skeleton w="60px" h={16} radius={4} />
                        <Skeleton w="80px" h={16} radius={4} />
                        <Skeleton w="70px" h={16} radius={4} />
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="80px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="100px" /></td>
                  </tr>
                ))
              ) : paginatedAdmins.length === 0 ? (
                <tr>
                  <td colSpan="5" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 32, marginBottom: 8 }}>🔐</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No sub-admins found</div>
                    <div style={{ fontSize: 12 }}>Create a new sub-admin or try editing your filters.</div>
                  </td>
                </tr>
              ) : (
                paginatedAdmins.map(admin => {
                  const badge = getStatusBadge(admin.status);
                  // Ensure permissions is list of keys
                  let perms = admin.permissions || [];
                  if (typeof perms === 'string') {
                    try { perms = JSON.parse(perms); } catch (e) { perms = []; }
                  }
                  return (
                    <tr key={admin.id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                      {/* Sub-Admin details */}
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 34, height: 34, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, border: '1px solid var(--border-color)', flexShrink: 0 }}>
                            {admin.name ? admin.name.substring(0, 2).toUpperCase() : 'SA'}
                          </div>
                          <div>
                            <span style={{ fontWeight: 600, color: 'var(--text-primary)', display: 'block' }}>{admin.name}</span>
                            <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{admin.email}</span>
                          </div>
                        </div>
                      </td>

                      {/* Permissions list */}
                      <td style={{ padding: '14px 8px', maxWidth: 350 }}>
                        {perms.length === 0 ? (
                          <span style={{ fontSize: 11, color: 'var(--text-muted)', fontStyle: 'italic' }}>None allocated</span>
                        ) : (
                          <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                            {perms.map(pKey => {
                              const found = AVAILABLE_PERMISSIONS.find(ap => ap.key === pKey);
                              return (
                                <span key={pKey} className="perm-chip" title={found?.desc || pKey}>
                                  {found?.label || pKey}
                                </span>
                              );
                            })}
                          </div>
                        )}
                      </td>

                      {/* Status badge */}
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

                      {/* Created date */}
                      <td style={{ padding: '14px 8px', color: 'var(--text-secondary)' }}>{formatDate(admin.created_at)}</td>

                      {/* Actions */}
                      <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                        <button
                          onClick={() => handleOpenEdit(admin.id)}
                          className="action-btn edit"
                        >
                          Edit
                        </button>
                        <button
                          onClick={() => handleDelete(admin.id, admin.name)}
                          className="action-btn delete"
                        >
                          Delete
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
        {!loading && filteredSubAdmins.length > 0 && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', borderTop: '0.5px solid var(--bg-muted)' }}>
            <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              Showing page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> (<strong>{totalDocs}</strong> sub-admins)
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

      {/* Floating Action Button */}
      <button
        onClick={handleOpenCreate}
        style={{
          position: 'fixed',
          bottom: 24,
          right: 24,
          width: 50,
          height: 50,
          borderRadius: 25,
          background: 'var(--accent-color)',
          color: 'var(--bg-card)',
          border: 'none',
          boxShadow: '0 4px 12px rgba(26,86,219,0.3)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: 22,
          cursor: 'pointer',
          zIndex: 900,
          transition: 'transform 0.15s, background 0.15s',
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = 'scale(1.05)';
          e.currentTarget.style.background = 'var(--accent-dark)';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = 'scale(1)';
          e.currentTarget.style.background = 'var(--accent-color)';
        }}
        title="Add New Sub-Admin"
      >
        ➕
      </button>

      {/* Detail / Form Drawer Overlay */}
      {drawerOpen && (
        <div
          onClick={() => { if (!saving) setDrawerOpen(false); }}
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
              maxWidth: 620,
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
                <span style={{ fontSize: 10, background: 'var(--accent-light)', color: 'var(--accent-color)', fontWeight: 700, padding: '2px 8px', borderRadius: 4 }}>
                  SUB-ADMIN MANAGEMENT
                </span>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--text-primary)', margin: '4px 0 0' }}>
                  {editingAdmin ? 'Update Sub-Admin Profile' : 'Configure New Sub-Admin'}
                </h3>
              </div>
              <button
                disabled={saving}
                onClick={() => setDrawerOpen(false)}
                style={{ background: 'none', border: 'none', fontSize: 20, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >
                ✕
              </button>
            </div>

            {/* Scroll Content Body */}
            <form onSubmit={handleSave} style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
              <div style={{ flex: 1, padding: 24 }}>
                {drawerLoading ? (
                  <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-secondary)' }}>
                    <div style={{ border: '3px solid #f3f3f3', borderTop: '3px solid var(--accent-color)', borderRadius: '50%', width: 24, height: 24, animation: 'spin 1s linear infinite', margin: '0 auto 10px' }} />
                    <span>Fetching profile records...</span>
                    <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
                  </div>
                ) : (
                  <div className="animate-fade" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    
                    {/* Basic Info Fields */}
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                      <div>
                        <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Full Name *</label>
                        <input
                          type="text"
                          required
                          placeholder="e.g. Prakash Ayyasamy"
                          value={formName}
                          onChange={(e) => setFormName(e.target.value)}
                          className="form-input"
                        />
                      </div>
                      <div>
                        <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Email Address *</label>
                        <input
                          type="email"
                          required
                          placeholder="e.g. prakash@urbanserve.in"
                          value={formEmail}
                          onChange={(e) => setFormEmail(e.target.value)}
                          className="form-input"
                        />
                      </div>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                      <div>
                        <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                          Password {editingAdmin ? '(Optional)' : '*'}
                        </label>
                        <input
                          type="password"
                          placeholder={editingAdmin ? 'Leave blank to retain current' : 'Define password'}
                          required={!editingAdmin}
                          value={formPassword}
                          onChange={(e) => setFormPassword(e.target.value)}
                          className="form-input"
                        />
                      </div>
                      <div>
                        <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Global Status</label>
                        <select
                          value={formStatus}
                          onChange={(e) => setFormStatus(e.target.value)}
                          className="form-input"
                        >
                          <option value="active">Active (Full Access Allowed)</option>
                          <option value="inactive">Inactive (Access Blocked temporarily)</option>
                          <option value="suspended">Suspended (Access Terminated)</option>
                        </select>
                      </div>
                    </div>

                    {/* Permissions Section */}
                    <div style={{ borderTop: '0.5px solid var(--border-color)', paddingTop: 18, marginTop: 6 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <div>
                          <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block' }}>
                            Access Scopes & Permissions
                          </label>
                          <span style={{ fontSize: 11, color: 'var(--text-secondary)' }}>
                            Select the module capabilities assigned to this sub-admin.
                          </span>
                        </div>
                        <button
                          type="button"
                          onClick={handleSelectAll}
                          style={{
                            border: '1px solid #D1D5DB',
                            background: 'var(--bg-card)',
                            borderRadius: 6,
                            padding: '4px 10px',
                            fontSize: 11,
                            fontWeight: 600,
                            color: 'var(--text-primary)',
                            cursor: 'pointer'
                          }}
                        >
                          {formPermissions.length === AVAILABLE_PERMISSIONS.length ? 'Clear All' : 'Select All'}
                        </button>
                      </div>

                      {/* Permissions Grid */}
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                        {AVAILABLE_PERMISSIONS.map(p => {
                          const isActive = formPermissions.includes(p.key);
                          return (
                            <div
                              key={p.key}
                              className={`perm-card ${isActive ? 'active' : ''}`}
                              onClick={() => handlePermissionToggle(p.key)}
                            >
                              <input
                                type="checkbox"
                                checked={isActive}
                                readOnly
                                style={{ marginTop: 3, cursor: 'pointer' }}
                              />
                              <div>
                                <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-primary)', display: 'block' }}>
                                  {p.label}
                                </span>
                                <span style={{ fontSize: 10, color: 'var(--text-secondary)', display: 'block', lineHeight: 1.25, marginTop: 2 }}>
                                  {p.desc}
                                </span>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>

                  </div>
                )}
              </div>

              {/* Drawer Footer actions */}
              <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-color)', display: 'flex', justifyContent: 'flex-end', gap: 10, background: 'var(--bg-app)' }}>
                <button
                  type="button"
                  disabled={saving}
                  onClick={() => setDrawerOpen(false)}
                  style={{
                    padding: '8px 16px',
                    borderRadius: 8,
                    border: '1px solid var(--border-color)',
                    background: 'var(--bg-card)',
                    color: 'var(--text-secondary)',
                    fontSize: 13,
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving || drawerLoading}
                  style={{
                    padding: '8px 18px',
                    borderRadius: 8,
                    border: 'none',
                    background: 'var(--accent-color)',
                    color: 'var(--bg-card)',
                    fontSize: 13,
                    fontWeight: 600,
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 6
                  }}
                >
                  {saving && (
                    <div style={{ border: '2px solid var(--bg-card)', borderTop: '2px solid transparent', borderRadius: '50%', width: 12, height: 12, animation: 'spin 1s linear infinite' }} />
                  )}
                  {editingAdmin ? 'Save Changes' : 'Create Profile'}
                </button>
              </div>
            </form>
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
