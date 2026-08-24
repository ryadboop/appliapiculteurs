import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

function publicPhotoUrl(path) {
  if (!path) return null
  const { data } = supabase.storage.from('visit-photos').getPublicUrl(path)
  return data?.publicUrl ?? null
}

export function useHiveVisits() {
  const [visits, setVisits] = useState([])
  const [loading, setLoading] = useState(true)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase
      .from('hive_visits')
      .select('*')
      .order('visit_date', { ascending: false })
    if (!error) {
      setVisits(
        data.map((v) => ({
          id: v.id,
          hiveId: v.hive_id,
          beekeeperId: v.beekeeper_id,
          visitDate: v.visit_date,
          photoUrl: publicPhotoUrl(v.photo_path),
          note: v.note,
          createdAt: v.created_at,
        }))
      )
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    refetch()
  }, [refetch])

  /** Dernier passage par rucher (le plus récent), pour l'affichage rapide. */
  const lastVisitByHive = visits.reduce((map, v) => {
    if (!map[v.hiveId] || v.visitDate > map[v.hiveId].visitDate) map[v.hiveId] = v
    return map
  }, {})

  const addVisit = useCallback(
    async ({ hiveId, beekeeperId, visitDate, photoFile, note }) => {
      let photoPath = null
      if (photoFile) {
        const ext = photoFile.name.split('.').pop() || 'jpg'
        photoPath = `${hiveId}/${Date.now()}.${ext}`
        const { error: uploadError } = await supabase.storage.from('visit-photos').upload(photoPath, photoFile)
        if (uploadError) throw uploadError
      }
      const { data: userData } = await supabase.auth.getUser()
      const { error } = await supabase.from('hive_visits').insert({
        hive_id: hiveId,
        beekeeper_id: beekeeperId,
        visit_date: visitDate,
        photo_path: photoPath,
        note: note || null,
        created_by: userData?.user?.id,
      })
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { visits, lastVisitByHive, loading, addVisit, refetch }
}
