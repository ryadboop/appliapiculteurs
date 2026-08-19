import { Link } from 'react-router-dom'

export default function AdminPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 md:px-8 md:py-14">
      <Link to="/" className="inline-flex items-center gap-1.5 -ml-2 rounded-xl px-2 py-1 text-sm text-ink-900/50 hover:text-ink-900 transition">
        <ArrowLeftIcon className="w-4 h-4" /> Dashboard
      </Link>
      <h1 className="mt-2 flex items-center gap-2 text-3xl font-semibold text-ink-900 md:text-4xl" style={{ fontFamily: 'var(--font-display)' }}>
        <ShieldIcon className="w-7 h-7 text-forest-700" /> Espace administrateur
      </h1>
      <div className="glass-card mt-8 rounded-3xl p-8 text-center">
        <p className="text-ink-900 font-medium">La création et suppression des accès depuis l'appli arrive dans la prochaine étape.</p>
        <p className="mt-2 text-sm text-ink-900/50 max-w-md mx-auto">
          En attendant, gère les comptes directement depuis Supabase : Authentication &gt; Users pour créer un accès, et une ligne
          SQL dans user_roles pour passer quelqu'un admin.
        </p>
      </div>
    </main>
  )
}

function ArrowLeftIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M19 12H5M12 19l-7-7 7-7" />
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
