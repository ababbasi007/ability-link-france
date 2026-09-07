import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchAppointments,
  fetchAssistanceBookings,
  fetchTravelBookings,
  setAppointmentStatus,
} from '../lib/data'
import {
  FilterBar,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'
import {
  IconAccessibility,
  IconCalendar,
  IconClock,
  IconHeadset,
  IconHeart,
  IconMapPin,
  IconMore,
  IconUser,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const CATEGORIES = [
  { id: 'all', label: 'All Bookings', tone: 'blue' },
  { id: 'tele_rehab', label: 'Tele Rehab', tone: 'green' },
  { id: 'tele_health', label: 'Tele Health', tone: 'purple' },
  { id: 'therapy', label: 'Therapy Sessions', tone: 'pink' },
  { id: 'caregiver', label: 'Caregiver Support', tone: 'orange' },
  { id: 'assistive', label: 'Assistive Technology', tone: 'blue' },
  { id: 'consult', label: 'Consultations', tone: 'purple' },
  { id: 'programs', label: 'Programs', tone: 'green' },
  { id: 'tours', label: 'Tours & Travel', tone: 'blue' },
  { id: 'in_person', label: 'In-Person Services', tone: 'orange' },
]

const TABS = [
  { id: 'upcoming', label: 'Upcoming' },
  { id: 'past', label: 'Past Bookings' },
  { id: 'cancelled', label: 'Cancelled' },
  { id: 'saved', label: 'Saved Providers' },
]

function asDate(value: unknown): Date | null {
  if (!value) return null
  if (typeof value === 'string') {
    const d = new Date(value)
    return Number.isNaN(d.getTime()) ? null : d
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    return (value as { toDate: () => Date }).toDate()
  }
  return null
}

function formatWhen(value: unknown): string {
  const d = asDate(value)
  if (!d) return '—'
  return d.toLocaleString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'info' | 'muted' {
  switch (status) {
    case 'booked':
    case 'confirmed':
    case 'completed':
    case 'fulfilled':
      return 'ok'
    case 'pending':
    case 'confirm':
    case 'in_progress':
      return 'warn'
    case 'cancelled':
    case 'no_show':
      return 'danger'
    default:
      return 'muted'
  }
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

function bookingKind(doc: Doc): string {
  const kind = String(doc.kind ?? doc.mode ?? doc.service ?? '').toLowerCase()
  if (kind.includes('rehab') || kind.includes('physio')) return 'tele_rehab'
  if (kind.includes('health') || kind.includes('doctor')) return 'tele_health'
  if (kind.includes('therap')) return 'therapy'
  if (kind.includes('care')) return 'caregiver'
  if (kind.includes('assist')) return 'assistive'
  if (kind.includes('tour') || kind.includes('travel')) return 'tours'
  if (kind.includes('program')) return 'programs'
  if (kind.includes('person') || kind.includes('clinic')) return 'in_person'
  return 'consult'
}

export function BookingsOpsPage() {
  const [tab, setTab] = useState('upcoming')
  const [category, setCategory] = useState('all')
  const [appointments, setAppointments] = useState<Doc[]>([])
  const [travel, setTravel] = useState<Doc[]>([])
  const [assistance, setAssistance] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [serviceType, setServiceType] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [a, t, as] = await Promise.all([
        fetchAppointments(200),
        fetchTravelBookings(100),
        fetchAssistanceBookings(100),
      ])
      setAppointments(a)
      setTravel(t)
      setAssistance(as)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load bookings')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const unified = useMemo(() => {
    const fromAppts = appointments.map((a) => ({
      ...a,
      _source: 'appointment' as const,
      _title: String(
        a.title ??
          `${a.kind ?? 'Appointment'} — ${a.specialty ?? a.providerName ?? 'Session'}`,
      ),
      _provider: String(a.providerName ?? a.providerId ?? 'Provider'),
      _when: a.startAt ?? a.createdAt,
      _status: String(a.status ?? 'pending'),
      _mode: String(a.mode ?? 'Online'),
    }))
    const fromTravel = travel.map((b) => ({
      ...b,
      _source: 'travel' as const,
      _title: String(b.destinationName ?? b.service ?? 'Travel booking'),
      _provider: String(b.service ?? 'Tourism'),
      _when: b.startAt ?? b.createdAt,
      _status: String(b.status ?? 'pending'),
      _mode: 'Travel',
    }))
    const fromAssist = assistance.map((b) => ({
      ...b,
      _source: 'assistance' as const,
      _title: String(b.assistanceType ?? b.service ?? 'Assistance'),
      _provider: String(b.providerId ?? 'Assistant'),
      _when: b.startAt ?? b.createdAt,
      _status: String(b.status ?? 'pending'),
      _mode: String(b.mode ?? 'In-person'),
    }))
    return [...fromAppts, ...fromTravel, ...fromAssist]
  }, [appointments, travel, assistance])

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    const now = Date.now()
    return unified
      .filter((b) => {
        const status = b._status.toLowerCase()
        const when = asDate(b._when)?.getTime() ?? 0
        const kind = bookingKind(b)

        if (category !== 'all' && kind !== category) return false
        if (serviceType !== 'all' && kind !== serviceType) return false
        if (statusFilter !== 'all' && status !== statusFilter) return false

        if (tab === 'cancelled' && status !== 'cancelled') return false
        if (tab === 'past') {
          if (status === 'cancelled') return false
          if (when > now && status !== 'completed' && status !== 'fulfilled') return false
        }
        if (tab === 'upcoming') {
          if (status === 'cancelled' || status === 'completed' || status === 'fulfilled')
            return false
        }
        if (tab === 'saved') return false

        if (!needle) return true
        return (
          b._title.toLowerCase().includes(needle) ||
          b._provider.toLowerCase().includes(needle) ||
          status.includes(needle) ||
          b.id.toLowerCase().includes(needle)
        )
      })
      .sort((a, b) => {
        const da = asDate(a._when)?.getTime() ?? 0
        const db = asDate(b._when)?.getTime() ?? 0
        return tab === 'past' ? db - da : da - db
      })
  }, [unified, q, category, serviceType, statusFilter, tab])

  const updateStatus = async (id: string, status: string, source: string) => {
    if (source !== 'appointment') return
    setBusyId(id)
    try {
      await setAppointmentStatus(id, status)
      setAppointments((prev) => prev.map((a) => (a.id === id ? { ...a, status } : a)))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const calDays = useMemo(() => {
    const days: { d: number; active?: boolean; has?: boolean }[] = []
    for (let i = 1; i <= 30; i++) {
      days.push({ d: i, active: i === 5, has: i === 6 || i === 8 || i === 12 || i === 18 })
    }
    return days
  }, [])

  return (
    <div className="al-page">
      <PageHeader
        title="Bookings"
        subtitle="Manage your bookings, sessions and appointments across Ability Link services."
        primaryAction={{ label: 'New Booking', href: '/appointments' }}
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="al-cat-scroll">
        {CATEGORIES.map((c) => {
          const toneBg =
            c.tone === 'green'
              ? '#dcfce7'
              : c.tone === 'purple'
                ? '#ede9fe'
                : c.tone === 'pink'
                  ? '#fce7f3'
                  : c.tone === 'orange'
                    ? '#ffedd5'
                    : '#dbeafe'
          const toneColor =
            c.tone === 'green'
              ? '#16a34a'
              : c.tone === 'purple'
                ? '#7c3aed'
                : c.tone === 'pink'
                  ? '#db2777'
                  : c.tone === 'orange'
                    ? '#ea580c'
                    : '#2563eb'
          return (
            <button
              key={c.id}
              type="button"
              onClick={() => setCategory(c.id)}
              className={`al-cat-tile${category === c.id ? ' active' : ''}`}
            >
              <div className="icon" style={{ background: toneBg, color: toneColor }}>
                {c.id === 'caregiver' ? (
                  <IconHeart width={16} height={16} />
                ) : c.id === 'assistive' ? (
                  <IconAccessibility width={16} height={16} />
                ) : c.id === 'tours' ? (
                  <IconMapPin width={16} height={16} />
                ) : (
                  <IconCalendar width={16} height={16} />
                )}
              </div>
              <span>{c.label}</span>
            </button>
          )
        })}
      </div>

      <div className="al-hero-banner" style={{ marginBottom: 16, minHeight: 140 }}>
        <h2>Book Support, Build a Brighter Tomorrow</h2>
        <p>Find therapists, caregivers, programs and accessible travel in one place.</p>
        <Link to="/appointments" className="al-btn al-btn--primary">
          Find a Service →
        </Link>
      </div>

      <div className="al-tabs-row">
        <TabBar tabs={TABS} active={tab} onChange={setTab} />
      </div>

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search bookings..."
        moreFilters
        onReset={() => {
          setQ('')
          setServiceType('all')
          setStatusFilter('all')
          setCategory('all')
        }}
      >
        <select value={serviceType} onChange={(e) => setServiceType(e.target.value)}>
          <option value="all">All Services</option>
          {CATEGORIES.filter((c) => c.id !== 'all').map((c) => (
            <option key={c.id} value={c.id}>
              {c.label}
            </option>
          ))}
        </select>
        <select defaultValue="all">
          <option value="all">All Dates</option>
          <option value="week">This Week</option>
          <option value="month">This Month</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="confirmed">Confirmed</option>
          <option value="pending">Pending</option>
          <option value="booked">Booked</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div>
          <strong style={{ display: 'block', marginBottom: 10 }}>
            {tab === 'upcoming'
              ? 'Upcoming Bookings'
              : tab === 'past'
                ? 'Past Bookings'
                : tab === 'cancelled'
                  ? 'Cancelled'
                  : 'Saved Providers'}
          </strong>
          {loading ? (
            <p className="muted">Loading…</p>
          ) : tab === 'saved' ? (
            <div className="al-table-card" style={{ padding: 20 }}>
              <p className="muted" style={{ margin: 0 }}>
                Saved providers appear here once you star a provider from Tele Health or Tele Rehab.
              </p>
              <Link to="/providers" className="al-btn al-btn--primary" style={{ marginTop: 12 }}>
                Browse Providers
              </Link>
            </div>
          ) : filtered.length === 0 ? (
            <div className="al-table-card" style={{ padding: 20 }}>
              <p className="muted" style={{ margin: 0 }}>
                No bookings found.
              </p>
            </div>
          ) : (
            <div style={{ display: 'grid', gap: 10 }}>
              {filtered.slice(0, 20).map((b) => {
                const online =
                  String(b._mode).toLowerCase().includes('online') ||
                  String(b._mode).toLowerCase().includes('video') ||
                  String(b._mode).toLowerCase() === 'online'
                return (
                  <div
                    key={`${b._source}-${b.id}`}
                    className="al-table-card"
                    style={{
                      padding: 14,
                      display: 'grid',
                      gridTemplateColumns: 'auto 1fr auto',
                      gap: 14,
                      alignItems: 'center',
                    }}
                  >
                    <span className="al-activity-icon al-activity-icon--blue">
                      <IconHeadset width={16} height={16} />
                    </span>
                    <div>
                      <strong style={{ display: 'block', fontSize: 14 }}>{b._title}</strong>
                      <div className="al-person" style={{ marginTop: 6 }}>
                        <img src={avatarUrl(b._provider)} alt="" style={{ width: 28, height: 28 }} />
                        <div>
                          <strong style={{ fontSize: 12 }}>{b._provider}</strong>
                          <span style={{ fontSize: 11 }}>Professional</span>
                        </div>
                      </div>
                      <div
                        className="muted"
                        style={{
                          display: 'flex',
                          gap: 12,
                          marginTop: 8,
                          fontSize: 12,
                          alignItems: 'center',
                        }}
                      >
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                          <IconCalendar width={12} height={12} /> {formatWhen(b._when)}
                        </span>
                        <StatusPill tone="info">{online ? 'Online' : b._mode}</StatusPill>
                        <StatusPill tone={statusTone(b._status)}>{b._status}</StatusPill>
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      {tab === 'upcoming' && online ? (
                        <button type="button" className="al-btn al-btn--primary">
                          Join Session
                        </button>
                      ) : (
                        <button type="button" className="al-btn al-btn--primary">
                          View Details
                        </button>
                      )}
                      {tab === 'upcoming' ? (
                        <button
                          type="button"
                          className="al-btn al-btn--outline"
                          disabled={busyId === b.id}
                          onClick={() =>
                            void updateStatus(
                              b.id,
                              tab === 'upcoming' ? 'cancelled' : 'booked',
                              b._source,
                            )
                          }
                        >
                          {b._source === 'appointment' ? 'Cancel' : 'Reschedule'}
                        </button>
                      ) : null}
                      <button type="button" className="icon-btn" aria-label="More">
                        <IconMore width={14} height={14} />
                      </button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        <div className="al-widgets">
          <Widget
            title="My Calendar"
            action={
              <button type="button" className="al-btn al-btn--ghost">
                View All
              </button>
            }
          >
            <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 8 }}>September 2026</div>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(7, 1fr)',
                gap: 4,
                fontSize: 11,
                textAlign: 'center',
              }}
            >
              {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => (
                <span key={d} className="muted" style={{ fontWeight: 700 }}>
                  {d}
                </span>
              ))}
              {calDays.map((d) => (
                <span
                  key={d.d}
                  style={{
                    padding: '6px 0',
                    borderRadius: 8,
                    background: d.active ? '#2563eb' : d.has ? '#dbeafe' : 'transparent',
                    color: d.active ? '#fff' : '#0f172a',
                    fontWeight: d.active || d.has ? 700 : 500,
                  }}
                >
                  {d.d}
                </span>
              ))}
            </div>
          </Widget>

          <Widget title="Quick Actions">
            <div className="al-qa-grid">
              <Link to="/appointments" className="al-btn al-btn--outline">
                <IconCalendar width={14} height={14} /> New Booking
              </Link>
              <Link to="/providers" className="al-btn al-btn--outline">
                <IconUsers width={14} height={14} /> Find a Provider
              </Link>
              <button type="button" className="al-btn al-btn--outline">
                <IconClock width={14} height={14} /> My Availability
              </button>
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setTab('saved')}
              >
                <IconUser width={14} height={14} /> Saved Providers
              </button>
            </div>
          </Widget>

          <div className="al-help-card" style={{ background: '#eff6ff' }}>
            <IconHeadset width={22} height={22} style={{ color: '#2563eb' }} />
            <strong>Need Help with Booking?</strong>
            <p>Our support team can help you find the right service.</p>
            <Link to="/support" className="al-btn al-btn--outline">
              Contact Support →
            </Link>
          </div>

          <Widget title="Upcoming Week">
            <div className="al-widget-list">
              {filtered.slice(0, 4).map((b) => (
                <div key={`w-${b.id}`} className="al-widget-item">
                  <span className="al-activity-icon al-activity-icon--blue">
                    <IconCalendar width={12} height={12} />
                  </span>
                  <div>
                    <strong>{b._title.slice(0, 28)}</strong>
                    <span>{formatWhen(b._when)}</span>
                  </div>
                </div>
              ))}
              {filtered.length === 0 ? (
                <p className="muted" style={{ margin: 0, fontSize: 12 }}>
                  No sessions this week.
                </p>
              ) : null}
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
