import { useEffect, useMemo, useState } from 'react'
import {
  fetchBarrierAlerts,
  fetchFraudReports,
  setBarrierAlertStatus,
  setFraudReportStatus,
} from '../lib/data'
import { cell, formatWhen, type OpsDoc } from '../lib/opsUtils'
import { IconRefresh, IconSearch } from '../components/icons'

export function TrustSafetyOpsPage() {
  const [tab, setTab] = useState<'fraud' | 'barriers'>('fraud')
  const [fraud, setFraud] = useState<OpsDoc[]>([])
  const [barriers, setBarriers] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [f, b] = await Promise.all([fetchFraudReports(200), fetchBarrierAlerts(200)])
      setFraud(f)
      setBarriers(b)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load trust data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const rows = useMemo(() => {
    const list = tab === 'fraud' ? fraud : barriers
    const needle = q.trim().toLowerCase()
    if (!needle) return list
    return list.filter((r) => JSON.stringify(r).toLowerCase().includes(needle))
  }, [tab, fraud, barriers, q])

  const setStatus = async (id: string, status: string) => {
    setBusyId(id)
    try {
      if (tab === 'fraud') {
        await setFraudReportStatus(id, status)
        setFraud((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)))
      } else {
        await setBarrierAlertStatus(id, status)
        setBarriers((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)))
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Trust & Safety</h1>
          <p>Fraud reports and physical barrier alerts — separate from place reports.</p>
        </div>
        <button type="button" className="btn secondary" onClick={() => void load()}>
          <IconRefresh /> Refresh
        </button>
      </header>
      {error ? <div className="alert error">{error}</div> : null}
      <div className="tabs">
        <button type="button" className={`tab ${tab === 'fraud' ? 'active' : ''}`} onClick={() => setTab('fraud')}>
          Fraud Reports ({fraud.length})
        </button>
        <button type="button" className={`tab ${tab === 'barriers' ? 'active' : ''}`} onClick={() => setTab('barriers')}>
          Barrier Alerts ({barriers.length})
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
                {tab === 'fraud' ? (
                  <>
                    <th>Target</th>
                    <th>Reason</th>
                    <th>Reporter</th>
                  </>
                ) : (
                  <>
                    <th>Place</th>
                    <th>Detail</th>
                    <th>Severity</th>
                  </>
                )}
                <th>Status</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  {tab === 'fraud' ? (
                    <>
                      <td>{cell(row.targetType)} / {cell(row.targetId)}</td>
                      <td>{cell(row.reason)}</td>
                      <td>{cell(row.uid)}</td>
                    </>
                  ) : (
                    <>
                      <td>{cell(row.placeName ?? row.title)}</td>
                      <td>{cell(row.detail ?? row.title)}</td>
                      <td>{cell(row.severity)}</td>
                    </>
                  )}
                  <td>{cell(row.status ?? 'open')}</td>
                  <td>{formatWhen(row.createdAt)}</td>
                  <td>
                    <button type="button" className="btn small" disabled={busyId === row.id} onClick={() => void setStatus(row.id, 'resolved')}>
                      Resolve
                    </button>
                    <button type="button" className="btn small" disabled={busyId === row.id} onClick={() => void setStatus(row.id, 'rejected')}>
                      Reject
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
