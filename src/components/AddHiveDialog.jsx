import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import Modal from './Modal'
import {
  FAREINS_BEEKEEPER,
  FAREINS_REGION,
  FAREINS_SITE,
  PLACEMENTS,
  PRICE_PER_HIVE,
  REGIONS,
  SHARE_ROLES,
  annualRevenue,
  formatEuro,
  sharedHosts,
} from '../lib/hives'

const steps = [
  { title: 'Le rucher', subtitle: 'Identité & nombre de ruches' },
  { title: "L'implantation", subtitle: 'Client & lieu d\u2019installation' },
  { title: "L'engagement", subtitle: 'Contrat 3 ans' },
]

const emptyForm = {
  name: '',
  site: '',
  client: '',
  region: REGIONS[0],
  placement: 'site',
  placementDetail: '',
  beekeeper: '',
  shareRole: '',
  hostHiveId: '',
  startDate: new Date().toISOString().slice(0, 10),
  hiveCount: 4,
  latitude: '',
  longitude: '',
  price: '',
}

const inputClass =
  'h-11 w-full rounded-xl border border-forest-100 bg-cream-50 px-3.5 text-sm text-ink-900 outline-none transition focus:ring-2 focus:ring-honey-400 focus:border-honey-400'
const labelClass = 'block text-sm font-medium text-ink-900/80 mb-1.5'

export default function AddHiveDialog({ onCreate, hives }) {
  const [open, setOpen] = useState(false)
  const [step, setStep] = useState(0)
  const [direction, setDirection] = useState(1)
  const [form, setForm] = useState(emptyForm)
  const [locating, setLocating] = useState(false)

  const placement = PLACEMENTS.find((p) => p.id === form.placement)
  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }))
  const hosts = sharedHosts(hives)

  const selectPlacement = (id) =>
    setForm((f) => ({
      ...f,
      placement: id,
      placementDetail: id === 'friche' ? '' : f.placementDetail,
      shareRole: id === 'partage' ? f.shareRole : '',
      hostHiveId: id === 'partage' ? f.hostHiveId : '',
      site: id === 'friche' ? FAREINS_SITE : f.site === FAREINS_SITE ? '' : f.site,
      region: id === 'friche' ? FAREINS_REGION : f.region,
      beekeeper: id === 'friche' ? FAREINS_BEEKEEPER : f.beekeeper === FAREINS_BEEKEEPER ? '' : f.beekeeper,
    }))

  const shareValid =
    form.placement !== 'partage' || form.shareRole === 'hote' || (form.shareRole === 'heberge' && form.hostHiveId.trim() !== '')

  const lat = form.latitude.trim() === '' ? null : Number(form.latitude.replace(',', '.'))
  const lng = form.longitude.trim() === '' ? null : Number(form.longitude.replace(',', '.'))
  const latValid = lat === null || (Number.isFinite(lat) && lat >= -90 && lat <= 90)
  const lngValid = lng === null || (Number.isFinite(lng) && lng >= -180 && lng <= 180)
  const coordsValid = latValid && lngValid && (lat === null) === (lng === null)

  const customPrice = form.price.trim() === '' ? null : Number(form.price.replace(',', '.').replace(/\s/g, ''))
  const priceValid = customPrice === null || (Number.isFinite(customPrice) && customPrice >= 0)
  const finalPrice = customPrice ?? annualRevenue(form.hiveCount)

  const locate = () => {
    if (!navigator.geolocation) return
    setLocating(true)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setForm((f) => ({ ...f, latitude: pos.coords.latitude.toFixed(6), longitude: pos.coords.longitude.toFixed(6) }))
        setLocating(false)
      },
      () => setLocating(false),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  const canContinue =
    (step === 0 && form.name.trim().length > 1) ||
    (step === 1 && form.client.trim().length > 1 && form.site.trim().length > 1 && coordsValid && shareValid) ||
    (step === 2 && priceValid)

  const reset = () => {
    setStep(0)
    setDirection(1)
    setForm({ ...emptyForm, startDate: new Date().toISOString().slice(0, 10) })
  }

  const close = () => {
    setOpen(false)
    setTimeout(reset, 300)
  }

  const submit = () => {
    if (!coordsValid || !priceValid || !shareValid) return
    onCreate({
      name: form.name.trim(),
      site: form.site.trim(),
      client: form.client.trim(),
      region: form.region,
      placement: form.placement,
      placementDetail: form.placementDetail.trim(),
      beekeeper: form.beekeeper.trim(),
      shareRole: form.placement === 'partage' ? form.shareRole : '',
      hostHiveId: form.placement === 'partage' && form.shareRole === 'heberge' ? form.hostHiveId : null,
      startDate: form.startDate,
      hiveCount: form.hiveCount,
      latitude: lat,
      longitude: lng,
      price: customPrice,
    })
    close()
  }

  const progress = ((step + 1) / steps.length) * 100

  return (
    <>
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => setOpen(true)}
        className="flex items-center gap-2 rounded-2xl bg-honey-500 px-4 py-2.5 text-sm font-semibold text-white hover:bg-honey-600 transition shadow-sm"
      >
        <SparkleIcon className="w-4 h-4" /> Ajouter une ruche
      </motion.button>

      <Modal open={open} onClose={close} maxWidth="max-w-lg">
        <div className="gradient-forest px-6 pb-7 pt-6 text-white rounded-t-3xl">
          <p className="text-xs uppercase tracking-[0.2em] opacity-70">
            Étape {step + 1} / {steps.length}
          </p>
          <h2 className="mt-1 text-2xl font-semibold" style={{ fontFamily: 'var(--font-display)' }}>
            {steps[step].title}
          </h2>
          <p className="text-sm opacity-75">{steps[step].subtitle}</p>

          <div className="mt-5 h-1.5 w-full overflow-hidden rounded-full bg-white/20">
            <motion.div
              className="gradient-honey h-full rounded-full"
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
            />
          </div>

          <div className="mt-4 flex items-center gap-2">
            {steps.map((s, i) => (
              <div
                key={s.title}
                className={`flex size-8 items-center justify-center rounded-full text-xs transition-colors duration-300 ${
                  i < step ? 'bg-honey-500 text-white' : i === step ? 'bg-white/20 ring-2 ring-honey-400' : 'bg-white/10 opacity-60'
                }`}
              >
                {i < step ? <CheckIcon className="w-4 h-4" /> : i + 1}
              </div>
            ))}
          </div>
        </div>

        <div className="min-h-[300px] px-6 py-6">
          <AnimatePresence mode="wait" initial={false} custom={direction}>
            <motion.div
              key={step}
              custom={direction}
              initial={{ opacity: 0, x: direction * 28 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: direction * -28 }}
              transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
              className="space-y-4"
            >
              {step === 0 && (
                <>
                  <div>
                    <label className={labelClass}>Nom du rucher</label>
                    <input
                      autoFocus
                      placeholder="Rucher des Tilleuls"
                      value={form.name}
                      onChange={(e) => set('name', e.target.value)}
                      className={inputClass}
                    />
                  </div>
                  <div>
                    <label className={labelClass}>Nombre de ruches installées · {form.hiveCount}</label>
                    <input
                      type="range"
                      min={1}
                      max={20}
                      step={1}
                      value={form.hiveCount}
                      onChange={(e) => set('hiveCount', Number(e.target.value))}
                      className="w-full accent-honey-500"
                    />
                    <p className="text-xs text-ink-900/50 mt-1">
                      Soit environ {(form.hiveCount * 40000).toLocaleString('fr-FR')} abeilles pollinisatrices (une colonie par
                      ruche).
                    </p>
                  </div>
                </>
              )}

              {step === 1 && (
                <>
                  <div>
                    <label className={labelClass}>Client</label>
                    <input
                      autoFocus
                      placeholder="Groupe Verdier"
                      value={form.client}
                      onChange={(e) => set('client', e.target.value)}
                      className={inputClass}
                    />
                  </div>

                  <div>
                    <label className={labelClass}>Lieu d'installation</label>
                    <div className="grid grid-cols-3 gap-2">
                      {PLACEMENTS.map((p) => (
                        <button
                          key={p.id}
                          type="button"
                          onClick={() => selectPlacement(p.id)}
                          className={`rounded-2xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                            form.placement === p.id
                              ? 'border-forest-700 bg-forest-100 text-forest-800'
                              : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                          }`}
                        >
                          {p.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  {form.placement === 'partage' && (
                    <div className="space-y-3 rounded-2xl border border-forest-100 bg-cream-50 p-3">
                      <div>
                        <label className={labelClass}>Votre rôle sur le rucher partagé</label>
                        <div className="grid grid-cols-2 gap-2">
                          {SHARE_ROLES.map((r) => (
                            <button
                              key={r.id}
                              type="button"
                              onClick={() =>
                                setForm((f) => ({ ...f, shareRole: r.id, hostHiveId: r.id === 'hote' ? '' : f.hostHiveId }))
                              }
                              className={`rounded-xl border px-3 py-2.5 text-center text-sm font-medium transition-all ${
                                form.shareRole === r.id
                                  ? 'border-forest-700 bg-forest-100 text-forest-800'
                                  : 'border-forest-100 bg-white text-ink-900/50 hover:border-forest-700/40'
                              }`}
                            >
                              {r.label}
                            </button>
                          ))}
                        </div>
                      </div>

                      {form.shareRole === 'heberge' &&
                        (hosts.length === 0 ? (
                          <p className="text-xs text-red-600">
                            Aucun rucher partagé hôte enregistré : créez d'abord le rucher hôte.
                          </p>
                        ) : (
                          <div>
                            <label className={labelClass}>Rucher hôte</label>
                            <select
                              value={form.hostHiveId}
                              onChange={(e) => set('hostHiveId', e.target.value)}
                              className={inputClass}
                            >
                              <option value="">Choisir un rucher partagé existant</option>
                              {hosts.map((h) => (
                                <option key={h.id} value={h.id}>
                                  {h.name} · {h.site}
                                </option>
                              ))}
                            </select>
                          </div>
                        ))}

                      {form.shareRole === '' && (
                        <p className="text-xs text-ink-900/50">
                          Indiquez si ce rucher accueille (hôte) ou est accueilli (hébergé).
                        </p>
                      )}
                    </div>
                  )}

                  {placement.needsAddress && (
                    <div>
                      <label className={labelClass}>Adresse exacte</label>
                      <input
                        placeholder={placement.addressPlaceholder}
                        value={form.placementDetail}
                        onChange={(e) => set('placementDetail', e.target.value)}
                        className={inputClass}
                      />
                    </div>
                  )}

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className={labelClass}>Commune / ville</label>
                      <input placeholder="Fareins (01)" value={form.site} onChange={(e) => set('site', e.target.value)} className={inputClass} />
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
                  </div>

                  <div>
                    <label className={labelClass}>Apiculteur partenaire</label>
                    <input
                      placeholder="Dominique Parriaud"
                      value={form.beekeeper}
                      onChange={(e) => set('beekeeper', e.target.value)}
                      className={inputClass}
                    />
                    {form.placement === 'friche' && <p className="text-xs text-ink-900/50 mt-1">Pré-rempli automatiquement pour Fareins.</p>}
                  </div>

                  <div>
                    <div className="flex items-center justify-between mb-1.5">
                      <label className="text-sm font-medium text-ink-900/80">Coordonnées GPS (optionnel)</label>
                      <button
                        type="button"
                        onClick={locate}
                        className="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-forest-700 hover:bg-forest-100 transition"
                      >
                        <PinIcon className="w-3.5 h-3.5" /> {locating ? 'Localisation…' : 'Position actuelle'}
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <input
                        inputMode="decimal"
                        placeholder="Latitude · 46.0512"
                        value={form.latitude}
                        onChange={(e) => set('latitude', e.target.value)}
                        className={inputClass}
                      />
                      <input
                        inputMode="decimal"
                        placeholder="Longitude · 4.7891"
                        value={form.longitude}
                        onChange={(e) => set('longitude', e.target.value)}
                        className={inputClass}
                      />
                    </div>
                    {!coordsValid && <p className="text-xs text-red-600 mt-1">Renseignez latitude et longitude valides (-90/90 et -180/180).</p>}
                    {coordsValid && lat !== null && lng !== null && (
                      <iframe
                        title="Aperçu de la position du rucher"
                        className="h-40 w-full rounded-xl border border-forest-100 mt-2"
                        loading="lazy"
                        src={`https://www.openstreetmap.org/export/embed.html?bbox=${lng - 0.01}%2C${lat - 0.008}%2C${lng + 0.01}%2C${lat + 0.008}&layer=mapnik&marker=${lat}%2C${lng}`}
                      />
                    )}
                  </div>
                </>
              )}

              {step === 2 && (
                <>
                  <div>
                    <label className={labelClass}>Date de début d'engagement</label>
                    <input type="date" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} className={inputClass} />
                  </div>

                  <div className="rounded-2xl border border-forest-100 bg-cream-50 p-4">
                    <p className="text-xs font-medium uppercase tracking-wider text-ink-900/50">Chiffre d'affaires annuel</p>
                    <p className="mt-1 text-3xl font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
                      {formatEuro(finalPrice)} HT
                    </p>
                    <p className="mt-1 text-xs text-ink-900/50">
                      Tarif de base : {form.hiveCount} ruche{form.hiveCount > 1 ? 's' : ''} × {formatEuro(PRICE_PER_HIVE)} HT / an ={' '}
                      {formatEuro(annualRevenue(form.hiveCount))}
                    </p>
                  </div>

                  <div>
                    <label className={labelClass}>Prix total facturé (€ HT / an)</label>
                    <input
                      inputMode="decimal"
                      placeholder={String(annualRevenue(form.hiveCount))}
                      value={form.price}
                      onChange={(e) => set('price', e.target.value)}
                      className={inputClass}
                    />
                    {priceValid ? (
                      <p className="text-xs text-ink-900/50 mt-1">Laissez vide pour appliquer le tarif de base, ou saisissez un prix remisé.</p>
                    ) : (
                      <p className="text-xs text-red-600 mt-1">Saisissez un montant positif valide.</p>
                    )}
                  </div>

                  <div className="rounded-2xl bg-honey-100 p-3 text-xs text-honey-600 font-medium">
                    Engagement de 3 ans · fin prévue le{' '}
                    {new Date(new Date(form.startDate).getTime() + 3 * 365.25 * 24 * 3600 * 1000).toLocaleDateString('fr-FR')}
                  </div>
                </>
              )}
            </motion.div>
          </AnimatePresence>
        </div>

        <div className="flex items-center justify-between gap-3 border-t border-forest-100 px-6 py-4">
          <button
            onClick={() => {
              setDirection(-1)
              setStep((s) => Math.max(0, s - 1))
            }}
            disabled={step === 0}
            className="flex items-center gap-1.5 rounded-xl px-4 py-2 text-sm font-medium text-ink-900/60 hover:bg-cream-50 transition disabled:opacity-30"
          >
            <ArrowLeftIcon className="w-4 h-4" /> Retour
          </button>
          {step < steps.length - 1 ? (
            <button
              disabled={!canContinue}
              onClick={() => {
                setDirection(1)
                setStep((s) => s + 1)
              }}
              className="flex items-center gap-1.5 rounded-xl bg-forest-800 px-4 py-2 text-sm font-medium text-white hover:bg-forest-700 transition disabled:opacity-40"
            >
              Continuer <ArrowRightIcon className="w-4 h-4" />
            </button>
          ) : (
            <button
              onClick={submit}
              disabled={!priceValid || !coordsValid}
              className="flex items-center gap-1.5 rounded-xl bg-honey-500 px-4 py-2 text-sm font-semibold text-white hover:bg-honey-600 transition disabled:opacity-40"
            >
              <CheckIcon className="w-4 h-4" /> Créer la ruche
            </button>
          )}
        </div>
      </Modal>
    </>
  )
}

function SparkleIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8" />
    </svg>
  )
}
function CheckIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M20 6 9 17l-5-5" />
    </svg>
  )
}
function ArrowLeftIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M19 12H5M12 19l-7-7 7-7" />
    </svg>
  )
}
function ArrowRightIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M5 12h14M12 5l7 7-7 7" />
    </svg>
  )
}
function PinIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <circle cx="12" cy="12" r="8" />
      <circle cx="12" cy="12" r="2" />
    </svg>
  )
}
