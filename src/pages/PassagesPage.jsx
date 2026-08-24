import { useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'
import { useHives } from '../hooks/useHives'
import { useHiveVisits } from '../hooks/useHiveVisits'
import Modal from '../components/Modal'
import { nextVisitDue } from '../lib/hives'

export default function PassagesPage() {
  const { myBeekeeperId, isAdmin } = useAuth()
  const { hives, loading: hivesLoading } = useHives()
  const { lastVisitByHive, addVisit } = useHiveVisits()
  const [activeHive, setActiveHive] = useState(null)

  const ruchersAffiches = useMemo(() => {
    const base = isAdmin ? hives : hives.filter((h) => h.beekeeperId === myBeekeeperId)
    return base
      .map((h) => {
        const dernier = lastVisitByHive[h.id]
        const echeance = nextVisitDue(dernier?.visitDate, h.startDate)
        return { ...h, dernierPassage: dernier, echeance }
      })
      .sort((a, b) => a.echeance.daysUntilDue - b.echeance.daysUntilDue)
  }, [hives, isAdmin, myBeekeeperId, lastVisitByHive])

  if (!hivesLoading && !myBeekeeperId && !isAdmin) {
    return (
      <main className="mx-auto w-full max-w-3xl px-5 py-10 md:px-8 md:py-14">
        <div className="glass-card mt-2 rounded-3xl p-8 text-center">
          <p className="text-ink-900 font-medium">Cette page est réservée aux apiculteurs partenaires.</p>
          <p className="mt-2 text-sm text-ink-900/50">Ton compte n'est lié à aucun profil apiculteur pour le moment.</p>
        </div>
      </main>
    )
  }

  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 md:px-8 md:py-14">
      <h1 className="text-3xl font-semibold text-ink-900 md:text-4xl" style={{ fontFamily: 'var(--font-display)' }}>
        Passages mensuels
      </h1>
      <p className="mt-2 max-w-lg text-sm text-ink-900/50">
        {isAdmin
          ? "Vue d'ensemble de tous les ruchers, tous apiculteurs confondus. Une alerte apparaît 3 jours avant l'échéance."
          : "Un passage par mois et par rucher. Une alerte apparaît 3 jours avant l'échéance."}
      </p>

      <div className="mt-8 space-y-3">
        {hivesLoading && <div className="glass-card rounded-3xl px-6 py-14 text-center text-sm text-ink-900/40">Chargement…</div>}
        {!hivesLoading && ruchersAffiches.length === 0 && (
          <div className="glass-card rounded-3xl px-6 py-14 text-center text-sm text-ink-900/40">
            {isAdmin ? 'Aucun rucher enregistré pour le moment.' : "Aucun rucher ne t'est encore assigné."}
          </div>
        )}
        {ruchersAffiches.map((h) => (
          <VisitCard key={h.id} hive={h} showBeekeeper={isAdmin} onLog={() => setActiveHive(h)} />
        ))}
      </div>

      {activeHive && (
        <LogVisitModal
          hive={activeHive}
          beekeeperId={activeHive.beekeeperId}
          onClose={() => setActiveHive(null)}
          onSubmit={async (payload) => {
            await addVisit(payload)
            setActiveHive(null)
          }}
        />
      )}
    </main>
  )
}

function VisitCard({ hive, showBeekeeper, onLog }) {
  const { echeance, dernierPassage } = hive
  const alerte = echeance.isDueSoon || echeance.isOverdue

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass-card rounded-3xl p-5 flex flex-wrap items-center gap-4 justify-between"
      style={alerte ? { border: '1px solid rgba(220,38,38,0.35)' } : undefined}
    >
      <div className="flex items-center gap-4 min-w-0">
        {dernierPassage?.photoUrl ? (
          <img src={dernierPassage.photoUrl} alt="" className="size-14 rounded-xl object-cover shrink-0" />
        ) : (
          <div className="size-14 rounded-xl bg-forest-100 text-forest-800 flex items-center justify-center shrink-0">
            <HiveIcon className="w-6 h-6" />
          </div>
        )}
        <div className="min-w-0">
          <p className="font-semibold text-ink-900 truncate">{hive.name}</p>
          <p className="text-xs text-ink-900/50 truncate">
            {hive.site}
            {showBeekeeper && ` · ${hive.beekeeperName || 'Aucun apiculteur assigné'}`}
          </p>
          <p className="text-xs mt-1">
            {dernierPassage ? (
              <span className="text-ink-900/60">Dernier passage le {new Date(dernierPassage.visitDate).toLocaleDateString('fr-FR')}</span>
            ) : (
              <span className="text-ink-900/40">Aucun passage enregistré</span>
            )}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-3 shrink-0">
        {alerte && (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 text-red-600 text-xs font-semibold px-3 py-1.5">
            <AlertDot />
            {echeance.isOverdue ? `En retard de ${Math.abs(echeance.daysUntilDue)} j` : 'Passage à prévoir'}
          </span>
        )}
        <button
          onClick={onLog}
          className="rounded-xl bg-forest-800 px-4 py-2.5 text-sm font-medium text-white hover:bg-forest-700 transition"
        >
          Enregistrer un passage
        </button>
      </div>
    </motion.div>
  )
}

function AlertDot() {
  return (
    <span className="relative flex size-2">
      <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-500 opacity-75" />
      <span className="relative inline-flex rounded-full size-2 bg-red-500" />
    </span>
  )
}

function LogVisitModal({ hive, beekeeperId, onClose, onSubmit }) {
  const [visitDate, setVisitDate] = useState(new Date().toISOString().slice(0, 10))
  const [photoFile, setPhotoFile] = useState(null)
  const [preview, setPreview] = useState(null)
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const onPickPhoto = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    setPhotoFile(file)
    setPreview(URL.createObjectURL(file))
  }

  const submit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    try {
      await onSubmit({ hiveId: hive.id, beekeeperId, visitDate, photoFile, note })
    } catch (err) {
      setError(err.message || "Impossible d'enregistrer ce passage.")
      setSubmitting(false)
    }
  }

  return (
    <Modal open onClose={onClose} maxWidth="max-w-md">
      <form onSubmit={submit} className="p-6">
        <h3 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
          Passage · {hive.name}
        </h3>
        <p className="text-sm text-ink-900/50 mt-0.5">{hive.site}</p>

        <div className="mt-5 space-y-4">
          <div>
            <label className="block text-sm font-medium text-ink-900/80 mb-1.5">Date du passage</label>
            <input
              type="date"
              required
              max={new Date().toISOString().slice(0, 10)}
              value={visitDate}
              onChange={(e) => setVisitDate(e.target.value)}
              className="h-11 w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 text-sm text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-ink-900/80 mb-1.5">Photo des ruches (facultatif)</label>
            {preview ? (
              <div className="relative">
                <img src={preview} alt="Aperçu" className="w-full h-40 object-cover rounded-xl" />
                <button
                  type="button"
                  onClick={() => {
                    setPhotoFile(null)
                    setPreview(null)
                  }}
                  className="absolute top-2 right-2 rounded-lg bg-black/60 text-white text-xs px-2 py-1"
                >
                  Retirer
                </button>
              </div>
            ) : (
              <label className="flex items-center justify-center gap-2 h-24 rounded-xl border-2 border-dashed border-forest-100 text-sm text-ink-900/50 cursor-pointer hover:border-honey-400 transition">
                <CameraIcon className="w-5 h-5" />
                Ajouter une photo
                <input type="file" accept="image/*" capture="environment" onChange={onPickPhoto} className="hidden" />
              </label>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-ink-900/80 mb-1.5">Note (facultatif)</label>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={2}
              placeholder="Observation particulière…"
              className="w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 py-2.5 text-sm text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition resize-none"
            />
          </div>

          {error && <p className="text-xs text-red-600">{error}</p>}
        </div>

        <div className="flex justify-end gap-2 mt-6">
          <button type="button" onClick={onClose} className="rounded-xl px-4 py-2 text-sm font-medium text-ink-900/60 hover:bg-cream-50 transition">
            Annuler
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="rounded-xl bg-honey-500 px-4 py-2 text-sm font-semibold text-white hover:bg-honey-600 transition disabled:opacity-50"
          >
            {submitting ? 'Enregistrement…' : 'Valider le passage'}
          </button>
        </div>
      </form>
    </Modal>
  )
}

function HiveIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 2 3 7v10l9 5 9-5V7z" />
    </svg>
  )
}
function CameraIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2Z" />
      <circle cx="12" cy="13" r="4" />
    </svg>
  )
}
