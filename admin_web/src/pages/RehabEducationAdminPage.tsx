import { useEffect, useMemo, useState } from 'react'
import {
  fetchRehabEducationHubRecommended,
  fetchRehabEducationHubTopics,
  fetchRehabEducationModules,
  setRehabEducationHubRecommendedActive,
  setRehabEducationHubTopicActive,
  setRehabEducationModuleActive,
  upsertRehabEducationHubRecommended,
  upsertRehabEducationHubTopic,
  upsertRehabEducationModule,
} from '../lib/data'
import { IconGraduation, IconPlus, IconRefresh, IconUsers } from '../components/icons'
import {
  FilterBar,
  PageHeader,
  TabBar,
  Widget,
} from '../components/PageChrome'

type Doc = Record<string, unknown> & { id: string }

const ROUTE_KEYS = [
  'mobility_movement',
  'strengthening',
  'back_spine',
  'joints_pain',
  'lower_body',
  'core',
  'full_body',
  'neurological',
  'breathing',
  'mental_health',
  'view_all',
]

export function RehabEducationAdminPage() {
  const [tab, setTab] = useState<'topics' | 'modules' | 'recommended'>('topics')
  const [topics, setTopics] = useState<Doc[]>([])
  const [modules, setModules] = useState<Doc[]>([])
  const [recommended, setRecommended] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')

  const [topicForm, setTopicForm] = useState({
    title: '',
    subtitle: '',
    routeKey: 'mobility_movement',
    sortOrder: '0',
  })
  const [moduleForm, setModuleForm] = useState({
    moduleKey: '',
    title: '',
    heroTitle: '',
    heroBody: '',
  })
  const [recForm, setRecForm] = useState({
    title: '',
    type: 'video',
    meta: '',
    imageUrl: '',
    category: 'exercises',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [t, m, r] = await Promise.all([
        fetchRehabEducationHubTopics(50),
        fetchRehabEducationModules(50),
        fetchRehabEducationHubRecommended(50),
      ])
      setTopics(t)
      setModules(m)
      setRecommended(r)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load rehab education data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    const list = tab === 'topics' ? topics : tab === 'modules' ? modules : recommended
    if (!needle) return list
    return list.filter((item) => JSON.stringify(item).toLowerCase().includes(needle))
  }, [tab, topics, modules, recommended, q])

  const saveTopic = async () => {
    if (!topicForm.title.trim()) {
      setError('Topic title is required')
      return
    }
    try {
      await upsertRehabEducationHubTopic(null, {
        title: topicForm.title.trim(),
        subtitle: topicForm.subtitle.trim(),
        routeKey: topicForm.routeKey,
        sortOrder: Number(topicForm.sortOrder) || 0,
        iconCodePoint: 0xe227,
        iconColor: 0xff7c5cfc,
        bgColor: 0xfff3f0ff,
        active: true,
      })
      setTopicForm({ title: '', subtitle: '', routeKey: 'mobility_movement', sortOrder: '0' })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save topic')
    }
  }

  const saveModule = async () => {
    if (!moduleForm.moduleKey.trim() || !moduleForm.title.trim()) {
      setError('Module key and title are required')
      return
    }
    try {
      await upsertRehabEducationModule(moduleForm.moduleKey.trim(), {
        moduleKey: moduleForm.moduleKey.trim(),
        title: moduleForm.title.trim(),
        heroTitle: moduleForm.heroTitle.trim(),
        heroBody: moduleForm.heroBody.trim(),
        accentColor: 0xff7c5cfc,
        active: true,
      })
      setModuleForm({ moduleKey: '', title: '', heroTitle: '', heroBody: '' })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save module')
    }
  }

  const saveRecommended = async () => {
    if (!recForm.title.trim()) {
      setError('Recommended title is required')
      return
    }
    try {
      await upsertRehabEducationHubRecommended(null, {
        title: recForm.title.trim(),
        type: recForm.type,
        meta: recForm.meta.trim(),
        imageUrl: recForm.imageUrl.trim(),
        category: recForm.category.trim() || 'exercises',
        active: true,
        sortOrder: recommended.length,
      })
      setRecForm({ title: '', type: 'video', meta: '', imageUrl: '', category: 'exercises' })
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save recommended item')
    }
  }

  const toggleTopic = async (id: string, active: boolean) => {
    setBusyId(id)
    try {
      await setRehabEducationHubTopicActive(id, active)
      setTopics((prev) => prev.map((t) => (t.id === id ? { ...t, active } : t)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const toggleModule = async (id: string, active: boolean) => {
    setBusyId(id)
    try {
      await setRehabEducationModuleActive(id, active)
      setModules((prev) => prev.map((m) => (m.id === id ? { ...m, active } : m)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  const toggleRec = async (id: string, active: boolean) => {
    setBusyId(id)
    try {
      await setRehabEducationHubRecommendedActive(id, active)
      setRecommended((prev) => prev.map((r) => (r.id === id ? { ...r, active } : r)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setBusyId('')
    }
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Programs"
        subtitle="Discover programs that create opportunities, build skills and support a more inclusive future."
        primaryAction={{ label: 'Add Program', onClick: () => setTab('topics') }}
        secondaryAction={
          <button type="button" className="al-btn al-btn--outline" onClick={() => void load()}>
            <IconRefresh width={15} height={15} /> Refresh
          </button>
        }
      />

      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      <div className="al-cat-scroll">
        {[
          { id: 'all', label: 'All Programs', bg: '#dbeafe', color: '#2563eb' },
          { id: 'skills', label: 'Skills & Training', bg: '#dcfce7', color: '#16a34a' },
          { id: 'employment', label: 'Employment', bg: '#ede9fe', color: '#7c3aed' },
          { id: 'health', label: 'Health & Wellness', bg: '#fee2e2', color: '#dc2626' },
          { id: 'education', label: 'Education', bg: '#dbeafe', color: '#2563eb' },
          { id: 'community', label: 'Community & Social', bg: '#ccfbf1', color: '#0d9488' },
        ].map((c) => (
          <button key={c.id} type="button" className={`al-cat-tile${c.id === 'all' ? ' active' : ''}`}>
            <div className="icon" style={{ background: c.bg, color: c.color }}>
              <IconGraduation width={16} height={16} />
            </div>
            <span>{c.label}</span>
          </button>
        ))}
      </div>

      <div className="al-hero-banner" style={{ marginBottom: 16 }}>
        <h2>Programs for Brighter Futures</h2>
        <p>More Opportunities. Stronger Together.</p>
        <button type="button" className="al-btn al-btn--primary" onClick={() => setTab('modules')}>
          Explore Programs →
        </button>
      </div>

      <TabBar
        tabs={[
          { id: 'topics', label: `Topics (${topics.length})` },
          { id: 'modules', label: `Modules (${modules.length})` },
          { id: 'recommended', label: `Recommended (${recommended.length})` },
        ]}
        active={tab}
        onChange={(id) => setTab(id as typeof tab)}
      />

      <div className="al-split">
        <div>
          <FilterBar search={q} onSearch={setQ} searchPlaceholder="Search programs, skills, locations..." onReset={() => setQ('')}>
            <select defaultValue="all"><option value="all">All Types</option></select>
            <select defaultValue="all"><option value="all">All Groups</option></select>
            <select defaultValue="all"><option value="all">All Locations</option></select>
          </FilterBar>

      {loading ? (
        <div className="card">Loading…</div>
      ) : (
        <>
          <div className="card table-card">
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  {tab === 'topics' ? (
                    <>
                      <th>Route</th>
                      <th>Order</th>
                    </>
                  ) : null}
                  {tab === 'modules' ? <th>Key</th> : null}
                  {tab === 'recommended' ? <th>Type</th> : null}
                  <th>Active</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((item) => (
                  <tr key={item.id}>
                    <td>{String(item.title ?? item.name ?? item.id)}</td>
                    {tab === 'topics' ? (
                      <>
                        <td>{String(item.routeKey ?? '—')}</td>
                        <td>{String(item.sortOrder ?? 0)}</td>
                      </>
                    ) : null}
                    {tab === 'modules' ? <td>{String(item.moduleKey ?? item.id)}</td> : null}
                    {tab === 'recommended' ? <td>{String(item.type ?? '—')}</td> : null}
                    <td>
                      <button
                        type="button"
                        className="btn small"
                        disabled={busyId === item.id}
                        onClick={() => {
                          const active = item.active !== false
                          if (tab === 'topics') void toggleTopic(item.id, !active)
                          else if (tab === 'modules') void toggleModule(item.id, !active)
                          else void toggleRec(item.id, !active)
                        }}
                      >
                        {item.active === false ? 'Enable' : 'Disable'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="card form-card">
            <h2>
              <IconPlus /> Add {tab === 'topics' ? 'Topic' : tab === 'modules' ? 'Module' : 'Recommended'}
            </h2>
            {tab === 'topics' ? (
              <div className="form-grid">
                <label>
                  Title
                  <input
                    value={topicForm.title}
                    onChange={(e) => setTopicForm({ ...topicForm, title: e.target.value })}
                  />
                </label>
                <label>
                  Subtitle
                  <input
                    value={topicForm.subtitle}
                    onChange={(e) => setTopicForm({ ...topicForm, subtitle: e.target.value })}
                  />
                </label>
                <label>
                  Route key
                  <select
                    value={topicForm.routeKey}
                    onChange={(e) => setTopicForm({ ...topicForm, routeKey: e.target.value })}
                  >
                    {ROUTE_KEYS.map((k) => (
                      <option key={k} value={k}>
                        {k}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  Sort order
                  <input
                    value={topicForm.sortOrder}
                    onChange={(e) => setTopicForm({ ...topicForm, sortOrder: e.target.value })}
                  />
                </label>
                <button type="button" className="btn primary" onClick={() => void saveTopic()}>
                  Save topic
                </button>
              </div>
            ) : null}
            {tab === 'modules' ? (
              <div className="form-grid">
                <label>
                  Module key (doc id)
                  <input
                    value={moduleForm.moduleKey}
                    onChange={(e) => setModuleForm({ ...moduleForm, moduleKey: e.target.value })}
                    placeholder="e.g. joints_pain"
                  />
                </label>
                <label>
                  Title
                  <input
                    value={moduleForm.title}
                    onChange={(e) => setModuleForm({ ...moduleForm, title: e.target.value })}
                  />
                </label>
                <label>
                  Hero title
                  <input
                    value={moduleForm.heroTitle}
                    onChange={(e) => setModuleForm({ ...moduleForm, heroTitle: e.target.value })}
                  />
                </label>
                <label>
                  Hero body
                  <textarea
                    value={moduleForm.heroBody}
                    onChange={(e) => setModuleForm({ ...moduleForm, heroBody: e.target.value })}
                  />
                </label>
                <button type="button" className="btn primary" onClick={() => void saveModule()}>
                  Save module
                </button>
              </div>
            ) : null}
            {tab === 'recommended' ? (
              <div className="form-grid">
                <label>
                  Title
                  <input
                    value={recForm.title}
                    onChange={(e) => setRecForm({ ...recForm, title: e.target.value })}
                  />
                </label>
                <label>
                  Type
                  <select
                    value={recForm.type}
                    onChange={(e) => setRecForm({ ...recForm, type: e.target.value })}
                  >
                    <option value="video">Video</option>
                    <option value="article">Article</option>
                    <option value="guide">Guide</option>
                  </select>
                </label>
                <label>
                  Meta
                  <input
                    value={recForm.meta}
                    onChange={(e) => setRecForm({ ...recForm, meta: e.target.value })}
                  />
                </label>
                <label>
                  Image URL
                  <input
                    value={recForm.imageUrl}
                    onChange={(e) => setRecForm({ ...recForm, imageUrl: e.target.value })}
                  />
                </label>
                <label>
                  Category filter
                  <input
                    value={recForm.category}
                    onChange={(e) => setRecForm({ ...recForm, category: e.target.value })}
                  />
                </label>
                <button type="button" className="btn primary" onClick={() => void saveRecommended()}>
                  Save recommended
                </button>
              </div>
            ) : null}
          </div>
        </>
      )}

        </div>
        <div className="al-widgets">
          <Widget title="Quick Filters">
            <div className="al-widget-list">
              {['Free Programs', 'Online Programs', 'In-Person', 'For Youth', 'For Adults', 'Certificate Provided'].map((f, i) => (
                <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
                  <input type="checkbox" defaultChecked={i === 0} /> {f}
                </label>
              ))}
            </div>
          </Widget>
          <div className="al-help-card">
            <IconUsers width={18} height={18} style={{ color: '#2563eb' }} />
            <strong>Need Help Choosing?</strong>
            <p>Get AI recommendations for the right program.</p>
            <button type="button" className="al-btn al-btn--primary">Get Recommendations →</button>
          </div>
          <Widget title="Popular Program Types">
            <div className="al-cat-rank">
              {[
                ['Skills & Training', 124],
                ['Employment Support', 86],
                ['Health & Wellness', 72],
                ['Education', 54],
              ].map(([label, n]) => (
                <div key={String(label)} className="al-cat-rank-row">
                  <div className="left"><span>{label}</span></div>
                  <strong>{n}</strong>
                </div>
              ))}
            </div>
          </Widget>
        </div>
      </div>
    </div>
  )
}

