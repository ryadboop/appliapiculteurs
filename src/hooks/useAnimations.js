import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

function fromRow(row) {
  return {
    id: row.id,
    hiveId: row.hive_id,
    locationType: row.location_type,
    customAddress: row.custom_address,
    date: row.animation_date,
    beekeeperId: row.beekeeper_id,
    intervenantName: row.intervenant_name,
    comment: row.comment,
    createdAt: row.created_at,
  }
}

export function useAnimations() {
  const [animations, setAnimations] = useState([])
  const [loading, setLoading] = useState(true)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase.from('animations').select('*').order('animation_date', { ascending: true })
    if (!error) setAnimations(data.map(fromRow))
    setLoading(false)
  }, [])

  useEffect(() => {
    refetch()
  }, [refetch])

  const addAnimation = useCallback(
    async (a) => {
      const { data: userData } = await supabase.auth.getUser()
      const { error } = await supabase.from('animations').insert({
        hive_id: a.hiveId,
        location_type: a.locationType,
        custom_address: a.locationType === 'autre' ? a.customAddress.trim() : '',
        animation_date: a.date,
        beekeeper_id: a.beekeeperId || null,
        intervenant_name: a.beekeeperId ? '' : a.intervenantName.trim(),
        comment: a.comment?.trim() || null,
        created_by: userData?.user?.id,
      })
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  const removeAnimation = useCallback(
    async (id) => {
      const { error } = await supabase.from('animations').delete().eq('id', id)
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { animations, loading, addAnimation, removeAnimation, refetch }
}
