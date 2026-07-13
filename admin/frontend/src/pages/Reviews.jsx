import { useState, useEffect } from 'react';
import { reviewsAPI } from '../api';

function Skeleton({ w = '100%', h = 16, radius = 6 }) {
  return (
    <div style={{
      width: w, height: h, borderRadius: radius,
      background: 'linear-gradient(90deg,#F3F4F6 25%,#E5E7EB 50%,#F3F4F6 75%)',
      backgroundSize: '200% 100%',
      animation: 'shimmer 1.4s infinite',
    }} />
  );
}

function StarRow({ rating }) {
  return (
    <div style={{ display: 'flex', gap: 2 }}>
      {[1, 2, 3, 4, 5].map(i => (
        <span key={i} style={{ color: i <= rating ? '#FBBF24' : '#E5E7EB', fontSize: 14 }}>★</span>
      ))}
      <span style={{ fontSize: 12, color: '#6B7280', marginLeft: 4, fontWeight: 600 }}>{rating}/5</span>
    </div>
  );
}

function StatCard({ label, value, icon, bg, fg, loading }) {
  return (
    <div style={{
      background: '#fff', border: '0.5px solid #E5E7EB', borderRadius: 12,
      padding: '16px 20px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
    }}>
      <div>
        <div style={{ fontSize: 12, color: '#6B7280', marginBottom: 6, fontWeight: 500 }}>{label}</div>
        {loading ? <Skeleton w="70px" h={28} /> : (
          <div style={{ fontSize: 24, fontWeight: 700, color: '#111827' }}>{value}</div>
        )}
      </div>
      <div style={{
        width: 44, height: 44, borderRadius: 10, backgroundColor: bg, color: fg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22, flexShrink: 0,
      }}>{icon}</div>
    </div>
  );
}

export default function Reviews() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [search, setSearch] = useState('');
  const [filterRating, setFilterRating] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const limit = 10;

  const [stats, setStats] = useState({ total: 0, avg: 0, fiveStar: 0, oneStar: 0 });

  const fetchReviews = () => {
    setLoading(true);
    setError('');
    reviewsAPI.getAll()
      .then(res => {
        if (res && res.success) {
          const list = res.data?.rows || res.data || [];
          setReviews(list);
          calcStats(list);
        }
      })
      .catch(err => {
        console.error('Error fetching reviews:', err);
        setError(err?.message || 'Failed to load reviews.');
      })
      .finally(() => setLoading(false));
  };

  const calcStats = (list) => {
    const total = list.length;
    const avg = total ? (list.reduce((a, r) => a + (r.rating || 0), 0) / total).toFixed(1) : '0.0';
    const fiveStar = list.filter(r => r.rating === 5).length;
    const oneStar = list.filter(r => r.rating === 1).length;
    setStats({ total, avg, fiveStar, oneStar });
  };

  useEffect(() => { fetchReviews(); }, []);

  const formatDate = (d) => {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  const filtered = reviews.filter(r => {
    const s = search.toLowerCase().trim();
    const matchSearch = !s ||
      (r.user_name || '').toLowerCase().includes(s) ||
      (r.worker_name || '').toLowerCase().includes(s) ||
      (r.comment || '').toLowerCase().includes(s);
    const matchRating = !filterRating || r.rating === Number(filterRating);
    return matchSearch && matchRating;
  });

  const totalPages = Math.ceil(filtered.length / limit) || 1;
  const paginated = filtered.slice((currentPage - 1) * limit, currentPage * limit);

  useEffect(() => setCurrentPage(1), [search, filterRating]);

  const getRatingBadge = (rating) => {
    if (rating >= 4) return { bg: '#D1FAE5', fg: '#065F46' };
    if (rating >= 3) return { bg: '#FFFBEB', fg: '#D97706' };
    return { bg: '#FEE2E2', fg: '#991B1B' };
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: '#F9FAFB', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        .review-row { transition: background 0.1s; }
        .review-row:hover { background: #F9FAFB; }
      `}</style>

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: '#111827', margin: 0 }}>Reviews & Feedback</h2>
          <p style={{ fontSize: 12, color: '#6B7280', margin: '4px 0 0' }}>
            Analyze customer experiences, monitor service quality, and view worker ratings.
          </p>
        </div>
        <button
          onClick={fetchReviews}
          style={{ background: '#1A56DB', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 12, fontWeight: 600, cursor: 'pointer', color: '#fff' }}
        >
          🔄 Refresh
        </button>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        <StatCard label="Total Reviews" value={stats.total} icon="📝" bg="#EFF4FF" fg="#1A56DB" loading={loading} />
        <StatCard label="Average Rating" value={`${stats.avg} ★`} icon="⭐" bg="#FFFBEB" fg="#D97706" loading={loading} />
        <StatCard label="5-Star Reviews" value={stats.fiveStar} icon="🌟" bg="#F0FDF4" fg="#059669" loading={loading} />
        <StatCard label="1-Star Reviews" value={stats.oneStar} icon="⚠️" bg="#FEF2F2" fg="#DC2626" loading={loading} />
      </div>

      {/* Rating Distribution Bar */}
      {!loading && stats.total > 0 && (
        <div style={{ background: '#fff', border: '0.5px solid #E5E7EB', borderRadius: 12, padding: '16px 20px', marginBottom: 20, boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
          <div style={{ fontSize: 12, fontWeight: 600, color: '#4B5563', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            Rating Distribution
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[5, 4, 3, 2, 1].map(star => {
              const count = reviews.filter(r => r.rating === star).length;
              const pct = stats.total ? Math.round((count / stats.total) * 100) : 0;
              const color = star >= 4 ? '#10B981' : star === 3 ? '#F59E0B' : '#EF4444';
              return (
                <div key={star} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 12, color: '#374151', width: 30, textAlign: 'right' }}>{star}★</span>
                  <div style={{ flex: 1, height: 8, background: '#F3F4F6', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{ width: `${pct}%`, height: '100%', background: color, borderRadius: 4, transition: 'width 0.6s ease' }} />
                  </div>
                  <span style={{ fontSize: 11, color: '#6B7280', width: 60 }}>{count} ({pct}%)</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Table Container */}
      <div style={{ background: '#fff', border: '0.5px solid #E5E7EB', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

        {/* Controls */}
        <div style={{ padding: '16px 24px', borderBottom: '0.5px solid #E5E7EB', display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: 240, maxWidth: 380 }}>
            <input
              type="text"
              placeholder="Search by customer, worker, or comment..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: '100%', padding: '8px 12px 8px 34px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', fontFamily: 'inherit', boxSizing: 'border-box' }}
            />
            <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#9CA3AF', fontSize: 14 }}>🔍</span>
          </div>
          <select
            value={filterRating}
            onChange={(e) => setFilterRating(e.target.value)}
            style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, color: '#374151', outline: 'none', fontFamily: 'inherit', fontWeight: 500 }}
          >
            <option value="">All Ratings</option>
            <option value="5">★★★★★ 5 Stars</option>
            <option value="4">★★★★☆ 4 Stars</option>
            <option value="3">★★★☆☆ 3 Stars</option>
            <option value="2">★★☆☆☆ 2 Stars</option>
            <option value="1">★☆☆☆☆ 1 Star</option>
          </select>
          {(search || filterRating) && (
            <button
              onClick={() => { setSearch(''); setFilterRating(''); }}
              style={{ border: 'none', background: 'none', color: '#6B7280', fontSize: 12, cursor: 'pointer', textDecoration: 'underline' }}
            >
              Clear filters
            </button>
          )}
          <span style={{ marginLeft: 'auto', fontSize: 12, color: '#6B7280' }}>
            {filtered.length} review{filtered.length !== 1 ? 's' : ''}
          </span>
        </div>

        {error && (
          <div style={{ background: '#FEE2E2', border: '1px solid #FCA5A5', color: '#991B1B', padding: '12px 16px', margin: '16px 24px 0', borderRadius: 8, fontSize: 13 }}>
            ⚠️ <strong>Error:</strong> {error}
            <button onClick={fetchReviews} style={{ marginLeft: 12, background: 'none', border: 'none', color: '#991B1B', cursor: 'pointer', textDecoration: 'underline', fontSize: 12 }}>Retry</button>
          </div>
        )}

        {/* Table */}
        <div style={{ overflowX: 'auto', padding: '0 24px 20px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', minWidth: 800 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #E5E7EB', color: '#4B5563', fontSize: 11, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                <th style={{ padding: '14px 8px' }}>Customer</th>
                <th style={{ padding: '14px 8px' }}>Worker</th>
                <th style={{ padding: '14px 8px' }}>Rating</th>
                <th style={{ padding: '14px 8px' }}>Comment</th>
                <th style={{ padding: '14px 8px' }}>Booking</th>
                <th style={{ padding: '14px 8px' }}>Date</th>
              </tr>
            </thead>
            <tbody style={{ fontSize: 13, color: '#374151' }}>
              {loading ? (
                [...Array(5)].map((_, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid #F3F4F6' }}>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="130px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="110px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="100px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="250px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="60px" /></td>
                    <td style={{ padding: '14px 8px' }}><Skeleton w="90px" /></td>
                  </tr>
                ))
              ) : paginated.length === 0 ? (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '48px 0', color: '#9CA3AF' }}>
                    <div style={{ fontSize: 36, marginBottom: 10 }}>⭐</div>
                    <div style={{ fontWeight: 600, color: '#4B5563', marginBottom: 4 }}>
                      {search || filterRating ? 'No matching reviews' : 'No reviews submitted yet'}
                    </div>
                    <div style={{ fontSize: 12 }}>
                      {search || filterRating ? 'Try adjusting your filters.' : 'Customer reviews will appear here once submitted in the app.'}
                    </div>
                  </td>
                </tr>
              ) : (
                paginated.map(r => {
                  const badge = getRatingBadge(r.rating);
                  return (
                    <tr key={r.id} className="review-row" style={{ borderBottom: '1px solid #F3F4F6' }}>
                      <td style={{ padding: '14px 8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <div style={{ width: 30, height: 30, borderRadius: '50%', background: '#EFF4FF', color: '#1A56DB', fontSize: 11, fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                            {(r.user_name || 'C')[0].toUpperCase()}
                          </div>
                          <span style={{ fontWeight: 600, color: '#111827' }}>{r.user_name || 'Customer'}</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: '#4B5563' }}>{r.worker_name || '—'}</td>
                      <td style={{ padding: '14px 8px' }}>
                        <div>
                          <StarRow rating={r.rating} />
                          <span style={{ fontSize: 10, borderRadius: 4, padding: '1px 6px', marginTop: 4, display: 'inline-block', backgroundColor: badge.bg, color: badge.fg, fontWeight: 700 }}>
                            {r.rating >= 4 ? 'Positive' : r.rating >= 3 ? 'Neutral' : 'Negative'}
                          </span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 8px', color: '#4B5563', maxWidth: 280 }}>
                        {r.comment ? (
                          <span title={r.comment} style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                            "{r.comment}"
                          </span>
                        ) : (
                          <span style={{ fontStyle: 'italic', color: '#9CA3AF' }}>No comment provided</span>
                        )}
                      </td>
                      <td style={{ padding: '14px 8px', color: '#6B7280', fontSize: 12 }}>
                        {r.booking_id ? `#${r.booking_id}` : '—'}
                      </td>
                      <td style={{ padding: '14px 8px', color: '#6B7280', fontSize: 12 }}>{formatDate(r.created_at)}</td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {!loading && filtered.length > limit && (
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 24px', borderTop: '0.5px solid #F3F4F6' }}>
            <span style={{ fontSize: 12, color: '#6B7280' }}>
              Page <strong>{currentPage}</strong> of <strong>{totalPages}</strong> · <strong>{filtered.length}</strong> reviews
            </span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid #E5E7EB', background: '#fff', color: currentPage === 1 ? '#9CA3AF' : '#374151', fontSize: 12, cursor: currentPage === 1 ? 'not-allowed' : 'pointer' }}>
                ◀ Prev
              </button>
              <button disabled={currentPage === totalPages} onClick={() => setCurrentPage(p => p + 1)}
                style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid #E5E7EB', background: '#fff', color: currentPage === totalPages ? '#9CA3AF' : '#374151', fontSize: 12, cursor: currentPage === totalPages ? 'not-allowed' : 'pointer' }}>
                Next ▶
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
