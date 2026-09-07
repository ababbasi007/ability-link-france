import { useEffect, useMemo, useState, type ReactNode } from 'react'
import {
  approveSubmission,
  fetchAllPlaceSubmissions,
  fetchPlaceReports,
  setSubmissionStatus,
} from '../lib/data'
import { GOOGLE_MAPS_API_KEY } from '../lib/googleMaps'
import { DemoBanner } from '../components/DemoBanner'
import {
  IconBuilding,
  IconCheck,
  IconChevronLeft,
  IconChevronRight,
  IconClock,
  IconCross,
  IconEye,
  IconFilter,
  IconGlobe,
  IconInfo,
  IconMapPin,
  IconPhone,
  IconSearch,
  IconShieldCheck,
  IconShoppingBag,
  IconTrain,
  IconTree,
  IconUtensils,
  IconX,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }
type StatusKey = 'pending' | 'inReview' | 'approved' | 'rejected' | 'reported'

type Row = {
  id: string
  name: string
  address: string
  category: string
  addedByName: string
  addedByHandle: string
  addedAgo: string
  status: StatusKey
  imageUrl: string
  photos: string[]
  phone: string
  website: string
  hours: string
  description: string
  features: string[]
  lat: number
  lng: number
  raw: Doc
}

const FEATURE_LABELS: { key: string; label: string }[] = [
  { key: 'wheelchair', label: 'Wheelchair Access' },
  { key: 'ramp', label: 'Ramp' },
  { key: 'parking', label: 'Accessible Parking' },
  { key: 'toilet', label: 'Accessible Restroom' },
  { key: 'elevator', label: 'Elevator' },
  { key: 'stepFree', label: 'Step-Free Entrance' },
  { key: 'visual', label: 'Tactile Paving' },
  { key: 'hearing', label: 'Hearing Assistance' },
  { key: 'braille', label: 'Braille' },
  { key: 'serviceAnimal', label: 'Service Animal' },
  { key: 'wideCorridors', label: 'Wide Doorways' },
  { key: 'lowVisionFriendly', label: 'Low Vision Friendly' },
  { key: 'audioAnnouncements', label: 'Audio Assistance' },
  { key: 'accessibleTransit', label: 'Accessible Pathways' },
]


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
  return `${Math.round(hrs / 24)} day${hrs < 48 ? '' : 's'} ago`
}

function normalizeCategory(raw: string): string {
  const c = raw.toLowerCase()
  if (c.includes('hospital') || c.includes('health')) return 'Hospitals'
  if (c.includes('restaurant') || c.includes('cafe') || c.includes('food'))
    return 'Restaurants'
  if (c.includes('mall') || c.includes('shop')) return 'Shopping'
  if (c.includes('park')) return 'Parks'
  if (c.includes('transit') || c.includes('metro')) return 'Transit'
  if (!raw) return 'Other'
  return raw.charAt(0).toUpperCase() + raw.slice(1)
}

function categoryIcon(cat: string): { icon: ReactNode; tone: string } {
  switch (cat) {
    case 'Hospitals':
      return { icon: <IconCross width={14} height={14} />, tone: 'cat-pink' }
    case 'Restaurants':
      return { icon: <IconUtensils width={14} height={14} />, tone: 'cat-purple' }
    case 'Shopping':
      return { icon: <IconShoppingBag width={14} height={14} />, tone: 'cat-blue' }
    case 'Parks':
      return { icon: <IconTree width={14} height={14} />, tone: 'cat-green' }
    case 'Transit':
      return { icon: <IconTrain width={14} height={14} />, tone: 'cat-slate' }
    default:
      return { icon: <IconBuilding width={14} height={14} />, tone: 'cat-slate' }
  }
}

function mapStatus(raw: string): StatusKey {
  const s = raw.toLowerCase()
  if (s === 'approved' || s === 'verified') return 'approved'
  if (s === 'rejected' || s === 'denied') return 'rejected'
  if (s === 'inreview' || s === 'in_review' || s === 'review' || s === 'needsinfo')
    return 'inReview'
  if (s === 'reported') return 'reported'
  return 'pending'
}

function mapRow(d: Doc): Row {
  const name = String(d.name ?? d.placeName ?? 'Untitled place')
  const uid = String(d.uid ?? d.userId ?? 'user')
  const addedByName = String(d.submitterName ?? d.userName ?? uid.slice(0, 10))
  const photos = [
    ...(((d.photoUrls as string[]) ?? []).filter(Boolean)),
    String(d.imageUrl ?? d.photoUrl ?? ''),
  ].filter(Boolean)
  return {
    id: d.id,
    name,
    address: String(d.address ?? d.city ?? '—'),
    category: normalizeCategory(String(d.categoryLabel ?? d.category ?? '')),
    addedByName,
    addedByHandle: `@${addedByName.toLowerCase().replace(/\s+/g, '_').slice(0, 12)}`,
    addedAgo: formatAgo(d.createdAt),
    status: mapStatus(String(d.status ?? 'pending')),
    imageUrl: photos[0] ?? '',
    photos,
    phone: String(d.phone ?? ''),
    website: String(d.website ?? ''),
    hours: String(d.hours ?? 'Hours not set'),
    description: String(
      d.description ??
        d.notes ??
        'No description provided.',
    ),
    features: (d.features as string[]) ?? [],
    lat: Number(d.lat),
    lng: Number(d.lng),
    raw: d,
  }
}

function statusPill(status: StatusKey) {
  if (status === 'pending') return <span className="v-pill v-pill-pending">Pending</span>
  if (status === 'inReview') return <span className="v-pill v-pill-review">In Review</span>
  if (status === 'approved') return <span className="v-pill v-pill-ok">Verified</span>
  if (status === 'rejected') return <span className="v-pill v-pill-reject">Rejected</span>
  return <span className="v-pill v-pill-report">Reported</span>
}

export function VerificationsPage() {
  const [rows, setRows] = useState<Row[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [reportedCount, setReportedCount] = useState(0)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [tab, setTab] = useState<'all' | 'pending' | 'inReview' | 'reviewed' | 'reported'>(
    'all',
  )
  const [sort, setSort] = useState('newest')
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [activeId, setActiveId] = useState<string | null>(null)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [panelTab, setPanelTab] = useState<'details' | 'accessibility' | 'photos' | 'activity'>(
    'details',
  )
  const [photoIdx, setPhotoIdx] = useState(0)
  const [notes, setNotes] = useState('')
  const [showAllFeatures, setShowAllFeatures] = useState(false)

  const reload = async () => {
    try {
      const [subs, reports] = await Promise.all([
        fetchAllPlaceSubmissions(200),
        fetchPlaceReports(100),
      ])
      const openReports = reports.filter(
        (r) => r.status === 'open' || r.status === 'inReview' || !r.status,
      ).length
      if (!subs.length) {
        setRows([])
        setUsingDemo(false)
        setReportedCount(openReports)
        setActiveId(null)
      } else {
        const mapped = subs.map(mapRow)
        setRows(mapped)
        setUsingDemo(false)
        setReportedCount(openReports)
        setActiveId((prev) =>
          mapped.some((m) => m.id === prev) ? prev : mapped[0]?.id ?? null,
        )
      }
      setError('')
    } catch (e) {
      setRows([])
      setUsingDemo(false)
      setReportedCount(0)
      setActiveId(null)
      setError(e instanceof Error ? e.message : String(e))
    }
  }

  useEffect(() => {
    void reload()
  }, [])

  const stats = useMemo(() => {
    return {
      pending: rows.filter((r) => r.status === 'pending').length,
      inReview: rows.filter((r) => r.status === 'inReview').length,
      verified: rows.filter((r) => r.status === 'approved').length,
      rejected: rows.filter((r) => r.status === 'rejected').length,
    }
  }, [rows])

  const filtered = useMemo(() => {
    let list = [...rows]
    if (tab === 'pending') list = list.filter((r) => r.status === 'pending')
    else if (tab === 'inReview') list = list.filter((r) => r.status === 'inReview')
    else if (tab === 'reviewed')
      list = list.filter((r) => r.status === 'approved' || r.status === 'rejected')
    else if (tab === 'reported') list = list.filter((r) => r.status === 'reported')
    if (sort === 'oldest') list = [...list].reverse()
    if (sort === 'name') list = [...list].sort((a, b) => a.name.localeCompare(b.name))
    return list
  }, [rows, tab, sort])

  const displayTotal = filtered.length

  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = filtered.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)

  const active = activeId ? rows.find((r) => r.id === activeId) ?? null : null
  const activePhotos =
    active?.photos?.length ? active.photos : active?.imageUrl ? [active.imageUrl] : []

  useEffect(() => {
    setPhotoIdx(0)
    setPanelTab('details')
    setNotes(String(active?.raw.reviewerNotes ?? ''))
    setShowAllFeatures(false)
  }, [activeId])

  const allPageSelected =
    pageRows.length > 0 && pageRows.every((r) => selected.has(r.id))

  const runAction = async (
    row: Row,
    action: 'approved' | 'rejected' | 'needsInfo',
  ) => {
    if (usingDemo || row.id.startsWith('demo-')) {
      setRows((prev) =>
        prev.map((r) =>
          r.id === row.id
            ? {
                ...r,
                status:
                  action === 'approved'
                    ? 'approved'
                    : action === 'rejected'
                      ? 'rejected'
                      : 'inReview',
              }
            : r,
        ),
      )
      return
    }
    setBusy(row.id)
    try {
      if (action === 'approved') await approveSubmission(row.raw, notes)
      else if (action === 'needsInfo')
        await setSubmissionStatus(row.id, 'needsInfo', { reviewerNotes: notes })
      else await setSubmissionStatus(row.id, 'rejected', { reviewerNotes: notes })
      await reload()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  const tabCounts = {
    all: rows.length,
    pending: stats.pending,
    inReview: stats.inReview,
    reviewed: rows.filter((r) => r.status === 'approved' || r.status === 'rejected').length,
    reported: reportedCount,
  }

  const visibleFeatures = showAllFeatures ? FEATURE_LABELS : FEATURE_LABELS.slice(0, 9)
  const staticMap =
    active && Number.isFinite(active.lat) && Number.isFinite(active.lng)
      ? `https://maps.googleapis.com/maps/api/staticmap?center=${active.lat},${active.lng}&zoom=15&size=180x140&scale=2&maptype=roadmap&markers=color:red%7C${active.lat},${active.lng}&key=${GOOGLE_MAPS_API_KEY}`
      : ''

  return (
    <div className="v-page">
      <div className="v-main">
        <header className="v-page-head">
          <h1>Verification</h1>
          <p>Review and verify places added by users and community.</p>
        </header>

        <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
        {error ? <div className="error">{error}</div> : null}

        <div className="v-stats">
          <article className="v-stat">
            <div className="v-stat-icon amber">
              <IconClock />
            </div>
            <div>
              <span className="v-stat-label">Pending</span>
              <strong>{stats.pending.toLocaleString()}</strong>
              <em>Needs review</em>
            </div>
          </article>
          <article className="v-stat">
            <div className="v-stat-icon blue">
              <IconSearch />
            </div>
            <div>
              <span className="v-stat-label">In Review</span>
              <strong>{stats.inReview.toLocaleString()}</strong>
              <em>Under review</em>
            </div>
          </article>
          <article className="v-stat">
            <div className="v-stat-icon green">
              <IconShieldCheck />
            </div>
            <div>
              <span className="v-stat-label">Verified</span>
              <strong>{stats.verified.toLocaleString()}</strong>
              <em>Approved</em>
            </div>
          </article>
          <article className="v-stat">
            <div className="v-stat-icon red">
              <IconX />
            </div>
            <div>
              <span className="v-stat-label">Rejected</span>
              <strong>{stats.rejected.toLocaleString()}</strong>
              <em>Not approved</em>
            </div>
          </article>
        </div>

        <div className="v-toolbar">
          <div className="v-tabs">
            {(
              [
                ['all', `All (${tabCounts.all.toLocaleString()})`],
                ['pending', `Pending (${tabCounts.pending.toLocaleString()})`],
                ['inReview', `In Review (${tabCounts.inReview.toLocaleString()})`],
                ['reviewed', 'Reviewed'],
                ['reported', `Reported (${tabCounts.reported.toLocaleString()})`],
              ] as const
            ).map(([key, label]) => (
              <button
                key={key}
                type="button"
                className={tab === key ? 'active' : ''}
                onClick={() => {
                  setTab(key)
                  setPage(1)
                }}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="v-toolbar-right">
            <label className="v-sort">
              <select value={sort} onChange={(e) => setSort(e.target.value)}>
                <option value="newest">Sort by: Newest First</option>
                <option value="oldest">Sort by: Oldest First</option>
                <option value="name">Sort by: Name</option>
              </select>
            </label>
            <button type="button" className="v-filters-btn">
              <IconFilter width={15} height={15} />
              Filters
            </button>
          </div>
        </div>

        <div className="v-table-card">
          <div className="v-table-scroll">
            <table className="v-table">
              <thead>
                <tr>
                  <th className="check">
                    <input
                      type="checkbox"
                      checked={allPageSelected}
                      onChange={() => {
                        setSelected((prev) => {
                          const next = new Set(prev)
                          if (allPageSelected) pageRows.forEach((r) => next.delete(r.id))
                          else pageRows.forEach((r) => next.add(r.id))
                          return next
                        })
                      }}
                    />
                  </th>
                  <th>Place</th>
                  <th>Category</th>
                  <th>Added By</th>
                  <th>Added On</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.map((r) => {
                  const cat = categoryIcon(r.category)
                  return (
                    <tr
                      key={r.id}
                      className={active?.id === r.id ? 'active' : ''}
                      onClick={() => setActiveId(r.id)}
                    >
                      <td className="check" onClick={(e) => e.stopPropagation()}>
                        <input
                          type="checkbox"
                          checked={selected.has(r.id)}
                          onChange={() => {
                            setSelected((prev) => {
                              const next = new Set(prev)
                              if (next.has(r.id)) next.delete(r.id)
                              else next.add(r.id)
                              return next
                            })
                          }}
                        />
                      </td>
                      <td>
                        <div className="v-place">
                          <div className="v-thumb">
                            {r.imageUrl ? <img src={r.imageUrl} alt="" /> : r.name[0]}
                          </div>
                          <div>
                            <strong>{r.name}</strong>
                            <span>{r.address}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span className={`v-cat ${cat.tone}`}>
                          <i>{cat.icon}</i>
                          {r.category}
                        </span>
                      </td>
                      <td>
                        <div className="v-user">
                          <img
                            src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(r.addedByName)}`}
                            alt=""
                          />
                          <div>
                            <strong>{r.addedByName}</strong>
                            <span>{r.addedByHandle}</span>
                          </div>
                        </div>
                      </td>
                      <td className="muted">{r.addedAgo}</td>
                      <td>{statusPill(r.status)}</td>
                      <td onClick={(e) => e.stopPropagation()}>
                        <div className="v-row-actions">
                          <button type="button" title="View" onClick={() => setActiveId(r.id)}>
                            <IconEye width={16} height={16} />
                          </button>
                          <button type="button" title="Detail" onClick={() => setActiveId(r.id)}>
                            <IconChevronRight width={16} height={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          <div className="v-footer">
            <span>
              Showing {from} to {to} of {displayTotal.toLocaleString()} places
            </span>
            <label>
              Rows per page:
              <select
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value))
                  setPage(1)
                }}
              >
                {[8, 10, 25].map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
            </label>
            <div className="v-pages">
              <button
                type="button"
                disabled={safePage <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                <IconChevronLeft width={16} height={16} />
              </button>
              {Array.from({ length: Math.min(5, pageCount) }, (_, i) => i + 1).map((p) => (
                <button
                  key={p}
                  type="button"
                  className={p === safePage ? 'active' : ''}
                  onClick={() => setPage(p)}
                >
                  {p}
                </button>
              ))}
              {pageCount > 5 ? <span>…</span> : null}
              <button
                type="button"
                disabled={safePage >= pageCount}
                onClick={() => setPage((p) => p + 1)}
              >
                <IconChevronRight width={16} height={16} />
              </button>
            </div>
          </div>
        </div>
      </div>

      {active ? (
        <aside className="v-panel">
          <div className="v-panel-top">
            <div>
              <h2>{active.name}</h2>
              <div className="v-panel-sub">
                {active.status === 'pending' ? (
                  <span className="v-pill v-pill-pending">Pending Verification</span>
                ) : (
                  statusPill(active.status)
                )}
                <p>
                  Added {active.addedAgo} by {active.addedByName} ({active.addedByHandle})
                </p>
              </div>
            </div>
            <button type="button" className="v-close" onClick={() => setActiveId(null)}>
              <IconX />
            </button>
          </div>

          <div className="v-hero">
            {activePhotos.length ? (
              <img src={activePhotos[photoIdx % activePhotos.length]} alt="" />
            ) : (
              <div className="v-hero-empty">No photos</div>
            )}
            {activePhotos.length > 1 ? (
              <>
                <button
                  type="button"
                  className="v-hero-nav left"
                  onClick={() =>
                    setPhotoIdx((i) => (i - 1 + activePhotos.length) % activePhotos.length)
                  }
                >
                  <IconChevronLeft />
                </button>
                <button
                  type="button"
                  className="v-hero-nav right"
                  onClick={() => setPhotoIdx((i) => (i + 1) % activePhotos.length)}
                >
                  <IconChevronRight />
                </button>
                <span className="v-hero-count">
                  {(photoIdx % activePhotos.length) + 1} / {activePhotos.length}
                </span>
              </>
            ) : null}
          </div>

          <nav className="v-panel-tabs">
            {(
              [
                ['details', 'Details'],
                ['accessibility', 'Accessibility'],
                ['photos', `Photos (${activePhotos.length})`],
                ['activity', 'Activity'],
              ] as const
            ).map(([key, label]) => (
              <button
                key={key}
                type="button"
                className={panelTab === key ? 'active' : ''}
                onClick={() => setPanelTab(key)}
              >
                {label}
              </button>
            ))}
          </nav>

          <div className="v-panel-scroll">
            {(panelTab === 'details' || panelTab === 'accessibility') && (
              <>
                <div className="v-contact-block">
                  <ul className="v-contact">
                    <li>
                      <IconMapPin width={15} height={15} />
                      <span>{active.address}</span>
                    </li>
                    {active.phone ? (
                      <li>
                        <IconPhone width={15} height={15} />
                        <span>{active.phone}</span>
                      </li>
                    ) : null}
                    {active.website ? (
                      <li>
                        <IconGlobe width={15} height={15} />
                        <a
                          href={
                            active.website.startsWith('http')
                              ? active.website
                              : `https://${active.website}`
                          }
                          target="_blank"
                          rel="noreferrer"
                        >
                          {active.website}
                        </a>
                      </li>
                    ) : null}
                    <li>
                      <IconClock width={15} height={15} />
                      <span>{active.hours}</span>
                    </li>
                  </ul>
                  {staticMap ? (
                    <img className="v-map" src={staticMap} alt="Location map" />
                  ) : (
                    <div className="v-map empty">
                      <IconMapPin />
                    </div>
                  )}
                </div>

                <section className="v-block">
                  <h3>Description</h3>
                  <p>{active.description}</p>
                </section>

                <section className="v-block">
                  <h3>Accessibility Features</h3>
                  <div className="v-features">
                    {visibleFeatures.map((f) => {
                      const on = active.features.includes(f.key)
                      return (
                        <label key={f.key} className={on ? 'on' : ''}>
                          <input type="checkbox" checked={on} readOnly />
                          {f.label}
                        </label>
                      )
                    })}
                  </div>
                  {!showAllFeatures ? (
                    <button
                      type="button"
                      className="v-more"
                      onClick={() => setShowAllFeatures(true)}
                    >
                      + {FEATURE_LABELS.length - 9} More
                    </button>
                  ) : null}
                </section>
              </>
            )}

            {panelTab === 'photos' && (
              <div className="v-photo-grid">
                {activePhotos.map((src, i) => (
                  <button
                    key={src + i}
                    type="button"
                    className={i === photoIdx ? 'on' : ''}
                    onClick={() => setPhotoIdx(i)}
                  >
                    <img src={src} alt="" />
                  </button>
                ))}
              </div>
            )}

            {panelTab === 'activity' && (
              <div className="v-activity">
                <div>
                  <IconClock width={14} height={14} />
                  <div>
                    <strong>Submitted</strong>
                    <span>
                      {active.addedAgo} · {active.addedByName}
                    </span>
                  </div>
                </div>
                <div>
                  <IconSearch width={14} height={14} />
                  <div>
                    <strong>Current status</strong>
                    <span>{active.status}</span>
                  </div>
                </div>
              </div>
            )}

            <section className="v-block">
              <h3>Verification Notes (Optional)</h3>
              <textarea
                rows={3}
                maxLength={300}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Add notes about this place..."
              />
              <div className="v-count">{notes.length} / 300</div>
            </section>
          </div>

          <div className="v-actions">
            <button
              type="button"
              className="v-btn reject"
              disabled={busy === active.id}
              onClick={() => void runAction(active, 'rejected')}
            >
              <IconX width={15} height={15} />
              Reject
            </button>
            <button
              type="button"
              className="v-btn info"
              disabled={busy === active.id}
              onClick={() => void runAction(active, 'needsInfo')}
            >
              <IconInfo width={15} height={15} />
              Request More Info
            </button>
            <button
              type="button"
              className="v-btn approve"
              disabled={busy === active.id}
              onClick={() => void runAction(active, 'approved')}
            >
              <IconCheck width={15} height={15} />
              {busy === active.id ? 'Saving…' : 'Verify & Approve'}
            </button>
          </div>
        </aside>
      ) : null}
    </div>
  )
}
