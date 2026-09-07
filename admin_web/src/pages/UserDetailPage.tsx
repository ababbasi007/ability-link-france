import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import {
  fetchUser,
  fetchUserActivityLogs,
  fetchUserAppointments,
  fetchUserReports,
  fetchUserReviews,
  requestUserPasswordReset,
  setUserStatus,
} from '../lib/data'
import {
  IconChevronLeft,
  IconRefresh,
  IconShieldCheck,
  IconX,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }
type TabKey =
  | 'profile'
  | 'accessibility'
  | 'bookings'
  | 'reviews'
  | 'reports'
  | 'activity'

const TABS: { key: TabKey; label: string }[] = [
  { key: 'profile', label: 'Profile' },
  { key: 'accessibility', label: 'Accessibility Profile' },
  { key: 'bookings', label: 'Bookings' },
  { key: 'reviews', label: 'Reviews' },
  { key: 'reports', label: 'Reports' },
  { key: 'activity', label: 'Activity Log' },
]

function formatDate(value: unknown): string {
  if (!value) return '—'
  if (typeof value === 'string') {
    const d = new Date(value)
    if (!Number.isNaN(d.getTime())) {
      return d.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
      })
    }
    return value
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    const d = (value as { toDate: () => Date }).toDate()
    return d.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    })
  }
  if (typeof value === 'object' && value !== null && 'seconds' in value) {
    const d = new Date((value as { seconds: number }).seconds * 1000)
    return d.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    })
  }
  return '—'
}

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

function dumpValue(value: unknown): string {
  if (value == null || value === '') return '—'
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value)
  }
  if (Array.isArray(value)) {
    if (!value.length) return '—'
    return value
      .map((v) => (typeof v === 'object' ? JSON.stringify(v) : String(v)))
      .join(', ')
  }
  try {
    return JSON.stringify(value, null, 2)
  } catch {
    return String(value)
  }
}

function verificationPill(raw: Doc) {
  const v = String(
    raw.verificationStatus ?? raw.verification ?? raw.kycStatus ?? '',
  ).toLowerCase()
  const verified =
    (v.includes('verif') && !v.includes('not')) ||
    raw.emailVerified === true ||
    raw.isVerified === true
  const inReview = v.includes('review') || v.includes('pending')
  if (verified) {
    return (
      <span className="us-verify verified">
        <IconShieldCheck width={13} height={13} />
        Verified
      </span>
    )
  }
  if (inReview) {
    return (
      <span className="us-verify review">
        In Review
      </span>
    )
  }
  return (
    <span className="us-verify not">
      <IconX width={13} height={13} />
      Not Verified
    </span>
  )
}

function statusPill(status: string) {
  const s = status.toLowerCase()
  const cls =
    s.includes('block') || s.includes('suspend')
      ? 'blocked'
      : s.includes('pending')
        ? 'pending'
        : s.includes('inactive')
          ? 'inactive'
          : 'active'
  const label =
    cls === 'blocked'
      ? 'Blocked'
      : cls === 'pending'
        ? 'Pending'
        : cls === 'inactive'
          ? 'Inactive'
          : 'Active'
  return <span className={`us-pill ${cls}`}>{label}</span>
}

export function UserDetailPage() {
  const { id = '' } = useParams<{ id: string }>()
  const [tab, setTab] = useState<TabKey>('profile')
  const [user, setUser] = useState<Doc | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [statusDraft, setStatusDraft] = useState('active')
  const [appointments, setAppointments] = useState<Doc[]>([])
  const [reviews, setReviews] = useState<Doc[]>([])
  const [reports, setReports] = useState<Doc[]>([])
  const [activity, setActivity] = useState<Doc[]>([])
  const [tabLoading, setTabLoading] = useState(false)

  const loadUser = async () => {
    if (!id) {
      setError('Missing user id')
      setLoading(false)
      return
    }
    setLoading(true)
    setError('')
    try {
      const doc = await fetchUser(id)
      if (!doc) {
        setUser(null)
        setError('User not found')
      } else {
        setUser(doc)
        setStatusDraft(String(doc.accountStatus ?? doc.status ?? 'active'))
      }
    } catch (e) {
      setUser(null)
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadUser()
  }, [id])

  useEffect(() => {
    if (!id || tab === 'profile' || tab === 'accessibility') return
    let cancelled = false
    const run = async () => {
      setTabLoading(true)
      try {
        if (tab === 'bookings') {
          const rows = await fetchUserAppointments(id)
          if (!cancelled) setAppointments(rows)
        } else if (tab === 'reviews') {
          const rows = await fetchUserReviews(id)
          if (!cancelled) setReviews(rows)
        } else if (tab === 'reports') {
          const rows = await fetchUserReports(id)
          if (!cancelled) setReports(rows)
        } else if (tab === 'activity') {
          const rows = await fetchUserActivityLogs(id)
          if (!cancelled) setActivity(rows)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : String(e))
      } finally {
        if (!cancelled) setTabLoading(false)
      }
    }
    void run()
    return () => {
      cancelled = true
    }
  }, [id, tab])

  const profile = useMemo(() => {
    if (!user) return null
    const personal =
      user.personal && typeof user.personal === 'object'
        ? (user.personal as Record<string, unknown>)
        : {}
    const contact =
      user.contact && typeof user.contact === 'object'
        ? (user.contact as Record<string, unknown>)
        : {}
    const location =
      user.location && typeof user.location === 'object'
        ? (user.location as Record<string, unknown>)
        : {}
    const name =
      String(user.fullName ?? '').trim() ||
      `${personal.firstName ?? ''} ${personal.lastName ?? ''}`.trim() ||
      String(user.displayName ?? '').trim() ||
      user.id
    const email = String(user.email ?? contact.email ?? personal.email ?? '—')
    const phone = String(user.phone ?? contact.phone ?? personal.phone ?? '—')
    const role = String(user.platformRole ?? user.role ?? 'user')
    const city = String(location.city ?? user.city ?? personal.city ?? '—')
    const status = String(user.accountStatus ?? user.status ?? 'active')
    const photo = String(
      user.photoUrl ?? user.avatarUrl ?? personal.photoUrl ?? '',
    )
    return {
      name,
      email,
      phone,
      role,
      city,
      status,
      photo,
      joined: formatDate(user.createdAt ?? user.joinedAt ?? user.createdOn),
    }
  }, [user])

  const accessibilitySections = useMemo(() => {
    if (!user) return []
    const keys = [
      'accessibility',
      'personal',
      'contact',
      'healthcare',
      'preferences',
      'services',
      'passportId',
    ] as const
    return keys.map((key) => ({
      key,
      value: user[key],
    }))
  }, [user])

  const saveStatus = async () => {
    if (!id) return
    setBusy(true)
    setError('')
    try {
      await setUserStatus(id, statusDraft)
      await loadUser()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  const resetPassword = async () => {
    if (!id) return
    setBusy(true)
    setError('')
    try {
      await requestUserPasswordReset(id)
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
            <Link to="/users" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
              <IconChevronLeft width={14} height={14} /> Back to users
            </Link>
            <h1 className="page-title">User detail</h1>
          </div>
        </div>
        <div className="card">
          <p className="muted">Loading…</p>
        </div>
      </div>
    )
  }

  if (!user || !profile) {
    return (
      <div className="dash">
        <div className="page-head">
          <div>
            <Link to="/users" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
              <IconChevronLeft width={14} height={14} /> Back to users
            </Link>
            <h1 className="page-title">User detail</h1>
          </div>
        </div>
        <div className="card">
          {error ? <div className="error">{error}</div> : <p className="muted">User not found.</p>}
        </div>
      </div>
    )
  }

  return (
    <div className="dash">
      <div className="page-head">
        <div>
          <Link to="/users" className="muted" style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
            <IconChevronLeft width={14} height={14} /> Back to users
          </Link>
          <h1 className="page-title">{profile.name}</h1>
          <p className="muted">{profile.email}</p>
        </div>
        <button type="button" className="btn" onClick={() => void loadUser()}>
          <IconRefresh /> Refresh
        </button>
      </div>

      {error ? (
        <div className="card" style={{ borderColor: '#fecaca', marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

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
              {profile.photo ? (
                <img
                  src={profile.photo}
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
                  {profile.name.slice(0, 1).toUpperCase()}
                </div>
              )}
            </div>
            <div className="table-wrap">
              <table className="table">
                <tbody>
                  <tr>
                    <th style={{ width: 160 }}>Name</th>
                    <td>{profile.name}</td>
                  </tr>
                  <tr>
                    <th>Email</th>
                    <td>{profile.email}</td>
                  </tr>
                  <tr>
                    <th>Phone</th>
                    <td>{profile.phone}</td>
                  </tr>
                  <tr>
                    <th>Role</th>
                    <td>{profile.role}</td>
                  </tr>
                  <tr>
                    <th>City</th>
                    <td>{profile.city}</td>
                  </tr>
                  <tr>
                    <th>Status</th>
                    <td>{statusPill(profile.status)}</td>
                  </tr>
                  <tr>
                    <th>Verification</th>
                    <td>{verificationPill(user)}</td>
                  </tr>
                  <tr>
                    <th>Joined</th>
                    <td>{profile.joined}</td>
                  </tr>
                  <tr>
                    <th>User ID</th>
                    <td className="muted">{user.id}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div
            style={{
              marginTop: 18,
              display: 'flex',
              gap: 10,
              flexWrap: 'wrap',
              alignItems: 'center',
            }}
          >
            <label className="muted" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              Status
              <select
                value={statusDraft}
                onChange={(e) => setStatusDraft(e.target.value)}
                disabled={busy}
              >
                <option value="active">active</option>
                <option value="inactive">inactive</option>
                <option value="pending">pending</option>
                <option value="suspended">suspended</option>
              </select>
            </label>
            <button
              type="button"
              className="btn primary"
              disabled={busy}
              onClick={() => void saveStatus()}
            >
              Update status
            </button>
            <button
              type="button"
              className="btn"
              disabled={busy}
              onClick={() => void resetPassword()}
            >
              Send password reset
            </button>
          </div>
        </div>
      ) : null}

      {tab === 'accessibility' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Accessibility profile</h3>
          <p className="muted" style={{ marginTop: 0 }}>
            Fields from the user document used by the accessibility passport.
          </p>
          {accessibilitySections.map((section) => (
            <div key={section.key} style={{ marginBottom: 16 }}>
              <h4 style={{ margin: '0 0 6px' }}>{section.key}</h4>
              <pre
                style={{
                  margin: 0,
                  padding: 12,
                  background: '#f9fafb',
                  borderRadius: 8,
                  overflow: 'auto',
                  fontSize: 13,
                  whiteSpace: 'pre-wrap',
                }}
              >
                {dumpValue(section.value)}
              </pre>
            </div>
          ))}
        </div>
      ) : null}

      {tab === 'bookings' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Bookings</h3>
          {tabLoading ? (
            <p className="muted">Loading…</p>
          ) : appointments.length === 0 ? (
            <p className="muted">No bookings found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Status</th>
                    <th>Provider</th>
                    <th>When</th>
                  </tr>
                </thead>
                <tbody>
                  {appointments.map((r) => (
                    <tr key={r.id}>
                      <td className="muted">{r.id}</td>
                      <td>{String(r.status ?? '—')}</td>
                      <td>{String(r.providerName ?? r.providerUid ?? '—')}</td>
                      <td>{formatWhen(r.scheduledAt ?? r.startAt ?? r.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'reviews' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Reviews</h3>
          {tabLoading ? (
            <p className="muted">Loading…</p>
          ) : reviews.length === 0 ? (
            <p className="muted">No reviews found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Rating</th>
                    <th>Target</th>
                    <th>Comment</th>
                    <th>When</th>
                  </tr>
                </thead>
                <tbody>
                  {reviews.map((r) => (
                    <tr key={r.id}>
                      <td className="muted">{r.id}</td>
                      <td>{String(r.rating ?? r.stars ?? '—')}</td>
                      <td>{String(r.placeName ?? r.providerName ?? r.targetId ?? '—')}</td>
                      <td>{String(r.comment ?? r.text ?? r.body ?? '—')}</td>
                      <td>{formatWhen(r.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'reports' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Reports</h3>
          {tabLoading ? (
            <p className="muted">Loading…</p>
          ) : reports.length === 0 ? (
            <p className="muted">No reports found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Status</th>
                    <th>Type</th>
                    <th>Reason</th>
                    <th>When</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((r) => (
                    <tr key={r.id}>
                      <td className="muted">{r.id}</td>
                      <td>{String(r.status ?? '—')}</td>
                      <td>{String(r.type ?? r.kind ?? '—')}</td>
                      <td>{String(r.reason ?? r.message ?? r.details ?? '—')}</td>
                      <td>{formatWhen(r.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {tab === 'activity' ? (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Activity log</h3>
          {tabLoading ? (
            <p className="muted">Loading…</p>
          ) : activity.length === 0 ? (
            <p className="muted">No activity found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>When</th>
                    <th>Level</th>
                    <th>Module</th>
                    <th>Event</th>
                    <th>Details</th>
                  </tr>
                </thead>
                <tbody>
                  {activity.map((r) => (
                    <tr key={r.id}>
                      <td>{formatWhen(r.createdAt)}</td>
                      <td>{String(r.level ?? '—')}</td>
                      <td>{String(r.module ?? '—')}</td>
                      <td>{String(r.event ?? '—')}</td>
                      <td className="muted">{String(r.details ?? '—')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}
    </div>
  )
}
