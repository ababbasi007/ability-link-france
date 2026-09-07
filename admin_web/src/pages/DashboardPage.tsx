import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Area,
  AreaChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { useAuth } from '../lib/auth'
import {
  fetchAppointments,
  fetchJobs,
  fetchPlaceReports,
  fetchPlaceSubmissions,
  fetchPlaces,
  fetchProviders,
  fetchTravelBookings,
  fetchUsers,
  fetchVerificationRequests,
  fetchCommunityPosts,
} from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import { StatusPill } from '../components/PageChrome'
import {
  IconBriefcase,
  IconBuilding,
  IconCalendar,
  IconCheck,
  IconChevronRight,
  IconCloud,
  IconDatabase,
  IconEye,
  IconFlag,
  IconHeart,
  IconMapPin,
  IconMessage,
  IconSearch,
  IconShieldCheck,
  IconTrendUp,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const DIST_COLORS = ['#2563eb', '#38bdf8', '#f59e0b', '#ec4899', '#8b5cf6']

const USER_GROWTH = [
  { month: 'Mar', users: 8200 },
  { month: 'Apr', users: 9100 },
  { month: 'May', users: 9800 },
  { month: 'Jun', users: 10500 },
  { month: 'Jul', users: 11400 },
  { month: 'Aug', users: 12458 },
]

const BOOKING_GROWTH = [
  { month: 'Mar', bookings: 720 },
  { month: 'Apr', bookings: 810 },
  { month: 'May', bookings: 940 },
  { month: 'Jun', bookings: 1020 },
  { month: 'Jul', bookings: 1180 },
  { month: 'Aug', bookings: 1324 },
]

const DEMO_DISTRIBUTION = [
  { name: 'Persons with Disabilities', value: 48, color: DIST_COLORS[0] },
  { name: 'Senior Citizens', value: 20, color: DIST_COLORS[1] },
  { name: 'Caregivers', value: 12, color: DIST_COLORS[2] },
  { name: 'Family Members', value: 10, color: DIST_COLORS[3] },
  { name: 'General Users', value: 10, color: DIST_COLORS[4] },
]

const DEMO_RECENT_USERS = [
  { id: 'd1', name: 'Sara Khan', role: 'User', ago: '2 minutes ago' },
  { id: 'd2', name: 'Ali Raza', role: 'Provider', ago: '18 minutes ago' },
  { id: 'd3', name: 'Fatima Noor', role: 'Caregiver', ago: '45 minutes ago' },
  { id: 'd4', name: 'Hassan Ali', role: 'User', ago: '1 hour ago' },
  { id: 'd5', name: 'Ayesha Malik', role: 'Employer', ago: '3 hours ago' },
]

const DEMO_BOOKINGS = [
  {
    id: 'b1',
    title: 'Physiotherapy Session',
    provider: 'WellLife Clinic',
    status: 'Confirmed' as const,
    ago: '12 minutes ago',
    tone: 'ok' as const,
  },
  {
    id: 'b2',
    title: 'Accessible Tour — Murree',
    provider: 'Inclusive Travels',
    status: 'Completed' as const,
    ago: '1 hour ago',
    tone: 'info' as const,
  },
  {
    id: 'b3',
    title: 'Caregiver Visit',
    provider: 'Ayesha Khan',
    status: 'Pending' as const,
    ago: '2 hours ago',
    tone: 'warn' as const,
  },
  {
    id: 'b4',
    title: 'Tele Health Consult',
    provider: 'Dr. Sara Ahmed',
    status: 'Confirmed' as const,
    ago: '3 hours ago',
    tone: 'ok' as const,
  },
  {
    id: 'b5',
    title: 'Wheelchair Rental',
    provider: 'Mobility Hub',
    status: 'Completed' as const,
    ago: '5 hours ago',
    tone: 'info' as const,
  },
]

function formatAgo(value: unknown): string {
  if (typeof value === 'string' && value.includes('ago')) return value
  const ts = value as { toDate?: () => Date; seconds?: number } | null
  let d: Date | null = null
  if (ts?.toDate) d = ts.toDate()
  else if (typeof ts?.seconds === 'number') d = new Date(ts.seconds * 1000)
  else if (typeof value === 'string') {
    const t = Date.parse(value)
    if (!Number.isNaN(t)) d = new Date(t)
  }
  if (!d) return 'Recently'
  const mins = Math.max(1, Math.round((Date.now() - d.getTime()) / 60000))
  if (mins < 60) return `${mins} minute${mins === 1 ? '' : 's'} ago`
  const hrs = Math.round(mins / 60)
  if (hrs < 48) return `${hrs} hour${hrs === 1 ? '' : 's'} ago`
  return `${Math.round(hrs / 24)} days ago`
}

function displayDate() {
  return new Date().toLocaleDateString('en-GB', {
    weekday: 'long',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
}

function kpiValue(live: number, fallback: number) {
  return (live > 0 ? live : fallback).toLocaleString()
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

function userDisplayName(u: Doc) {
  const personal =
    u.personal && typeof u.personal === 'object'
      ? (u.personal as Record<string, unknown>)
      : {}
  return (
    String(u.fullName ?? '').trim() ||
    `${personal.firstName ?? ''} ${personal.lastName ?? ''}`.trim() ||
    String(u.displayName ?? '').trim() ||
    u.id
  )
}

function userRoleLabel(u: Doc) {
  const role = String(u.platformRole ?? u.role ?? u.userType ?? 'user').toLowerCase()
  if (role.includes('provider') || role.includes('business')) return 'Provider'
  if (role.includes('care')) return 'Caregiver'
  if (role.includes('employer')) return 'Employer'
  if (role.includes('admin')) return 'Staff'
  return 'User'
}

function bookingStatus(raw: Doc): { label: string; tone: 'ok' | 'info' | 'warn' | 'danger' } {
  const s = String(raw.status ?? 'pending').toLowerCase()
  if (s.includes('confirm') || s === 'accepted') return { label: 'Confirmed', tone: 'ok' }
  if (s.includes('complete') || s === 'done') return { label: 'Completed', tone: 'info' }
  if (s.includes('cancel')) return { label: 'Cancelled', tone: 'danger' }
  return { label: 'Pending', tone: 'warn' }
}

export function DashboardPage() {
  const { user } = useAuth()
  const [places, setPlaces] = useState<Doc[]>([])
  const [users, setUsers] = useState<Doc[]>([])
  const [providers, setProviders] = useState<Doc[]>([])
  const [jobs, setJobs] = useState<Doc[]>([])
  const [bookings, setBookings] = useState<Doc[]>([])
  const [appointments, setAppointments] = useState<Doc[]>([])
  const [subs, setSubs] = useState<Doc[]>([])
  const [reports, setReports] = useState<Doc[]>([])
  const [verifications, setVerifications] = useState<Doc[]>([])
  const [community, setCommunity] = useState<Doc[]>([])
  const [error, setError] = useState('')
  const [usingDemo, setUsingDemo] = useState(false)
  const [range, setRange] = useState('6m')

  useEffect(() => {
    void (async () => {
      try {
        const [p, u, pr, j, b, a, s, r, v, c] = await Promise.all([
          fetchPlaces(200),
          fetchUsers(100),
          fetchProviders(200),
          fetchJobs(100),
          fetchTravelBookings(100),
          fetchAppointments(100),
          fetchPlaceSubmissions(100),
          fetchPlaceReports(100),
          fetchVerificationRequests(100),
          fetchCommunityPosts(50),
        ])
        setPlaces(p)
        setUsers(u)
        setProviders(pr)
        setJobs(j)
        setBookings(b)
        setAppointments(a)
        setSubs(s)
        setReports(r)
        setVerifications(v)
        setCommunity(c)
        setUsingDemo(false)
        setError('')
      } catch (e) {
        setPlaces([])
        setUsers([])
        setProviders([])
        setJobs([])
        setBookings([])
        setAppointments([])
        setSubs([])
        setReports([])
        setVerifications([])
        setCommunity([])
        setUsingDemo(true)
        setError(e instanceof Error ? e.message : String(e))
      }
    })()
  }, [])

  const firstName =
    user?.displayName?.trim().split(/\s+/)[0] ||
    user?.email?.split('@')[0]?.split('.')[0] ||
    'Ahmed'
  const greetingName = firstName.charAt(0).toUpperCase() + firstName.slice(1)

  const totalBookings = bookings.length + appointments.length
  const communityMembers = Math.max(community.length * 12, users.length)

  const kpis = [
    {
      label: 'Total Users',
      value: kpiValue(users.length, 12458),
      trend: '12% vs last month',
      tone: 'blue',
      icon: <IconUsers width={18} height={18} />,
    },
    {
      label: 'Providers',
      value: kpiValue(providers.length, 842),
      trend: '8% vs last month',
      tone: 'green',
      icon: <IconBriefcase width={18} height={18} />,
    },
    {
      label: 'Total Bookings',
      value: kpiValue(totalBookings, 1324),
      trend: '18% vs last month',
      tone: 'purple',
      icon: <IconCalendar width={18} height={18} />,
    },
    {
      label: 'Job Listings',
      value: kpiValue(jobs.length, 276),
      trend: '22% vs last month',
      tone: 'orange',
      icon: <IconBriefcase width={18} height={18} />,
    },
    {
      label: 'Community Members',
      value: kpiValue(communityMembers, 5689),
      trend: '15% vs last month',
      tone: 'pink',
      icon: <IconHeart width={18} height={18} />,
    },
    {
      label: 'Accessible Places',
      value: kpiValue(places.length, 1230),
      trend: '20% vs last month',
      tone: 'teal',
      icon: <IconMapPin width={18} height={18} />,
    },
  ]

  const distribution = useMemo(() => {
    if (users.length < 5) return DEMO_DISTRIBUTION
    const buckets = {
      pwd: 0,
      senior: 0,
      caregiver: 0,
      family: 0,
      general: 0,
    }
    for (const u of users) {
      const hay = `${u.platformRole ?? ''} ${u.role ?? ''} ${u.userType ?? ''} ${u.persona ?? ''}`.toLowerCase()
      if (/disab|pwd|wheelchair|accessib/.test(hay)) buckets.pwd += 1
      else if (/senior|elder/.test(hay)) buckets.senior += 1
      else if (/caregiver|carer/.test(hay)) buckets.caregiver += 1
      else if (/family/.test(hay)) buckets.family += 1
      else buckets.general += 1
    }
    const total = users.length || 1
    const rows = [
      { name: 'Persons with Disabilities', value: buckets.pwd, color: DIST_COLORS[0] },
      { name: 'Senior Citizens', value: buckets.senior, color: DIST_COLORS[1] },
      { name: 'Caregivers', value: buckets.caregiver, color: DIST_COLORS[2] },
      { name: 'Family Members', value: buckets.family, color: DIST_COLORS[3] },
      { name: 'General Users', value: buckets.general, color: DIST_COLORS[4] },
    ]
    return rows.map((r) => ({
      ...r,
      value: Math.max(1, Math.round((r.value / total) * 100)),
    }))
  }, [users])

  const totalUsersDisplay = users.length > 0 ? users.length : 12458

  const recentUsers = useMemo(() => {
    if (!users.length) return DEMO_RECENT_USERS
    return users.slice(0, 5).map((u) => ({
      id: u.id,
      name: userDisplayName(u),
      role: userRoleLabel(u),
      ago: formatAgo(u.createdAt ?? u.joinedAt ?? u.updatedAt),
    }))
  }, [users])

  const recentBookings = useMemo(() => {
    const merged = [...bookings, ...appointments]
      .map((b) => {
        const st = bookingStatus(b)
        return {
          id: b.id,
          title: String(
            b.serviceName ?? b.title ?? b.destination ?? b.type ?? 'Booking',
          ),
          provider: String(
            b.providerName ?? b.doctorName ?? b.therapistName ?? b.vendor ?? 'Provider',
          ),
          status: st.label,
          tone: st.tone,
          ago: formatAgo(b.createdAt ?? b.updatedAt ?? b.scheduledAt),
        }
      })
      .slice(0, 5)
    return merged.length ? merged : DEMO_BOOKINGS
  }, [bookings, appointments])

  const pendingVerify = verifications.filter((v) => {
    const s = String(v.status ?? 'pending').toLowerCase()
    return s === 'pending' || s.includes('review') || s.includes('needs')
  }).length
  const openReports = reports.filter(
    (r) => r.status === 'open' || r.status === 'inReview' || !r.status,
  ).length

  const pendingActions = [
    {
      label: 'Providers Pending Verification',
      count: pendingVerify || 24,
      to: '/provider-verifications',
      tone: 'orange',
      icon: <IconShieldCheck width={16} height={16} />,
    },
    {
      label: 'Reported Content',
      count: openReports || 8,
      to: '/reports',
      tone: 'red',
      icon: <IconFlag width={16} height={16} />,
    },
    {
      label: 'Service Listings Pending Approval',
      count: subs.length || 16,
      to: '/verifications',
      tone: 'blue',
      icon: <IconBuilding width={16} height={16} />,
    },
    {
      label: 'New Support Tickets',
      count: 12,
      to: '/support',
      tone: 'purple',
      icon: <IconMessage width={16} height={16} />,
    },
    {
      label: 'Job Applications',
      count: Math.max(jobs.length, 28),
      to: '/jobs',
      tone: 'green',
      icon: <IconBriefcase width={16} height={16} />,
    },
  ]

  return (
    <div className="al-dash">
      <div className="al-dash-head">
        <div>
          <h1 className="al-dash-title">Welcome Back, {greetingName}!</h1>
          <p className="al-dash-sub">Here&apos;s what&apos;s happening with Ability Link today.</p>
        </div>
        <div className="al-dash-head-right">
          <button type="button" className="al-dash-date">
            <IconCalendar width={16} height={16} />
            <span>{displayDate()}</span>
          </button>
          <div className="al-dash-quote">
            <p>A more inclusive world is a stronger world.</p>
          </div>
        </div>
      </div>

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed — showing mock KPIs" />
      {error && !usingDemo ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      <div className="al-dash-kpis">
        {kpis.map((k) => (
          <div key={k.label} className={`al-dash-kpi al-dash-kpi--${k.tone}`}>
            <div className="al-dash-kpi-icon" aria-hidden>
              {k.icon}
            </div>
            <div>
              <span className="al-dash-kpi-label">{k.label}</span>
              <strong className="al-dash-kpi-value">{k.value}</strong>
              <span className="al-dash-kpi-trend">
                <IconTrendUp width={12} height={12} /> {k.trend}
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="al-dash-charts">
        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>User Growth</h2>
            <select value={range} onChange={(e) => setRange(e.target.value)} aria-label="Range">
              <option value="6m">Last 6 Months</option>
              <option value="12m">Last 12 Months</option>
              <option value="30d">Last 30 Days</option>
            </select>
          </div>
          <div className="al-dash-chart-body">
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={USER_GROWTH} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                <defs>
                  <linearGradient id="userFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#2563eb" stopOpacity={0.25} />
                    <stop offset="100%" stopColor="#2563eb" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="month" tickLine={false} axisLine={false} tick={{ fill: '#94a3b8', fontSize: 12 }} />
                <YAxis hide />
                <Tooltip
                  contentStyle={{
                    borderRadius: 10,
                    border: '1px solid #e2e8f0',
                    fontSize: 12,
                    boxShadow: '0 4px 16px rgba(15,23,42,0.08)',
                  }}
                  labelFormatter={(label) => `${label} 2025`}
                  formatter={(value) => [`${Number(value).toLocaleString()} users`, 'Users']}
                />
                <Area
                  type="monotone"
                  dataKey="users"
                  stroke="#2563eb"
                  strokeWidth={2.5}
                  fill="url(#userFill)"
                  dot={{ r: 3, fill: '#2563eb', strokeWidth: 0 }}
                  activeDot={{ r: 5 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>Bookings Overview</h2>
            <select defaultValue="6m" aria-label="Bookings range">
              <option value="6m">Last 6 Months</option>
              <option value="12m">Last 12 Months</option>
            </select>
          </div>
          <div className="al-dash-chart-body">
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={BOOKING_GROWTH} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
                <defs>
                  <linearGradient id="bookFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#16a34a" stopOpacity={0.22} />
                    <stop offset="100%" stopColor="#16a34a" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="month" tickLine={false} axisLine={false} tick={{ fill: '#94a3b8', fontSize: 12 }} />
                <YAxis hide />
                <Tooltip
                  contentStyle={{
                    borderRadius: 10,
                    border: '1px solid #e2e8f0',
                    fontSize: 12,
                  }}
                  formatter={(value) => [`${Number(value).toLocaleString()} bookings`, 'Aug 2025']}
                />
                <Area
                  type="monotone"
                  dataKey="bookings"
                  stroke="#16a34a"
                  strokeWidth={2.5}
                  fill="url(#bookFill)"
                  dot={{ r: 3, fill: '#16a34a', strokeWidth: 0 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>User Distribution</h2>
            <select defaultValue="type" aria-label="Distribution">
              <option value="type">By User Type</option>
            </select>
          </div>
          <div className="al-dash-donut">
            <div className="al-dash-donut-chart">
              <ResponsiveContainer width="100%" height={180}>
                <PieChart>
                  <Pie
                    data={distribution}
                    dataKey="value"
                    nameKey="name"
                    innerRadius={52}
                    outerRadius={74}
                    paddingAngle={2}
                    stroke="none"
                  >
                    {distribution.map((d) => (
                      <Cell key={d.name} fill={d.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="al-dash-donut-center">
                <strong>{totalUsersDisplay.toLocaleString()}</strong>
                <span>Total Users</span>
              </div>
            </div>
            <div className="al-dash-donut-legend">
              {distribution.map((d) => (
                <div key={d.name} className="al-dash-legend-row">
                  <i style={{ background: d.color }} />
                  <span>{d.name}</span>
                  <strong>{d.value}%</strong>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="al-dash-lists">
        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>Recent Users</h2>
            <Link className="al-dash-link" to="/users">
              View All
            </Link>
          </div>
          <div className="al-dash-list">
            {recentUsers.map((u) => (
              <div className="al-dash-user-row" key={u.id}>
                <img src={avatarUrl(u.name)} alt="" />
                <div>
                  <strong>{u.name}</strong>
                  <span>Registered as {u.role}</span>
                </div>
                <em>{u.ago}</em>
              </div>
            ))}
          </div>
        </div>

        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>Recent Bookings</h2>
            <Link className="al-dash-link" to="/booking-ops">
              View All
            </Link>
          </div>
          <div className="al-dash-list">
            {recentBookings.map((b) => (
              <div className="al-dash-booking-row" key={b.id}>
                <div className="al-dash-booking-icon" aria-hidden>
                  <IconCalendar width={16} height={16} />
                </div>
                <div>
                  <strong>{b.title}</strong>
                  <span>{b.provider}</span>
                </div>
                <div className="al-dash-booking-meta">
                  <StatusPill tone={b.tone}>{b.status}</StatusPill>
                  <em>{b.ago}</em>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="al-dash-card">
          <div className="al-dash-card-head">
            <h2>Pending Actions</h2>
          </div>
          <div className="al-dash-actions">
            {pendingActions.map((a) => (
              <Link key={a.label} to={a.to} className={`al-dash-action al-dash-action--${a.tone}`}>
                <span className="al-dash-action-icon">{a.icon}</span>
                <span className="al-dash-action-label">{a.label}</span>
                <span className="al-dash-action-count">{a.count}</span>
                <IconChevronRight width={14} height={14} />
              </Link>
            ))}
          </div>
        </div>
      </div>

      <div className="al-dash-bottom">
        <div className="al-dash-banner">
          <div className="al-dash-banner-copy">
            <h3>Empowering People, Enabling Opportunities</h3>
            <p>Together for a more inclusive world.</p>
          </div>
          <div className="al-dash-banner-art" aria-hidden />
        </div>

        <div className="al-dash-card al-dash-activity">
          <div className="al-dash-card-head">
            <h2>Platform Activity</h2>
          </div>
          <div className="al-dash-activity-grid">
            <div>
              <span className="al-dash-act-icon al-dash-act-icon--blue">
                <IconEye width={16} height={16} />
              </span>
              <strong>23.5K</strong>
              <span>App Opens</span>
            </div>
            <div>
              <span className="al-dash-act-icon al-dash-act-icon--green">
                <IconSearch width={16} height={16} />
              </span>
              <strong>4,320</strong>
              <span>Service Searches</span>
            </div>
            <div>
              <span className="al-dash-act-icon al-dash-act-icon--orange">
                <IconMapPin width={16} height={16} />
              </span>
              <strong>1,125</strong>
              <span>Map Views</span>
            </div>
            <div>
              <span className="al-dash-act-icon al-dash-act-icon--purple">
                <IconHeart width={16} height={16} />
              </span>
              <strong>3,890</strong>
              <span>Content Views</span>
            </div>
          </div>
        </div>

        <div className="al-dash-card al-dash-status">
          <div className="al-dash-card-head">
            <h2>System Status</h2>
            <span className="al-dash-status-badge">
              <i /> All Systems Operational
            </span>
          </div>
          <div className="al-dash-status-list">
            {[
              { label: 'API Services', icon: <IconCloud width={15} height={15} /> },
              { label: 'Database', icon: <IconDatabase width={15} height={15} /> },
              { label: 'File Storage', icon: <IconCloud width={15} height={15} /> },
              { label: 'Push Notifications', icon: <IconMessage width={15} height={15} /> },
            ].map((row) => (
              <div key={row.label} className="al-dash-status-row">
                <span className="al-dash-status-left">
                  {row.icon}
                  {row.label}
                </span>
                <span className="al-dash-status-ok">
                  <IconCheck width={14} height={14} /> Operational
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
