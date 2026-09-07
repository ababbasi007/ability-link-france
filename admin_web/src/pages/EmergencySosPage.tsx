import { useEffect, useMemo, useState } from 'react'
import {
  fetchEmergencyResources,
  fetchSosAlerts,
  setSosAlertStatus,
  upsertEmergencyResource,
} from '../lib/data'
import { IconPhone, IconRefresh, IconSearch, IconWarning } from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

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
    hour: 'numeric',
    minute: '2-digit',
  })
}

function statusTone(status: string) {
  switch (status) {
    case 'acknowledged':
      return 'warn'
    case 'resolved':
      return 'ok'
    case 'cancelled':
      return 'muted'
    default:
      return 'danger'
  }
}

export function EmergencySosPage() {
  const [tab, setTab] = useState<'alerts' | 'resources'>('alerts')
  const [alerts, setAlerts] = useState<Doc[]>([])
  const [resources, setResources] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [filter, setFilter] = useState<'all' | 'open' | 'acknowledged' | 'resolved'>('open')
  const [busyId, setBusyId] = useState('')
  const [resourceForm, setResourceForm] = useState({
    name: '',
    kind: 'hotline',
    phone: '',
    summary: '',
    country: 'PK',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [a, r] = await Promise.all([
        fetchSosAlerts(150),
        fetchEmergencyResources(200),
      ])
      setAlerts(a)
      setResources(r)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load SOS data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredAlerts = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return alerts
      .filter((a) => {
        const status = String(a.status ?? 'open')
        if (filter !== 'all' && status !== filter) return false
        if (!needle) return true
        return (
          String(a.message ?? '').toLowerCase().includes(needle) ||
          String(a.uid ?? '').toLowerCase().includes(needle) ||
          String(a.emergencyNumber ?? '').toLowerCase().includes(needle) ||
          a.id.toLowerCase().includes(needle)
        )
      })
      .sort((a, b) => {
        const da = asDate(a.createdAt)?.getTime() ?? 0
        const db = asDate(b.createdAt)?.getTime() ?? 0
        return db - da
      })
  }, [alerts, filter, q])

  const openCount = alerts.filter((a) => String(a.status ?? 'open') === 'open').length

  const act = async (
    id: string,
    status: 'acknowledged' | 'resolved' | 'cancelled',
  ) => {
    setBusyId(id)
    try {
      await setSosAlertStatus(id, status)
      setAlerts((prev) =>
        prev.map((a) => (a.id === id ? { ...a, status } : a)),
      )
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveResource = async () => {
    if (!resourceForm.name.trim() || !resourceForm.phone.trim()) {
      setError('Name and phone are required')
      return
    }
    try {
      await upsertEmergencyResource(null, {
        name: resourceForm.name.trim(),
        kind: resourceForm.kind,
        phone: resourceForm.phone.trim(),
        summary: resourceForm.summary.trim(),
        country: resourceForm.country.trim().toUpperCase(),
        stepFree: true,
        lat: 0,
        lng: 0,
      })
      setResourceForm({
        name: '',
        kind: 'hotline',
        phone: '',
        summary: '',
        country: 'PK',
      })
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not save resource')
    }
  }

  return (
    <div className="dash">
      <div className="page-head">
        <div>
          <h1 className="page-title">Emergency SOS</h1>
          <p className="muted">
            Live SOS inbox and emergency resources. Open alerts need acknowledge / resolve.
          </p>
        </div>
        <button type="button" className="btn" onClick={() => void load()}>
          <IconRefresh /> Refresh
        </button>
      </div>

      <div className="pp-kpis" style={{ marginBottom: 16 }}>
        <div className="card" style={{ padding: 14 }}>
          <div className="muted" style={{ fontSize: 12 }}>Open alerts</div>
          <strong style={{ fontSize: 24, color: '#b91c1c' }}>{openCount}</strong>
        </div>
        <div className="card" style={{ padding: 14 }}>
          <div className="muted" style={{ fontSize: 12 }}>Total alerts</div>
          <strong style={{ fontSize: 24 }}>{alerts.length}</strong>
        </div>
        <div className="card" style={{ padding: 14 }}>
          <div className="muted" style={{ fontSize: 12 }}>Resources</div>
          <strong style={{ fontSize: 24 }}>{resources.length}</strong>
        </div>
      </div>

      <div className="tabs" style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
        <button
          type="button"
          className={`btn${tab === 'alerts' ? ' primary' : ''}`}
          onClick={() => setTab('alerts')}
        >
          <IconWarning /> SOS Alerts
        </button>
        <button
          type="button"
          className={`btn${tab === 'resources' ? ' primary' : ''}`}
          onClick={() => setTab('resources')}
        >
          <IconPhone /> Emergency Resources
        </button>
      </div>

      {error ? (
        <div className="card" style={{ borderColor: '#fecaca', marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      {tab === 'alerts' ? (
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
            <div className="search-wrap" style={{ flex: 1, minWidth: 200 }}>
              <IconSearch />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Search message, uid, phone…"
              />
            </div>
            {(['open', 'acknowledged', 'resolved', 'all'] as const).map((f) => (
              <button
                key={f}
                type="button"
                className={`btn${filter === f ? ' primary' : ''}`}
                onClick={() => setFilter(f)}
              >
                {f}
              </button>
            ))}
          </div>

          {loading ? (
            <p className="muted">Loading alerts…</p>
          ) : filteredAlerts.length === 0 ? (
            <p className="muted">No SOS alerts match this filter.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>When</th>
                    <th>Status</th>
                    <th>User</th>
                    <th>Message / contacts</th>
                    <th>Location</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredAlerts.map((a) => {
                    const status = String(a.status ?? 'open')
                    const medical = (a.medical ?? {}) as Record<string, unknown>
                    const mapsUrl = String(a.mapsUrl ?? '')
                    const lat = a.lat
                    const lng = a.lng
                    return (
                      <tr key={a.id}>
                        <td>{formatWhen(a.createdAt)}</td>
                        <td>
                          <span className={`pp-pill ${statusTone(status)}`}>
                            {status}
                          </span>
                        </td>
                        <td>
                          <div style={{ fontFamily: 'monospace', fontSize: 12 }}>
                            {String(a.uid ?? '—').slice(0, 10)}…
                          </div>
                          <div className="muted" style={{ fontSize: 12 }}>
                            {String(a.emergencyNumber ?? '')}
                          </div>
                        </td>
                        <td>
                          <div>{String(a.message || 'SOS pressed')}</div>
                          <div className="muted" style={{ fontSize: 12 }}>
                            {[a.contactNames].flat().filter(Boolean).join(', ') ||
                              String(medical.conditions ?? '')}
                          </div>
                        </td>
                        <td>
                          {mapsUrl ? (
                            <a href={mapsUrl} target="_blank" rel="noreferrer">
                              Open map
                            </a>
                          ) : lat != null && lng != null ? (
                            <a
                              href={`https://maps.google.com/?q=${lat},${lng}`}
                              target="_blank"
                              rel="noreferrer"
                            >
                              {Number(lat).toFixed(4)}, {Number(lng).toFixed(4)}
                            </a>
                          ) : (
                            '—'
                          )}
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                            {status === 'open' ? (
                              <button
                                type="button"
                                className="btn"
                                disabled={busyId === a.id}
                                onClick={() => void act(a.id, 'acknowledged')}
                              >
                                Acknowledge
                              </button>
                            ) : null}
                            {status !== 'resolved' && status !== 'cancelled' ? (
                              <button
                                type="button"
                                className="btn primary"
                                disabled={busyId === a.id}
                                onClick={() => void act(a.id, 'resolved')}
                              >
                                Resolve
                              </button>
                            ) : null}
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
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Add resource</h3>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
              gap: 10,
              marginBottom: 14,
            }}
          >
            <input
              placeholder="Name"
              value={resourceForm.name}
              onChange={(e) =>
                setResourceForm((s) => ({ ...s, name: e.target.value }))
              }
            />
            <input
              placeholder="Kind (hotline, hospital…)"
              value={resourceForm.kind}
              onChange={(e) =>
                setResourceForm((s) => ({ ...s, kind: e.target.value }))
              }
            />
            <input
              placeholder="Phone"
              value={resourceForm.phone}
              onChange={(e) =>
                setResourceForm((s) => ({ ...s, phone: e.target.value }))
              }
            />
            <input
              placeholder="Country code"
              value={resourceForm.country}
              onChange={(e) =>
                setResourceForm((s) => ({ ...s, country: e.target.value }))
              }
            />
            <input
              placeholder="Summary"
              value={resourceForm.summary}
              onChange={(e) =>
                setResourceForm((s) => ({ ...s, summary: e.target.value }))
              }
              style={{ gridColumn: '1 / -1' }}
            />
          </div>
          <button type="button" className="btn primary" onClick={() => void saveResource()}>
            Save resource
          </button>

          <div className="table-wrap" style={{ marginTop: 18 }}>
            <table className="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Kind</th>
                  <th>Phone</th>
                  <th>Country</th>
                  <th>Summary</th>
                </tr>
              </thead>
              <tbody>
                {resources.map((r) => (
                  <tr key={r.id}>
                    <td>{String(r.name ?? '—')}</td>
                    <td>{String(r.kind ?? '—')}</td>
                    <td>{String(r.phone ?? '—')}</td>
                    <td>{String(r.country ?? '—')}</td>
                    <td className="muted">{String(r.summary ?? '')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
