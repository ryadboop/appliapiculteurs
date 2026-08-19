import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

export function useBeekeepers() {
  const [beekeepers, setBeekeepers] = useState([])
  const [loading, setLoading] = useState(true)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase.from('beekeepers').select('*').order('name', { ascending: true })
    if (!error) setBeekeepers(data)
    setLoading(false)
  }, [])

  useEffect(() => {
    refetch()
  }, [refetch])

  const addBeekeeper = useCallback(
    async (name) => {
      const { error } = await supabase.from('beekeepers').insert({ name: name.trim() })
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  const removeBeekeeper = useCallback(
    async (id) => {
      const { error } = await supabase.from('beekeepers').delete().eq('id', id)
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { beekeepers, loading, addBeekeeper, removeBeekeeper, refetch }
}
