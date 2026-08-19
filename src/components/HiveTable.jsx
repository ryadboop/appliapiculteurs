import { AnimatePresence, motion } from 'framer-motion'
import DeleteHiveDialog from './DeleteHiveDialog'
import EngagementRing from './EngagementRing'
import { engagementProgress, formatEuro, monthsRemaining, placementLabel, statusLabel } from '../lib/hives'

const statusStyles = {
  active: 'bg-forest-100 text-forest-800',
  pending: 'bg-honey-100 text-honey-600',
  renewal: 'bg-honey-500 text-white',
}

export default function HiveTable({ hives, isAdmin, myBeekeeperId, onDelete, onSelect }) {
  const cols = isAdmin ? '1.6fr 1.2fr 1fr 1.4fr 0.9fr' : '1.6fr 1.2fr 1.4fr 0.9fr'

  return (
    <div className="glass-card overflow-hidden rounded-3xl">
      <div
        className="hidden md:grid gap-4 border-b border-forest-800/10 px-6 py-3 text-xs font-semibold uppercase tracking-wider text-ink-900/40"
        style={{ gridTemplateColumns: cols }}
      >
        <span>Rucher</span>
        <span>Client</span>
        {isAdmin && <span>CA annuel</span>}
        <span>Engagement 3 ans</span>
        <span className="text-right">Statut</span>
      </div>

      <div className="divide-y divide-forest-800/8">
        <AnimatePresence initial={false} mode="popLayout">
          {hives.map((hive, i) => {
            const progress = engagementProgress(hive.startDate)
            return (
              <motion.div
                key={hive.id}
                layout
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.97 }}
                transition={{ duration: 0.3, delay: Math.min(i * 0.03, 0.2) }}
                onClick={() => onSelect?.(hive)}
                role="button"
                tabIndex={0}
                className="group cursor-pointer px-6 py-4 transition-colors hover:bg-mist-100/50"
              >
                {/* Version mobile */}
                <div className="md:hidden">
                  <RowMobile hive={hive} progress={progress} isAdmin={isAdmin} onDelete={onDelete} />
                </div>

                {/* Version bureau */}
                <div className="hidden md:grid gap-4 items-center" style={{ gridTemplateColumns: cols }}>
                  <div className="flex items-center gap-3">
                    <span className="flex size-9 items-center justify-center rounded-xl bg-forest-100 text-forest-800 transition-transform group-hover:scale-110">
                      <HexIcon className="w-4 h-4" />
                    </span>
                    <div className="leading-tight">
                      <p className="font-semibold text-ink-900 flex items-center gap-1.5">
                        {hive.name}
                        {myBeekeeperId && hive.beekeeperId === myBeekeeperId && (
                          <span className="text-[10px] font-semibold uppercase tracking-wide bg-honey-100 text-honey-600 px-1.5 py-0.5 rounded-full">
                            Vous
                          </span>
                        )}
                      </p>
                      <p className="text-xs text-ink-900/50">
                        {hive.site} · {hive.hiveCount} ruche{hive.hiveCount > 1 ? 's' : ''} · {placementLabel[hive.placement]}
                      </p>
                    </div>
                  </div>

                  <div className="text-sm">
                    <p className="text-ink-900">{hive.client}</p>
                    <p className="text-xs text-ink-900/50">{hive.beekeeperName ? `Apiculteur · ${hive.beekeeperName}` : hive.region}</p>
                  </div>

                  {isAdmin && (
                    <p className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-mono)' }}>
                      {formatEuro(hive.revenue)}
                    </p>
                  )}

                  <EngagementRing
                    progress={progress}
                    size={44}
                    label={`${monthsRemaining(hive.startDate)} mois restants`}
                    sublabel={`Depuis le ${new Date(hive.startDate).toLocaleDateString('fr-FR')}`}
                  />

                  <div className="flex items-center gap-1 justify-end" onClick={(e) => e.stopPropagation()}>
                    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${statusStyles[hive.status]}`}>
                      {statusLabel[hive.status]}
                    </span>
                    {isAdmin && <DeleteHiveDialog hive={hive} onDelete={() => onDelete(hive.id)} />}
                  </div>
                </div>
              </motion.div>
            )
          })}
        </AnimatePresence>

        {hives.length === 0 && (
          <p className="px-6 py-14 text-center text-sm text-ink-900/50">
            Aucune ruche pour le moment · ajoutez votre première ruche pour démarrer.
          </p>
        )}
      </div>
    </div>
  )
}

function RowMobile({ hive, progress, isAdmin, onDelete }) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="flex size-9 items-center justify-center rounded-xl bg-forest-100 text-forest-800">
            <HexIcon className="w-4 h-4" />
          </span>
          <div className="leading-tight">
            <p className="font-semibold text-ink-900">{hive.name}</p>
            <p className="text-xs text-ink-900/50">{hive.site}</p>
          </div>
        </div>
        <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${statusStyles[hive.status]}`}>
          {statusLabel[hive.status]}
        </span>
      </div>
      <div className="flex items-center justify-between">
        <EngagementRing progress={progress} size={36} />
        <div className="text-right">
          {isAdmin && (
            <p className="font-semibold text-ink-900" style={{ fontFamily: 'var(--font-mono)' }}>
              {formatEuro(hive.revenue)}
            </p>
          )}
          <p className="text-xs text-ink-900/50">{hive.client}</p>
        </div>
      </div>
      {isAdmin && (
        <div className="flex justify-end" onClick={(e) => e.stopPropagation()}>
          <DeleteHiveDialog hive={hive} onDelete={() => onDelete(hive.id)} />
        </div>
      )}
    </div>
  )
}

function HexIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M12 2 3 7v10l9 5 9-5V7z" />
    </svg>
  )
}
