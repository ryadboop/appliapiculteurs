import { motion } from 'framer-motion'

export default function KpiCard({ icon, label, sublabel, children, accent = 'forest' }) {
  const iconBg = accent === 'honey' ? 'bg-honey-500' : 'bg-forest-800'

  return (
    <motion.div
      whileHover={{ y: -3, boxShadow: '0 16px 40px -16px rgba(20,67,43,0.28)' }}
      transition={{ type: 'spring', stiffness: 300, damping: 22 }}
      className="glass-card rounded-3xl p-6"
    >
      <div className={`w-10 h-10 rounded-xl ${iconBg} text-white flex items-center justify-center mb-4`}>
        {icon}
      </div>
      <p className="text-xs font-semibold tracking-wide text-ink-900/50 uppercase mb-1">{label}</p>
      <p className="font-mono text-3xl font-semibold text-ink-900">{children}</p>
      {sublabel && <p className="text-sm text-ink-900/50 mt-1">{sublabel}</p>}
    </motion.div>
  )
}
