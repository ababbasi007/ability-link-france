import { useEffect, useMemo, useState } from 'react'
import {
  fetchCommunityEvents,
  fetchCommunityGroups,
  fetchCommunityPosts,
  setCommunityEventFeatured,
  setCommunityGroupFeatured,
  setCommunityPostStatus,
  upsertCommunityEvent,
  upsertCommunityGroup,
} from '../lib/data'
import {
  FilterBar,
  KpiRow,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'
import {
  IconCalendar,
  IconFlag,
  IconHeart,
  IconMessage,
  IconMore,
  IconPlus,
  IconStar,
  IconTrain,
  IconUsers,
  IconWheelchair,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'posts', label: 'Posts' },
  { id: 'groups', label: 'Groups' },
  { id: 'members', label: 'Members' },
  { id: 'reports', label: 'Reports' },
  { id: 'moderation', label: 'Moderation' },
  { id: 'events', label: 'Events' },
  { id: 'resources', label: 'Resources' },
  { id: 'settings', label: 'Settings' },
]

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
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  })
}

function formatDay(value: unknown): { mon: string; day: string } {
  const d = asDate(value) ?? new Date()
  return {
    mon: d.toLocaleString('en-US', { month: 'short' }).toUpperCase(),
    day: String(d.getDate()),
  }
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'muted' {
  switch (status) {
    case 'published':
      return 'ok'
    case 'flagged':
    case 'hidden':
    case 'pending':
      return 'warn'
    case 'removed':
      return 'danger'
    default:
      return 'muted'
  }
}

function snippet(text: string, max = 72) {
  const t = text.trim()
  if (!t) return '—'
  return t.length > max ? `${t.slice(0, max)}…` : t
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

const GROUP_ICONS = [
  <IconWheelchair key="w" width={22} height={22} />,
  <IconHeart key="h" width={22} height={22} />,
  <IconTrain key="t" width={22} height={22} />,
  <IconUsers key="u" width={22} height={22} />,
]

export function CommunityOpsPage() {
  const [tab, setTab] = useState('overview')
  const [posts, setPosts] = useState<Doc[]>([])
  const [groups, setGroups] = useState<Doc[]>([])
  const [events, setEvents] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [groupForm, setGroupForm] = useState({ name: '', description: '', topic: '' })
  const [eventForm, setEventForm] = useState({
    title: '',
    description: '',
    location: '',
    startAt: '',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [p, g, e] = await Promise.all([
        fetchCommunityPosts(100),
        fetchCommunityGroups(100),
        fetchCommunityEvents(100),
      ])
      setPosts(p)
      setGroups(g)
      setEvents(e)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load community data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredPosts = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return posts.filter((p) => {
      const status = String(p.status ?? 'published')
      if (statusFilter !== 'all' && status !== statusFilter) return false
      if (!needle) return true
      return (
        String(p.title ?? '').toLowerCase().includes(needle) ||
        String(p.body ?? p.content ?? '').toLowerCase().includes(needle) ||
        String(p.uid ?? p.authorUid ?? '').toLowerCase().includes(needle) ||
        status.toLowerCase().includes(needle)
      )
    })
  }, [posts, q, statusFilter])

  const filteredGroups = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return groups.filter((g) => {
      if (!needle) return true
      return (
        String(g.name ?? '').toLowerCase().includes(needle) ||
        String(g.topic ?? '').toLowerCase().includes(needle) ||
        String(g.description ?? '').toLowerCase().includes(needle)
      )
    })
  }, [groups, q])

  const filteredEvents = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return events.filter((e) => {
      if (!needle) return true
      return (
        String(e.title ?? '').toLowerCase().includes(needle) ||
        String(e.location ?? '').toLowerCase().includes(needle) ||
        String(e.description ?? '').toLowerCase().includes(needle)
      )
    })
  }, [events, q])

  const setPostStatus = async (id: string, status: 'published' | 'hidden' | 'removed') => {
    setBusyId(id)
    try {
      await setCommunityPostStatus(id, status)
      setPosts((prev) => prev.map((p) => (p.id === id ? { ...p, status } : p)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const toggleGroupFeatured = async (id: string, featured: boolean) => {
    setBusyId(id)
    try {
      await setCommunityGroupFeatured(id, featured)
      setGroups((prev) =>
        prev.map((g) => (g.id === id ? { ...g, featured, official: featured } : g)),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const toggleEventFeatured = async (id: string, featured: boolean) => {
    setBusyId(id)
    try {
      await setCommunityEventFeatured(id, featured)
      setEvents((prev) =>
        prev.map((e) => (e.id === id ? { ...e, featured, official: featured } : e)),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveGroup = async () => {
    if (!groupForm.name.trim()) {
      setError('Group name is required')
      return
    }
    try {
      await upsertCommunityGroup(null, {
        name: groupForm.name.trim(),
        description: groupForm.description.trim(),
        topic: groupForm.topic.trim() || 'general',
        featured: true,
        official: true,
      })
      setGroupForm({ name: '', description: '', topic: '' })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not create group')
    }
  }

  const saveEvent = async () => {
    if (!eventForm.title.trim() || !eventForm.startAt.trim()) {
      setError('Event title and startAt (ISO) are required')
      return
    }
    try {
      await upsertCommunityEvent(null, {
        title: eventForm.title.trim(),
        description: eventForm.description.trim(),
        location: eventForm.location.trim(),
        startAt: eventForm.startAt.trim(),
        featured: true,
        official: true,
      })
      setEventForm({ title: '', description: '', location: '', startAt: '' })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not create event')
    }
  }

  const pending = posts.filter((p) => {
    const s = String(p.status ?? '')
    return s === 'pending' || s === 'flagged' || s === 'hidden'
  }).length

  return (
    <div className="al-page">
      <div className="muted" style={{ fontSize: 12, marginBottom: 6 }}>
        Dashboard › Community
      </div>
      <PageHeader
        title="Community Management"
        subtitle="Manage discussions, groups, posts and community members. Keep the community safe, supportive and inclusive."
        primaryAction={{ label: 'New Post', onClick: () => setTab('posts') }}
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <KpiRow
        cols={4}
        items={[
          {
            label: 'Total Members',
            value: Math.max(posts.length * 12, groups.length * 40 || 8642).toLocaleString(),
            trend: '12% vs last month',
            tone: 'blue',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Total Posts',
            value: posts.length.toLocaleString(),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconMessage width={18} height={18} />,
          },
          {
            label: 'Active Groups',
            value: groups.length.toLocaleString(),
            trend: '27% vs last month',
            tone: 'purple',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Upcoming Events',
            value: events.length.toLocaleString(),
            trend: '33% vs last month',
            tone: 'pink',
            icon: <IconCalendar width={18} height={18} />,
          },
        ]}
      />

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search posts, members, or groups..."
        onReset={() => {
          setQ('')
          setTypeFilter('all')
          setStatusFilter('all')
        }}
      >
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
          <option value="all">All Types</option>
          <option value="discussion">Discussion</option>
          <option value="question">Question</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="published">Published</option>
          <option value="pending">Pending</option>
          <option value="flagged">Flagged</option>
          <option value="hidden">Hidden</option>
        </select>
        <select defaultValue="newest">
          <option value="newest">Newest First</option>
          <option value="oldest">Oldest First</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div>
          {(tab === 'overview' || tab === 'posts' || tab === 'moderation') && (
            <div className="al-table-card" style={{ marginBottom: 16 }}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '12px 14px',
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <strong>Recent Community Posts</strong>
                <button type="button" className="al-btn al-btn--ghost" onClick={() => setTab('posts')}>
                  View All Posts →
                </button>
              </div>
              {loading ? (
                <p className="muted" style={{ padding: 20 }}>
                  Loading…
                </p>
              ) : filteredPosts.length === 0 ? (
                <p className="muted" style={{ padding: 20 }}>
                  No posts found.
                </p>
              ) : (
                <div className="table-wrap">
                  <table className="al-table">
                    <thead>
                      <tr>
                        <th style={{ width: 36 }}>
                          <input type="checkbox" aria-label="Select all" />
                        </th>
                        <th>Post</th>
                        <th>Author</th>
                        <th>Category</th>
                        <th>Date</th>
                        <th>Status</th>
                        <th>Engagement</th>
                        <th />
                      </tr>
                    </thead>
                    <tbody>
                      {filteredPosts.slice(0, tab === 'overview' ? 6 : 40).map((p) => {
                        const status = String(p.status ?? 'published')
                        const author = String(p.authorName ?? p.uid ?? p.authorUid ?? 'Member')
                        const likes = Number(p.likeCount ?? p.likes ?? 0)
                        const comments = Number(p.commentCount ?? p.comments ?? 0)
                        return (
                          <tr key={p.id}>
                            <td>
                              <input type="checkbox" aria-label={`Select ${p.id}`} />
                            </td>
                            <td>
                              <strong style={{ display: 'block' }}>
                                {String(p.title ?? 'Untitled post')}
                              </strong>
                              <span className="muted" style={{ fontSize: 12 }}>
                                {snippet(String(p.body ?? p.content ?? ''))}
                              </span>
                            </td>
                            <td>
                              <div className="al-person">
                                <img src={avatarUrl(author)} alt="" />
                                <div>
                                  <strong>{author.slice(0, 18)}</strong>
                                </div>
                              </div>
                            </td>
                            <td>
                              <StatusPill tone="info">
                                {String(p.category ?? p.topic ?? 'General')}
                              </StatusPill>
                            </td>
                            <td>{formatWhen(p.createdAt ?? p.updatedAt)}</td>
                            <td>
                              <StatusPill tone={statusTone(status)}>{status}</StatusPill>
                            </td>
                            <td>
                              <span style={{ display: 'inline-flex', gap: 8, fontSize: 12 }}>
                                <span>♥ {likes}</span>
                                <span>💬 {comments}</span>
                              </span>
                            </td>
                            <td>
                              <div style={{ display: 'flex', gap: 4 }}>
                                {status !== 'published' ? (
                                  <button
                                    type="button"
                                    className="al-btn al-btn--primary"
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === p.id}
                                    onClick={() => void setPostStatus(p.id, 'published')}
                                  >
                                    Publish
                                  </button>
                                ) : (
                                  <button
                                    type="button"
                                    className="al-btn al-btn--outline"
                                    style={{ padding: '4px 8px', fontSize: 11 }}
                                    disabled={busyId === p.id}
                                    onClick={() => void setPostStatus(p.id, 'hidden')}
                                  >
                                    Hide
                                  </button>
                                )}
                                <button type="button" className="icon-btn" aria-label="More">
                                  <IconMore width={14} height={14} />
                                </button>
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
          )}

          {(tab === 'overview' || tab === 'groups') && (
            <div style={{ marginBottom: 16 }}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginBottom: 10,
                }}
              >
                <strong>Community Groups</strong>
                <button type="button" className="al-btn al-btn--ghost" onClick={() => setTab('groups')}>
                  View All →
                </button>
              </div>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))',
                  gap: 12,
                }}
              >
                {(filteredGroups.length ? filteredGroups : [{ id: 'demo', name: 'Mobility Support', description: 'Tips and peer support', memberCount: 420 }]).slice(0, 4).map((g, i) => (
                  <div key={g.id} className="al-table-card" style={{ padding: 14 }}>
                    <div
                      className="al-kpi-icon"
                      style={{
                        background: ['#dbeafe', '#fce7f3', '#dcfce7', '#ede9fe'][i % 4],
                        color: ['#2563eb', '#db2777', '#16a34a', '#7c3aed'][i % 4],
                        marginBottom: 10,
                      }}
                    >
                      {GROUP_ICONS[i % 4]}
                    </div>
                    <strong style={{ display: 'block', marginBottom: 4 }}>
                      {String(g.name ?? 'Group')}
                    </strong>
                    <span className="muted" style={{ fontSize: 12 }}>
                      {Number(g.memberCount ?? 0).toLocaleString()} members
                    </span>
                    <p className="muted" style={{ fontSize: 12, margin: '8px 0' }}>
                      {snippet(String(g.description ?? ''), 60)}
                    </p>
                    <button
                      type="button"
                      className="al-btn al-btn--ghost"
                      style={{ padding: 0 }}
                      disabled={busyId === g.id}
                      onClick={() => void toggleGroupFeatured(g.id, !g.featured)}
                    >
                      {g.featured ? 'Unfeature' : 'View Group'} →
                    </button>
                  </div>
                ))}
              </div>
              {tab === 'groups' ? (
                <div className="al-table-card" style={{ marginTop: 16, padding: 16 }}>
                  <h3 style={{ marginTop: 0 }}>Create group</h3>
                  <div style={{ display: 'grid', gap: 8 }}>
                    <input
                      placeholder="Name"
                      value={groupForm.name}
                      onChange={(e) => setGroupForm((s) => ({ ...s, name: e.target.value }))}
                    />
                    <input
                      placeholder="Topic"
                      value={groupForm.topic}
                      onChange={(e) => setGroupForm((s) => ({ ...s, topic: e.target.value }))}
                    />
                    <input
                      placeholder="Description"
                      value={groupForm.description}
                      onChange={(e) =>
                        setGroupForm((s) => ({ ...s, description: e.target.value }))
                      }
                    />
                    <button type="button" className="al-btn al-btn--primary" onClick={() => void saveGroup()}>
                      <IconPlus width={14} height={14} /> Create group
                    </button>
                  </div>
                </div>
              ) : null}
            </div>
          )}

          {(tab === 'overview' || tab === 'events') && (
            <div>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginBottom: 10,
                }}
              >
                <strong>Upcoming Community Events</strong>
              </div>
              <div style={{ display: 'grid', gap: 10 }}>
                {filteredEvents.slice(0, 3).map((e) => {
                  const { mon, day } = formatDay(e.startAt ?? e.createdAt)
                  return (
                    <div
                      key={e.id}
                      className="al-table-card"
                      style={{
                        padding: 12,
                        display: 'flex',
                        gap: 12,
                        alignItems: 'center',
                      }}
                    >
                      <div
                        style={{
                          width: 52,
                          borderRadius: 8,
                          background: '#eff6ff',
                          textAlign: 'center',
                          padding: '8px 0',
                        }}
                      >
                        <div style={{ fontSize: 10, fontWeight: 700, color: '#2563eb' }}>{mon}</div>
                        <div style={{ fontSize: 18, fontWeight: 800 }}>{day}</div>
                      </div>
                      <div style={{ flex: 1 }}>
                        <strong>{String(e.title ?? 'Event')}</strong>
                        <div className="muted" style={{ fontSize: 12 }}>
                          {String(e.location ?? 'Online')} · {formatWhen(e.startAt)}
                        </div>
                      </div>
                      <button
                        type="button"
                        className="al-btn al-btn--outline"
                        disabled={busyId === e.id}
                        onClick={() => void toggleEventFeatured(e.id, !e.featured)}
                      >
                        {e.featured ? 'Unfeature' : 'Feature'}
                      </button>
                    </div>
                  )
                })}
                {filteredEvents.length === 0 ? (
                  <p className="muted">No upcoming events.</p>
                ) : null}
              </div>
              {tab === 'events' ? (
                <div className="al-table-card" style={{ marginTop: 16, padding: 16 }}>
                  <h3 style={{ marginTop: 0 }}>Create event</h3>
                  <div style={{ display: 'grid', gap: 8 }}>
                    <input
                      placeholder="Title"
                      value={eventForm.title}
                      onChange={(e) => setEventForm((s) => ({ ...s, title: e.target.value }))}
                    />
                    <input
                      placeholder="Location"
                      value={eventForm.location}
                      onChange={(e) => setEventForm((s) => ({ ...s, location: e.target.value }))}
                    />
                    <input
                      placeholder="Start (ISO datetime)"
                      value={eventForm.startAt}
                      onChange={(e) => setEventForm((s) => ({ ...s, startAt: e.target.value }))}
                    />
                    <input
                      placeholder="Description"
                      value={eventForm.description}
                      onChange={(e) =>
                        setEventForm((s) => ({ ...s, description: e.target.value }))
                      }
                    />
                    <button type="button" className="al-btn al-btn--primary" onClick={() => void saveEvent()}>
                      <IconPlus width={14} height={14} /> Create event
                    </button>
                  </div>
                </div>
              ) : null}
            </div>
          )}
        </div>

        <div className="al-widgets">
          <Widget title="Quick Actions">
            <div className="al-widget-list">
              {[
                { label: 'Create New Post', tab: 'posts', primary: true },
                { label: 'Create Group', tab: 'groups' },
                { label: 'Schedule Event', tab: 'events' },
                { label: 'Manage Categories', tab: 'settings' },
                { label: 'Community Guidelines', tab: 'resources' },
                { label: 'Moderation Tools', tab: 'moderation' },
                { label: 'Send Announcement', tab: 'posts' },
              ].map((a) => (
                <button
                  key={a.label}
                  type="button"
                  className={`al-btn ${a.primary ? 'al-btn--primary' : 'al-btn--outline'}`}
                  style={{ width: '100%', justifyContent: 'flex-start' }}
                  onClick={() => setTab(a.tab)}
                >
                  {a.label}
                </button>
              ))}
            </div>
          </Widget>

          <Widget
            title="Recent Reports"
            action={
              <button type="button" className="al-btn al-btn--ghost" onClick={() => setTab('reports')}>
                View All
              </button>
            }
          >
            <div className="al-widget-list">
              {[
                { title: 'Inappropriate content', ago: '14 min ago', tone: 'red' as const },
                { title: 'Spam post', ago: '1 hour ago', tone: 'orange' as const },
                { title: 'Harassment report', ago: '3 hours ago', tone: 'red' as const },
              ].map((r) => (
                <div key={r.title} className="al-widget-item">
                  <span className={`al-activity-icon al-activity-icon--${r.tone === 'red' ? 'red' : 'orange'}`}>
                    <IconFlag width={14} height={14} />
                  </span>
                  <div>
                    <strong>{r.title}</strong>
                    <span>{r.ago}</span>
                  </div>
                </div>
              ))}
              {pending > 0 ? (
                <p className="muted" style={{ fontSize: 12, margin: 0 }}>
                  {pending} posts need moderation
                </p>
              ) : null}
            </div>
          </Widget>

          <Widget title="Top Members">
            <div className="al-widget-list">
              {['Sara Khan', 'Ahmed Raza', 'Fatima Ali'].map((name, i) => (
                <div key={name} className="al-widget-item">
                  <strong style={{ width: 18 }}>{i + 1}</strong>
                  <img
                    src={avatarUrl(name)}
                    alt=""
                    style={{ width: 32, height: 32, borderRadius: '50%' }}
                  />
                  <div style={{ flex: 1 }}>
                    <strong>{name}</strong>
                    <span>{(1200 - i * 180).toLocaleString()} pts</span>
                  </div>
                  <IconStar width={14} height={14} style={{ color: '#f59e0b' }} />
                </div>
              ))}
            </div>
          </Widget>

          <Widget title="Community Growth">
            <div className="al-mini-bars" style={{ height: 72 }}>
              {[40, 55, 48, 62, 70, 68, 80, 75, 88].map((h, i) => (
                <span key={i} style={{ height: `${h}%` }} />
              ))}
            </div>
            <p style={{ margin: '10px 0 0', fontSize: 12, color: '#16a34a', fontWeight: 700 }}>
              +12% New members this month
            </p>
          </Widget>
        </div>
      </div>
    </div>
  )
}
