import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type FormEvent,
  type ReactNode,
} from 'react'
import {
  IconBell,
  IconCheckCircle,
  IconClock,
  IconFlag,
  IconHeart,
  IconMapPin,
  IconMegaphone,
  IconRefresh,
  IconSearch,
  IconSend,
  IconShieldCheck,
  IconStar,
} from '../components/icons'
import { DemoBanner } from '../components/DemoBanner'
import { PageHeader, Widget } from '../components/PageChrome'
import { useAuth } from '../lib/auth'
import {
  createBroadcast,
  fetchBroadcasts,
  sendBroadcast,
  setBroadcastStatus,
  type BroadcastStatus,
} from '../lib/data'

type NotifStatus = 'delivered' | 'scheduled' | 'pending' | 'failed' | 'sending'
type IconKey =
  | 'megaphone'
  | 'pin'
  | 'heart'
  | 'shield'
  | 'bell'
  | 'flag'
  | 'star'
  | 'clock'

type Doc = Record<string, unknown> & { id: string }

type NotifRow = {
  id: string
  title: string
  description: string
  type: string
  audience: string
  audienceCount: number
  channel: string
  status: NotifStatus
  rate: number | null
  when: string
  icon: IconKey
  tone: string
  rawStatus: BroadcastStatus
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
  })
}

function mapUiStatus(status: string): NotifStatus {
  switch (status) {
    case 'sent':
      return 'delivered'
    case 'scheduled':
      return 'scheduled'
    case 'sending':
      return 'sending'
    case 'failed':
      return 'failed'
    case 'draft':
    default:
      return 'pending'
  }
}

function uiToBroadcastStatus(status: NotifStatus): BroadcastStatus {
  switch (status) {
    case 'delivered':
      return 'sent'
    case 'scheduled':
      return 'scheduled'
    case 'sending':
      return 'sending'
    case 'failed':
      return 'failed'
    case 'pending':
    default:
      return 'draft'
  }
}

function formatChannels(channels: unknown): string {
  const list = Array.isArray(channels) ? channels.map(String) : []
  if (!list.length) return 'In-App'
  return list
    .map((c) => {
      const lower = c.toLowerCase()
      if (lower === 'inapp' || lower === 'in-app') return 'In-App'
      if (lower === 'push') return 'Push'
      if (lower === 'email') return 'Email'
      return c.charAt(0).toUpperCase() + c.slice(1)
    })
    .join(' + ')
}

function formatAudience(audience: unknown): string {
  const a = String(audience ?? 'all').toLowerCase()
  if (a === 'active') return 'Active Users'
  return 'All Users'
}

function iconForType(type: string): { icon: IconKey; tone: string } {
  const t = type.toLowerCase()
  if (t.includes('alert')) return { icon: 'flag', tone: 'red' }
  if (t.includes('promo')) return { icon: 'heart', tone: 'purple' }
  if (t.includes('remind')) return { icon: 'clock', tone: 'amber' }
  if (t.includes('survey')) return { icon: 'star', tone: 'yellow' }
  if (t.includes('update')) return { icon: 'pin', tone: 'blue' }
  if (t.includes('verif') || t.includes('security')) return { icon: 'shield', tone: 'blue' }
  if (t.includes('announce') || t.includes('general')) return { icon: 'megaphone', tone: 'green' }
  return { icon: 'bell', tone: 'green' }
}

function displayType(type: string) {
  const raw = type.trim() || 'general'
  return raw.charAt(0).toUpperCase() + raw.slice(1)
}

function toRow(doc: Doc): NotifRow {
  const type = String(doc.type ?? 'general')
  const { icon, tone } = iconForType(type)
  const rawStatus = (String(doc.status ?? 'draft') as BroadcastStatus) || 'draft'
  const recipients = Number(doc.recipientCount ?? 0)
  const delivered = Number(doc.deliveredCount ?? 0)
  const rate =
    recipients > 0 && (rawStatus === 'sent' || rawStatus === 'failed')
      ? Math.round((delivered / recipients) * 1000) / 10
      : null
  return {
    id: doc.id,
    title: String(doc.title ?? 'Untitled'),
    description: String(doc.body ?? ''),
    type: displayType(type),
    audience: formatAudience(doc.audience),
    audienceCount: recipients,
    channel: formatChannels(doc.channels),
    status: mapUiStatus(rawStatus),
    rate,
    when: formatDateTime(doc.sentAt ?? doc.createdAt),
    icon,
    tone,
    rawStatus,
  }
}

function iconNode(key: IconKey): ReactNode {
  const props = { width: 16, height: 16 }
  switch (key) {
    case 'megaphone':
      return <IconMegaphone {...props} />
    case 'pin':
      return <IconMapPin {...props} />
    case 'heart':
      return <IconHeart {...props} />
    case 'shield':
      return <IconShieldCheck {...props} />
    case 'bell':
      return <IconBell {...props} />
    case 'flag':
      return <IconFlag {...props} />
    case 'star':
      return <IconStar {...props} />
    case 'clock':
      return <IconClock {...props} />
  }
}

export function NotificationsPage() {
  const { user } = useAuth()
  const [rows, setRows] = useState<NotifRow[]>([])
  const [fetchFailed, setFetchFailed] = useState(false)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [audience, setAudience] = useState<'all' | 'active'>('all')
  const [channelInApp, setChannelInApp] = useState(true)
  const [channelPush, setChannelPush] = useState(false)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [channelFilter, setChannelFilter] = useState('all')
  const [page, setPage] = useState(1)
  const pageSize = 10
  const [menuId, setMenuId] = useState<string | null>(null)

  const reload = useCallback(async () => {
    try {
      const data = await fetchBroadcasts(100)
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

  const stats = useMemo(() => {
    const total = rows.length
    const sent = rows.filter((r) => r.status === 'delivered' || r.rawStatus === 'sent').length
    const scheduled = rows.filter((r) => r.status === 'scheduled').length
    const delivered = rows.filter((r) => r.status === 'delivered').length
    const failed = rows.filter((r) => r.status === 'failed').length
    const pct = (n: number) => (total ? `${((n / total) * 100).toFixed(1)}%` : '0%')
    return {
      total,
      sent,
      sentPct: pct(sent),
      scheduled,
      scheduledPct: pct(scheduled),
      delivered,
      deliveredPct: delivered ? `${pct(delivered)} of loaded` : 'No deliveries yet',
      failed,
      failedPct: failed ? pct(failed) : '0% failure rate',
    }
  }, [rows])

  const channels = useMemo(() => {
    return [...new Set(rows.map((r) => r.channel))].sort()
  }, [rows])

  const types = useMemo(() => {
    return [...new Set(rows.map((r) => r.type))].sort()
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      if (statusFilter !== 'all' && r.status !== statusFilter) return false
      if (typeFilter !== 'all' && r.type !== typeFilter) return false
      if (channelFilter !== 'all' && r.channel !== channelFilter) return false
      if (!q) return true
      return (
        r.title.toLowerCase().includes(q) ||
        r.description.toLowerCase().includes(q) ||
        r.audience.toLowerCase().includes(q)
      )
    })
  }, [rows, search, statusFilter, typeFilter, channelFilter])

  const displayTotal = filtered.length
  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = filtered.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)

  const setStatus = async (row: NotifRow, status: NotifStatus) => {
    setMenuId(null)
    try {
      await setBroadcastStatus(row.id, uiToBroadcastStatus(status))
      await reload()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    }
  }

  const retrySend = async (row: NotifRow) => {
    if (!user?.uid) {
      setError('Sign in required to send notifications.')
      return
    }
    setBusy(true)
    setError('')
    try {
      await sendBroadcast(row.id, user.uid)
      await reload()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  const openComposer = () => {
    setShowForm(true)
    setError('')
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (!user?.uid) {
      setError('Sign in required to send notifications.')
      return
    }
    const channels: string[] = []
    if (channelInApp) channels.push('inApp')
    if (channelPush) channels.push('push')
    if (!title.trim() || !body.trim()) {
      setError('Title and body are required.')
      return
    }
    if (!channels.length) {
      setError('Select at least one channel.')
      return
    }
    setBusy(true)
    setError('')
    try {
      const id = await createBroadcast(
        {
          title: title.trim(),
          body: body.trim(),
          type: 'general',
          audience,
          channels,
        },
        user.uid,
      )
      await sendBroadcast(id, user.uid)
      setTitle('')
      setBody('')
      setAudience('all')
      setChannelInApp(true)
      setChannelPush(false)
      setShowForm(false)
      await reload()
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setBusy(false)
    }
  }

  const feedTab =
    typeFilter === 'all'
      ? 'all'
      : typeFilter.toLowerCase().includes('book')
        ? 'bookings'
        : typeFilter.toLowerCase().includes('message')
          ? 'messages'
          : typeFilter.toLowerCase().includes('appoint')
            ? 'appointments'
            : typeFilter.toLowerCase().includes('system') || typeFilter.toLowerCase().includes('update')
              ? 'system'
              : typeFilter.toLowerCase().includes('promo') || typeFilter.toLowerCase().includes('offer')
                ? 'offers'
                : 'all'

  const setFeedTab = (id: string) => {
    setPage(1)
    if (id === 'all') setTypeFilter('all')
    else if (id === 'bookings') setTypeFilter(types.find((t) => t.toLowerCase().includes('book')) ?? 'Booking')
    else if (id === 'messages') setTypeFilter(types.find((t) => t.toLowerCase().includes('message')) ?? 'Message')
    else if (id === 'appointments') setTypeFilter(types.find((t) => t.toLowerCase().includes('appoint')) ?? 'Appointment')
    else if (id === 'system') setTypeFilter(types.find((t) => t.toLowerCase().includes('update') || t.toLowerCase().includes('system')) ?? 'Update')
    else if (id === 'offers') setTypeFilter(types.find((t) => t.toLowerCase().includes('promo') || t.toLowerCase().includes('offer')) ?? 'Promotion')
  }

  const unreadCount = rows.filter((r) => r.status === 'pending' || r.status === 'scheduled').length || Math.min(5, rows.length)

  return (
    <div className="al-page">
      <PageHeader
        title="Notifications"
        subtitle="Stay updated with your activities, bookings, messages and important updates."
        primaryAction={{ label: 'New Notification', onClick: openComposer }}
        secondaryAction={
          <button type="button" className="al-btn al-btn--outline" onClick={openComposer} disabled={busy}>
            <IconSend width={15} height={15} /> Send
          </button>
        }
      />

      <DemoBanner active={fetchFailed} reason="Firestore fetch failed — showing empty list" />
      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      {showForm ? (
        <form className="al-table-card" onSubmit={(e) => void onSubmit(e)} style={{ padding: 16, marginBottom: 16 }}>
          <h2 style={{ marginTop: 0, fontSize: 16 }}>Send notification</h2>
          <div style={{ display: 'grid', gap: 10, maxWidth: 560 }}>
            <label className="field">
              Title
              <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Notification title" disabled={busy} />
            </label>
            <label className="field">
              Body
              <textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Message body" rows={3} disabled={busy} />
            </label>
            <label className="field">
              Audience
              <select value={audience} onChange={(e) => setAudience(e.target.value as 'all' | 'active')} disabled={busy}>
                <option value="all">All Users</option>
                <option value="active">Active Users</option>
              </select>
            </label>
            <div style={{ display: 'flex', gap: 16 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
                <input type="checkbox" checked={channelInApp} onChange={(e) => setChannelInApp(e.target.checked)} disabled={busy} />
                In-App
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
                <input type="checkbox" checked={channelPush} onChange={(e) => setChannelPush(e.target.checked)} disabled={busy} />
                Push
              </label>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="submit" className="al-btn al-btn--primary" disabled={busy}>
                <IconSend width={15} height={15} /> {busy ? 'Sending…' : 'Create & Send'}
              </button>
              <button type="button" className="al-btn al-btn--ghost" disabled={busy} onClick={() => setShowForm(false)}>
                Cancel
              </button>
            </div>
          </div>
        </form>
      ) : null}

      <div className="al-split">
        <div>
          <div className="al-tabs-row" style={{ marginBottom: 14 }}>
            <div className="al-tabs" role="tablist" style={{ flexWrap: 'wrap', gap: 6, borderBottom: 0 }}>
              {[
                { id: 'all', label: 'All', badge: unreadCount },
                { id: 'bookings', label: 'Bookings' },
                { id: 'messages', label: 'Messages' },
                { id: 'appointments', label: 'Appointments' },
                { id: 'system', label: 'System Updates' },
                { id: 'offers', label: 'Offers & Programs' },
              ].map((t) => (
                <button
                  key={t.id}
                  type="button"
                  role="tab"
                  className={`al-tab${feedTab === t.id ? ' active' : ''}`}
                  style={{
                    borderRadius: 999,
                    border: feedTab === t.id ? '1px solid #bfdbfe' : '1px solid var(--border)',
                    background: feedTab === t.id ? '#eff6ff' : '#fff',
                    borderBottom: undefined,
                    padding: '8px 14px',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                  onClick={() => setFeedTab(t.id)}
                >
                  {t.label}
                  {'badge' in t && t.badge ? (
                    <span className="badge" style={{ position: 'static' }}>{t.badge > 99 ? '99+' : t.badge}</span>
                  ) : null}
                </button>
              ))}
            </div>
            <button
              type="button"
              className="al-tabs-action"
              onClick={() => {
                pageRows.forEach((r) => {
                  if (r.status === 'pending' || r.status === 'scheduled') void setStatus(r, 'delivered')
                })
              }}
            >
              <IconCheckCircle width={14} height={14} /> Mark All as Read
            </button>
          </div>

          <div className="al-filter-bar" style={{ marginBottom: 12 }}>
            <div className="al-filter-search">
              <IconSearch width={15} height={15} />
              <input
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value)
                  setPage(1)
                }}
                placeholder="Search notifications, bookings, messages..."
              />
            </div>
            <div className="al-filter-fields">
              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value)
                  setPage(1)
                }}
              >
                <option value="all">All Status</option>
                <option value="delivered">Delivered</option>
                <option value="scheduled">Scheduled</option>
                <option value="pending">Pending</option>
                <option value="failed">Failed</option>
              </select>
              <select
                value={channelFilter}
                onChange={(e) => {
                  setChannelFilter(e.target.value)
                  setPage(1)
                }}
              >
                <option value="all">All Channels</option>
                {channels.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
            <button type="button" className="al-btn al-btn--ghost" onClick={() => void reload()}>
              <IconRefresh width={14} height={14} /> Refresh
            </button>
          </div>

          <div className="al-table-card">
            {pageRows.length === 0 ? (
              <p className="muted" style={{ padding: 20 }}>
                {rows.length === 0
                  ? 'No notifications yet. Create one to get started.'
                  : 'No notifications match your filters.'}
              </p>
            ) : (
              <div>
                {pageRows.map((r, idx) => {
                  const unread = r.status === 'pending' || r.status === 'scheduled' || idx < 5
                  return (
                    <div
                      key={r.id}
                      className="al-activity-item"
                      style={{ padding: '14px 16px', cursor: 'pointer' }}
                      onClick={() => setMenuId((id) => (id === r.id ? null : r.id))}
                    >
                      <span className={`al-activity-icon al-activity-icon--${r.tone === 'red' ? 'red' : r.tone === 'amber' ? 'orange' : r.tone === 'purple' ? 'purple' : r.tone === 'green' ? 'green' : 'blue'}`}>
                        {iconNode(r.icon)}
                      </span>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <strong style={{ display: 'block', fontSize: 13.5 }}>{r.title}</strong>
                        <span className="muted" style={{ fontSize: 12.5 }}>
                          {r.description || `${r.type} · ${r.channel} · ${r.audience}`}
                        </span>
                      </div>
                      <div style={{ textAlign: 'right', flexShrink: 0 }}>
                        <span className="muted" style={{ fontSize: 11.5, display: 'block' }}>{r.when}</span>
                        {unread ? (
                          <span
                            style={{
                              display: 'inline-block',
                              width: 8,
                              height: 8,
                              borderRadius: '50%',
                              background: '#2563eb',
                              marginTop: 6,
                            }}
                          />
                        ) : null}
                      </div>
                      {menuId === r.id ? (
                        <div style={{ position: 'absolute', right: 16, marginTop: 40, background: '#fff', border: '1px solid var(--border)', borderRadius: 8, boxShadow: 'var(--shadow-md)', zIndex: 5, padding: 6 }}>
                          <button type="button" className="al-btn al-btn--ghost" onClick={() => void setStatus(r, 'delivered')}>Mark Delivered</button>
                          <button type="button" className="al-btn al-btn--ghost" onClick={() => void setStatus(r, 'scheduled')}>Mark Scheduled</button>
                          {r.status === 'failed' ? (
                            <button type="button" className="al-btn al-btn--ghost" disabled={busy} onClick={() => void retrySend(r)}>Retry Send</button>
                          ) : null}
                        </div>
                      ) : null}
                    </div>
                  )
                })}
              </div>
            )}
            <div className="al-footer" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px' }}>
              <span className="muted" style={{ fontSize: 12 }}>
                Showing {from}–{to} of {displayTotal.toLocaleString()} · Sent {stats.sent} · Failed {stats.failed}
              </span>
              <div className="al-pages">
                <button type="button" disabled={safePage <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))}>‹</button>
                <button type="button" className="active">{safePage}</button>
                <button type="button" disabled={safePage >= pageCount} onClick={() => setPage((p) => Math.min(pageCount, p + 1))}>›</button>
              </div>
            </div>
          </div>
        </div>

        <div className="al-widgets">
          <Widget title="Notification Preferences">
            <div className="al-widget-list">
              {[
                'Bookings & Appointments',
                'Messages',
                'System Updates',
                'Offers & Programs',
                'Jobs & Education',
                'Payments',
              ].map((label) => (
                <div key={label} className="al-widget-item" style={{ justifyContent: 'space-between' }}>
                  <strong style={{ fontWeight: 600 }}>{label}</strong>
                  <span
                    role="switch"
                    aria-checked="true"
                    style={{
                      width: 40,
                      height: 22,
                      borderRadius: 999,
                      background: '#2563eb',
                      position: 'relative',
                      display: 'inline-block',
                    }}
                  >
                    <span
                      style={{
                        position: 'absolute',
                        top: 2,
                        right: 2,
                        width: 18,
                        height: 18,
                        borderRadius: '50%',
                        background: '#fff',
                      }}
                    />
                  </span>
                </div>
              ))}
            </div>
          </Widget>

          <Widget
            title="Filters"
            action={
              <button
                type="button"
                className="al-btn al-btn--ghost"
                onClick={() => {
                  setSearch('')
                  setStatusFilter('all')
                  setTypeFilter('all')
                  setChannelFilter('all')
                  setPage(1)
                }}
              >
                Clear All
              </button>
            }
          >
            <div className="al-widget-list">
              {['All Notifications', 'Unread Only', 'Bookings', 'Messages', 'Jobs', 'Payments'].map((f, i) => (
                <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
                  <input
                    type="checkbox"
                    defaultChecked={i === 0}
                    onChange={() => {
                      if (f === 'Unread Only') setStatusFilter('pending')
                      else if (f === 'All Notifications') {
                        setStatusFilter('all')
                        setTypeFilter('all')
                      }
                    }}
                  />
                  {f}
                </label>
              ))}
            </div>
          </Widget>

          <div className="al-help-card" style={{ background: '#eff6ff' }}>
            <span className="al-kpi-icon" style={{ background: '#2563eb', color: '#fff', margin: '0 auto' }}>?</span>
            <strong>Need Help?</strong>
            <p>Manage your notification settings or contact support for assistance.</p>
            <a className="al-btn al-btn--outline" href="/support">Contact Support →</a>
          </div>
        </div>
      </div>
    </div>
  )
}
