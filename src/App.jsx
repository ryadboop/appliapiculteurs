import { Routes, Route } from 'react-router-dom'
import { useAuth } from './hooks/useAuth'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import HistoriquePage from './pages/HistoriquePage'
import AdminPage from './pages/AdminPage'

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
    <Routes>
      <Route path="/" element={<DashboardPage />} />
      <Route path="/historique" element={<HistoriquePage />} />
      <Route path="/admin" element={<AdminPage />} />
      <Route path="*" element={<DashboardPage />} />
    </Routes>
  )
}
