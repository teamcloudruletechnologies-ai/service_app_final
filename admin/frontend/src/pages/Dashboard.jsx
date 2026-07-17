import { useState, useEffect } from 'react';
import { dashboardAPI } from '../api';

/* ─── colour tokens ─── */
const C = {
  blue:   { bg: 'var(--accent-light)', fg: 'var(--accent-color)' },
  green:  { bg: 'var(--status-green-bg)', fg: 'var(--status-green-fg)' },
  amber:  { bg: 'var(--status-amber-bg)', fg: 'var(--status-amber-fg)' },
  purple: { bg: '#F5F3FF', fg: '#7C3AED' },
  red:    { bg: 'var(--status-red-bg)', fg: 'var(--status-red-fg)' },
};


const STATUS_STYLE = {
  Completed:     { background: 'var(--status-green-bg)', color: 'var(--status-green-fg)' },
  completed:     { background: 'var(--status-green-bg)', color: 'var(--status-green-fg)' },
  'In Progress': { background: 'var(--status-amber-bg)', color: 'var(--status-amber-fg)' },
  in_progress:   { background: 'var(--status-amber-bg)', color: 'var(--status-amber-fg)' },
  Pending:       { background: 'var(--accent-light)', color: 'var(--accent-dark)' },
  pending:       { background: 'var(--accent-light)', color: 'var(--accent-dark)' },
  Cancelled:     { background: 'var(--status-red-bg)', color: 'var(--status-red-fg)' },
  cancelled:     { background: 'var(--status-red-bg)', color: 'var(--status-red-fg)' },
};

const BAR_COLORS = ['var(--accent-border)','var(--accent-border)','#60A5FA','var(--accent-color)','var(--accent-color)','var(--accent-dark)','var(--accent-dark)'];
const DAYS = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

const SERVICE_DONUT = [
  { label: 'Plumbing',   val: '34%', color: 'var(--accent-color)' },
  { label: 'Cleaning',   val: '27%', color: '#10B981' },
  { label: 'Electrical', val: '19%', color: '#F59E0B' },
  { label: 'AC Service', val: '12%', color: '#8B5CF6' },
  { label: 'Others',     val: '8%',  color: 'var(--text-secondary)' },
];

const font = "'DM Sans', system-ui, sans-serif";
const card = {
  background: 'var(--bg-card)',
  border: '0.5px solid var(--border-color)',
  borderRadius: 12,
  padding: '14px 16px',
};

/* ─── helpers ─── */
function getBookingCount(bookings, status) {
  const found = bookings?.find(b => b.status === status);
  return found ? Number(found.total) : 0;
}

function formatRevenue(val) {
  const n = Number(val);
  if (n >= 100000) return `₹${(n / 100000).toFixed(1)}L`;
  if (n >= 1000)   return `₹${(n / 1000).toFixed(1)}K`;
  return `₹${n}`;
}

/* ─── Skeleton pulse ─── */
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

/* ─── sub-components ─── */
function StatCard({ label, value, trend, note, up, bg, fg, loading }) {
  // Select generic simple icons based on label keyword
  const isUsers = label.toLowerCase().includes('user') || label.toLowerCase().includes('worker');
  const isMoney = label.toLowerCase().includes('revenue');
  const isDoc = label.toLowerCase().includes('kyc');
  const isCheck = label.toLowerCase().includes('complete');
  const isCross = label.toLowerCase().includes('cancel');

  let Icon = (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
    </svg>
  );
  if (isUsers) Icon = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
  if (isMoney) Icon = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/></svg>;
  if (isDoc) Icon = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>;
  if (isCheck) Icon = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>;
  if (isCross) Icon = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>;

  return (
    <div style={{
      ...card, 
      border: '1px solid var(--border-color)', 
      boxShadow: '0 2px 8px rgba(28,25,23,0.03)',
      transition: 'all 0.2s ease',
      cursor: 'pointer'
    }}
    onMouseEnter={(e) => { e.currentTarget.style.borderColor = '#F87171'; e.currentTarget.style.boxShadow = '0 4px 12px rgba(226,55,68,0.08)'; e.currentTarget.style.transform = 'translateY(-2px)'; }}
    onMouseLeave={(e) => { e.currentTarget.style.borderColor = 'var(--border-color)'; e.currentTarget.style.boxShadow = '0 2px 8px rgba(28,25,23,0.03)'; e.currentTarget.style.transform = 'none'; }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-secondary)', marginBottom: 8, letterSpacing: '0.02em', textTransform: 'uppercase' }}>{label}</div>
          {loading
            ? <Skeleton w="60%" h={26} />
            : <div style={{ fontSize: 26, fontWeight: 800, color: 'var(--text-primary)', lineHeight: 1, letterSpacing: '-0.02em' }}>{value}</div>
          }
        </div>
        <div style={{ width: 42, height: 42, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <span style={{ color: fg, display: 'flex' }}>{Icon}</span>
        </div>
      </div>
      {(trend || note) && (
        loading
          ? <Skeleton w="70%" h={12} />
          : <div style={{ fontSize: 12, fontWeight: 500, color: up === false ? 'var(--status-red-fg)' : up ? 'var(--status-green-fg)' : 'var(--text-muted)' }}>
              {up === true && '↑ '}{up === false && '↓ '}{trend || note}
            </div>
      )}
    </div>
  );
}

function BarChart({ data }) {
  const [hov, setHov] = useState(null);
  const vals   = data?.length ? data.map(d => Number(d.revenue || 0)) : [38000,52000,44000,61000,73000,89000,67000];
  const labels = data?.length ? data.map(d => d.day || d.date?.slice(5,10)) : DAYS;
  const max    = Math.max(...vals) || 1;

  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 110, paddingBottom: 22, position: 'relative' }}>
      {vals.map((v, i) => {
        const h = Math.round((v / max) * 80);
        return (
          <div
            key={i}
            style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%', justifyContent: 'flex-end', cursor: 'default' }}
            onMouseEnter={() => setHov(i)}
            onMouseLeave={() => setHov(null)}
          >
            {hov === i && (
              <div style={{ fontSize: 10, color: 'var(--accent-color)', fontWeight: 700, position: 'absolute', bottom: 32 + h, background: 'var(--accent-light)', borderRadius: 4, padding: '2px 6px' }}>
                {formatRevenue(v)}
              </div>
            )}
            <div style={{
              width: '100%', height: h || 4, borderRadius: '4px 4px 0 0',
              background: BAR_COLORS[i % BAR_COLORS.length],
              opacity: hov === null || hov === i ? 1 : 0.5,
              transition: 'opacity 0.15s',
            }} />
            <span style={{ fontSize: 10, color: 'var(--text-muted)', position: 'absolute', bottom: 4 }}>{labels[i]}</span>
          </div>
        );
      })}
    </div>
  );
}

function DonutSVG({ totalBookings }) {
  const cx = 55, cy = 55, r = 42;
  let cursor = -90;
  const segs = SERVICE_DONUT.map((s) => {
    const pct   = parseFloat(s.val) / 100;
    const angle = pct * 360;
    const start = cursor;
    cursor += angle;
    return { ...s, start, angle };
  });
  function polar(angleDeg, radius) {
    const rad = (angleDeg * Math.PI) / 180;
    return [cx + radius * Math.cos(rad), cy + radius * Math.sin(rad)];
  }
  return (
    <svg width={110} height={110} viewBox="0 0 110 110">
      {segs.map((seg, i) => {
        const [x1,y1]   = polar(seg.start, r);
        const [x2,y2]   = polar(seg.start + seg.angle, r);
        const inner      = r - 18;
        const [ix1,iy1] = polar(seg.start, inner);
        const [ix2,iy2] = polar(seg.start + seg.angle, inner);
        const large      = seg.angle > 180 ? 1 : 0;
        return (
          <path key={i}
            d={`M ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2} L ${ix2} ${iy2} A ${inner} ${inner} 0 ${large} 0 ${ix1} ${iy1} Z`}
            fill={seg.color} stroke="var(--bg-card)" strokeWidth={1.5}
          />
        );
      })}
      <text x={cx} y={cy-5} textAnchor="middle" fontSize={11} fontWeight={700} fill="var(--text-primary)">{totalBookings || '—'}</text>
      <text x={cx} y={cy+9} textAnchor="middle" fontSize={8} fill="var(--text-muted)">bookings</text>
    </svg>
  );
}

/* ─── Dashboard ─── */
export default function Dashboard() {
  const [data,    setData]    = useState(null);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState(null);

  useEffect(() => {
    let active = true; // ✅ guard: prevent state update on unmounted component

    dashboardAPI.getStats()
      .then(res => {
        if (!active) return;
        // ✅ api interceptor already returns response.data — so res IS the data
        setData(res);
        setLoading(false);
      })
      .catch(err => {
        if (!active) return;
        console.error('Dashboard API error:', err);
        setError(err?.message || 'Failed to load');
        setLoading(false);
      });

    return () => { active = false; }; // ✅ cleanup on unmount
  }, []); // ✅ empty deps — runs only once

  /* ─── Parse ─── */
  const users          = data?.users;
  const workers        = data?.workers;
  const bookings       = data?.bookings       || [];
  const kyc            = data?.kyc            || [];
  const revenue        = data?.revenue        || 0;
  const recentBookings = data?.recentBookings || [];
  const revenueChart   = data?.revenueChart   || [];
  const activity       = data?.activity       || [];
  const todayStats     = data?.todayStats     || {};
  const activeWorkers  = data?.activeWorkers  || 0;
  const topServices    = data?.topServices    || [];

  const totalBookings   = bookings.reduce((s, b) => s + Number(b.total), 0);
  const completedCount  = getBookingCount(bookings, 'completed');
  const inProgressCount = getBookingCount(bookings, 'in_progress');
  const cancelledCount  = getBookingCount(bookings, 'cancelled');
  const kycPending      = kyc.find(k => k.status === 'pending');

  return (
    <>
      {/* shimmer keyframe */}
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>

      <div style={{ flex: 1, overflowY: 'auto', padding: '18px 20px', background: 'var(--bg-app)', fontFamily: font }}>

        {/* Error banner */}
        {error && (
          <div style={{ background: 'var(--status-red-bg)', color: 'var(--status-red-fg)', padding: '10px 14px', borderRadius: 8, marginBottom: 14, fontSize: 13 }}>
            ⚠️ API Error: {error} — showing cached data
          </div>
        )}

        {/* Today's Overview */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 12, marginBottom: 14 }}>
          <StatCard label="Today's Bookings"    value={todayStats.today_bookings ?? 0}                  note="Booked today"      up={null} loading={loading} bg="var(--accent-light)" fg="var(--accent-color)" />
          <StatCard label="Today's Revenue"     value={todayStats.today_revenue != null ? formatRevenue(todayStats.today_revenue) : '₹0'} note="Earned today"      up={null} loading={loading} bg="var(--accent-light)" fg="var(--accent-color)" />
          <StatCard label="Today Completed"     value={todayStats.today_completed ?? 0}                 note="Jobs finished"     up={null} loading={loading} bg="var(--status-green-bg)" fg="var(--status-green-fg)" />
          <StatCard label="Workers Online"      value={activeWorkers}                                   note="Active right now"  up={null} loading={loading} bg="#EFF6FF" fg="#2563EB" />
        </div>

        {/* Primary stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 12, marginBottom: 14 }}>
          <StatCard label="Total users"          value={users?.total   ? Number(users.total).toLocaleString()     : '0'} trend="+12.4% this month" up={true}  loading={loading} {...C.blue}   />
          <StatCard label="Active workers"       value={workers?.active ? Number(workers.active).toLocaleString() : '0'} trend="+5.1% this month"  up={true}  loading={loading} {...C.green}  />
          <StatCard label="Total bookings"       value={totalBookings   ? totalBookings.toLocaleString()           : '0'} trend="+8.9% this month"  up={true}  loading={loading} {...C.amber}  />
          <StatCard label="Revenue (this month)" value={formatRevenue(revenue)}                                           trend="+18.3% vs last mo" up={true}  loading={loading} {...C.purple} />
        </div>

        {/* Secondary stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 12, marginBottom: 14 }}>
          <StatCard label="Completed"   value={completedCount.toLocaleString()}  note={totalBookings ? `${((completedCount/totalBookings)*100).toFixed(1)}% completion rate` : '—'} up={null} loading={loading} {...C.green}  />
          <StatCard label="In Progress" value={inProgressCount.toLocaleString()} note="Live right now"                                                                               up={null} loading={loading} {...C.amber}  />
          <StatCard label="Cancelled"   value={cancelledCount.toLocaleString()}  note={totalBookings ? `${((cancelledCount/totalBookings)*100).toFixed(1)}% cancel rate`   : '—'} up={null} loading={loading} {...C.red}    />
          <StatCard label="KYC pending" value={kycPending ? Number(kycPending.total).toLocaleString() : '0'}                                                  note="Needs review"  up={null} loading={loading} {...C.blue}   />
        </div>

        {/* Charts row */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 14 }}>
          <div style={card}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>Revenue this week</span>
              <span style={{ fontSize: 12, color: 'var(--accent-color)', cursor: 'pointer' }}>View report →</span>
            </div>
            <BarChart data={revenueChart} />
          </div>
          <div style={card}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>Service breakdown</span>
              <span style={{ fontSize: 12, color: 'var(--accent-color)', cursor: 'pointer' }}>Details →</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <DonutSVG totalBookings={totalBookings} />
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {SERVICE_DONUT.map(d => (
                  <div key={d.label} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--text-secondary)' }}>
                    <div style={{ width: 8, height: 8, borderRadius: '50%', background: d.color, flexShrink: 0 }} />
                    <span style={{ flex: 1 }}>{d.label}</span>
                    <span style={{ fontWeight: 700, color: 'var(--text-primary)', paddingLeft: 10 }}>{d.val}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Top Services */}
        {topServices.length > 0 && (
          <div style={{ ...card, marginBottom: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
              <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>Top Services</span>
              <span style={{ fontSize: 12, color: 'var(--accent-color)', cursor: 'pointer' }}>View all →</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 10 }}>
              {topServices.slice(0, 6).map((s, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 10, background: 'var(--bg-muted)', transition: 'all 0.15s', cursor: 'pointer' }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--accent-light)'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--bg-muted)'; }}
                >
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--accent-light)', color: 'var(--accent-color)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 800, flexShrink: 0 }}>
                    #{i + 1}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{s.name}</div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{s.bookings} bookings · {formatRevenue(s.revenue)}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Bookings + KYC/Activity */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>

          {/* Recent bookings */}
          <div style={card}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
              <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>Recent bookings</span>
              <span style={{ fontSize: 12, color: 'var(--accent-color)', cursor: 'pointer' }}>View all →</span>
            </div>
            {loading ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {[1,2,3].map(i => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Skeleton w={30} h={30} radius={50} />
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
                      <Skeleton w="55%" h={13} />
                      <Skeleton w="40%" h={11} />
                    </div>
                    <Skeleton w={50} h={20} />
                  </div>
                ))}
              </div>
            ) : recentBookings.length === 0 ? (
              <div style={{ fontSize: 13, color: 'var(--text-muted)', padding: '12px 0' }}>No bookings yet</div>
            ) : (
              recentBookings.map((b, i) => {
                const init = (b.user_name || b.name || '??').split(' ').map(w => w[0]).join('').slice(0,2).toUpperCase();
                return (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '9px 0', borderBottom: '0.5px solid var(--bg-muted)' }}>
                    <div style={{ width: 30, height: 30, borderRadius: '50%', background: 'var(--accent-light)', color: 'var(--accent-color)', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{init}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{b.user_name || b.name || 'Unknown'}</div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{b.service_type || b.service || '—'} · {b.worker_name || b.worker || '—'}</div>
                    </div>
                    <div style={{ textAlign: 'right', flexShrink: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>₹{Number(b.amount).toLocaleString()}</div>
                      <div style={{ display: 'inline-flex', fontSize: 11, borderRadius: 4, padding: '2px 7px', fontWeight: 600, marginTop: 2, ...(STATUS_STYLE[b.status] || STATUS_STYLE.pending) }}>
                        {b.status}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* KYC + Activity */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={card}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>
                  KYC queue
                  {kycPending && Number(kycPending.total) > 0 && (
                    <span style={{ background: 'var(--status-amber-bg)', color: 'var(--status-amber-fg)', fontSize: 11, borderRadius: 10, padding: '1px 7px', marginLeft: 6, fontWeight: 600 }}>{kycPending.total}</span>
                  )}
                </span>
                <span style={{ fontSize: 12, color: 'var(--accent-color)', cursor: 'pointer' }}>Manage →</span>
              </div>
              {loading ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {[1,2].map(i => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <Skeleton w={30} h={30} radius={8} />
                      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
                        <Skeleton w="50%" h={13} />
                        <Skeleton w="35%" h={11} />
                      </div>
                      <Skeleton w={70} h={26} radius={6} />
                    </div>
                  ))}
                </div>
              ) : kyc.length === 0 ? (
                <div style={{ fontSize: 13, color: 'var(--text-muted)' }}>No KYC pending 🎉</div>
              ) : (
                kyc.filter(k => k.status === 'pending').slice(0,3).map((k, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: '0.5px solid var(--bg-muted)' }}>
                    <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--status-amber-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, flexShrink: 0 }}>🪪</div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>{k.worker_name || `Worker #${k.worker_id}`}</div>
                      <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>{k.service_type || '—'} · {k.status}</div>
                    </div>
                    <div style={{ display: 'flex', gap: 5 }}>
                      <button style={{ fontSize: 11, background: 'var(--status-green-bg)', color: 'var(--status-green-fg)', border: 'none', borderRadius: 6, padding: '4px 10px', cursor: 'pointer', fontWeight: 600, fontFamily: font }}>Approve</button>
                      <button style={{ fontSize: 11, background: 'var(--status-red-bg)', color: 'var(--status-red-fg)', border: 'none', borderRadius: 6, padding: '4px 10px', cursor: 'pointer', fontWeight: 600, fontFamily: font }}>Reject</button>
                    </div>
                  </div>
                ))
              )}
            </div>

            <div style={card}>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)', marginBottom: 10 }}>Platform activity</div>
              {loading ? (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {[1,2,3].map(i => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <Skeleton w={28} h={28} radius={8} />
                      <Skeleton w="65%" h={12} />
                      <Skeleton w={30} h={11} />
                    </div>
                  ))}
                </div>
              ) : activity.length === 0 ? (
                <div style={{ fontSize: 13, color: 'var(--text-muted)' }}>No recent activity</div>
              ) : (
                activity.slice(0,4).map((a, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 10, padding: '7px 0', borderBottom: i < activity.length - 1 ? '0.5px solid var(--bg-muted)' : 'none' }}>
                    <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--status-green-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, flexShrink: 0 }}>📋</div>
                    <div style={{ flex: 1, fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5 }}>{a.action || a.details || a.message}</div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)', flexShrink: 0 }}>{a.time || a.created_at?.slice(11,16)}</div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

      </div>
    </>
  );
}