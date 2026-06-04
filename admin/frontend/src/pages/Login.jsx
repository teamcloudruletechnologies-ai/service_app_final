import { useState } from 'react';
import { authAPI } from '../api';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

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
        setError('Login failed. Invalid response structure.');
      }
    } catch (err) {
      console.error('Login error:', err);
      // backend returns error response like: { success: false, message: "Invalid credentials" }
      const errMsg = err?.message || 'Unable to connect to the server. Please try again.';
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center bg-[#0B0F19] overflow-hidden font-sans">
      {/* Decorative ambient background glows */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[60%] rounded-full bg-blue-600/10 blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[60%] rounded-full bg-purple-600/10 blur-[120px] pointer-events-none" />

      {/* Grid Pattern overlay */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#1f29370a_1px,transparent_1px),linear-gradient(to_bottom,#1f29370a_1px,transparent_1px)] bg-[size:24px_24px] pointer-events-none opacity-20" />

      {/* Glass Login Card */}
      <div className="relative w-full max-w-md mx-4 p-8 bg-[#161D30]/80 backdrop-blur-xl border border-gray-800/80 rounded-2xl shadow-2xl transition-all duration-300">
        
        {/* Header & Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center mb-4 transition-transform hover:scale-105 duration-300">
            <svg width="48" height="48" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" className="shadow-lg shadow-blue-500/20 rounded-xl">
              <defs>
                <linearGradient id="logoGradLogin" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#2563EB" />
                  <stop offset="100%" stopColor="#3B82F6" />
                </linearGradient>
              </defs>
              <rect width="32" height="32" rx="8" fill="url(#logoGradLogin)" />
              <path d="M16 7L24 13.5V23.5H8V13.5L16 7Z" fill="white" fillOpacity="0.2" />
              <path d="M16 7L24 13.5M16 7L8 13.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M12 18L15 21L21 14" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">UrbanServe</h1>
          <p className="text-sm text-gray-400 mt-1">Super Admin Panel Control Center</p>
        </div>

        {/* Error Alert Banner */}
        {error && (
          <div className="mb-5 p-3.5 bg-red-950/40 border border-red-500/30 rounded-xl flex items-start gap-2.5 text-sm text-red-300 animate-shake">
            <span className="text-base leading-none">⚠️</span>
            <span className="flex-1">{error}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
              Email Address
            </label>
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-500 text-sm">📧</span>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@urbanserve.com"
                disabled={loading}
                className="w-full pl-10 pr-4 py-3 bg-[#0E1322]/80 border border-gray-800 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 text-gray-100 rounded-xl text-sm outline-none transition-all placeholder:text-gray-600 disabled:opacity-50"
              />
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider">
                Password
              </label>
              <a href="#" className="text-xs text-blue-400 hover:text-blue-300 transition-colors">
                Forgot password?
              </a>
            </div>
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-500 text-sm">🔐</span>
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                disabled={loading}
                className="w-full pl-10 pr-12 py-3 bg-[#0E1322]/80 border border-gray-800 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 text-gray-100 rounded-xl text-sm outline-none transition-all placeholder:text-gray-600 disabled:opacity-50"
              />
              <button
                type="button"
                tabIndex="-1"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300 text-sm p-1 rounded transition-colors focus:outline-none"
              >
                {showPassword ? '👁️' : '🙈'}
              </button>
            </div>
          </div>

          <div className="flex items-center">
            <input
              id="remember_me"
              type="checkbox"
              className="w-4 h-4 rounded border-gray-800 bg-[#0E1322]/80 text-blue-600 focus:ring-blue-500/20"
            />
            <label htmlFor="remember_me" className="ml-2.5 text-xs text-gray-400 select-none">
              Keep me logged in for 7 days
            </label>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={loading}
            className="relative w-full py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-semibold rounded-xl text-sm transition-all focus:outline-none focus:ring-2 focus:ring-indigo-500/50 active:scale-[0.99] disabled:opacity-75 disabled:pointer-events-none cursor-pointer flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/25"
          >
            {loading ? (
              <>
                <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>Verifying credentials...</span>
              </>
            ) : (
              <span>Sign In to Dashboard</span>
            )}
          </button>
        </form>

        {/* Card footer details */}
        <div className="mt-8 text-center border-t border-gray-800/60 pt-6">
          <p className="text-xs text-gray-500">
            For security purposes, all sessions are monitored and logged. By signing in, you agree to our Terms of Use.
          </p>
        </div>
      </div>
      
      {/* Keyframe animation injected inline */}
      <style>{`
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-4px); }
          75% { transform: translateX(4px); }
        }
        .animate-shake {
          animation: shake 0.2s ease-in-out 2;
        }
      `}</style>
    </div>
  );
}
