// Statuts possibles d'un rucher.
export const HIVE_STATUS = {
  active: 'active',
  pending: 'pending',
  renewal: 'renewal',
}

export const statusLabel = {
  active: 'En cours',
  pending: 'À installer',
  renewal: 'Renouvellement',
}

export const PLACEMENTS = [
  { id: 'friche', label: 'Fareins', needsAddress: false },
  {
    id: 'site',
    label: 'Sur site',
    needsAddress: true,
    addressPlaceholder: '12 rue des Acacias, 69003 Lyon',
  },
  {
    id: 'partage',
    label: 'Rucher partagé',
    needsAddress: true,
    addressPlaceholder: 'Rucher des Dombes, 01330 Villars-les-Dombes',
  },
]

export const placementLabel = {
  friche: 'Fareins',
  site: 'Sur site',
  partage: 'Rucher partagé',
}

export const SHARE_ROLES = [
  { id: 'hote', label: 'Hôte' },
  { id: 'heberge', label: 'Hébergé' },
]

export const shareRoleLabel = {
  '': '',
  hote: 'Hôte',
  heberge: 'Hébergé',
}

export const REGIONS = [
  'Auvergne-Rhône-Alpes',
  'Occitanie',
  'Bretagne',
  'Nouvelle-Aquitaine',
  'Grand Est',
  "Provence-Alpes-Côte d'Azur",
]

export const FAREINS_SITE = 'Fareins (01)'
export const FAREINS_REGION = 'Auvergne-Rhône-Alpes'
export const FAREINS_BEEKEEPER = 'Dominique Parriaud'

/** Prix public d'une ruche : 1 440 € HT / an. */
export const PRICE_PER_HIVE = 1440

export function annualRevenue(hiveCount) {
  return hiveCount * PRICE_PER_HIVE
}

/** CA retenu : prix personnalisé s'il existe, sinon tarif de base. */
export function effectiveRevenue(hiveCount, price) {
  return price === null || price === undefined || Number.isNaN(price) ? annualRevenue(hiveCount) : price
}

/** Ruchers partagés hôtes pouvant héberger d'autres ruchers. */
export function sharedHosts(hives, excludeId) {
  return hives.filter((h) => h.placement === 'partage' && h.shareRole === 'hote' && h.id !== excludeId)
}

const YEAR_MS = 365.25 * 24 * 60 * 60 * 1000
const DAY_MS = 24 * 60 * 60 * 1000

function today() {
  return new Date(Math.floor(Date.now() / DAY_MS) * DAY_MS)
}

/** Progression de l'engagement 3 ans, 0 → 1. */
export function engagementProgress(startDate, now = today()) {
  const start = new Date(startDate).getTime()
  const elapsed = now.getTime() - start
  return Math.min(1, Math.max(0, elapsed / (3 * YEAR_MS)))
}

export function monthsRemaining(startDate, now = today()) {
  const end = new Date(startDate).getTime() + 3 * YEAR_MS
  return Math.max(0, Math.round((end - now.getTime()) / (YEAR_MS / 12)))
}

/** Date de fin de l'engagement 3 ans. */
export function engagementEnd(startDate) {
  return new Date(new Date(startDate).getTime() + 3 * YEAR_MS)
}

export function engagementCompleted(startDate, now = today()) {
  return engagementEnd(startDate).getTime() <= now.getTime()
}

/** Statut calculé : à installer, en cours, ou renouvellement. */
export function computeStatus(startDate, now = today()) {
  if (new Date(startDate).getTime() > now.getTime()) return 'pending'
  return engagementCompleted(startDate, now) ? 'renewal' : 'active'
}

export function formatEuro(value) {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 0,
  }).format(value ?? 0)
}

export function formatCoords(lat, lng) {
  if (lat == null || lng == null) return null
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`
}
