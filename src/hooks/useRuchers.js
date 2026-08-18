import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'

export function useRuchers() {
  const { isAdmin } = useAuth()
  const [ruchers, setRuchers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase
      .from('v_ruchers')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      setError(error.message)
    } else {
      setError(null)
      setRuchers(data)
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    refetch()

    // Admin : mise à jour instantanée via Supabase Realtime (la table brute
    // est accessible en lecture pour les admins, cf. schema.sql).
    if (isAdmin) {
      const channel = supabase
        .channel('ruchers-realtime')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'ruchers' }, () => {
          refetch()
        })
        .subscribe()

      return () => {
        supabase.removeChannel(channel)
      }
    }

    // Utilisateur standard : pas d'accès realtime à la table brute (le CA
    // ne doit jamais transiter, même masqué, sur ce canal). On resynchronise
    // au retour sur l'onglet et à intervalle régulier — largement suffisant
    // pour un outil consulté quelques fois par jour.
    const onFocus = () => refetch()
    window.addEventListener('focus', onFocus)
    const interval = setInterval(refetch, 60_000)

    return () => {
      window.removeEventListener('focus', onFocus)
      clearInterval(interval)
    }
  }, [isAdmin, refetch])

  return { ruchers, loading, error, refetch }
}
