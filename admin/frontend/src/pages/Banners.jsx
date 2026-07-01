import { useState, useEffect } from 'react';
import { bannersAPI } from '../api';

const resolveImageUrl = (url) => {
  if (!url) return '';
  if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) return url;
  return `http://localhost:5000${url}`;
};

function StatCard({ label, value, icon, bg, fg, loading }) {
  return (
    <div style={{
      background: '#fff',
      border: '0.5px solid #E5E7EB',
      borderRadius: 16,
      padding: '16px 20px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
      animation: 'fadeIn 0.25s ease-out forwards'
    }}>
      <div>
        <div style={{ fontSize: 12, fontWeight: 500, color: '#6B7280', marginBottom: 6 }}>{label}</div>
        {loading ? (
          <div style={{
            width: 50,
            height: 24,
            background: 'linear-gradient(90deg, #F3F4F6 25%, #E5E7EB 50%, #F3F4F6 75%)',
            backgroundSize: '200% 100%',
            animation: 'shimmer 1.5s infinite linear',
            borderRadius: 4
          }} />
        ) : (
          <div style={{ fontSize: 22, fontWeight: 800, color: '#111827', letterSpacing: '-0.5px' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 42,
        height: 42,
        borderRadius: 12,
        background: bg,
        color: fg,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 18
      }}>
        {icon}
      </div>
    </div>
  );
}

export default function Banners() {
  const [banners, setBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState(null); // null = Create, otherwise the Banner object

  // Form states
  const [title, setTitle] = useState('');
  const [linkUrl, setLinkUrl] = useState('');
  const [status, setStatus] = useState('active');
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState('');

  const fetchBanners = () => {
    setLoading(true);
    bannersAPI.getAll()
      .then(res => {
        const list = res?.data?.rows || res?.rows || [];
        setBanners(list);
      })
      .catch(err => {
        console.error('Error fetching banners:', err);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const handleOpenCreate = () => {
    setEditingBanner(null);
    setTitle('');
    setLinkUrl('');
    setStatus('active');
    setSelectedFile(null);
    setPreviewUrl('');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (banner) => {
    setEditingBanner(banner);
    setTitle(banner.title || '');
    setLinkUrl(banner.link_url || '');
    setStatus(banner.status || 'active');
    setSelectedFile(null);
    setPreviewUrl(resolveImageUrl(banner.image_url));
    setIsModalOpen(true);
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!editingBanner && !selectedFile) {
      return alert('Please select a banner image to upload.');
    }

    setSubmitting(true);
    const formData = new FormData();
    formData.append('title', title);
    formData.append('link_url', linkUrl);
    formData.append('status', status);
    if (selectedFile) {
      formData.append('image', selectedFile);
    }

    const savePromise = editingBanner
      ? bannersAPI.update(editingBanner.id, formData)
      : bannersAPI.create(formData);

    savePromise
      .then(res => {
        if (res && res.success) {
          setIsModalOpen(false);
          fetchBanners();
        }
      })
      .catch(err => {
        console.error('Error saving banner:', err);
        alert(err?.message || 'Failed to save banner.');
      })
      .finally(() => setSubmitting(false));
  };

  const handleDelete = (banner) => {
    if (window.confirm('Are you sure you want to permanently delete this banner?')) {
      bannersAPI.delete(banner.id)
        .then(res => {
          if (res && res.success) {
            fetchBanners();
          }
        })
        .catch(err => {
          console.error('Error deleting banner:', err);
          alert(err?.message || 'Failed to delete banner.');
        });
    }
  };

  const handleToggleStatus = (banner) => {
    const newStatus = banner.status === 'active' ? 'inactive' : 'active';
    const formData = new FormData();
    formData.append('status', newStatus);

    bannersAPI.update(banner.id, formData)
      .then(res => {
        if (res && res.success) {
          fetchBanners();
        }
      })
      .catch(err => {
        console.error('Error toggling banner status:', err);
        alert(err?.message || 'Failed to update banner status.');
      });
  };

  const totalCount = banners.length;
  const activeCount = banners.filter(b => b.status === 'active').length;
  const inactiveCount = banners.filter(b => b.status !== 'active').length;

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: '#F9FAFB', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
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
          <h2 style={{ fontSize: 20, fontWeight: 700, color: '#111827', margin: 0 }}>Promo Banners</h2>
          <p style={{ fontSize: 12, color: '#6B7280', margin: '4px 0 0' }}>Upload and configure promotional banners to showcase as a carousel in the user app home screen.</p>
        </div>
        <button
          onClick={handleOpenCreate}
          style={{
            background: '#1A56DB',
            border: 'none',
            borderRadius: 8,
            color: '#fff',
            padding: '8px 16px',
            fontSize: 12,
            fontWeight: 600,
            cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(26, 86, 219, 0.15)',
            transition: 'all 0.15s'
          }}
          onMouseEnter={(e) => e.currentTarget.style.background = '#1e40af'}
          onMouseLeave={(e) => e.currentTarget.style.background = '#1A56DB'}
        >
          ➕ Add New Banner
        </button>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard
          label="Total Banners"
          value={totalCount}
          icon="🖼️"
          bg="#EFF4FF"
          fg="#1A56DB"
          loading={loading}
        />
        <StatCard
          label="Active Banners"
          value={activeCount}
          icon="🟢"
          bg="#F0FDF4"
          fg="#059669"
          loading={loading}
        />
        <StatCard
          label="Inactive Banners"
          value={inactiveCount}
          icon="🔴"
          bg="#FEE2E2"
          fg="#DC2626"
          loading={loading}
        />
      </div>

      {/* Main Table Container */}
      <div style={{ background: '#fff', borderRadius: 16, border: '0.5px solid #E5E7EB', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        <div style={{ padding: '16px 20px', borderBottom: '0.5px solid #E5E7EB', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontWeight: 700, fontSize: 14, color: '#111827' }}>All Banners</span>
          <button
            onClick={fetchBanners}
            style={{ background: 'none', border: 'none', color: '#1A56DB', cursor: 'pointer', fontSize: 12, fontWeight: 600 }}
          >
            🔄 Refresh
          </button>
        </div>

        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#6B7280', fontSize: 13 }}>
            Loading promotional banners...
          </div>
        ) : banners.length === 0 ? (
          <div style={{ padding: '60px 40px', textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 12 }}>🖼️</div>
            <div style={{ fontWeight: 600, color: '#374151', fontSize: 14, marginBottom: 4 }}>No Banners Found</div>
            <div style={{ color: '#6B7280', fontSize: 12, marginBottom: 16 }}>Get started by adding your first promotional banner.</div>
            <button
              onClick={handleOpenCreate}
              style={{ background: '#1A56DB', border: 'none', borderRadius: 6, color: '#fff', padding: '6px 12px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
            >
              Add Banner
            </button>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: 13 }}>
              <thead>
                <tr style={{ background: '#F9FAFB', borderBottom: '0.5px solid #E5E7EB', color: '#4B5563' }}>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 140 }}>Image</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600 }}>Title</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600 }}>Action Link</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 120 }}>Status</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 180, textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {banners.map((b) => (
                  <tr key={b.id} style={{ borderBottom: '0.5px solid #F3F4F6', transition: 'background 0.15s' }}>
                    <td style={{ padding: '12px 20px' }}>
                      <div style={{ width: 100, height: 50, borderRadius: 8, background: '#F3F4F6', overflow: 'hidden', border: '0.5px solid #E5E7EB' }}>
                        <img
                          src={resolveImageUrl(b.image_url)}
                          alt={b.title || 'Banner'}
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = 'https://placehold.co/100x50?text=No+Image';
                          }}
                        />
                      </div>
                    </td>
                    <td style={{ padding: '12px 20px', fontWeight: 600, color: '#111827' }}>
                      {b.title || <span style={{ color: '#9CA3AF', fontStyle: 'italic', fontWeight: 400 }}>No Title</span>}
                    </td>
                    <td style={{ padding: '12px 20px', color: '#4B5563', fontFamily: 'monospace', fontSize: 12 }}>
                      {b.link_url || <span style={{ color: '#9CA3AF', fontStyle: 'italic' }}>None</span>}
                    </td>
                    <td style={{ padding: '12px 20px' }}>
                      <span
                        onClick={() => handleToggleStatus(b)}
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 5,
                          padding: '3px 8px',
                          borderRadius: 12,
                          fontSize: 11,
                          fontWeight: 600,
                          cursor: 'pointer',
                          background: b.status === 'active' ? '#D1FAE5' : '#F3F4F6',
                          color: b.status === 'active' ? '#065F46' : '#4B5563',
                        }}
                      >
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: b.status === 'active' ? '#10B981' : '#6B7280' }} />
                        {b.status === 'active' ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 20px', textAlign: 'right' }}>
                      <button
                        onClick={() => handleOpenEdit(b)}
                        style={{ background: 'none', border: 'none', color: '#2563EB', marginRight: 12, cursor: 'pointer', fontWeight: 600, fontSize: 12 }}
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(b)}
                        style={{ background: 'none', border: 'none', color: '#DC2626', cursor: 'pointer', fontWeight: 600, fontSize: 12 }}
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal / Drawer for Create & Edit */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(17, 24, 39, 0.4)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div
            className="animate-fade"
            style={{
              background: '#fff', borderRadius: 20, width: '100%', maxWidth: 480,
              boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)',
              border: '0.5px solid #E5E7EB', overflow: 'hidden'
            }}
          >
            {/* Modal Header */}
            <div style={{ padding: '20px 24px', borderBottom: '0.5px solid #E5E7EB', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: '#111827' }}>
                {editingBanner ? 'Edit Promo Banner' : 'Add New Promo Banner'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                style={{ background: 'none', border: 'none', fontSize: 18, color: '#9CA3AF', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>

            {/* Modal Body / Form */}
            <form onSubmit={handleSubmit} style={{ padding: '24px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {/* Title */}
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#4B5563', textTransform: 'uppercase', marginBottom: 6 }}>
                    Banner Title (Optional)
                  </label>
                  <input
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="E.g., 50% Off AC Services"
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, boxSizing: 'border-box' }}
                  />
                </div>

                {/* Action Link */}
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#4B5563', textTransform: 'uppercase', marginBottom: 6 }}>
                    Action Link URL (Optional)
                  </label>
                  <input
                    type="text"
                    value={linkUrl}
                    onChange={(e) => setLinkUrl(e.target.value)}
                    placeholder="E.g., /services/1"
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, boxSizing: 'border-box' }}
                  />
                </div>

                {/* Status */}
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#4B5563', textTransform: 'uppercase', marginBottom: 6 }}>
                    Status
                  </label>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, background: '#fff', boxSizing: 'border-box' }}
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>

                {/* Image Upload */}
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: '#4B5563', textTransform: 'uppercase', marginBottom: 6 }}>
                    Banner Image
                  </label>
                  <div style={{
                    border: '2px dashed #D1D5DB', borderRadius: 12, padding: '16px',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    background: '#F9FAFB', cursor: 'pointer', position: 'relative'
                  }}>
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleFileChange}
                      style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', opacity: 0, cursor: 'pointer' }}
                    />
                    {previewUrl ? (
                      <div style={{ width: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
                        <img
                          src={previewUrl}
                          alt="Preview"
                          style={{ width: '100%', maxHeight: 120, objectFit: 'contain', borderRadius: 6 }}
                        />
                        <span style={{ fontSize: 11, color: '#2563EB', fontWeight: 600 }}>Click or drag to replace image</span>
                      </div>
                    ) : (
                      <div style={{ textAlign: 'center', color: '#6B7280' }}>
                        <div style={{ fontSize: 24, marginBottom: 6 }}>📤</div>
                        <div style={{ fontSize: 12, fontWeight: 600 }}>Upload Image File</div>
                        <div style={{ fontSize: 10, color: '#9CA3AF', marginTop: 2 }}>Drag & drop or click to browse</div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Modal Footer / Actions */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 28, borderTop: '0.5px solid #E5E7EB', paddingTop: 16 }}>
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  style={{ background: '#F3F4F6', border: 'none', borderRadius: 8, color: '#374151', padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    background: '#1A56DB', border: 'none', borderRadius: 8, color: '#fff',
                    padding: '8px 20px', fontSize: 12, fontWeight: 600, cursor: 'pointer',
                    opacity: submitting ? 0.7 : 1, display: 'flex', alignItems: 'center', gap: 6
                  }}
                >
                  {submitting ? 'Saving...' : (editingBanner ? 'Save Changes' : 'Add Banner')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
