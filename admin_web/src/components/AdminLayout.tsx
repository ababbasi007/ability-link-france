import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../lib/auth'
import { canAccessPath } from '../lib/rbac'
import { useI18n } from '../i18n'
import {
  fetchPlaceReports,
  fetchPlaceSubmissions,
  fetchSosAlerts,
  fetchVerificationRequests,
  ADMIN_ROLE_LABELS,
} from '../lib/data'
import {
  IconAccessibility,
  IconBell,
  IconBriefcase,
  IconChart,
  IconChevronDown,
  IconFlag,
  IconGraduation,
  IconGrid,
  IconHeadset,
  IconMapPin,
  IconMenu,
  IconMessage,
  IconSearch,
  IconSettings,
  IconShieldCheck,
  IconUser,
  IconUsers,
  IconCalendar,
  IconHeart,
  IconFileText,
  IconLock,
  IconCreditCard,
  IconLayers,
  IconUpload,
  IconStar,
} from './icons'

type NavItem = {
  to: string
  label: string
  icon: ReactNode
  end?: boolean
  badgeKey?: 'subs' | 'reports' | 'sos' | 'providerVerify'
}

type NavSection = {
  id: string
  label?: string
  items: NavItem[]
}

/** Mockup IA — maps to existing admin routes. */
const NAV_SECTIONS: NavSection[] = [
  {
    id: 'top',
    items: [{ to: '/', label: 'Dashboard', icon: <IconGrid />, end: true }],
  },
  {
    id: 'people',
    label: 'People',
    items: [
      { to: '/users', label: 'Users', icon: <IconUsers /> },
      { to: '/providers', label: 'Providers', icon: <IconBriefcase /> },
      { to: '/caregivers', label: 'Caregivers', icon: <IconHeart /> },
    ],
  },
  {
    id: 'platform',
    label: 'Platform',
    items: [
      { to: '/doctors', label: 'Services', icon: <IconLayers /> },
      { to: '/places', label: 'Ability Map', icon: <IconMapPin /> },
      { to: '/tele-rehab', label: 'Tele Rehab', icon: <IconHeadset /> },
      { to: '/appointments', label: 'Tele Health', icon: <IconCalendar /> },
      { to: '/jobs', label: 'Jobs', icon: <IconBriefcase /> },
      { to: '/education-programs', label: 'Education', icon: <IconGraduation /> },
      { to: '/bookings', label: 'Tourism', icon: <IconMapPin /> },
      { to: '/assistive-tech', label: 'Assistive Technology', icon: <IconAccessibility /> },
      { to: '/community', label: 'Community', icon: <IconMessage /> },
      { to: '/benefits', label: 'Benefits', icon: <IconGraduation /> },
      { to: '/legal-rights', label: 'Rights & Legal', icon: <IconFileText /> },
    ],
  },
  {
    id: 'content',
    label: 'Content',
    items: [
      { to: '/tele-rehab', label: 'Exercises', icon: <IconHeart /> },
      { to: '/legal-rights', label: 'Articles', icon: <IconFileText /> },
      { to: '/home-hero', label: 'Videos', icon: <IconUpload /> },
      { to: '/rehab-education', label: 'Programs', icon: <IconLayers /> },
      { to: '/reference-data', label: 'Assessments', icon: <IconStar /> },
    ],
  },
  {
    id: 'operations',
    label: 'Operations',
    items: [
      { to: '/booking-ops', label: 'Bookings', icon: <IconCalendar /> },
      { to: '/billing', label: 'Payments', icon: <IconCreditCard /> },
      { to: '/notifications', label: 'Notifications', icon: <IconBell /> },
      { to: '/analytics', label: 'Reports & Analytics', icon: <IconChart />, badgeKey: 'reports' },
      { to: '/reports', label: 'Moderation Queue', icon: <IconFlag /> },
      {
        to: '/verifications',
        label: 'Place Verification',
        icon: <IconShieldCheck />,
        badgeKey: 'subs',
      },
      {
        to: '/provider-verifications',
        label: 'Provider Verification',
        icon: <IconUser />,
        badgeKey: 'providerVerify',
      },
    ],
  },
  {
    id: 'system',
    label: 'System',
    items: [
      { to: '/settings', label: 'Settings', icon: <IconSettings /> },
      { to: '/support', label: 'Help & Support', icon: <IconHeadset /> },
      { to: '/admins', label: 'Admins', icon: <IconLock /> },
      { to: '/passport-admin', label: 'Passport Admin', icon: <IconLock /> },
    ],
  },
]

function sectionHasActive(section: NavSection, pathname: string): boolean {
  return section.items.some((item) => {
    if (item.end) return pathname === item.to
    if (item.to === '/') return pathname === '/'
    return pathname === item.to || pathname.startsWith(`${item.to}/`)
  })
}

function searchPlaceholderFor(pathname: string): string {
  if (pathname === '/' || pathname === '') return 'Search users, providers, services, bookings...'
  if (pathname.startsWith('/providers')) return 'Search providers, services, locations...'
  if (pathname.startsWith('/caregivers')) return 'Search caregivers, locations, skills...'
  if (pathname.startsWith('/users')) return 'Search users, providers, services, bookings...'
  if (pathname.startsWith('/places')) return 'Search places, locations, categories...'
  if (pathname.startsWith('/jobs')) return 'Search jobs, employers, locations, skills...'
  if (pathname.startsWith('/education')) return 'Search courses, institutions, skills...'
  if (pathname.startsWith('/appointments')) return 'Search patients, doctors, specialties...'
  if (pathname.startsWith('/tele-rehab')) return 'Search patients, therapists, sessions...'
  if (pathname.startsWith('/bookings')) return 'Search destinations, hotels, attractions...'
  if (pathname.startsWith('/booking-ops')) return 'Search services, therapists, programs or locations...'
  if (pathname.startsWith('/billing')) return 'Search services, bookings, or transactions...'
  if (pathname.startsWith('/notifications')) return 'Search notifications, bookings, messages...'
  if (pathname.startsWith('/settings')) return 'Search settings, account, privacy, notifications...'
  if (pathname.startsWith('/support')) return 'Search help articles, FAQs, or type your question...'
  if (pathname.startsWith('/community')) return 'Search users, posts, groups, reports...'
  if (pathname.startsWith('/benefits')) return 'Search benefits, categories, countries...'
  if (pathname.startsWith('/legal-rights')) return 'Search laws, articles, countries, topics...'
  if (pathname.startsWith('/assistive-tech')) return 'Search assistive devices, brands, or keywords...'
  if (pathname.startsWith('/home-hero')) return 'Search videos, topics or keywords...'
  if (pathname.startsWith('/rehab-education')) return 'Search programs, skills, locations or keywords...'
  if (pathname.startsWith('/reference-data')) return 'Search assessments, skills, health, accessibility or keywords...'
  if (pathname.startsWith('/analytics') || pathname.startsWith('/reports'))
    return 'Search reports, users, services, or keywords...'
  return 'Search Ability Link admin...'
}

export function AdminLayout() {
  const { user, admin, roles, logout } = useAuth()
  const { locale, setLocale, t } = useI18n()
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [badges, setBadges] = useState({
    subs: 0,
    reports: 0,
    sos: 0,
    providerVerify: 0,
  })
  const [openSections, setOpenSections] = useState<Record<string, boolean>>(() => {
    const init: Record<string, boolean> = {}
    for (const s of NAV_SECTIONS) init[s.id] = true
    return init
  })

  const visibleSections = useMemo(() => {
    return NAV_SECTIONS.map((section) => ({
      ...section,
      items: section.items.filter((item) => canAccessPath(item.to, roles, admin)),
    })).filter((section) => section.items.length > 0)
  }, [roles, admin])

  useEffect(() => {
    for (const s of visibleSections) {
      if (sectionHasActive(s, location.pathname)) {
        setOpenSections((prev) => (prev[s.id] ? prev : { ...prev, [s.id]: true }))
      }
    }
  }, [location.pathname, visibleSections])

  useEffect(() => {
    void (async () => {
      try {
        const [subs, reports, sos, verify] = await Promise.all([
          fetchPlaceSubmissions(100),
          fetchPlaceReports(100),
          fetchSosAlerts(100),
          fetchVerificationRequests(100),
        ])
        const openReports = reports.filter(
          (r) => r.status === 'open' || r.status === 'inReview' || !r.status,
        ).length
        const openSos = sos.filter((r) => String(r.status ?? 'open') === 'open').length
        const pendingVerify = verify.filter((v) => {
          const s = String(v.status ?? 'pending').toLowerCase()
          return s === 'pending' || s === 'needsinfo' || s === 'needs_info' || s === 'more_info'
        }).length
        setBadges({
          subs: subs.length,
          reports: openReports,
          sos: openSos,
          providerVerify: pendingVerify,
        })
      } catch {
        /* ignore */
      }
    })()
  }, [])

  const displayName =
    user?.displayName?.trim() ||
    user?.email?.split('@')[0]?.replace(/\./g, ' ') ||
    'Admin User'
  const roleLabel = admin
    ? 'Administrator'
    : roles.length
      ? roles.map((r) => ADMIN_ROLE_LABELS[r]).join(', ')
      : 'Moderator'
  const avatar =
    user?.photoURL ||
    `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(user?.uid ?? 'admin')}`

  const badgeCount = (key?: NavItem['badgeKey']) => {
    if (!key) return undefined
    return badges[key]
  }

  return (
    <div className={`app-shell${sidebarOpen ? '' : ' sidebar-collapsed'}`}>
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark" aria-hidden>
            AL
          </div>
          <div className="brand-text">
            <strong>{t('app.brand')}</strong>
            <span>Access · Support · Opportunity</span>
          </div>
        </div>

        <nav className="nav-list" aria-label="Admin">
          {visibleSections.map((section) => {
            const open = openSections[section.id] !== false
            return (
              <div key={section.id} className="nav-section">
                {section.label ? (
                  <button
                    type="button"
                    className="nav-section-toggle"
                    aria-expanded={open}
                    onClick={() =>
                      setOpenSections((prev) => ({
                        ...prev,
                        [section.id]: !open,
                      }))
                    }
                  >
                    <span>{section.label}</span>
                    <IconChevronDown
                      className={`nav-section-chevron${open ? ' open' : ''}`}
                      width={14}
                      height={14}
                    />
                  </button>
                ) : null}
                {open || !section.label ? (
                  <div className="nav-section-items">
                    {section.items.map((item) => {
                      const count = badgeCount(item.badgeKey)
                      return (
                        <NavLink
                          key={`${section.id}-${item.to}-${item.label}`}
                          to={item.to}
                          end={item.end}
                          className={({ isActive }) =>
                            `nav-link${isActive ? ' active' : ''}`
                          }
                        >
                          <span className="nav-link-main">
                            <span className="nav-icon">{item.icon}</span>
                            <span>{item.label}</span>
                          </span>
                          {count != null && count > 0 ? (
                            <span className="badge">{count > 99 ? '99+' : count}</span>
                          ) : null}
                        </NavLink>
                      )
                    })}
                  </div>
                ) : null}
              </div>
            )
          })}
        </nav>

        <div className="sidebar-help">
          <div className="sidebar-help-icon" aria-hidden>
            <IconHeadset width={18} height={18} />
          </div>
          <strong>Need help?</strong>
          <p>Guides, FAQs, and support for operators.</p>
          <Link className="btn btn-solid" to="/support">
            Contact Support
          </Link>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <button
            className="icon-btn"
            type="button"
            aria-label="Toggle menu"
            onClick={() => setSidebarOpen((v) => !v)}
          >
            <IconMenu />
          </button>

          <div className="search-wrap">
            <IconSearch className="search-icon" />
            <input
              className="search"
              placeholder={searchPlaceholderFor(location.pathname)}
            />
          </div>

          <div className="topbar-right">
            <label className="locale-select" style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
              <select
                value={locale}
                onChange={(e) => setLocale(e.target.value === 'fr' ? 'fr' : 'en')}
                aria-label={t('settings.language')}
              >
                <option value="en">EN</option>
                <option value="fr">FR</option>
              </select>
            </label>
            <button className="icon-btn notify-btn" type="button" aria-label="Notifications">
              <IconBell />
              <span className="notify-dot">
                {Math.min(
                  99,
                  Math.max(5, badges.reports + badges.sos + badges.providerVerify),
                )}
              </span>
            </button>
            <button className="icon-btn" type="button" aria-label="Messages">
              <IconMessage />
            </button>
            <div className="user-chip">
              <img className="user-avatar" src={avatar} alt="" />
              <div className="user-meta">
                <strong>{displayName}</strong>
                <span>{roleLabel}</span>
              </div>
              <button
                type="button"
                className="icon-btn chevron"
                aria-label="Sign out"
                title="Sign out"
                onClick={() => void logout()}
              >
                <IconChevronDown />
              </button>
            </div>
          </div>
        </header>

        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
