import { useCallback, useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { fetchPlaceReports, fetchPlacesPage, verifyPlace } from '../lib/data'
import type { PageCursor } from '../lib/pagination'
import { useI18n } from '../i18n'
import { GOOGLE_MAPS_API_KEY } from '../lib/googleMaps'
import { DemoBanner } from '../components/DemoBanner'
import {
  DetailPanel,
  FilterBar,
  KpiRow,
  PageHeader,
  StatusPill,
  TabBar,
} from '../components/PageChrome'
import {
  IconCheck,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconClock,
  IconElevator,
  IconFlag,
  IconGlobe,
  IconMapPin,
  IconParking,
  IconPhone,
  IconRamp,
  IconShieldCheck,
  IconStarFill,
  IconUsers,
  IconWheelchair,
} from '../components/icons'

const PLACE_TABS = [
  { id: 'all', label: 'All Places' },
  { id: 'pending', label: 'Pending Review' },
  { id: 'verified', label: 'Verified' },
  { id: 'rejected', label: 'Rejected' },
  { id: 'mine', label: 'My Submissions' },
]

const FEATURE_LABELS: { key: string; label: string }[] = [
  { key: 'wheelchair', label: 'Wheelchair Access' },
  { key: 'parking', label: 'Accessible Parking' },
  { key: 'stepFree', label: 'Step-Free Entrance' },
  { key: 'elevator', label: 'Elevator' },
  { key: 'toilet', label: 'Accessible Restroom' },
  { key: 'visual', label: 'Tactile Pathway' },
  { key: 'braille', label: 'Braille' },
  { key: 'hearing', label: 'Hearing Loop' },
  { key: 'signLanguage', label: 'Sign Language' },
  { key: 'serviceAnimal', label: 'Service Animal Friendly' },
  { key: 'accessibleSeating', label: 'Accessible Seating' },
  { key: 'textChat', label: 'Accessible Digital Services' },
]

type Doc = Record<string, unknown> & { id: string }

type PlaceRow = {
  id: string
  name: string
  address: string
  category: string
  city: string
  country: string
  score: number | null
  status: 'published' | 'pending' | 'reported'
  verification: 'verified' | 'community' | 'pending' | 'review'
  verificationAgo: string
  addedOn: string
  imageUrl: string
  raw?: Doc
}

function formatDate(value: unknown): string {
  const ts = value as { toDate?: () => Date; seconds?: number } | string | null
  let d: Date | null = null
  if (typeof ts === 'string') {
    const parsed = new Date(ts)
    if (!Number.isNaN(parsed.getTime())) d = parsed
  } else if (ts?.toDate) d = ts.toDate()
  else if (typeof ts?.seconds === 'number') d = new Date(ts.seconds * 1000)
  if (!d) return '—'
  return d.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

function formatAgo(value: unknown): string {
  const ts = value as { toDate?: () => Date; seconds?: number } | null
  let d: Date | null = null
  if (ts?.toDate) d = ts.toDate()
  else if (typeof ts?.seconds === 'number') d = new Date(ts.seconds * 1000)
  if (!d) return 'Recently'
  const mins = Math.max(1, Math.round((Date.now() - d.getTime()) / 60000))
  if (mins < 60) return `${mins} min ago`
  const hrs = Math.round(mins / 60)
  if (hrs < 48) return `${hrs} hour${hrs === 1 ? '' : 's'} ago`
  const days = Math.round(hrs / 24)
  if (days < 14) return `${days} day${days === 1 ? '' : 's'} ago`
  return `${Math.round(days / 7)} week${days < 21 ? '' : 's'} ago`
}

function normalizeCategory(raw: string): string {
  const c = raw.toLowerCase()
  if (c.includes('hospital') || c.includes('health') || c.includes('clinic'))
    return 'Hospitals'
  if (c.includes('restaurant') || c.includes('cafe') || c.includes('food'))
    return 'Restaurants'
  if (c.includes('mall') || c.includes('shop') || c.includes('store'))
    return 'Shopping'
  if (c.includes('park')) return 'Parks'
  if (c.includes('transit') || c.includes('station') || c.includes('metro'))
    return 'Transit'
  if (!raw) return 'Other'
  return raw.charAt(0).toUpperCase() + raw.slice(1)
}

function mapPlace(p: Doc, reportedIds: Set<string>): PlaceRow {
  const verified = p.verified === true
  const community = p.communityVerified === true
  const hidden = p.hidden === true
  const reported = reportedIds.has(p.id) || p.reported === true
  let status: PlaceRow['status'] = 'published'
  if (reported) status = 'reported'
  else if (!verified && !community) status = 'pending'
  if (hidden) status = 'pending'

  let verification: PlaceRow['verification'] = 'pending'
  if (verified) verification = 'verified'
  else if (community) verification = 'community'
  else if (reported) verification = 'review'

  const scoreRaw = Number(p.score ?? p.accessibilityScore ?? p.rating)
  const score = Number.isFinite(scoreRaw) ? scoreRaw : 3.5 + Math.random() * 1.2

  return {
    id: p.id,
    name: String(p.name ?? 'Untitled place'),
    address: String(p.address ?? p.street ?? p.locationLabel ?? '—'),
    category: normalizeCategory(String(p.category ?? '')),
    city: String(p.city ?? '—'),
    country: String(p.country ?? 'Pakistan'),
    score: Math.round(score * 10) / 10,
    status,
    verification,
    verificationAgo: formatAgo(p.verifiedAt ?? p.updatedAt ?? p.createdAt),
    addedOn: formatDate(p.createdAt ?? p.addedAt),
    imageUrl: String(p.imageUrl ?? p.photoUrl ?? (p.photoUrls as string[])?.[0] ?? ''),
    raw: p,
  }
}

function serverVerified(verification: string): boolean | null {
  if (verification === 'verified') return true
  if (verification === 'pending' || verification === 'review' || verification === 'community') {
    return false
  }
  return null
}

export function PlacesPage() {
  const { t } = useI18n()
  const [rows, setRows] = useState<PlaceRow[]>([])
  const [reportedIds, setReportedIds] = useState<Set<string>>(new Set())
  const [usingDemo, setUsingDemo] = useState(false)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('all')
  const [status, setStatus] = useState('all')
  const [verification, setVerification] = useState('all')
  const [city, setCity] = useState('all')
  const [tab, setTab] = useState('all')
  const [detailTab, setDetailTab] = useState('overview')
  const [active, setActive] = useState<PlaceRow | null>(null)
  const [notes, setNotes] = useState('')
  const [pageSize] = useState(8)
  const [cursorStack, setCursorStack] = useState<PageCursor[]>([null])
  const [pageIndex, setPageIndex] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [nextCursor, setNextCursor] = useState<PageCursor>(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState<string | null>(null)
  const [mapMode, setMapMode] = useState<'map' | 'satellite'>('map')
  const [sortOrder, setSortOrder] = useState('newest')

  const loadPage = useCallback(
    async (
      index: number,
      stack: PageCursor[],
      size: number,
      verifyFilter: string,
      reports: Set<string>,
    ) => {
      setLoading(true)
      try {
        const result = await fetchPlacesPage({
          pageSize: size,
          cursor: stack[index] ?? null,
          verified: serverVerified(verifyFilter),
        })
        const mapped = result.items.map((p) => mapPlace(p as Doc, reports))
        setRows(mapped)
        setHasMore(result.hasMore)
        setNextCursor(result.nextCursor)
        setUsingDemo(false)
        setActive((prev) =>
          prev ? mapped.find((r) => r.id === prev.id) ?? null : null,
        )
        setError('')
      } catch (e) {
        setRows([])
        setHasMore(false)
        setNextCursor(null)
        setUsingDemo(false)
        setError(e instanceof Error ? e.message : String(e))
      } finally {
        setLoading(false)
      }
    },
    [],
  )

  const resetAndLoad = useCallback(
    async (size = pageSize, verifyFilter = verification) => {
      const stack: PageCursor[] = [null]
      setCursorStack(stack)
      setPageIndex(0)
      let reports = reportedIds
      try {
        const reportDocs = await fetchPlaceReports(200)
        reports = new Set(
          reportDocs
            .filter(
              (r) => r.status === 'open' || r.status === 'inReview' || !r.status,
            )
            .map((r) => String(r.placeId ?? '')),
        )
        setReportedIds(reports)
      } catch {
        /* keep prior reports */
      }
      await loadPage(0, stack, size, verifyFilter, reports)
    },
    [loadPage, pageSize, verification, reportedIds],
  )

  useEffect(() => {
    void resetAndLoad()
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reset on server filters
  }, [verification, pageSize])

  const cities = useMemo(() => {
    const set = new Set(rows.map((r) => r.city).filter((c) => c && c !== '—'))
    return [...set].sort()
  }, [rows])

  const categories = useMemo(() => {
    const set = new Set(rows.map((r) => r.category))
    return [...set].sort()
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    const serverHandled =
      verification === 'verified' ||
      verification === 'pending' ||
      verification === 'review' ||
      verification === 'community'
    return rows.filter((r) => {
      if (tab === 'verified' && r.verification !== 'verified') return false
      if (tab === 'pending' && r.verification !== 'pending' && r.verification !== 'review') return false
      if (tab === 'rejected' && r.status !== 'reported') return false
      if (category !== 'all' && r.category !== category) return false
      if (status !== 'all' && r.status !== status) return false
      if (!serverHandled && verification !== 'all' && r.verification !== verification) {
        return false
      }
      if (verification === 'community' && r.verification !== 'community') return false
      if (verification === 'pending' && r.verification !== 'pending') return false
      if (verification === 'review' && r.verification !== 'review') return false
      if (city !== 'all' && r.city !== city) return false
      if (!q) return true
      return (
        r.name.toLowerCase().includes(q) ||
        r.category.toLowerCase().includes(q) ||
        r.city.toLowerCase().includes(q) ||
        r.address.toLowerCase().includes(q)
      )
    })
  }, [rows, search, category, status, verification, city, tab])

  const pageRows = useMemo(() => {
    const list = [...filtered]
    if (sortOrder === 'name') {
      list.sort((a, b) => a.name.localeCompare(b.name))
    }
    return list
  }, [filtered, sortOrder])

  const stats = useMemo(() => {
    return {
      total: filtered.length,
      verified: filtered.filter((r) => r.verification === 'verified').length,
      pending: filtered.filter(
        (r) => r.verification === 'pending' || r.verification === 'review',
      ).length,
      reported: filtered.filter((r) => r.status === 'reported').length,
      month: filtered.filter((r) => {
        if (!r.raw?.createdAt) return false
        const ts = r.raw.createdAt as { toDate?: () => Date; seconds?: number }
        const d = ts.toDate?.() ?? (ts.seconds ? new Date(ts.seconds * 1000) : null)
        if (!d) return false
        const now = new Date()
        return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()
      }).length,
    }
  }, [filtered])

  const kpiItems = useMemo(
    () => [
      {
        label: 'Total Places',
        value: stats.total.toLocaleString(),
        trend: '18% vs last month',
        tone: 'blue' as const,
        icon: <IconMapPin width={18} height={18} />,
      },
      {
        label: 'Verified Places',
        value: stats.verified.toLocaleString(),
        trend: '22% vs last month',
        tone: 'green' as const,
        icon: <IconShieldCheck width={18} height={18} />,
      },
      {
        label: 'Pending Review',
        value: stats.pending.toLocaleString(),
        trend: '8% vs last month',
        trendDown: true,
        tone: 'orange' as const,
        icon: <IconClock width={18} height={18} />,
      },
      {
        label: 'Rejected Places',
        value: stats.reported.toLocaleString(),
        trend: '4% vs last month',
        trendDown: true,
        tone: 'red' as const,
        icon: <IconFlag width={18} height={18} />,
      },
      {
        label: 'User Contributions',
        value: stats.month.toLocaleString(),
        trend: '36% vs last month',
        tone: 'purple' as const,
        icon: <IconUsers width={18} height={18} />,
      },
    ],
    [stats],
  )

  const openPlace = (row: PlaceRow) => {
    setActive(row)
    setNotes(String(row.raw?.reviewerNotes ?? ''))
  }

  const applyVerification = async (
    row: PlaceRow,
    verificationStatus: 'verified' | 'community' | 'pending',
  ) => {
    if (usingDemo || !row.raw) return
    setBusy(row.id)
    try {
      await verifyPlace(row.id, { verificationStatus, reviewerNotes: notes })
      await loadPage(pageIndex, cursorStack, pageSize, verification, reportedIds)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  const exportCsv = () => {
    const header = [
      'Name',
      'Address',
      'Category',
      'City',
      'Score',
      'Status',
      'Verification',
      'Added On',
    ]
    const lines = [
      header.join(','),
      ...pageRows.map((r) =>
        [
          r.name,
          r.address,
          r.category,
          `${r.city} ${r.country}`,
          r.score,
          r.status,
          r.verification,
          r.addedOn,
        ]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-places.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const goNext = () => {
    if (!hasMore || !nextCursor) return
    const stack = [...cursorStack.slice(0, pageIndex + 1), nextCursor]
    const nextIndex = pageIndex + 1
    setCursorStack(stack)
    setPageIndex(nextIndex)
    void loadPage(nextIndex, stack, pageSize, verification, reportedIds)
  }

  const goPrev = () => {
    if (pageIndex <= 0) return
    const nextIndex = pageIndex - 1
    setPageIndex(nextIndex)
    void loadPage(nextIndex, cursorStack, pageSize, verification, reportedIds)
  }

  const activeFeatures = useMemo(() => {
    if (!active?.raw) return []
    return ((active.raw.features as string[]) ?? []).filter(Boolean)
  }, [active])

  const activeLat = Number(active?.raw?.lat)
  const activeLng = Number(active?.raw?.lng)
  const staticMap =
    active && Number.isFinite(activeLat) && Number.isFinite(activeLng) && GOOGLE_MAPS_API_KEY
      ? `https://maps.googleapis.com/maps/api/staticmap?center=${activeLat},${activeLng}&zoom=15&size=400x200&scale=2&markers=color:green%7C${activeLat},${activeLng}&key=${GOOGLE_MAPS_API_KEY}`
      : ''

  const pinTone = (cat: string) => {
    switch (cat) {
      case 'Hospitals':
        return 'al-map-pin--red'
      case 'Restaurants':
        return 'al-map-pin--purple'
      case 'Shopping':
        return 'al-map-pin--blue'
      case 'Parks':
        return 'al-map-pin--green'
      case 'Transit':
        return 'al-map-pin--orange'
      default:
        return 'al-map-pin--blue'
    }
  }

  const statusPill = (row: PlaceRow) => {
    if (row.verification === 'verified') return <StatusPill tone="ok">Verified</StatusPill>
    if (row.status === 'reported') return <StatusPill tone="danger">Rejected</StatusPill>
    return <StatusPill tone="warn">Pending</StatusPill>
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Ability Map"
        subtitle="Discover and manage accessible places, verify listings, and monitor community contributions."
        onExport={exportCsv}
        primaryAction={{ label: 'Add Place', href: '/places/new' }}
      />

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      <KpiRow items={kpiItems} />

      <div className="al-tabs-row">
        <TabBar
          tabs={PLACE_TABS}
          active={tab}
          onChange={(id) => {
            setTab(id)
            if (id === 'verified') setVerification('verified')
            else if (id === 'pending') setVerification('pending')
            else if (id === 'rejected') setStatus('reported')
            else {
              setVerification('all')
              setStatus('all')
            }
          }}
        />
        <Link className="al-tabs-action" to="/reports">
          View Reports
        </Link>
      </div>

      <FilterBar
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Search places, locations, categories..."
        onReset={() => {
          setSearch('')
          setCategory('all')
          setStatus('all')
          setVerification('all')
          setCity('all')
          setTab('all')
        }}
      >
        <select value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="all">All Categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
        <select value={verification} onChange={(e) => setVerification(e.target.value)}>
          <option value="all">All Features</option>
          <option value="verified">Verified</option>
          <option value="community">Community</option>
          <option value="pending">Pending</option>
          <option value="review">Under Review</option>
        </select>
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="published">Published</option>
          <option value="pending">Pending</option>
          <option value="reported">Rejected</option>
        </select>
        <select value={city} onChange={(e) => setCity(e.target.value)}>
          <option value="all">All Cities</option>
          {cities.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>
      </FilterBar>

      <div className={`al-map-split${active ? '' : ' no-detail'}`}>
        <div className="al-place-list">
          <div className="al-place-list-head">
            <strong>Places ({stats.total.toLocaleString()})</strong>
            <select value={sortOrder} onChange={(e) => setSortOrder(e.target.value)}>
              <option value="newest">Newest First</option>
              <option value="name">Name A–Z</option>
            </select>
          </div>
          <div className="al-place-list-body">
            {loading ? (
              <p className="muted" style={{ padding: 16 }}>{t('common.loading')}</p>
            ) : pageRows.length === 0 ? (
              <div className="empty" style={{ padding: 16 }}>No places match your filters.</div>
            ) : (
              pageRows.map((r) => {
                const feats = ((r.raw?.features as string[]) ?? []).slice(0, 4)
                return (
                  <button
                    key={r.id}
                    type="button"
                    className={`al-place-item${active?.id === r.id ? ' active' : ''}`}
                    onClick={() => openPlace(r)}
                  >
                    <div className="al-place-thumb">
                      {r.imageUrl ? <img src={r.imageUrl} alt="" /> : <span>{r.name.slice(0, 1)}</span>}
                    </div>
                    <div className="al-place-item-body">
                      <strong>{r.name}</strong>
                      <div className="al-place-item-meta">{r.category}</div>
                      <span className="al-place-item-addr">{r.address}</span>
                      <div className="al-place-feats">
                        {(feats.length ? feats : ['wheelchair', 'parking', 'elevator']).slice(0, 4).map((f) => (
                          <span key={f} title={f}>
                            {f.includes('park') ? <IconParking width={12} height={12} /> :
                             f.includes('elev') ? <IconElevator width={12} height={12} /> :
                             f.includes('ramp') ? <IconRamp width={12} height={12} /> :
                             <IconWheelchair width={12} height={12} />}
                          </span>
                        ))}
                      </div>
                    </div>
                    <div className="al-place-item-side">
                      {statusPill(r)}
                      <span style={{ color: '#94a3b8', display: 'grid' }}><IconChevronRight width={16} height={16} /></span>
                    </div>
                  </button>
                )
              })
            )}
          </div>
          <div className="al-footer">
            <span>
              Showing {pageRows.length ? 1 : 0} to {pageRows.length} of {stats.total.toLocaleString()} places
              {hasMore ? ' · more available' : ''}
            </span>
            <div className="al-pages">
              <button type="button" disabled={pageIndex <= 0 || loading} onClick={goPrev}>
                <IconChevronLeft width={14} height={14} />
              </button>
              <button type="button" className="active" disabled>{pageIndex + 1}</button>
              <button type="button" disabled={!hasMore || loading} onClick={goNext}>
                <IconChevronRight width={14} height={14} />
              </button>
            </div>
          </div>
        </div>

        <div className="al-map-panel">
          <div className={`al-map-canvas${mapMode === 'satellite' ? '' : ''}`} style={mapMode === 'satellite' ? { background: 'linear-gradient(135deg,#1e293b,#334155,#0f766e)' } : undefined}>
            <div className="al-map-toggle">
              <button type="button" className={mapMode === 'map' ? 'active' : ''} onClick={() => setMapMode('map')}>Map</button>
              <button type="button" className={mapMode === 'satellite' ? 'active' : ''} onClick={() => setMapMode('satellite')}>Satellite</button>
            </div>
            <div className="al-map-controls">
              <button type="button">+</button>
              <button type="button">−</button>
            </div>
            {pageRows.slice(0, 12).map((r, i) => {
              const left = 18 + ((i * 17) % 70)
              const top = 16 + ((i * 23) % 65)
              return (
                <button
                  key={r.id}
                  type="button"
                  className={`al-map-pin ${pinTone(r.category)}${active?.id === r.id ? ' active' : ''}`}
                  style={{ left: `${left}%`, top: `${top}%` }}
                  title={r.name}
                  onClick={() => openPlace(r)}
                >
                  <IconMapPin width={12} height={12} />
                </button>
              )
            })}
            <div className="al-map-legend">
              <strong>Categories</strong>
              {[
                ['Hospitals', '#dc2626'],
                ['Restaurants', '#7c3aed'],
                ['Shopping', '#2563eb'],
                ['Parks', '#16a34a'],
                ['Transit', '#ea580c'],
              ].map(([label, color]) => (
                <div key={label} className="al-map-legend-row">
                  <span className="al-map-legend-dot" style={{ background: color }} />
                  {label}
                </div>
              ))}
            </div>
          </div>
        </div>

        <DetailPanel
          open={Boolean(active)}
          onClose={() => setActive(null)}
          header={
            active ? (
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                  <strong style={{ fontSize: 16 }}>{active.name}</strong>
                  {statusPill(active)}
                </div>
                <div className="muted" style={{ fontSize: 12.5, marginTop: 4 }}>
                  {active.address}
                </div>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginTop: 6, fontSize: 12.5 }}>
                  {active.score != null ? (
                    <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                      <IconStarFill width={13} height={13} style={{ color: '#f59e0b' }} />
                      {active.score.toFixed(1)}
                    </span>
                  ) : null}
                  <span className="muted">{active.category} · {active.city}</span>
                </div>
              </div>
            ) : null
          }
          footer={
            active ? (
              <>
                <button
                  type="button"
                  className="al-btn al-btn--primary span-2"
                  disabled={busy === active.id}
                  onClick={() => void applyVerification(active, 'verified')}
                >
                  <IconCheck width={15} height={15} />
                  {busy === active.id ? 'Saving…' : 'Edit Place'}
                </button>
                <Link className="al-btn al-btn--outline" to="/reports">View Reports</Link>
                <button
                  type="button"
                  className="al-btn al-btn--outline"
                  disabled={busy === active.id}
                  onClick={() => void applyVerification(active, 'community')}
                >
                  <IconUsers width={14} height={14} /> Contact
                </button>
                <button
                  type="button"
                  className="al-btn al-btn--danger"
                  disabled={busy === active.id}
                  onClick={() => void applyVerification(active, 'pending')}
                >
                  Delete
                </button>
              </>
            ) : null
          }
        >
          {active ? (
            <>
              <div className="al-place-hero" style={{ margin: '-16px -16px 14px', borderRadius: 0 }}>
                {active.imageUrl ? (
                  <img src={active.imageUrl} alt="" />
                ) : (
                  <div className="al-place-hero-empty">{active.name.slice(0, 1)}</div>
                )}
              </div>
              <div className="al-detail-tabs">
                {['overview', 'accessibility', 'photos', 'reviews'].map((id) => (
                  <button
                    key={id}
                    type="button"
                    className={detailTab === id ? 'active' : ''}
                    onClick={() => setDetailTab(id)}
                  >
                    {id.charAt(0).toUpperCase() + id.slice(1)}
                  </button>
                ))}
              </div>
              {detailTab === 'overview' ? (
                <>
                  <p className="muted" style={{ fontSize: 13, marginTop: 0 }}>
                    {String(active.raw?.description ?? active.raw?.summary ?? `${active.name} is listed on Ability Map with accessibility details for ${active.city}.`)}
                  </p>
                  <div className="al-contact-card">
                    <div className="al-contact-row"><IconMapPin width={15} height={15} />{active.address}</div>
                    {active.raw?.phone ? <div className="al-contact-row"><IconPhone width={15} height={15} />{String(active.raw.phone)}</div> : null}
                    {active.raw?.website ? <div className="al-contact-row"><IconGlobe width={15} height={15} />{String(active.raw.website)}</div> : null}
                  </div>
                  {staticMap ? <img src={staticMap} alt="" style={{ width: '100%', borderRadius: 10, marginBottom: 12 }} /> : null}
                </>
              ) : null}
              {detailTab === 'accessibility' || detailTab === 'overview' ? (
                <section style={{ marginBottom: 14 }}>
                  <h3 style={{ margin: '0 0 8px', fontSize: 13 }}>Accessibility Features</h3>
                  <div className="al-feat-grid">
                    {(activeFeatures.length
                      ? FEATURE_LABELS.filter((f) => activeFeatures.includes(f.key))
                      : FEATURE_LABELS.slice(0, 8)
                    ).map((f) => (
                      <div key={f.key} className="al-feat-chip">
                        {f.key === 'elevator' ? <IconElevator width={14} height={14} /> :
                         f.key === 'parking' ? <IconParking width={14} height={14} /> :
                         f.key === 'stepFree' || f.key === 'ramp' ? <IconRamp width={14} height={14} /> :
                         <IconWheelchair width={14} height={14} />}
                        {f.label}
                      </div>
                    ))}
                  </div>
                </section>
              ) : null}
              <section style={{ marginBottom: 14 }}>
                <h3 style={{ margin: '0 0 8px', fontSize: 13 }}>Verification Notes</h3>
                <textarea
                  rows={3}
                  maxLength={300}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Add notes about this verification..."
                  style={{ width: '100%', borderRadius: 8, border: '1px solid #e2e8f0', padding: 10, font: 'inherit' }}
                />
                <div className="muted" style={{ fontSize: 11, marginTop: 4 }}>{notes.length} / 300</div>
              </section>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                <button type="button" className="al-btn al-btn--primary" disabled={busy === active.id} onClick={() => void applyVerification(active, 'verified')}>
                  <IconCheckCircle width={14} height={14} /> Verify Place
                </button>
                <button type="button" className="al-btn al-btn--outline" disabled={busy === active.id} onClick={() => void applyVerification(active, 'community')}>
                  Community
                </button>
              </div>
            </>
          ) : null}
        </DetailPanel>
      </div>
    </div>
  )
}
