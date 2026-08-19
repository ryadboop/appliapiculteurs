import { useEffect, useState } from 'react'
import Modal from './Modal'
import EngagementRing from './EngagementRing'
import { useBeekeepers } from '../hooks/useBeekeepers'
import {
  PLACEMENTS,
  REGIONS,
  SHARE_ROLES,
  annualRevenue,
  engagementProgress,
  formatCoords,
  formatEuro,
  monthsRemaining,
  placementLabel,
  shareRoleLabel,
  sharedHosts,
  statusLabel,
} from '../lib/hives'

const inputClass =
  'h-11 w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 text-sm text-ink-900 outline-none transition focus:ring-2 focus:ring-honey-400 focus:border-honey-400'
const labelClass = 'block text-sm font-medium text-ink-900/80 mb-1.5'

function Row({ label, value }) {
  return (
    <div className="rounded-2xl border border-forest-100 bg-cream-50 px-4 py-3">
      <p className="text-[11px] font-medium uppercase tracking-wider text-ink-900/40">{label}</p>
      <p className="mt-0.5 text-sm font-medium text-ink-900">{value || '—'}</p>
    </div>
  )
}

export default function HiveDetailDialog({ hive, hives, isAdmin, onClose, onSave }) {
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(null)
  const [form, setForm] = useState(null)
  const { beekeepers } = useBeekeepers()

  useEffect(() => {
    if (!hive) return
    setEditing(false)
    setError(null)
    setForm({
      name: hive.name,
      client: hive.client,
      site: hive.site,
      region: hive.region,
      placement: hive.placement,
      placementDetail: hive.placementDetail,
      beekeeperId: hive.beekeeperId ?? '',
      shareRole: hive.shareRole ?? '',
      hostHiveId: hive.hostHiveId ?? '',
      startDate: hive.startDate,
      hiveCount: hive.hiveCount,
      latitude: hive.latitude == null ? '' : String(hive.latitude),
      longitude: hive.longitude == null ? '' : String(hive.longitude),
      price: hive.price == null ? '' : String(hive.price),
    })
  }, [hive])

  if (!hive || !form) return null

  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }))

  const lat = form.latitude.trim() === '' ? null : Number(form.latitude.replace(',', '.'))
  const lng = form.longitude.trim() === '' ? null : Number(form.longitude.replace(',', '.'))
  const coordsValid =
    (lat === null && lng === null) ||
    (lat !== null && lng !== null && Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180)

  const customPrice = form.price.trim() === '' ? null : Number(form.price.replace(',', '.').replace(/\s/g, ''))
  const priceValid = customPrice === null || (Number.isFinite(customPrice) && customPrice >= 0)
  const nameValid = form.name.trim().length > 1 && form.client.trim().length > 1
  const hosts = sharedHosts(hives, hive.id)
  const shareValid = form.placement !== 'partage' || form.shareRole === 'hote' || (form.shareRole === 'heberge' && form.hostHiveId !== '')
  const canSave = coordsValid && priceValid && nameValid && shareValid && !saving

  const locate = () => {
    if (!navigator.geolocation) return
    navigator.geolocation.getCurrentPosition((pos) =>
      setForm((f) => ({ ...f, latitude: pos.coords.latitude.toFixed(6), longitude: pos.coords.longitude.toFixed(6) }))
    )
  }

  const save = async () => {
    if (!canSave) return
    setSaving(true)
    setError(null)
    try {
      await onSave(hive.id, {
        name: form.name.trim(),
        client: form.client.trim(),
        site: form.site.trim(),
        region: form.region,
        placement: form.placement,
        placementDetail: form.placementDetail.trim(),
        beekeeperId: form.beekeeperId || null,
        shareRole: form.placement === 'partage' ? form.shareRole : '',
        hostHiveId: form.placement === 'partage' && form.shareRole === 'heberge' ? form.hostHiveId : null,
        startDate: form.startDate,
        hiveCount: form.hiveCount,
        latitude: lat,
        longitude: lng,
        price: customPrice,
      })
      setEditing(false)
    } catch {
      setError('Modification impossible — seuls les administrateurs peuvent modifier un rucher.')
    } finally {
      setSaving(false)
    }
  }

  const progress = engagementProgress(hive.startDate)

  return (
    <Modal open onClose={onClose} maxWidth="max-w-2xl">
      <div className="gradient-forest px-6 pb-6 pt-6 text-white rounded-t-3xl">
        <p className="text-xs uppercase tracking-[0.2em] opacity-70">
          {placementLabel[hive.placement]} · {statusLabel[hive.status]}
        </p>
        <h2 className="mt-1 text-2xl font-semibold" style={{ fontFamily: 'var(--font-display)' }}>
          {hive.name}
        </h2>
        <p className="text-sm opacity-80">
          {hive.client} · {hive.site}
        </p>
      </div>

      <div className="space-y-4 px-6 py-6">
        {!editing ? (
          <>
            <div className="grid gap-3 sm:grid-cols-2">
              <Row label="Client" value={hive.client} />
              <Row label="Nombre de ruches" value={hive.hiveCount} />
              <Row label="Commune / ville" value={hive.site} />
              <Row label="Région" value={hive.region} />
              <Row label="Implantation" value={placementLabel[hive.placement]} />
              <Row label="Adresse exacte" value={hive.placementDetail} />
              <Row label="Apiculteur partenaire" value={hive.beekeeperName} />
              {hive.placement === 'partage' && (
                <>
                  <Row label="Rôle" value={shareRoleLabel[hive.shareRole || '']} />
                  {hive.shareRole === 'heberge' && (
                    <Row label="Hébergé sur" value={hives.find((h) => h.id === hive.hostHiveId)?.name ?? '—'} />
                  )}
                </>
              )}
              <Row label="Coordonnées GPS" value={formatCoords(hive.latitude, hive.longitude)} />
              <Row label="Début d'engagement" value={new Date(hive.startDate).toLocaleDateString('fr-FR')} />
              {isAdmin && <Row label="Prix total facturé" value={formatEuro(hive.revenue)} />}
            </div>

            <div className="rounded-2xl border border-forest-100 bg-cream-50 p-4">
              <EngagementRing
                progress={progress}
                size={64}
                label={`${monthsRemaining(hive.startDate)} mois restants`}
                sublabel={`Engagement 3 ans depuis le ${new Date(hive.startDate).toLocaleDateString('fr-FR')}`}
              />
            </div>

            {hive.latitude != null && hive.longitude != null && (
              <iframe
                title="Position du rucher"
                className="h-48 w-full rounded-xl border border-forest-100"
                loading="lazy"
                src={`https://www.openstreetmap.org/export/embed.html?bbox=${hive.longitude - 0.01}%2C${hive.latitude - 0.008}%2C${hive.longitude + 0.01}%2C${hive.latitude + 0.008}&layer=mapnik&marker=${hive.latitude}%2C${hive.longitude}`}
              />
            )}
          </>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className={labelClass}>Nom du rucher</label>
              <input value={form.name} onChange={(e) => set('name', e.target.value)} className={inputClass} />
            </div>
            <div>
              <label className={labelClass}>Client</label>
              <input value={form.client} onChange={(e) => set('client', e.target.value)} className={inputClass} />
            </div>
            <div>
              <label className={labelClass}>Commune / ville</label>
              <input value={form.site} onChange={(e) => set('site', e.target.value)} className={inputClass} />
            </div>
            <div>
              <label className={labelClass}>Région</label>
              <select value={form.region} onChange={(e) => set('region', e.target.value)} className={inputClass}>
                {REGIONS.map((r) => (
                  <option key={r} value={r}>
                    {r}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className={labelClass}>Implantation</label>
              <select value={form.placement} onChange={(e) => set('placement', e.target.value)} className={inputClass}>
                {PLACEMENTS.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className={labelClass}>Adresse exacte</label>
              <input value={form.placementDetail} onChange={(e) => set('placementDetail', e.target.value)} className={inputClass} />
            </div>

            {form.placement === 'partage' && (
              <>
                <div>
                  <label className={labelClass}>Rôle sur le rucher partagé</label>
                  <select
                    value={form.shareRole}
                    onChange={(e) => setForm((f) => ({ ...f, shareRole: e.target.value, hostHiveId: e.target.value === 'hote' ? '' : f.hostHiveId }))}
                    className={inputClass}
                  >
                    <option value="">Hôte ou hébergé</option>
                    {SHARE_ROLES.map((r) => (
                      <option key={r.id} value={r.id}>
                        {r.label}
                      </option>
                    ))}
                  </select>
                </div>
                {form.shareRole === 'heberge' && (
                  <div>
                    <label className={labelClass}>Rucher hôte</label>
                    <select value={form.hostHiveId} onChange={(e) => set('hostHiveId', e.target.value)} className={inputClass}>
                      <option value="">Choisir un rucher partagé</option>
                      {hosts.map((h) => (
                        <option key={h.id} value={h.id}>
                          {h.name} · {h.site}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </>
            )}

            <div>
              <label className={labelClass}>Apiculteur partenaire</label>
              <select value={form.beekeeperId} onChange={(e) => set('beekeeperId', e.target.value)} className={inputClass}>
                <option value="">Aucun apiculteur assigné</option>
                {beekeepers.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className={labelClass}>Nombre de ruches</label>
              <input
                type="number"
                min={1}
                value={form.hiveCount}
                onChange={(e) => set('hiveCount', Math.max(1, Number(e.target.value) || 1))}
                className={inputClass}
              />
            </div>
            <div>
              <label className={labelClass}>Début d'engagement</label>
              <input type="date" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} className={inputClass} />
            </div>
            <div>
              <label className={labelClass}>Prix total (€ HT / an)</label>
              <input
                inputMode="decimal"
                placeholder={String(annualRevenue(form.hiveCount))}
                value={form.price}
                onChange={(e) => set('price', e.target.value)}
                className={inputClass}
              />
            </div>

            <div className="sm:col-span-2">
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-sm font-medium text-ink-900/80">Coordonnées GPS</label>
                <button type="button" onClick={locate} className="text-xs font-medium text-forest-700 hover:bg-forest-100 rounded-lg px-2 py-1 transition">
                  Position actuelle
                </button>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <input placeholder="Latitude" value={form.latitude} onChange={(e) => set('latitude', e.target.value)} className={inputClass} />
                <input placeholder="Longitude" value={form.longitude} onChange={(e) => set('longitude', e.target.value)} className={inputClass} />
              </div>
              {!coordsValid && <p className="text-xs text-red-600 mt-1">Coordonnées GPS invalides.</p>}
              {!priceValid && <p className="text-xs text-red-600 mt-1">Prix total invalide.</p>}
              {error && <p className="text-xs text-red-600 mt-1">{error}</p>}
            </div>
          </div>
        )}
      </div>

      <div className="flex items-center justify-between gap-3 border-t border-forest-100 px-6 py-4">
        <p className="text-xs text-ink-900/40">{isAdmin ? 'Accès administrateur' : 'Lecture seule'}</p>
        {isAdmin ? (
          editing ? (
            <div className="flex gap-2">
              <button onClick={() => setEditing(false)} className="rounded-xl px-4 py-2 text-sm font-medium text-ink-900/60 hover:bg-cream-50 transition">
                Annuler
              </button>
              <button
                onClick={save}
                disabled={!canSave}
                className="rounded-xl bg-honey-500 px-4 py-2 text-sm font-semibold text-white hover:bg-honey-600 transition disabled:opacity-40"
              >
                Enregistrer
              </button>
            </div>
          ) : (
            <button onClick={() => setEditing(true)} className="rounded-xl bg-forest-800 px-4 py-2 text-sm font-medium text-white hover:bg-forest-700 transition">
              Modifier
            </button>
          )
        ) : (
          <button onClick={onClose} className="rounded-xl px-4 py-2 text-sm font-medium text-ink-900/60 hover:bg-cream-50 transition">
            Fermer
          </button>
        )}
      </div>
    </Modal>
  )
}
