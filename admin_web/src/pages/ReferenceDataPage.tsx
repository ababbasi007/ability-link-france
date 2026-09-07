import { useEffect, useMemo, useState } from 'react'
import {
  fetchExpansionPartners,
  fetchGovernmentOffices,
  fetchHealthOrgs,
  fetchMarkets,
  fetchOpenDataBundles,
  setExpansionPartnerStatus,
  upsertGovernmentOffice,
  upsertMarket,
} from '../lib/data'
import { cell, formatWhen, type OpsDoc } from '../lib/opsUtils'
import {
  IconAccessibility,
  IconBriefcase,
  IconChart,
  IconClock,
  IconFileText,
  IconGraduation,
  IconHeart,
  IconPlus,
  IconRefresh,
  IconStar,
  IconUsers,
} from '../components/icons'
import {
  DetailPanel,
  FilterBar,
  PageHeader,
  StatusPill,
  TabBar,
  Widget,
} from '../components/PageChrome'

const ASSESS_CATS = [
  { id: 'all', label: 'All Assessments', bg: '#dbeafe', color: '#2563eb', icon: 'grid' },
  { id: 'function', label: 'Disability & Function', bg: '#dcfce7', color: '#16a34a', icon: 'access' },
  { id: 'health', label: 'Health & Wellness', bg: '#fee2e2', color: '#dc2626', icon: 'heart' },
  { id: 'skills', label: 'Skills & Education', bg: '#ccfbf1', color: '#0d9488', icon: 'grad' },
  { id: 'employment', label: 'Employment Readiness', bg: '#ede9fe', color: '#7c3aed', icon: 'brief' },
  { id: 'access', label: 'Accessibility Needs', bg: '#dbeafe', color: '#2563eb', icon: 'access' },
  { id: 'mental', label: 'Mental Wellbeing', bg: '#fce7f3', color: '#db2777', icon: 'heart' },
  { id: 'caregiver', label: 'Caregiver Needs', bg: '#ffedd5', color: '#ea580c', icon: 'users' },
  { id: 'rights', label: 'Rights & Benefits', bg: '#e0e7ff', color: '#4f46e5', icon: 'file' },
] as const

const ASSESS_CARDS = [
  {
    id: 'functional',
    cat: 'function',
    title: 'Functional Ability Assessment',
    description: 'Evaluate mobility, self-care and daily living skills.',
    duration: '10–15 minutes',
    bg: '#dbeafe',
    color: '#2563eb',
    icon: 'access' as const,
  },
  {
    id: 'health',
    cat: 'health',
    title: 'Health & Wellness Check',
    description: 'Understand your physical health and wellness needs.',
    duration: '8–12 minutes',
    bg: '#fee2e2',
    color: '#dc2626',
    icon: 'heart' as const,
  },
  {
    id: 'skills',
    cat: 'skills',
    title: 'Skills & Learning Assessment',
    description: 'Identify education and training opportunities.',
    duration: '12–18 minutes',
    bg: '#ccfbf1',
    color: '#0d9488',
    icon: 'grad' as const,
  },
  {
    id: 'employment',
    cat: 'employment',
    title: 'Employment Readiness Test',
    description: 'Assess job readiness and workplace support needs.',
    duration: '15–20 minutes',
    bg: '#ede9fe',
    color: '#7c3aed',
    icon: 'brief' as const,
  },
  {
    id: 'access',
    cat: 'access',
    title: 'Accessibility Needs Survey',
    description: 'Map physical, digital and communication access needs.',
    duration: '10 minutes',
    bg: '#dbeafe',
    color: '#2563eb',
    icon: 'access' as const,
  },
  {
    id: 'mental',
    cat: 'mental',
    title: 'Mental Wellbeing Screen',
    description: 'Check stress, mood and emotional support needs.',
    duration: '8–10 minutes',
    bg: '#fce7f3',
    color: '#db2777',
    icon: 'heart' as const,
  },
  {
    id: 'caregiver',
    cat: 'caregiver',
    title: 'Caregiver Support Assessment',
    description: 'Understand caregiver burden and support options.',
    duration: '10–15 minutes',
    bg: '#ffedd5',
    color: '#ea580c',
    icon: 'users' as const,
  },
  {
    id: 'rights',
    cat: 'rights',
    title: 'Rights & Benefits Finder',
    description: 'Discover benefits and legal supports you may qualify for.',
    duration: '12 minutes',
    bg: '#e0e7ff',
    color: '#4f46e5',
    icon: 'file' as const,
  },
]

function catIcon(kind: string, color: string) {
  const props = { width: 18, height: 18, style: { color } as const }
  switch (kind) {
    case 'heart':
      return <IconHeart {...props} />
    case 'grad':
      return <IconGraduation {...props} />
    case 'brief':
      return <IconBriefcase {...props} />
    case 'users':
      return <IconUsers {...props} />
    case 'file':
      return <IconFileText {...props} />
    case 'access':
      return <IconAccessibility {...props} />
    default:
      return <IconStar {...props} />
  }
}

export function ReferenceDataPage() {
  const [view, setView] = useState<'browse' | 'manage'>('browse')
  const [cat, setCat] = useState('all')
  const [tab, setTab] = useState<'offices' | 'markets' | 'healthOrgs' | 'partners' | 'openData'>('offices')
  const [offices, setOffices] = useState<OpsDoc[]>([])
  const [markets, setMarkets] = useState<OpsDoc[]>([])
  const [healthOrgs, setHealthOrgs] = useState<OpsDoc[]>([])
  const [partners, setPartners] = useState<OpsDoc[]>([])
  const [openData, setOpenData] = useState<OpsDoc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [q, setQ] = useState('')
  const [detailOpen, setDetailOpen] = useState(false)
  const [selectedAssess, setSelectedAssess] = useState<(typeof ASSESS_CARDS)[number] | null>(null)
  const [officeForm, setOfficeForm] = useState({ name: '', agency: '', city: '', phone: '' })
  const [marketForm, setMarketForm] = useState({
    code: 'PK',
    name: 'Pakistan',
    currency: 'PKR',
    emergencyNumber: '1122',
  })

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [o, m, h, p, d] = await Promise.all([
        fetchGovernmentOffices(200),
        fetchMarkets(50),
        fetchHealthOrgs(200),
        fetchExpansionPartners(200),
        fetchOpenDataBundles(20),
      ])
      setOffices(o)
      setMarkets(m)
      setHealthOrgs(h)
      setPartners(p)
      setOpenData(d)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load reference data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const rows = useMemo(() => {
    const list =
      tab === 'offices'
        ? offices
        : tab === 'markets'
          ? markets
          : tab === 'healthOrgs'
            ? healthOrgs
            : tab === 'partners'
              ? partners
              : openData
    const needle = q.trim().toLowerCase()
    if (!needle) return list
    return list.filter((r) => JSON.stringify(r).toLowerCase().includes(needle))
  }, [tab, offices, markets, healthOrgs, partners, openData, q])

  const filteredCards = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return ASSESS_CARDS.filter((c) => {
      if (cat !== 'all' && c.cat !== cat) return false
      if (!needle) return true
      return (
        c.title.toLowerCase().includes(needle) ||
        c.description.toLowerCase().includes(needle)
      )
    })
  }, [cat, q])

  const openCard = (card: (typeof ASSESS_CARDS)[number]) => {
    setSelectedAssess(card)
    setDetailOpen(true)
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Assessments"
        subtitle="Understand your needs, discover opportunities and get personalized recommendations."
        primaryAction={{
          label: 'Start New Assessment',
          onClick: () => openCard(ASSESS_CARDS[0]),
        }}
        secondaryAction={
          <>
            <button
              type="button"
              className={`al-btn ${view === 'manage' ? 'al-btn--primary' : 'al-btn--outline'}`}
              onClick={() => setView((v) => (v === 'browse' ? 'manage' : 'browse'))}
            >
              {view === 'browse' ? 'Manage Data' : 'Browse Assessments'}
            </button>
            <button type="button" className="al-btn al-btn--outline" onClick={() => void load()}>
              <IconRefresh width={15} height={15} /> Refresh
            </button>
          </>
        }
      />

      {error ? (
        <div className="error" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      {view === 'browse' ? (
        <>
          <div className="al-cat-scroll">
            {ASSESS_CATS.map((c) => (
              <button
                key={c.id}
                type="button"
                className={`al-cat-tile${cat === c.id ? ' active' : ''}`}
                onClick={() => setCat(c.id)}
              >
                <div className="icon" style={{ background: c.bg, color: c.color }}>
                  {catIcon(c.icon, c.color)}
                </div>
                <span>{c.label}</span>
              </button>
            ))}
          </div>

          <div
            className="al-hero-banner al-hero-banner--assess"
            style={{ marginBottom: 16 }}
          >
            <h2>Know Your Strengths. Unlock Your Potential.</h2>
            <p>Assess · Plan · Grow · Thrive</p>
            <button
              type="button"
              className="al-btn al-btn--primary"
              onClick={() => openCard(ASSESS_CARDS[0])}
            >
              Start an Assessment →
            </button>
          </div>

          <div className="al-split">
            <div>
              <FilterBar
                search={q}
                onSearch={setQ}
                searchPlaceholder="Search assessments..."
                moreFilters
                onReset={() => {
                  setQ('')
                  setCat('all')
                }}
              >
                <select value={cat} onChange={(e) => setCat(e.target.value)}>
                  <option value="all">All Categories</option>
                  {ASSESS_CATS.filter((c) => c.id !== 'all').map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.label}
                    </option>
                  ))}
                </select>
                <select defaultValue="all">
                  <option value="all">All Users</option>
                </select>
                <select defaultValue="any">
                  <option value="any">Any Duration</option>
                </select>
                <select defaultValue="relevant">
                  <option value="relevant">Most Relevant</option>
                </select>
              </FilterBar>

              {loading ? (
                <div className="al-table-card" style={{ padding: 20 }}>
                  Loading…
                </div>
              ) : (
                <div className="al-assess-grid">
                  {filteredCards.map((card) => (
                    <article key={card.id} className="al-assess-card">
                      <div
                        className="al-assess-icon"
                        style={{ background: card.bg, color: card.color }}
                      >
                        {catIcon(card.icon, card.color)}
                      </div>
                      <strong>{card.title}</strong>
                      <p>{card.description}</p>
                      <div className="al-assess-meta">
                        <IconClock width={13} height={13} /> {card.duration}
                      </div>
                      <button
                        type="button"
                        className="al-type-link"
                        onClick={() => openCard(card)}
                      >
                        Start Assessment →
                      </button>
                    </article>
                  ))}
                </div>
              )}

              <div className="al-table-card" style={{ marginTop: 16, padding: 14 }}>
                <strong style={{ display: 'block', marginBottom: 8 }}>
                  Linked reference data ({offices.length + markets.length + healthOrgs.length} records)
                </strong>
                <p className="muted" style={{ margin: 0, fontSize: 12.5 }}>
                  Assessment recommendations pull from government offices, markets and health orgs.
                  Switch to Manage Data to edit Firestore catalogs.
                </p>
              </div>
            </div>

            <div className="al-widgets">
              <Widget title="Your Assessment Journey">
                <div className="al-donut-wrap">
                  <div className="al-donut" aria-hidden>
                    <span>60%</span>
                  </div>
                  <div>
                    <strong style={{ display: 'block', fontSize: 13 }}>3 of 5 completed</strong>
                    <span className="muted" style={{ fontSize: 12 }}>
                      Keep going to unlock recommendations
                    </span>
                  </div>
                </div>
                <div className="al-journey-stats">
                  <div>
                    <strong>3</strong>
                    <span>Completed</span>
                  </div>
                  <div>
                    <strong>1</strong>
                    <span>In Progress</span>
                  </div>
                  <div>
                    <strong>1</strong>
                    <span>Recommended</span>
                  </div>
                </div>
              </Widget>

              <div className="al-help-card">
                <span
                  className="al-kpi-icon"
                  style={{ background: '#dbeafe', color: '#2563eb', margin: '0 auto' }}
                >
                  <IconStar width={18} height={18} />
                </span>
                <strong>Need Help?</strong>
                <p>Our AI Assistant can guide you to the right assessments based on your goals.</p>
                <button type="button" className="al-btn al-btn--primary">
                  Get Recommendations →
                </button>
              </div>

              <Widget title="Recent Assessments">
                <div className="al-widget-list">
                  {[
                    { title: 'Functional Ability Assessment', tone: 'ok' as const, status: 'Completed', when: 'Sep 2, 2026' },
                    { title: 'Employment Readiness Test', tone: 'info' as const, status: 'In Progress', when: 'Sep 4, 2026' },
                    { title: 'Accessibility Needs Survey', tone: 'muted' as const, status: 'Not Started', when: '—' },
                  ].map((r) => (
                    <div key={r.title} className="al-widget-item">
                      <span className="al-activity-icon al-activity-icon--blue">
                        <IconFileText width={12} height={12} />
                      </span>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <strong>{r.title}</strong>
                        <span>{r.when}</span>
                      </div>
                      <StatusPill tone={r.tone}>{r.status}</StatusPill>
                    </div>
                  ))}
                </div>
              </Widget>

              <div className="al-help-card" style={{ background: '#eff6ff' }}>
                <IconChart width={20} height={20} style={{ color: '#2563eb' }} />
                <strong>Your Results Matter</strong>
                <p>Completed assessments unlock personalized resources, benefits and care paths.</p>
              </div>
            </div>
          </div>
        </>
      ) : (
        <>
          <TabBar
            tabs={[
              { id: 'offices', label: `Gov Offices (${offices.length})` },
              { id: 'markets', label: `Markets (${markets.length})` },
              { id: 'healthOrgs', label: `Health Orgs (${healthOrgs.length})` },
              { id: 'partners', label: `Partners (${partners.length})` },
              { id: 'openData', label: `Open Data (${openData.length})` },
            ]}
            active={tab}
            onChange={(id) => setTab(id as typeof tab)}
          />

          <FilterBar
            search={q}
            onSearch={setQ}
            searchPlaceholder="Search reference data…"
            moreFilters={false}
            onReset={() => setQ('')}
          />

          {loading ? (
            <div className="al-table-card" style={{ padding: 20 }}>
              Loading…
            </div>
          ) : (
            <>
              <div className="al-table-card">
                <table className="al-table">
                  <thead>
                    <tr>
                      {tab === 'offices' ? (
                        <>
                          <th>Name</th>
                          <th>Agency</th>
                          <th>City</th>
                          <th>Phone</th>
                        </>
                      ) : tab === 'markets' ? (
                        <>
                          <th>Code</th>
                          <th>Name</th>
                          <th>Currency</th>
                          <th>Emergency</th>
                        </>
                      ) : tab === 'healthOrgs' ? (
                        <>
                          <th>Name</th>
                          <th>Kind</th>
                          <th>City</th>
                          <th>Owner</th>
                        </>
                      ) : tab === 'partners' ? (
                        <>
                          <th>Name</th>
                          <th>Market</th>
                          <th>Kind</th>
                          <th>Status</th>
                        </>
                      ) : (
                        <>
                          <th>ID</th>
                          <th>Kind</th>
                          <th>Features</th>
                        </>
                      )}
                      <th>Updated</th>
                      {tab === 'partners' ? <th>Actions</th> : null}
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row) => (
                      <tr key={row.id}>
                        {tab === 'offices' ? (
                          <>
                            <td>{cell(row.name)}</td>
                            <td>{cell(row.agency)}</td>
                            <td>{cell(row.city)}</td>
                            <td>{cell(row.phone)}</td>
                          </>
                        ) : tab === 'markets' ? (
                          <>
                            <td>{cell(row.id)}</td>
                            <td>{cell(row.name)}</td>
                            <td>{cell(row.currency)}</td>
                            <td>{cell(row.emergencyNumber)}</td>
                          </>
                        ) : tab === 'healthOrgs' ? (
                          <>
                            <td>{cell(row.name)}</td>
                            <td>{cell(row.kind)}</td>
                            <td>{cell(row.city)}</td>
                            <td>{cell(row.ownerUid)}</td>
                          </>
                        ) : tab === 'partners' ? (
                          <>
                            <td>{cell(row.name)}</td>
                            <td>{cell(row.marketCode)}</td>
                            <td>{cell(row.kind)}</td>
                            <td>{cell(row.status)}</td>
                          </>
                        ) : (
                          <>
                            <td>{cell(row.id)}</td>
                            <td>{cell(row.kind)}</td>
                            <td>{cell(row.featureCount)}</td>
                          </>
                        )}
                        <td>{formatWhen(row.updatedAt ?? row.createdAt)}</td>
                        {tab === 'partners' ? (
                          <td>
                            <button
                              type="button"
                              className="al-btn al-btn--outline"
                              onClick={async () => {
                                try {
                                  await setExpansionPartnerStatus(row.id, 'approved')
                                  setPartners((prev) =>
                                    prev.map((r) =>
                                      r.id === row.id ? { ...r, status: 'approved' } : r,
                                    ),
                                  )
                                } catch (err) {
                                  setError(err instanceof Error ? err.message : 'Update failed')
                                }
                              }}
                            >
                              Approve
                            </button>
                          </td>
                        ) : null}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {tab === 'offices' ? (
                <div className="al-table-card" style={{ marginTop: 16, padding: 16 }}>
                  <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <IconPlus width={16} height={16} /> Add government office
                  </h3>
                  <div
                    style={{
                      display: 'grid',
                      gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                      gap: 10,
                    }}
                  >
                    <label className="field">
                      Name
                      <input
                        value={officeForm.name}
                        onChange={(e) => setOfficeForm({ ...officeForm, name: e.target.value })}
                      />
                    </label>
                    <label className="field">
                      Agency
                      <input
                        value={officeForm.agency}
                        onChange={(e) => setOfficeForm({ ...officeForm, agency: e.target.value })}
                      />
                    </label>
                    <label className="field">
                      City
                      <input
                        value={officeForm.city}
                        onChange={(e) => setOfficeForm({ ...officeForm, city: e.target.value })}
                      />
                    </label>
                    <label className="field">
                      Phone
                      <input
                        value={officeForm.phone}
                        onChange={(e) => setOfficeForm({ ...officeForm, phone: e.target.value })}
                      />
                    </label>
                    <button
                      type="button"
                      className="al-btn al-btn--primary"
                      onClick={async () => {
                        try {
                          await upsertGovernmentOffice(null, officeForm)
                          setOfficeForm({ name: '', agency: '', city: '', phone: '' })
                          await load()
                        } catch (err) {
                          setError(err instanceof Error ? err.message : 'Save failed')
                        }
                      }}
                    >
                      Save office
                    </button>
                  </div>
                </div>
              ) : null}

              {tab === 'markets' ? (
                <div className="al-table-card" style={{ marginTop: 16, padding: 16 }}>
                  <h3 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <IconPlus width={16} height={16} /> Upsert market
                  </h3>
                  <div
                    style={{
                      display: 'grid',
                      gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))',
                      gap: 10,
                    }}
                  >
                    <label className="field">
                      Code
                      <input
                        value={marketForm.code}
                        onChange={(e) => setMarketForm({ ...marketForm, code: e.target.value })}
                      />
                    </label>
                    <label className="field">
                      Name
                      <input
                        value={marketForm.name}
                        onChange={(e) => setMarketForm({ ...marketForm, name: e.target.value })}
                      />
                    </label>
                    <label className="field">
                      Currency
                      <input
                        value={marketForm.currency}
                        onChange={(e) =>
                          setMarketForm({ ...marketForm, currency: e.target.value })
                        }
                      />
                    </label>
                    <label className="field">
                      Emergency #
                      <input
                        value={marketForm.emergencyNumber}
                        onChange={(e) =>
                          setMarketForm({ ...marketForm, emergencyNumber: e.target.value })
                        }
                      />
                    </label>
                    <button
                      type="button"
                      className="al-btn al-btn--primary"
                      onClick={async () => {
                        try {
                          await upsertMarket(marketForm.code, marketForm)
                          await load()
                        } catch (err) {
                          setError(err instanceof Error ? err.message : 'Save failed')
                        }
                      }}
                    >
                      Save market
                    </button>
                  </div>
                </div>
              ) : null}
            </>
          )}
        </>
      )}

      <DetailPanel
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        title={selectedAssess?.title ?? 'Assessment'}
        footer={
          <button
            type="button"
            className="al-btn al-btn--primary"
            style={{ width: '100%' }}
            onClick={() => setDetailOpen(false)}
          >
            Start Assessment
          </button>
        }
      >
        {selectedAssess ? (
          <div style={{ display: 'grid', gap: 12 }}>
            <div
              className="al-assess-icon"
              style={{ background: selectedAssess.bg, color: selectedAssess.color }}
            >
              {catIcon(selectedAssess.icon, selectedAssess.color)}
            </div>
            <p className="muted" style={{ margin: 0 }}>
              {selectedAssess.description}
            </p>
            <div className="al-assess-meta">
              <IconClock width={13} height={13} /> {selectedAssess.duration}
            </div>
            <p style={{ margin: 0, fontSize: 13 }}>
              Results sync with reference catalogs ({offices.length} offices, {markets.length}{' '}
              markets) for personalized recommendations.
            </p>
          </div>
        ) : null}
      </DetailPanel>
    </div>
  )
}
