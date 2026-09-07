import { useEffect, useMemo, useState } from 'react'
import {
  fetchLocationShares,
  fetchPassportAccessLogs,
  fetchPassportShares,
  fetchPatientConsents,
} from '../lib/data'
import { cell, formatWhen, type OpsDoc } from '../lib/opsUtils'
import { IconRefresh, IconSearch } from '../components/icons'

export function CaregiverOpsPage() {
  const [tab, setTab] = useState<'passports' | 'logs' | 'consents' | 'location'>('passports')
  const [shares, setShares] = useState<OpsDoc[]>([])
  const [logs, setLogs] = useState<OpsDoc[]>([])
  const [consents, setConsents] = useState<OpsDoc[]>([])
  const [locations, setLocations] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [s, l, c, loc] = await Promise.all([
        fetchPassportShares(200),
        fetchPassportAccessLogs(200),
        fetchPatientConsents(200),
        fetchLocationShares(200),
      ])
      setShares(s)
      setLogs(l)
      setConsents(c)
      setLocations(loc)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load caregiver data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const rows = useMemo(() => {
    const list =
      tab === 'passports' ? shares : tab === 'logs' ? logs : tab === 'consents' ? consents : locations
    const needle = q.trim().toLowerCase()
    if (!needle) return list
    return list.filter((r) => JSON.stringify(r).toLowerCase().includes(needle))
  }, [tab, shares, logs, consents, locations, q])

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Caregiver & Consent</h1>
          <p>Passport share audit trail, patient consents, and location shares. PHI snapshots are never shown here. Dedicated Passport admin: <a href="/passport-admin">/passport-admin</a>.</p>
        </div>
        <button type="button" className="btn secondary" onClick={() => void load()}>
          <IconRefresh /> Refresh
        </button>
      </header>
      {error ? <div className="alert error">{error}</div> : null}
      <div className="tabs">
        <button type="button" className={`tab ${tab === 'passports' ? 'active' : ''}`} onClick={() => setTab('passports')}>
          Passport Shares ({shares.length})
        </button>
        <button type="button" className={`tab ${tab === 'logs' ? 'active' : ''}`} onClick={() => setTab('logs')}>
          Access Logs ({logs.length})
        </button>
        <button type="button" className={`tab ${tab === 'consents' ? 'active' : ''}`} onClick={() => setTab('consents')}>
          Consents ({consents.length})
        </button>
        <button type="button" className={`tab ${tab === 'location' ? 'active' : ''}`} onClick={() => setTab('location')}>
          Location Shares ({locations.length})
        </button>
      </div>
      <div className="toolbar">
        <div className="search-box">
          <IconSearch />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search…" />
        </div>
      </div>
      {loading ? (
        <div className="card">Loading…</div>
      ) : (
        <div className="card table-card">
          <table>
            <thead>
              <tr>
                {tab === 'passports' ? (
                  <>
                    <th>Owner</th>
                    <th>Fields</th>
                    <th>Status</th>
                    <th>Access count</th>
                    <th>Expires</th>
                  </>
                ) : tab === 'logs' ? (
                  <>
                    <th>Owner</th>
                    <th>Share</th>
                    <th>Action</th>
                    <th>Viewer</th>
                  </>
                ) : tab === 'consents' ? (
                  <>
                    <th>Patient</th>
                    <th>Org</th>
                    <th>Needs</th>
                    <th>Status</th>
                  </>
                ) : (
                  <>
                    <th>User</th>
                    <th>Status</th>
                    <th>Lat/Lng</th>
                    <th>Expires</th>
                  </>
                )}
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  {tab === 'passports' ? (
                    <>
                      <td>{cell(row.ownerUid)}</td>
                      <td>{cell(row.fields)}</td>
                      <td>{cell(row.status)}</td>
                      <td>{cell(row.accessCount)}</td>
                      <td>{formatWhen(row.expiresAt)}</td>
                    </>
                  ) : tab === 'logs' ? (
                    <>
                      <td>{cell(row.ownerUid)}</td>
                      <td>{cell(row.shareId)}</td>
                      <td>{cell(row.action)}</td>
                      <td>{cell(row.viewerName ?? row.viewerUid)}</td>
                    </>
                  ) : tab === 'consents' ? (
                    <>
                      <td>{cell(row.patientName ?? row.uid)}</td>
                      <td>{cell(row.orgId)}</td>
                      <td>{cell(row.needs)}</td>
                      <td>{cell(row.status)}</td>
                    </>
                  ) : (
                    <>
                      <td>{cell(row.uid)}</td>
                      <td>{cell(row.status)}</td>
                      <td>{cell(row.lat)}/{cell(row.lng)}</td>
                      <td>{formatWhen(row.expiresAt)}</td>
                    </>
                  )}
                  <td>{formatWhen(row.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
