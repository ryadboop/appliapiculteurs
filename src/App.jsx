import { useAuth } from './hooks/useAuth'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'

export default function App() {
  const { session, profile, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center text-ink-900/40 text-sm">
        Chargement…
      </div>
    )
  }

  if (!session || !profile) {
    return <LoginPage />
  }

  return <DashboardPage />
}
