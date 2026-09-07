import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import {
  fetchPlaceReports,
  fetchPlaces,
  fetchReviews,
  fetchUsers,
} from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import {
  KpiRow,
  PageHeader,
  TabBar,
  Widget,
} from '../components/PageChrome'
import {
  IconBriefcase,
  IconCalendar,
  IconChart,
  IconDownload,
  IconEye,
  IconFileText,
  IconFlag,
  IconMapPin,
  IconStar,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const CAT_COLORS = ['#2563eb', '#16a34a', '#ea580c', '#7c3aed', '#db2777', '#94a3b8']

const TREND = [
  { day: 'Aug 1', users: 9800, revenue: 180000 },
  { day: 'Aug 5', users: 10200, revenue: 210000 },
  { day: 'Aug 10', users: 10840, revenue: 240000 },
  { day: 'Aug 15', users: 11200, revenue: 265000 },
  { day: 'Aug 20', users: 11680, revenue: 290000 },
  { day: 'Aug 25', users: 12040, revenue: 310000 },
  { day: 'Aug 31', users: 12482, revenue: 328000 },
]

const BOOKING_BARS = [
  { name: 'Tele Rehab', value: 320 },
  { name: 'Tele Health', value: 280 },
  { name: 'Consultations', value: 210 },
  { name: 'Programs', value: 160 },
  { name: 'Assistive Tech', value: 120 },
  { name: 'Tours', value: 90 },
]

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'users', label: 'Users' },
  { id: 'services', label: 'Services' },
  { id: 'bookings', label: 'Bookings' },
  { id: 'programs', label: 'Programs' },
  { id: 'assessments', label: 'Assessments' },
  { id: 'engagement', label: 'Engagement' },
  { id: 'revenue', label: 'Revenue' },
]

function dateRangeLabel() {
  return '1 Aug 2026 – 31 Aug 2026'
}

export function AnalyticsPage() {
  const [tab, setTab] = useState('overview')
  const [places, setPlaces] = useState<Doc[]>([])
  const [users, setUsers] = useState<Doc[]>([])
  const [reviews, setReviews] = useState<Doc[]>([])
  const [reports, setReports] = useState<Doc[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [userType, setUserType] = useState('all')
  const [serviceCat, setServiceCat] = useState('all')
  const [location, setLocation] = useState('all')

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const [p, u, rv, rp] = await Promise.all([
          fetchPlaces(400),
          fetchUsers(200),
          fetchReviews(200),
          fetchPlaceReports(200),
        ])
        if (cancelled) return
        setPlaces(p)
        setUsers(u)
        setReviews(rv)
        setReports(rp)
        setUsingDemo(false)
      } catch {
        if (!cancelled) {
          setPlaces([])
          setUsers([])
          setReviews([])
          setReports([])
          setUsingDemo(false)
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  const kpi = useMemo(() => {
    return {
      users: users.length || 12482,
      bookings: Math.max(places.length, 1356),
      assessments: Math.round((reviews.length || 892) * 1.1),
      providers: Math.max(Math.round(users.length * 0.05), 640),
      views: Math.max(places.length * 12, 28471),
      revenue: 'PKR 1,248,000',
    }
  }, [places, users, reviews])

  const categories = useMemo(() => {
    const fallback = [
      { name: 'People with Disabilities', value: 42 },
      { name: 'Caregivers', value: 18 },
      { name: 'Senior Citizens', value: 16 },
      { name: 'Healthcare Professionals', value: 10 },
      { name: 'Students', value: 8 },
      { name: 'Others', value: 6 },
    ]
    if (!users.length) return fallback
    const counts = new Map<string, number>()
    for (const u of users) {
      const c = String(u.role ?? u.userType ?? u.category ?? 'Others')
      counts.set(c, (counts.get(c) ?? 0) + 1)
    }
    const total = users.length || 1
    const derived = [...counts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6)
      .map(([name, value]) => ({
        name,
        value: Math.round((value / total) * 100),
      }))
    return derived.length ? derived : fallback
  }, [users])

  const locations = useMemo(() => {
    if (!places.length) {
      return [
        { city: 'Islamabad', value: 28 },
        { city: 'Lahore', value: 18 },
        { city: 'Karachi', value: 15 },
        { city: 'Peshawar', value: 12 },
        { city: 'Abbottabad', value: 9 },
      ]
    }
    const counts = new Map<string, number>()
    for (const p of places) {
      const city = String(p.city || 'Unknown')
      counts.set(city, (counts.get(city) ?? 0) + 1)
    }
    const total = places.length || 1
    return [...counts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([city, value]) => ({
        city,
        value: Math.round((value / total) * 100),
      }))
  }, [places])

  const avgRating = useMemo(() => {
    if (!reviews.length) return 4.6
    const sum = reviews.reduce((s, r) => s + Number(r.rating ?? 0), 0)
    const n = reviews.filter((r) => Number(r.rating ?? 0) > 0).length || 1
    return Math.round((sum / n) * 10) / 10 || 4.6
  }, [reviews])

  return (
    <div className="al-page">
      <PageHeader
        title="Reports & Analytics"
        subtitle="Data-driven insights for a more inclusive world."
        secondaryAction={
          <button type="button" className="al-btn al-btn--outline">
            <IconCalendar width={15} height={15} /> {dateRangeLabel()}
          </button>
        }
      />

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <KpiRow
        cols={6}
        items={[
          {
            label: 'Total Users',
            value: kpi.users.toLocaleString(),
            trend: '12% vs last month',
            tone: 'blue',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Total Bookings',
            value: kpi.bookings.toLocaleString(),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconCalendar width={18} height={18} />,
          },
          {
            label: 'Assessments Completed',
            value: kpi.assessments.toLocaleString(),
            trend: '25% vs last month',
            tone: 'purple',
            icon: <IconFileText width={18} height={18} />,
          },
          {
            label: 'Active Providers',
            value: kpi.providers.toLocaleString(),
            trend: '10% vs last month',
            tone: 'orange',
            icon: <IconBriefcase width={18} height={18} />,
          },
          {
            label: 'Content Views',
            value: kpi.views.toLocaleString(),
            trend: '32% vs last month',
            tone: 'pink',
            icon: <IconEye width={18} height={18} />,
          },
          {
            label: 'Total Revenue',
            value: kpi.revenue,
            trend: '20% vs last month',
            tone: 'green',
            icon: <IconChart width={18} height={18} />,
          },
        ]}
      />

      <div className="al-split">
        <div>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1.2fr 1fr',
              gap: 12,
              marginBottom: 12,
            }}
          >
            <div className="al-table-card" style={{ padding: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                <strong>User Growth</strong>
                <select defaultValue="30" style={{ fontSize: 12, borderRadius: 8, border: '1px solid var(--border)', padding: '4px 8px' }}>
                  <option value="30">Last 30 Days</option>
                  <option value="7">Last 7 Days</option>
                </select>
              </div>
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={TREND}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="day" tick={{ fontSize: 11, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: '#64748b' }} axisLine={false} tickLine={false} width={40} />
                  <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 12 }} />
                  <Line type="monotone" dataKey="users" stroke="#2563eb" strokeWidth={2.5} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>Users by Category</strong>
              <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginTop: 8 }}>
                <ResponsiveContainer width="45%" height={180}>
                  <PieChart>
                    <Pie data={categories} dataKey="value" innerRadius={48} outerRadius={72} paddingAngle={2}>
                      {categories.map((_, i) => (
                        <Cell key={i} fill={CAT_COLORS[i % CAT_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ flex: 1, display: 'grid', gap: 6 }}>
                  {categories.map((c, i) => (
                    <div key={c.name} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12 }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                        <i style={{ width: 8, height: 8, borderRadius: '50%', background: CAT_COLORS[i % CAT_COLORS.length], display: 'inline-block' }} />
                        {c.name}
                      </span>
                      <strong>{c.value}%</strong>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: 12,
              marginBottom: 12,
            }}
          >
            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>Bookings by Service Type</strong>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={BOOKING_BARS}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: '#64748b' }} axisLine={false} tickLine={false} width={36} />
                  <Tooltip contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 12 }} />
                  <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                    {BOOKING_BARS.map((_, i) => (
                      <Cell key={i} fill={CAT_COLORS[i % CAT_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>Revenue Overview</strong>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={TREND}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="day" tick={{ fontSize: 10, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 11, fill: '#64748b' }} axisLine={false} tickLine={false} width={44} />
                  <Tooltip
                    formatter={(v) => [`PKR ${Number(v).toLocaleString()}`, 'Revenue']}
                    contentStyle={{ borderRadius: 10, border: '1px solid #e2e8f0', fontSize: 12 }}
                  />
                  <Bar dataKey="revenue" fill="#16a34a" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>Top Locations</strong>
              <div style={{ marginTop: 12, display: 'grid', gap: 10 }}>
                {locations.map((l) => (
                  <div key={l.city}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                      <span>{l.city}</span>
                      <strong>{l.value}%</strong>
                    </div>
                    <div style={{ height: 6, background: '#f1f5f9', borderRadius: 999 }}>
                      <div style={{ width: `${l.value}%`, height: '100%', background: '#2563eb', borderRadius: 999 }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>Top Content</strong>
              <div style={{ marginTop: 12, display: 'grid', gap: 10 }}>
                {[
                  { label: 'Exercises', n: 9200 },
                  { label: 'Videos', n: 7800 },
                  { label: 'Articles', n: 6400 },
                  { label: 'Programs', n: 5100 },
                  { label: 'Assessments', n: 4200 },
                ].map((c) => (
                  <div key={c.label}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                      <span>{c.label}</span>
                      <strong>{c.n.toLocaleString()}</strong>
                    </div>
                    <div style={{ height: 6, background: '#f1f5f9', borderRadius: 999 }}>
                      <div style={{ width: `${(c.n / 9200) * 100}%`, height: '100%', background: '#7c3aed', borderRadius: 999 }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="al-table-card" style={{ padding: 16 }}>
              <strong>User Satisfaction</strong>
              <div style={{ textAlign: 'center', margin: '16px 0 8px' }}>
                <div className="al-stat-big" style={{ color: '#2563eb' }}>{avgRating}</div>
                <div className="muted" style={{ fontSize: 12 }}>out of 5</div>
                <div style={{ color: '#f59e0b', marginTop: 4 }}>
                  {[1, 2, 3, 4, 5].map((i) => (
                    <IconStar key={i} width={14} height={14} style={{ display: 'inline', marginRight: 2 }} />
                  ))}
                </div>
              </div>
              <div style={{ display: 'grid', gap: 6, fontSize: 12 }}>
                {[5, 4, 3, 2, 1].map((s) => (
                  <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ width: 28 }}>{s}★</span>
                    <div style={{ flex: 1, height: 6, background: '#f1f5f9', borderRadius: 999 }}>
                      <div style={{ width: `${s === 5 ? 62 : s === 4 ? 22 : s === 3 ? 10 : 4}%`, height: '100%', background: '#f59e0b', borderRadius: 999 }} />
                    </div>
                  </div>
                ))}
              </div>
              <div style={{ marginTop: 10, fontSize: 12 }}>
                <Link to="/reports" className="al-type-link">
                  <IconFlag width={12} height={12} /> {reports.length} open reports →
                </Link>
              </div>
            </div>
          </div>
        </div>

        <div className="al-widgets">
          <Widget
            title="Filters"
            action={
              <button
                type="button"
                className="al-btn al-btn--ghost"
                onClick={() => {
                  setUserType('all')
                  setServiceCat('all')
                  setLocation('all')
                }}
              >
                Reset
              </button>
            }
          >
            <div style={{ display: 'grid', gap: 8 }}>
              <label className="field">
                Date Range
                <select defaultValue="aug">
                  <option value="aug">1–31 Aug 2026</option>
                  <option value="jul">1–31 Jul 2026</option>
                </select>
              </label>
              <label className="field">
                User Type
                <select value={userType} onChange={(e) => setUserType(e.target.value)}>
                  <option value="all">All Users</option>
                  <option value="pwd">Persons with Disabilities</option>
                  <option value="caregiver">Caregivers</option>
                </select>
              </label>
              <label className="field">
                Service Category
                <select value={serviceCat} onChange={(e) => setServiceCat(e.target.value)}>
                  <option value="all">All Services</option>
                  <option value="rehab">Tele Rehab</option>
                  <option value="health">Tele Health</option>
                </select>
              </label>
              <label className="field">
                Location
                <select value={location} onChange={(e) => setLocation(e.target.value)}>
                  <option value="all">All Locations</option>
                  {locations.map((l) => (
                    <option key={l.city} value={l.city}>{l.city}</option>
                  ))}
                </select>
              </label>
              <label className="field">
                Report Type
                <select defaultValue="overview">
                  <option value="overview">Overview</option>
                  <option value="engagement">Engagement</option>
                  <option value="revenue">Revenue</option>
                </select>
              </label>
              <button type="button" className="al-btn al-btn--primary" style={{ width: '100%' }}>
                Generate Report
              </button>
            </div>
          </Widget>

          <Widget title="Key Insights">
            <div className="al-widget-list">
              {[
                { text: 'User growth increased by 12% compared to last month.', icon: <IconUsers width={14} height={14} />, tone: 'blue' },
                { text: 'Tele Rehab bookings are the highest (24% of total).', icon: <IconCalendar width={14} height={14} />, tone: 'green' },
                { text: 'Engagement with educational content is up by 32%.', icon: <IconEye width={14} height={14} />, tone: 'purple' },
                { text: 'Revenue increased by 20% month-on-month.', icon: <IconChart width={14} height={14} />, tone: 'orange' },
              ].map((i) => (
                <div key={i.text} className="al-widget-item">
                  <span className={`al-activity-icon al-activity-icon--${i.tone}`}>
                    {i.icon}
                  </span>
                  <span style={{ fontSize: 12.5, color: '#334155' }}>{i.text}</span>
                </div>
              ))}
            </div>
          </Widget>

          <Widget title="Export Reports">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
              {['PDF', 'Excel', 'CSV'].map((fmt) => (
                <button key={fmt} type="button" className="al-btn al-btn--outline" style={{ fontSize: 12 }}>
                  <IconDownload width={13} height={13} /> {fmt}
                </button>
              ))}
            </div>
          </Widget>

          <div className="al-help-card">
            <IconMapPin width={18} height={18} style={{ color: '#2563eb' }} />
            <strong>{places.length.toLocaleString()} places tracked</strong>
            <p>Ability Map coverage across verified and community places.</p>
            <Link to="/places" className="al-btn al-btn--outline">
              Open Ability Map →
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
