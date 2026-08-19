import { useState } from 'react'
import { motion } from 'framer-motion'
import { useAuth } from '../hooks/useAuth'

export default function LoginPage() {
  const { signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    const { error } = await signIn(email, password)
    if (error) {
      setError(
        error.message === 'Invalid login credentials'
          ? 'Email ou mot de passe incorrect.'
          : error.message
      )
    }
    setSubmitting(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, ease: 'easeOut' }}
        className="glass-card w-full max-w-sm rounded-3xl px-8 py-10"
      >
        <div className="mb-1">
          <span className="relative inline-block font-bold text-forest-800 text-lg">
            izigreen
            <svg width="12" height="12" viewBox="0 0 24 24" className="absolute -top-1 -right-3 fill-honey-500">
              <circle cx="12" cy="12" r="10" />
              <path d="M8 12.5l2.5 2.5L16 9" stroke="white" strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </span>
        </div>
        <h1 className="text-2xl font-extrabold text-ink-900 mb-1">Suivi des ruches</h1>
        <p className="text-sm text-ink-900/60 mb-8">
          Accès réservé à l'équipe IziGreen.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-ink-900/80 mb-1.5">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-xl border border-forest-100 bg-white px-4 py-2.5 text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition"
              placeholder="prenom.nom@izigreen.fr"
            />
          </div>
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-ink-900/80 mb-1.5">
              Mot de passe
            </label>
            <input
              id="password"
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-xl border border-forest-100 bg-white px-4 py-2.5 text-ink-900 outline-none focus:ring-2 focus:ring-honey-400 focus:border-honey-400 transition"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2"
            >
              {error}
            </motion.p>
          )}

          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.98 }}
            type="submit"
            disabled={submitting}
            className="w-full rounded-xl bg-forest-800 text-white font-medium py-2.5 mt-2 hover:bg-forest-700 transition disabled:opacity-60"
          >
            {submitting ? 'Connexion…' : 'Se connecter'}
          </motion.button>
        </form>

        <p className="text-xs text-ink-900/40 mt-6 text-center">
          Pas encore de compte ? Demande à un administrateur de t'en créer un.
        </p>
      </motion.div>
    </div>
  )
}
