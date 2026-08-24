import { useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'
import { useHives } from '../hooks/useHives'
import { useBeekeepers } from '../hooks/useBeekeepers'
import { useAnimations } from '../hooks/useAnimations'
import Modal from '../components/Modal'

const inputClass =
  'h-11 w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 text-sm text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition'
const labelClass = 'block text-sm font-medium text-ink-900/80 mb-1.5'

export default function AnimationsPage() {
  const { isAdmin } = useAuth()
  const { hives } = useHives()
  const { beekeepers } = useBeekeepers()
  const { animations, loading, addAnimation, removeAnimation } = useAnimations()
  const [open, setOpen] = useState(false)

  const parHive = useMemo(() => Object.fromEntries(hives.map((h) => [h.id, h])), [hives])
  const parBeekeeper = useMemo(() => Object.fromEntries(beekeepers.map((b) => [b.id, b])), [beekeepers])

  const today = new Date().toISOString().slice(0, 10)
  const aVenir = animations.filter((a) => a.date >= today)
  const passees = animations.filter((a) => a.date < today)

  if (!isAdmin) {
    return (
      <main className="mx-auto w-full max-w-3xl px-5 py-10 md:px-8 md:py-14">
        <div className="glass-card mt-2 rounded-3xl p-8 text-center">
          <p className="text-ink-900 font-medium">Cette page est réservée aux administrateurs.</p>
        </div>
      </main>
    )
  }

  const remove = async (a) => {
    if (!window.confirm(`Supprimer cette animation du ${new Date(a.date).toLocaleDateString('fr-FR')} ?`)) return
    await removeAnimation(a.id)
  }

  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 md:px-8 md:py-14">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-semibold text-ink-900 md:text-4xl" style={{ fontFamily: 'var(--font-display)' }}>
            Animations
          </h1>
          <p className="mt-2 max-w-lg text-sm text-ink-900/50">Interventions planifiées sur ou hors des ruchers.</p>
        </div>
        <button
          onClick={() => setOpen(true)}
          className="flex items-center gap-2 rounded-2xl bg-honey-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-honey-600 transition shrink-0"
        >
          <PlusIcon className="w-4 h-4" /> Ajouter une animation
        </button>
      </div>

      {loading && <div className="glass-card mt-8 rounded-3xl px-6 py-14 text-center text-sm text-ink-900/40">Chargement…</div>}

      {!loading && (
        <>
          <Section title="À venir" items={aVenir} parHive={parHive} parBeekeeper={parBeekeeper} onDelete={remove} empty="Aucune animation planifiée." />
          <Section title="Passées" items={[...passees].reverse()} parHive={parHive} parBeekeeper={parBeekeeper} onDelete={remove} empty="Aucune animation passée." muted />
        </>
      )}

      {open && (
        <AddAnimationModal
          hives={hives}
          beekeepers={beekeepers}
          onClose={() => setOpen(false)}
          onSubmit={async (payload) => {
            await addAnimation(payload)
            setOpen(false)
          }}
        />
      )}
    </main>
  )
}

function Section({ title, items, parHive, parBeekeeper, onDelete, empty, muted }) {
  return (
    <section className="mt-8">
      <h2 className="text-sm font-semibold uppercase tracking-wide text-ink-900/40 mb-3">{title}</h2>
      {items.length === 0 ? (
        <div className="glass-card rounded-3xl px-6 py-8 text-center text-sm text-ink-900/40">{empty}</div>
      ) : (
        <div className="space-y-2">
          <AnimatePresence initial={false}>
            {items.map((a) => {
              const hive = parHive[a.hiveId]
              const intervenant = a.beekeeperId ? parBeekeeper[a.beekeeperId]?.name : a.intervenantName
              const adresse = a.locationType === 'site' ? hive?.placementDetail || hive?.site : a.customAddress
              return (
                <motion.div
                  key={a.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: muted ? 0.6 : 1 }}
                  exit={{ opacity: 0 }}
                  className="glass-card rounded-2xl p-4 flex flex-wrap items-start justify-between gap-3"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-semibold text-ink-900">
                        {new Date(a.date).toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric', month: 'long' })}
                      </span>
                      <span className="text-xs text-ink-900/40">·</span>
                      <span className="text-sm text-ink-900">{hive?.name ?? 'Rucher supprimé'}</span>
                    </div>
                    <p className="text-xs text-ink-900/50 mt-0.5">
                      {adresse} · Intervenant : {intervenant || '—'}
                    </p>
                    {a.comment && <p className="text-xs text-ink-900/60 mt-1.5 italic">« {a.comment} »</p>}
                  </div>
                  <button
                    onClick={() => onDelete(a)}
                    className="flex size-8 items-center justify-center rounded-lg text-ink-900/40 hover:bg-red-50 hover:text-red-600 transition shrink-0"
                    aria-label="Supprimer"
                  >
                    <TrashIcon className="w-4 h-4" />
                  </button>
                </motion.div>
              )
            })}
          </AnimatePresence>
        </div>
      )}
    </section>
  )
}

function AddAnimationModal({ hives, beekeepers, onClose, onSubmit }) {
  const [hiveId, setHiveId] = useState('')
  const [locationType, setLocationType] = useState('site')
  const [customAddress, setCustomAddress] = useState('')
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10))
  const [intervenantMode, setIntervenantMode] = useState('beekeeper')
  const [beekeeperId, setBeekeeperId] = useState('')
  const [intervenantName, setIntervenantName] = useState('')
  const [comment, setComment] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

  const hive = hives.find((h) => h.id === hiveId)
  const adresseSite = hive ? hive.placementDetail || hive.site : ''

  const valid =
    hiveId &&
    date &&
    (locationType === 'site' || customAddress.trim().length > 1) &&
    (intervenantMode === 'beekeeper' ? beekeeperId : intervenantName.trim().length > 1)

  const submit = async (e) => {
    e.preventDefault()
    if (!valid) return
    setSubmitting(true)
    setError(null)
    try {
      await onSubmit({
        hiveId,
        locationType,
        customAddress,
        date,
        beekeeperId: intervenantMode === 'beekeeper' ? beekeeperId : null,
        intervenantName: intervenantMode === 'autre' ? intervenantName : '',
        comment,
      })
    } catch (err) {
      setError(err.message || "Impossible d'enregistrer cette animation.")
      setSubmitting(false)
    }
  }

  return (
    <Modal open onClose={onClose} maxWidth="max-w-lg">
      <form onSubmit={submit} className="p-6">
        <h3 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
          Nouvelle animation
        </h3>

        <div className="mt-5 space-y-4">
          <div>
            <label className={labelClass}>Rucher</label>
            <select value={hiveId} onChange={(e) => setHiveId(e.target.value)} className={inputClass} required>
              <option value="">Choisir un rucher</option>
              {hives.map((h) => (
                <option key={h.id} value={h.id}>
                  {h.name} · {h.site}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className={labelClass}>Lieu</label>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setLocationType('site')}
                className={`rounded-xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                  locationType === 'site' ? 'border-forest-700 bg-forest-100 text-forest-800' : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                }`}
              >
                Sur site
              </button>
              <button
                type="button"
                onClick={() => setLocationType('autre')}
                className={`rounded-xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                  locationType === 'autre' ? 'border-forest-700 bg-forest-100 text-forest-800' : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                }`}
              >
                Autre adresse
              </button>
            </div>
            {locationType === 'site' ? (
              <p className="text-xs text-ink-900/50 mt-2">{hive ? `Adresse du rucher : ${adresseSite}` : 'Choisis un rucher pour voir son adresse.'}</p>
            ) : (
              <input
                className={`${inputClass} mt-2`}
                placeholder="Adresse où se déroulera l'animation"
                value={customAddress}
                onChange={(e) => setCustomAddress(e.target.value)}
              />
            )}
          </div>

          <div>
            <label className={labelClass}>Date de l'animation</label>
            <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className={inputClass} required />
          </div>

          <div>
            <label className={labelClass}>Intervenant</label>
            <div className="grid grid-cols-2 gap-2 mb-2">
              <button
                type="button"
                onClick={() => setIntervenantMode('beekeeper')}
                className={`rounded-xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                  intervenantMode === 'beekeeper' ? 'border-forest-700 bg-forest-100 text-forest-800' : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                }`}
              >
                Apiculteur partenaire
              </button>
              <button
                type="button"
                onClick={() => setIntervenantMode('autre')}
                className={`rounded-xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                  intervenantMode === 'autre' ? 'border-forest-700 bg-forest-100 text-forest-800' : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                }`}
              >
                Autre personne
              </button>
            </div>
            {intervenantMode === 'beekeeper' ? (
              <select value={beekeeperId} onChange={(e) => setBeekeeperId(e.target.value)} className={inputClass}>
                <option value="">Choisir un apiculteur</option>
                {beekeepers.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            ) : (
              <input className={inputClass} placeholder="Prénom Nom" value={intervenantName} onChange={(e) => setIntervenantName(e.target.value)} />
            )}
          </div>

          <div>
            <label className={labelClass}>Commentaire (facultatif)</label>
            <textarea
              value={comment}
              onChange={(e) => setComment(e.target.value)}
              rows={3}
              placeholder="Ce qui a été convenu, horaire précis, durée, matériel…"
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
            disabled={!valid || submitting}
            className="rounded-xl bg-honey-500 px-4 py-2 text-sm font-semibold text-white hover:bg-honey-600 transition disabled:opacity-40"
          >
            {submitting ? 'Enregistrement…' : "Ajouter l'animation"}
          </button>
        </div>
      </form>
    </Modal>
  )
}

function PlusIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 5v14M5 12h14" />
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
