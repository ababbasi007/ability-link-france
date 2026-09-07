import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  fetchProvider,
  fetchProviderVerificationHistory,
  setProviderFlags,
  type ProviderDocument,
} from '../lib/data'
import {
  IconChevronLeft,
  IconExternalLink,
  IconRefresh,
  IconShieldCheck,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }
type TabKey = 'profile' | 'services' | 'documents' | 'verification' | 'flags'

const TABS: { key: TabKey; label: string }[] = [
  { key: 'profile', label: 'Profile' },
  { key: 'services', label: 'Services' },
  { key: 'documents', label: 'Documents' },
  { key: 'verification', label: 'Verification history' },
  { key: 'flags', label: 'Flags' },
]

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

function asList(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.map((v) => String(v)).filter(Boolean)
  }
  if (typeof value === 'string' && value.trim()) {
    return value.split(',').map((s) => s.trim()).filter(Boolean)
  }
  return []
}

function statusPill(status: string) {
  const s = status.toLowerCase()
  if (s === 'approved' || s === 'verified') {
    return <span className="v-pill v-pill-ok">Approved</span>
  }
  if (s === 'rejected' || s === 'denied') {
    return <span className="v-pill v-pill-reject">Rejected</span>
  }
  if (s.includes('need') || s.includes('info') || s.includes('review')) {
    return <span className="v-pill v-pill-review">Needs Info</span>
  }
  return <span className="v-pill v-pill-pending">Pending</span>
}

export function ProviderDetailPage() {
  const { id = '' } = useParams<{ id: string }>()
  const [tab, setTab] = useState<TabKey>('profile')
  const [provider, setProvider] = useState<Doc | null>(null)
  const [history, setHistory] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [historyLoading, setHistoryLoading] = useState(false)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [flags, setFlags] = useState({
    verified: false,
    hidden: false,
    availableNow: false,
  })

  const load = async () => {
    if (!id) {
      setError('Missing provider id')
      setLoading(false)
      return
    }
    setLoading(true)
    setError('')
    try {
      const doc = await fetchProvider(id)
      if (!doc) {
        setProvider(null)
        setError('Provider not found')
      } else {
        setProvider(doc)
        setFlags({
          verified: doc.verified === true,
          hidden: doc.hidden === true,
          availableNow: doc.availableNow === true,
        })
      }
    } catch (e) {
      setProvider(null)
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [id])

  useEffect(() => {
    if (!id || tab !== 'verification') return
    let cancelled = false
    const run = async () => {
      setHistoryLoading(true)
      try {
        const rows = await fetchProviderVerificationHistory(id)
        if (!cancelled) setHistory(rows)
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : String(e))
      } finally {
        if (!cancelled) setHistoryLoading(false)
      }
    }
    void run()
    return () => {
      cancelled = true
    }
  }, [id, tab])

  const services = useMemo(() => asList(provider?.services), [provider])
  const skills = useMemo(() => asList(provider?.skills), [provider])
  const languages = useMemo(() => asList(provider?.languages), [provider])
  const accessibilityTags = useMemo(
    () => asList(provider?.accessibilityTags),
    [provider],
  )

  const documents = useMemo((): ProviderDocument[] => {
    if (!provider || !Array.isArray(provider.documents)) return []
    return (provider.documents as ProviderDocument[]).filter((d) =>
      String(d?.url ?? '').trim(),
    )
  }, [provider])

  const saveFlags = async () => {
    if (!id) return
    setBusy(true)
    setError('')
    try {
      await setProviderFlags(id, flags)
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  if (loading) {
    return (
      <div className="dash">
        <div className="page-head">
          <div>
            <Link to="/providers" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
              <IconChevronLeft width={14} height={14} /> Back to providers
            </Link>
            <h1 className="page-title">Provider detail</h1>
          </div>
        </div>
        <div className="card">
          <p className="muted">Loading…</p>
        </div>
      </div>
    )
  }

  if (!provider) {
    return (
      <div className="dash">
        <div className="page-head">
          <div>
            <Link to="/providers" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
              <IconChevronLeft width={14} height={14} /> Back to providers
            </Link>
            <h1 className="page-title">Provider detail</h1>
          </div>
        </div>
        <div className="card">
          {error ? <div className="error">{error}</div> : <p className="muted">Provider not found.</p>}
        </div>
      </div>
    )
  }

  const name = String(provider.name ?? provider.id)
  const photo = String(provider.photoUrl ?? provider.imageUrl ?? '')

  return (
    <div className="dash">
      <div className="page-head">
        <div>
          <Link to="/providers" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
            <IconChevronLeft width={14} height={14} /> Back to providers
          </Link>
          <h1 className="page-title">{name}</h1>
          <p className="muted">
            {String(provider.category ?? '—')} · {String(provider.city ?? '—')}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <Link className="btn" to="/provider-verifications">
            <IconShieldCheck /> Verification queue
          </Link>
          <button type="button" className="btn" onClick={() => void load()}>
            <IconRefresh /> Refresh
          </button>
        </div>
      </div>

      {error ? (
        <div className="card" style={{ borderColor: '#fecaca', marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="pp-pills" style={{ marginBottom: 12 }}>
        {provider.verified === true ? (
          <span className="pp-pill ok">Verified</span>
        ) : (
          <span className="pp-pill muted">Unverified</span>
        )}
        {provider.hidden === true ? (
          <span className="pp-pill warn">Hidden</span>
        ) : (
          <span className="pp-pill muted">Visible</span>
        )}
        {provider.availableNow === true ? (
          <span className="pp-pill live">Available now</span>
        ) : (
          <span className="pp-pill muted">Not available</span>
        )}
      </div>

      <div className="tabs" style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
        {TABS.map((t) => (
          <button
            key={t.key}
            type="button"
            className={`btn${tab === t.key ? ' primary' : ''}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'profile' ? (
        <div className="card">
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '120px 1fr',
              gap: 20,
              alignItems: 'start',
            }}
          >
            <div>
              {photo ? (
                <img
                  src={photo}
                  alt=""
                  style={{ width: 96, height: 96, borderRadius: 12, objectFit: 'cover' }}
                />
              ) : (
                <div
                  style={{
                    width: 96,
                    height: 96,
                    borderRadius: 12,
                    background: '#f3f4f6',
                    display: 'grid',
                    placeItems: 'center',
                    fontWeight: 600,
                  }}
                >
                  {name.slice(0, 1).toUpperCase()}
                </div>
              )}
            </div>
            <div className="table-wrap">
              <table className="table">
                <tbody>
                  <tr>
                    <th style={{ width: 160 }}>Name</th>
                    <td>{name}</td>
                  </tr>
                  <tr>
                    <th>Title</th>
                    <td>{String(provider.title ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>Specialty</th>
                    <td>{String(provider.specialty ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>Category</th>
                    <td>{String(provider.category ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>City</th>
                    <td>{String(provider.city ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>Owner UID</th>
                    <td className="muted">{String(provider.ownerUid ?? provider.uid ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>Rating</th>
                    <td>
                      {String(provider.rating ?? '—')}
                      {provider.reviewCount != null
                        ? ` (${String(provider.reviewCount)} reviews)`
                        : ''}
                    </td>
                  </tr>
                  <tr>
                    <th>Price from</th>
                    <td>
                      {provider.priceFrom != null
                        ? `${String(provider.currency ?? '')} ${String(provider.priceFrom)}`
                        : '—'}
                    </td>
                  </tr>
                  <tr>
                    <th>Bio</th>
                    <td>{String(provider.bio ?? provider.description ?? '—')}</td>
                  </tr>
                  <tr>
                    <th>Languages</th>
                    <td>{languages.length ? languages.join(', ') : '—'}</td>
                  </tr>
                  <tr>
                    <th>Accessibility</th>
                    <td>
                      {accessibilityTags.length ? accessibilityTags.join(', ') : '—'}
                    </td>
                  </tr>
                  <tr>
                    <th>Provider ID</th>
                    <td className="muted">{provider.id}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : null}

      {tab === 'services' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Services</h3>
          {services.length === 0 ? (
            <p className="muted">No services listed.</p>
          ) : (
            <ul style={{ margin: 0, paddingLeft: 18 }}>
              {services.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ul>
          )}
          <h3 style={{ marginTop: 18 }}>Skills</h3>
          {skills.length === 0 ? (
            <p className="muted">No skills listed.</p>
          ) : (
            <div className="pp-pills">
              {skills.map((s) => (
                <span key={s} className="pp-pill muted">
                  {s}
                </span>
              ))}
            </div>
          )}
        </div>
      ) : null}

      {tab === 'documents' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Documents</h3>
          {documents.length === 0 ? (
            <p className="muted">No documents uploaded.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Type</th>
                    <th>File</th>
                    <th>Open</th>
                  </tr>
                </thead>
                <tbody>
                  {documents.map((d) => (
                    <tr key={d.id || d.url}>
                      <td>{d.title || '—'}</td>
                      <td>{d.type || '—'}</td>
                      <td className="muted">{d.fileName || '—'}</td>
                      <td>
                        <a
                          href={d.url}
                          target="_blank"
                          rel="noreferrer"
                          className="btn"
                          style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}
                        >
                          <IconExternalLink width={14} height={14} />
                          Open
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'verification' ? (
        <div className="card">
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              gap: 12,
              alignItems: 'center',
              marginBottom: 12,
            }}
          >
            <h3 style={{ margin: 0 }}>Verification history</h3>
            <Link className="btn" to="/provider-verifications">
              Open queue
            </Link>
          </div>
          {historyLoading ? (
            <p className="muted">Loading…</p>
          ) : history.length === 0 ? (
            <p className="muted">No verification requests for this provider.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th>Reviewed</th>
                    <th>Note</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((r) => (
                    <tr key={r.id}>
                      <td className="muted">{r.id}</td>
                      <td>{statusPill(String(r.status ?? 'pending'))}</td>
                      <td>{formatWhen(r.createdAt)}</td>
                      <td>{formatWhen(r.reviewedAt)}</td>
                      <td>{String(r.adminNote ?? r.reviewerNotes ?? '—')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'flags' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Provider flags</h3>
          <p className="muted">Toggle marketplace visibility and verification state.</p>
          <div style={{ display: 'grid', gap: 12, maxWidth: 360 }}>
            <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={flags.verified}
                onChange={(e) =>
                  setFlags((f) => ({ ...f, verified: e.target.checked }))
                }
              />
              Verified
            </label>
            <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={flags.hidden}
                onChange={(e) =>
                  setFlags((f) => ({ ...f, hidden: e.target.checked }))
                }
              />
              Hidden
            </label>
            <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <input
                type="checkbox"
                checked={flags.availableNow}
                onChange={(e) =>
                  setFlags((f) => ({ ...f, availableNow: e.target.checked }))
                }
              />
              Available now
            </label>
            <button
              type="button"
              className="btn primary"
              disabled={busy}
              onClick={() => void saveFlags()}
            >
              {busy ? 'Saving…' : 'Save flags'}
            </button>
          </div>
        </div>
      ) : null}
    </div>
  )
}
