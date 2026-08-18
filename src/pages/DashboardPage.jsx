import { useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'
import { useRuchers } from '../hooks/useRuchers'
import KpiCard from '../components/KpiCard'
import EngagementBadge from '../components/EngagementBadge'
import AnimatedNumber from '../components/AnimatedNumber'

const ONGLETS_STATUT = [
  { id: 'toutes', label: 'Toutes' },
  { id: 'en_cours', label: 'En cours' },
  { id: 'a_installer', label: 'À installer' },
  { id: 'renouvellement', label: 'Renouvellement' },
]

const STATUT_STYLE = {
  a_installer: 'bg-forest-100 text-forest-800',
  en_cours: 'bg-forest-800 text-white',
  renouvellement: 'bg-honey-500 text-white',
}

const STATUT_LABEL = {
  a_installer: 'À installer',
  en_cours: 'En cours',
  renouvellement: 'Renouvellement',
}

const formatEuros = (n) =>
  (n ?? 0).toLocaleString('fr-FR', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 })

export default function DashboardPage() {
  const { profile, isAdmin, signOut } = useAuth()
  const { ruchers, loading, error } = useRuchers()
  const [statutFiltre, setStatutFiltre] = useState('toutes')
  const [historiqueOuvert, setHistoriqueOuvert] = useState(false)

  const anneeCourante = new Date().getFullYear()
  const [anneeAffichee, setAnneeAffichee] = useState(anneeCourante)

  const anneesDisponibles = useMemo(() => {
    const annees = new Set(ruchers.map((r) => r.annee_installation).filter(Boolean))
    annees.add(anneeCourante)
    return Array.from(annees).sort((a, b) => b - a)
  }, [ruchers, anneeCourante])

  // Les 3 KPIs en tête portent sur les NOUVELLES ruches de l'année affichée
  // (la saison qu'on regarde), pas sur tout le portefeuille.
  const ruchersDeLaSaison = useMemo(
    () => ruchers.filter((r) => r.annee_installation === anneeAffichee),
    [ruchers, anneeAffichee]
  )
  const clientsUniques = useMemo(() => {
    const ids = new Set(ruchersDeLaSaison.map((r) => r.client_id).filter(Boolean))
    return ids.size
  }, [ruchersDeLaSaison])
  const caSaison = useMemo(
    () => ruchersDeLaSaison.reduce((somme, r) => somme + Number(r.prix_total || 0), 0),
    [ruchersDeLaSaison]
  )

  // Le tableau, lui, montre tout le portefeuille actif (peu importe l'année
  // d'installation) : un rucher en "renouvellement" a forcément été installé
  // il y a 3 ans, pas cette saison — il doit rester visible ici.
  const ruchersAffiches = useMemo(() => {
    if (statutFiltre === 'toutes') return ruchers
    return ruchers.filter((r) => r.statut === statutFiltre)
  }, [ruchers, statutFiltre])

  return (
    <div className="min-h-screen px-4 py-8 sm:px-8 lg:px-12">
      <div className="max-w-6xl mx-auto">
        {/* En-tête */}
        <header className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-2">
            <span className="font-display font-semibold text-forest-800 text-lg">izigreen</span>
            <span className="text-honey-500 text-lg leading-none">◆</span>
            <span className="font-display font-medium text-ink-900 text-lg ml-2">Suivi des ruches</span>
          </div>
          <div className="flex items-center gap-4 text-sm">
            <span className="flex items-center gap-1.5 text-ink-900/60">
              <ShieldIcon className="w-4 h-4" />
              {isAdmin ? 'Admin' : profile?.full_name || 'Utilisateur'}
            </span>
            <button
              onClick={signOut}
              className="flex items-center gap-1.5 text-ink-900/60 hover:text-ink-900 transition"
            >
              <LogoutIcon className="w-4 h-4" />
              Se déconnecter
            </button>
          </div>
        </header>

        <span className="inline-flex items-center gap-1.5 bg-forest-800/5 border border-forest-800/10 text-forest-800 text-xs font-medium px-3 py-1 rounded-full mb-4">
          IziGreen · Saison {anneeAffichee}
        </span>

        <div className="flex flex-wrap items-end justify-between gap-4 mb-8">
          <div>
            <h1 className="font-display text-3xl sm:text-4xl font-semibold text-ink-900">
              Vos ruchers, en un coup d'œil
            </h1>
            <p className="text-ink-900/50 mt-1.5">
              Chiffres clés du 1er janvier au 31 décembre {anneeAffichee} · clôture et archivage
              automatiques chaque 1er janvier.
            </p>
          </div>
          <div className="flex gap-2 relative">
            <button
              onClick={() => setHistoriqueOuvert((v) => !v)}
              className="flex items-center gap-2 rounded-xl border border-forest-800/15 bg-white px-4 py-2.5 text-sm font-medium text-ink-900 hover:bg-forest-100/40 transition"
            >
              <HistoryIcon className="w-4 h-4" />
              Historique
            </button>
            <AnimatePresence>
              {historiqueOuvert && (
                <motion.div
                  initial={{ opacity: 0, y: -6 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -6 }}
                  className="absolute right-0 top-full mt-2 glass-card rounded-2xl p-2 z-10 min-w-[160px]"
                >
                  {anneesDisponibles.map((annee) => (
                    <button
                      key={annee}
                      onClick={() => {
                        setAnneeAffichee(annee)
                        setHistoriqueOuvert(false)
                      }}
                      className={`w-full text-left px-3 py-2 rounded-xl text-sm transition ${
                        annee === anneeAffichee
                          ? 'bg-forest-800 text-white'
                          : 'hover:bg-forest-100/60 text-ink-900'
                      }`}
                    >
                      Saison {annee}
                    </button>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
            {isAdmin && (
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="flex items-center gap-2 rounded-xl bg-honey-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-honey-600 transition shadow-sm"
              >
                <PlusIcon className="w-4 h-4" />
                Ajouter une ruche
              </motion.button>
            )}
          </div>
        </div>

        {/* KPIs */}
        <div className={`grid gap-4 mb-8 ${isAdmin ? 'sm:grid-cols-3' : 'sm:grid-cols-2'}`}>
          <KpiCard icon={<HiveIcon className="w-5 h-5" />} label="Ruches installées" sublabel={`${ruchersDeLaSaison.length} rucher${ruchersDeLaSaison.length > 1 ? 's' : ''} suivi${ruchersDeLaSaison.length > 1 ? 's' : ''}`}>
            <AnimatedNumber value={ruchersDeLaSaison.length} />
          </KpiCard>
          <KpiCard icon={<UsersIcon className="w-5 h-5" />} label="Clients uniques" sublabel="Nouveaux clients cette saison">
            <AnimatedNumber value={clientsUniques} />
          </KpiCard>
          {isAdmin && (
            <KpiCard icon={<TrendingIcon className="w-5 h-5" />} label="Chiffre d'affaires" sublabel="Cumul annuel contractualisé HT" accent="honey">
              <AnimatedNumber value={caSaison} formatter={formatEuros} />
            </KpiCard>
          )}
        </div>

        {/* Tableau */}
        <div className="glass-card rounded-3xl overflow-hidden">
          <div className="flex flex-wrap items-center justify-between gap-3 px-6 pt-5 pb-4">
            <div className="flex gap-1 bg-forest-100/50 rounded-xl p-1">
              {ONGLETS_STATUT.map((onglet) => (
                <button
                  key={onglet.id}
                  onClick={() => setStatutFiltre(onglet.id)}
                  className={`relative px-4 py-1.5 text-sm font-medium rounded-lg transition ${
                    statutFiltre === onglet.id ? 'text-white' : 'text-ink-900/60 hover:text-ink-900'
                  }`}
                >
                  {statutFiltre === onglet.id && (
                    <motion.span
                      layoutId="onglet-actif"
                      className="absolute inset-0 bg-forest-800 rounded-lg"
                      transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                    />
                  )}
                  <span className="relative">{onglet.label}</span>
                </button>
              ))}
            </div>
            <span className="text-sm text-ink-900/50">
              {ruchersAffiches.length} rucher{ruchersAffiches.length > 1 ? 's' : ''}
            </span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-xs font-semibold text-ink-900/40 uppercase tracking-wide border-t border-forest-800/10">
                  <th className="px-6 py-3">Rucher</th>
                  <th className="px-6 py-3">Client</th>
                  {isAdmin && <th className="px-6 py-3">CA annuel</th>}
                  <th className="px-6 py-3">Engagement 3 ans</th>
                  <th className="px-6 py-3">Statut</th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={isAdmin ? 5 : 4} className="px-6 py-10 text-center text-ink-900/40">
                      Chargement…
                    </td>
                  </tr>
                )}
                {error && (
                  <tr>
                    <td colSpan={isAdmin ? 5 : 4} className="px-6 py-10 text-center text-red-600">
                      {error}
                    </td>
                  </tr>
                )}
                {!loading && !error && ruchersAffiches.length === 0 && (
                  <tr>
                    <td colSpan={isAdmin ? 5 : 4} className="px-6 py-10 text-center text-ink-900/40">
                      Aucune ruche pour le moment · ajoutez votre première ruche pour démarrer.
                    </td>
                  </tr>
                )}
                <AnimatePresence>
                  {!loading &&
                    !error &&
                    ruchersAffiches.map((r) => (
                      <motion.tr
                        key={r.id}
                        layout
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="border-t border-forest-800/8 hover:bg-mist-100/50 transition-colors"
                      >
                        <td className="px-6 py-3.5 font-medium text-ink-900">
                          {r.commune_ville || '—'}
                        </td>
                        <td className="px-6 py-3.5 text-ink-900/70">{r.client_nom || '—'}</td>
                        {isAdmin && (
                          <td className="px-6 py-3.5 font-mono text-ink-900/80">
                            {formatEuros(r.prix_total)}
                          </td>
                        )}
                        <td className="px-6 py-3.5">
                          <EngagementBadge dateInstallation={r.date_installation} statut={r.statut} />
                        </td>
                        <td className="px-6 py-3.5">
                          <span className={`inline-block px-2.5 py-1 rounded-full text-xs font-medium ${STATUT_STYLE[r.statut]}`}>
                            {STATUT_LABEL[r.statut]}
                          </span>
                        </td>
                      </motion.tr>
                    ))}
                </AnimatePresence>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

function HiveIcon(props) {
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
function TrendingIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" />
      <polyline points="17 6 23 6 23 12" />
    </svg>
  )
}
function PlusIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 5v14M5 12h14" />
    </svg>
  )
}
function HistoryIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M3 3v5h5" />
      <path d="M3.05 13A9 9 0 1 0 6 5.3L3 8" />
      <path d="M12 7v5l4 2" />
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
