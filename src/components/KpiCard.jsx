import { motion } from 'framer-motion'

export default function KpiCard({ icon, label, sublabel, children, accent = 'forest' }) {
  const iconBg = accent === 'honey' ? 'bg-honey-500' : 'bg-forest-800'

  return (
    <motion.div
      whileHover={{ y: -3, boxShadow: '0 16px 40px -16px rgba(20,67,43,0.28)' }}
      transition={{ type: 'spring', stiffness: 300, damping: 22 }}
      className="glass-card rounded-2xl p-4 sm:p-5 min-w-0"
    >
      <div className={`w-8 h-8 rounded-lg ${iconBg} text-white flex items-center justify-center mb-3 shrink-0 [&>svg]:w-4 [&>svg]:h-4`}>
        {icon}
      </div>
      <p className="text-[10px] sm:text-xs font-semibold tracking-wide text-ink-900/50 uppercase mb-1 truncate">{label}</p>
      <p className="font-mono text-xl sm:text-2xl font-semibold text-ink-900 truncate">{children}</p>
      {sublabel && <p className="text-xs text-ink-900/50 mt-1 truncate">{sublabel}</p>}
    </motion.div>
  )
}
