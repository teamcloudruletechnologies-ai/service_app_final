import { useState, useEffect } from 'react';
import { servicesAPI } from '../api';
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

export default function Services() {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Form Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingService, setEditingService] = useState(null);
  const [confirmConfig, setConfirmConfig] = useState({
    isOpen: false,
    title: '',
    message: '',
    confirmText: 'Confirm',
    variant: 'danger',
    onConfirm: () => {},
  });
  const [categories, setCategories] = useState([]);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    image: '',
    status: 'active'
  });
  const [submitting, setSubmitting] = useState(false);

  const fetchCategories = () => {
    servicesAPI.getCategories()
      .then(res => {
        if (res && res.success) {
          const catList = Array.isArray(res.data) 
            ? res.data 
            : (res.data?.rows || []);
          setCategories(catList);
        }
      })
      .catch(err => {
        console.error('Error fetching categories for dropdown:', err);
      });
  };

  // Fetch Services list
  const fetchServices = () => {
    setLoading(true);
    setError('');
    servicesAPI.getAll()
      .then(res => {
        if (res && res.success) {
          const serviceList = Array.isArray(res.data) 
            ? res.data 
            : (res.data?.rows || []);
          setServices(serviceList);
        }
      })
      .catch(err => {
        console.error('Error fetching admin services catalog:', err);
        setError(err?.message || 'Failed to load services database.');
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchServices();
  }, []);

  // Handle open modal for create
  const handleOpenCreate = () => {
    setEditingService(null);
    setFormData({
      name: '',
      description: '',
      image: '',
      status: 'active'
    });
    setIsModalOpen(true);
  };

  // Handle open modal for edit
  const handleOpenEdit = (service) => {
    setEditingService(service);
    setFormData({
      name: service.name,
      description: service.description || '',
      image: service.image_url || '',
      status: service.status || 'active'
    });
    setIsModalOpen(true);
  };

  // Submit Form (Create / Edit)
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name) return toast.warning('Service Name is required.');

    setSubmitting(true);
    const payload = {
      name: formData.name,
      description: formData.description || null,
      image: formData.image || '',
      status: formData.status
    };

    const savePromise = editingService
      ? servicesAPI.update(editingService.id, payload)
      : servicesAPI.create(payload);

    savePromise
      .then(res => {
        if (res && res.success) {
          toast.success(editingService ? 'Service updated successfully!' : 'Service created successfully!');
          setIsModalOpen(false);
          fetchServices();
        }
      })
      .catch(err => {
        console.error('Error saving service:', err);
        toast.error(err?.message || 'Failed to save service category.');
      })
      .finally(() => setSubmitting(false));
  };

  // Toggle status ('active' <-> 'inactive')
  const handleToggleStatus = (service) => {
    const newStatus = service.status === 'active' ? 'inactive' : 'active';
    servicesAPI.updateStatus(service.id, newStatus)
      .then(res => {
        if (res && res.success) {
          toast.success(`Service status updated to ${newStatus}`);
          fetchServices();
        }
      })
      .catch(err => {
        console.error('Error toggling service status:', err);
        toast.error(err?.message || 'Failed to update service availability status.');
      });
  };

  // Delete Service
  const handleDelete = (service) => {
    setConfirmConfig({
      isOpen: true,
      title: 'Delete Service Category',
      message: `Are you sure you want to permanently delete the "${service.name}" service category?\nThis cannot be undone.`,
      confirmText: 'Delete Category',
      variant: 'danger',
      onConfirm: () => {
        setConfirmConfig(prev => ({ ...prev, isOpen: false }));
        servicesAPI.delete(service.id)
          .then(res => {
            if (res && res.success) {
              toast.success('Service category deleted successfully!');
              fetchServices();
            }
          })
          .catch(err => {
            console.error('Error deleting service:', err);
            toast.error(err?.message || 'Failed to delete service category.');
          });
      }
    });
  };

  // Stats
  const totalCount = services.length;
  const activeCount = services.filter(s => s.status === 'active').length;
  const disabledCount = services.filter(s => s.status !== 'active').length;

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
        .animate-fade {
          animation: fadeIn 0.2s ease-out forwards;
        }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Service Catalog Configuration</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Configure offered home services, update rates, upload service assets, and toggle service visibility.</p>
        </div>
        <button
          onClick={handleOpenCreate}
          style={{
            background: 'var(--accent-color)',
            border: 'none',
            borderRadius: 8,
            color: 'var(--bg-card)',
            padding: '8px 16px',
            fontSize: 12,
            fontWeight: 600,
            cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(26, 86, 219, 0.15)',
            transition: 'all 0.15s'
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = 'var(--accent-dark)'}
          onMouseLeave={(e) => e.currentTarget.style.background = 'var(--accent-color)'}
        >
          ➕ Add New Service
        </button>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total Categories"
          value={totalCount}
          icon="🗂️"
          bg="var(--accent-light)"
          fg="var(--accent-color)"
          loading={loading}
        />
        <StatCard
          label="Active Offerings"
          value={activeCount}
          icon="🟢"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={loading}
        />
        <StatCard
          label="Disabled/Unavailable"
          value={disabledCount}
          icon="🔴"
          bg="var(--status-red-bg)"
          fg="var(--status-red-fg)"
          loading={loading}
        />
      </div>

      {/* Table Container Card */}
      <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        
        {error && (
          <div style={{ background: 'var(--status-red-bg)', border: '1px solid #FCA5A5', color: 'var(--status-red-fg)', padding: '12px 16px', borderRadius: 8, margin: '20px 24px 0', fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
          </div>
        )}

        <div style={{ overflowX: 'auto', padding: '20px 24px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)', color: 'var(--text-secondary)', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Image</th>
                <th style={{ padding: '14px 8px', fontWeight: 600 }}>Service Name</th>
                <th style={{ padding: '14px 8px', fontWeight: 600, textAlign: 'center' }}>Status</th>
                <th style={{ padding: '14px 8px', textAlign: 'center', fontWeight: 600 }}>Actions</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: 'var(--text-primary)' }}>
              {loading ? (
                [...Array(4)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="32px" h="32px" radius={8} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="120px" /></td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}><Skeleton w="70px" radius={12} /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="120px" /></td>
                  </tr>
                ))
              ) : services.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-muted)' }}>
                    <div style={{ fontSize: 32, marginBottom: 8 }}>🗂️</div>
                    <div style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>No services configured</div>
                    <div style={{ fontSize: 12 }}>Add a service category to display here.</div>
                  </td>
                </tr>
              ) : (
                services.map(s => (
                  <tr key={s.id} style={{ borderBottom: '1px solid var(--bg-muted)' }}>
                    <td style={{ padding: '14px 8px' }}>
                      <div style={{ width: 44, height: 44, borderRadius: 8, overflow: 'hidden', background: 'var(--bg-muted)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {s.image_url ? (
                          <img src={s.image_url} alt={s.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <span style={{ fontSize: 20 }}>🛠️</span>
                        )}
                      </div>
                    </td>
                    <td style={{ padding: '14px 8px', fontWeight: 600, color: 'var(--text-primary)' }}>{s.name}</td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                      <span style={{
                        display: 'inline-flex',
                        fontSize: 10,
                        borderRadius: 12,
                        padding: '1px 8px',
                        fontWeight: 700,
                        backgroundColor: s.status === 'active' ? 'var(--status-green-bg)' : 'var(--status-red-bg)',
                        color: s.status === 'active' ? 'var(--status-green-fg)' : 'var(--status-red-fg)'
                      }}>
                        {s.status === 'active' ? 'Active' : 'Disabled'}
                      </span>
                    </td>
                    <td style={{ padding: '14px 8px', textAlign: 'center' }}>
                      <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
                        <button
                          onClick={() => handleOpenEdit(s)}
                          style={{ border: '1px solid var(--border-color)', background: 'var(--bg-card)', borderRadius: 6, padding: '4px 8px', fontSize: 11, fontWeight: 600, color: 'var(--text-primary)', cursor: 'pointer' }}
                        >
                          ✏️ Edit
                        </button>
                        <button
                          onClick={() => handleToggleStatus(s)}
                          style={{
                            border: '1px solid',
                            borderColor: s.status === 'active' ? 'var(--status-amber-fg)' : 'var(--status-green-fg)',
                            background: s.status === 'active' ? 'var(--status-amber-bg)' : '#EFFDF5',
                            borderRadius: 6,
                            borderColor: s.status === 'active' ? 'var(--status-amber-fg)' : 'var(--status-green-fg)',
                            padding: '4px 8px',
                            fontSize: 11,
                            fontWeight: 600,
                            color: s.status === 'active' ? 'var(--status-amber-fg)' : 'var(--status-green-fg)',
                            cursor: 'pointer'
                          }}
                        >
                          {s.status === 'active' ? '🚫 Disable' : '⚡ Enable'}
                        </button>
                        <button
                          onClick={() => handleDelete(s)}
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
      </div>

      {/* Edit / Create Form Modal */}
      {isModalOpen && (
        <div
          onClick={() => setIsModalOpen(false)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(11, 15, 25, 0.4)',
            backdropFilter: 'blur(4px)',
            zIndex: 1000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <form
            onSubmit={handleSubmit}
            onClick={(e) => e.stopPropagation()}
            className="animate-fade"
            style={{
              width: '90%',
              maxWidth: 480,
              background: 'var(--bg-card)',
              border: '1px solid var(--border-color)',
              borderRadius: 16,
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)',
              overflow: 'hidden'
            }}
          >
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 20px', borderBottom: '1px solid var(--border-color)' }}>
              <h3 style={{ fontSize: 15, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>
                {editingService ? `Edit Service: ${editingService.name}` : 'Create New Service'}
              </h3>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                style={{ background: 'none', border: 'none', fontSize: 16, color: 'var(--text-muted)', cursor: 'pointer', padding: 4 }}
              >
                ✕
              </button>
            </div>

            {/* Scrollable inputs */}
            <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14, maxHeight: '70vh', overflowY: 'auto' }}>
              
              {/* Name */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Service Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Plumber"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none' }}
                />
              </div>

              {/* Description */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Description</label>
                <textarea
                  placeholder="Describe the service..."
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', resize: 'vertical', minHeight: 80, fontFamily: 'inherit' }}
                />
              </div>

              {/* Image URL */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Service Image URL</label>
                <input
                  type="text"
                  placeholder="https://..."
                  value={formData.image}
                  onChange={(e) => setFormData(prev => ({ ...prev, image: e.target.value }))}
                  style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', fontFamily: 'monospace' }}
                />
              </div>

              {/* Status toggle selector */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                <label style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>Catalog Availability Status</label>
                <select
                  value={formData.status}
                  onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
                  style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', cursor: 'pointer', background: 'var(--bg-card)' }}
                >
                  <option value="active">Active (Available for booking)</option>
                  <option value="inactive">Disabled (Hidden from catalog)</option>
                </select>
              </div>

            </div>

            {/* Footer Buttons */}
            <div style={{ borderTop: '1px solid var(--border-color)', padding: '12px 20px', backgroundColor: '#FAFAFB', display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                style={{
                  padding: '8px 14px',
                  borderRadius: 8,
                  border: '1px solid #D1D5DB',
                  background: 'var(--bg-card)',
                  color: 'var(--text-primary)',
                  fontSize: 12,
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting}
                style={{
                  padding: '8px 16px',
                  borderRadius: 8,
                  border: 'none',
                  background: 'var(--accent-color)',
                  color: 'var(--bg-card)',
                  fontSize: 12,
                  fontWeight: 600,
                  cursor: 'pointer',
                  boxShadow: '0 2px 4px rgba(26, 86, 219, 0.1)'
                }}
              >
                {submitting ? 'Saving...' : 'Save Configuration'}
              </button>
            </div>
          </form>
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
