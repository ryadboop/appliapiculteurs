import { useId } from 'react'
import { motion } from 'framer-motion'

const HEX_POINTS = '100,50 75,93.3 25,93.3 0,50 25,6.7 75,6.7'

function pourcentageEngagement(dateInstallation) {
  if (!dateInstallation) return 0
  const debut = new Date(dateInstallation)
  const maintenant = new Date()
  const dureeTotaleMs = 3 * 365.25 * 24 * 60 * 60 * 1000
  const ecouleMs = maintenant - debut
  return Math.max(0, Math.min(100, (ecouleMs / dureeTotaleMs) * 100))
}

function libelle(statut, pct) {
  if (statut === 'a_installer') return 'À installer'
  if (statut === 'renouvellement') return 'Renouvellement à prévoir'
  return `En cours — ${Math.round(pct)}% de l'engagement 3 ans`
}

export default function EngagementBadge({ dateInstallation, statut, size = 36 }) {
  const clipId = useId()
  const pct = pourcentageEngagement(dateInstallation)

  const fillColor =
    statut === 'renouvellement'
      ? 'var(--color-honey-500)'
      : statut === 'a_installer'
        ? 'var(--color-forest-100)'
        : pct > 75
          ? 'var(--color-honey-400)'
          : 'var(--color-forest-600)'

  return (
    <span className="inline-flex items-center" title={libelle(statut, pct)}>
      <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true">
        <defs>
          <clipPath id={clipId}>
            <polygon points={HEX_POINTS} />
          </clipPath>
        </defs>
        <polygon points={HEX_POINTS} fill="var(--color-mist-100)" />
        <motion.rect
          x="0"
          width="100"
          fill={fillColor}
          clipPath={`url(#${clipId})`}
          initial={{ y: 100, height: 0 }}
          animate={{ y: 100 - pct, height: pct }}
          transition={{ duration: 0.9, ease: 'easeOut' }}
        />
        <polygon
          points={HEX_POINTS}
          fill="none"
          stroke="var(--color-forest-700)"
          strokeWidth="3"
          opacity="0.35"
        />
      </svg>
      <span className="sr-only">{libelle(statut, pct)}</span>
    </span>
  )
}
