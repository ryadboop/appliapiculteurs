import { useState } from 'react'
import { Link } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { useBeekeepers } from '../hooks/useBeekeepers'

export default function AdminPage() {
  const { beekeepers, loading, addBeekeeper, removeBeekeeper } = useBeekeepers()
  const [name, setName] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState(null)

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

  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-10 md:px-8 md:py-14">
      <Link to="/" className="inline-flex items-center gap-1.5 -ml-2 rounded-xl px-2 py-1 text-sm text-ink-900/50 hover:text-ink-900 transition">
        <ArrowLeftIcon className="w-4 h-4" /> Dashboard
      </Link>
      <h1 className="mt-2 flex items-center gap-2 text-3xl font-semibold text-ink-900 md:text-4xl" style={{ fontFamily: 'var(--font-display)' }}>
        <ShieldIcon className="w-7 h-7 text-forest-700" /> Espace administrateur
      </h1>

      <section className="glass-card mt-8 rounded-3xl p-6">
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
function TrashIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m3 0-1 14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2L4 6h16Z" />
    </svg>
  )
}
