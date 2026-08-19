import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'

export default function EngagementRing({ progress, size = 48, label, sublabel }) {
  const stroke = size >= 80 ? 8 : 5
  const r = (size - stroke) / 2
  const c = 2 * Math.PI * r
  const pct = Math.round(progress * 100)
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])

  return (
    <div className="flex items-center gap-3">
      <div className="relative shrink-0" style={{ width: size, height: size }}>
        <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth={stroke} className="stroke-forest-100" />
          {mounted && (
            <motion.circle
              cx={size / 2}
              cy={size / 2}
              r={r}
              fill="none"
              strokeWidth={stroke}
              strokeLinecap="round"
              className={pct >= 80 ? 'stroke-honey-500' : 'stroke-forest-700'}
              strokeDasharray={c}
              initial={{ strokeDashoffset: c }}
              animate={{ strokeDashoffset: c - c * progress }}
              transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
            />
          )}
        </svg>
        <span
          className="absolute inset-0 flex items-center justify-center font-semibold text-ink-900"
          style={{ fontSize: size / 4, fontFamily: 'var(--font-display)' }}
        >
          {pct}%
        </span>
      </div>
      {(label || sublabel) && (
        <div className="leading-tight">
          {label && <p className="text-sm font-semibold text-ink-900">{label}</p>}
          {sublabel && <p className="text-xs text-ink-900/50">{sublabel}</p>}
        </div>
      )}
    </div>
  )
}
