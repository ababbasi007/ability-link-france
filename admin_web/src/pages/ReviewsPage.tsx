import { useEffect, useMemo, useState } from 'react'
import { fetchReviews, setReviewStatus } from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import {
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconDownload,
  IconEye,
  IconFilter,
  IconFlag,
  IconMessage,
  IconMoreVertical,
  IconSearch,
  IconStar,
  IconStarFill,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

type ReviewStatus = 'pending' | 'approved' | 'inReview' | 'reported'
type ReviewType = 'Accessibility' | 'Experience' | 'General'

type ReviewRow = {
  id: string
  text: string
  photos: string[]
  placeName: string
  placeAddress: string
  placeImage: string
  category: string
  rating: number
  reviewType: ReviewType
  reviewerName: string
  reviewerHandle: string
  reviewerCount: number
  date: string
  ago: string
  status: ReviewStatus
  raw: Doc
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
  return `${Math.round(hrs / 24)} day${hrs < 48 ? '' : 's'} ago`
}

function mapStatus(raw: string): ReviewStatus {
  const s = raw.toLowerCase()
  if (s === 'published' || s === 'approved' || s === 'active') return 'approved'
  if (s === 'hidden' || s === 'reported' || s === 'flagged') return 'reported'
  if (s === 'inreview' || s === 'in_review' || s === 'review') return 'inReview'
  if (s === 'pending' || s === 'moderation' || !s) return 'pending'
  return 'pending'
}

function mapType(raw: unknown, text: string): ReviewType {
  const t = String(raw ?? '').toLowerCase()
  if (t.includes('access')) return 'Accessibility'
  if (t.includes('experience')) return 'Experience'
  const blob = text.toLowerCase()
  if (
    blob.includes('wheelchair') ||
    blob.includes('ramp') ||
    blob.includes('elevator') ||
    blob.includes('accessible') ||
    blob.includes('braille')
  ) {
    return 'Accessibility'
  }
  if (blob.includes('staff') || blob.includes('service') || blob.includes('visit')) {
    return 'Experience'
  }
  return 'General'
}

function mapRow(d: Doc): ReviewRow {
  const text = String(d.text ?? d.comment ?? d.body ?? d.review ?? 'No review text')
  const ratingRaw = Number(d.rating ?? d.score ?? 0)
  const rating = Number.isFinite(ratingRaw) && ratingRaw > 0 ? ratingRaw : 4
  const reviewerName = String(
    d.userName ?? d.authorName ?? String(d.uid ?? 'user').slice(0, 10),
  )
  const photos = [
    ...(((d.photoUrls as string[]) ?? []).filter(Boolean)),
    ...(((d.images as string[]) ?? []).filter(Boolean)),
  ]
  return {
    id: d.id,
    text,
    photos,
    placeName: String(d.placeName ?? d.targetName ?? 'Unknown place'),
    placeAddress: String(d.address ?? d.placeAddress ?? '—'),
    placeImage: String(d.placeImageUrl ?? d.imageUrl ?? ''),
    category: String(d.category ?? d.placeCategory ?? 'Other'),
    rating,
    reviewType: mapType(d.reviewType ?? d.type, text),
    reviewerName,
    reviewerHandle: `@${reviewerName.toLowerCase().replace(/\s+/g, '').slice(0, 14)}`,
    reviewerCount: Number(d.authorReviewCount ?? d.reviewCount ?? 1) || 1,
    date: formatDate(d.createdAt),
    ago: formatAgo(d.createdAt),
    status: mapStatus(String(d.status ?? 'pending')),
    raw: d,
  }
}

function Stars({ rating }: { rating: number }) {
  const full = Math.floor(rating)
  const tone = rating >= 4 ? 'good' : rating >= 3 ? 'mid' : 'low'
  return (
    <div className={`rv-stars ${tone}`}>
      <strong>{rating.toFixed(1)}</strong>
      <span className="rv-star-row" aria-hidden>
        {Array.from({ length: 5 }, (_, i) =>
          i < full ? (
            <IconStarFill key={i} width={12} height={12} />
          ) : (
            <IconStar key={i} width={12} height={12} />
          ),
        )}
      </span>
    </div>
  )
}

function statusPill(status: ReviewStatus) {
  if (status === 'pending') return <span className="rv-pill pending">Pending</span>
  if (status === 'approved') return <span className="rv-pill approved">Approved</span>
  if (status === 'inReview') return <span className="rv-pill review">In Review</span>
  return <span className="rv-pill reported">Reported</span>
}

function typePill(type: ReviewType) {
  const cls =
    type === 'Accessibility' ? 'access' : type === 'Experience' ? 'experience' : 'general'
  return <span className={`rv-type ${cls}`}>{type}</span>
}

export function ReviewsPage() {
  const [rows, setRows] = useState<ReviewRow[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [placeFilter, setPlaceFilter] = useState('all')
  const [ratingFilter, setRatingFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [tab, setTab] = useState<'all' | 'pending' | 'reported'>('all')
  const [sort, setSort] = useState('newest')
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [busy, setBusy] = useState<string | null>(null)
  const [menuId, setMenuId] = useState<string | null>(null)

  const reload = async () => {
    try {
      const data = await fetchReviews(200)
      if (!data.length) {
        setRows([])
        setUsingDemo(false)
      } else {
        setRows(data.map(mapRow))
        setUsingDemo(false)
      }
      setError('')
    } catch (e) {
      setRows([])
      setUsingDemo(false)
      setError(e instanceof Error ? e.message : String(e))
    }
  }

  useEffect(() => {
    void reload()
  }, [])

  const stats = useMemo(() => {
    const ratings = rows.map((r) => r.rating).filter((n) => n > 0)
    const avg = ratings.length
      ? Math.round((ratings.reduce((a, b) => a + b, 0) / ratings.length) * 10) / 10
      : 0
    return {
      total: rows.length,
      pending: rows.filter((r) => r.status === 'pending').length,
      approved: rows.filter((r) => r.status === 'approved').length,
      reported: rows.filter((r) => r.status === 'reported').length,
      avg,
    }
  }, [rows])

  const places = useMemo(
    () => [...new Set(rows.map((r) => r.placeName))].sort(),
    [rows],
  )

  const filtered = useMemo(() => {
    let list = [...rows]
    if (tab === 'pending') list = list.filter((r) => r.status === 'pending')
    if (tab === 'reported') list = list.filter((r) => r.status === 'reported')

    const q = search.trim().toLowerCase()
    list = list.filter((r) => {
      if (placeFilter !== 'all' && r.placeName !== placeFilter) return false
      if (statusFilter !== 'all' && r.status !== statusFilter) return false
      if (typeFilter !== 'all' && r.reviewType !== typeFilter) return false
      if (ratingFilter !== 'all') {
        const min = Number(ratingFilter)
        if (r.rating < min) return false
      }
      if (!q) return true
      return (
        r.text.toLowerCase().includes(q) ||
        r.placeName.toLowerCase().includes(q) ||
        r.reviewerName.toLowerCase().includes(q)
      )
    })

    if (sort === 'oldest') list.reverse()
    if (sort === 'rating') list.sort((a, b) => b.rating - a.rating)
    if (sort === 'place') list.sort((a, b) => a.placeName.localeCompare(b.placeName))
    return list
  }, [rows, tab, search, placeFilter, statusFilter, typeFilter, ratingFilter, sort])

  const displayTotal = filtered.length

  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = filtered.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)
  const allSelected =
    pageRows.length > 0 && pageRows.every((r) => selected.has(r.id))

  const tabCounts = {
    all: rows.length,
    pending: rows.filter((r) => r.status === 'pending').length,
    reported: rows.filter((r) => r.status === 'reported').length,
  }

  const updateStatus = async (row: ReviewRow, status: ReviewStatus) => {
    setMenuId(null)
    if (usingDemo || row.id.startsWith('rv')) {
      setRows((prev) => prev.map((r) => (r.id === row.id ? { ...r, status } : r)))
      return
    }
    setBusy(row.id)
    try {
      const firestoreStatus =
        status === 'approved'
          ? 'published'
          : status === 'reported'
            ? 'hidden'
            : status === 'inReview'
              ? 'inReview'
              : 'pending'
      await setReviewStatus(row.id, firestoreStatus)
      await reload()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  const exportCsv = () => {
    const header = [
      'Place',
      'Rating',
      'Type',
      'Review',
      'Reviewer',
      'Date',
      'Status',
    ]
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [
          r.placeName,
          r.rating,
          r.reviewType,
          r.text,
          r.reviewerName,
          r.date,
          r.status,
        ]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-reviews.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="rv-page">
      <header className="rv-head">
        <div>
          <h1>Reviews</h1>
          <p>Manage and moderate all place reviews.</p>
        </div>
        <button type="button" className="rv-export" onClick={exportCsv}>
          <IconDownload width={16} height={16} />
          Export Reviews
        </button>
      </header>

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error ? <div className="error">{error}</div> : null}

      <div className="rv-stats">
        <article className="rv-stat">
          <div className="rv-stat-icon green">
            <IconStarFill />
          </div>
          <div>
            <span>Total Reviews</span>
            <strong>{stats.total.toLocaleString()}</strong>
            <em>All time</em>
          </div>
        </article>
        <article className="rv-stat">
          <div className="rv-stat-icon blue">
            <IconMessage />
          </div>
          <div>
            <span>Pending</span>
            <strong>{stats.pending.toLocaleString()}</strong>
            <em>Needs review</em>
          </div>
        </article>
        <article className="rv-stat">
          <div className="rv-stat-icon purple">
            <IconCheckCircle />
          </div>
          <div>
            <span>Approved</span>
            <strong>{stats.approved.toLocaleString()}</strong>
            <em>Published</em>
          </div>
        </article>
        <article className="rv-stat">
          <div className="rv-stat-icon red">
            <IconFlag />
          </div>
          <div>
            <span>Reported</span>
            <strong>{stats.reported.toLocaleString()}</strong>
            <em>Flagged by users</em>
          </div>
        </article>
        <article className="rv-stat">
          <div className="rv-stat-icon amber">
            <IconStarFill />
          </div>
          <div>
            <span>Average Rating</span>
            <strong>{stats.avg.toFixed(1)}</strong>
            <em>All places</em>
          </div>
        </article>
      </div>

      <div className="rv-filters">
        <div className="rv-search">
          <IconSearch className="rv-search-icon" />
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Search reviews by place or user..."
          />
        </div>
        <select
          value={placeFilter}
          onChange={(e) => {
            setPlaceFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Places</option>
          {places.map((p) => (
            <option key={p} value={p}>
              {p}
            </option>
          ))}
        </select>
        <select
          value={ratingFilter}
          onChange={(e) => {
            setRatingFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Ratings</option>
          <option value="5">5 stars</option>
          <option value="4">4+ stars</option>
          <option value="3">3+ stars</option>
          <option value="2">2+ stars</option>
        </select>
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Status</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="inReview">In Review</option>
          <option value="reported">Reported</option>
        </select>
        <select
          value={typeFilter}
          onChange={(e) => {
            setTypeFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Review Types</option>
          <option value="Accessibility">Accessibility</option>
          <option value="Experience">Experience</option>
          <option value="General">General</option>
        </select>
        <button type="button" className="rv-btn ghost">
          <IconFilter width={15} height={15} />
          More Filters
        </button>
      </div>

      <div className="rv-toolbar">
        <div className="rv-tabs">
          {(
            [
              ['all', `All Reviews (${tabCounts.all.toLocaleString()})`],
              ['pending', `Pending (${tabCounts.pending.toLocaleString()})`],
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
        <select value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="newest">Sort by: Newest First</option>
          <option value="oldest">Sort by: Oldest First</option>
          <option value="rating">Sort by: Rating</option>
          <option value="place">Sort by: Place</option>
        </select>
      </div>

      <div className="rv-table-card">
        <div className="rv-table-scroll">
          <table className="rv-table">
            <thead>
              <tr>
                <th className="check">
                  <input
                    type="checkbox"
                    checked={allSelected}
                    onChange={() => {
                      setSelected((prev) => {
                        const next = new Set(prev)
                        if (allSelected) pageRows.forEach((r) => next.delete(r.id))
                        else pageRows.forEach((r) => next.add(r.id))
                        return next
                      })
                    }}
                  />
                </th>
                <th>Review</th>
                <th>Place</th>
                <th>Rating</th>
                <th>Review Type</th>
                <th>Reviewed By</th>
                <th>Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {pageRows.map((r) => {
                const visiblePhotos = r.photos.slice(0, 3)
                const extra = Math.max(0, r.photos.length - 3)
                return (
                  <tr key={r.id} className={selected.has(r.id) ? 'selected' : ''}>
                    <td className="check">
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
                      <div className="rv-text">
                        <p>{r.text}</p>
                        {visiblePhotos.length ? (
                          <div className="rv-photos">
                            {visiblePhotos.map((src) => (
                              <img key={src} src={src} alt="" />
                            ))}
                            {extra > 0 ? <span className="rv-more-photos">+{extra}</span> : null}
                          </div>
                        ) : null}
                      </div>
                    </td>
                    <td>
                      <div className="rv-place">
                        <div className="rv-thumb">
                          {r.placeImage ? (
                            <img src={r.placeImage} alt="" />
                          ) : (
                            <span>{r.placeName[0]}</span>
                          )}
                        </div>
                        <div>
                          <strong>{r.placeName}</strong>
                          <span>{r.placeAddress}</span>
                          <em className="rv-cat">{r.category}</em>
                        </div>
                      </div>
                    </td>
                    <td>
                      <Stars rating={r.rating} />
                    </td>
                    <td>{typePill(r.reviewType)}</td>
                    <td>
                      <div className="rv-user">
                        <img
                          src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(r.reviewerName)}`}
                          alt=""
                        />
                        <div>
                          <strong>{r.reviewerName}</strong>
                          <span>{r.reviewerHandle}</span>
                          <em>{r.reviewerCount} reviews</em>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="rv-when">
                        <strong>{r.date}</strong>
                        <span>{r.ago}</span>
                      </div>
                    </td>
                    <td>{statusPill(r.status)}</td>
                    <td>
                      <div className="rv-actions">
                        <button
                          type="button"
                          title="View"
                          disabled={busy === r.id}
                          onClick={() => void updateStatus(r, 'inReview')}
                        >
                          <IconEye width={16} height={16} />
                        </button>
                        <div className="rv-more-wrap">
                          <button
                            type="button"
                            title="More"
                            onClick={() => setMenuId((id) => (id === r.id ? null : r.id))}
                          >
                            <IconMoreVertical width={16} height={16} />
                          </button>
                          {menuId === r.id ? (
                            <div className="rv-menu">
                              <button type="button" onClick={() => void updateStatus(r, 'approved')}>
                                Approve
                              </button>
                              <button type="button" onClick={() => void updateStatus(r, 'pending')}>
                                Mark Pending
                              </button>
                              <button type="button" onClick={() => void updateStatus(r, 'inReview')}>
                                Mark In Review
                              </button>
                              <button type="button" onClick={() => void updateStatus(r, 'reported')}>
                                Flag / Hide
                              </button>
                            </div>
                          ) : null}
                        </div>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        {!pageRows.length ? (
          <div className="empty" style={{ padding: 20 }}>
            No reviews match your filters.
          </div>
        ) : null}

        <div className="rv-footer">
          <span>
            Showing {from} to {to} of {displayTotal.toLocaleString()} reviews
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
              {[10, 25, 50].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
          <div className="rv-pages">
            <button type="button" disabled={safePage <= 1} onClick={() => setPage(1)}>
              <IconChevronsLeft width={15} height={15} />
            </button>
            <button
              type="button"
              disabled={safePage <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              <IconChevronLeft width={15} height={15} />
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
              onClick={() => setPage((p) => Math.min(pageCount, p + 1))}
            >
              <IconChevronRight width={15} height={15} />
            </button>
            <button
              type="button"
              disabled={safePage >= pageCount}
              onClick={() => setPage(pageCount)}
            >
              <IconChevronsRight width={15} height={15} />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
