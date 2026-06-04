import { useState } from 'react';

const NAV = [
  {
    items: [
      { icon: '⊞', label: 'Dashboard', key: 'dashboard', active: true },
    ],
  },
  {
    label: 'Management',
    items: [
      { icon: '👥', label: 'Users', key: 'users', badge: 12 },
      { icon: '💼', label: 'Workers', key: 'workers' },
      { icon: '🪪', label: 'KYC', key: 'kyc', badge: 5 },
      { icon: '📅', label: 'Bookings', key: 'bookings' },
      { icon: '🧾', label: 'Invoices', key: 'invoices' },
    ],
  },
  {
    label: 'Platform',
    items: [
      { icon: '💳', label: 'Payments', key: 'payments', isNew: true },
      { icon: '⭐', label: 'Reviews', key: 'reviews', isNew: true },
      { icon: '💬', label: 'Support', key: 'support' },
      { icon: '🗂️', label: 'Services', key: 'services' },
    ],
  },
  {
    label: 'Config',
    items: [
      { icon: '🔔', label: 'Notifications', key: 'notifications', isNew: true },
      { icon: '📍', label: 'Locations', key: 'locations', isNew: true },
      { icon: '🔐', label: 'Roles & Perms', key: 'roles', isNew: true },
      { icon: '⚙️', label: 'Settings', key: 'settings', isNew: true },
    ],
  },
];

const s = {
  sidebar: {
    width: 220,
    background: '#fff',
    borderRight: '0.5px solid #E5E7EB',
    display: 'flex',
    flexDirection: 'column',
    flexShrink: 0,
    height: '100vh',
    position: 'sticky',
    top: 0,
    fontFamily: "'DM Sans', system-ui, sans-serif",
  },
  logoArea: {
    padding: '18px 18px 16px',
    borderBottom: '0.5px solid #E5E7EB',
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    flexShrink: 0,
  },
  logoDot: {
    width: 30,
    height: 30,
    background: '#1A56DB',
    borderRadius: 8,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: 15,
    color: '#fff',
    flexShrink: 0,
  },
  logoText: {
    fontSize: 13,
    fontWeight: 600,
    color: '#111827',
    lineHeight: 1.3,
  },
  logoSub: {
    fontSize: 11,
    color: '#9CA3AF',
  },
  navSection: {
    padding: '10px 10px 4px',
  },
  navLabel: {
    fontSize: 10,
    fontWeight: 600,
    color: '#9CA3AF',
    letterSpacing: '0.08em',
    textTransform: 'uppercase',
    padding: '4px 6px 6px',
  },
  navItem: (active) => ({
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    padding: '7px 10px',
    borderRadius: 8,
    fontSize: 13,
    color: active ? '#1A56DB' : '#6B7280',
    fontWeight: active ? 600 : 400,
    background: active ? '#EFF4FF' : 'transparent',
    cursor: 'pointer',
    marginBottom: 2,
    transition: 'background 0.15s, color 0.15s',
    userSelect: 'none',
  }),
  iconWrap: {
    fontSize: 15,
    width: 18,
    textAlign: 'center',
    flexShrink: 0,
  },
  badge: {
    marginLeft: 'auto',
    background: '#EF4444',
    color: '#fff',
    fontSize: 10,
    borderRadius: 10,
    padding: '1px 6px',
    fontWeight: 600,
  },
  badgeNew: {
    marginLeft: 'auto',
    background: '#D1FAE5',
    color: '#065F46',
    fontSize: 10,
    borderRadius: 10,
    padding: '1px 6px',
    fontWeight: 600,
  },
  footer: {
    padding: '14px 14px',
    borderTop: '0.5px solid #E5E7EB',
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    flexShrink: 0,
  },
  avatar: {
    width: 30,
    height: 30,
    borderRadius: '50%',
    background: '#EFF4FF',
    color: '#1A56DB',
    fontSize: 11,
    fontWeight: 700,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  footerName: {
    fontSize: 12,
    fontWeight: 600,
    color: '#111827',
  },
  footerRole: {
    fontSize: 11,
    color: '#9CA3AF',
  },
};

export default function Sidebar({ activeKey, onNav, onLogout }) {
  const [hovered, setHovered] = useState(null);

  return (
    <aside style={s.sidebar}>
      {/* Logo */}
      <div style={s.logoArea}>
        <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" style={{ flexShrink: 0 }}>
          <defs>
            <linearGradient id="logoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#2563EB" />
              <stop offset="100%" stopColor="#3B82F6" />
            </linearGradient>
          </defs>
          <rect width="32" height="32" rx="8" fill="url(#logoGrad)" />
          <path d="M16 7L24 13.5V23.5H8V13.5L16 7Z" fill="white" fillOpacity="0.2" />
          <path d="M16 7L24 13.5M16 7L8 13.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          <path d="M12 18L15 21L21 14" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <div>
          <div style={s.logoText}>UrbanServe</div>
          <div style={s.logoSub}>Admin Panel</div>
        </div>
      </div>

      {/* Nav - scrollable */}
      <nav style={{ flex: 1, paddingTop: 8, overflowY: 'auto' }}>
        {NAV.map((section, si) => (
          <div key={si} style={s.navSection}>
            {section.label && (
              <div style={s.navLabel}>{section.label}</div>
            )}
            {section.items.map((item) => {
              const active = (activeKey || 'dashboard') === item.key;
              const isHovered = hovered === item.key;
              return (
                <div
                  key={item.key}
                  style={{
                    ...s.navItem(active),
                    background: active
                      ? '#EFF4FF'
                      : isHovered
                      ? '#F9FAFB'
                      : 'transparent',
                    color: active ? '#1A56DB' : isHovered ? '#111827' : '#6B7280',
                  }}
                  onClick={() => onNav?.(item.key)}
                  onMouseEnter={() => setHovered(item.key)}
                  onMouseLeave={() => setHovered(null)}
                >
                  <span style={s.iconWrap}>{item.icon}</span>
                  <span style={{ flex: 1 }}>{item.label}</span>
                  {item.badge && <span style={s.badge}>{item.badge}</span>}
                  {item.isNew && !item.badge && (
                    <span style={s.badgeNew}>New</span>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Footer user */}
      <div style={s.footer}>
        <div style={s.avatar}>PA</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ ...s.footerName, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>Prakash A.</div>
          <div style={s.footerRole}>Super Admin</div>
        </div>
        <button
          onClick={onLogout}
          title="Sign Out"
          style={{
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            fontSize: 16,
            color: '#9CA3AF',
            padding: '6px',
            borderRadius: '6px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            transition: 'color 0.15s, background-color 0.15s',
            flexShrink: 0,
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.color = '#DC2626';
            e.currentTarget.style.backgroundColor = '#FEF2F2';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.color = '#9CA3AF';
            e.currentTarget.style.backgroundColor = 'transparent';
          }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
        </button>
      </div>
    </aside>
  );
}