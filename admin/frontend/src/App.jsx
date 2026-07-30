import { useState, useEffect, useRef } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Topbar from './components/Topbar';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Invoices from './pages/Invoices';
import Bookings from './pages/Bookings';
import Users from './pages/Users';
import Services from './pages/Services';
import Kyc from './pages/Kyc';
import Workers from './pages/Workers';
import Support from './pages/Support';
import Notifications from './pages/Notifications';
import Roles from './pages/Roles';
import Banners from './pages/Banners';
import Payments from './pages/Payments';
import Reviews from './pages/Reviews';
import Locations from './pages/Locations';
import Settings from './pages/Settings';
import { bookingsAPI } from './api';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

/* ── New Booking Toast Popup ── */
function NewBookingToast({ bookings, onDismiss, onViewBookings }) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (bookings.length > 0) {
      setVisible(true);
    }
  }, [bookings]);

  const handleDismiss = () => {
    setVisible(false);
    setTimeout(onDismiss, 300);
  };

  const handleView = () => {
    setVisible(false);
    setTimeout(() => { onDismiss(); onViewBookings(); }, 300);
  };

  if (bookings.length === 0) return null;

  const latest = bookings[0];

  return (
    <div style={{
      position: 'fixed', top: 20, right: 20, zIndex: 9999,
      transform: visible ? 'translateX(0)' : 'translateX(120%)',
      transition: 'transform 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)',
      maxWidth: 340, width: '100%',
    }}>
      <div style={{
        background: 'var(--bg-card)',
        borderRadius: 16,
        boxShadow: '0 8px 40px rgba(181, 154, 87, 0.12), 0 12px 30px rgba(0,0,0,0.06)',
        border: '1px solid var(--border-color)',
        overflow: 'hidden',
      }}>
        {/* Header bar - charcoal black background with gold border line */}
        <div style={{
          background: 'linear-gradient(135deg, #1A1A1A, #121212)',
          padding: '12px 16px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          borderBottom: '2px solid var(--accent-color)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8,
              background: 'rgba(181, 154, 87, 0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 16,
            }}>📋</div>
            <div>
              <div style={{ color: '#fff', fontWeight: 700, fontSize: 13 }}>
                {bookings.length > 1 ? `${bookings.length} New Bookings!` : 'New Booking Received!'}
              </div>
              <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 11 }}>Just now</div>
            </div>
          </div>
          <button
            onClick={handleDismiss}
            style={{
              background: 'rgba(255,255,255,0.1)', border: 'none', color: '#fff',
              borderRadius: 6, width: 26, height: 26, cursor: 'pointer',
              fontSize: 14, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >✕</button>
        </div>
        {/* Body */}
        <div style={{ padding: '14px 16px' }}>
          <div style={{ fontSize: 13, color: 'var(--text-primary)', fontWeight: 600, marginBottom: 4 }}>
            {latest.user_name || latest.name || 'A user'} booked a service
          </div>
          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 12 }}>
            {latest.service_type || latest.service || 'Service'} · ₹{Number(latest.amount || 0).toLocaleString()}
          </div>
          {bookings.length > 1 && (
            <div style={{
              background: 'var(--accent-light)', borderRadius: 8, padding: '6px 10px',
              fontSize: 11, color: 'var(--accent-dark)', marginBottom: 12,
              border: '1px solid var(--accent-border)',
            }}>
              +{bookings.length - 1} more new booking{bookings.length > 2 ? 's' : ''} waiting
            </div>
          )}
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              onClick={handleView}
              style={{
                flex: 1, background: 'var(--accent-color)', color: '#fff', border: 'none',
                borderRadius: 8, padding: '8px 12px', cursor: 'pointer',
                fontSize: 12, fontWeight: 600, transition: 'background 0.2s',
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = 'var(--accent-dark)'}
              onMouseLeave={(e) => e.currentTarget.style.background = 'var(--accent-color)'}
            >View Bookings</button>
            <button
              onClick={handleDismiss}
              style={{
                background: 'var(--bg-muted)', color: 'var(--text-primary)', border: 'none',
                borderRadius: 8, padding: '8px 14px', cursor: 'pointer',
                fontSize: 12, fontWeight: 600,
              }}
            >Dismiss</button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  const [token, setToken] = useState(() => localStorage.getItem('admin_token'));
  const [newBookings, setNewBookings] = useState([]);
  const lastSeenIdRef = useRef(null);
  const pollingRef = useRef(null);
  const navigate = useNavigate();

  // Poll for new bookings every 30 seconds
  useEffect(() => {
    if (!token) return;

    const checkForNewBookings = async () => {
      try {
        const res = await bookingsAPI.getAll({ status: 'pending', limit: 10 });
        const rows = res?.data?.rows || res?.rows || [];
        if (rows.length === 0) return;

        const latestId = rows[0]?.id;

        // First run — just remember the last known ID, don't alert
        if (lastSeenIdRef.current === null) {
          lastSeenIdRef.current = latestId;
          return;
        }

        // Find bookings newer than last seen
        const fresh = rows.filter(b => b.id > lastSeenIdRef.current);
        if (fresh.length > 0) {
          lastSeenIdRef.current = latestId;
          setNewBookings(fresh);
        }
      } catch (_) {
        // silently ignore polling errors
      }
    };

    // Initial check after 3 seconds
    const initialTimeout = setTimeout(checkForNewBookings, 3000);
    // Then poll every 30 seconds
    pollingRef.current = setInterval(checkForNewBookings, 30000);

    return () => {
      clearTimeout(initialTimeout);
      clearInterval(pollingRef.current);
    };
  }, [token]);

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    setToken(null);
    navigate('/login');
  };

  if (!token) {
    return (
      <Routes>
        <Route
          path="/login"
          element={
            <Login
              onLoginSuccess={(newToken) => {
                localStorage.setItem('admin_token', newToken);
                setToken(newToken);
                navigate('/');
              }}
            />
          }
        />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-app)', color: 'var(--text-primary)' }}>
      <Sidebar onLogout={handleLogout} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Topbar />
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/dashboard" element={<Navigate to="/" replace />} />
          <Route path="/users" element={<Users />} />
          <Route path="/workers" element={<Workers />} />
          <Route path="/kyc" element={<Kyc />} />
          <Route path="/bookings" element={<Bookings />} />
          <Route path="/invoices" element={<Invoices />} />
          <Route path="/payments" element={<Payments />} />
          <Route path="/reviews" element={<Reviews />} />
          <Route path="/support" element={<Support />} />
          <Route path="/services" element={<Services />} />
          <Route path="/banners" element={<Banners />} />
          <Route path="/notifications" element={<Notifications />} />
          <Route path="/roles" element={<Roles />} />
          <Route path="/locations" element={<Locations />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/login" element={<Navigate to="/" replace />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>

      {/* New Booking Popup Toast */}
      {newBookings.length > 0 && (
        <NewBookingToast
          bookings={newBookings}
          onDismiss={() => setNewBookings([])}
          onViewBookings={() => navigate('/bookings')}
        />
      )}

      {/* Global Toast Container */}
      <ToastContainer
        position="top-right"
        autoClose={3500}
        hideProgressBar={false}
        newestOnTop
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="dark"
      />
    </div>
  );
}


