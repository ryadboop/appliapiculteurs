import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'

const TABLE_LABEL = {
  hives: 'Rucher',
  beekeepers: 'Apiculteur',
  animations: 'Animation',
  hive_visits: 'Passage',
  user_roles: 'Rôle',
}

const ACTION_LABEL = {
  insert: 'Créé',
  update: 'Modifié',
  delete: 'Supprimé',
}

const FIELD_LABEL = {
  name: 'nom',
  client: 'client',
  site: 'commune/ville',
  region: 'région',
  start_date: "date d'installation",
  hive_count: 'nombre de ruches',
  placement: 'implantation',
  placement_detail: 'adresse',
  beekeeper_id: 'apiculteur',
  share_role: 'rôle partagé',
  host_hive_id: 'rucher hôte',
  latitude: 'latitude',
  longitude: 'longitude',
  price: 'prix',
  visit_date: 'date du passage',
  animation_date: "date de l'animation",
  location_type: 'lieu',
  custom_address: 'adresse',
  intervenant_name: 'intervenant',
  comment: 'commentaire',
  role: 'rôle',
}

function recordLabel(tableName, data) {
  if (!data) return '—'
  if (tableName === 'hives' || tableName === 'beekeepers') return data.name
  if (tableName === 'animations') return `Animation du ${data.animation_date}`
  if (tableName === 'hive_visits') return `Passage du ${data.visit_date}`
  if (tableName === 'user_roles') return `Rôle ${data.role}`
  return data.id
}

function changedFields(oldData, newData) {
  if (!oldData || !newData) return []
  const keys = new Set([...Object.keys(oldData), ...Object.keys(newData)])
  const changed = []
  for (const k of keys) {
    if (['updated_at', 'created_at'].includes(k)) continue
    if (JSON.stringify(oldData[k]) !== JSON.stringify(newData[k])) changed.push(FIELD_LABEL[k] || k)
  }
  return changed
}

function fromRow(row) {
  return {
    id: row.id,
    tableName: row.table_name,
    tableLabel: TABLE_LABEL[row.table_name] || row.table_name,
    action: row.action,
    actionLabel: ACTION_LABEL[row.action],
    label: recordLabel(row.table_name, row.new_data || row.old_data),
    changedFields: row.action === 'update' ? changedFields(row.old_data, row.new_data) : [],
    changedByEmail: row.changed_by_email,
    changedAt: row.changed_at,
    oldData: row.old_data,
    newData: row.new_data,
  }
}

export function useAuditLog(limit = 150) {
  const [entries, setEntries] = useState([])
  const [loading, setLoading] = useState(true)

  const refetch = useCallback(async () => {
    const { data, error } = await supabase
      .from('v_audit_log')
      .select('*')
      .order('changed_at', { ascending: false })
      .limit(limit)
    if (!error) setEntries(data.map(fromRow))
    setLoading(false)
  }, [limit])

  useEffect(() => {
    refetch()
  }, [refetch])

  const restoreHive = useCallback(
    async (oldData) => {
      const { id, created_at, updated_at, ...rest } = oldData
      const { error } = await supabase.from('hives').insert(rest)
      if (error) throw error
      await refetch()
    },
    [refetch]
  )

  return { entries, loading, restoreHive, refetch }
}
