import { useEffect, useMemo, useState } from 'react'
import {
  fetchPassportAccessLogs,
  fetchPassportShares,
  revokePassportShare,
} from '../lib/data'
import { formatWhen } from '../lib/opsUtils'
import {
  IconBan,
  IconLock,
  IconRefresh,
  IconSearch,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }
type TabKey = 'shares' | 'logs'
type StatusFilter = 'all' | 'active' | 'revoked'

/** Safe field join — never stringify full share docs (may contain PHI). */
function fieldsLabel(fields: unknown): string {
  if (!Array.isArray(fields)) return '—'
  return fields.map((f) => String(f)).join(', ') || '—'
}

function consentLabel(consent: unknown): string {
  if (consent == null || consent === '') return '—'
  if (typeof consent === 'boolean') return consent ? 'Yes' : 'No'
  return String(consent)
}

function statusPill(status: string) {
  const s = String(status || '').toLowerCase()
  const cls = s === 'active' ? 'active' : s === 'revoked' ? 'blocked' : 'inactive'
  const label =
    s === 'active' ? 'Active' : s === 'revoked' ? 'Revoked' : status || '—'
  return <span className={`us-pill ${cls}`}>{label}</span>
}

export function PassportAdminPage() {
  const [tab, setTab] = useState<TabKey>('shares')
  const [shares, setShares] = useState<Doc[]>([])
  const [logs, setLogs] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [q, setQ] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [s, l] = await Promise.all([
        fetchPassportShares(200),
        fetchPassportAccessLogs(200),
      ])
      setShares(s)
      setLogs(l)
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to load passport data',
      )
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredShares = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return shares.filter((row) => {
      const status = String(row.status ?? '').toLowerCase()
      if (statusFilter !== 'all' && status !== statusFilter) return false
      if (!needle) return true
      return String(row.ownerUid ?? '')
        .toLowerCase()
        .includes(needle)
    })
  }, [shares, q, statusFilter])

  const filteredLogs = useMemo(() => {
    const needle = q.trim().toLowerCase()
    if (!needle) return logs
    return logs.filter((row) => {
      return (
        String(row.ownerUid ?? '')
          .toLowerCase()
          .includes(needle) ||
        String(row.shareId ?? '')
          .toLowerCase()
          .includes(needle) ||
        String(row.viewerUid ?? '')
          .toLowerCase()
          .includes(needle) ||
        String(row.viewerName ?? '')
          .toLowerCase()
          .includes(needle)
      )
    })
  }, [logs, q])

  const forceRevoke = async (id: string) => {
    const ok = window.confirm(
      'Force-revoke this passport share? The owner and viewers will lose access.',
    )
    if (!ok) return
    const reason =
      window.prompt('Optional revoke reason (shown in activity logs):') ?? ''
    setBusyId(id)
    setError('')
    setMsg('')
    try {
      await revokePassportShare(id, reason)
      setShares((prev) =>
        prev.map((s) =>
          s.id === id ? { ...s, status: 'revoked', revokeReason: reason } : s,
        ),
      )
      setMsg(`Share ${id} revoked.`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Revoke failed')
    } finally {
      setBusyId('')
    }
  }

  return (
    <div className="dash">
      <div className="page-head">
        <div>
          <h1 className="page-title">Passport Admin</h1>
          <p className="muted">
            Privacy-first share oversight. For consents, see{' '}
            <a href="/caregiver-ops">Caregiver & Consent</a>.
          </p>
        </div>
        <button type="button" className="btn" onClick={() => void load()}>
          <IconRefresh /> Refresh
        </button>
      </div>

      <div
        className="card"
        style={{
          marginBottom: 14,
          display: 'flex',
          gap: 10,
          alignItems: 'flex-start',
          background: '#eff6ff',
          borderColor: '#bfdbfe',
        }}
      >
        <IconLock width={18} height={18} />
        <div>
          <strong>Snapshots and health data are never shown in this console.</strong>
          <p className="muted" style={{ margin: '4px 0 0' }}>
            Only share metadata and access audit fields are listed. PHI fields
            (snapshot, healthcare, allergies, conditions, emergency contacts) are
            never rendered.
          </p>
        </div>
      </div>

      <div
        className="tabs"
        style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap' }}
      >
        <button
          type="button"
          className={`btn${tab === 'shares' ? ' primary' : ''}`}
          onClick={() => {
            setTab('shares')
            setQ('')
          }}
        >
          Shares ({shares.length})
        </button>
        <button
          type="button"
          className={`btn${tab === 'logs' ? ' primary' : ''}`}
          onClick={() => {
            setTab('logs')
            setQ('')
          }}
        >
          Access logs ({logs.length})
        </button>
      </div>

      {error ? (
        <div className="card" style={{ borderColor: '#fecaca', marginBottom: 12 }}>
          {error}
        </div>
      ) : null}
      {msg ? (
        <div className="card" style={{ marginBottom: 12 }}>
          {msg}
        </div>
      ) : null}

      <div className="card">
        <div
          style={{
            display: 'flex',
            gap: 10,
            flexWrap: 'wrap',
            marginBottom: 12,
            alignItems: 'center',
          }}
        >
          <div className="search-wrap" style={{ maxWidth: 360, flex: 1 }}>
            <IconSearch />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder={
                tab === 'shares' ? 'Search ownerUid…' : 'Search logs…'
              }
            />
          </div>
          {tab === 'shares' ? (
            <select
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as StatusFilter)
              }
            >
              <option value="all">All statuses</option>
              <option value="active">Active</option>
              <option value="revoked">Revoked</option>
            </select>
          ) : null}
        </div>

        {loading ? (
          <p className="muted">Loading…</p>
        ) : tab === 'shares' ? (
          filteredShares.length === 0 ? (
            <p className="muted">No passport shares match your filters.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Id</th>
                    <th>Owner UID</th>
                    <th>Fields</th>
                    <th>Status</th>
                    <th>Consent</th>
                    <th>Access count</th>
                    <th>Last viewer</th>
                    <th>Expires</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredShares.map((row) => {
                    const status = String(row.status ?? '')
                    return (
                      <tr key={row.id}>
                        <td>
                          <code style={{ fontSize: 11 }}>{row.id}</code>
                        </td>
                        <td>
                          <code style={{ fontSize: 11 }}>
                            {String(row.ownerUid ?? '—')}
                          </code>
                        </td>
                        <td>{fieldsLabel(row.fields)}</td>
                        <td>{statusPill(status)}</td>
                        <td>{consentLabel(row.consent)}</td>
                        <td>{String(row.accessCount ?? 0)}</td>
                        <td>
                          {String(
                            row.lastViewerName ??
                              row.lastViewerUid ??
                              row.lastViewer ??
                              '—',
                          )}
                        </td>
                        <td>{formatWhen(row.expiresAt)}</td>
                        <td>{formatWhen(row.createdAt)}</td>
                        <td>
                          {status.toLowerCase() !== 'revoked' ? (
                            <button
                              type="button"
                              className="btn"
                              disabled={busyId === row.id}
                              onClick={() => void forceRevoke(row.id)}
                            >
                              <IconBan width={14} height={14} /> Force revoke
                            </button>
                          ) : (
                            <span className="muted">—</span>
                          )}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )
        ) : filteredLogs.length === 0 ? (
          <p className="muted">No access logs found.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Owner UID</th>
                  <th>Share ID</th>
                  <th>Action</th>
                  <th>Viewer name</th>
                  <th>Viewer UID</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <code style={{ fontSize: 11 }}>
                        {String(row.ownerUid ?? '—')}
                      </code>
                    </td>
                    <td>
                      <code style={{ fontSize: 11 }}>
                        {String(row.shareId ?? '—')}
                      </code>
                    </td>
                    <td>{String(row.action ?? '—')}</td>
                    <td>{String(row.viewerName ?? '—')}</td>
                    <td>
                      <code style={{ fontSize: 11 }}>
                        {String(row.viewerUid ?? '—')}
                      </code>
                    </td>
                    <td>{formatWhen(row.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
