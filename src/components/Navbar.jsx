import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import izigreenLogo from '../assets/izigreen-logo.png'

function NavLink({ to, children, icon }) {
  const { pathname } = useLocation()
  const active = pathname === to

  return (
    <Link
      to={to}
      className={`flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm font-medium transition ${
        active ? 'bg-forest-800 text-white' : 'text-ink-900/60 hover:text-ink-900 hover:bg-white/60'
      }`}
    >
      {icon}
      {children}
    </Link>
  )
}

export default function Navbar() {
  const { isAdmin, myBeekeeperId, signOut } = useAuth()

  return (
    <header className="sticky top-0 z-30">
      <nav
        className="mx-auto max-w-6xl flex items-center gap-1 px-4 py-2.5 sm:px-6"
        style={{
          background: 'rgba(255,255,255,0.72)',
          backdropFilter: 'blur(18px) saturate(140%)',
          WebkitBackdropFilter: 'blur(18px) saturate(140%)',
          borderBottom: '1px solid color-mix(in srgb, white 60%, var(--color-forest-100))',
        }}
      >
        <Link to="/" className="flex items-center gap-2 pr-2 shrink-0">
          <img src={izigreenLogo} alt="izigreen" className="h-5 w-auto" />
        </Link>

        <span className="w-px h-5 bg-forest-800/10 mx-1 shrink-0" />

        <div className="flex items-center gap-1 overflow-x-auto">
          <NavLink to="/" icon={<HiveIcon className="w-4 h-4" />}>
            Suivi des ruches
          </NavLink>
          {isAdmin && (
            <NavLink to="/animations" icon={<SparkleIcon className="w-4 h-4" />}>
              Animation
            </NavLink>
          )}
          {(myBeekeeperId || isAdmin) && (
            <NavLink to="/passages" icon={<CalendarIcon className="w-4 h-4" />}>
              Passages
            </NavLink>
          )}
        </div>

        <div className="ml-auto flex items-center gap-1 shrink-0">
          {isAdmin && (
            <NavLink to="/admin" icon={<ShieldIcon className="w-4 h-4" />}>
              Admin
            </NavLink>
          )}
          <button
            onClick={signOut}
            className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm font-medium text-ink-900/60 hover:text-ink-900 hover:bg-white/60 transition"
          >
            <LogoutIcon className="w-4 h-4" />
            <span className="hidden sm:inline">Se déconnecter</span>
          </button>
        </div>
      </nav>
    </header>
  )
}

function HiveIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 2 3 7v10l9 5 9-5V7z" />
    </svg>
  )
}
function SparkleIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8" />
    </svg>
  )
}
function CalendarIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <path d="M16 2v4M8 2v4M3 10h18" />
    </svg>
  )
}
function ShieldIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
    </svg>
  )
}
function LogoutIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}
