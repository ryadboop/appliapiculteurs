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
      .order('visited_at', { ascending: false })
    if (!error) {
      setVisits(
        data.map((v) => ({
          id: v.id,
          hiveId: v.hive_id,
          beekeeperId: v.beekeeper_id,
          visitedAt: v.visited_at,
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
    if (!map[v.hiveId] || new Date(v.visitedAt) > new Date(map[v.hiveId].visitedAt)) map[v.hiveId] = v
    return map
  }, {})

  /**
   * Enregistre un passage. La date ET l'heure sont posées automatiquement
   * par la base (colonne visited_at, défaut now()) au moment de la
   * validation — on ne les transmet jamais depuis le client.
   * Photo et note sont obligatoires (vérifié aussi côté interface).
   */
  const addVisit = useCallback(
    async ({ hiveId, beekeeperId, photoFile, note }) => {
      if (!photoFile) throw new Error('Une photo de la ruche est obligatoire pour valider ce passage.')
      if (!note || !note.trim()) throw new Error('Un commentaire sur la ruche est obligatoire pour valider ce passage.')

      const ext = photoFile.name.split('.').pop() || 'jpg'
      const photoPath = `${hiveId}/${Date.now()}.${ext}`
      const { error: uploadError } = await supabase.storage.from('visit-photos').upload(photoPath, photoFile)
      if (uploadError) throw uploadError

      const { data: userData } = await supabase.auth.getUser()
      const { error } = await supabase.from('hive_visits').insert({
        hive_id: hiveId,
        beekeeper_id: beekeeperId,
        photo_path: photoPath,
        note: note.trim(),
        created_by: userData?.user?.id,
      })
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { visits, lastVisitByHive, loading, addVisit, refetch }
}
