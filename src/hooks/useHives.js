import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './useAuth'
import { computeStatus, effectiveRevenue } from '../lib/hives'

function fromRow(row) {
  return {
    id: row.id,
    name: row.name,
    client: row.client,
    site: row.site,
    region: row.region,
    startDate: row.start_date,
    hiveCount: row.hive_count,
    placement: row.placement,
    placementDetail: row.placement_detail,
    beekeeper: row.beekeeper,
    shareRole: row.share_role || '',
    hostHiveId: row.host_hive_id,
    latitude: row.latitude,
    longitude: row.longitude,
    price: row.price, // null pour un compte standard (masqué par la vue)
    revenue: row.base_revenue == null ? null : effectiveRevenue(row.hive_count, row.price),
    status: row.status ?? computeStatus(row.start_date),
    startYear: row.start_year,
  }
}

export function useHives() {
  const { isAdmin } = useAuth()
  const [hives, setHives] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase
      .from('v_hives')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      setError(error.message)
    } else {
      setError(null)
      setHives(data.map(fromRow))
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    refetch()

    if (isAdmin) {
      const channel = supabase
        .channel('hives-realtime')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'hives' }, () => refetch())
        .subscribe()
      return () => supabase.removeChannel(channel)
    }

    const onFocus = () => refetch()
    window.addEventListener('focus', onFocus)
    const interval = setInterval(refetch, 60_000)
    return () => {
      window.removeEventListener('focus', onFocus)
      clearInterval(interval)
    }
  }, [isAdmin, refetch])

  const addHive = useCallback(
    async (hive) => {
      const { data: userData } = await supabase.auth.getUser()
      const { error } = await supabase.from('hives').insert({
        name: hive.name,
        client: hive.client,
        site: hive.site,
        region: hive.region,
        start_date: hive.startDate,
        hive_count: hive.hiveCount,
        placement: hive.placement,
        placement_detail: hive.placementDetail,
        beekeeper: hive.beekeeper ?? '',
        share_role: hive.shareRole ?? '',
        host_hive_id: hive.hostHiveId || null,
        latitude: hive.latitude,
        longitude: hive.longitude,
        price: hive.price,
        created_by: userData?.user?.id,
      })
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  const updateHive = useCallback(
    async (id, patch) => {
      const map = {
        name: 'name',
        client: 'client',
        site: 'site',
        region: 'region',
        startDate: 'start_date',
        hiveCount: 'hive_count',
        placement: 'placement',
        placementDetail: 'placement_detail',
        beekeeper: 'beekeeper',
        shareRole: 'share_role',
        hostHiveId: 'host_hive_id',
        latitude: 'latitude',
        longitude: 'longitude',
        price: 'price',
      }
      const payload = {}
      for (const [jsKey, dbKey] of Object.entries(map)) {
        if (patch[jsKey] !== undefined) payload[dbKey] = patch[jsKey]
      }
      const { error } = await supabase.from('hives').update(payload).eq('id', id)
      await refetch()
      if (error) throw error
    },
    [refetch]
  )

  const removeHive = useCallback(
    async (id) => {
      const { error } = await supabase.from('hives').delete().eq('id', id)
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { hives, loading, error, addHive, updateHive, removeHive, refetch }
}
