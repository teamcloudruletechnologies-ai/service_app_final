import { useEffect } from 'react';

export default function ConfirmModal({
  isOpen,
  title = 'Confirm Action',
  message = 'Are you sure you want to proceed?',
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  variant = 'danger', // 'danger' | 'warning' | 'info'
  loading = false,
  onConfirm,
  onClose,
}) {
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && isOpen && !loading) {
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, loading, onClose]);

  if (!isOpen) return null;

  const isDanger = variant === 'danger';
  const isWarning = variant === 'warning';

  const iconBg = isDanger ? '#FEF2F2' : isWarning ? '#FFFBEB' : '#F0F4EF';
  const iconFg = isDanger ? '#DC2626' : isWarning ? '#D97706' : '#4A5343';
  const confirmBg = isDanger ? '#DC2626' : isWarning ? '#D97706' : '#4A5343';
  const confirmHoverBg = isDanger ? '#B91C1C' : isWarning ? '#B45309' : '#373E32';

  return (
    <div
      onClick={() => !loading && onClose()}
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0, 0, 0, 0.65)',
        backdropFilter: 'blur(4px)',
        zIndex: 99999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 16,
        animation: 'fadeIn 0.2s ease-out forwards',
        fontFamily: "'DM Sans', system-ui, sans-serif",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          width: '100%',
          maxWidth: 440,
          background: 'var(--bg-card, #FFFFFF)',
          borderRadius: 20,
          border: '1px solid var(--border-color, #E5E7EB)',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.25), 0 10px 20px rgba(0, 0, 0, 0.15)',
          overflow: 'hidden',
          animation: 'scaleUp 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards',
        }}
      >
        <style>{`
          @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
          }
          @keyframes scaleUp {
            from { opacity: 0; transform: scale(0.92) translateY(10px); }
            to { opacity: 1; transform: scale(1) translateY(0); }
          }
        `}</style>

        {/* Content Box */}
        <div style={{ padding: '24px 24px 20px' }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16 }}>
            {/* Icon */}
            <div
              style={{
                width: 44,
                height: 44,
                borderRadius: 14,
                backgroundColor: iconBg,
                color: iconFg,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 22,
                flexShrink: 0,
              }}
            >
              {isDanger ? '⚠️' : isWarning ? '🔔' : 'ℹ️'}
            </div>

            {/* Text details */}
            <div style={{ flex: 1 }}>
              <h3
                style={{
                  margin: 0,
                  fontSize: 17,
                  fontWeight: 700,
                  color: 'var(--text-primary, #111827)',
                  lineHeight: 1.3,
                  letterSpacing: '-0.01em',
                }}
              >
                {title}
              </h3>
              <p
                style={{
                  margin: '8px 0 0',
                  fontSize: 13.5,
                  color: 'var(--text-secondary, #4B5563)',
                  lineHeight: 1.5,
                  whiteSpace: 'pre-line',
                }}
              >
                {message}
              </p>
            </div>
          </div>
        </div>

        {/* Footer actions */}
        <div
          style={{
            padding: '14px 24px 20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            gap: 10,
            background: 'var(--bg-muted, #F9FAFB)',
            borderTop: '1px solid var(--border-color, #F3F4F6)',
          }}
        >
          <button
            type="button"
            disabled={loading}
            onClick={onClose}
            style={{
              padding: '10px 18px',
              borderRadius: 10,
              border: '1px solid var(--border-color, #D1D5DB)',
              background: '#FFFFFF',
              color: 'var(--text-primary, #374151)',
              fontSize: 13,
              fontWeight: 600,
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => !loading && (e.currentTarget.style.backgroundColor = '#F3F4F6')}
            onMouseLeave={(e) => !loading && (e.currentTarget.style.backgroundColor = '#FFFFFF')}
          >
            {cancelText}
          </button>

          <button
            type="button"
            disabled={loading}
            onClick={onConfirm}
            style={{
              padding: '10px 20px',
              borderRadius: 10,
              border: 'none',
              backgroundColor: confirmBg,
              color: '#FFFFFF',
              fontSize: 13,
              fontWeight: 700,
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              boxShadow: isDanger ? '0 4px 14px rgba(220, 38, 38, 0.3)' : '0 4px 14px rgba(74, 83, 67, 0.25)',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => !loading && (e.currentTarget.style.backgroundColor = confirmHoverBg)}
            onMouseLeave={(e) => !loading && (e.currentTarget.style.backgroundColor = confirmBg)}
          >
            {loading ? (
              <>
                <span
                  style={{
                    width: 14,
                    height: 14,
                    border: '2px solid #FFFFFF',
                    borderTop: '2px solid transparent',
                    borderRadius: '50%',
                    display: 'inline-block',
                    animation: 'spin 1s linear infinite',
                  }}
                />
                Processing...
              </>
            ) : (
              confirmText
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
