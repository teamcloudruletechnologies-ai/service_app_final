import { useState, useEffect } from 'react';
import { categoriesAPI } from '../api';

const formatGoogleDriveUrl = (url) => {
  if (!url || typeof url !== 'string') return url;
  const trimmed = url.trim();
  if (!trimmed.includes('drive.google.com') && !trimmed.includes('googleusercontent.com')) return trimmed;

  const matchD = trimmed.match(/\/file\/d\/([a-zA-Z0-9_-]+)/);
  if (matchD && matchD[1]) {
    return `https://drive.google.com/thumbnail?id=${matchD[1]}&sz=w1000`;
  }
  const matchId = trimmed.match(/[?&]id=([a-zA-Z0-9_-]+)/);
  if (matchId && matchId[1]) {
    return `https://drive.google.com/thumbnail?id=${matchId[1]}&sz=w1000`;
  }
  const matchLh3 = trimmed.match(/googleusercontent\.com\/d\/([a-zA-Z0-9_-]+)/);
  if (matchLh3 && matchLh3[1]) {
    return `https://drive.google.com/thumbnail?id=${matchLh3[1]}&sz=w1000`;
  }
  return trimmed;
};

const resolveIconUrl = (url) => {
  if (!url) return '';
  const formatted = formatGoogleDriveUrl(url);
  if (formatted.startsWith('http://') || formatted.startsWith('https://') || formatted.startsWith('data:')) return formatted;
  return `http://localhost:5000${formatted}`;
};

function StatCard({ label, value, icon, bg, fg, loading }) {
  return (
    <div style={{
      background: 'var(--bg-card)',
      border: '0.5px solid var(--border-color)',
      borderRadius: 16,
      padding: '16px 20px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
      animation: 'fadeIn 0.25s ease-out forwards'
    }}>
      <div>
        <div style={{ fontSize: 12, fontWeight: 500, color: 'var(--text-secondary)', marginBottom: 6 }}>{label}</div>
        {loading ? (
          <div style={{
            width: 50, height: 24,
            background: 'linear-gradient(90deg, var(--bg-muted) 25%, var(--border-color) 50%, var(--bg-muted) 75%)',
            backgroundSize: '200% 100%',
            animation: 'shimmer 1.5s infinite linear',
            borderRadius: 4
          }} />
        ) : (
          <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', letterSpacing: '-0.5px' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 42, height: 42, borderRadius: 12,
        background: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18
      }}>
        {icon}
      </div>
    </div>
  );
}

export default function Categories() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [search, setSearch] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);

  // Form states
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [status, setStatus] = useState('active');
  const [iconUrlInput, setIconUrlInput] = useState('');
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState('');

  const fetchCategories = () => {
    setLoading(true);
    categoriesAPI.getAll({ search: search.trim() || undefined })
      .then(res => {
        const list = res?.data?.rows || res?.rows || res?.data || [];
        setCategories(Array.isArray(list) ? list : []);
      })
      .catch(err => {
        console.error('Error fetching categories:', err);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchCategories();
  }, [search]);

  const handleOpenCreate = () => {
    setEditingCategory(null);
    setName('');
    setDescription('');
    setStatus('active');
    setIconUrlInput('');
    setSelectedFile(null);
    setPreviewUrl('');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (category) => {
    setEditingCategory(category);
    setName(category.name || '');
    setDescription(category.description || '');
    setStatus(category.status || 'active');
    setIconUrlInput(category.icon_url || '');
    setSelectedFile(null);
    setPreviewUrl(resolveIconUrl(category.icon_url));
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

  const handleIconUrlChange = (e) => {
    const rawVal = e.target.value;
    const formatted = formatGoogleDriveUrl(rawVal);
    setIconUrlInput(rawVal);
    if (formatted) {
      setPreviewUrl(formatted);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name.trim()) {
      return alert('Category name is required.');
    }

    setSubmitting(true);
    const formData = new FormData();
    formData.append('name', name.trim());
    formData.append('description', description.trim());
    formData.append('status', status);

    if (selectedFile) {
      formData.append('icon', selectedFile);
    } else if (iconUrlInput.trim()) {
      formData.append('icon_url', formatGoogleDriveUrl(iconUrlInput.trim()));
    }

    const savePromise = editingCategory
      ? categoriesAPI.update(editingCategory.id, formData)
      : categoriesAPI.create(formData);

    savePromise
      .then(res => {
        if (res && (res.success || res.data)) {
          setIsModalOpen(false);
          fetchCategories();
        }
      })
      .catch(err => {
        console.error('Error saving category:', err);
        alert(err?.message || 'Failed to save category.');
      })
      .finally(() => setSubmitting(false));
  };

  const handleDelete = (category) => {
    if (window.confirm(`Are you sure you want to delete category "${category.name}"?`)) {
      categoriesAPI.delete(category.id)
        .then(res => {
          if (res && (res.success || res.data)) {
            fetchCategories();
          }
        })
        .catch(err => {
          console.error('Error deleting category:', err);
          alert(err?.message || 'Failed to delete category.');
        });
    }
  };

  const handleToggleStatus = (category) => {
    const newStatus = category.status === 'active' ? 'inactive' : 'active';
    const formData = new FormData();
    formData.append('status', newStatus);

    categoriesAPI.update(category.id, formData)
      .then(res => {
        if (res && (res.success || res.data)) {
          fetchCategories();
        }
      })
      .catch(err => {
        console.error('Error toggling category status:', err);
        alert(err?.message || 'Failed to update status.');
      });
  };

  const totalCount = categories.length;
  const activeCount = categories.filter(c => c.status === 'active').length;
  const inactiveCount = categories.filter(c => c.status !== 'active').length;

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
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>Service Categories</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>Manage top-level service categories available for users and workers.</p>
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
          ➕ Add New Category
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
          label="Active Categories"
          value={activeCount}
          icon="🟢"
          bg="var(--status-green-bg)"
          fg="var(--status-green-fg)"
          loading={loading}
        />
        <StatCard
          label="Inactive Categories"
          value={inactiveCount}
          icon="🔴"
          bg="var(--status-red-bg)"
          fg="var(--status-red-fg)"
          loading={loading}
        />
      </div>

      {/* Main Table Container */}
      <div style={{ background: 'var(--bg-card)', borderRadius: 16, border: '0.5px solid var(--border-color)', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        <div style={{ padding: '16px 20px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16 }}>
          <span style={{ fontWeight: 700, fontSize: 14, color: 'var(--text-primary)' }}>All Categories</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <input
              type="text"
              placeholder="Search category..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                padding: '6px 12px', borderRadius: 8, border: '1px solid var(--border-color)',
                fontSize: 12, background: 'var(--bg-app)', color: 'var(--text-primary)', outline: 'none'
              }}
            />
            <button
              onClick={fetchCategories}
              style={{ background: 'none', border: 'none', color: 'var(--accent-color)', cursor: 'pointer', fontSize: 12, fontWeight: 600 }}
            >
              🔄 Refresh
            </button>
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)', fontSize: 13 }}>
            Loading categories...
          </div>
        ) : categories.length === 0 ? (
          <div style={{ padding: '60px 40px', textAlign: 'center' }}>
            <div style={{ fontSize: 32, marginBottom: 12 }}>🗂️</div>
            <div style={{ fontWeight: 600, color: 'var(--text-primary)', fontSize: 14, marginBottom: 4 }}>No Categories Found</div>
            <div style={{ color: 'var(--text-secondary)', fontSize: 12, marginBottom: 16 }}>Create your first service category to organize services.</div>
            <button
              onClick={handleOpenCreate}
              style={{ background: 'var(--accent-color)', border: 'none', borderRadius: 6, color: 'var(--bg-card)', padding: '6px 12px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
            >
              Add Category
            </button>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: 13 }}>
              <thead>
                <tr style={{ background: 'var(--bg-app)', borderBottom: '0.5px solid var(--border-color)', color: 'var(--text-secondary)' }}>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 80 }}>Icon</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 200 }}>Category Name</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600 }}>Description</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 120 }}>Status</th>
                  <th style={{ padding: '14px 20px', fontWeight: 600, width: 160, textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {categories.map((c) => (
                  <tr key={c.id} style={{ borderBottom: '0.5px solid var(--bg-muted)', transition: 'background 0.15s' }}>
                    <td style={{ padding: '12px 20px' }}>
                      <div style={{ width: 44, height: 44, borderRadius: 10, background: 'var(--bg-muted)', overflow: 'hidden', border: '0.5px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {c.icon_url ? (
                          <img
                            src={resolveIconUrl(c.icon_url)}
                            alt={c.name}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            onError={(e) => {
                              e.target.onerror = null;
                              e.target.src = 'https://placehold.co/44x44?text=Icon';
                            }}
                          />
                        ) : (
                          <span style={{ fontSize: 20 }}>🛠️</span>
                        )}
                      </div>
                    </td>
                    <td style={{ padding: '12px 20px', fontWeight: 700, color: 'var(--text-primary)' }}>
                      {c.name}
                    </td>
                    <td style={{ padding: '12px 20px', color: 'var(--text-secondary)', fontSize: 12 }}>
                      {c.description || <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>No description</span>}
                    </td>
                    <td style={{ padding: '12px 20px' }}>
                      <span
                        onClick={() => handleToggleStatus(c)}
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 5,
                          padding: '3px 8px',
                          borderRadius: 12,
                          fontSize: 11,
                          fontWeight: 600,
                          cursor: 'pointer',
                          background: c.status === 'active' ? 'var(--status-green-bg)' : 'var(--bg-muted)',
                          color: c.status === 'active' ? 'var(--status-green-fg)' : 'var(--text-secondary)',
                        }}
                      >
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: c.status === 'active' ? '#10B981' : 'var(--text-secondary)' }} />
                        {c.status === 'active' ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td style={{ padding: '12px 20px', textAlign: 'right' }}>
                      <button
                        onClick={() => handleOpenEdit(c)}
                        style={{ background: 'none', border: 'none', color: 'var(--accent-color)', marginRight: 12, cursor: 'pointer', fontWeight: 600, fontSize: 12 }}
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDelete(c)}
                        style={{ background: 'none', border: 'none', color: 'var(--status-red-fg)', cursor: 'pointer', fontWeight: 600, fontSize: 12 }}
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

      {/* Modal for Create / Edit */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(17, 24, 39, 0.4)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div
            className="animate-fade"
            style={{
              background: 'var(--bg-card)', borderRadius: 20, width: '100%', maxWidth: 480,
              boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)',
              border: '0.5px solid var(--border-color)', overflow: 'hidden'
            }}
          >
            <div style={{ padding: '20px 24px', borderBottom: '0.5px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--text-primary)' }}>
                {editingCategory ? 'Edit Service Category' : 'Add New Category'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                style={{ background: 'none', border: 'none', fontSize: 18, color: 'var(--text-muted)', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSubmit} style={{ padding: '24px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: 6 }}>
                    Category Name *
                  </label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="E.g., Appliance Services"
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, boxSizing: 'border-box' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: 6 }}>
                    Description
                  </label>
                  <textarea
                    rows={3}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="Brief details about what services are included..."
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, boxSizing: 'border-box', fontFamily: 'inherit' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: 6 }}>
                    Status
                  </label>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value)}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, background: 'var(--bg-card)', boxSizing: 'border-box' }}
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: 6 }}>
                    Google Drive Link or Icon Image URL
                  </label>
                  <input
                    type="text"
                    value={iconUrlInput}
                    onChange={handleIconUrlChange}
                    placeholder="Paste Google Drive link or icon URL..."
                    style={{ width: '100%', padding: '10px 12px', borderRadius: 8, border: '1px solid #D1D5DB', fontSize: 13, boxSizing: 'border-box', marginBottom: 6 }}
                  />
                  <div style={{ fontSize: 11, color: '#6B7280', marginBottom: 12 }}>
                    💡 <b>Google Drive support:</b> Drive share links are automatically converted to direct icon images!
                  </div>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: 6 }}>
                    OR Upload Local File
                  </label>
                  <div style={{
                    border: '2px dashed #D1D5DB', borderRadius: 12, padding: '16px',
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    background: 'var(--bg-app)', cursor: 'pointer', position: 'relative'
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
                          style={{ width: 60, height: 60, objectFit: 'contain', borderRadius: 8 }}
                        />
                        <span style={{ fontSize: 11, color: 'var(--accent-color)', fontWeight: 600 }}>Click or drag to replace icon</span>
                      </div>
                    ) : (
                      <div style={{ textAlign: 'center', color: 'var(--text-secondary)' }}>
                        <div style={{ fontSize: 24, marginBottom: 6 }}>📤</div>
                        <div style={{ fontSize: 12, fontWeight: 600 }}>Upload Icon File</div>
                        <div style={{ fontSize: 10, color: 'var(--text-muted)', marginTop: 2 }}>Drag & drop or click to browse</div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 28, borderTop: '0.5px solid var(--border-color)', paddingTop: 16 }}>
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  style={{ background: 'var(--bg-muted)', border: 'none', borderRadius: 8, color: 'var(--text-primary)', padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    background: 'var(--accent-color)', border: 'none', borderRadius: 8, color: 'var(--bg-card)',
                    padding: '8px 20px', fontSize: 12, fontWeight: 600, cursor: 'pointer',
                    opacity: submitting ? 0.7 : 1, display: 'flex', alignItems: 'center', gap: 6
                  }}
                >
                  {submitting ? 'Saving...' : (editingCategory ? 'Save Changes' : 'Add Category')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
