import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'
import { useHives } from '../hooks/useHives'
import { formatEuro, hiveMatchesSearch, placementLabel } from '../lib/hives'
import { downloadCsv } from '../lib/csv'

function downloadArchive(year, hives) {
  downloadCsv(
    `izigreen-ruchers-${year}.csv`,
    ['Rucher', 'Client', 'Commune', 'Région', 'Implantation', 'Apiculteur', 'Ruches', 'CA annuel (€ HT)', 'Début engagement', 'Statut'],
    hives.map((h) => [
      h.name,
      h.client,
      h.site,
      h.region,
      placementLabel[h.placement],
      h.beekeeperName ?? '',
      h.hiveCount,
      h.revenue ?? '',
      h.startDate,
      h.status,
    ])
  )
}

export default function HistoriquePage() {
  const { isAdmin } = useAuth()
  const { hives, loading } = useHives()
  const currentYear = new Date().getFullYear()
  const [search, setSearch] = useState('')

  const byYear = useMemo(() => {
    const map = new Map()
    for (const h of hives) {
      if (!h.startYear || h.startYear >= currentYear) continue
      if (!hiveMatchesSearch(h, search)) continue
      if (!map.has(h.startYear)) map.set(h.startYear, [])
      map.get(h.startYear).push(h)
    }
    return Array.from(map.entries()).sort((a, b) => b[0] - a[0])
  }, [hives, currentYear, search])

  return (
    <main className="mx-auto w-full max-w-5xl px-5 py-10 md:px-8 md:py-14">
      <motion.header initial={{ opacity: 0, y: -12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
        <h1 className="text-4xl font-semibold text-ink-900 md:text-5xl" style={{ fontFamily: 'var(--font-display)' }}>
          Historique annuel
        </h1>
        <p className="mt-2 max-w-xl text-sm text-ink-900/50">
          Chaque année passée reste consultable ici et téléchargeable au format CSV, calculée directement depuis la date
          d'installation de chaque rucher.
        </p>
      </motion.header>

      <div className="relative mt-6">
        <SearchIcon className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-ink-900/30" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Rechercher un rucher ou un client…"
          className="h-11 w-full max-w-md rounded-2xl border border-forest-800/15 bg-white/70 pl-10 pr-3.5 text-sm text-ink-900 outline-none transition focus:ring-2 focus:ring-honey-400 focus:border-honey-400"
        />
      </div>

      <section className="mt-6 space-y-4">
        {!loading && byYear.length === 0 && (
          <div className="glass-card rounded-3xl px-6 py-16 text-center">
            <p className="text-xl font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
              {search.trim() ? 'Aucun résultat' : "Aucune année archivée pour l'instant"}
            </p>
            <p className="mt-2 text-sm text-ink-900/50">
              {search.trim()
                ? `Aucun rucher archivé ne correspond à « ${search} ».`
                : `L'année ${currentYear} est en cours : elle apparaîtra ici automatiquement à partir du ${currentYear + 1}.`}
            </p>
          </div>
        )}

        {byYear.map(([year, yearHives], i) => {
          const revenue = isAdmin ? yearHives.reduce((s, h) => s + (h.revenue ?? 0), 0) : null
          return (
            <motion.article
              key={year}
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, delay: i * 0.05 }}
              className="glass-card rounded-3xl p-6"
            >
              <div className="flex flex-wrap items-center justify-between gap-4">
                <div>
                  <p className="text-xs font-medium uppercase tracking-wider text-ink-900/40">Exercice clôturé</p>
                  <h2 className="text-3xl font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
                    {year}
                  </h2>
                </div>
                {isAdmin && (
                  <button
                    onClick={() => downloadArchive(year, yearHives)}
                    className="flex items-center gap-2 rounded-2xl bg-honey-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-honey-600 transition"
                  >
                    <DownloadIcon className="w-4 h-4" /> Télécharger le CSV
                  </button>
                )}
              </div>

              <div className={`mt-5 grid gap-3 ${isAdmin ? 'sm:grid-cols-2' : 'sm:grid-cols-1'}`}>
                {isAdmin && (
                  <div className="rounded-2xl bg-cream-50 p-4">
                    <p className="text-xs uppercase tracking-wider text-ink-900/40">CA annuel</p>
                    <p className="mt-1 text-2xl font-semibold text-ink-900" style={{ fontFamily: 'var(--font-mono)' }}>
                      {formatEuro(revenue)}
                    </p>
                  </div>
                )}
                <div className="rounded-2xl bg-cream-50 p-4">
                  <p className="text-xs uppercase tracking-wider text-ink-900/40">Ruchers installés</p>
                  <p className="mt-1 text-2xl font-semibold text-ink-900" style={{ fontFamily: 'var(--font-mono)' }}>
                    {yearHives.length}
                  </p>
                </div>
              </div>

              <div className="mt-4 divide-y divide-forest-800/8 rounded-2xl border border-forest-800/10">
                {yearHives.map((h) => (
                  <div key={h.id} className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm">
                    <div>
                      <p className="font-semibold text-ink-900">{h.name}</p>
                      <p className="text-xs text-ink-900/50">
                        {h.client} · {h.site} · {placementLabel[h.placement]}
                      </p>
                    </div>
                    {isAdmin && (
                      <p className="font-semibold text-ink-900" style={{ fontFamily: 'var(--font-mono)' }}>
                        {formatEuro(h.revenue)}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </motion.article>
          )
        })}
      </section>
    </main>
  )
}

function DownloadIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" />
    </svg>
  )
}
function SearchIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <circle cx="11" cy="11" r="8" />
      <path d="m21 21-4.3-4.3" />
    </svg>
  )
}
