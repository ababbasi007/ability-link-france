import { useEffect, useMemo, useState } from 'react'
import {
  fetchBenefitApplications,
  fetchBenefitSchemes,
  setBenefitSchemeActive,
  upsertBenefitScheme,
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
  IconClock,
  IconFileText,
  IconMore,
  IconPlus,
  IconShieldCheck,
  IconTags,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'benefits', label: 'Benefits' },
  { id: 'categories', label: 'Categories' },
  { id: 'countries', label: 'Countries' },
  { id: 'eligibility', label: 'Eligibility Rules' },
  { id: 'applications', label: 'Applications' },
  { id: 'resources', label: 'Resources' },
  { id: 'reports', label: 'Reports' },
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
  return d.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

function statusTone(status: string): 'ok' | 'warn' | 'danger' | 'muted' | 'yellow' {
  switch (status) {
    case 'approved':
    case 'granted':
    case 'published':
    case 'active':
      return 'ok'
    case 'pending':
    case 'submitted':
    case 'in_review':
    case 'under_review':
      return 'warn'
    case 'draft':
      return 'yellow'
    case 'rejected':
    case 'denied':
      return 'danger'
    default:
      return 'muted'
  }
}

function catTone(cat: string): 'ok' | 'info' | 'pink' | 'purple' | 'danger' {
  const c = cat.toLowerCase()
  if (c.includes('financ')) return 'ok'
  if (c.includes('health')) return 'danger'
  if (c.includes('employ')) return 'info'
  if (c.includes('hous')) return 'pink'
  if (c.includes('educ')) return 'purple'
  return 'info'
}

function eligibilitySummary(doc: Doc): string {
  const rules = doc.eligibilityRules ?? doc.eligibility
  if (typeof rules === 'string' && rules.trim()) return rules.trim()
  if (Array.isArray(rules)) return rules.map(String).join(', ') || '—'
  if (rules && typeof rules === 'object') {
    try {
      return JSON.stringify(rules)
    } catch {
      return '—'
    }
  }
  return String(doc.eligibilitySummary ?? '—')
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(seed)}`
}

export function BenefitsOpsPage() {
  const [tab, setTab] = useState('overview')
  const [schemes, setSchemes] = useState<Doc[]>([])
  const [applications, setApplications] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [country, setCountry] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [schemeForm, setSchemeForm] = useState({
    title: '',
    country: 'PK',
    summary: '',
    eligibilityRules: '',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [s, a] = await Promise.all([
        fetchBenefitSchemes(150),
        fetchBenefitApplications(100),
      ])
      setSchemes(s)
      setApplications(a)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load benefits data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filteredSchemes = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return schemes.filter((s) => {
      if (country !== 'all' && String(s.country ?? '').toUpperCase() !== country) return false
      const active = s.active !== false
      const status = active ? 'published' : 'draft'
      if (statusFilter === 'published' && !active) return false
      if (statusFilter === 'draft' && active) return false
      if (!needle) return true
      return (
        String(s.title ?? s.name ?? '').toLowerCase().includes(needle) ||
        String(s.country ?? '').toLowerCase().includes(needle) ||
        String(s.summary ?? '').toLowerCase().includes(needle) ||
        status.includes(needle)
      )
    })
  }, [schemes, q, country, statusFilter])

  const filteredApplications = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return applications.filter((a) => {
      if (statusFilter !== 'all' && String(a.status ?? '') !== statusFilter) return false
      if (!needle) return true
      return (
        String(a.schemeId ?? '').toLowerCase().includes(needle) ||
        String(a.uid ?? '').toLowerCase().includes(needle) ||
        String(a.status ?? '').toLowerCase().includes(needle)
      )
    })
  }, [applications, q, statusFilter])

  const approved = applications.filter((a) => {
    const s = String(a.status ?? '').toLowerCase()
    return s === 'approved' || s === 'granted'
  }).length
  const pending = applications.filter((a) => {
    const s = String(a.status ?? '').toLowerCase()
    return s === 'pending' || s === 'submitted' || s === 'in_review'
  }).length

  const countries = useMemo(() => {
    return [...new Set(schemes.map((s) => String(s.country ?? '').toUpperCase()).filter(Boolean))].sort()
  }, [schemes])

  const toggleActive = async (id: string, active: boolean) => {
    setBusyId(id)
    try {
      await setBenefitSchemeActive(id, active)
      setSchemes((prev) => prev.map((s) => (s.id === id ? { ...s, active } : s)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const saveScheme = async () => {
    if (!schemeForm.title.trim()) {
      setError('Scheme title is required')
      return
    }
    try {
      await upsertBenefitScheme(null, {
        title: schemeForm.title.trim(),
        name: schemeForm.title.trim(),
        country: schemeForm.country.trim().toUpperCase() || 'PK',
        summary: schemeForm.summary.trim(),
        eligibilityRules: schemeForm.eligibilityRules.trim(),
        active: true,
      })
      setSchemeForm({ title: '', country: 'PK', summary: '', eligibilityRules: '' })
      await load()
      setTab('benefits')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save scheme')
    }
  }

  const showSchemes = tab === 'overview' || tab === 'benefits' || tab === 'categories'
  const showApps = tab === 'overview' || tab === 'applications'

  return (
    <div className="al-page">
      <div className="muted" style={{ fontSize: 12, marginBottom: 6 }}>
        Dashboard › Benefits
      </div>
      <PageHeader
        title="Benefits Management"
        subtitle="Manage government benefits, financial aid, allowances and support programs for persons with disabilities and senior citizens."
        primaryAction={{ label: 'Add Benefit', onClick: () => setTab('benefits') }}
        onExport={() => {
          const lines = [
            'Title,Country,Active,Summary',
            ...filteredSchemes.map((s) =>
              [s.title ?? s.name, s.country, s.active !== false, s.summary]
                .map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`)
                .join(','),
            ),
          ]
          const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = 'benefits.csv'
          a.click()
          URL.revokeObjectURL(url)
        }}
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
            label: 'Total Benefits',
            value: schemes.length.toLocaleString(),
            trend: '12% vs last month',
            tone: 'green',
            icon: <IconTags width={18} height={18} />,
          },
          {
            label: 'Total Applications',
            value: applications.length.toLocaleString(),
            trend: '28% vs last month',
            tone: 'purple',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Approved Applications',
            value: approved.toLocaleString(),
            trend: '25% vs last month',
            tone: 'blue',
            icon: <IconShieldCheck width={18} height={18} />,
          },
          {
            label: 'Pending Applications',
            value: pending.toLocaleString(),
            trend: '8% vs last month',
            trendDown: true,
            tone: 'pink',
            icon: <IconClock width={18} height={18} />,
          },
        ]}
      />

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search benefits (e.g. disability allowance)..."
        onReset={() => {
          setQ('')
          setCountry('all')
          setStatusFilter('all')
        }}
      >
        <select defaultValue="all">
          <option value="all">All Categories</option>
          <option value="financial">Financial Support</option>
          <option value="healthcare">Healthcare</option>
          <option value="employment">Employment</option>
        </select>
        <select value={country} onChange={(e) => setCountry(e.target.value)}>
          <option value="all">All Countries</option>
          {countries.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <select defaultValue="all">
          <option value="all">All Target Groups</option>
          <option value="pwd">Persons with Disabilities</option>
          <option value="seniors">Senior Citizens</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="all">All Status</option>
          <option value="published">Published</option>
          <option value="draft">Draft</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div>
          {showSchemes ? (
            <div className="al-table-card" style={{ marginBottom: 16 }}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '12px 14px',
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <strong>Benefits List</strong>
                <span className="muted" style={{ fontSize: 12 }}>
                  {loading ? 'Loading…' : `${filteredSchemes.length} benefits`}
                </span>
              </div>
              {loading ? (
                <p className="muted" style={{ padding: 20 }}>
                  Loading…
                </p>
              ) : filteredSchemes.length === 0 ? (
                <p className="muted" style={{ padding: 20 }}>
                  No benefits found.
                </p>
              ) : (
                <div className="table-wrap">
                  <table className="al-table">
                    <thead>
                      <tr>
                        <th style={{ width: 36 }}>
                          <input type="checkbox" aria-label="Select all" />
                        </th>
                        <th>Title</th>
                        <th>Category</th>
                        <th>Target Group</th>
                        <th>Country</th>
                        <th>Status</th>
                        <th>Applications</th>
                        <th>Last Updated</th>
                        <th />
                      </tr>
                    </thead>
                    <tbody>
                      {filteredSchemes.map((s) => {
                        const active = s.active !== false
                        const cat = String(s.category ?? 'Financial Support')
                        const apps = applications.filter(
                          (a) => String(a.schemeId ?? '') === s.id,
                        ).length
                        return (
                          <tr key={s.id}>
                            <td>
                              <input type="checkbox" aria-label={`Select ${s.id}`} />
                            </td>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <span className="al-activity-icon al-activity-icon--blue">
                                  <IconFileText width={14} height={14} />
                                </span>
                                <div>
                                  <strong>{String(s.title ?? s.name ?? '—')}</strong>
                                  <span className="muted" style={{ display: 'block', fontSize: 11 }}>
                                    {eligibilitySummary(s).slice(0, 48)}
                                  </span>
                                </div>
                              </div>
                            </td>
                            <td>
                              <StatusPill tone={catTone(cat)}>{cat}</StatusPill>
                            </td>
                            <td>
                              <StatusPill tone="purple">
                                {String(s.targetGroup ?? 'Persons with Disabilities')}
                              </StatusPill>
                            </td>
                            <td>{String(s.country ?? '—')}</td>
                            <td>
                              <StatusPill tone={statusTone(active ? 'published' : 'draft')}>
                                {active ? 'Published' : 'Draft'}
                              </StatusPill>
                            </td>
                            <td>{apps}</td>
                            <td>{formatWhen(s.updatedAt ?? s.createdAt)}</td>
                            <td>
                              <div style={{ display: 'flex', gap: 4 }}>
                                <button
                                  type="button"
                                  className="al-btn al-btn--outline"
                                  style={{ padding: '4px 8px', fontSize: 11 }}
                                  disabled={busyId === s.id}
                                  onClick={() => void toggleActive(s.id, !active)}
                                >
                                  {active ? 'Deactivate' : 'Activate'}
                                </button>
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
          ) : null}

          {tab === 'benefits' ? (
            <div className="al-table-card" style={{ padding: 16, marginBottom: 16 }}>
              <h3 style={{ marginTop: 0 }}>
                <IconPlus width={16} height={16} /> Add benefit
              </h3>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                  gap: 10,
                }}
              >
                <input
                  placeholder="Title"
                  value={schemeForm.title}
                  onChange={(e) => setSchemeForm((s) => ({ ...s, title: e.target.value }))}
                />
                <input
                  placeholder="Country"
                  value={schemeForm.country}
                  onChange={(e) => setSchemeForm((s) => ({ ...s, country: e.target.value }))}
                />
                <input
                  placeholder="Summary"
                  value={schemeForm.summary}
                  onChange={(e) => setSchemeForm((s) => ({ ...s, summary: e.target.value }))}
                  style={{ gridColumn: '1 / -1' }}
                />
                <input
                  placeholder="Eligibility rules"
                  value={schemeForm.eligibilityRules}
                  onChange={(e) =>
                    setSchemeForm((s) => ({ ...s, eligibilityRules: e.target.value }))
                  }
                  style={{ gridColumn: '1 / -1' }}
                />
                <button type="button" className="al-btn al-btn--primary" onClick={() => void saveScheme()}>
                  Save benefit
                </button>
              </div>
            </div>
          ) : null}

          {showApps ? (
            <div className="al-table-card">
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  padding: '12px 14px',
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <strong>Recent Applications</strong>
                <button
                  type="button"
                  className="al-btn al-btn--ghost"
                  onClick={() => setTab('applications')}
                >
                  View All →
                </button>
              </div>
              {filteredApplications.length === 0 ? (
                <p className="muted" style={{ padding: 20 }}>
                  No applications.
                </p>
              ) : (
                <div className="table-wrap">
                  <table className="al-table">
                    <thead>
                      <tr>
                        <th>Applicant</th>
                        <th>Benefit</th>
                        <th>Date</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredApplications.slice(0, tab === 'overview' ? 5 : 40).map((a) => {
                        const name = String(a.applicantName ?? a.uid ?? 'Applicant')
                        const scheme =
                          schemes.find((s) => s.id === String(a.schemeId ?? ''))?.title ??
                          a.schemeId ??
                          '—'
                        return (
                          <tr key={a.id}>
                            <td>
                              <div className="al-person">
                                <img src={avatarUrl(name)} alt="" />
                                <div>
                                  <strong>{name.slice(0, 20)}</strong>
                                </div>
                              </div>
                            </td>
                            <td>{String(scheme)}</td>
                            <td>{formatWhen(a.createdAt ?? a.updatedAt)}</td>
                            <td>
                              <StatusPill tone={statusTone(String(a.status ?? 'pending'))}>
                                {String(a.status ?? 'pending')}
                              </StatusPill>
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ) : null}

          {tab === 'overview' ? (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: 12,
                marginTop: 16,
              }}
            >
              <div className="al-table-card" style={{ padding: 16 }}>
                <strong>Benefits by Target Group</strong>
                <div style={{ marginTop: 12, display: 'grid', gap: 8 }}>
                  {[
                    { label: 'Persons with Disabilities', pct: 50 },
                    { label: 'Senior Citizens', pct: 23 },
                    { label: 'Caregivers', pct: 11 },
                    { label: 'Families', pct: 10 },
                    { label: 'Others', pct: 6 },
                  ].map((r) => (
                    <div key={r.label}>
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          fontSize: 12,
                          marginBottom: 4,
                        }}
                      >
                        <span>{r.label}</span>
                        <strong>{r.pct}%</strong>
                      </div>
                      <div
                        style={{
                          height: 6,
                          background: '#f1f5f9',
                          borderRadius: 999,
                          overflow: 'hidden',
                        }}
                      >
                        <div
                          style={{
                            width: `${r.pct}%`,
                            height: '100%',
                            background: '#2563eb',
                            borderRadius: 999,
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="al-table-card" style={{ padding: 16 }}>
                <strong>Monthly Applications</strong>
                <div className="al-mini-bars" style={{ height: 100, marginTop: 12 }}>
                  {[30, 40, 45, 50, 55, 60, 70, 75, 88].map((h, i) => (
                    <span key={i} style={{ height: `${h}%` }} />
                  ))}
                </div>
                <p style={{ margin: '10px 0 0', fontSize: 12, color: '#16a34a', fontWeight: 700 }}>
                  +28% Applications increased this month
                </p>
              </div>
            </div>
          ) : null}
        </div>

        <div className="al-widgets">
          <Widget title="Quick Actions">
            <div className="al-widget-list">
              {[
                { label: 'Add New Benefit', tab: 'benefits' },
                { label: 'Manage Categories', tab: 'categories' },
                { label: 'Manage Countries', tab: 'countries' },
                { label: 'Eligibility Rules', tab: 'eligibility' },
                { label: 'Import Benefits', tab: 'resources' },
                { label: 'Export Data', tab: 'reports' },
              ].map((a) => (
                <button
                  key={a.label}
                  type="button"
                  className="al-btn al-btn--outline"
                  style={{ width: '100%', justifyContent: 'flex-start' }}
                  onClick={() => setTab(a.tab)}
                >
                  {a.label}
                </button>
              ))}
            </div>
          </Widget>

          <Widget
            title="Top Categories"
            action={
              <button type="button" className="al-btn al-btn--ghost" onClick={() => setTab('categories')}>
                View All
              </button>
            }
          >
            <div className="al-cat-rank">
              {[
                { label: 'Financial Support', n: 32, tone: 'green' },
                { label: 'Healthcare', n: 18, tone: 'red' },
                { label: 'Education', n: 16, tone: 'blue' },
                { label: 'Employment', n: 14, tone: 'purple' },
                { label: 'Transport', n: 10, tone: 'orange' },
              ].map((c) => (
                <div key={c.label} className="al-cat-rank-row">
                  <div className="left">
                    <span className={`al-cat-rank-icon al-activity-icon--${c.tone === 'red' ? 'red' : c.tone === 'green' ? 'green' : c.tone === 'purple' ? 'purple' : c.tone === 'orange' ? 'orange' : 'blue'}`}>
                      <IconTags width={12} height={12} />
                    </span>
                    <span>{c.label}</span>
                  </div>
                  <strong>{c.n}</strong>
                </div>
              ))}
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}
