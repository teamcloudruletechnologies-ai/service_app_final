import { useState } from 'react';

const TABS = [
  { key: 'general', label: '⚙️ General', icon: '⚙️' },
  { key: 'payments', label: '💳 Payments', icon: '💳' },
  { key: 'notifications', label: '🔔 Notifications', icon: '🔔' },
  { key: 'security', label: '🔐 Security', icon: '🔐' },
];

function SettingRow({ label, desc, children }) {
  return (
    <div style={{ padding: '18px 0', borderBottom: '1px solid var(--bg-muted)', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 24 }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontWeight: 600, fontSize: 13, color: 'var(--text-primary)', marginBottom: 2 }}>{label}</div>
        {desc && <div style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5 }}>{desc}</div>}
      </div>
      <div style={{ flexShrink: 0 }}>{children}</div>
    </div>
  );
}

function Toggle({ value, onChange }) {
  return (
    <button
      onClick={() => onChange(!value)}
      style={{
        width: 44, height: 24, borderRadius: 12, border: 'none', cursor: 'pointer',
        background: value ? 'var(--accent-color)' : '#D1D5DB',
        position: 'relative', transition: 'background 0.2s',
        padding: 0,
      }}
    >
      <div style={{
        width: 18, height: 18, borderRadius: '50%', background: 'var(--bg-card)',
        position: 'absolute', top: 3, transition: 'left 0.2s',
        left: value ? 23 : 3,
        boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
      }} />
    </button>
  );
}

function FormInput({ value, onChange, type = 'text', placeholder = '' }) {
  return (
    <input
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      style={{
        padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8,
        fontSize: 13, outline: 'none', fontFamily: 'inherit', width: 260, boxSizing: 'border-box',
        transition: 'border-color 0.15s',
      }}
      onFocus={(e) => e.target.style.borderColor = 'var(--accent-color)'}
      onBlur={(e) => e.target.style.borderColor = '#D1D5DB'}
    />
  );
}

function SaveButton({ saving, onClick, label = 'Save Changes' }) {
  return (
    <button
      onClick={onClick}
      disabled={saving}
      style={{
        background: saving ? 'var(--accent-border)' : 'var(--accent-color)',
        border: 'none', borderRadius: 8, color: 'var(--bg-card)',
        padding: '10px 24px', fontSize: 13, fontWeight: 600,
        cursor: saving ? 'not-allowed' : 'pointer',
        boxShadow: '0 4px 12px rgba(26, 86, 219, 0.2)',
        transition: 'all 0.15s',
        display: 'flex', alignItems: 'center', gap: 8,
      }}
    >
      {saving ? (
        <>
          <span style={{ display: 'inline-block', width: 14, height: 14, border: '2px solid rgba(255,255,255,0.4)', borderTop: '2px solid var(--bg-card)', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
          Saving...
        </>
      ) : `💾 ${label}`}
    </button>
  );
}

export default function Settings() {
  const [activeTab, setActiveTab] = useState('general');
  const [saved, setSaved] = useState('');
  const [saving, setSaving] = useState(false);

  // General Settings
  const [appName, setAppName] = useState('UrbanServe');
  const [commission, setCommission] = useState(10);
  const [supportPhone, setSupportPhone] = useState('+91 98765 43210');
  const [supportEmail, setSupportEmail] = useState('support@urbanserve.in');
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [autoAssign, setAutoAssign] = useState(true);

  // Payment Settings
  const [razorpayKeyId, setRazorpayKeyId] = useState('rzp_test_ScvkOVs9j85AoG');
  const [razorpaySecret, setRazorpaySecret] = useState('nCsjp8egns3TH9uzlLs17QGa');
  const [currency, setCurrency] = useState('INR');
  const [minBookingAmt, setMinBookingAmt] = useState(99);
  const [razorpayMode, setRazorpayMode] = useState('test');

  // Notification Settings
  const [fcmKey, setFcmKey] = useState('AAAAd4p-8N0:APA91bF9f...');
  const [smsProvider, setSmsProvider] = useState('msg91');
  const [smsApiKey, setSmsApiKey] = useState('');
  const [bookingAlerts, setBookingAlerts] = useState(true);
  const [paymentAlerts, setPaymentAlerts] = useState(true);
  const [kycAlerts, setKycAlerts] = useState(true);

  // Security Settings
  const [jwtExpiry, setJwtExpiry] = useState('7d');
  const [maxLoginAttempts, setMaxLoginAttempts] = useState(5);
  const [twoFactor, setTwoFactor] = useState(false);
  const [ipWhitelist, setIpWhitelist] = useState('');

  const handleSave = (section) => {
    setSaving(true);
    setSaved('');
    setTimeout(() => {
      setSaving(false);
      setSaved(section);
      setTimeout(() => setSaved(''), 3000);
    }, 1000);
  };

  const tabStyle = (key) => ({
    padding: '10px 18px', border: 'none', cursor: 'pointer',
    fontSize: 13, fontWeight: 600, borderRadius: 8,
    background: activeTab === key ? 'var(--accent-light)' : 'transparent',
    color: activeTab === key ? 'var(--accent-color)' : 'var(--text-secondary)',
    transition: 'all 0.15s',
  });

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '24px 28px', background: 'var(--bg-app)', fontFamily: "'DM Sans', system-ui, sans-serif" }}>
      <style>{`
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes slideIn { from { opacity: 0; x: -10px; } to { opacity: 1; x: 0; } }
      `}</style>

      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)', margin: 0 }}>System Settings</h2>
        <p style={{ fontSize: 12, color: 'var(--text-secondary)', margin: '4px 0 0' }}>
          Configure global platform settings, notification gateways, and payment integrations.
        </p>
      </div>

      {/* Success Banner */}
      {saved && (
        <div style={{
          background: 'var(--status-green-bg)', border: '1px solid #6EE7B7', color: 'var(--status-green-fg)',
          padding: '10px 16px', borderRadius: 8, marginBottom: 16,
          fontSize: 13, fontWeight: 500, display: 'flex', alignItems: 'center', gap: 8,
          animation: 'fadeIn 0.2s ease-out',
        }}>
          ✅ {saved} settings saved successfully!
        </div>
      )}

      <div style={{ display: 'flex', gap: 24, alignItems: 'flex-start' }}>

        {/* Sidebar Tabs */}
        <div style={{ background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, padding: 12, minWidth: 200, flexShrink: 0, boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
          {TABS.map(tab => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              style={tabStyle(tab.key)}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, whiteSpace: 'nowrap' }}>
                <span>{tab.icon}</span>
                <span>{tab.label.split(' ').slice(1).join(' ')}</span>
              </div>
            </button>
          ))}
        </div>

        {/* Content Panel */}
        <div style={{ flex: 1, background: 'var(--bg-card)', border: '0.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>

          {/* Tab Header */}
          <div style={{ padding: '16px 24px', borderBottom: '1px solid var(--border-color)', background: 'linear-gradient(to right, var(--bg-app), var(--bg-card))' }}>
            <div style={{ fontWeight: 700, fontSize: 15, color: 'var(--text-primary)' }}>
              {TABS.find(t => t.key === activeTab)?.label}
            </div>
            <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>
              {activeTab === 'general' && 'Application-wide configuration and operational preferences'}
              {activeTab === 'payments' && 'Razorpay gateway credentials and billing configuration'}
              {activeTab === 'notifications' && 'FCM push notifications and SMS OTP service configuration'}
              {activeTab === 'security' && 'Authentication, access controls and security settings'}
            </div>
          </div>

          <div style={{ padding: '0 24px 24px' }}>

            {/* ─── GENERAL TAB ─── */}
            {activeTab === 'general' && (
              <div style={{ animation: 'fadeIn 0.2s ease-out' }}>
                <SettingRow label="Application Name" desc="The name displayed in the app header and notifications.">
                  <FormInput value={appName} onChange={setAppName} placeholder="UrbanServe" />
                </SettingRow>
                <SettingRow label="Platform Commission %" desc="Percentage fee deducted from each completed service. Remaining 90% goes to workers.">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <input
                      type="number" min="1" max="50" value={commission}
                      onChange={(e) => setCommission(e.target.value)}
                      style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, width: 80, outline: 'none' }}
                    />
                    <span style={{ color: 'var(--text-secondary)', fontSize: 13 }}>%</span>
                  </div>
                </SettingRow>
                <SettingRow label="Support Phone" desc="Contact number shown to users for customer support.">
                  <FormInput value={supportPhone} onChange={setSupportPhone} placeholder="+91 98765 43210" />
                </SettingRow>
                <SettingRow label="Support Email" desc="Email address for platform support queries.">
                  <FormInput type="email" value={supportEmail} onChange={setSupportEmail} placeholder="support@urbanserve.in" />
                </SettingRow>
                <SettingRow label="Auto-Assign Workers" desc="Automatically assign nearest available worker to new bookings.">
                  <Toggle value={autoAssign} onChange={setAutoAssign} />
                </SettingRow>
                <SettingRow label="Maintenance Mode" desc="Temporarily disable the app for all users during maintenance.">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Toggle value={maintenanceMode} onChange={setMaintenanceMode} />
                    {maintenanceMode && (
                      <span style={{ fontSize: 11, color: 'var(--status-red-fg)', fontWeight: 600, background: 'var(--status-red-bg)', padding: '2px 8px', borderRadius: 6 }}>
                        ⚠️ ACTIVE
                      </span>
                    )}
                  </div>
                </SettingRow>
                <div style={{ paddingTop: 20, display: 'flex', justifyContent: 'flex-end' }}>
                  <SaveButton saving={saving} onClick={() => handleSave('General')} />
                </div>
              </div>
            )}

            {/* ─── PAYMENTS TAB ─── */}
            {activeTab === 'payments' && (
              <div style={{ animation: 'fadeIn 0.2s ease-out' }}>
                <div style={{ background: 'var(--status-amber-bg)', border: '1px solid #FDE68A', borderRadius: 8, padding: '10px 14px', marginTop: 16, marginBottom: 4, fontSize: 12, color: 'var(--status-amber-fg)' }}>
                  ⚠️ <strong>Important:</strong> These credentials are used for live payment processing. Handle with care.
                </div>
                <SettingRow label="Gateway Mode" desc="Select test mode for development, live mode for production.">
                  <select
                    value={razorpayMode}
                    onChange={(e) => setRazorpayMode(e.target.value)}
                    style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', background: 'var(--bg-card)', fontFamily: 'inherit' }}
                  >
                    <option value="test">🧪 Test Mode</option>
                    <option value="live">🚀 Live Mode</option>
                  </select>
                </SettingRow>
                <SettingRow label="Razorpay Key ID" desc="Your Razorpay Key ID from the dashboard (starts with rzp_).">
                  <FormInput value={razorpayKeyId} onChange={setRazorpayKeyId} placeholder="rzp_test_..." />
                </SettingRow>
                <SettingRow label="Razorpay Key Secret" desc="Your Razorpay Key Secret. Never share this publicly.">
                  <FormInput type="password" value={razorpaySecret} onChange={setRazorpaySecret} placeholder="••••••••••••••" />
                </SettingRow>
                <SettingRow label="Currency" desc="Default billing currency for all transactions.">
                  <select
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value)}
                    style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', background: 'var(--bg-card)', fontFamily: 'inherit' }}
                  >
                    <option value="INR">🇮🇳 INR — Indian Rupee</option>
                    <option value="USD">🇺🇸 USD — US Dollar</option>
                  </select>
                </SettingRow>
                <SettingRow label="Minimum Booking Amount" desc="Minimum payment required to confirm a booking (in ₹).">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: 'var(--text-secondary)', fontSize: 13 }}>₹</span>
                    <input
                      type="number" min="1" value={minBookingAmt}
                      onChange={(e) => setMinBookingAmt(e.target.value)}
                      style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, width: 100, outline: 'none' }}
                    />
                  </div>
                </SettingRow>
                <div style={{ paddingTop: 20, display: 'flex', justifyContent: 'flex-end' }}>
                  <SaveButton saving={saving} onClick={() => handleSave('Payment')} />
                </div>
              </div>
            )}

            {/* ─── NOTIFICATIONS TAB ─── */}
            {activeTab === 'notifications' && (
              <div style={{ animation: 'fadeIn 0.2s ease-out' }}>
                <SettingRow label="Firebase Cloud Messaging (FCM) Server Key" desc="Used to send push notifications to mobile apps.">
                  <FormInput value={fcmKey} onChange={setFcmKey} placeholder="AAAA..." />
                </SettingRow>
                <SettingRow label="SMS / OTP Provider" desc="Select the service used for SMS verification codes.">
                  <select
                    value={smsProvider}
                    onChange={(e) => setSmsProvider(e.target.value)}
                    style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', background: 'var(--bg-card)', fontFamily: 'inherit' }}
                  >
                    <option value="msg91">MSG91 OTP Service</option>
                    <option value="twilio">Twilio SMS Gateway</option>
                    <option value="firebase">Firebase SMS Auth</option>
                  </select>
                </SettingRow>
                <SettingRow label="SMS API Key" desc="API key for the selected SMS provider.">
                  <FormInput value={smsApiKey} onChange={setSmsApiKey} placeholder="Enter API key..." />
                </SettingRow>
                <SettingRow label="Booking Alerts" desc="Send push notification to admin when a new booking is created.">
                  <Toggle value={bookingAlerts} onChange={setBookingAlerts} />
                </SettingRow>
                <SettingRow label="Payment Alerts" desc="Notify admin when a payment is made or fails.">
                  <Toggle value={paymentAlerts} onChange={setPaymentAlerts} />
                </SettingRow>
                <SettingRow label="KYC Verification Alerts" desc="Notify admin on new KYC submissions requiring review.">
                  <Toggle value={kycAlerts} onChange={setKycAlerts} />
                </SettingRow>
                <div style={{ paddingTop: 20, display: 'flex', justifyContent: 'flex-end' }}>
                  <SaveButton saving={saving} onClick={() => handleSave('Notification')} />
                </div>
              </div>
            )}

            {/* ─── SECURITY TAB ─── */}
            {activeTab === 'security' && (
              <div style={{ animation: 'fadeIn 0.2s ease-out' }}>
                <SettingRow label="JWT Token Expiry" desc="Duration before admin tokens expire. Shorter = more secure.">
                  <select
                    value={jwtExpiry}
                    onChange={(e) => setJwtExpiry(e.target.value)}
                    style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, outline: 'none', background: 'var(--bg-card)', fontFamily: 'inherit' }}
                  >
                    <option value="1d">1 Day</option>
                    <option value="7d">7 Days (Default)</option>
                    <option value="30d">30 Days</option>
                    <option value="90d">90 Days</option>
                  </select>
                </SettingRow>
                <SettingRow label="Max Login Attempts" desc="Lock accounts after this many consecutive failed login attempts.">
                  <input
                    type="number" min="3" max="20" value={maxLoginAttempts}
                    onChange={(e) => setMaxLoginAttempts(e.target.value)}
                    style={{ padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 13, width: 80, outline: 'none' }}
                  />
                </SettingRow>
                <SettingRow label="Two-Factor Authentication" desc="Require OTP verification for all admin logins.">
                  <Toggle value={twoFactor} onChange={setTwoFactor} />
                </SettingRow>
                <SettingRow label="IP Allowlist" desc="Restrict admin access to specific IP addresses (comma-separated). Leave empty to allow all.">
                  <textarea
                    value={ipWhitelist}
                    onChange={(e) => setIpWhitelist(e.target.value)}
                    placeholder="192.168.1.1, 10.0.0.0/8"
                    rows={3}
                    style={{ width: 280, padding: '8px 12px', border: '1px solid #D1D5DB', borderRadius: 8, fontSize: 12, outline: 'none', fontFamily: 'monospace', resize: 'vertical', boxSizing: 'border-box' }}
                  />
                </SettingRow>
                <div style={{ paddingTop: 20, display: 'flex', justifyContent: 'flex-end' }}>
                  <SaveButton saving={saving} onClick={() => handleSave('Security')} />
                </div>
              </div>
            )}

          </div>
        </div>
      </div>
    </div>
  );
}
