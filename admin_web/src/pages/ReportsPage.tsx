import { useCallback, useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchReportsHub,
  resolveHubItem,
  type ReportHubItem,
  type ReportHubSource,
} from '../lib/data'
import { useI18n } from '../i18n'
import { DemoBanner } from '../components/DemoBanner'
import {
  IconFlag,
  IconMore,
  IconSearch,
} from '../components/icons'

type SourceTab = 'all' | ReportHubSource

const SOURCES: SourceTab[] = [
  'all',
  'place',
  'review',
  'community',
  'job',
  'provider',
]

function formatWhen(value: unknown): string {
  const ts = value as { toDate?: () => Date; seconds?: number } | string | null
  let d: Date | null = null
  if (typeof ts === 'string') {
    const parsed = new Date(ts)
    if (!Number.isNaN(parsed.getTime())) d = parsed
  } else if (ts?.toDate) d = ts.toDate()
  else if (typeof ts?.seconds === 'number') d = new Date(ts.seconds * 1000)
  if (!d) return '—'
  return d.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function statusPill(status: string) {
  const s = status.toLowerCase().replace(/_/g, ' ')
  let cls = 'r-pill pending'
  if (s.includes('resolv') || s.includes('approv') || s.includes('publish') || s === 'live') {
    cls = 'r-pill resolved'
  } else if (s.includes('reject') || s.includes('dismiss') || s.includes('remov') || s.includes('hidden')) {
    cls = 'r-pill rejected'
  } else if (s.includes('review') || s.includes('open') || s.includes('flag')) {
    cls = 'r-pill review'
  }
  const label = status
    ? status.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
    : 'Unknown'
  return <span className={cls}>{label}</span>
}

function sourcePill(source: ReportHubSource) {
  return <span className="r-pill review">{source}</span>
}

function actionsFor(source: ReportHubSource): { label: string; status: string }[] {
  switch (source) {
    case 'place':
      return [
        { label: 'In review', status: 'in_review' },
        { label: 'Resolved', status: 'resolved' },
        { label: 'Dismissed', status: 'dismissed' },
      ]
    case 'review':
      return [
        { label: 'Approved', status: 'approved' },
        { label: 'Hidden', status: 'hidden' },
      ]
    case 'community':
      return [
        { label: 'Published', status: 'published' },
        { label: 'Hidden', status: 'hidden' },
        { label: 'Removed', status: 'removed' },
      ]
    case 'job':
      return [
        { label: 'Approved', status: 'approved' },
        { label: 'Rejected', status: 'rejected' },
        { label: 'Live', status: 'live' },
      ]
    case 'provider':
      return [
        { label: 'Resolved', status: 'resolved' },
        { label: 'Rejected', status: 'rejected' },
      ]
  }
}

export function ReportsPage() {
  const { t } = useI18n()
  const [rows, setRows] = useState<ReportHubItem[]>([])
  const [source, setSource] = useState<SourceTab>('all')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState<string | null>(null)
  const [menuId, setMenuId] = useState<string | null>(null)
  const [usingDemo, setUsingDemo] = useState(false)

  const reload = useCallback(async (src: SourceTab) => {
    setLoading(true)
    try {
      const data = await fetchReportsHub({ source: src, max: 150 })
      setRows(data)
      setUsingDemo(false)
      setError('')
    } catch (e) {
      setRows([])
      setUsingDemo(false)
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void reload(source)
  }, [reload, source])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    if (!q) return rows
    return rows.filter((r) => {
      return (
        r.title.toLowerCase().includes(q) ||
        r.subtitle.toLowerCase().includes(q) ||
        r.status.toLowerCase().includes(q) ||
        r.source.toLowerCase().includes(q) ||
        r.id.toLowerCase().includes(q)
      )
    })
  }, [rows, search])

  const resolve = async (row: ReportHubItem, status: string) => {
    setMenuId(null)
    setBusy(row.id)
    try {
      await resolveHubItem(row.source, row.id, status)
      await reload(source)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="r-page">
      <header className="r-head">
        <h1>{t('reports.title')}</h1>
        <p>{t('reports.subtitle')}</p>
      </header>

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error ? <div className="error">{error}</div> : null}

      <div className="r-filters" style={{ flexWrap: 'wrap' }}>
        <div className="r-search">
          <IconSearch className="r-search-icon" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={`${t('common.search')}…`}
          />
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {SOURCES.map((s) => (
            <button
              key={s}
              type="button"
              className={`r-btn ${source === s ? '' : 'ghost'}`}
              onClick={() => setSource(s)}
            >
              {t(`reports.source.${s}`)}
            </button>
          ))}
        </div>
        <button
          type="button"
          className="r-btn ghost"
          onClick={() => void reload(source)}
        >
          {t('common.refresh')}
        </button>
      </div>

      <p className="muted" style={{ margin: '0 0 12px', fontSize: 13 }}>
        Specialized queues:{' '}
        <Link to="/trust-safety">Trust &amp; Safety</Link>
        {' · '}
        <Link to="/reviews">Reviews</Link>
        {' · '}
        <Link to="/community">Community</Link>
        {' · '}
        <Link to="/jobs">Jobs</Link>
      </p>

      <div className="r-table-card">
        <div className="r-table-scroll">
          <table className="r-table">
            <thead>
              <tr>
                <th>Source</th>
                <th>Title</th>
                <th>Detail</th>
                <th>Status</th>
                <th>When</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="muted" style={{ padding: 20 }}>
                    {t('common.loading')}
                  </td>
                </tr>
              ) : (
                filtered.map((r) => (
                  <tr key={`${r.source}-${r.id}`}>
                    <td>{sourcePill(r.source)}</td>
                    <td>
                      <strong>{r.title}</strong>
                    </td>
                    <td>
                      <span className="muted" style={{ fontSize: 13 }}>
                        {r.subtitle || '—'}
                      </span>
                    </td>
                    <td>{statusPill(r.status)}</td>
                    <td>
                      <div className="r-when">
                        <strong>{formatWhen(r.createdAt)}</strong>
                      </div>
                    </td>
                    <td>
                      <div className="r-actions">
                        <div className="r-more-wrap">
                          <button
                            type="button"
                            title="Actions"
                            disabled={busy === r.id}
                            onClick={() =>
                              setMenuId((id) =>
                                id === `${r.source}-${r.id}`
                                  ? null
                                  : `${r.source}-${r.id}`,
                              )
                            }
                          >
                            <IconMore width={16} height={16} />
                          </button>
                          {menuId === `${r.source}-${r.id}` ? (
                            <div className="r-menu">
                              {actionsFor(r.source).map((a) => (
                                <button
                                  key={a.status}
                                  type="button"
                                  onClick={() => void resolve(r, a.status)}
                                >
                                  {a.label}
                                </button>
                              ))}
                            </div>
                          ) : null}
                        </div>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {!loading && !filtered.length ? (
          <div className="empty" style={{ padding: 20 }}>
            <IconFlag width={18} height={18} style={{ marginRight: 8 }} />
            No reports match your filters.
          </div>
        ) : null}

        <div className="r-footer">
          <span>
            {filtered.length} item{filtered.length === 1 ? '' : 's'}
            {search.trim() ? ' (filtered)' : ''}
          </span>
        </div>
      </div>
    </div>
  )
}
