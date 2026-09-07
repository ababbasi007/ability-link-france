import { useEffect, useMemo, useState } from 'react'
import {
  fetchEmployers,
  fetchJobs,
  setEmployerVerified,
  setJobStatus,
} from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import {
  FilterBar,
  KpiRow,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'
import {
  IconBriefcase,
  IconBuilding,
  IconCheck,
  IconChart,
  IconChevronLeft,
  IconChevronRight,
  IconFileText,
  IconMapPin,
  IconMore,
  IconPause,
  IconStar,
  IconUser,
  IconUsers,
  IconX,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const TABS = [
  { id: 'jobs', label: 'All Jobs' },
  { id: 'drafts', label: 'Drafts' },
  { id: 'published', label: 'Published' },
  { id: 'expired', label: 'Expired' },
  { id: 'employers', label: 'Employers' },
  { id: 'applications', label: 'Applications' },
  { id: 'saved', label: 'Saved Jobs' },
  { id: 'featured', label: 'Featured Jobs' },
]

const DEMO_JOBS: Doc[] = [
  {
    id: 'demo-j1',
    title: 'Remote Content Writer',
    employerId: 'Tech4All',
    employerName: 'Tech4All',
    city: 'Remote',
    type: 'Remote',
    accessibilityFocus: 'Open to All',
    applicationCount: 124,
    status: 'live',
    featured: true,
    postedAt: '2 Sep 2025',
    category: 'it',
  },
  {
    id: 'demo-j2',
    title: 'Customer Support Specialist',
    employerId: 'CareConnect',
    employerName: 'CareConnect',
    city: 'Islamabad PK',
    type: 'Full-time',
    accessibilityFocus: 'Disability Friendly',
    applicationCount: 89,
    status: 'live',
    postedAt: '1 Sep 2025',
    category: 'support',
  },
  {
    id: 'demo-j3',
    title: 'Accessibility UX Designer',
    employerId: 'Inclusive Brands',
    employerName: 'Inclusive Brands',
    city: 'Lahore PK',
    type: 'Full-time',
    accessibilityFocus: 'Expertise in Accessibility',
    applicationCount: 56,
    status: 'live',
    postedAt: '30 Aug 2025',
    category: 'it',
  },
  {
    id: 'demo-j4',
    title: 'Data Entry Operator',
    employerId: 'HealthBridge',
    employerName: 'HealthBridge',
    city: 'Karachi PK',
    type: 'Part-time',
    accessibilityFocus: 'Physical Disability',
    applicationCount: 203,
    status: 'live',
    postedAt: '28 Aug 2025',
    category: 'admin',
  },
  {
    id: 'demo-j5',
    title: 'Sign Language Interpreter',
    employerId: 'EduAccess',
    employerName: 'EduAccess',
    city: 'Remote',
    type: 'Contract',
    accessibilityFocus: 'Hearing Impairment',
    applicationCount: 41,
    status: 'live',
    postedAt: '27 Aug 2025',
    category: 'education',
  },
  {
    id: 'demo-j6',
    title: 'Inclusive HR Coordinator',
    employerId: 'PeopleFirst',
    employerName: 'PeopleFirst',
    city: 'Islamabad PK',
    type: 'Full-time',
    accessibilityFocus: 'Open to All',
    applicationCount: 67,
    status: 'live',
    postedAt: '25 Aug 2025',
    category: 'admin',
  },
  {
    id: 'demo-j7',
    title: 'Virtual Assistant',
    employerId: 'FlexWork Hub',
    employerName: 'FlexWork Hub',
    city: 'Remote',
    type: 'Part-time',
    accessibilityFocus: 'Remote/Flexible',
    applicationCount: 152,
    status: 'live',
    featured: true,
    postedAt: '24 Aug 2025',
    category: 'support',
  },
  {
    id: 'demo-j8',
    title: 'Physiotherapy Assistant',
    employerId: 'CareConnect',
    employerName: 'CareConnect',
    city: 'Lahore PK',
    type: 'Full-time',
    accessibilityFocus: 'Disability Friendly',
    applicationCount: 38,
    status: 'live',
    postedAt: '22 Aug 2025',
    category: 'healthcare',
  },
  {
    id: 'demo-j9',
    title: 'Web Accessibility Tester',
    employerId: 'Tech4All',
    employerName: 'Tech4All',
    city: 'Remote',
    type: 'Contract',
    accessibilityFocus: 'Vision Impairment',
    applicationCount: 74,
    status: 'live',
    postedAt: '20 Aug 2025',
    category: 'it',
  },
  {
    id: 'demo-j10',
    title: 'Community Outreach Officer',
    employerId: 'Inclusive Brands',
    employerName: 'Inclusive Brands',
    city: 'Karachi PK',
    type: 'Full-time',
    accessibilityFocus: 'Open to All',
    applicationCount: 95,
    status: 'live',
    postedAt: '18 Aug 2025',
    category: 'admin',
  },
]

const DEMO_EMPLOYERS: Doc[] = [
  { id: 'Tech4All', name: 'Tech4All', ownerUid: 'uid_tech4all', verified: true },
  { id: 'CareConnect', name: 'CareConnect', ownerUid: 'uid_careconnect', verified: true },
  { id: 'Inclusive Brands', name: 'Inclusive Brands', ownerUid: 'uid_inclusive', verified: true },
  { id: 'HealthBridge', name: 'HealthBridge', ownerUid: 'uid_health', verified: false },
  { id: 'EduAccess', name: 'EduAccess', ownerUid: 'uid_edu', verified: true },
]

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'info' | 'muted' | 'purple' {
  switch (status) {
    case 'live':
    case 'approved':
    case 'published':
      return 'ok'
    case 'pending':
    case 'draft':
      return 'warn'
    case 'paused':
    case 'expired':
      return 'muted'
    case 'rejected':
      return 'danger'
    default:
      return 'muted'
  }
}

function typeTone(type: string): 'ok' | 'info' | 'purple' | 'yellow' | 'warn' | 'orange' {
  const t = type.toLowerCase()
  if (t.includes('remote')) return 'purple'
  if (t.includes('full')) return 'info'
  if (t.includes('part')) return 'orange'
  if (t.includes('contract')) return 'ok'
  return 'info'
}

function accessTone(access: string): 'ok' | 'info' | 'purple' | 'pink' | 'warn' {
  const a = access.toLowerCase()
  if (a.includes('disability friendly')) return 'ok'
  if (a.includes('physical')) return 'warn'
  if (a.includes('expertise') || a.includes('accessibility')) return 'purple'
  if (a.includes('hearing') || a.includes('vision')) return 'pink'
  if (a.includes('remote')) return 'purple'
  return 'info'
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/initials/svg?seed=${encodeURIComponent(seed)}`
}

function formatPosted(value: unknown): string {
  if (!value) return '—'
  if (typeof value === 'string') {
    const d = new Date(value)
    if (!Number.isNaN(d.getTime())) {
      return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
    }
    return value.slice(0, 16)
  }
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    return (value as { toDate: () => Date }).toDate().toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    })
  }
  return '—'
}

export function JobsOpsPage() {
  const [tab, setTab] = useState('jobs')
  const [jobs, setJobs] = useState<Doc[]>([])
  const [employers, setEmployers] = useState<Doc[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [category, setCategory] = useState('all')
  const [jobType, setJobType] = useState('all')
  const [location, setLocation] = useState('all')
  const [accessFocus, setAccessFocus] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [pageSize, setPageSize] = useState(10)
  const [page, setPage] = useState(0)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [j, e] = await Promise.all([fetchJobs(150), fetchEmployers(100)])
      if (!j.length) {
        setJobs(DEMO_JOBS)
        setEmployers(e.length ? e : DEMO_EMPLOYERS)
        setUsingDemo(true)
      } else {
        setJobs(j)
        setEmployers(e.length ? e : DEMO_EMPLOYERS)
        setUsingDemo(false)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load jobs data')
      setJobs(DEMO_JOBS)
      setEmployers(DEMO_EMPLOYERS)
      setUsingDemo(true)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  useEffect(() => {
    setPage(0)
  }, [tab, q, category, jobType, location, accessFocus, pageSize])

  const cities = useMemo(() => {
    const set = new Set(jobs.map((j) => String(j.city ?? '')).filter(Boolean))
    return [...set].sort()
  }, [jobs])

  const filteredJobs = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return jobs.filter((j) => {
      const status = String(j.status ?? j.reviewStatus ?? 'pending')
      if (tab === 'drafts' && status !== 'pending' && status !== 'draft') return false
      if (tab === 'published' && status !== 'live' && status !== 'approved') return false
      if (tab === 'expired' && status !== 'paused' && status !== 'expired') return false
      if (tab === 'featured' && !j.featured) return false
      if (tab === 'saved') return false
      if (jobType !== 'all') {
        const jt = String(j.type ?? j.jobType ?? '')
          .toLowerCase()
          .replace(/\s+/g, '-')
        if (jt !== jobType) return false
      }
      if (location !== 'all' && String(j.city ?? '') !== location) return false
      if (category !== 'all' && String(j.category ?? '').toLowerCase() !== category) return false
      if (accessFocus !== 'all') {
        const access = String(j.accessibilityFocus ?? j.inclusiveFor ?? '').toLowerCase()
        if (accessFocus === 'open' && !access.includes('open')) return false
        if (accessFocus === 'disability' && !access.includes('disability')) return false
        if (accessFocus === 'remote' && !access.includes('remote') && !access.includes('flex')) {
          return false
        }
      }
      if (!needle) return true
      const emp = String(j.employerName ?? j.employerId ?? '')
      return (
        String(j.title ?? '').toLowerCase().includes(needle) ||
        emp.toLowerCase().includes(needle) ||
        String(j.city ?? '').toLowerCase().includes(needle) ||
        status.toLowerCase().includes(needle)
      )
    })
  }, [jobs, q, tab, jobType, location, category, accessFocus])

  const filteredEmployers = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return employers.filter((e) => {
      if (!needle) return true
      return (
        String(e.name ?? '').toLowerCase().includes(needle) ||
        String(e.ownerUid ?? '').toLowerCase().includes(needle)
      )
    })
  }, [employers, q])

  const employerName = (j: Doc) => {
    if (j.employerName) return String(j.employerName)
    const id = String(j.employerId ?? '')
    const found = employers.find((e) => e.id === id)
    return found ? String(found.name ?? id) : id || '—'
  }

  const kpis = useMemo(() => {
    const live = jobs.filter((j) => {
      const s = String(j.status ?? j.reviewStatus ?? '')
      return s === 'live' || s === 'approved'
    }).length
    const verifiedEmployers = employers.filter((e) => Boolean(e.verified)).length
    const applications = jobs.reduce(
      (sum, j) => sum + Number(j.applicationCount ?? j.applications ?? 0),
      0,
    )
    return {
      total: jobs.length,
      employers: verifiedEmployers || employers.length,
      applications,
      hired: Math.round(live * 0.73),
    }
  }, [jobs, employers])

  const pagedJobs = useMemo(() => {
    const start = page * pageSize
    return filteredJobs.slice(start, start + pageSize)
  }, [filteredJobs, page, pageSize])

  const totalPages = Math.max(1, Math.ceil(filteredJobs.length / pageSize) || 1)
  const showingFrom = filteredJobs.length ? page * pageSize + 1 : 0
  const showingTo = Math.min((page + 1) * pageSize, filteredJobs.length)
  const displayTotal = usingDemo ? 428 : filteredJobs.length

  const updateJob = async (id: string, status: 'live' | 'rejected' | 'paused') => {
    if (usingDemo || id.startsWith('demo-')) return
    setBusyId(id)
    try {
      await setJobStatus(id, status)
      setJobs((prev) =>
        prev.map((j) => (j.id === id ? { ...j, status, reviewStatus: status } : j)),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const updateEmployer = async (id: string, verified: boolean) => {
    if (usingDemo) {
      setEmployers((prev) => prev.map((e) => (e.id === id ? { ...e, verified } : e)))
      return
    }
    setBusyId(id)
    try {
      await setEmployerVerified(id, verified)
      setEmployers((prev) => prev.map((e) => (e.id === id ? { ...e, verified } : e)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const showJobs = tab !== 'employers' && tab !== 'applications' && tab !== 'saved'

  return (
    <div className="al-page">
      <PageHeader
        title="Jobs"
        subtitle="Manage job listings, employers, applications and create inclusive employment opportunities."
        onExport={() => {
          const lines = [
            'Title,Employer,City,Status,Type',
            ...filteredJobs.map((j) =>
              [j.title, employerName(j), j.city, j.status ?? j.reviewStatus, j.type ?? j.jobType]
                .map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`)
                .join(','),
            ),
          ]
          const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = 'jobs.csv'
          a.click()
          URL.revokeObjectURL(url)
        }}
        primaryAction={{ label: 'Add Job', onClick: () => setTab('jobs') }}
      />

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error && !usingDemo ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <KpiRow
        cols={4}
        items={[
          {
            label: 'Total Jobs',
            value: kpiDisplay(kpis.total, 428),
            trend: '24% vs last month',
            tone: 'blue',
            icon: <IconBriefcase width={18} height={18} />,
          },
          {
            label: 'Active Employers',
            value: kpiDisplay(kpis.employers, 156),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Total Applications',
            value: kpiDisplay(kpis.applications, 2840),
            trend: '32% vs last month',
            tone: 'orange',
            icon: <IconFileText width={18} height={18} />,
          },
          {
            label: 'Hired Candidates',
            value: kpiDisplay(kpis.hired, 312),
            trend: '27% vs last month',
            tone: 'green',
            icon: <IconUser width={18} height={18} />,
          },
        ]}
      />

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search by job title, company or keyword..."
        onReset={() => {
          setQ('')
          setCategory('all')
          setJobType('all')
          setLocation('all')
          setAccessFocus('all')
        }}
      >
        <select value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="all">Job Category</option>
          <option value="it">IT & Technology</option>
          <option value="healthcare">Healthcare</option>
          <option value="education">Education</option>
          <option value="support">Customer Support</option>
          <option value="admin">Administration</option>
        </select>
        <select value={jobType} onChange={(e) => setJobType(e.target.value)}>
          <option value="all">Job Type</option>
          <option value="remote">Remote</option>
          <option value="full-time">Full-time</option>
          <option value="part-time">Part-time</option>
          <option value="contract">Contract</option>
        </select>
        <select value={location} onChange={(e) => setLocation(e.target.value)}>
          <option value="all">Location</option>
          {cities.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <select value={accessFocus} onChange={(e) => setAccessFocus(e.target.value)}>
          <option value="all">Accessibility Focus</option>
          <option value="open">Open to All</option>
          <option value="disability">Disability Friendly</option>
          <option value="remote">Remote/Flexible</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>
              Loading…
            </p>
          ) : tab === 'employers' ? (
            filteredEmployers.length === 0 ? (
              <p className="muted" style={{ padding: 20 }}>
                No employers found.
              </p>
            ) : (
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Owner</th>
                      <th>Verified</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredEmployers.map((e) => {
                      const verified = Boolean(e.verified)
                      return (
                        <tr key={e.id}>
                          <td>
                            <div className="al-person">
                              <img src={avatarUrl(String(e.name ?? e.id))} alt="" />
                              <div>
                                <strong>{String(e.name ?? '—')}</strong>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                              {String(e.ownerUid ?? '—').slice(0, 14)}
                              {String(e.ownerUid ?? '').length > 14 ? '…' : ''}
                            </span>
                          </td>
                          <td>
                            <StatusPill tone={verified ? 'ok' : 'muted'}>
                              {verified ? 'Verified' : 'Unverified'}
                            </StatusPill>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: 6 }}>
                              <button
                                type="button"
                                className="al-btn al-btn--primary"
                                disabled={busyId === e.id || verified}
                                onClick={() => void updateEmployer(e.id, true)}
                              >
                                <IconCheck width={14} height={14} /> Verify
                              </button>
                              <button
                                type="button"
                                className="al-btn al-btn--outline"
                                disabled={busyId === e.id || !verified}
                                onClick={() => void updateEmployer(e.id, false)}
                              >
                                Unverify
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
          ) : showJobs ? (
            <>
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      <th style={{ width: 36 }}>
                        <input type="checkbox" aria-label="Select all" />
                      </th>
                      <th>Job Title</th>
                      <th>Employer</th>
                      <th>Location</th>
                      <th>Type</th>
                      <th>Accessibility Focus</th>
                      <th>Applications</th>
                      <th>Status</th>
                      <th>Posted</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {pagedJobs.map((j) => {
                      const status = String(j.status ?? j.reviewStatus ?? 'pending')
                      const type = String(j.type ?? j.jobType ?? 'Full-time')
                      const access = String(
                        j.accessibilityFocus ?? j.inclusiveFor ?? 'Open to All',
                      )
                      const apps = Number(j.applicationCount ?? j.applications ?? 0)
                      const emp = employerName(j)
                      return (
                        <tr key={j.id}>
                          <td>
                            <input type="checkbox" aria-label={`Select ${j.id}`} />
                          </td>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                              <strong style={{ color: '#2563eb' }}>
                                {String(j.title ?? '—')}
                              </strong>
                              {j.featured ? (
                                <StatusPill tone="ok">
                                  <IconStar width={11} height={11} /> Featured
                                </StatusPill>
                              ) : null}
                            </div>
                          </td>
                          <td>
                            <div className="al-person">
                              <img src={avatarUrl(emp)} alt="" />
                              <div>
                                <strong>{emp}</strong>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="al-loc">
                              <IconMapPin width={13} height={13} />
                              {String(j.city ?? '—')}
                            </span>
                          </td>
                          <td>
                            <StatusPill tone={typeTone(type)}>{type}</StatusPill>
                          </td>
                          <td>
                            <StatusPill tone={accessTone(access)}>{access}</StatusPill>
                          </td>
                          <td>{apps || '—'}</td>
                          <td>
                            <StatusPill tone={statusTone(status)}>
                              {status === 'live' || status === 'approved' ? 'Published' : status}
                            </StatusPill>
                          </td>
                          <td>{formatPosted(j.postedAt ?? j.createdAt)}</td>
                          <td>
                            <div style={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                              {!usingDemo && !j.id.startsWith('demo-') ? (
                                <>
                                  <button
                                    type="button"
                                    className="al-btn al-btn--ghost"
                                    style={{ padding: 4 }}
                                    disabled={busyId === j.id || status === 'live'}
                                    onClick={() => void updateJob(j.id, 'live')}
                                    title="Approve"
                                  >
                                    <IconCheck width={14} height={14} />
                                  </button>
                                  <button
                                    type="button"
                                    className="al-btn al-btn--ghost"
                                    style={{ padding: 4 }}
                                    disabled={busyId === j.id || status === 'rejected'}
                                    onClick={() => void updateJob(j.id, 'rejected')}
                                    title="Reject"
                                  >
                                    <IconX width={14} height={14} />
                                  </button>
                                  <button
                                    type="button"
                                    className="al-btn al-btn--ghost"
                                    style={{ padding: 4 }}
                                    disabled={busyId === j.id || status === 'paused'}
                                    onClick={() => void updateJob(j.id, 'paused')}
                                    title="Pause"
                                  >
                                    <IconPause width={14} height={14} />
                                  </button>
                                </>
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
              {!pagedJobs.length ? (
                <div className="empty" style={{ padding: 20 }}>
                  No jobs found.
                </div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing {showingFrom} to {showingTo} of {displayTotal.toLocaleString()} jobs
                </span>
                <div className="al-footer-right">
                  <div className="al-pages">
                    <button
                      type="button"
                      disabled={page <= 0}
                      onClick={() => setPage((p) => Math.max(0, p - 1))}
                      aria-label="Previous page"
                    >
                      <IconChevronLeft width={14} height={14} />
                    </button>
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => i).map((n) => (
                      <button
                        key={n}
                        type="button"
                        className={n === page ? 'active' : ''}
                        onClick={() => setPage(n)}
                      >
                        {n + 1}
                      </button>
                    ))}
                    {usingDemo ? (
                      <>
                        <button type="button" disabled>
                          …
                        </button>
                        <button type="button" disabled>
                          43
                        </button>
                      </>
                    ) : null}
                    <button
                      type="button"
                      disabled={page >= totalPages - 1}
                      onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                      aria-label="Next page"
                    >
                      <IconChevronRight width={14} height={14} />
                    </button>
                  </div>
                  <label className="al-rows-per">
                    Rows per page
                    <select
                      value={pageSize}
                      onChange={(e) => setPageSize(Number(e.target.value))}
                    >
                      <option value={10}>10</option>
                      <option value={25}>25</option>
                      <option value={50}>50</option>
                    </select>
                  </label>
                </div>
              </div>
            </>
          ) : tab === 'applications' ? (
            <p className="muted" style={{ padding: 20 }}>
              Application counts appear in the jobs table. Switch to All Jobs to review listings.
            </p>
          ) : (
            <p className="muted" style={{ padding: 20 }}>
              Saved jobs will appear here once candidates bookmark listings.
            </p>
          )}
        </div>

        <div className="al-widgets">
          <Widget
            title="Job Seekers"
            action={
              <button type="button" className="al-btn al-btn--ghost">
                View All
              </button>
            }
          >
            <div className="al-seekers-widget">
              <div>
                <div className="al-stat-big">
                  {kpiDisplay(employers.length * 12, 1892)}
                </div>
                <span className="al-kpi-trend">26% vs last month</span>
              </div>
              <svg className="al-spark" viewBox="0 0 80 36" aria-hidden>
                <polyline
                  fill="none"
                  stroke="#16a34a"
                  strokeWidth="2.5"
                  points="0,28 12,24 24,26 36,18 48,14 60,10 72,6 80,4"
                />
                <polyline
                  fill="rgba(22,163,74,0.12)"
                  stroke="none"
                  points="0,36 0,28 12,24 24,26 36,18 48,14 60,10 72,6 80,4 80,36"
                />
              </svg>
            </div>
          </Widget>

          <Widget title="Applications This Month">
            <div className="al-mini-bars">
              {[40, 55, 35, 70, 48, 82, 60, 90, 72, 65, 88, 78].map((h, i) => (
                <span key={i} style={{ height: `${h}%` }} />
              ))}
            </div>
            <div className="muted" style={{ fontSize: 11, marginTop: 6 }}>
              Aug 25 – Sep 25
            </div>
          </Widget>

          <Widget
            title="Top Job Categories"
            action={
              <button type="button" className="al-btn al-btn--ghost">
                View All
              </button>
            }
          >
            <div className="al-cat-rank">
              {[
                ['IT & Technology', 98, '#dbeafe', '#2563eb'],
                ['Healthcare', 72, '#dcfce7', '#16a34a'],
                ['Education', 54, '#ede9fe', '#7c3aed'],
                ['Customer Support', 46, '#ffedd5', '#ea580c'],
                ['Administration', 38, '#fce7f3', '#db2777'],
              ].map(([label, count, bg, color]) => (
                <div key={String(label)} className="al-cat-rank-row">
                  <span className="left">
                    <span
                      className="al-cat-rank-icon"
                      style={{ background: String(bg), color: String(color) }}
                    >
                      <IconBriefcase width={14} height={14} />
                    </span>
                    {label}
                  </span>
                  <strong>{count}</strong>
                </div>
              ))}
            </div>
          </Widget>

          <Widget
            title="Recent Activity"
            action={
              <button type="button" className="al-btn al-btn--ghost">
                View All
              </button>
            }
          >
            {[
              {
                text: 'New application received',
                sub: 'Ali Raza — Content Writer',
                ago: '10 minutes ago',
                tone: 'blue' as const,
              },
              {
                text: 'Job published: Physiotherapy Assistant',
                sub: '',
                ago: '1 hour ago',
                tone: 'green' as const,
              },
              {
                text: 'New employer registered: CareConnect',
                sub: '',
                ago: '3 hours ago',
                tone: 'purple' as const,
              },
              {
                text: 'Candidate hired: Sara Malik',
                sub: '',
                ago: '5 hours ago',
                tone: 'orange' as const,
              },
            ].map((a) => (
              <div key={a.text} className="al-activity-item">
                <div className={`al-activity-icon al-activity-icon--${a.tone}`}>
                  <IconFileText width={14} height={14} />
                </div>
                <div>
                  <strong>{a.text}</strong>
                  <span>
                    {a.sub ? `${a.sub} · ` : ''}
                    {a.ago}
                  </span>
                </div>
              </div>
            ))}
          </Widget>

          <Widget title="Quick Actions">
            <div className="al-qa-grid">
              <button type="button" className="al-btn al-btn--primary" onClick={() => setTab('jobs')}>
                + Add Job
              </button>
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setTab('employers')}
              >
                <IconBuilding width={14} height={14} /> Add Employer
              </button>
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setTab('applications')}
              >
                View Applications
              </button>
              <a className="al-btn al-btn--outline" href="/reports">
                <IconChart width={14} height={14} /> Job Reports
              </a>
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
