import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  IconBell,
  IconCalendar,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconCloud,
  IconCreditCard,
  IconDatabase,
  IconDownload,
  IconEye,
  IconFileText,
  IconFilter,
  IconFlag,
  IconLock,
  IconMapPin,
  IconSearch,
  IconShieldCheck,
  IconTrash,
  IconUsers,
  IconWarning,
  IconXCircle,
} from '../components/icons'
import { DemoBanner } from '../components/DemoBanner'
import { clearActivityLogs, fetchActivityLogs } from '../lib/data'

type LogLevel = 'info' | 'warning' | 'error' | 'critical'

type Doc = Record<string, unknown> & { id: string }

type LogRow = {
  id: string
  time: string
  level: LogLevel
  module: string
  event: string
  user: string
  ip: string
  details: string
}

function formatDateTime(value: unknown): string {
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
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
  })
}

function mapLevel(value: unknown): LogLevel {
  const s = String(value ?? 'info').toLowerCase()
  if (s === 'warning' || s === 'warn') return 'warning'
  if (s === 'error') return 'error'
  if (s === 'critical' || s === 'fatal') return 'critical'
  return 'info'
}

function toRow(doc: Doc): LogRow {
  return {
    id: doc.id,
    time: formatDateTime(doc.createdAt),
    level: mapLevel(doc.level),
    module: String(doc.module ?? 'System'),
    event: String(doc.event ?? '—'),
    user: String(doc.user ?? doc.actorUid ?? '—'),
    ip: String(doc.ip ?? '—'),
    details: String(doc.details ?? ''),
  }
}

function levelLabel(level: LogLevel) {
  switch (level) {
    case 'info':
      return 'Info'
    case 'warning':
      return 'Warning'
    case 'error':
      return 'Error'
    case 'critical':
      return 'Critical'
  }
}

function moduleIcon(module: string): ReactNode {
  const props = { width: 14, height: 14 }
  const m = module.toLowerCase()
  if (m.includes('auth')) return <IconLock {...props} />
  if (m.includes('place')) return <IconMapPin {...props} />
  if (m.includes('payment')) return <IconCreditCard {...props} />
  if (m.includes('user')) return <IconUsers {...props} />
  if (m.includes('database') || m.includes('firestore')) return <IconDatabase {...props} />
  if (m.includes('backup')) return <IconCloud {...props} />
  if (m.includes('report')) return <IconFlag {...props} />
  if (m.includes('notif')) return <IconBell {...props} />
  if (m.includes('api')) return <IconFileText {...props} />
  return <IconShieldCheck {...props} />
}

export function SystemLogsPage() {
  const [rows, setRows] = useState<LogRow[]>([])
  const [fetchFailed, setFetchFailed] = useState(false)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [search, setSearch] = useState('')
  const [levelFilter, setLevelFilter] = useState('all')
  const [moduleFilter, setModuleFilter] = useState('all')
  const [userFilter, setUserFilter] = useState('all')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)

  const reload = useCallback(async () => {
    try {
      const data = await fetchActivityLogs(200)
      setRows(data.map((d) => toRow(d as Doc)))
      setFetchFailed(false)
      setError('')
    } catch (e) {
      setRows([])
      setFetchFailed(true)
      setError(e instanceof Error ? e.message : String(e))
    }
  }, [])

  useEffect(() => {
    void reload()
  }, [reload])

  const modules = useMemo(() => {
    return [...new Set(rows.map((r) => r.module))].sort()
  }, [rows])

  const users = useMemo(() => {
    return [...new Set(rows.map((r) => r.user))].sort()
  }, [rows])

  const stats = useMemo(() => {
    const total = rows.length
    const info = rows.filter((r) => r.level === 'info').length
    const warnings = rows.filter((r) => r.level === 'warning').length
    const errors = rows.filter((r) => r.level === 'error').length
    const critical = rows.filter((r) => r.level === 'critical').length
    const pct = (n: number) => (total ? `${((n / total) * 100).toFixed(1)}%` : '0%')
    return {
      total,
      info,
      infoPct: `${pct(info)} of total`,
      warnings,
      warningsPct: `${pct(warnings)} of total`,
      errors,
      errorsPct: `${pct(errors)} of total`,
      critical,
      criticalPct: `${pct(critical)} of total`,
    }
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      if (levelFilter !== 'all' && r.level !== levelFilter) return false
      if (moduleFilter !== 'all' && r.module !== moduleFilter) return false
      if (userFilter !== 'all' && r.user !== userFilter) return false
      if (!q) return true
      return (
        r.event.toLowerCase().includes(q) ||
        r.details.toLowerCase().includes(q) ||
        r.user.toLowerCase().includes(q) ||
        r.module.toLowerCase().includes(q)
      )
    })
  }, [rows, search, levelFilter, moduleFilter, userFilter])

  const displayTotal = filtered.length
  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = pageRows.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)

  const exportCsv = () => {
    const header = ['Time', 'Level', 'Module', 'Event', 'User', 'IP', 'Details']
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [r.time, r.level, r.module, r.event, r.user, r.ip, r.details]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-system-logs.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const clearLogs = async () => {
    if (!window.confirm('Clear recent activity logs from Firestore?')) return
    setBusy(true)
    setError('')
    try {
      await clearActivityLogs()
      await reload()
      setPage(1)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  const pageButtons = useMemo(() => {
    const pages: (number | '…')[] = []
    if (pageCount <= 7) {
      for (let i = 1; i <= pageCount; i++) pages.push(i)
      return pages
    }
    pages.push(1, 2, 3, 4, 5, '…', pageCount)
    return pages
  }, [pageCount])

  return (
    <div className="lg-page">
      <header className="lg-head">
        <div>
          <h1>System Logs</h1>
          <p>Monitor system activities and events.</p>
        </div>
        <div className="lg-head-actions">
          <button
            type="button"
            className="lg-btn ghost"
            onClick={exportCsv}
            disabled={busy}
          >
            <IconDownload width={15} height={15} />
            Export Logs
          </button>
          <button
            type="button"
            className="lg-btn primary"
            onClick={() => void clearLogs()}
            disabled={busy}
          >
            <IconTrash width={15} height={15} />
            Clear Logs
          </button>
        </div>
      </header>

      <DemoBanner
        active={fetchFailed}
        reason="Firestore fetch failed — showing empty list"
      />
      {error ? <div className="error">{error}</div> : null}

      <div className="lg-stats">
        <article className="lg-stat">
          <div className="lg-stat-icon blue">
            <IconFileText />
          </div>
          <div>
            <span>Total Logs</span>
            <strong>{stats.total.toLocaleString()}</strong>
            <em>Loaded</em>
          </div>
        </article>
        <article className="lg-stat">
          <div className="lg-stat-icon green">
            <IconCheckCircle />
          </div>
          <div>
            <span>Info</span>
            <strong>{stats.info.toLocaleString()}</strong>
            <em>{stats.infoPct}</em>
          </div>
        </article>
        <article className="lg-stat">
          <div className="lg-stat-icon amber">
            <IconWarning />
          </div>
          <div>
            <span>Warnings</span>
            <strong>{stats.warnings.toLocaleString()}</strong>
            <em>{stats.warningsPct}</em>
          </div>
        </article>
        <article className="lg-stat">
          <div className="lg-stat-icon red">
            <IconXCircle />
          </div>
          <div>
            <span>Errors</span>
            <strong>{stats.errors.toLocaleString()}</strong>
            <em>{stats.errorsPct}</em>
          </div>
        </article>
        <article className="lg-stat">
          <div className="lg-stat-icon purple">
            <IconShieldCheck />
          </div>
          <div>
            <span>Critical</span>
            <strong>{stats.critical.toLocaleString()}</strong>
            <em>{stats.criticalPct}</em>
          </div>
        </article>
      </div>

      <div className="lg-filters">
        <div className="lg-search">
          <IconSearch className="lg-search-icon" />
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Search logs..."
          />
        </div>
        <select
          value={levelFilter}
          onChange={(e) => {
            setLevelFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Log Levels</option>
          <option value="info">Info</option>
          <option value="warning">Warning</option>
          <option value="error">Error</option>
          <option value="critical">Critical</option>
        </select>
        <select
          value={moduleFilter}
          onChange={(e) => {
            setModuleFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Modules</option>
          {modules.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
        <select
          value={userFilter}
          onChange={(e) => {
            setUserFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Users</option>
          {users.map((u) => (
            <option key={u} value={u}>
              {u}
            </option>
          ))}
        </select>
        <button type="button" className="lg-btn ghost date">
          <IconCalendar width={15} height={15} />
          All dates
        </button>
        <button
          type="button"
          className="lg-btn ghost"
          onClick={() => void reload()}
          disabled={busy}
        >
          <IconFilter width={15} height={15} />
          Refresh
        </button>
      </div>

      <div className="lg-table-card">
        <div className="lg-table-scroll">
          <table className="lg-table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Level</th>
                <th>Module</th>
                <th>Event</th>
                <th>User</th>
                <th>IP Address</th>
                <th>Details</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {pageRows.map((r) => (
                <tr key={r.id}>
                  <td className="lg-time">{r.time}</td>
                  <td>
                    <span className={`lg-level ${r.level}`}>
                      {levelLabel(r.level)}
                    </span>
                  </td>
                  <td>
                    <div className="lg-module">
                      {moduleIcon(r.module)}
                      <span>{r.module}</span>
                    </div>
                  </td>
                  <td className="lg-event">{r.event}</td>
                  <td className="lg-user">{r.user}</td>
                  <td className="lg-ip">{r.ip}</td>
                  <td className="lg-details">{r.details}</td>
                  <td>
                    <button type="button" className="lg-view" title="View details">
                      <IconEye width={15} height={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {!pageRows.length ? (
          <div className="empty" style={{ padding: 20 }}>
            {rows.length === 0
              ? 'No activity logs yet.'
              : 'No logs match your filters.'}
          </div>
        ) : null}

        <div className="lg-footer">
          <span>
            Showing {from} to {to} of {displayTotal.toLocaleString()} logs
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
              {[8, 10, 25, 50].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
          <div className="lg-pages">
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
            {pageButtons.map((p, i) =>
              p === '…' ? (
                <span key={`e-${i}`}>…</span>
              ) : (
                <button
                  key={`${p}-${i}`}
                  type="button"
                  className={p === safePage ? 'active' : ''}
                  onClick={() => setPage(p)}
                >
                  {p}
                </button>
              ),
            )}
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
