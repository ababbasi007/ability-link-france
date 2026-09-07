import { useEffect, useMemo, useState } from 'react'
import { useAuth } from '../lib/auth'
import {
  fetchAiOversight,
  fetchAssistantReports,
  setAiOversightStatus,
  setAssistantReportStatus,
} from '../lib/data'
import { cell, formatWhen, type OpsDoc } from '../lib/opsUtils'
import { IconRefresh, IconSearch } from '../components/icons'

export function AiOpsPage() {
  const { user } = useAuth()
  const [tab, setTab] = useState<'oversight' | 'reports'>('oversight')
  const [oversight, setOversight] = useState<OpsDoc[]>([])
  const [reports, setReports] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [o, r] = await Promise.all([fetchAiOversight(200), fetchAssistantReports(200)])
      setOversight(o)
      setReports(r)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load AI data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const rows = useMemo(() => {
    const list = tab === 'oversight' ? oversight : reports
    const needle = q.trim().toLowerCase()
    if (!needle) return list
    return list.filter((r) => JSON.stringify(r).toLowerCase().includes(needle))
  }, [tab, oversight, reports, q])

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>AI Assistant Oversight</h1>
          <p>Review flagged AI replies and provider assistant misconduct reports.</p>
        </div>
        <button type="button" className="btn secondary" onClick={() => void load()}>
          <IconRefresh /> Refresh
        </button>
      </header>
      {error ? <div className="alert error">{error}</div> : null}
      <div className="tabs">
        <button type="button" className={`tab ${tab === 'oversight' ? 'active' : ''}`} onClick={() => setTab('oversight')}>
          AI Oversight ({oversight.length})
        </button>
        <button type="button" className={`tab ${tab === 'reports' ? 'active' : ''}`} onClick={() => setTab('reports')}>
          Assistant Reports ({reports.length})
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
                {tab === 'oversight' ? (
                  <>
                    <th>User</th>
                    <th>Flags</th>
                    <th>Score</th>
                    <th>Prompt</th>
                    <th>Reply</th>
                  </>
                ) : (
                  <>
                    <th>Provider</th>
                    <th>Reason</th>
                    <th>User</th>
                    <th>Detail</th>
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
                  {tab === 'oversight' ? (
                    <>
                      <td>{cell(row.uid)}</td>
                      <td>{cell(row.flags)}</td>
                      <td>{cell(row.score)}</td>
                      <td>{cell(String(row.prompt ?? '').slice(0, 60))}</td>
                      <td>{cell(String(row.reply ?? '').slice(0, 60))}</td>
                    </>
                  ) : (
                    <>
                      <td>{cell(row.providerName)}</td>
                      <td>{cell(row.reason)}</td>
                      <td>{cell(row.uid)}</td>
                      <td>{cell(String(row.detail ?? '').slice(0, 60))}</td>
                    </>
                  )}
                  <td>{cell(row.status ?? 'open')}</td>
                  <td>{formatWhen(row.createdAt)}</td>
                  <td>
                    <button
                      type="button"
                      className="btn small"
                      disabled={busyId === row.id}
                      onClick={async () => {
                        setBusyId(row.id)
                        try {
                          if (tab === 'oversight') {
                            await setAiOversightStatus(row.id, 'reviewed', user?.uid ?? '')
                            setOversight((prev) => prev.map((r) => (r.id === row.id ? { ...r, status: 'reviewed' } : r)))
                          } else {
                            await setAssistantReportStatus(row.id, 'resolved')
                            setReports((prev) => prev.map((r) => (r.id === row.id ? { ...r, status: 'resolved' } : r)))
                          }
                        } catch (err) {
                          setError(err instanceof Error ? err.message : 'Update failed')
                        } finally {
                          setBusyId('')
                        }
                      }}
                    >
                      Review
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
