import { useState } from 'react';
import Sidebar from './components/Sidebar';
import Topbar from './components/Topbar';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Invoices from './pages/Invoices';
import Bookings from './pages/Bookings';
import Workers from './pages/Workers';
import Support from './pages/Support';
import Locations from './pages/Locations';

export default function App() {
  const [token, setToken] = useState(() => localStorage.getItem('admin_token'));
  const [activePage, setActivePage] = useState('dashboard');

  if (!token) {
    return (
      <Login
        onLoginSuccess={(newToken) => {
          localStorage.setItem('admin_token', newToken);
          setToken(newToken);
          // If the user was on /login, clean the address bar to /
          if (window.location.pathname === '/login') {
            window.history.pushState({}, '', '/');
          }
        }}
      />
    );
  }

  function renderPage() {
    switch (activePage) {
      case 'dashboard':
        return <Dashboard />;
      case 'invoices':
        return <Invoices />;
      case 'bookings':
        return <Bookings />;
      case 'workers':
        return <Workers />;
      case 'support':
        return <Support />;
      case 'locations':
        return <Locations />;
      default:
        return (
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'DM Sans, system-ui, sans-serif', color: '#9CA3AF', fontSize: 14 }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 40, marginBottom: 12 }}>🚧</div>
              <div style={{ fontWeight: 600, color: '#374151', marginBottom: 4 }}>Page coming soon</div>
              <div>"{activePage}" module not built yet</div>
            </div>
          </div>
        );
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    setToken(null);
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#F9FAFB' }}>
      <Sidebar activeKey={activePage} onNav={setActivePage} onLogout={handleLogout} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Topbar activePage={activePage} />
        {renderPage()}
      </div>
    </div>
  );
}