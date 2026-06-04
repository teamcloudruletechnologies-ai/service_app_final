            import { useState } from 'react';

const PAGE_META = {
  dashboard:     { title: 'Dashboard',       crumb: 'Admin Panel › Dashboard' },
  users:         { title: 'Users',           crumb: 'Admin Panel › Management › Users' },
  workers:       { title: 'Workers',         crumb: 'Admin Panel › Management › Workers' },
  kyc:           { title: 'KYC',             crumb: 'Admin Panel › Management › KYC' },
  bookings:      { title: 'Bookings',        crumb: 'Admin Panel › Management › Bookings' },
  invoices:      { title: 'Invoices',        crumb: 'Admin Panel › Management › Invoices' },
  payments:      { title: 'Payments',        crumb: 'Admin Panel › Platform › Payments' },
  reviews:       { title: 'Reviews',         crumb: 'Admin Panel › Platform › Reviews' },
  support:       { title: 'Support',         crumb: 'Admin Panel › Platform › Support' },
  services:      { title: 'Services',        crumb: 'Admin Panel › Platform › Services' },
  notifications: { title: 'Notifications',  crumb: 'Admin Panel › Config › Notifications' },
  locations:     { title: 'Locations',       crumb: 'Admin Panel › Config › Locations' },
  roles:         { title: 'Roles & Perms',   crumb: 'Admin Panel › Config › Roles & Perms' },
  settings:      { title: 'Settings',        crumb: 'Admin Panel › Config › Settings' },
};



const s = {
  topbar: {
    background: '#fff',
    borderBottom: '0.5px solid #E5E7EB',
    padding: '0 20px',
    height: 52,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    flexShrink: 0,
    fontFamily: "'DM Sans', system-ui, sans-serif",
  },
  left: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
  },
  title: {
    fontSize: 15,
    fontWeight: 600,
    color: '#111827',
    lineHeight: 1.3,
  },
  crumb: {
    fontSize: 11,
    color: '#9CA3AF',
  },
  right: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
  },
  iconBtn: (active) => ({
    width: 32,
    height: 32,
    borderRadius: 8,
    border: '0.5px solid #E5E7EB',
    background: active ? '#EFF4FF' : '#fff',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer',
    fontSize: 15,
    position: 'relative',
    transition: 'background 0.15s',
    flexShrink: 0,
  }),
  notifDot: {
    width: 6,
    height: 6,
    background: '#EF4444',
    borderRadius: '50%',
    position: 'absolute',
    top: 5,
    right: 5,
  },
  searchBox: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    background: '#F9FAFB',
    border: '0.5px solid #E5E7EB',
    borderRadius: 8,
    padding: '0 10px',
    height: 32,
    fontSize: 12,
    color: '#9CA3AF',
    cursor: 'pointer',
    width: 180,
    transition: 'border-color 0.15s',
  },
  divider: {
    width: 1,
    height: 20,
    background: '#E5E7EB',
    margin: '0 2px',
  },
  avatarBtn: {
    width: 32,
    height: 32,
    borderRadius: '50%',
    background: '#EFF4FF',
    color: '#1A56DB',
    fontSize: 12,
    fontWeight: 700,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer',
    border: '2px solid #BFDBFE',
    flexShrink: 0,
    fontFamily: "'DM Sans', system-ui, sans-serif",
  },
};

export default function Topbar({ activePage }) {
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchVal, setSearchVal] = useState('');
  const meta = PAGE_META[activePage] || PAGE_META.dashboard;

  return (
    <header style={s.topbar}>
      {/* Left: title + breadcrumb */}
      <div style={s.left}>
        <span style={s.title}>{meta.title}</span>
        <span style={s.crumb}>{meta.crumb}</span>
      </div>

      {/* Right: actions */}
      <div style={s.right}>
        {/* Inline search */}
        {searchOpen ? (
          <div
            style={{
              ...s.searchBox,
              borderColor: '#93C5FD',
              background: '#fff',
              width: 220,
            }}
          >
            <span style={{ fontSize: 14 }}>🔍</span>
            <input
              autoFocus
              value={searchVal}
              onChange={(e) => setSearchVal(e.target.value)}
              onBlur={() => { setSearchOpen(false); setSearchVal(''); }}
              placeholder="Search..."
              style={{
                border: 'none',
                outline: 'none',
                background: 'transparent',
                fontSize: 12,
                color: '#111827',
                width: '100%',
                fontFamily: "'DM Sans', system-ui, sans-serif",
              }}
            />
          </div>
        ) : (
          <div style={s.searchBox} onClick={() => setSearchOpen(true)}>
            <span style={{ fontSize: 14 }}>🔍</span>
            <span>Search...</span>
            <span
              style={{
                marginLeft: 'auto',
                fontSize: 10,
                background: '#E5E7EB',
                borderRadius: 4,
                padding: '1px 5px',
                color: '#6B7280',
                fontWeight: 500,
              }}
            >
              ⌘K
            </span>
          </div>
        )}

        <div style={s.divider} />

        {/* Notification bell */}
        <div style={s.iconBtn(false)} title="Notifications">
          🔔
          <span style={s.notifDot} />
        </div>

        {/* Refresh */}
        <div style={s.iconBtn(false)} title="Refresh">
          🔄
        </div>

        <div style={s.divider} />

        {/* Avatar */}
        <div style={s.avatarBtn} title="Prakash A. — Super Admin">
          PA
        </div>
      </div>
    </header>
  );
}