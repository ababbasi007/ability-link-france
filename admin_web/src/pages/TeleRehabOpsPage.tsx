import { useEffect, useMemo, useState } from 'react'
import {
  fetchRehabCareAccess,
  fetchSessionChats,
  setRehabCareAccessStatus,
} from '../lib/data'
import { cell, formatWhen, type OpsDoc } from '../lib/opsUtils'
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
  IconCheckCircle,
  IconFileText,
  IconHeart,
  IconLayers,
  IconMore,
  IconUser,
  IconUsers,
} from '../components/icons'

const TABS = [
  { id: 'access', label: 'Sessions' },
  { id: 'chats', label: 'Patients' },
  { id: 'therapists', label: 'Therapists' },
  { id: 'programs', label: 'Programs' },
  { id: 'exercises', label: 'Exercise Library' },
  { id: 'assessments', label: 'Assessments' },
  { id: 'progress', label: 'Progress' },
  { id: 'reports', label: 'Reports' },
]

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'info' | 'muted' | 'purple' {
  const s = status.toLowerCase()
  if (s.includes('active') || s.includes('granted') || s.includes('complet')) return 'ok'
  if (s.includes('pending') || s.includes('schedul')) return 'info'
  if (s.includes('ongoing')) return 'info'
  if (s.includes('upcoming')) return 'purple'
  if (s.includes('cancel') || s.includes('revok')) return 'danger'
  return 'muted'
}

export function TeleRehabOpsPage() {
  const [tab, setTab] = useState('access')
  const [access, setAccess] = useState<OpsDoc[]>([])
  const [chats, setChats] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [sessionType, setSessionType] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [therapist, setTherapist] = useState('all')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [a, c] = await Promise.all([fetchRehabCareAccess(200), fetchSessionChats(100)])
      setAccess(a)
      setChats(c)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load tele-rehab ops data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const dataTab = tab === 'chats' ? 'chats' : 'access'
  const rows = useMemo(() => {
    const list = dataTab === 'access' ? access : chats
    const needle = q.trim().toLowerCase()
    return list.filter((r) => {
      const status = String(r.status ?? '')
      if (statusFilter !== 'all' && status.toLowerCase() !== statusFilter) return false
      if (!needle) return true
      return JSON.stringify(r).toLowerCase().includes(needle)
    })
  }, [dataTab, access, chats, q, statusFilter])

  const upcoming = access[0] ?? null

  return (
    <div className="al-page">
      <PageHeader
        title="Tele Rehab"
        subtitle="Manage online rehabilitation sessions, therapists, programs and patient progress."
        primaryAction={{ label: 'New Session', onClick: () => void load() }}
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <KpiRow
        items={[
          {
            label: 'Total Sessions',
            value: access.length.toLocaleString(),
            trend: '24% vs last month',
            tone: 'blue',
            icon: <IconCalendar width={18} height={18} />,
          },
          {
            label: 'Active Patients',
            value: chats.length.toLocaleString(),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconUser width={18} height={18} />,
          },
          {
            label: 'Therapists',
            value: Math.max(1, new Set(access.map((r) => String(r.clinicianUid ?? ''))).size).toLocaleString(),
            trend: '12% vs last month',
            tone: 'orange',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Programs',
            value: Math.max(1, Math.round(access.length / 4)).toLocaleString(),
            trend: '9% vs last month',
            tone: 'purple',
            icon: <IconLayers width={18} height={18} />,
          },
          {
            label: 'Exercises',
            value: Math.max(1, access.length * 3).toLocaleString(),
            trend: '15% vs last month',
            tone: 'red',
            icon: <IconHeart width={18} height={18} />,
          },
        ]}
      />

      <div className="al-tabs-row">
        <TabBar tabs={TABS} active={tab} onChange={setTab} />
        <a className="al-tabs-action" href="/tele-rehab">
          <IconCalendar width={14} height={14} /> View Calendar
        </a>
      </div>

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search by patient, therapist or session ID..."
        onReset={() => {
          setQ('')
          setSessionType('all')
          setStatusFilter('all')
          setTherapist('all')
        }}
      >
        <select value={sessionType} onChange={(e) => setSessionType(e.target.value)}>
          <option value="all">All Types</option>
          <option value="video">Video Call</option>
          <option value="chat">Chat</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="granted">Granted</option>
          <option value="revoked">Revoked</option>
          <option value="pending">Pending</option>
        </select>
        <select value={therapist} onChange={(e) => setTherapist(e.target.value)}>
          <option value="all">All Therapists</option>
        </select>
        <span className="al-btn al-btn--outline" style={{ pointerEvents: 'none' }}>
          <IconCalendar width={14} height={14} /> 1 Sep 2025 - 30 Sep 2025
        </span>
      </FilterBar>

      <div className="al-split">
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>
              Loading…
            </p>
          ) : !['access', 'chats'].includes(tab) ? (
            <p className="muted" style={{ padding: 20 }}>
              {TABS.find((t) => t.id === tab)?.label} is managed in{' '}
              <a href="/tele-rehab">Rehab CMS</a>. Sessions and care-access data appear under
              Sessions / Patients.
            </p>
          ) : (
            <>
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      <th style={{ width: 36 }}>
                        <input type="checkbox" aria-label="Select all" />
                      </th>
                      {dataTab === 'access' ? (
                        <>
                          <th>Date & Time</th>
                          <th>Patient</th>
                          <th>Therapist</th>
                          <th>Program / Focus</th>
                          <th>Type</th>
                          <th>Status</th>
                        </>
                      ) : (
                        <>
                          <th>Thread</th>
                          <th>Participants</th>
                          <th>Appointment</th>
                          <th>Updated</th>
                        </>
                      )}
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row) => {
                      const status = String(row.status ?? 'scheduled')
                      const patient = String(row.patientUid ?? row.id)
                      const clinician = String(row.clinicianUid ?? 'Therapist')
                      return (
                        <tr key={row.id}>
                          <td>
                            <input type="checkbox" aria-label={`Select ${row.id}`} />
                          </td>
                          {dataTab === 'access' ? (
                            <>
                              <td>{formatWhen(row.updatedAt ?? row.createdAt)}</td>
                              <td>
                                <div className="al-person">
                                  <img src={avatarUrl(patient)} alt="" />
                                  <div>
                                    <strong>Patient {patient.slice(0, 6)}</strong>
                                    <span>ID: {patient.slice(0, 8)}</span>
                                  </div>
                                </div>
                              </td>
                              <td>
                                <div className="al-person">
                                  <img src={avatarUrl(clinician)} alt="" />
                                  <div>
                                    <strong>Dr. {clinician.slice(0, 8)}</strong>
                                  </div>
                                </div>
                              </td>
                              <td>{cell(row.providerId) !== '—' ? `Care · ${cell(row.providerId)}` : 'Rehab Session'}</td>
                              <td>
                                <span className="al-type-link">Video Call</span>
                              </td>
                              <td>
                                <StatusPill tone={statusTone(status)}>{status}</StatusPill>
                              </td>
                            </>
                          ) : (
                            <>
                              <td>{cell(row.id)}</td>
                              <td>{cell(row.participants)}</td>
                              <td>{cell(row.appointmentId)}</td>
                              <td>{formatWhen(row.updatedAt ?? row.createdAt)}</td>
                            </>
                          )}
                          <td>
                            <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
                              {dataTab === 'access' ? (
                                <button
                                  type="button"
                                  className="al-btn al-btn--ghost"
                                  style={{ padding: '4px 6px', fontSize: 11 }}
                                  disabled={busyId === row.id}
                                  onClick={async () => {
                                    setBusyId(row.id)
                                    try {
                                      await setRehabCareAccessStatus(row.id, 'revoked')
                                      setAccess((prev) =>
                                        prev.map((r) =>
                                          r.id === row.id ? { ...r, status: 'revoked' } : r,
                                        ),
                                      )
                                    } catch (err) {
                                      setError(
                                        err instanceof Error ? err.message : 'Update failed',
                                      )
                                    } finally {
                                      setBusyId('')
                                    }
                                  }}
                                >
                                  Revoke
                                </button>
                              ) : null}
                              <button type="button" className="icon-btn" aria-label="More">
                                <IconMore width={16} height={16} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
              {!rows.length ? (
                <div className="empty" style={{ padding: 20 }}>
                  No records found.
                </div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing 1 to {rows.length} of{' '}
                  {(dataTab === 'access' ? access.length : chats.length).toLocaleString()}{' '}
                  {dataTab === 'access' ? 'sessions' : 'threads'}
                </span>
              </div>
            </>
          )}
        </div>

        <div className="al-widgets">
          <Widget
            title="Upcoming Session"
            action={<button type="button" className="al-btn al-btn--ghost">View</button>}
          >
            {upcoming ? (
              <>
                <div className="al-upcoming-card">
                  <div className="al-person" style={{ marginBottom: 10 }}>
                    <img
                      src={avatarUrl(String(upcoming.patientUid ?? upcoming.id))}
                      alt=""
                    />
                    <div style={{ flex: 1 }}>
                      <strong>
                        Patient {String(upcoming.patientUid ?? upcoming.id).slice(0, 8)}
                      </strong>
                      <span>ID: {String(upcoming.patientUid ?? upcoming.id).slice(0, 10)}</span>
                    </div>
                    <StatusPill tone="ok">Confirmed</StatusPill>
                  </div>
                  <div className="al-widget-list">
                    <div className="al-widget-item">
                      <IconCalendar width={14} height={14} />
                      <div>
                        <strong>{formatWhen(upcoming.updatedAt ?? upcoming.createdAt)}</strong>
                        <span>45 mins · Video Call</span>
                      </div>
                    </div>
                    <div className="al-widget-item">
                      <IconUser width={14} height={14} />
                      <div>
                        <strong>
                          Dr. {String(upcoming.clinicianUid ?? 'Therapist').slice(0, 10)}
                        </strong>
                        <span>Physiotherapist</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="al-upcoming-actions">
                  <button type="button" className="al-btn al-btn--primary">
                    Join Session
                  </button>
                  <div className="row">
                    <button type="button" className="al-btn al-btn--outline">
                      Reschedule
                    </button>
                    <button type="button" className="al-btn al-btn--danger">
                      Cancel
                    </button>
                  </div>
                </div>
              </>
            ) : (
              <p className="muted" style={{ margin: 0, fontSize: 12.5 }}>
                No upcoming sessions.
              </p>
            )}
          </Widget>

          <Widget
            title="Recent Activity"
            action={<button type="button" className="al-btn al-btn--ghost">View All</button>}
          >
            {[
              {
                text: 'Fatima Noor completed a session',
                ago: '2 hours ago',
                tone: 'green' as const,
                icon: <IconCheckCircle width={14} height={14} />,
              },
              {
                text: 'Usman Khan joined a session',
                ago: '4 hours ago',
                tone: 'blue' as const,
                icon: <IconUser width={14} height={14} />,
              },
              {
                text: 'New assessment submitted',
                ago: '6 hours ago',
                tone: 'purple' as const,
                icon: <IconFileText width={14} height={14} />,
              },
            ].map((a) => (
              <div key={a.text} className="al-activity-item">
                <div className={`al-activity-icon al-activity-icon--${a.tone}`}>{a.icon}</div>
                <div>
                  <strong>{a.text}</strong>
                  <span>{a.ago}</span>
                </div>
              </div>
            ))}
          </Widget>

          <Widget title="Quick Actions">
            <div className="al-qa-grid">
              <button type="button" className="al-btn al-btn--outline">
                <IconUser width={14} height={14} /> Add Patient
              </button>
              <button type="button" className="al-btn al-btn--outline">
                <IconUsers width={14} height={14} /> Add Therapist
              </button>
              <a className="al-btn al-btn--outline" href="/tele-rehab">
                <IconLayers width={14} height={14} /> Create Program
              </a>
              <a className="al-btn al-btn--outline" href="/tele-rehab">
                <IconHeart width={14} height={14} /> Manage Exercises
              </a>
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
