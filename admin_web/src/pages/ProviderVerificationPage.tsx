import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchProvider,
  fetchVerificationRequests,
  reviewVerificationRequest,
  type VerificationStatus,
} from '../lib/data'
import {
  IconCheck,
  IconClock,
  IconInfo,
  IconRefresh,
  IconShieldCheck,
  IconX,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }
type StatusFilter = VerificationStatus | 'all'

function formatWhen(value: unknown): string {
  if (!value) return '—'
  let d: Date | null = null
  if (typeof value === 'string') {
    const t = new Date(value)
    if (!Number.isNaN(t.getTime())) d = t
  } else if (typeof value === 'object' && value !== null && 'toDate' in value) {
    d = (value as { toDate: () => Date }).toDate()
  } else if (typeof value === 'object' && value !== null && 'seconds' in value) {
    d = new Date((value as { seconds: number }).seconds * 1000)
  }
  if (!d) return '—'
  return d.toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function mapStatus(raw: unknown): VerificationStatus {
  const s = String(raw ?? 'pending').toLowerCase()
  if (s === 'approved' || s === 'verified') return 'approved'
  if (s === 'rejected' || s === 'denied') return 'rejected'
  if (s === 'needsinfo' || s === 'needs_info' || s === 'inreview' || s === 'in_review') {
    return 'needsInfo'
  }
  return 'pending'
}

function statusPill(status: VerificationStatus) {
  if (status === 'pending') return <span className="v-pill v-pill-pending">Pending</span>
  if (status === 'needsInfo') return <span className="v-pill v-pill-review">Needs Info</span>
  if (status === 'approved') return <span className="v-pill v-pill-ok">Approved</span>
  return <span className="v-pill v-pill-reject">Rejected</span>
}

function requestName(r: Doc): string {
  return (
    String(r.name ?? r.displayName ?? r.providerName ?? r.title ?? '').trim() ||
    String(r.targetId ?? r.id)
  )
}

export function ProviderVerificationPage() {
  const [rows, setRows] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('pending')
  const [targetTypeFilter, setTargetTypeFilter] = useState('')
  const [activeId, setActiveId] = useState<string | null>(null)
  const [provider, setProvider] = useState<Doc | null>(null)
  const [providerLoading, setProviderLoading] = useState(false)
  const [adminNote, setAdminNote] = useState('')
  const [busy, setBusy] = useState(false)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const data = await fetchVerificationRequests(200)
      setRows(data)
      setActiveId((prev) => {
        if (prev && data.some((r) => r.id === prev)) return prev
        return data[0]?.id ?? null
      })
    } catch (e) {
      setRows([])
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const stats = useMemo(() => {
    const counts = { pending: 0, needsInfo: 0, approved: 0, rejected: 0 }
    for (const r of rows) {
      counts[mapStatus(r.status)] += 1
    }
    return counts
  }, [rows])

  const filtered = useMemo(() => {
    const needle = targetTypeFilter.trim().toLowerCase()
    return rows.filter((r) => {
      const status = mapStatus(r.status)
      if (statusFilter !== 'all' && status !== statusFilter) return false
      if (!needle) return true
      return String(r.targetType ?? '').toLowerCase().includes(needle)
    })
  }, [rows, statusFilter, targetTypeFilter])

  const active = activeId ? rows.find((r) => r.id === activeId) ?? null : null

  useEffect(() => {
    if (!active) {
      setProvider(null)
      setAdminNote('')
      return
    }
    setAdminNote(String(active.adminNote ?? active.reviewerNotes ?? ''))
    const targetId = String(active.targetId ?? '')
    if (!targetId) {
      setProvider(null)
      return
    }
    let cancelled = false
    const run = async () => {
      setProviderLoading(true)
      try {
        const p = await fetchProvider(targetId)
        if (!cancelled) setProvider(p)
      } catch {
        if (!cancelled) setProvider(null)
      } finally {
        if (!cancelled) setProviderLoading(false)
      }
    }
    void run()
    return () => {
      cancelled = true
    }
  }, [activeId])

  const documents = useMemo(() => {
    const fromRequest = Array.isArray(active?.documents)
      ? (active!.documents as Array<Record<string, unknown>>)
      : []
    const fromProvider = Array.isArray(provider?.documents)
      ? (provider!.documents as Array<Record<string, unknown>>)
      : []
    const merged = [...fromRequest, ...fromProvider]
    return merged.filter((d) => String(d.url ?? '').trim())
  }, [active, provider])

  const runAction = async (status: VerificationStatus) => {
    if (!active) return
    setBusy(true)
    setError('')
    try {
      await reviewVerificationRequest({
        id: active.id,
        status,
        adminNote,
      })
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="v-page">
      <div className="v-main">
        <header className="v-page-head">
          <h1>Provider verification</h1>
          <p>Review verification requests for providers (not places).</p>
        </header>

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
              <IconInfo />
            </div>
            <div>
              <span className="v-stat-label">Needs Info</span>
              <strong>{stats.needsInfo.toLocaleString()}</strong>
              <em>Waiting on provider</em>
            </div>
          </article>
          <article className="v-stat">
            <div className="v-stat-icon green">
              <IconShieldCheck />
            </div>
            <div>
              <span className="v-stat-label">Approved</span>
              <strong>{stats.approved.toLocaleString()}</strong>
              <em>Verified</em>
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
                ['pending', `Pending (${stats.pending})`],
                ['needsInfo', `Needs Info (${stats.needsInfo})`],
                ['approved', `Approved (${stats.approved})`],
                ['rejected', `Rejected (${stats.rejected})`],
                ['all', `All (${rows.length})`],
              ] as const
            ).map(([key, label]) => (
              <button
                key={key}
                type="button"
                className={statusFilter === key ? 'active' : ''}
                onClick={() => setStatusFilter(key)}
              >
                {label}
              </button>
            ))}
          </div>
          <div className="v-toolbar-right" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <input
              value={targetTypeFilter}
              onChange={(e) => setTargetTypeFilter(e.target.value)}
              placeholder="Filter targetType…"
              style={{ minWidth: 160 }}
            />
            <button type="button" className="btn" onClick={() => void load()}>
              <IconRefresh /> Refresh
            </button>
          </div>
        </div>

        <div className="v-table-card">
          <div className="v-table-scroll">
            {loading ? (
              <p className="muted" style={{ padding: 16 }}>
                Loading…
              </p>
            ) : filtered.length === 0 ? (
              <p className="muted" style={{ padding: 16 }}>
                No verification requests match your filters.
              </p>
            ) : (
              <table className="v-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Target Type</th>
                    <th>Target ID</th>
                    <th>Status</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((r) => {
                    const status = mapStatus(r.status)
                    return (
                      <tr
                        key={r.id}
                        className={active?.id === r.id ? 'active' : ''}
                        onClick={() => setActiveId(r.id)}
                        style={{ cursor: 'pointer' }}
                      >
                        <td>
                          <strong>{requestName(r)}</strong>
                        </td>
                        <td>{String(r.targetType ?? '—')}</td>
                        <td className="muted">{String(r.targetId ?? '—')}</td>
                        <td>{statusPill(status)}</td>
                        <td className="muted">{formatWhen(r.createdAt)}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {active ? (
        <aside className="v-panel">
          <div className="v-panel-top">
            <div>
              <h2>{requestName(active)}</h2>
              <div className="v-panel-sub">
                {statusPill(mapStatus(active.status))}
                <p>
                  {String(active.targetType ?? 'provider')} · {String(active.targetId ?? '—')}
                </p>
              </div>
            </div>
            <button type="button" className="v-close" onClick={() => setActiveId(null)}>
              <IconX />
            </button>
          </div>

          <div className="v-panel-scroll">
            <section className="v-block">
              <h3>Request fields</h3>
              <div className="table-wrap">
                <table className="table">
                  <tbody>
                    {(
                      [
                        ['id', active.id],
                        ['status', String(active.status ?? '—')],
                        ['targetType', String(active.targetType ?? '—')],
                        ['targetId', String(active.targetId ?? '—')],
                        ['uid', String(active.uid ?? active.userId ?? '—')],
                        ['createdAt', formatWhen(active.createdAt)],
                        ['reviewedAt', formatWhen(active.reviewedAt)],
                        ['reviewedBy', String(active.reviewedBy ?? '—')],
                        ['message', String(active.message ?? active.notes ?? '—')],
                      ] as const
                    ).map(([label, value]) => (
                      <tr key={label}>
                        <th style={{ width: 120 }}>{label}</th>
                        <td>{value}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>

            <section className="v-block">
              <h3>Provider</h3>
              {providerLoading ? (
                <p className="muted">Loading provider…</p>
              ) : provider ? (
                <div>
                  <p style={{ margin: '0 0 8px' }}>
                    <strong>{String(provider.name ?? provider.id)}</strong>
                    {' · '}
                    {String(provider.category ?? '—')}
                    {' · '}
                    {String(provider.city ?? '—')}
                  </p>
                  <div className="pp-pills" style={{ marginBottom: 8 }}>
                    {provider.verified === true ? (
                      <span className="pp-pill ok">Verified</span>
                    ) : (
                      <span className="pp-pill muted">Unverified</span>
                    )}
                    {provider.hidden === true ? (
                      <span className="pp-pill warn">Hidden</span>
                    ) : null}
                    {provider.availableNow === true ? (
                      <span className="pp-pill live">Available</span>
                    ) : null}
                  </div>
                  <Link className="btn" to={`/providers/${provider.id}`}>
                    Open provider detail
                  </Link>
                </div>
              ) : (
                <p className="muted">
                  No provider found for targetId {String(active.targetId ?? '—')}.
                </p>
              )}
            </section>

            <section className="v-block">
              <h3>Documents</h3>
              {documents.length === 0 ? (
                <p className="muted">No documents attached.</p>
              ) : (
                <ul style={{ margin: 0, paddingLeft: 18 }}>
                  {documents.map((d, i) => {
                    const url = String(d.url ?? '')
                    const title = String(d.title ?? d.fileName ?? d.type ?? `Document ${i + 1}`)
                    return (
                      <li key={`${url}-${i}`} style={{ marginBottom: 6 }}>
                        <a href={url} target="_blank" rel="noreferrer">
                          {title}
                        </a>
                        {d.type ? (
                          <span className="muted"> · {String(d.type)}</span>
                        ) : null}
                      </li>
                    )
                  })}
                </ul>
              )}
            </section>

            <section className="v-block">
              <h3>Admin note</h3>
              <textarea
                rows={3}
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                placeholder="Add a note for the provider or audit trail…"
              />
            </section>
          </div>

          <div className="v-actions">
            <button
              type="button"
              className="v-btn reject"
              disabled={busy}
              onClick={() => void runAction('rejected')}
            >
              <IconX width={15} height={15} />
              Reject
            </button>
            <button
              type="button"
              className="v-btn info"
              disabled={busy}
              onClick={() => void runAction('needsInfo')}
            >
              <IconInfo width={15} height={15} />
              Request More Info
            </button>
            <button
              type="button"
              className="v-btn approve"
              disabled={busy}
              onClick={() => void runAction('approved')}
            >
              <IconCheck width={15} height={15} />
              {busy ? 'Saving…' : 'Approve'}
            </button>
          </div>
        </aside>
      ) : null}
    </div>
  )
}
