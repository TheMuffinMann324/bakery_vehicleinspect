export function KeyCap({ label }: { label: string }) {
  return <span className={`keycap${label.length > 1 ? ' wide' : ''}`}>{label}</span>
}

export const KeyIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <circle cx="8" cy="15" r="4.5" fill="none" stroke="currentColor" strokeWidth="2.4" />
    <path d="M11.2 11.8 20 3M16.5 6.5l2.5 2.5M14 9l2 2" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
  </svg>
)

export const ShieldIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth="1.6" />
    <path d="M12 6.5 16.5 8v3.6c0 2.8-1.9 4.8-4.5 5.9-2.6-1.1-4.5-3.1-4.5-5.9V8z" fill="currentColor" />
  </svg>
)

export const GpsIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <circle cx="12" cy="12" r="6.5" fill="none" stroke="currentColor" strokeWidth="2" />
    <circle cx="12" cy="12" r="2.5" fill="currentColor" />
    <path d="M12 1.5v4M12 18.5v4M1.5 12h4M18.5 12h4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
  </svg>
)

export const BadgeIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <rect x="2.5" y="4" width="19" height="16" rx="3" fill="none" stroke="currentColor" strokeWidth="1.8" />
    <path d="M7 15.5 9 9l3 3.5L15 9l2 6.5z" fill="currentColor" />
  </svg>
)

export const PerfIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <rect x="2" y="3" width="20" height="18" rx="1.5" fill="none" stroke="currentColor" strokeWidth="1.8" />
    <path d="M5 17l4.5-6 3.5 3.5L19 7" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
  </svg>
)

export const RoadIcon = () => (
  <svg viewBox="0 0 24 24" className="ico">
    <rect x="2" y="3" width="20" height="18" rx="1.5" fill="none" stroke="currentColor" strokeWidth="1.8" />
    <path d="M9.5 6 6 18M14.5 6 18 18" stroke="currentColor" strokeWidth="2" />
    <path d="M12 7v2M12 11v2.2M12 15.5V18" stroke="currentColor" strokeWidth="1.6" />
  </svg>
)

export const Crown = () => (
  <svg viewBox="0 0 64 40" className="crown">
    <path
      d="M6 30 3 8l14 10L32 2l15 16 14-10-3 22zM7 33h50v5H7z"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinejoin="round"
    />
  </svg>
)
