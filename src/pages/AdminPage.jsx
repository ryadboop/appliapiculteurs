import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useBeekeepers } from '../hooks/useBeekeepers'
import { useHives } from '../hooks/useHives'
import { useHiveVisits } from '../hooks/useHiveVisits'
import { useAuditLog } from '../hooks/useAuditLog'
import { downloadCsv, dateStamp } from '../lib/csv'
import { placementLabel, shareRoleLabel, statusLabel } from '../lib/hives'

export default function AdminPage() {
  const { beekeepers, loading, addBeekeeper, removeBeekeeper } = useBeekeepers()
  const { hives } = useHives()
  const { visits } = useHiveVisits()
  const { entries: auditEntries, loading: auditLoading, restoreHive } = useAuditLog()
  const [restoring, setRestoring] = useState(null)
  const [name, setName] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const exportRuchers = () => {
    downloadCsv(
      `izigreen-ruchers-${dateStamp()}.csv`,
      [
        'Nom du rucher',
        'Client',
        'Commune / Ville',
        'Région',
        'Implantation',
        'Adresse exacte',
        'Apiculteur',
        'Nombre de ruches',
        'CA annuel (€ HT)',
        'Statut',
        "Rôle rucher partagé",
        'Rucher hôte lié',
        'Latitude',
        'Longitude',
        "Date d'installation",
        "Fin d'engagement (3 ans)",
      ],
      hives.map((h) => {
        const finEngagement = new Date(h.startDate)
        finEngagement.setFullYear(finEngagement.getFullYear() + 3)
        const hote = hives.find((x) => x.id === h.hostHiveId)
        return [
          h.name,
          h.client,
          h.site,
          h.region,
          placementLabel[h.placement],
          h.placementDetail,
          h.beekeeperName ?? '',
          h.hiveCount,
          h.revenue ?? '',
          statusLabel[h.status],
          shareRoleLabel[h.shareRole || ''],
          hote?.name ?? '',
          h.latitude ?? '',
          h.longitude ?? '',
          h.startDate,
          finEngagement.toISOString().slice(0, 10),
        ]
      })
    )
  }

  const exportPassages = () => {
    const parHive = Object.fromEntries(hives.map((h) => [h.id, h]))
    downloadCsv(
      `izigreen-passages-${dateStamp()}.csv`,
      ['Rucher', 'Client', 'Commune / Ville', 'Apiculteur', 'Date du passage', 'Note', 'Lien photo', 'Enregistré le'],
      visits.map((v) => {
        const h = parHive[v.hiveId]
        return [
          h?.name ?? '',
          h?.client ?? '',
          h?.site ?? '',
          h?.beekeeperName ?? '',
          v.visitDate,
          v.note ?? '',
          v.photoUrl ?? '',
          new Date(v.createdAt).toLocaleString('fr-FR'),
        ]
      })
    )
  }

  const submit = async (e) => {
    e.preventDefault()
    if (!name.trim()) return
    setSubmitting(true)
    setError(null)
    try {
      await addBeekeeper(name)
      setName('')
    } catch (err) {
      setError(err.message?.includes('duplicate') ? 'Cet apiculteur existe déjà.' : "Impossible d'ajouter cet apiculteur.")
    } finally {
      setSubmitting(false)
    }
  }

  const remove = async (b) => {
    if (!window.confirm(`Supprimer ${b.name} de la liste des apiculteurs partenaires ?`)) return
    try {
      await removeBeekeeper(b.id)
    } catch {
      setError("Suppression impossible — cet apiculteur est peut-être encore assigné à des ruchers.")
    }
  }

  const doRestore = async (entry) => {
    if (!window.confirm(`Restaurer le rucher "${entry.label}" ? Attention : ses passages/animations antérieurs à la suppression ne sont pas récupérés automatiquement.`))
      return
    setRestoring(entry.id)
    try {
      await restoreHive(entry.oldData)
    } catch (err) {
      alert('Restauration impossible : ' + err.message)
    } finally {
      setRestoring(null)
    }
  }

  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 md:px-8 md:py-14">
      <h1 className="flex items-center gap-2 text-3xl font-semibold text-ink-900 md:text-4xl" style={{ fontFamily: 'var(--font-display)' }}>
        <ShieldIcon className="w-7 h-7 text-forest-700" /> Espace administrateur
      </h1>

      <section className="glass-card mt-8 rounded-3xl p-6">
        <h2 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
          Exports
        </h2>
        <p className="mt-1 text-sm text-ink-900/50">
          Fichiers CSV complets, prêts pour Excel/Sheets (accents corrects, colonnes numériques exploitables).
        </p>
        <div className="mt-4 flex flex-wrap gap-3">
          <button
            onClick={exportRuchers}
            className="flex items-center gap-2 rounded-2xl bg-forest-800 px-4 py-2.5 text-sm font-medium text-white hover:bg-forest-700 transition"
          >
            <DownloadIcon className="w-4 h-4" />
            Exporter les ruchers ({hives.length})
          </button>
          <button
            onClick={exportPassages}
            className="flex items-center gap-2 rounded-2xl bg-honey-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-honey-600 transition"
          >
            <DownloadIcon className="w-4 h-4" />
            Exporter les passages ({visits.length})
          </button>
        </div>
      </section>

      <section className="glass-card mt-5 rounded-3xl p-6">
        <h2 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
          Apiculteurs partenaires
        </h2>
        <p className="mt-1 text-sm text-ink-900/50">
          Cette liste alimente le menu déroulant du formulaire "Ajouter une ruche". Lier un apiculteur à un compte de
          connexion (pour qu'il voie ses ruchers en premier) se fera à l'étape suivante, quand on créera ses accès.
        </p>

        <form onSubmit={submit} className="mt-4 flex flex-wrap items-end gap-3">
          <div className="flex-1 min-w-[200px]">
            <label className="block text-sm font-medium text-ink-900/80 mb-1.5">Nom de l'apiculteur</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Prénom Nom"
              className="h-11 w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 text-sm text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition"
            />
          </div>
          <button
            type="submit"
            disabled={submitting || !name.trim()}
            className="h-11 rounded-xl bg-forest-800 px-5 text-sm font-medium text-white hover:bg-forest-700 transition disabled:opacity-40"
          >
            Ajouter
          </button>
        </form>
        {error && <p className="text-xs text-red-600 mt-2">{error}</p>}

        <div className="mt-5 divide-y divide-forest-800/8 rounded-2xl border border-forest-800/10">
          {loading && <p className="px-4 py-6 text-center text-sm text-ink-900/40">Chargement…</p>}
          {!loading && beekeepers.length === 0 && (
            <p className="px-4 py-6 text-center text-sm text-ink-900/40">Aucun apiculteur enregistré pour le moment.</p>
          )}
          <AnimatePresence initial={false}>
            {beekeepers.map((b) => (
              <motion.div
                key={b.id}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex items-center justify-between gap-3 px-4 py-3"
              >
                <div>
                  <p className="text-sm font-medium text-ink-900">{b.name}</p>
                  <p className="text-xs text-ink-900/40">{b.user_id ? 'Compte de connexion lié' : 'Pas encore de compte lié'}</p>
                </div>
                <button
                  onClick={() => remove(b)}
                  className="flex size-8 items-center justify-center rounded-lg text-ink-900/40 hover:bg-red-50 hover:text-red-600 transition"
                  aria-label={`Supprimer ${b.name}`}
                >
                  <TrashIcon className="w-4 h-4" />
                </button>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </section>

      <section className="glass-card mt-5 rounded-3xl p-6 text-center">
        <p className="text-ink-900 font-medium">La création des accès (comptes) reste à connecter.</p>
        <p className="mt-2 text-sm text-ink-900/50 max-w-md mx-auto">
          En attendant, crée les comptes depuis Supabase (Authentication &gt; Users), puis lie chacun à son profil
          apiculteur avec une ligne SQL — je te la donne quand tu es prêt à créer les premiers accès.
        </p>
      </section>

      <section className="glass-card mt-5 rounded-3xl p-6">
        <h2 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
          Journal des modifications
        </h2>
        <p className="mt-1 text-sm text-ink-900/50">
          Qui a créé, modifié ou supprimé quoi, et quand. Les 150 dernières actions.
        </p>

        <div className="mt-4 divide-y divide-forest-800/8 rounded-2xl border border-forest-800/10 max-h-[480px] overflow-y-auto">
          {auditLoading && <p className="px-4 py-6 text-center text-sm text-ink-900/40">Chargement…</p>}
          {!auditLoading && auditEntries.length === 0 && (
            <p className="px-4 py-6 text-center text-sm text-ink-900/40">Aucune action enregistrée pour le moment.</p>
          )}
          {auditEntries.map((entry) => (
            <div key={entry.id} className="flex flex-wrap items-center justify-between gap-3 px-4 py-3">
              <div className="min-w-0">
                <p className="text-sm text-ink-900">
                  <span
                    className={`inline-block mr-2 px-2 py-0.5 rounded-full text-[11px] font-semibold uppercase ${
                      entry.action === 'insert'
                        ? 'bg-forest-100 text-forest-800'
                        : entry.action === 'delete'
                          ? 'bg-red-50 text-red-600'
                          : 'bg-honey-100 text-honey-600'
                    }`}
                  >
                    {entry.actionLabel}
                  </span>
                  <span className="font-medium">{entry.tableLabel}</span> · {entry.label}
                </p>
                <p className="text-xs text-ink-900/40 mt-0.5">
                  {new Date(entry.changedAt).toLocaleString('fr-FR')}
                  {entry.changedByEmail && ` · ${entry.changedByEmail}`}
                  {entry.changedFields.length > 0 && ` · champs modifiés : ${entry.changedFields.join(', ')}`}
                </p>
              </div>
              {entry.action === 'delete' && entry.tableName === 'hives' && (
                <button
                  onClick={() => doRestore(entry)}
                  disabled={restoring === entry.id}
                  className="shrink-0 rounded-xl bg-forest-800 px-3 py-1.5 text-xs font-medium text-white hover:bg-forest-700 transition disabled:opacity-50"
                >
                  {restoring === entry.id ? 'Restauration…' : 'Restaurer'}
                </button>
              )}
            </div>
          ))}
        </div>
      </section>
    </main>
  )
}

function ShieldIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z" />
    </svg>
  )
}
function TrashIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m3 0-1 14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2L4 6h16Z" />
    </svg>
  )
}
function DownloadIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" />
    </svg>
  )
}
