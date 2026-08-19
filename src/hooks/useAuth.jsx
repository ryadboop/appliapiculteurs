import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { supabase } from '../lib/supabase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [myBeekeeperId, setMyBeekeeperId] = useState(null)
  const [loading, setLoading] = useState(true)

  const loadRole = useCallback(async (userId) => {
    if (!userId) {
      setIsAdmin(false)
      setMyBeekeeperId(null)
      return
    }
    const [{ data: roleRow, error: roleError }, { data: beekeeperRow, error: beekeeperError }] = await Promise.all([
      supabase.from('user_roles').select('role').eq('user_id', userId).eq('role', 'admin').maybeSingle(),
      supabase.from('beekeepers').select('id').eq('user_id', userId).maybeSingle(),
    ])
    if (roleError) console.error('Impossible de vérifier le rôle :', roleError.message)
    if (beekeeperError) console.error('Impossible de vérifier le profil apiculteur :', beekeeperError.message)
    setIsAdmin(Boolean(roleRow))
    setMyBeekeeperId(beekeeperRow?.id ?? null)
  }, [])

  useEffect(() => {
    let isMounted = true

    supabase.auth.getSession().then(async ({ data: { session } }) => {
      if (!isMounted) return
      setSession(session)
      await loadRole(session?.user?.id)
      setLoading(false)
    })

    const { data: listener } = supabase.auth.onAuthStateChange(async (_event, session) => {
      setSession(session)
      await loadRole(session?.user?.id)
    })

    return () => {
      isMounted = false
      listener.subscription.unsubscribe()
    }
  }, [loadRole])

  const signIn = useCallback(async (email, password) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return { error }
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
  }, [])

  const value = {
    session,
    user: session?.user ?? null,
    isAdmin,
    myBeekeeperId,
    loading,
    signIn,
    signOut,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth doit être utilisé à l’intérieur de <AuthProvider>')
  return ctx
}
