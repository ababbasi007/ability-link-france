import { useEffect, useMemo, useState } from 'react'
import {
  fetchEducationProgramsAdmin,
  setEducationProgramVerified,
  upsertEducationProgramAdmin,
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
  IconBuilding,
  IconChart,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconFileText,
  IconGraduation,
  IconMore,
  IconStar,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const TABS = [
  { id: 'programs', label: 'All Programs' },
  { id: 'institutions', label: 'Institutions' },
  { id: 'online', label: 'Online Learning' },
  { id: 'scholarships', label: 'Scholarships' },
  { id: 'tools', label: 'Assistive Learning Tools' },
  { id: 'applications', label: 'Applications' },
  { id: 'reports', label: 'Reports' },
]

const DEMO_PROGRAMS: Doc[] = [
  {
    id: 'demo-p1',
    name: 'Digital Marketing Fundamentals',
    summary: 'Learn inclusive digital campaigns from scratch',
    institution: 'OpenLearn Academy',
    level: 'Certificate',
    mode: 'Online',
    accessibility: 'Accessible',
    enrolled: 842,
    verified: true,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=120&q=80',
  },
  {
    id: 'demo-p2',
    name: 'Assistive Technology Basics',
    summary: 'Hands-on intro to everyday AT tools',
    institution: 'Ability Institute',
    level: 'Short Course',
    mode: 'Blended',
    accessibility: 'Screen Reader',
    enrolled: 516,
    verified: true,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=120&q=80',
  },
  {
    id: 'demo-p3',
    name: 'Inclusive Classroom Teaching',
    summary: 'Strategies for diverse learners',
    institution: 'EduAccess University',
    level: 'Professional',
    mode: 'On campus',
    accessibility: 'Captions',
    enrolled: 294,
    verified: false,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=120&q=80',
  },
  {
    id: 'demo-p4',
    name: 'Sign Language Communication',
    summary: 'Beginner to conversational fluency',
    institution: 'HearWell College',
    level: 'Certificate',
    mode: 'Online',
    accessibility: 'Easy Read',
    enrolled: 671,
    verified: true,
    kind: 'course',
    online: true,
    thumb: 'https://images.unsplash.com/photo-1577896851231-70ef042ee908?w=120&q=80',
  },
  {
    id: 'demo-p5',
    name: 'Workplace Accessibility Audit',
    summary: 'Assess and improve workplace inclusion',
    institution: 'Inclusive Brands U',
    level: 'Short Course',
    mode: 'Blended',
    accessibility: 'Accessible',
    enrolled: 188,
    verified: true,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=120&q=80',
  },
  {
    id: 'demo-p6',
    name: 'Scholarship: STEM for All',
    summary: 'Full tuition support for STEM learners',
    institution: 'Global Access Fund',
    level: 'Scholarship',
    mode: 'Online',
    accessibility: 'Screen Reader',
    enrolled: 120,
    verified: true,
    kind: 'scholarship',
    thumb: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=120&q=80',
  },
  {
    id: 'demo-p7',
    name: 'Life Skills & Independence',
    summary: 'Daily living skills for young adults',
    institution: 'Ability Institute',
    level: 'Short Course',
    mode: 'On campus',
    accessibility: 'Easy Read',
    enrolled: 403,
    verified: false,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=120&q=80',
  },
  {
    id: 'demo-p8',
    name: 'Healthcare Assistant Pathway',
    summary: 'Entry pathway into care careers',
    institution: 'CareConnect Academy',
    level: 'Professional',
    mode: 'Blended',
    accessibility: 'Captions',
    enrolled: 356,
    verified: true,
    kind: 'course',
    thumb: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=120&q=80',
  },
  {
    id: 'demo-p9',
    name: 'Web Accessibility (WCAG)',
    summary: 'Build compliant digital experiences',
    institution: 'Tech4All School',
    level: 'Certificate',
    mode: 'Online',
    accessibility: 'Screen Reader',
    enrolled: 912,
    verified: true,
    kind: 'course',
    online: true,
    thumb: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=120&q=80',
  },
  {
    id: 'demo-p10',
    name: 'Parent & Caregiver Support',
    summary: 'Guidance for supporting learners at home',
    institution: 'Family Bridge',
    level: 'Short Course',
    mode: 'Online',
    accessibility: 'Accessible',
    enrolled: 245,
    verified: true,
    kind: 'course',
    online: true,
    thumb: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=120&q=80',
  },
]

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

function levelTone(level: string): 'info' | 'purple' | 'pink' | 'ok' | 'muted' {
  const l = level.toLowerCase()
  if (l.includes('cert')) return 'info'
  if (l.includes('short')) return 'purple'
  if (l.includes('pro')) return 'pink'
  if (l.includes('scholar')) return 'ok'
  return 'muted'
}

function accessTone(label: string): 'ok' | 'info' | 'purple' | 'pink' {
  const a = label.toLowerCase()
  if (a.includes('screen')) return 'info'
  if (a.includes('caption')) return 'purple'
  if (a.includes('easy')) return 'pink'
  return 'ok'
}

function avatarUrl(seed: string) {
  return `https://api.dicebear.com/7.x/initials/svg?seed=${encodeURIComponent(seed)}`
}

function programAccess(p: Doc): string {
  if (typeof p.accessibility === 'string' && p.accessibility) return p.accessibility
  const feats = p.accessFeatures
  if (Array.isArray(feats) && feats.length) return String(feats[0])
  return 'Accessible'
}

export function EducationProgramsAdminPage() {
  const [programs, setPrograms] = useState<Doc[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [tab, setTab] = useState('programs')
  const [level, setLevel] = useState('all')
  const [category, setCategory] = useState('all')
  const [mode, setMode] = useState('all')
  const [accessibility, setAccessibility] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [pageSize, setPageSize] = useState(10)
  const [page, setPage] = useState(0)
  const [form, setForm] = useState({
    name: '',
    kind: 'course',
    institution: '',
    city: '',
    summary: '',
    level: 'beginner',
    mode: 'online',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const rows = await fetchEducationProgramsAdmin(200)
      if (!rows.length) {
        setPrograms(DEMO_PROGRAMS)
        setUsingDemo(true)
      } else {
        setPrograms(rows)
        setUsingDemo(false)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load education programs')
      setPrograms(DEMO_PROGRAMS)
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
  }, [tab, q, level, category, mode, accessibility, pageSize])

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return programs.filter((p) => {
      const kind = String(p.kind ?? '').toLowerCase()
      const pMode = String(p.mode ?? (p.online ? 'online' : '')).toLowerCase()
      const pLevel = String(p.level ?? '').toLowerCase()
      const access = programAccess(p).toLowerCase()
      if (tab === 'scholarships' && !kind.includes('scholarship')) return false
      if (tab === 'online' && pMode !== 'online' && !p.online) return false
      if (tab === 'tools') return kind.includes('tool') || kind.includes('assistive')
      if (tab === 'applications' || tab === 'reports') return false
      if (level !== 'all' && !pLevel.includes(level)) return false
      if (mode !== 'all' && !pMode.includes(mode.replace('-', ' ')) && pMode !== mode) return false
      if (category !== 'all' && kind !== category) return false
      if (accessibility !== 'all') {
        if (accessibility === 'screen' && !access.includes('screen')) return false
        if (accessibility === 'captions' && !access.includes('caption')) return false
        if (accessibility === 'accessible' && !access.includes('accessible')) return false
        if (accessibility === 'easy' && !access.includes('easy')) return false
      }
      if (!needle) return true
      return (
        String(p.name ?? p.title ?? '').toLowerCase().includes(needle) ||
        String(p.institution ?? '').toLowerCase().includes(needle) ||
        kind.includes(needle)
      )
    })
  }, [programs, q, tab, level, mode, category, accessibility])

  const institutions = useMemo(() => {
    const map = new Map<string, number>()
    for (const p of programs) {
      const name = String(p.institution ?? 'Unknown')
      map.set(name, (map.get(name) ?? 0) + 1)
    }
    return [...map.entries()].sort((a, b) => b[1] - a[1])
  }, [programs])

  const kpis = useMemo(() => {
    const verified = programs.filter((p) => Boolean(p.verified)).length
    const enrolled = programs.reduce(
      (sum, p) => sum + Number(p.enrolled ?? p.learners ?? 0),
      0,
    )
    return {
      total: programs.length,
      institutions: institutions.length,
      enrolled,
      completion: programs.length ? Math.min(98, 60 + Math.round((verified / programs.length) * 20)) : 0,
    }
  }, [programs, institutions])

  const paged = useMemo(() => {
    const start = page * pageSize
    return filtered.slice(start, start + pageSize)
  }, [filtered, page, pageSize])

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize) || 1)
  const showingFrom = filtered.length ? page * pageSize + 1 : 0
  const showingTo = Math.min((page + 1) * pageSize, filtered.length)
  const displayTotal = usingDemo ? 1286 : filtered.length

  const save = async () => {
    if (!form.name.trim()) {
      setError('Program name is required')
      return
    }
    if (usingDemo) {
      const id = `demo-${Date.now()}`
      setPrograms((prev) => [
        {
          id,
          name: form.name.trim(),
          kind: form.kind,
          institution: form.institution.trim() || 'New Institution',
          summary: form.summary.trim(),
          level: form.level,
          mode: form.mode,
          verified: false,
          enrolled: 0,
          accessibility: 'Accessible',
        },
        ...prev,
      ])
      setShowForm(false)
      return
    }
    try {
      const id = form.name.trim().toLowerCase().replace(/\s+/g, '_').slice(0, 48)
      await upsertEducationProgramAdmin(id, {
        name: form.name.trim(),
        kind: form.kind,
        institution: form.institution.trim(),
        city: form.city.trim(),
        summary: form.summary.trim(),
        description: form.summary.trim(),
        level: form.level,
        mode: form.mode,
        accessFeatures: [],
        inclusiveFor: [],
        verified: false,
        online: form.mode === 'online' || form.mode === 'hybrid',
      })
      setForm({
        name: '',
        kind: 'course',
        institution: '',
        city: '',
        summary: '',
        level: 'beginner',
        mode: 'online',
      })
      setShowForm(false)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save program')
    }
  }

  const toggleVerified = async (id: string, verified: boolean) => {
    if (usingDemo || id.startsWith('demo-')) {
      setPrograms((prev) => prev.map((p) => (p.id === id ? { ...p, verified } : p)))
      return
    }
    setBusyId(id)
    try {
      await setEducationProgramVerified(id, verified)
      setPrograms((prev) => prev.map((p) => (p.id === id ? { ...p, verified } : p)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Education"
        subtitle="Manage educational opportunities, courses and learning resources for an inclusive future."
        onExport={() => {
          const lines = [
            'Name,Kind,Institution,City,Verified',
            ...filtered.map((p) =>
              [p.name ?? p.title, p.kind, p.institution, p.city, p.verified]
                .map((v) => `"${String(v ?? '').replace(/"/g, '""')}"`)
                .join(','),
            ),
          ]
          const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = 'education-programs.csv'
          a.click()
          URL.revokeObjectURL(url)
        }}
        primaryAction={{ label: 'Add Program', onClick: () => setShowForm(true) }}
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
            label: 'Total Programs',
            value: kpiDisplay(kpis.total, 1286),
            trend: '22% vs last month',
            tone: 'blue',
            icon: <IconGraduation width={18} height={18} />,
          },
          {
            label: 'Active Institutions',
            value: kpiDisplay(kpis.institutions, 342),
            trend: '18% vs last month',
            tone: 'green',
            icon: <IconBuilding width={18} height={18} />,
          },
          {
            label: 'Enrolled Learners',
            value: kpiDisplay(kpis.enrolled, 5892),
            trend: '31% vs last month',
            tone: 'yellow',
            icon: <IconUsers width={18} height={18} />,
          },
          {
            label: 'Completion Rate',
            value: usingDemo || !kpis.total ? '78%' : `${kpis.completion}%`,
            trend: '6% vs last month',
            tone: 'pink',
            icon: <IconStar width={18} height={18} />,
          },
        ]}
      />

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search by program name, institution or keyword..."
        onReset={() => {
          setQ('')
          setLevel('all')
          setCategory('all')
          setMode('all')
          setAccessibility('all')
        }}
      >
        <select value={level} onChange={(e) => setLevel(e.target.value)}>
          <option value="all">Education Level</option>
          <option value="certificate">Certificate</option>
          <option value="short">Short Course</option>
          <option value="professional">Professional</option>
          <option value="beginner">Beginner</option>
        </select>
        <select value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="all">Category</option>
          <option value="course">Course</option>
          <option value="school">School</option>
          <option value="university">University</option>
          <option value="scholarship">Scholarship</option>
        </select>
        <select value={mode} onChange={(e) => setMode(e.target.value)}>
          <option value="all">Mode</option>
          <option value="online">Online</option>
          <option value="blended">Blended</option>
          <option value="hybrid">Hybrid</option>
          <option value="on-campus">On campus</option>
        </select>
        <select value={accessibility} onChange={(e) => setAccessibility(e.target.value)}>
          <option value="all">Accessibility</option>
          <option value="accessible">Accessible</option>
          <option value="screen">Screen Reader</option>
          <option value="captions">Captions</option>
          <option value="easy">Easy Read</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>
              Loading…
            </p>
          ) : tab === 'institutions' ? (
            <div className="table-wrap">
              <table className="al-table">
                <thead>
                  <tr>
                    <th>Institution</th>
                    <th>Programs</th>
                  </tr>
                </thead>
                <tbody>
                  {institutions.map(([name, count]) => (
                    <tr key={name}>
                      <td>
                        <div className="al-person">
                          <img src={avatarUrl(name)} alt="" />
                          <div>
                            <strong>{name}</strong>
                          </div>
                        </div>
                      </td>
                      <td>{count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : tab === 'applications' || tab === 'reports' ? (
            <p className="muted" style={{ padding: 20 }}>
              {tab === 'applications'
                ? 'Program applications will appear here as learners apply.'
                : 'Education reports are available from Quick Actions → View Reports.'}
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
                      <th>Program / Course</th>
                      <th>Institution</th>
                      <th>Level</th>
                      <th>Mode</th>
                      <th>Accessibility</th>
                      <th>Enrolled</th>
                      <th>Status</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {paged.map((p) => {
                      const name = String(p.name ?? p.title ?? p.id)
                      const inst = String(p.institution ?? '—')
                      const pLevel = String(p.level ?? p.kind ?? 'Course')
                      const pMode = String(p.mode ?? (p.online ? 'Online' : 'Blended'))
                      const enrolled = Number(p.enrolled ?? p.learners ?? 0)
                      const verified = Boolean(p.verified)
                      const access = programAccess(p)
                      const thumb = String(p.thumb ?? p.imageUrl ?? '')
                      return (
                        <tr key={p.id}>
                          <td>
                            <input type="checkbox" aria-label={`Select ${name}`} />
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                              <div
                                className="al-place-thumb"
                                style={{ width: 44, height: 44, borderRadius: 8 }}
                              >
                                {thumb ? (
                                  <img src={thumb} alt="" />
                                ) : (
                                  <IconGraduation width={18} height={18} />
                                )}
                              </div>
                              <div>
                                <strong>{name}</strong>
                                <span className="muted" style={{ display: 'block', fontSize: 12 }}>
                                  {String(p.summary ?? p.description ?? p.kind ?? '').slice(0, 60) ||
                                    'Inclusive learning program'}
                                </span>
                              </div>
                            </div>
                          </td>
                          <td>
                            <div className="al-person">
                              <img src={avatarUrl(inst)} alt="" />
                              <div>
                                <strong>{inst}</strong>
                              </div>
                            </div>
                          </td>
                          <td>
                            <StatusPill tone={levelTone(pLevel)}>{pLevel}</StatusPill>
                          </td>
                          <td>
                            <span
                              className="al-type-link"
                              style={{
                                color: pMode.toLowerCase().includes('blend')
                                  ? '#ca8a04'
                                  : pMode.toLowerCase().includes('campus')
                                    ? '#0f172a'
                                    : undefined,
                              }}
                            >
                              {pMode}
                            </span>
                          </td>
                          <td>
                            <StatusPill tone={accessTone(access)}>{access}</StatusPill>
                          </td>
                          <td>{enrolled || '—'}</td>
                          <td>
                            <StatusPill tone={verified ? 'ok' : 'warn'}>
                              {verified ? 'Published' : 'Draft'}
                            </StatusPill>
                          </td>
                          <td>
                            <div style={{ display: 'flex', gap: 4 }}>
                              <button
                                type="button"
                                className="al-btn al-btn--ghost"
                                style={{ padding: 4, fontSize: 11 }}
                                disabled={busyId === p.id}
                                onClick={() => void toggleVerified(p.id, !verified)}
                              >
                                {verified ? 'Unverify' : 'Verify'}
                              </button>
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
              {!paged.length ? (
                <div className="empty" style={{ padding: 20 }}>
                  No programs match your filters.
                </div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing {showingFrom} to {showingTo} of {displayTotal.toLocaleString()} programs
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
                          129
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
          )}

          {showForm ? (
            <div style={{ padding: 16, borderTop: '1px solid #e2e8f0' }}>
              <h3 style={{ marginTop: 0 }}>Add program</h3>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                  gap: 10,
                }}
              >
                <input
                  placeholder="Name"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
                <select
                  value={form.kind}
                  onChange={(e) => setForm({ ...form, kind: e.target.value })}
                >
                  <option value="course">Course</option>
                  <option value="school">School</option>
                  <option value="university">University</option>
                  <option value="scholarship">Scholarship</option>
                  <option value="special_ed">Special education</option>
                </select>
                <input
                  placeholder="Institution"
                  value={form.institution}
                  onChange={(e) => setForm({ ...form, institution: e.target.value })}
                />
                <input
                  placeholder="City"
                  value={form.city}
                  onChange={(e) => setForm({ ...form, city: e.target.value })}
                />
                <input
                  placeholder="Level"
                  value={form.level}
                  onChange={(e) => setForm({ ...form, level: e.target.value })}
                />
                <select
                  value={form.mode}
                  onChange={(e) => setForm({ ...form, mode: e.target.value })}
                >
                  <option value="online">Online</option>
                  <option value="hybrid">Hybrid</option>
                  <option value="on-campus">On campus</option>
                </select>
                <textarea
                  placeholder="Summary"
                  value={form.summary}
                  onChange={(e) => setForm({ ...form, summary: e.target.value })}
                  style={{ gridColumn: '1 / -1', minHeight: 70 }}
                />
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
                <button type="button" className="al-btn al-btn--primary" onClick={() => void save()}>
                  Save program
                </button>
                <button
                  type="button"
                  className="al-btn al-btn--outline"
                  onClick={() => setShowForm(false)}
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : null}
        </div>

        <div className="al-widgets">
          <div className="al-featured-prog">
            <div className="al-featured-prog-label">Featured Program</div>
            <img
              src="https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=600&q=80"
              alt="Student using a laptop"
            />
            <div className="body">
              <strong>Skills for a Brighter Tomorrow</strong>
              <p>Inclusive online learning for every ability.</p>
              <button type="button" className="al-btn al-btn--primary">
                View Program
              </button>
            </div>
          </div>

          <Widget
            title="Education by Category"
            action={
              <button type="button" className="al-btn al-btn--ghost">
                View All
              </button>
            }
          >
            <div className="al-cat-rank">
              {[
                ['Technology & IT', 284, '#dbeafe', '#2563eb'],
                ['Healthcare', 176, '#dcfce7', '#16a34a'],
                ['Business', 142, '#ffedd5', '#ea580c'],
                ['Languages', 98, '#ede9fe', '#7c3aed'],
                ['Life Skills', 76, '#fce7f3', '#db2777'],
              ].map(([label, count, bg, color]) => (
                <div key={String(label)} className="al-cat-rank-row">
                  <span className="left">
                    <span
                      className="al-cat-rank-icon"
                      style={{ background: String(bg), color: String(color) }}
                    >
                      <IconGraduation width={14} height={14} />
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
                text: 'New program submitted',
                ago: '2 hours ago',
                tone: 'blue' as const,
                icon: <IconFileText width={14} height={14} />,
              },
              {
                text: 'Application approved: Sara Khan',
                ago: '4 hours ago',
                tone: 'green' as const,
                icon: <IconCheckCircle width={14} height={14} />,
              },
              {
                text: 'New institution registered',
                ago: '6 hours ago',
                tone: 'purple' as const,
                icon: <IconBuilding width={14} height={14} />,
              },
              {
                text: 'Program published: WCAG Essentials',
                ago: '8 hours ago',
                tone: 'orange' as const,
                icon: <IconGraduation width={14} height={14} />,
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
              <button
                type="button"
                className="al-btn al-btn--primary"
                onClick={() => setShowForm(true)}
              >
                + Add Program
              </button>
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setTab('institutions')}
              >
                Add Institution
              </button>
              <button
                type="button"
                className="al-btn al-btn--outline"
                onClick={() => setTab('applications')}
              >
                Manage Applications
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
