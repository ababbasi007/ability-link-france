import { useEffect, useMemo, useState } from 'react'
import {
  fetchAppointments,
  fetchVerificationRequests,
  setAppointmentStatus,
  setVerificationRequestStatus,
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
  IconBuilding,
  IconCalendar,
  IconChart,
  IconCheck,
  IconCheckCircle,
  IconClock,
  IconFileText,
  IconMore,
  IconSend,
  IconUser,
  IconUsers,
  IconX,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const TABS = [
  { id: 'appointments', label: 'Appointments' },
  { id: 'doctors', label: 'Doctors' },
  { id: 'patients', label: 'Patients' },
  { id: 'clinics', label: 'Clinics / Hospitals' },
  { id: 'specialties', label: 'Specialties' },
  { id: 'prescriptions', label: 'Prescriptions' },
  { id: 'records', label: 'Medical Records' },
  { id: 'reports', label: 'Reports' },
  { id: 'verification', label: 'Verification' },
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

function formatTime(value: unknown): string {
  const d = asDate(value)
  if (!d) return '—'
  return d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'info' | 'muted' | 'purple' {
  switch (status) {
    case 'booked':
    case 'approved':
    case 'confirmed':
      return 'ok'
    case 'completed':
      return 'ok'
    case 'cancelled':
    case 'rejected':
      return 'danger'
    case 'no_show':
      return 'danger'
    case 'pending':
      return 'warn'
    case 'ongoing':
      return 'info'
    case 'upcoming':
      return 'purple'
    default:
      return 'muted'
  }
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

export function AppointmentsOpsPage() {
  const [tab, setTab] = useState('appointments')
  const [appointments, setAppointments] = useState<Doc[]>([])
  const [verificationRequests, setVerificationRequests] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [specialtyFilter, setSpecialtyFilter] = useState('all')
  const [modeFilter, setModeFilter] = useState('all')
  const [busyId, setBusyId] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [a, v] = await Promise.all([
        fetchAppointments(200),
        fetchVerificationRequests(100),
      ])
      setAppointments(a)
      setVerificationRequests(v)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load appointments data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const specialties = useMemo(() => {
    const set = new Set(
      appointments.map((a) => String(a.specialty ?? '')).filter(Boolean),
    )
    return [...set].sort()
  }, [appointments])

  const sortedAppointments = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return [...appointments]
      .filter((a) => {
        const status = String(a.status ?? '')
        const mode = String(a.mode ?? '')
        const kind = String(a.kind ?? '')
        const specialty = String(a.specialty ?? '')
        if (statusFilter !== 'all' && status !== statusFilter) return false
        if (modeFilter !== 'all' && mode.toLowerCase() !== modeFilter) return false
        if (typeFilter !== 'all' && kind.toLowerCase() !== typeFilter) return false
        if (specialtyFilter !== 'all' && specialty !== specialtyFilter) return false
        if (!needle) return true
        return (
          String(a.providerName ?? '').toLowerCase().includes(needle) ||
          specialty.toLowerCase().includes(needle) ||
          String(a.uid ?? '').toLowerCase().includes(needle) ||
          status.toLowerCase().includes(needle) ||
          a.id.toLowerCase().includes(needle)
        )
      })
      .sort((a, b) => {
        const da = asDate(a.createdAt ?? a.startAt)?.getTime() ?? 0
        const db = asDate(b.createdAt ?? b.startAt)?.getTime() ?? 0
        return db - da
      })
  }, [appointments, q, typeFilter, statusFilter, specialtyFilter, modeFilter])

  const kpis = useMemo(() => {
    const booked = appointments.filter((a) => String(a.status ?? '') === 'booked').length
    const completed = appointments.filter((a) => String(a.status ?? '') === 'completed').length
    const pending = appointments.filter((a) => String(a.status ?? '') === 'pending').length
    const doctors = new Set(appointments.map((a) => String(a.providerName ?? a.providerId ?? ''))).size
    const patients = new Set(appointments.map((a) => String(a.uid ?? ''))).size
    return { total: appointments.length, booked, completed, pending, doctors, patients }
  }, [appointments])

  const filteredVerification = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return verificationRequests.filter((v) => {
      if (!needle) return true
      return (
        String(v.name ?? '').toLowerCase().includes(needle) ||
        String(v.targetType ?? '').toLowerCase().includes(needle) ||
        String(v.targetId ?? '').toLowerCase().includes(needle) ||
        String(v.status ?? '').toLowerCase().includes(needle) ||
        v.id.toLowerCase().includes(needle)
      )
    })
  }, [verificationRequests, q])

  const upcoming = useMemo(() => {
    return [...appointments]
      .filter((a) => {
        const s = String(a.status ?? '')
        return s === 'booked' || s === 'pending' || s === 'confirmed'
      })
      .sort((a, b) => {
        const da = asDate(a.startAt)?.getTime() ?? 0
        const db = asDate(b.startAt)?.getTime() ?? 0
        return da - db
      })
      .slice(0, 4)
  }, [appointments])

  const setApptStatus = async (
    id: string,
    status: 'booked' | 'completed' | 'cancelled' | 'no_show',
  ) => {
    setBusyId(id)
    try {
      await setAppointmentStatus(id, status)
      setAppointments((prev) =>
        prev.map((a) => (a.id === id ? { ...a, status } : a)),
      )
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const setVerifyStatus = async (id: string, status: 'approved' | 'rejected') => {
    setBusyId(id)
    try {
      await setVerificationRequestStatus(id, status)
      setVerificationRequests((prev) =>
        prev.map((v) => (v.id === id ? { ...v, status } : v)),
      )
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const showAppointmentsTable = tab === 'appointments' || tab === 'doctors' || tab === 'patients'

  return (
    <div className="al-page">
      <PageHeader
        title="Tele Health"
        subtitle="Manage online healthcare consultations, doctors, clinics and patient care."
        onExport={() => {
          const lines = [
            'Date,Provider,Specialty,Mode,Status,User',
            ...sortedAppointments.map((a) =>
              [
                formatWhen(a.startAt),
                a.providerName,
                a.specialty,
                a.mode,
                a.status,
                a.uid,
              ]
                .map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`)
                .join(','),
            ),
          ]
          const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
          const url = URL.createObjectURL(blob)
          const el = document.createElement('a')
          el.href = url
          el.download = 'tele-health-appointments.csv'
          el.click()
          URL.revokeObjectURL(url)
        }}
        primaryAction={{ label: 'Book Appointment', onClick: () => void load() }}
        secondaryAction={
          <span className="al-btn al-btn--outline" style={{ pointerEvents: 'none' }}>
            <IconCalendar width={15} height={15} /> 1 Sep 2025 - 30 Sep 2025
          </span>
        }
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <KpiRow
        items={[
          {
            label: 'Total Appointments',
            value: kpis.total.toLocaleString(),
            trend: '28% vs last month',
            tone: 'blue',
            icon: <IconCalendar width={18} height={18} />,
          },
          {
            label: 'Active Doctors',
            value: kpis.doctors.toLocaleString(),
            trend: '16% vs last month',
            tone: 'green',
            icon: <IconUser width={18} height={18} />,
          },
          {
            label: 'Total Patients',
            value: kpis.patients.toLocaleString(),
            trend: '24% vs last month',
            tone: 'orange',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Pending Appointments',
            value: kpis.pending.toLocaleString(),
            trend: '12% vs last month',
            trendDown: true,
            tone: 'red',
            icon: <IconClock width={18} height={18} />,
          },
          {
            label: 'Consultations Completed',
            value: kpis.completed.toLocaleString(),
            trend: '32% vs last month',
            tone: 'purple',
            icon: <IconCheckCircle width={18} height={18} />,
          },
        ]}
      />

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search by patient name, doctor name or ID..."
        onReset={() => {
          setQ('')
          setTypeFilter('all')
          setStatusFilter('all')
          setSpecialtyFilter('all')
          setModeFilter('all')
        }}
      >
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
          <option value="all">All Types</option>
          <option value="consult">Consultation</option>
          <option value="followup">Follow-up</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Statuses</option>
          <option value="booked">Booked</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="cancelled">Cancelled</option>
        </select>
        <select value={specialtyFilter} onChange={(e) => setSpecialtyFilter(e.target.value)}>
          <option value="all">All Specialties</option>
          {specialties.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>
        <select value={modeFilter} onChange={(e) => setModeFilter(e.target.value)}>
          <option value="all">All Modes</option>
          <option value="video">Video Call</option>
          <option value="in-person">In-person</option>
          <option value="chat">Chat</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>
              Loading…
            </p>
          ) : tab === 'verification' ? (
            filteredVerification.length === 0 ? (
              <p className="muted" style={{ padding: 20 }}>
                No verification requests found.
              </p>
            ) : (
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Target type</th>
                      <th>Target ID</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredVerification.map((v) => {
                      const status = String(v.status ?? 'pending')
                      return (
                        <tr key={v.id}>
                          <td>{String(v.name ?? '—')}</td>
                          <td>{String(v.targetType ?? '—')}</td>
                          <td>
                            <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                              {String(v.targetId ?? '—')}
                            </span>
                          </td>
                          <td>
                            <StatusPill tone={statusTone(status)}>{status}</StatusPill>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                              <button
                                type="button"
                                className="al-btn al-btn--primary"
                                disabled={busyId === v.id || status === 'approved'}
                                onClick={() => void setVerifyStatus(v.id, 'approved')}
                              >
                                <IconCheck width={14} height={14} /> Approve
                              </button>
                              <button
                                type="button"
                                className="al-btn al-btn--outline"
                                disabled={busyId === v.id || status === 'rejected'}
                                onClick={() => void setVerifyStatus(v.id, 'rejected')}
                              >
                                <IconX width={14} height={14} /> Reject
                              </button>
                            </div>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )
          ) : showAppointmentsTable ? (
            sortedAppointments.length === 0 ? (
              <p className="muted" style={{ padding: 20 }}>
                No appointments found.
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
                        <th>Date & Time</th>
                        <th>Patient</th>
                        <th>Doctor</th>
                        <th>Specialty</th>
                        <th>Mode</th>
                        <th>Status</th>
                        <th />
                      </tr>
                    </thead>
                    <tbody>
                      {sortedAppointments.map((a) => {
                        const status = String(a.status ?? 'booked')
                        const mode = String(a.mode ?? 'video')
                        const uid = String(a.uid ?? a.id)
                        const doctor = String(a.providerName ?? 'Doctor')
                        return (
                          <tr key={a.id}>
                            <td>
                              <input type="checkbox" aria-label={`Select ${a.id}`} />
                            </td>
                            <td>{formatWhen(a.startAt)}</td>
                            <td>
                              <div className="al-person">
                                <img src={avatarUrl(uid)} alt="" />
                                <div>
                                  <strong>Patient {uid.slice(0, 6)}</strong>
                                  <span>ID: {uid.slice(0, 8)}</span>
                                </div>
                              </div>
                            </td>
                            <td>
                              <div className="al-person">
                                <img src={avatarUrl(doctor)} alt="" />
                                <div>
                                  <strong>{doctor}</strong>
                                </div>
                              </div>
                            </td>
                            <td>{String(a.specialty ?? '—')}</td>
                            <td>
                              <StatusPill
                                tone={
                                  mode.toLowerCase().includes('person') ||
                                  mode.toLowerCase().includes('in')
                                    ? 'ok'
                                    : 'info'
                                }
                              >
                                {mode.toLowerCase().includes('person')
                                  ? 'In-person'
                                  : mode.toLowerCase().includes('chat')
                                    ? 'Chat'
                                    : 'Video Call'}
                              </StatusPill>
                            </td>
                            <td>
                              <StatusPill tone={statusTone(status)}>{status}</StatusPill>
                            </td>
                            <td>
                              <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
                                {(
                                  [
                                    ['booked', 'Booked'],
                                    ['completed', 'Done'],
                                    ['cancelled', 'Cancel'],
                                  ] as const
                                ).map(([s, label]) => (
                                  <button
                                    key={s}
                                    type="button"
                                    className="al-btn al-btn--ghost"
                                    style={{ padding: '4px 6px', fontSize: 11 }}
                                    disabled={busyId === a.id || status === s}
                                    onClick={() => void setApptStatus(a.id, s)}
                                  >
                                    {label}
                                  </button>
                                ))}
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
                <div className="al-footer">
                  <span>
                    Showing 1 to {sortedAppointments.length} of {kpis.total.toLocaleString()}{' '}
                    appointments
                  </span>
                  <div className="al-pages">
                    <button type="button" className="active" disabled>
                      1
                    </button>
                  </div>
                  <label>
                    Rows per page{' '}
                    <select defaultValue={10}>
                      <option value={10}>10</option>
                      <option value={25}>25</option>
                    </select>
                  </label>
                </div>
              </>
            )
          ) : (
            <p className="muted" style={{ padding: 20 }}>
              {TABS.find((t) => t.id === tab)?.label} view coming soon — use Appointments for live
              data. Provider verification:{' '}
              <a href="/provider-verifications">/provider-verifications</a>
            </p>
          )}
        </div>

        <div className="al-widgets">
          <Widget title="Today's Schedule" action={<button type="button" className="al-btn al-btn--ghost">View All</button>}>
            <div className="al-widget-list">
              {upcoming.length === 0 ? (
                <p className="muted" style={{ margin: 0, fontSize: 12.5 }}>
                  No upcoming appointments.
                </p>
              ) : (
                upcoming.map((a, i) => (
                  <div key={a.id} className="al-schedule-item">
                    <span className="al-schedule-time">{formatTime(a.startAt)}</span>
                    <img
                      src={avatarUrl(String(a.providerName ?? a.id))}
                      alt=""
                      width={32}
                      height={32}
                      style={{ borderRadius: '50%' }}
                    />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <strong>{String(a.providerName ?? 'Doctor')}</strong>
                      <span>{String(a.specialty ?? 'Consultation')}</span>
                    </div>
                    <StatusPill tone={i === 0 ? 'ok' : 'info'}>
                      {i === 0 ? 'Now' : `In ${i + 1}h`}
                    </StatusPill>
                  </div>
                ))
              )}
            </div>
          </Widget>

          <Widget
            title="Recent Notifications"
            action={<button type="button" className="al-btn al-btn--ghost">View All</button>}
          >
            {[
              {
                text: 'New appointment booked',
                ago: '10 minutes ago',
                tone: 'blue' as const,
                icon: <IconCalendar width={14} height={14} />,
              },
              {
                text: 'Prescription uploaded',
                ago: '1 hour ago',
                tone: 'purple' as const,
                icon: <IconFileText width={14} height={14} />,
              },
              {
                text: 'Consultation completed',
                ago: '3 hours ago',
                tone: 'green' as const,
                icon: <IconCheckCircle width={14} height={14} />,
              },
            ].map((n) => (
              <div key={n.text} className="al-activity-item">
                <div className={`al-activity-icon al-activity-icon--${n.tone}`}>{n.icon}</div>
                <div>
                  <strong>{n.text}</strong>
                  <span>{n.ago}</span>
                </div>
              </div>
            ))}
          </Widget>

          <Widget title="Quick Actions">
            <div className="al-qa-grid">
              <button type="button" className="al-btn al-btn--outline">
                <IconUser width={14} height={14} /> Add Doctor
              </button>
              <button type="button" className="al-btn al-btn--outline">
                <IconBuilding width={14} height={14} /> Add Clinic
              </button>
              <button type="button" className="al-btn al-btn--outline">
                <IconSend width={14} height={14} /> Send Notification
              </button>
              <a className="al-btn al-btn--outline" href="/reports">
                <IconChart width={14} height={14} /> View Reports
              </a>
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
