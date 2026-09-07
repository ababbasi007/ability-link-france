import { useEffect, useMemo, useState } from 'react'
import {
  fetchAssistanceBookings,
  fetchTravelBookings,
  setAssistanceBookingStatus,
  setTravelBookingStatus,
} from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import {
  FilterBar,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'
import {
  IconBuilding,
  IconGlobe,
  IconHeart,
  IconHeadset,
  IconMapPin,
  IconRamp,
  IconStarFill,
  IconTrain,
  IconUsers,
  IconWheelchair,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

type BookingStatus = 'confirm' | 'in_progress' | 'fulfilled' | 'cancelled'

const BROWSE_TABS = [
  { id: 'all', label: 'All' },
  { id: 'destinations', label: 'Destinations' },
  { id: 'hotels', label: 'Hotels' },
  { id: 'attractions', label: 'Attractions' },
  { id: 'experiences', label: 'Experiences' },
  { id: 'operators', label: 'Tour Operators' },
  { id: 'tips', label: 'Travel Tips' },
]

const STATUS_ACTIONS: { value: BookingStatus; label: string }[] = [
  { value: 'confirm', label: 'Confirm' },
  { value: 'in_progress', label: 'In progress' },
  { value: 'fulfilled', label: 'Fulfilled' },
  { value: 'cancelled', label: 'Cancelled' },
]

const DESTINATIONS = [
  {
    name: 'Istanbul, Türkiye',
    country: 'Türkiye',
    rating: 4.8,
    reviews: 1240,
    access: 'Very Accessible',
    tone: 'ok' as const,
    img: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=600&q=80',
  },
  {
    name: 'Barcelona, Spain',
    country: 'Spain',
    rating: 4.7,
    reviews: 980,
    access: 'Accessible',
    tone: 'ok' as const,
    img: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=600&q=80',
  },
  {
    name: 'Dubai, UAE',
    country: 'United Arab Emirates',
    rating: 4.6,
    reviews: 860,
    access: 'Very Accessible',
    tone: 'ok' as const,
    img: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=600&q=80',
  },
  {
    name: 'London, UK',
    country: 'United Kingdom',
    rating: 4.5,
    reviews: 1520,
    access: 'Partially Accessible',
    tone: 'warn' as const,
    img: 'https://images.unsplash.com/photo-1513635268270-b1951406ab64?w=600&q=80',
  },
  {
    name: 'Paris, France',
    country: 'France',
    rating: 4.4,
    reviews: 2100,
    access: 'Accessible',
    tone: 'ok' as const,
    img: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&q=80',
  },
  {
    name: 'Kuala Lumpur, Malaysia',
    country: 'Malaysia',
    rating: 4.3,
    reviews: 640,
    access: 'Partially Accessible',
    tone: 'warn' as const,
    img: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=600&q=80',
  },
  {
    name: 'New York, USA',
    country: 'United States',
    rating: 4.6,
    reviews: 1890,
    access: 'Very Accessible',
    tone: 'ok' as const,
    img: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=600&q=80',
  },
  {
    name: 'Rome, Italy',
    country: 'Italy',
    rating: 4.2,
    reviews: 1120,
    access: 'Partially Accessible',
    tone: 'warn' as const,
    img: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=600&q=80',
  },
]

const TRAVEL_TIPS = [
  {
    title: '10 Tips for Accessible Travel',
    sub: 'Practical packing & planning advice',
    icon: <IconGlobe width={16} height={16} />,
    bg: '#dbeafe',
    color: '#2563eb',
  },
  {
    title: 'Best Accessible Beaches in the World',
    sub: 'Smooth paths and beach wheelchairs',
    icon: <IconMapPin width={16} height={16} />,
    bg: '#dcfce7',
    color: '#16a34a',
  },
  {
    title: 'How to Find Accessible Hotels',
    sub: 'What to ask before you book',
    icon: <IconBuilding width={16} height={16} />,
    bg: '#ffedd5',
    color: '#ea580c',
  },
  {
    title: 'Packing Checklist',
    sub: 'Essentials for a smoother trip',
    icon: <IconTrain width={16} height={16} />,
    bg: '#ede9fe',
    color: '#7c3aed',
  },
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
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'muted' {
  switch (status) {
    case 'confirm':
    case 'confirmed':
    case 'in_progress':
      return 'warn'
    case 'fulfilled':
      return 'ok'
    case 'cancelled':
      return 'muted'
    default:
      return 'muted'
  }
}

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

export function TravelAssistanceOpsPage() {
  const [tab, setTab] = useState('all')
  const [travel, setTravel] = useState<Doc[]>([])
  const [assistance, setAssistance] = useState<Doc[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [destination, setDestination] = useState('all')
  const [category, setCategory] = useState('all')
  const [features, setFeatures] = useState('all')
  const [travelType, setTravelType] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [mapMode, setMapMode] = useState<'map' | 'list'>('map')
  const [opsView, setOpsView] = useState<'browse' | 'travel' | 'assistance'>('browse')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [t, a] = await Promise.all([
        fetchTravelBookings(150),
        fetchAssistanceBookings(150),
      ])
      setTravel(t)
      setAssistance(a)
      setUsingDemo(!t.length && !a.length)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load bookings')
      setTravel([])
      setAssistance([])
      setUsingDemo(true)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredTravel = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return travel.filter((b) => {
      if (!needle) return true
      return (
        String(b.destinationName ?? '').toLowerCase().includes(needle) ||
        String(b.service ?? '').toLowerCase().includes(needle) ||
        String(b.kind ?? '').toLowerCase().includes(needle) ||
        String(b.uid ?? '').toLowerCase().includes(needle) ||
        String(b.status ?? '').toLowerCase().includes(needle)
      )
    })
  }, [travel, q])

  const filteredAssistance = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return assistance.filter((b) => {
      if (!needle) return true
      return (
        String(b.providerId ?? '').toLowerCase().includes(needle) ||
        String(b.assistanceType ?? '').toLowerCase().includes(needle) ||
        String(b.service ?? '').toLowerCase().includes(needle) ||
        String(b.mode ?? '').toLowerCase().includes(needle) ||
        String(b.status ?? '').toLowerCase().includes(needle)
      )
    })
  }, [assistance, q])

  const setTravelStatus = async (id: string, status: BookingStatus) => {
    setBusyId(id)
    try {
      await setTravelBookingStatus(id, status)
      setTravel((prev) => prev.map((b) => (b.id === id ? { ...b, status } : b)))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const setAssistanceStatus = async (id: string, status: BookingStatus) => {
    setBusyId(id)
    try {
      await setAssistanceBookingStatus(id, status)
      setAssistance((prev) => prev.map((b) => (b.id === id ? { ...b, status } : b)))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const destCards = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return DESTINATIONS.filter((d) => {
      if (destination !== 'all') {
        const region = d.country.toLowerCase()
        if (destination === 'europe' && !['spain', 'united kingdom', 'france', 'italy'].includes(region)) {
          return false
        }
        if (destination === 'asia' && !['malaysia', 'türkiye', 'turkiye'].includes(region)) return false
        if (destination === 'me' && region !== 'united arab emirates') return false
      }
      if (!needle) return true
      return (
        d.name.toLowerCase().includes(needle) ||
        d.country.toLowerCase().includes(needle)
      )
    })
  }, [q, destination])

  const openTravelOps = () => {
    setOpsView('travel')
  }

  const openBrowse = (id: string) => {
    setOpsView('browse')
    setTab(id)
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Accessible Tourism"
        subtitle="Explore the world without limits. Find accessible destinations, hotels, attractions and experiences."
        primaryAction={{ label: 'Plan a Trip', onClick: openTravelOps }}
      />

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error && !usingDemo ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="al-hero-kpi">
        <div className="al-hero-banner al-hero-banner--tourism">
          <div className="al-hero-banner-copy">
            <h2>Travel Belongs to Everyone</h2>
            <p>Accessible journeys. Inclusive experiences. A more open world.</p>
            <button
              type="button"
              className="al-btn al-btn--dark"
              onClick={() => openBrowse('destinations')}
            >
              Explore Destinations →
            </button>
          </div>
          <blockquote className="al-hero-quote">
            “Different Abilities Same Horizons”
          </blockquote>
        </div>
        <div>
          <div className="al-kpi-stack">
            {(
              [
                {
                  label: 'Destinations',
                  value: kpiDisplay(travel.length * 8, 1250),
                  trend: '28% vs last month',
                  tone: 'blue',
                  icon: <IconMapPin width={16} height={16} />,
                },
                {
                  label: 'Accessible Hotels',
                  value: kpiDisplay(travel.length * 5, 842),
                  trend: '24% vs last month',
                  tone: 'green',
                  icon: <IconBuilding width={16} height={16} />,
                },
                {
                  label: 'Attractions',
                  value: kpiDisplay(travel.length * 4, 630),
                  trend: '19% vs last month',
                  tone: 'purple',
                  icon: <IconGlobe width={16} height={16} />,
                },
                {
                  label: 'Experiences',
                  value: kpiDisplay(assistance.length * 3, 420),
                  trend: '32% vs last month',
                  tone: 'orange',
                  icon: <IconUsers width={16} height={16} />,
                },
              ] as const
            ).map((item) => (
              <div key={item.label} className={`al-kpi al-kpi--${item.tone}`} style={{ margin: 0 }}>
                <div className="al-kpi-icon" aria-hidden>
                  {item.icon}
                </div>
                <div className="al-kpi-body">
                  <span className="al-kpi-label">{item.label}</span>
                  <strong className="al-kpi-value" style={{ fontSize: 20 }}>
                    {item.value}
                  </strong>
                  <span className="al-kpi-trend">{item.trend}</span>
                </div>
              </div>
            ))}
          </div>
          <div className="al-trip-plan-card">
            <div className="al-trip-plan-icon">
              <IconGlobe width={18} height={18} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <strong>Plan Your Accessible Trip</strong>
              <span className="muted" style={{ display: 'block', fontSize: 12.5 }}>
                Get personalized recommendations based on your needs.
              </span>
            </div>
            <button type="button" className="al-btn al-btn--primary" onClick={openTravelOps}>
              Create Trip Plan →
            </button>
          </div>
        </div>
      </div>

      {opsView === 'browse' ? (
        <>
          <TabBar tabs={BROWSE_TABS} active={tab} onChange={openBrowse} />

          <FilterBar
            search={q}
            onSearch={setQ}
            searchPlaceholder="Search destinations, hotels, attractions..."
            onReset={() => {
              setQ('')
              setDestination('all')
              setCategory('all')
              setFeatures('all')
              setTravelType('all')
            }}
          >
            <select value={destination} onChange={(e) => setDestination(e.target.value)}>
              <option value="all">Destination</option>
              <option value="europe">Europe</option>
              <option value="asia">Asia</option>
              <option value="me">Middle East</option>
            </select>
            <select value={category} onChange={(e) => setCategory(e.target.value)}>
              <option value="all">Category</option>
              <option value="hotel">Hotels</option>
              <option value="attraction">Attractions</option>
              <option value="experience">Experiences</option>
            </select>
            <select value={features} onChange={(e) => setFeatures(e.target.value)}>
              <option value="all">Accessibility Features</option>
              <option value="wheelchair">Wheelchair</option>
              <option value="sensory">Sensory-friendly</option>
            </select>
            <select value={travelType} onChange={(e) => setTravelType(e.target.value)}>
              <option value="all">Travel Type</option>
              <option value="leisure">Leisure</option>
              <option value="medical">Medical travel</option>
            </select>
          </FilterBar>
        </>
      ) : (
        <div className="al-tabs" role="tablist" style={{ marginBottom: 14 }}>
          <button
            type="button"
            role="tab"
            className={`al-tab${opsView === 'travel' ? ' active' : ''}`}
            onClick={() => setOpsView('travel')}
          >
            Travel Bookings
          </button>
          <button
            type="button"
            role="tab"
            className={`al-tab${opsView === 'assistance' ? ' active' : ''}`}
            onClick={() => setOpsView('assistance')}
          >
            Assistance
          </button>
          <button type="button" role="tab" className="al-tab" onClick={() => openBrowse('all')}>
            ← Back to browse
          </button>
        </div>
      )}

      <div className="al-split">
        <div>
          {opsView === 'browse' ? (
            <>
              {loading ? null : null}
              {tab === 'tips' ? null : (
                <>
                  <div className="al-section-head">
                    <h3>Featured Destinations</h3>
                    <button type="button" className="al-btn al-btn--ghost">
                      View All
                    </button>
                  </div>
                  <div className="al-dest-grid">
                    {destCards.map((d) => (
                      <article key={d.name} className="al-dest-card">
                        <div className="al-dest-img">
                          <img src={d.img} alt="" />
                          <button type="button" className="al-dest-fav" aria-label="Favorite">
                            <IconHeart width={14} height={14} />
                          </button>
                          <div className="al-dest-pill">
                            <StatusPill tone={d.tone}>{d.access}</StatusPill>
                          </div>
                        </div>
                        <div className="al-dest-body">
                          <strong>{d.name}</strong>
                          <div className="al-dest-rating">
                            <IconStarFill width={12} height={12} />
                            {d.rating} ({d.reviews.toLocaleString()} reviews)
                          </div>
                          <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>
                            {d.country}
                          </div>
                          <div className="al-place-feats" style={{ marginTop: 8 }}>
                            <span>
                              <IconWheelchair width={12} height={12} />
                            </span>
                            <span>
                              <IconRamp width={12} height={12} />
                            </span>
                            <span>
                              <IconTrain width={12} height={12} />
                            </span>
                            <span>
                              <IconBuilding width={12} height={12} />
                            </span>
                            <span style={{ width: 'auto', padding: '0 6px', fontSize: 11 }}>+5</span>
                          </div>
                        </div>
                      </article>
                    ))}
                  </div>
                </>
              )}

              <div style={{ marginTop: 20 }}>
                <div className="al-section-head">
                  <h3>Travel Tips & Guides</h3>
                  <button type="button" className="al-btn al-btn--ghost">
                    View All
                  </button>
                </div>
                <div className="al-tips-row">
                  {TRAVEL_TIPS.map((tip) => (
                    <div key={tip.title} className="al-tip-card">
                      <div className="icon" style={{ background: tip.bg, color: tip.color }}>
                        {tip.icon}
                      </div>
                      <strong>{tip.title}</strong>
                      <span>{tip.sub}</span>
                    </div>
                  ))}
                </div>
              </div>
            </>
          ) : opsView === 'travel' ? (
            <div className="al-table-card">
              {loading ? (
                <p className="muted" style={{ padding: 20 }}>
                  Loading…
                </p>
              ) : filteredTravel.length === 0 ? (
                <p className="muted" style={{ padding: 20 }}>
                  No travel bookings found.
                </p>
              ) : (
                <div className="table-wrap">
                  <table className="al-table">
                    <thead>
                      <tr>
                        <th>Destination</th>
                        <th>Service</th>
                        <th>Kind</th>
                        <th>Status</th>
                        <th>Start</th>
                        <th>User</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredTravel.map((b) => {
                        const status = String(b.status ?? '')
                        return (
                          <tr key={b.id}>
                            <td>{String(b.destinationName ?? '—')}</td>
                            <td>{String(b.service ?? '—')}</td>
                            <td>{String(b.kind ?? '—')}</td>
                            <td>
                              <StatusPill tone={statusTone(status)}>{status || '—'}</StatusPill>
                            </td>
                            <td>{formatWhen(b.startAt)}</td>
                            <td>
                              <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                                {String(b.uid ?? '—').slice(0, 12)}
                              </span>
                            </td>
                            <td>
                              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                {STATUS_ACTIONS.map(({ value, label }) => (
                                  <button
                                    key={value}
                                    type="button"
                                    className={`al-btn ${status === value ? 'al-btn--primary' : 'al-btn--outline'}`}
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === b.id || status === value}
                                    onClick={() => void setTravelStatus(b.id, value)}
                                  >
                                    {label}
                                  </button>
                                ))}
                              </div>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ) : (
            <div className="al-table-card">
              {loading ? (
                <p className="muted" style={{ padding: 20 }}>
                  Loading…
                </p>
              ) : filteredAssistance.length === 0 ? (
                <p className="muted" style={{ padding: 20 }}>
                  No assistance bookings found.
                </p>
              ) : (
                <div className="table-wrap">
                  <table className="al-table">
                    <thead>
                      <tr>
                        <th>Provider</th>
                        <th>Assistance type</th>
                        <th>Service</th>
                        <th>Mode</th>
                        <th>Status</th>
                        <th>Start</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredAssistance.map((b) => {
                        const status = String(b.status ?? '')
                        return (
                          <tr key={b.id}>
                            <td>
                              <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                                {String(b.providerId ?? '—')}
                              </span>
                            </td>
                            <td>{String(b.assistanceType ?? '—')}</td>
                            <td>{String(b.service ?? '—')}</td>
                            <td>{String(b.mode ?? '—')}</td>
                            <td>
                              <StatusPill tone={statusTone(status)}>{status || '—'}</StatusPill>
                            </td>
                            <td>{formatWhen(b.startAt)}</td>
                            <td>
                              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                {STATUS_ACTIONS.map(({ value, label }) => (
                                  <button
                                    key={value}
                                    type="button"
                                    className={`al-btn ${status === value ? 'al-btn--primary' : 'al-btn--outline'}`}
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === b.id || status === value}
                                    onClick={() => void setAssistanceStatus(b.id, value)}
                                  >
                                    {label}
                                  </button>
                                ))}
                              </div>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>

        <div className="al-widgets">
          <Widget
            title="Map"
            action={
              <div className="al-map-toggle" style={{ position: 'static' }}>
                <button
                  type="button"
                  className={mapMode === 'map' ? 'active' : ''}
                  onClick={() => setMapMode('map')}
                >
                  Map
                </button>
                <button
                  type="button"
                  className={mapMode === 'list' ? 'active' : ''}
                  onClick={() => setMapMode('list')}
                >
                  List
                </button>
              </div>
            }
          >
            {mapMode === 'map' ? (
              <div className="al-map-canvas al-map-canvas--rail">
                <div
                  className="al-map-pin al-map-pin--blue"
                  style={{ left: '28%', top: '42%' }}
                >
                  <IconMapPin width={12} height={12} />
                </div>
                <div
                  className="al-map-pin al-map-pin--green active"
                  style={{ left: '48%', top: '36%' }}
                >
                  <IconMapPin width={12} height={12} />
                </div>
                <div
                  className="al-map-pin al-map-pin--orange"
                  style={{ left: '62%', top: '58%' }}
                >
                  <IconMapPin width={12} height={12} />
                </div>
                <div className="al-map-popover">
                  <img
                    src="https://images.unsplash.com/photo-1583422409516-2895a77efded?w=200&q=80"
                    alt=""
                  />
                  <div>
                    <strong>Barcelona, Spain</strong>
                    <div className="al-dest-rating" style={{ marginTop: 2 }}>
                      <IconStarFill width={11} height={11} /> 4.7 · Accessible
                    </div>
                    <div className="al-place-feats" style={{ marginTop: 6 }}>
                      <span>
                        <IconWheelchair width={11} height={11} />
                      </span>
                      <span>
                        <IconRamp width={11} height={11} />
                      </span>
                      <span>
                        <IconTrain width={11} height={11} />
                      </span>
                    </div>
                    <button
                      type="button"
                      className="al-btn al-btn--ghost"
                      style={{ padding: 0, marginTop: 6 }}
                    >
                      View Details →
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="al-widget-list">
                {DESTINATIONS.slice(0, 5).map((d) => (
                  <div key={d.name} className="al-widget-item">
                    <div>
                      <strong>{d.name}</strong>
                      <span>
                        {d.rating} ★ · {d.access}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Widget>

          <Widget title="Popular Travel Categories">
            <div className="al-pop-cats">
              {[
                [
                  'Accessible Hotels',
                  '#ede9fe',
                  '#7c3aed',
                  <IconBuilding key="b" width={16} height={16} />,
                ],
                ['Attractions', '#dcfce7', '#16a34a', <IconGlobe key="g" width={16} height={16} />],
                ['Experiences', '#ffedd5', '#ea580c', <IconUsers key="u" width={16} height={16} />],
                [
                  'Accessible Transport',
                  '#dbeafe',
                  '#2563eb',
                  <IconTrain key="t" width={16} height={16} />,
                ],
                [
                  'Tour Operators',
                  '#fce7f3',
                  '#db2777',
                  <IconHeadset key="h" width={16} height={16} />,
                ],
              ].map(([label, bg, color, icon]) => (
                <button key={String(label)} type="button" className="al-pop-cat">
                  <span className="icon" style={{ background: String(bg), color: String(color) }}>
                    {icon}
                  </span>
                  {label}
                </button>
              ))}
            </div>
          </Widget>

          <div className="al-help-card">
            <IconHeadset width={22} height={22} color="#2563eb" />
            <strong>Need Help Planning?</strong>
            <p>
              Our travel experts can help you create an accessible itinerary based on your needs.
            </p>
            <button type="button" className="al-btn al-btn--primary">
              Get Support →
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
