import type { ReactNode } from 'react'
import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom'
import { AuthProvider, useAuth } from './lib/auth'
import { canAccessPath } from './lib/rbac'
import { AdminLayout } from './components/AdminLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { PlacesPage } from './pages/PlacesPage'
import { AddPlacePage } from './pages/AddPlacePage'
import { VerificationsPage } from './pages/VerificationsPage'
import { ReportsPage } from './pages/ReportsPage'
import { ReviewsPage } from './pages/ReviewsPage'
import { UsersPage } from './pages/UsersPage'
import { UserDetailPage } from './pages/UserDetailPage'
import { ProvidersPage } from './pages/ProvidersPage'
import { ProviderDetailPage } from './pages/ProviderDetailPage'
import { ProviderVerificationPage } from './pages/ProviderVerificationPage'
import {
  DoctorsPage,
  TherapistsPage,
  CaregiversPage,
} from './pages/ProviderProfilesPage'
import { CategoriesPage } from './pages/CategoriesPage'
import { AccessibilityFeaturesPage } from './pages/AccessibilityFeaturesPage'
import { HomeHeroImagesPage } from './pages/HomeHeroImagesPage'
import { AnalyticsPage } from './pages/AnalyticsPage'
import { NotificationsPage } from './pages/NotificationsPage'
import { SettingsPage } from './pages/SettingsPage'
import { AdminsPage } from './pages/AdminsPage'
import { SystemLogsPage } from './pages/SystemLogsPage'
import { ContactSupportPage } from './pages/ContactSupportPage'
import { EmergencySosPage } from './pages/EmergencySosPage'
import { AppointmentsOpsPage } from './pages/AppointmentsOpsPage'
import { TeleRehabAdminPage } from './pages/TeleRehabAdminPage'
import { RehabEducationAdminPage } from './pages/RehabEducationAdminPage'
import { EducationProgramsAdminPage } from './pages/EducationProgramsAdminPage'
import { TrustSafetyOpsPage } from './pages/TrustSafetyOpsPage'
import { AiOpsPage } from './pages/AiOpsPage'
import { BillingOpsPage } from './pages/BillingOpsPage'
import { TeleRehabOpsPage } from './pages/TeleRehabOpsPage'
import { CaregiverOpsPage } from './pages/CaregiverOpsPage'
import { ReferenceDataPage } from './pages/ReferenceDataPage'
import { CommunityOpsPage } from './pages/CommunityOpsPage'
import { TravelAssistanceOpsPage } from './pages/TravelAssistanceOpsPage'
import { BookingsOpsPage } from './pages/BookingsOpsPage'
import { JobsOpsPage } from './pages/JobsOpsPage'
import { BenefitsOpsPage } from './pages/BenefitsOpsPage'
import { LegalRightsAdminPage } from './pages/LegalRightsAdminPage'
import { AssistiveTechAdminPage } from './pages/AssistiveTechAdminPage'
import { PassportAdminPage } from './pages/PassportAdminPage'

function Guard({ children }: { children: ReactNode }) {
  const { user, allowed, loading } = useAuth()
  if (loading) {
    return (
      <div className="login-page">
        <div className="login-card">Loading…</div>
      </div>
    )
  }
  if (!user) return <Navigate to="/login" replace />
  if (!allowed) return <Navigate to="/login" replace />
  return children
}

function RoleGuard() {
  const { roles, admin } = useAuth()
  const { pathname } = useLocation()
  if (!canAccessPath(pathname, roles, admin)) {
    return (
      <div className="card" style={{ margin: 24 }}>
        <h2 style={{ marginTop: 0 }}>Access restricted</h2>
        <p className="muted">
          Your role does not include this module. Ask a Super Admin to update
          access on the Admins page.
        </p>
        <a className="btn" href="/">
          Back to Dashboard
        </a>
      </div>
    )
  }
  return <Outlet />
}

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <Guard>
              <AdminLayout />
            </Guard>
          }
        >
          <Route element={<RoleGuard />}>
            <Route index element={<DashboardPage />} />
            <Route path="places" element={<PlacesPage />} />
            <Route path="places/new" element={<AddPlacePage />} />
            <Route path="verifications" element={<VerificationsPage />} />
            <Route path="reports" element={<ReportsPage />} />
            <Route path="reviews" element={<ReviewsPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="users/:id" element={<UserDetailPage />} />
            <Route path="providers" element={<ProvidersPage />} />
            <Route path="providers/:id" element={<ProviderDetailPage />} />
            <Route
              path="provider-verifications"
              element={<ProviderVerificationPage />}
            />
            <Route path="doctors" element={<DoctorsPage />} />
            <Route path="therapists" element={<TherapistsPage />} />
            <Route path="caregivers" element={<CaregiversPage />} />
            <Route path="emergency" element={<EmergencySosPage />} />
            <Route path="appointments" element={<AppointmentsOpsPage />} />
            <Route path="tele-rehab" element={<TeleRehabAdminPage />} />
            <Route path="tele-rehab-ops" element={<TeleRehabOpsPage />} />
            <Route path="rehab-education" element={<RehabEducationAdminPage />} />
            <Route
              path="education-programs"
              element={<EducationProgramsAdminPage />}
            />
            <Route path="legal-rights" element={<LegalRightsAdminPage />} />
            <Route path="assistive-tech" element={<AssistiveTechAdminPage />} />
            <Route path="passport-admin" element={<PassportAdminPage />} />
            <Route path="trust-safety" element={<TrustSafetyOpsPage />} />
            <Route path="ai-ops" element={<AiOpsPage />} />
            <Route path="billing" element={<BillingOpsPage />} />
            <Route path="caregiver-ops" element={<CaregiverOpsPage />} />
            <Route path="reference-data" element={<ReferenceDataPage />} />
            <Route path="community" element={<CommunityOpsPage />} />
            <Route path="bookings" element={<TravelAssistanceOpsPage />} />
            <Route path="booking-ops" element={<BookingsOpsPage />} />
            <Route path="jobs" element={<JobsOpsPage />} />
            <Route path="benefits" element={<BenefitsOpsPage />} />
            <Route path="categories" element={<CategoriesPage />} />
            <Route path="accessibility" element={<AccessibilityFeaturesPage />} />
            <Route path="home-hero" element={<HomeHeroImagesPage />} />
            <Route path="analytics" element={<AnalyticsPage />} />
            <Route path="notifications" element={<NotificationsPage />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="admins" element={<AdminsPage />} />
            <Route path="logs" element={<SystemLogsPage />} />
            <Route path="support" element={<ContactSupportPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AuthProvider>
  )
}
