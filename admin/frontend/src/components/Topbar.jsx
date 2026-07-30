import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

const PAGE_META = {
  dashboard:     { title: 'Dashboard',       crumb: 'Admin Panel > Dashboard' },
  users:         { title: 'Users',           crumb: 'Admin Panel > Management > Users' },
  workers:       { title: 'Workers',         crumb: 'Admin Panel > Management > Workers' },
  kyc:           { title: 'KYC',             crumb: 'Admin Panel > Management > KYC' },
  bookings:      { title: 'Bookings',        crumb: 'Admin Panel > Management > Bookings' },
  invoices:      { title: 'Invoices',        crumb: 'Admin Panel > Management > Invoices' },
  payments:      { title: 'Payments',        crumb: 'Admin Panel > Platform > Payments' },
  reviews:       { title: 'Reviews',         crumb: 'Admin Panel > Platform > Reviews' },
  support:       { title: 'Support',         crumb: 'Admin Panel > Platform > Support' },
  services:      { title: 'Services',        crumb: 'Admin Panel > Platform > Services' },
  banners:       { title: 'Banners',         crumb: 'Admin Panel > Platform > Banners' },
  notifications: { title: 'Notifications',  crumb: 'Admin Panel > Config > Notifications' },
  locations:     { title: 'Locations',       crumb: 'Admin Panel > Config > Locations' },
  roles:         { title: 'Roles & Perms',   crumb: 'Admin Panel > Config > Roles & Perms' },
  settings:      { title: 'Settings',        crumb: 'Admin Panel > Config > Settings' },
};

export default function Topbar({ activePage }) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchVal, setSearchVal] = useState('');
  const location = useLocation();
  const navigate = useNavigate();

  const pageKey = activePage || (location.pathname === '/' ? 'dashboard' : location.pathname.substring(1));
  const meta = PAGE_META[pageKey] || PAGE_META.dashboard;

  return (
    <header style={{
      background: '#FFFFFF',
      borderBottom: '1px solid #F3F4F6',
      padding: '0 28px',
      height: 64,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      flexShrink: 0,
      fontFamily: "'DM Sans', system-ui, sans-serif",
    }}>
      {/* Left: title + breadcrumb */}
      <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <span style={{ fontSize: 18, fontWeight: 800, color: '#1C1917', lineHeight: 1.2, letterSpacing: '-0.02em' }}>{meta.title}</span>
        <span style={{ fontSize: 11, color: '#A8A29E', fontWeight: 500, marginTop: 2, letterSpacing: '0.02em' }}>{meta.crumb}</span>
      </div>

      {/* Right: actions */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        {/* Search */}
        {searchOpen ? (
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
              background: '#FFFFFF', border: '1.5px solid #1C1917',
              borderRadius: 12, padding: '0 12px', height: 38, width: 240,
              boxShadow: '0 0 0 3px rgba(74, 83, 67, 0.08)',
            transition: 'all 0.2s',
          }}>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#1C1917" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <input
              autoFocus
              value={searchVal}
              onChange={(e) => setSearchVal(e.target.value)}
              onBlur={() => { setSearchOpen(false); setSearchVal(''); }}
              placeholder="Search platform..."
              style={{
                border: 'none', outline: 'none', background: 'transparent',
                fontSize: 13, color: '#1C1917', width: '100%',
                fontFamily: "'DM Sans', system-ui, sans-serif",
                fontWeight: 500,
              }}
            />
          </div>
        ) : (
          <div
            style={{
              display: 'flex', alignItems: 'center', gap: 8,
              background: '#FFFFFF', border: '1px solid #F3F4F6',
              borderRadius: 12, padding: '0 12px', height: 38,
              fontSize: 13, color: '#A8A29E', cursor: 'pointer', width: 200,
              transition: 'border-color 0.15s, box-shadow 0.15s',
              boxShadow: '0 2px 4px rgba(28,25,23,0.02)',
              fontWeight: 500,
            }}
            onClick={() => setSearchOpen(true)}
            onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#8A9683'; e.currentTarget.style.boxShadow = '0 2px 8px rgba(74, 83, 67, 0.08)'; }}
            onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#F3F4F6'; e.currentTarget.style.boxShadow = '0 2px 4px rgba(28,25,23,0.02)'; }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#A8A29E" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
            <span>Search...</span>
            <span style={{
              marginLeft: 'auto', fontSize: 10,
              background: '#F0F4EF', borderRadius: 4,
              padding: '2px 6px', color: '#4A5343', fontWeight: 700,
            }}>
              ⌘ K
            </span>
          </div>
        )}

        <div style={{ width: 1, height: 20, background: '#F3F4F6', margin: '0 4px' }} />

        {/* Notification bell */}
        <button
          onClick={() => navigate('/notifications')}
          style={{
            width: 38, height: 38, borderRadius: 12,
            border: '1px solid #F3F4F6', background: '#FFFFFF',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', position: 'relative',
            transition: 'all 0.15s',
            boxShadow: '0 2px 4px rgba(28,25,23,0.02)',
          }}
          title="Notifications"
          onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#8A9683'; e.currentTarget.style.color = '#4A5343'; }}
          onMouseLeave={(e) => { e.currentTarget.style.borderColor = '#F3F4F6'; e.currentTarget.style.color = '#78716C'; }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ color: 'inherit' }}>
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
          <span style={{
            width: 8, height: 8, background: '#4A5343',
            borderRadius: '50%', position: 'absolute', top: 8, right: 8,
            border: '1.5px solid #FFFFFF'
          }} />
        </button>

        {/* Avatar */}
        <div
          style={{
            width: 38, height: 38, borderRadius: '50%',
            background: '#4A5343', color: '#FFFFFF',
            fontSize: 12, fontWeight: 800,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', border: '2px solid #FFFFFF',
            boxShadow: '0 2px 8px rgba(28,25,23,0.15)',
            flexShrink: 0, fontFamily: "'DM Sans', system-ui, sans-serif",
            marginLeft: 4,
          }}
          title="Prakash A. — Super Admin"
        >
          PA
        </div>
      </div>
    </header>
  );
}