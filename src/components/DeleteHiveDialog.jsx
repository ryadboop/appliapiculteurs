import { useState } from 'react'
import Modal from './Modal'
import { engagementCompleted, engagementEnd, monthsRemaining } from '../lib/hives'

export default function DeleteHiveDialog({ hive, onDelete }) {
  const [open, setOpen] = useState(false)
  const early = !engagementCompleted(hive.startDate)

  return (
    <>
      <button
        type="button"
        aria-label={`Supprimer ${hive.name}`}
        onClick={(e) => {
          e.stopPropagation()
          setOpen(true)
        }}
        className="flex size-9 items-center justify-center rounded-xl text-ink-900/40 hover:bg-red-50 hover:text-red-600 transition"
      >
        <TrashIcon className="w-4 h-4" />
      </button>

      <Modal open={open} onClose={() => setOpen(false)} maxWidth="max-w-md">
        <div className="p-6">
          <div className="flex items-center gap-2 mb-2">
            {early && <AlertIcon className="w-5 h-5 text-honey-600" />}
            <h3 className="text-lg font-semibold text-ink-900" style={{ fontFamily: 'var(--font-display)' }}>
              {early ? "Rupture anticipée de l'engagement" : `Supprimer ${hive.name} ?`}
            </h3>
          </div>
          <p className="text-sm text-ink-900/60">
            {early ? (
              <>
                <strong className="text-ink-900">{hive.name}</strong> est encore sous engagement de 3 ans : il reste{' '}
                <strong className="text-ink-900">{monthsRemaining(hive.startDate)} mois</strong> (fin prévue le{' '}
                {engagementEnd(hive.startDate).toLocaleDateString('fr-FR')}). La suppression retirera son chiffre d'affaires des
                indicateurs. Cette action est définitive.
              </>
            ) : (
              "L'engagement de 3 ans est arrivé à son terme. Le rucher sera retiré du suivi. Cette action est définitive."
            )}
          </p>
          <div className="flex justify-end gap-2 mt-6">
            <button
              onClick={() => setOpen(false)}
              className="rounded-xl px-4 py-2 text-sm font-medium text-ink-900/60 hover:bg-cream-50 transition"
            >
              Annuler
            </button>
            <button
              onClick={() => {
                onDelete()
                setOpen(false)
              }}
              className="rounded-xl bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 transition"
            >
              {early ? 'Supprimer malgré tout' : 'Supprimer'}
            </button>
          </div>
        </div>
      </Modal>
    </>
  )
}

function TrashIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m3 0-1 14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2L4 6h16Z" />
    </svg>
  )
}
function AlertIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" {...props}>
      <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z" />
      <path d="M12 9v4M12 17h.01" />
    </svg>
  )
}
