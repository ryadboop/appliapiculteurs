import { Routes, Route, useLocation } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { useAuth } from './hooks/useAuth'
import Navbar from './components/Navbar'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import HistoriquePage from './pages/HistoriquePage'
import AdminPage from './pages/AdminPage'
import PassagesPage from './pages/PassagesPage'
import AnimationsPage from './pages/AnimationsPage'

function AnimatedRoutes() {
  const location = useLocation()
  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.div
        key={location.pathname}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -10 }}
        transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
      >
        <Routes location={location}>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/historique" element={<HistoriquePage />} />
          <Route path="/admin" element={<AdminPage />} />
          <Route path="/passages" element={<PassagesPage />} />
          <Route path="/animations" element={<AnimationsPage />} />
          <Route path="*" element={<DashboardPage />} />
        </Routes>
      </motion.div>
    </AnimatePresence>
  )
}

export default function App() {
  const { session, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center text-ink-900/40 text-sm">
        Chargement…
      </div>
    )
  }

  if (!session) {
    return <LoginPage />
  }

  return (
    <>
      <Navbar />
      <AnimatedRoutes />
    </>
  )
}
