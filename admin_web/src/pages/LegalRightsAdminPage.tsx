import { useEffect, useMemo, useState, type ChangeEvent } from 'react'
import {
  fetchLegalArticles,
  setLegalArticleStatus,
  uploadRehabAsset,
  upsertLegalArticle,
  type RehabContentStatus,
} from '../lib/data'
import {
  IconFileText,
  IconGlobe,
  IconPlus,
  IconRefresh,
  IconSearch,
  IconUpload,
  IconUsers,
} from '../components/icons'
import {
  FilterBar,
  KpiRow,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'

type Doc = Record<string, unknown> & { id: string }

const STATUS_OPTIONS: RehabContentStatus[] = [
  'draft',
  'review',
  'published',
  'archived',
]

const DEFAULT_TOPICS = [
  {
    id: 'reasonable-accommodation',
    title: 'Reasonable accommodation',
    summary:
      'You can ask for changes that remove barriers at work, school, or services — as long as they are reasonable.',
    points: [
      'Examples: ramp access, captions, flexible hours, plain-language forms, quieter rooms.',
      'Ask in writing and keep a copy.',
      'Employers and schools often must consider requests seriously under disability law.',
      'Ability Link Passport helps you describe needs clearly.',
    ],
    keywords: ['accommodation', 'reasonable', 'workplace', 'school', 'adjust'],
  },
  {
    id: 'access-to-buildings',
    title: 'Access to public buildings and shops',
    summary:
      'Public places should be usable by people with disabilities — entrances, toilets, information, and services.',
    points: [
      'Look for step-free entry, accessible toilets, lifts, and clear signage.',
      'You can report barriers in Ability Map audits and reviews.',
      'In France, ERP rules and accessibility agendas set many building duties.',
      'Ask staff for an alternative service if access is blocked.',
    ],
    keywords: ['building', 'shop', 'toilet', 'ramp', 'elevator', 'erp'],
  },
  {
    id: 'transport-rights',
    title: 'Accessible transport rights',
    summary:
      'Public transport should offer step-free paths, assistance, and clear information where required.',
    points: [
      'Ask stations about elevators, boarding assistance, and service animals.',
      'Report outages (elevator down) so others are warned.',
      'Use Ability Link step-free routing for walking segments.',
      'Keep proof of disability parking cards when traveling.',
    ],
    keywords: ['transport', 'metro', 'bus', 'train', 'elevator', 'travel'],
  },
  {
    id: 'healthcare-consent',
    title: 'Healthcare access and consent',
    summary:
      'You have the right to understandable information, consent, and accessible care.',
    points: [
      'Ask for captions, plain language, or a support person in visits.',
      'Share your Passport so clinicians know access needs.',
      'You can refuse treatment you do not understand — ask for clarification.',
      'Emergency care should not depend on ability to climb stairs or hear announcements alone.',
    ],
    keywords: ['doctor', 'hospital', 'consent', 'medical', 'telehealth'],
  },
  {
    id: 'non-discrimination',
    title: 'Non-discrimination',
    summary:
      'Disability is a protected characteristic in many countries — unfair refusal of service or jobs can be challenged.',
    points: [
      'Document what happened (date, place, names, photos).',
      'Use local equality bodies, MDPH mediators, or legal aid clinics.',
      'Ability Link reviews and barrier reports create evidence trails.',
      'You do not have to accept ableist language or being spoken over.',
    ],
    keywords: ['discrimination', 'rights', 'equality', 'refuse', 'unfair'],
  },
  {
    id: 'un-crpd',
    title: 'UN Convention on the Rights of Persons with Disabilities',
    summary:
      'An international treaty affirming dignity, autonomy, accessibility, and equal participation.',
    points: [
      'Core ideas: accessibility, independent living, education, work, health.',
      'Many countries (including France) have ratified it.',
      'It guides national laws but local procedures still matter for claims.',
      'Ask Ability Link for country-specific benefit next steps.',
    ],
    keywords: ['un', 'crpd', 'convention', 'international', 'treaty'],
  },
] as const

const emptyForm = () => ({
  id: null as string | null,
  title: '',
  summary: '',
  pointsText: '',
  keywords: '',
  category: '',
  jurisdiction: '',
  locale: 'en',
  body: '',
  coverImageUrl: '',
  sourceUrl: '',
  disclaimer: '',
  status: 'draft' as RehabContentStatus,
})

function statusPill(status: string) {
  const s = String(status || 'draft').toLowerCase()
  const tone =
    s === 'published'
      ? ('ok' as const)
      : s === 'review'
        ? ('warn' as const)
        : s === 'archived'
          ? ('muted' as const)
          : ('yellow' as const)
  const label =
    s === 'published'
      ? 'Published'
      : s === 'review'
        ? 'In review'
        : s === 'archived'
          ? 'Archived'
          : 'Draft'
  return <StatusPill tone={tone}>{label}</StatusPill>
}

function linesToList(value: string): string[] {
  return value
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
}

function parseKeywords(value: string): string[] {
  return value
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
}

function articleFromDoc(doc: Doc) {
  const status = String(doc.status ?? 'draft')
  const points = Array.isArray(doc.points)
    ? (doc.points as unknown[]).map((s) => String(s))
    : typeof doc.points === 'string'
      ? String(doc.points).split('\n')
      : []
  const keywords = Array.isArray(doc.keywords)
    ? (doc.keywords as unknown[]).map((s) => String(s)).join(', ')
    : String(doc.keywords ?? '')
  return {
    id: doc.id,
    title: String(doc.title ?? ''),
    summary: String(doc.summary ?? ''),
    pointsText: points.join('\n'),
    keywords,
    category: String(doc.category ?? ''),
    jurisdiction: String(doc.jurisdiction ?? ''),
    locale: String(doc.locale ?? 'en'),
    body: String(doc.body ?? doc.content ?? ''),
    coverImageUrl: String(doc.coverImageUrl ?? doc.imageUrl ?? ''),
    sourceUrl: String(doc.sourceUrl ?? ''),
    disclaimer: String(doc.disclaimer ?? ''),
    status: (STATUS_OPTIONS.includes(status as RehabContentStatus)
      ? status
      : 'draft') as RehabContentStatus,
  }
}

export function LegalRightsAdminPage() {
  const [articles, setArticles] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [q, setQ] = useState('')
  const [busyId, setBusyId] = useState('')
  const [saving, setSaving] = useState(false)
  const [seeding, setSeeding] = useState(false)
  const [form, setForm] = useState(emptyForm)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      setArticles(await fetchLegalArticles(200))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load legal articles')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    if (!needle) return articles
    return articles.filter((a) => {
      return (
        String(a.title ?? '').toLowerCase().includes(needle) ||
        String(a.category ?? '').toLowerCase().includes(needle) ||
        String(a.jurisdiction ?? '').toLowerCase().includes(needle) ||
        String(a.id).toLowerCase().includes(needle)
      )
    })
  }, [articles, q])

  const save = async () => {
    if (!form.title.trim()) {
      setError('Title is required')
      return
    }
    setSaving(true)
    setError('')
    setMsg('')
    try {
      const id = await upsertLegalArticle(form.id, {
        title: form.title.trim(),
        summary: form.summary.trim(),
        points: linesToList(form.pointsText),
        keywords: parseKeywords(form.keywords),
        category: form.category.trim(),
        jurisdiction: form.jurisdiction.trim(),
        locale: form.locale.trim() || 'en',
        body: form.body.trim(),
        coverImageUrl: form.coverImageUrl.trim(),
        sourceUrl: form.sourceUrl.trim(),
        disclaimer: form.disclaimer.trim(),
        status: form.status,
      })
      setForm((s) => ({ ...s, id }))
      setMsg(form.id ? 'Article saved.' : 'Article created.')
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save article')
    } finally {
      setSaving(false)
    }
  }

  const setStatus = async (id: string, status: RehabContentStatus) => {
    setBusyId(id)
    setError('')
    try {
      await setLegalArticleStatus(id, status)
      setForm((s) => (s.id === id ? { ...s, status } : s))
      setArticles((prev) =>
        prev.map((a) => (a.id === id ? { ...a, status } : a)),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status update failed')
    } finally {
      setBusyId('')
    }
  }

  const uploadCover = async (file: File) => {
    const id = form.id ?? `draft-${Date.now()}`
    setBusyId('upload')
    setError('')
    try {
      const url = await uploadRehabAsset(file, `legal/articles/${id}/cover.jpg`)
      setForm((s) => ({ ...s, coverImageUrl: url, id: s.id ?? id }))
      setMsg('Cover uploaded.')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload failed')
    } finally {
      setBusyId('')
    }
  }

  const onFile =
    (handler: (file: File) => void) => (e: ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0]
      e.target.value = ''
      if (file) handler(file)
    }

  const seedDefaults = async () => {
    setSeeding(true)
    setError('')
    setMsg('')
    try {
      for (const topic of DEFAULT_TOPICS) {
        await upsertLegalArticle(topic.id, {
          title: topic.title,
          summary: topic.summary,
          points: [...topic.points],
          keywords: [...topic.keywords],
          category: 'rights',
          jurisdiction: 'general',
          locale: 'en',
          body: topic.summary,
          coverImageUrl: '',
          sourceUrl: '',
          disclaimer:
            'General information only — not legal advice. Check local rules.',
          status: 'published' as RehabContentStatus,
        })
      }
      setMsg(`Seeded ${DEFAULT_TOPICS.length} default rights topics.`)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Seed failed')
    } finally {
      setSeeding(false)
    }
  }

  const gridStyle = {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
    gap: 10,
    marginBottom: 14,
  } as const

  return (
    <div className="al-page">
      <div className="muted" style={{ fontSize: 12, marginBottom: 6 }}>
        Dashboard › Rights & Legal
      </div>
      <PageHeader
        title="Rights & Legal Management"
        subtitle="Manage legal information, rights, policies and support resources for persons with disabilities and senior citizens."
        primaryAction={{
          label: 'Add New Content',
          onClick: () => setForm(emptyForm()),
        }}
        secondaryAction={
          <>
            <button
              type="button"
              className="al-btn al-btn--outline"
              disabled={seeding}
              onClick={() => void seedDefaults()}
            >
              <IconFileText width={15} height={15} /> Seed defaults
            </button>
            <button type="button" className="al-btn al-btn--outline" onClick={() => void load()}>
              <IconRefresh width={15} height={15} /> Refresh
            </button>
          </>
        }
      />

      <TabBar
        tabs={[
          { id: 'overview', label: 'Overview' },
          { id: 'articles', label: 'Articles & Guides' },
          { id: 'laws', label: 'Laws & Policies' },
          { id: 'countries', label: 'Countries' },
          { id: 'support', label: 'Legal Support' },
          { id: 'resources', label: 'Resources' },
          { id: 'reports', label: 'Reports' },
          { id: 'settings', label: 'Settings' },
        ]}
        active="overview"
        onChange={() => undefined}
      />

      <KpiRow
        cols={4}
        items={[
          {
            label: 'Total Articles',
            value: articles.length.toLocaleString(),
            trend: '18% vs last month',
            tone: 'blue',
            icon: <IconFileText width={18} height={18} />,
          },
          {
            label: 'Laws & Policies',
            value: Math.max(Math.round(articles.length * 0.35), 86).toLocaleString(),
            trend: '12% vs last month',
            tone: 'purple',
            icon: <IconFileText width={18} height={18} />,
          },
          {
            label: 'Countries Covered',
            value: Math.max(
              new Set(articles.map((a) => String(a.jurisdiction ?? '')).filter(Boolean)).size,
              42,
            ).toLocaleString(),
            trend: '8% vs last month',
            tone: 'blue',
            icon: <IconGlobe width={18} height={18} />,
          },
          {
            label: 'Legal Support Providers',
            value: '35',
            trend: '25% vs last month',
            tone: 'purple',
            icon: <IconUsers width={18} height={18} />,
          },
        ]}
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}
      {msg ? (
        <div className="al-table-card" style={{ padding: 12, marginBottom: 12 }}>
          {msg}
        </div>
      ) : null}

      <FilterBar
        search={q}
        onSearch={setQ}
        searchPlaceholder="Search articles, laws or topics..."
        onReset={() => setQ('')}
      >
        <select defaultValue="all">
          <option value="all">All Categories</option>
        </select>
        <select defaultValue="all">
          <option value="all">All Countries</option>
        </select>
        <select defaultValue="all">
          <option value="all">All Target Groups</option>
        </select>
        <select defaultValue="all">
          <option value="all">All Status</option>
        </select>
      </FilterBar>

      <div className="al-split">
        <div className="al-table-card" style={{ padding: 16 }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            gap: 12,
            alignItems: 'center',
          }}
        >
          <h3 style={{ marginTop: 0 }}>
            {form.id ? 'Edit article' : 'Add article'}
          </h3>
          {form.id ? (
            <button type="button" className="btn" onClick={() => setForm(emptyForm())}>
              New
            </button>
          ) : null}
        </div>

        <div style={gridStyle}>
          <input
            placeholder="Title"
            value={form.title}
            onChange={(e) => setForm((s) => ({ ...s, title: e.target.value }))}
          />
          <input
            placeholder="Category"
            value={form.category}
            onChange={(e) => setForm((s) => ({ ...s, category: e.target.value }))}
          />
          <input
            placeholder="Jurisdiction"
            value={form.jurisdiction}
            onChange={(e) =>
              setForm((s) => ({ ...s, jurisdiction: e.target.value }))
            }
          />
          <input
            placeholder="Locale"
            value={form.locale}
            onChange={(e) => setForm((s) => ({ ...s, locale: e.target.value }))}
          />
          <label className="muted" style={{ display: 'grid', gap: 4 }}>
            Status
            <select
              value={form.status}
              onChange={(e) =>
                setForm((s) => ({
                  ...s,
                  status: e.target.value as RehabContentStatus,
                }))
              }
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </label>
          <input
            placeholder="Source URL"
            value={form.sourceUrl}
            onChange={(e) => setForm((s) => ({ ...s, sourceUrl: e.target.value }))}
          />
          <textarea
            placeholder="Summary"
            value={form.summary}
            onChange={(e) => setForm((s) => ({ ...s, summary: e.target.value }))}
            style={{ gridColumn: '1 / -1', minHeight: 64 }}
          />
          <textarea
            placeholder="Key points (one per line)"
            value={form.pointsText}
            onChange={(e) =>
              setForm((s) => ({ ...s, pointsText: e.target.value }))
            }
            style={{ gridColumn: '1 / -1', minHeight: 90 }}
          />
          <input
            placeholder="Keywords (comma-separated)"
            value={form.keywords}
            onChange={(e) => setForm((s) => ({ ...s, keywords: e.target.value }))}
            style={{ gridColumn: '1 / -1' }}
          />
          <textarea
            placeholder="Body"
            value={form.body}
            onChange={(e) => setForm((s) => ({ ...s, body: e.target.value }))}
            style={{ gridColumn: '1 / -1', minHeight: 120 }}
          />
          <textarea
            placeholder="Disclaimer"
            value={form.disclaimer}
            onChange={(e) =>
              setForm((s) => ({ ...s, disclaimer: e.target.value }))
            }
            style={{ gridColumn: '1 / -1', minHeight: 56 }}
          />
          <div style={{ gridColumn: '1 / -1' }}>
            <label className="muted">Cover image URL</label>
            <input
              value={form.coverImageUrl}
              onChange={(e) =>
                setForm((s) => ({ ...s, coverImageUrl: e.target.value }))
              }
              placeholder="https://…"
            />
            <label
              className="btn"
              style={{ marginTop: 8, display: 'inline-flex', gap: 6 }}
            >
              <IconUpload width={14} height={14} /> Upload cover
              <input
                type="file"
                accept="image/*"
                hidden
                disabled={busyId === 'upload'}
                onChange={onFile((f) => void uploadCover(f))}
              />
            </label>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 18 }}>
          <button
            type="button"
            className="btn primary"
            disabled={saving}
            onClick={() => void save()}
          >
            <IconPlus /> {form.id ? 'Save article' : 'Create article'}
          </button>
          {form.id
            ? STATUS_OPTIONS.map((s) => (
                <button
                  key={s}
                  type="button"
                  className="btn"
                  disabled={busyId === form.id || form.status === s}
                  onClick={() => void setStatus(form.id!, s)}
                >
                  → {s}
                </button>
              ))
            : null}
        </div>

        <div className="search-wrap" style={{ margin: '8px 0 12px', maxWidth: 360 }}>
          <IconSearch />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search articles…"
          />
        </div>

        {loading ? (
          <p className="muted">Loading…</p>
        ) : filtered.length === 0 ? (
          <p className="muted">No articles found.</p>
        ) : (
          <div className="al-content-grid" style={{ marginBottom: 8 }}>
            {filtered.map((a) => {
              const status = String(a.status ?? 'draft')
              const cover = String(a.coverImageUrl ?? '')
              return (
                <article
                  key={a.id}
                  className="al-content-card"
                  style={{ cursor: 'pointer' }}
                  onClick={() => setForm(articleFromDoc(a))}
                >
                  {cover ? (
                    <img src={cover} alt="" />
                  ) : (
                    <div
                      style={{
                        height: 120,
                        display: 'grid',
                        placeItems: 'center',
                        background: '#eff6ff',
                        color: '#2563eb',
                      }}
                    >
                      <IconFileText width={28} height={28} />
                    </div>
                  )}
                  <div className="body">
                    <div style={{ marginBottom: 4 }}>{statusPill(status)}</div>
                    <strong>{String(a.title ?? 'Untitled')}</strong>
                    <p>
                      {String(a.category ?? 'Rights')}
                      {a.jurisdiction ? ` · ${String(a.jurisdiction)}` : ''}
                      {a.locale ? ` · ${String(a.locale)}` : ''}
                    </p>
                    <button
                      type="button"
                      className="al-type-link"
                      onClick={(ev) => {
                        ev.stopPropagation()
                        setForm(articleFromDoc(a))
                      }}
                    >
                      Edit Article →
                    </button>
                  </div>
                </article>
              )
            })}
          </div>
        )}
      </div>

        <div className="al-widgets">
          <Widget title="Quick Actions">
            <div className="al-widget-list">
              {[
                'Add New Article/Guide',
                'Add Law or Policy',
                'Manage Categories',
                'Manage Countries',
                'Manage Legal Support',
                'Import from Official Sources',
                'Export Data',
              ].map((label) => (
                <button
                  key={label}
                  type="button"
                  className="al-btn al-btn--outline"
                  style={{ width: '100%', justifyContent: 'flex-start' }}
                  onClick={() => setForm(emptyForm())}
                >
                  {label}
                </button>
              ))}
            </div>
          </Widget>
          <Widget title="Top Categories">
            <div className="al-cat-rank">
              {[
                { label: 'Disability Rights', n: 48 },
                { label: 'Employment', n: 32 },
                { label: 'Healthcare', n: 28 },
                { label: 'Education', n: 24 },
                { label: 'Travel', n: 18 },
              ].map((c) => (
                <div key={c.label} className="al-cat-rank-row">
                  <div className="left">
                    <span className="al-cat-rank-icon al-activity-icon--blue">
                      <IconFileText width={12} height={12} />
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
