import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

// SVG Icons for professional look
const Icons = {
  Dashboard: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/></svg>,
  Users: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>,
  Workers: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>,
  KYC: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>,
  Bookings: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>,
  Invoices: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>,
  Payments: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>,
  Reviews: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>,
  Support: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>,
  Services: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>,
  Banners: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>,
  Notifications: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>,
  Locations: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>,
  Roles: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>,
  Settings: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
};

const NAV = [
  {
    items: [
      { label: 'Dashboard', key: 'dashboard', icon: Icons.Dashboard },
    ],
  },
  {
    label: 'Management',
    items: [
      { label: 'Users', key: 'users', badge: 12, icon: Icons.Users },
      { label: 'Workers', key: 'workers', icon: Icons.Workers },
      { label: 'KYC', key: 'kyc', badge: 5, icon: Icons.KYC },
      { label: 'Bookings', key: 'bookings', icon: Icons.Bookings },
      { label: 'Invoices', key: 'invoices', icon: Icons.Invoices },
    ],
  },
  {
    label: 'Platform',
    items: [
      { label: 'Payments', key: 'payments', icon: Icons.Payments },
      { label: 'Reviews', key: 'reviews', icon: Icons.Reviews },
      { label: 'Support', key: 'support', icon: Icons.Support },
      { label: 'Services', key: 'services', icon: Icons.Services },
      { label: 'Banners', key: 'banners', icon: Icons.Banners },
    ],
  },
  {
    label: 'Config',
    items: [
      { label: 'Notifications', key: 'notifications', icon: Icons.Notifications },
      { label: 'Roles & Perms', key: 'roles', icon: Icons.Roles },
      { label: 'Settings', key: 'settings', icon: Icons.Settings },
    ],
  },
];

export default function Sidebar({ activeKey, onNav, onLogout }) {
  const [hovered, setHovered] = useState(null);
  const location = useLocation();
  const navigate = useNavigate();

  // Determine current active page key from pathname
  const currentKey = activeKey || (location.pathname === '/' ? 'dashboard' : location.pathname.substring(1));

  // Dark black with olive accent
  const bgMain = '#181512';
  const borderCol = '#2D2721';
  const hoverBg = '#1E221B';
  const activeBg = '#4A5343'; // Muted Olive Green for active
  const textActive = '#FAF7F0';
  const textInactive = '#A89E91';

  const handleItemClick = (itemKey) => {
    const path = itemKey === 'dashboard' ? '/' : `/${itemKey}`;
    navigate(path);
    if (onNav) onNav(itemKey);
  };

  return (
    <aside style={{
      width: 230,
      background: bgMain,
      borderRight: `1px solid ${borderCol}`,
      display: 'flex',
      flexDirection: 'column',
      flexShrink: 0,
      height: '100vh',
      position: 'sticky',
      top: 0,
      fontFamily: "'DM Sans', system-ui, sans-serif",
    }}>
      {/* Logo */}
      <div style={{
        padding: '20px 20px 16px',
        borderBottom: `1px solid ${borderCol}`,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        flexShrink: 0,
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 10,
          background: 'linear-gradient(135deg, #4A5343, #373E32)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          boxShadow: '0 2px 8px rgba(74, 83, 67, 0.25)',
        }}>
          <svg width="18" height="18" viewBox="0 0 32 32" fill="none">
            <path d="M16 7L24 13.5V23.5H8V13.5L16 7Z" fill="#FAF7F0" fillOpacity="0.3" />
            <path d="M16 7L24 13.5M16 7L8 13.5" stroke="#FAF7F0" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            <path d="M12 18L15 21L21 14" stroke="#FAF7F0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <div>
          <div style={{ fontSize: 15, fontWeight: 800, color: '#FAF7F0', letterSpacing: '-0.02em', lineHeight: 1 }}>UrbanServe</div>
          <div style={{ fontSize: 10, color: '#4A5343', fontWeight: 600, marginTop: 3, letterSpacing: '0.05em' }}>ADMIN PANEL</div>
        </div>
      </div>

      {/* Nav - scrollable */}
      <nav style={{ flex: 1, paddingTop: 10, overflowY: 'auto' }}>
        {NAV.map((section, si) => (
          <div key={si} style={{ padding: '8px 12px 4px' }}>
            {section.label && (
              <div style={{
                fontSize: 10, fontWeight: 700, color: '#736555',
                letterSpacing: '0.12em', textTransform: 'uppercase',
                padding: '6px 12px 8px',
              }}>
                {section.label}
              </div>
            )}
            {section.items.map((item) => {
              const active = currentKey === item.key;
              const isHovered = hovered === item.key;
              return (
                <div
                  key={item.key}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    padding: '10px 14px',
                    borderRadius: 10,
                    fontSize: 13.5,
                    fontWeight: active ? 700 : 600, // bolder words
                    color: active ? '#181512' : isHovered ? textActive : textInactive,
                    background: active ? activeBg : isHovered ? hoverBg : 'transparent',
                    cursor: 'pointer',
                    marginBottom: 2,
                    transition: 'all 0.15s ease',
                    userSelect: 'none',
                    letterSpacing: '-0.01em',
                  }}
                  onClick={() => handleItemClick(item.key)}
                  onMouseEnter={() => setHovered(item.key)}
                  onMouseLeave={() => setHovered(null)}
                >
                  <span style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center', 
                    opacity: active ? 1 : isHovered ? 0.9 : 0.7 
                  }}>
                    {item.icon}
                  </span>
                  <span style={{ flex: 1 }}>{item.label}</span>
                  {item.badge && (
                    <span style={{
                      marginLeft: 'auto',
                      background: active ? '#181512' : '#4A5343',
                      color: active ? '#4A5343' : '#181512',
                      fontSize: 10,
                      borderRadius: 10,
                      padding: '2px 8px',
                      fontWeight: 800,
                      letterSpacing: '0.02em',
                    }}>
                      {item.badge}
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Footer user */}
      <div style={{
        padding: '16px 20px',
        borderTop: `1px solid ${borderCol}`,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        flexShrink: 0,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: '50%',
          background: '#1D211A',
          color: '#4A5343',
          fontSize: 12, fontWeight: 800,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          border: '1.5px solid #2F362C',
        }}>PA</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#FAF7F0', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>Prakash A.</div>
          <div style={{ fontSize: 11, color: '#A89E91', fontWeight: 500, marginTop: 2 }}>Super Admin</div>
        </div>
        <button
          onClick={onLogout}
          title="Sign Out"
          style={{
            background: 'none', border: 'none', cursor: 'pointer',
            fontSize: 18, color: '#736555', padding: '6px',
            borderRadius: '8px', display: 'flex', alignItems: 'center',
            justifyContent: 'center', transition: 'all 0.15s ease',
            flexShrink: 0,
          }}
          onMouseEnter={(e) => { e.currentTarget.style.color = '#4A5343'; e.currentTarget.style.backgroundColor = 'rgba(74, 83, 67, 0.1)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.color = '#736555'; e.currentTarget.style.backgroundColor = 'transparent'; }}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
        </button>
      </div>
    </aside>
  );
}