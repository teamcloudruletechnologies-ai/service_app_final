import { useState } from 'react';
import { authAPI } from '../api';

function IconMail() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="4" width="20" height="16" rx="2" />
      <path d="M2 7l10 7 10-7" />
    </svg>
  );
}

function IconLock() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="11" width="18" height="11" rx="2" />
      <path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}

function IconEye({ open }) {
  return open ? (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  ) : (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
      <line x1="1" y1="1" x2="23" y2="23" />
    </svg>
  );
}

function IconArrow() {
  return (
    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="5" y1="12" x2="19" y2="12" />
      <polyline points="12 5 19 12 12 19" />
    </svg>
  );
}

export default function Login({ onLoginSuccess }) {
  const [email, setEmail]               = useState('');
  const [password, setPassword]         = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading]           = useState(false);
  const [error, setError]               = useState('');
  const [focusedField, setFocusedField] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      const response = await authAPI.login(email.trim(), password);
      if (response && response.success && response.data?.token) {
        onLoginSuccess(response.data.token);
      } else {
        setError('Invalid credentials. Please try again.');
      }
    } catch (err) {
      setError(err?.message || 'Unable to connect. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const inputStyle = (field) => ({
    width: '100%',
    boxSizing: 'border-box',
    paddingLeft: 42,
    paddingRight: field === 'password' ? 42 : 14,
    paddingTop: 13,
    paddingBottom: 13,
    background: '#FAFAF9',
    border: `1.5px solid ${focusedField === field ? '#1C1917' : '#E7E2DA'}`,
    borderRadius: 12,
    fontSize: 14,
    color: '#1C1917',
    outline: 'none',
    fontFamily: "'DM Sans', system-ui, sans-serif",
    transition: 'border-color 0.2s, box-shadow 0.2s',
    boxShadow: focusedField === field ? '0 0 0 3px rgba(28,25,23,0.07)' : 'none',
  });

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(145deg, #F5EDE0 0%, #FAF7F0 40%, #EFE5D4 100%)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: "'DM Sans', system-ui, sans-serif",
      padding: '40px 20px',
      position: 'relative',
    }}>

      {/* Soft background blobs */}
      <div style={{
        position: 'absolute', top: '10%', left: '5%', width: 300, height: 300,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(181,154,87,0.08) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'absolute', bottom: '10%', right: '5%', width: 250, height: 250,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(181,154,87,0.06) 0%, transparent 70%)',
        pointerEvents: 'none',
      }} />

      {/* Centered Card */}
      <div style={{
        width: '100%',
        maxWidth: 440,
        background: '#FFFFFF',
        borderRadius: 24,
        padding: '44px 40px 36px',
        boxShadow: '0 8px 48px rgba(120,100,60,0.10), 0 2px 8px rgba(120,100,60,0.06)',
        border: '1px solid rgba(181,154,87,0.12)',
        position: 'relative',
        zIndex: 1,
      }}>

        {/* Logo */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 24 }}>
          <div style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'linear-gradient(135deg, #2C2921 0%, #1C1917 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            marginBottom: 12,
            boxShadow: '0 4px 20px rgba(28,25,23,0.20)',
          }}>
            <svg width="28" height="28" viewBox="0 0 32 32" fill="none">
              <path d="M16 7L24 13.5V23.5H8V13.5L16 7Z" fill="#B59A57" fillOpacity="0.3" />
              <path d="M16 7L24 13.5M16 7L8 13.5" stroke="#B59A57" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M12 18L15 21L21 14" stroke="#FAF7F0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div style={{ fontSize: 17, fontWeight: 700, color: '#1C1917', letterSpacing: '-0.02em', lineHeight: 1 }}>
            UrbanServe
          </div>
        </div>

        {/* Admin portal pill */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 20 }}>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            background: '#FAF7F0',
            border: '1px solid #EBE5D8',
            borderRadius: 999, padding: '5px 14px',
          }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#B59A57" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            <span style={{
              fontSize: 10, fontWeight: 700, color: '#9A7E3F',
              letterSpacing: '0.12em', textTransform: 'uppercase',
            }}>
              Admin Portal
            </span>
          </div>
        </div>

        {/* Heading */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <h1 style={{
            fontSize: 26, fontWeight: 800, color: '#1C1917',
            letterSpacing: '-0.03em', margin: '0 0 8px',
            lineHeight: 1.2,
          }}>
            Welcome to UrbanServe
          </h1>
          <p style={{ fontSize: 13, color: '#78716C', margin: 0, lineHeight: 1.5 }}>
            Sign in to your admin control center
          </p>
        </div>

        {/* Error banner */}
        {error && (
          <div style={{
            marginBottom: 18, padding: '11px 14px',
            background: '#FEF2F2', border: '1px solid #FECACA',
            borderRadius: 10, display: 'flex', alignItems: 'center', gap: 9,
            fontSize: 12, color: '#B91C1C', fontWeight: 500,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#DC2626" strokeWidth="2.5" strokeLinecap="round">
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>

          {/* Email */}
          <div>
            <label style={{
              display: 'block', fontSize: 11, fontWeight: 700,
              color: '#1C1917', letterSpacing: '0.08em',
              textTransform: 'uppercase', marginBottom: 8,
            }}>
              Email Address
            </label>
            <div style={{ position: 'relative' }}>
              <span style={{
                position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
                color: '#A8A29E', display: 'flex', alignItems: 'center', pointerEvents: 'none',
              }}>
                <IconMail />
              </span>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onFocus={() => setFocusedField('email')}
                onBlur={() => setFocusedField(null)}
                placeholder="name@example.com"
                disabled={loading}
                style={inputStyle('email')}
              />
            </div>
          </div>

          {/* Password */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <label style={{
                fontSize: 11, fontWeight: 700, color: '#1C1917',
                letterSpacing: '0.08em', textTransform: 'uppercase',
              }}>
                Password
              </label>
              <a
                href="#"
                style={{ fontSize: 11, color: '#9A7E3F', fontWeight: 600, textDecoration: 'none' }}
                onMouseEnter={(e) => e.target.style.color = '#B59A57'}
                onMouseLeave={(e) => e.target.style.color = '#9A7E3F'}
              >
                Forgot password?
              </a>
            </div>
            <div style={{ position: 'relative' }}>
              <span style={{
                position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
                color: '#A8A29E', display: 'flex', alignItems: 'center', pointerEvents: 'none',
              }}>
                <IconLock />
              </span>
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onFocus={() => setFocusedField('password')}
                onBlur={() => setFocusedField(null)}
                placeholder="Enter your password"
                disabled={loading}
                style={inputStyle('password')}
              />
              <button
                type="button"
                tabIndex="-1"
                onClick={() => setShowPassword(!showPassword)}
                style={{
                  position: 'absolute', right: 13, top: '50%', transform: 'translateY(-50%)',
                  background: 'none', border: 'none', cursor: 'pointer',
                  color: '#A8A29E', display: 'flex', alignItems: 'center',
                  padding: 4, borderRadius: 6, transition: 'color 0.15s',
                }}
                onMouseEnter={(e) => e.currentTarget.style.color = '#1C1917'}
                onMouseLeave={(e) => e.currentTarget.style.color = '#A8A29E'}
              >
                <IconEye open={showPassword} />
              </button>
            </div>
          </div>

          {/* Submit button */}
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%', padding: '14px 20px', marginTop: 4,
              background: '#1C1917', color: '#FAF7F0',
              border: 'none', borderRadius: 12,
              fontSize: 14, fontWeight: 700, letterSpacing: '0.02em',
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontFamily: 'inherit', opacity: loading ? 0.72 : 1,
              transition: 'all 0.2s ease',
              boxShadow: '0 4px 16px rgba(28,25,23,0.22)',
            }}
            onMouseEnter={(e) => {
              if (!loading) {
                e.currentTarget.style.background = '#2C2921';
                e.currentTarget.style.transform = 'translateY(-1px)';
                e.currentTarget.style.boxShadow = '0 6px 24px rgba(28,25,23,0.30)';
              }
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = '#1C1917';
              e.currentTarget.style.transform = 'none';
              e.currentTarget.style.boxShadow = '0 4px 16px rgba(28,25,23,0.22)';
            }}
          >
            {loading ? (
              <>
                <svg style={{ animation: 'spin 1s linear infinite' }} width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="rgba(250,247,240,0.25)" strokeWidth="3" />
                  <path d="M12 2a10 10 0 0 1 10 10" stroke="#FAF7F0" strokeWidth="3" strokeLinecap="round" />
                </svg>
                Signing in...
              </>
            ) : (
              <>
                Sign In to Dashboard
                <IconArrow />
              </>
            )}
          </button>
        </form>
      </div>

      {/* Footer */}
      <div style={{ marginTop: 28, textAlign: 'center' }}>
        <p style={{ fontSize: 12, color: '#A8A29E', margin: 0 }}>
          &copy; {new Date().getFullYear()} UrbanServe. All rights reserved.
        </p>
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to   { transform: rotate(360deg); }
        }
        input::placeholder { color: #C4B9AB; }
      `}</style>
    </div>
  );
}
