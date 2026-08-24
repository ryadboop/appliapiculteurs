import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'
import { useHives } from '../hooks/useHives'
import { celebrate } from '../lib/celebrate'
import { formatEuro, statusLabel } from '../lib/hives'
import KpiCard from '../components/KpiCard'
import AnimatedNumber from '../components/AnimatedNumber'
import AddHiveDialog from '../components/AddHiveDialog'
import HiveTable from '../components/HiveTable'
import HiveDetailDialog from '../components/HiveDetailDialog'
import izigreenLogo from '../assets/izigreen-logo.png'

const FILTERS = [
  { id: 'all', label: 'Toutes' },
  { id: 'active', label: statusLabel.active },
  { id: 'pending', label: statusLabel.pending },
  { id: 'renewal', label: statusLabel.renewal },
]

export default function DashboardPage() {
  const { isAdmin, myBeekeeperId, signOut } = useAuth()
  const { hives: hivesRaw, loading, error, addHive, updateHive, removeHive } = useHives()
  const [filter, setFilter] = useState('all')
  const [selectedId, setSelectedId] = useState(null)
  const year = new Date().getFullYear()

  // Si le compte connecté est lié à un profil apiculteur, ses propres
  // ruchers remontent en premier (tri stable, il voit aussi le reste).
  const hives = useMemo(() => {
    if (!myBeekeeperId) return hivesRaw
    const miens = hivesRaw.filter((h) => h.beekeeperId === myBeekeeperId)
    const autres = hivesRaw.filter((h) => h.beekeeperId !== myBeekeeperId)
    return [...miens, ...autres]
  }, [hivesRaw, myBeekeeperId])

  const visible = useMemo(() => (filter === 'all' ? hives : hives.filter((h) => h.status === filter)), [hives, filter])

  // KPIs cumulatifs sur l'ensemble du portefeuille actif (pas juste les
  // nouvelles installations de l'année) — cohérent avec la logique réelle du
  // projet d'origine : "Saison {year}" est l'étiquette de la période en
  // cours, la valeur reflète l'état actuel du parc de ruchers.
  const revenue = isAdmin ? hives.reduce((s, h) => s + (h.revenue ?? 0), 0) : 0
  const hiveCount = hives.reduce((s, h) => s + h.hiveCount, 0)
  const clientCount = new Set(hives.map((h) => h.client.trim().toLowerCase()).filter(Boolean)).size

  const create = async (hive) => {
    await addHive(hive)
    celebrate()
  }

  const handleDelete = async (id) => {
    await removeHive(id)
  }

  const selected = hives.find((h) => h.id === selectedId) ?? null

  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-10 md:px-8 md:py-14">
      <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.45 }} className="mb-8 flex items-center gap-3">
        <span className="relative inline-block font-bold text-forest-800 text-lg">
          <img src={izigreenLogo} alt="izigreen" className="h-6 w-auto" />
        </span>
        <span className="font-bold text-ink-900 text-lg">Suivi des ruches</span>
        <div className="ml-auto flex items-center gap-1">
          {(myBeekeeperId || isAdmin) && (
            <Link to="/passages" className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm text-ink-900/50 hover:text-ink-900 hover:bg-white/50 transition">
              <CalendarIcon className="w-4 h-4" /> Passages
            </Link>
          )}
          {isAdmin && (
            <Link to="/animations" className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm text-ink-900/50 hover:text-ink-900 hover:bg-white/50 transition">
              <SparkleIcon className="w-4 h-4" /> Animation
            </Link>
          )}
          {isAdmin && (
            <Link to="/admin" className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm text-ink-900/50 hover:text-ink-900 hover:bg-white/50 transition">
              <ShieldIcon className="w-4 h-4" /> Admin
            </Link>
          )}
          <button onClick={signOut} className="flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm text-ink-900/50 hover:text-ink-900 hover:bg-white/50 transition">
            <LogoutIcon className="w-4 h-4" /> Se déconnecter
          </button>
        </div>
      </motion.div>

      <motion.header
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex flex-wrap items-end justify-between gap-6"
      >
        <div>
          <span className="inline-flex items-center gap-2 rounded-full bg-forest-800/10 px-3 py-1 text-xs font-semibold text-forest-800">
            <LeafIcon className="w-3.5 h-3.5" /> IziGreen · Saison {year}
          </span>
          <h1 className="mt-3 text-4xl font-semibold text-ink-900 md:text-5xl" style={{ fontFamily: 'var(--font-display)' }}>
            Vos ruchers, en un coup d'œil
          </h1>
          <p className="mt-2 max-w-lg text-sm text-ink-900/50">
            Chiffres clés du 1<sup>er</sup> janvier au 31 décembre {year} · clôture et archivage automatiques chaque 1<sup>er</sup> janvier.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link
            to="/historique"
            className="flex items-center gap-2 rounded-2xl border border-forest-800/15 bg-white/70 px-4 py-2.5 text-sm font-medium text-ink-900 hover:bg-white transition"
          >
            <ArchiveIcon className="w-4 h-4" /> Historique
          </Link>
          {isAdmin && <AddHiveDialog onCreate={create} hives={hives} />}
        </div>
      </motion.header>

      <section className={`mt-9 grid gap-4 ${isAdmin ? 'sm:grid-cols-2 lg:grid-cols-3' : 'sm:grid-cols-2'}`}>
        <KpiCard icon={<HexIcon className="w-5 h-5" />} label={`Ruches installées ${year}`} sublabel={`${hives.length} rucher${hives.length > 1 ? 's' : ''} suivi${hives.length > 1 ? 's' : ''}`}>
          <AnimatedNumber value={hiveCount} />
        </KpiCard>
        <KpiCard icon={<UsersIcon className="w-5 h-5" />} label="Clients uniques" sublabel="Parrains distincts cette année">
          <AnimatedNumber value={clientCount} />
        </KpiCard>
        {isAdmin && (
          <KpiCard icon={<TrendIcon className="w-5 h-5" />} label="Chiffre d'affaires" sublabel="Cumul annuel contractualisé HT" accent="honey">
            <AnimatedNumber value={revenue} formatter={formatEuro} />
          </KpiCard>
        )}
      </section>

      <section className="mt-6">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.15 }}
          className="glass-card flex flex-wrap items-center gap-2 rounded-3xl p-3"
        >
          {FILTERS.map((f) => (
            <button
              key={f.id}
              onClick={() => setFilter(f.id)}
              className={`relative rounded-2xl px-4 py-2 text-sm font-medium transition-colors ${
                filter === f.id ? 'text-white' : 'text-ink-900/60 hover:text-ink-900'
              }`}
            >
              {filter === f.id && (
                <motion.span layoutId="filter-pill" className="gradient-forest absolute inset-0 rounded-2xl" transition={{ type: 'spring', stiffness: 420, damping: 34 }} />
              )}
              <span className="relative z-10">{f.label}</span>
            </button>
          ))}
          <span className="ml-auto pr-2 text-xs text-ink-900/40">
            {visible.length} rucher{visible.length > 1 ? 's' : ''}
          </span>
        </motion.div>
      </section>

      <section className="mt-4">
        {loading ? (
          <div className="glass-card rounded-3xl px-6 py-14 text-center text-sm text-ink-900/40">Chargement…</div>
        ) : error ? (
          <div className="glass-card rounded-3xl px-6 py-14 text-center text-sm text-red-600">{error}</div>
        ) : (
          <HiveTable hives={visible} isAdmin={isAdmin} myBeekeeperId={myBeekeeperId} onDelete={handleDelete} onSelect={(h) => setSelectedId(h.id)} />
        )}
      </section>

      {selected && (
        <HiveDetailDialog hive={selected} hives={hives} isAdmin={isAdmin} onClose={() => setSelectedId(null)} onSave={updateHive} />
      )}
    </main>
  )
}

function HexIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 2 3 7v10l9 5 9-5V7z" />
    </svg>
  )
}
function UsersIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  )
}
function TrendIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
      <polyline points="17 6 23 6 23 12" />
    </svg>
  )
}
function ArchiveIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <rect x="2" y="4" width="20" height="5" rx="1" />
      <path d="M4 9v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9M10 13h4" />
    </svg>
  )
}
function LeafIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M11 20A7 7 0 0 1 4 13V6a1 1 0 0 1 1-1h7a7 7 0 0 1 7 7 7 7 0 0 1-7 7Z" />
      <path d="M4 20l6-6" />
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
function CalendarIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <path d="M16 2v4M8 2v4M3 10h18" />
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
function LogoutIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}
