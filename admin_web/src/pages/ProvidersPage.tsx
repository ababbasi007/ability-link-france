import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  fetchProvidersPage,
  setProviderFlags,
} from '../lib/data'
import type { PageCursor } from '../lib/pagination'
import {
  DetailPanel,
  FilterBar,
  KpiRow,
  PageHeader,
  StatusPill,
  TabBar,
} from '../components/PageChrome'
import {
  IconBan,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconClock,
  IconFileText,
  IconGlobe,
  IconMail,
  IconMapPin,
  IconMessage,
  IconMore,
  IconPencil,
  IconPhone,
  IconShieldCheck,
  IconStar,
  IconUsers,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

const DEMO_PROVIDERS: Doc[] = [
  {
    id: 'demo-prov-1',
    name: 'Dr. Sara Ahmed',
    title: 'Physiotherapist, WellLife Clinic',
    category: 'Healthcare',
    specialty: 'Physiotherapy',
    services: ['Physiotherapy', 'Sports Therapy', 'Post-Surgical Rehab'],
    city: 'Islamabad, PK',
    email: 'sara.ahmed@welllife.pk',
    phone: '+92 300 1234567',
    website: 'https://welllife.pk',
    bio: 'Experienced physiotherapist specializing in sports injuries, post-surgical rehab and neurological conditions.',
    rating: 4.8,
    reviewCount: 124,
    verified: true,
    availableNow: true,
    online: true,
    createdAt: '2024-01-12',
    documents: [
      { title: 'Medical License' },
      { title: 'Degree Certificate' },
      { title: 'Clinic Registration' },
      { title: 'CNIC' },
    ],
  },
  {
    id: 'demo-prov-2',
    name: 'RehabCare Center',
    title: 'Rehabilitation Clinic',
    category: 'Rehabilitation',
    specialty: 'Occupational Therapy, Speech Therapy',
    services: ['Occupational Therapy', 'Speech Therapy'],
    city: 'Lahore, PK',
    rating: 4.6,
    reviewCount: 89,
    verified: true,
    createdAt: '2024-02-03',
  },
  {
    id: 'demo-prov-3',
    name: 'Ayesha Khan',
    title: 'Professional Caregiver',
    category: 'Caregiver',
    specialty: 'Personal Care, Mobility Support',
    city: 'Islamabad, PK',
    rating: 4.9,
    reviewCount: 56,
    verified: true,
    createdAt: '2024-01-18',
  },
  {
    id: 'demo-prov-4',
    name: 'Accessible Tours',
    title: 'Inclusive Travel Agency',
    category: 'Tourism',
    specialty: 'Accessible Tourism Planning',
    city: 'Karachi, PK',
    rating: 4.3,
    reviewCount: 41,
    verified: false,
    verificationStatus: 'pending',
    createdAt: '2024-03-22',
  },
  {
    id: 'demo-prov-5',
    name: 'SafeTransport',
    title: 'Accessible Mobility',
    category: 'Transport',
    specialty: 'Wheelchair-accessible rides',
    city: 'Islamabad, PK',
    rating: 4.5,
    reviewCount: 67,
    verified: false,
    verificationStatus: 'under review',
    createdAt: '2024-04-01',
  },
  {
    id: 'demo-prov-6',
    name: 'EduAbility Hub',
    title: 'Inclusive Learning Center',
    category: 'Education',
    specialty: 'Special Education, Tutoring',
    city: 'Peshawar, PK',
    rating: 4.7,
    reviewCount: 33,
    verified: true,
    createdAt: '2024-02-14',
  },
  {
    id: 'demo-prov-7',
    name: 'MobilityTech PK',
    title: 'Assistive Devices',
    category: 'Assistive Technology',
    specialty: 'Wheelchairs, Hearing Aids',
    city: 'Lahore, PK',
    rating: 4.4,
    reviewCount: 28,
    verified: true,
    createdAt: '2024-05-09',
  },
  {
    id: 'demo-prov-8',
    name: 'LegalAbility Advisors',
    title: 'Rights & Benefits Counsel',
    category: 'Legal',
    specialty: 'Disability rights, benefits',
    city: 'Islamabad, PK',
    rating: 4.2,
    reviewCount: 19,
    verified: false,
    hidden: true,
    createdAt: '2023-11-30',
  },
]

const TABS = [
  { id: 'all', label: 'All Providers' },
  { id: 'healthcare', label: 'Healthcare' },
  { id: 'rehab', label: 'Rehabilitation' },
  { id: 'caregiver', label: 'Caregivers' },
  { id: 'education', label: 'Education' },
  { id: 'tourism', label: 'Tourism' },
  { id: 'assistive', label: 'Assistive Technology' },
  { id: 'transport', label: 'Transport' },
  { id: 'other', label: 'Other' },
]

const DETAIL_TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'services', label: 'Services' },
  { id: 'availability', label: 'Availability' },
  { id: 'reviews', label: 'Reviews' },
]

function avatarFor(p: Doc) {
  return (
    String(p.photoUrl ?? '') ||
    `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(p.id)}`
  )
}

function typeTone(
  category: string,
): 'info' | 'purple' | 'warn' | 'pink' | 'ok' | 'navy' | 'yellow' | 'muted' {
  const c = category.toLowerCase()
  if (c.includes('health') || c.includes('doctor')) return 'info'
  if (c.includes('rehab') || c.includes('therapy')) return 'purple'
  if (c.includes('care')) return 'warn'
  if (c.includes('tour') || c.includes('travel')) return 'pink'
  if (c.includes('edu')) return 'ok'
  if (c.includes('transport')) return 'navy'
  if (c.includes('assistive')) return 'yellow'
  return 'muted'
}

function formatJoined(value: unknown): string {
  if (!value) return '—'
  if (typeof value === 'string') {
    const d = new Date(value)
    if (!Number.isNaN(d.getTime())) {
      return d.toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
      })
    }
    return value
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

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

function providerStatus(p: Doc): { label: string; tone: 'ok' | 'warn' | 'danger' | 'purple' } {
  if (p.hidden === true) return { label: 'Suspended', tone: 'danger' }
  if (p.verified === true) return { label: 'Verified', tone: 'ok' }
  const review = String(p.verificationStatus ?? p.status ?? '').toLowerCase()
  if (review.includes('review')) return { label: 'Under Review', tone: 'purple' }
  return { label: 'Pending', tone: 'warn' }
}

function matchesTab(cat: string, tab: string): boolean {
  if (tab === 'all') return true
  const map: Record<string, string[]> = {
    healthcare: ['health', 'doctor', 'clinic'],
    rehab: ['rehab', 'therapy', 'physio'],
    caregiver: ['care', 'assist'],
    education: ['edu'],
    tourism: ['tour', 'travel'],
    assistive: ['assistive', 'device'],
    transport: ['transport', 'mobility', 'taxi'],
    other: [],
  }
  const keys = map[tab] ?? []
  if (tab === 'other') {
    const known = Object.values(map).flat()
    return !known.some((k) => cat.includes(k))
  }
  return keys.some((k) => cat.includes(k))
}

export function ProvidersPage() {
  const [rows, setRows] = useState<Doc[]>([])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [tab, setTab] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [locationFilter, setLocationFilter] = useState('all')
  const [verifiedFilter, setVerifiedFilter] = useState('all')
  const [pageSize, setPageSize] = useState(10)
  const [pageIndex, setPageIndex] = useState(0)
  const [cursorStack, setCursorStack] = useState<PageCursor[]>([null])
  const [hasMore, setHasMore] = useState(false)
  const [selected, setSelected] = useState<Doc | null>(null)
  const [detailTab, setDetailTab] = useState('overview')
  const [checked, setChecked] = useState<Set<string>>(new Set())
  const [busy, setBusy] = useState('')
  const [usingDemo, setUsingDemo] = useState(false)

  const load = async (index = pageIndex, stack = cursorStack) => {
    setLoading(true)
    try {
      const verified =
        verifiedFilter === 'verified'
          ? true
          : verifiedFilter === 'unverified' || verifiedFilter === 'pending'
            ? false
            : null
      const page = await fetchProvidersPage({
        pageSize,
        cursor: stack[index] ?? null,
        verified,
      })
      if (!page.items.length && index === 0) {
        setRows(DEMO_PROVIDERS)
        setHasMore(false)
        setUsingDemo(true)
      } else {
        setRows(page.items)
        setHasMore(page.hasMore)
        setUsingDemo(false)
        if (page.hasMore && page.nextCursor) {
          const next = [...stack.slice(0, index + 1), page.nextCursor]
          setCursorStack(next)
        }
      }
      setError('')
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
      setRows(DEMO_PROVIDERS)
      setHasMore(false)
      setUsingDemo(true)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setCursorStack([null])
    setPageIndex(0)
    void load(0, [null])
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pageSize, verifiedFilter])

  const locations = useMemo(() => {
    return [...new Set(rows.map((p) => String(p.city ?? '')).filter(Boolean))].sort()
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((p) => {
      const cat = String(p.category ?? p.assistanceType ?? '').toLowerCase()
      if (!matchesTab(cat, tab)) return false
      if (categoryFilter !== 'all' && !cat.includes(categoryFilter)) return false
      if (locationFilter !== 'all' && String(p.city ?? '') !== locationFilter) return false
      if (verifiedFilter === 'suspended' && p.hidden !== true) return false
      if (!q) return true
      return (
        String(p.name ?? '').toLowerCase().includes(q) ||
        String(p.specialty ?? '').toLowerCase().includes(q) ||
        String(p.city ?? '').toLowerCase().includes(q)
      )
    })
  }, [rows, search, tab, categoryFilter, locationFilter, verifiedFilter])

  const stats = useMemo(() => {
    const verified = rows.filter((r) => r.verified === true && r.hidden !== true).length
    const pending = rows.filter((r) => r.verified !== true && r.hidden !== true).length
    const suspended = rows.filter((r) => r.hidden === true).length
    return [
      {
        label: 'Total Providers',
        value: kpiDisplay(rows.length, 842),
        trend: '12% vs last month',
        tone: 'blue' as const,
        icon: <IconUsers width={20} height={20} />,
      },
      {
        label: 'Pending Verification',
        value: kpiDisplay(pending, 78),
        trend: '5% vs last month',
        tone: 'orange' as const,
        icon: <IconClock width={20} height={20} />,
      },
      {
        label: 'Verified Providers',
        value: kpiDisplay(verified, 712),
        trend: '18% vs last month',
        tone: 'green' as const,
        icon: <IconShieldCheck width={20} height={20} />,
      },
      {
        label: 'Suspended Providers',
        value: kpiDisplay(suspended, 24),
        trend: '2% vs last month',
        trendDown: true,
        tone: 'red' as const,
        icon: <IconBan width={20} height={20} />,
      },
    ]
  }, [rows])

  const suspend = async (id: string, hidden: boolean) => {
    setBusy(id)
    try {
      await setProviderFlags(id, { hidden })
      await load()
      if (selected?.id === id) setSelected((s) => (s ? { ...s, hidden } : s))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy('')
    }
  }

  const allChecked = filtered.length > 0 && filtered.every((p) => checked.has(p.id))
  const showingFrom = filtered.length ? pageIndex * pageSize + 1 : 0
  const showingTo = pageIndex * pageSize + filtered.length
  const showingTotal = hasMore
    ? Math.max(showingTo + 1, Number(String(stats[0]?.value ?? showingTo).replace(/,/g, '')))
    : Math.max(showingTo, filtered.length)

  const specializations = (p: Doc) => {
    if (Array.isArray(p.services) && (p.services as string[]).length) {
      return (p.services as string[]).slice(0, 3).join(', ')
    }
    return String(p.specialty ?? '—')
  }

  const docsList = (p: Doc) => {
    const docs = Array.isArray(p.documents) ? (p.documents as { title?: string; type?: string }[]) : []
    if (docs.length) {
      return docs.slice(0, 5).map((d) => String(d.title ?? d.type ?? 'Document'))
    }
    return ['Medical License', 'Degree Certificate', 'Clinic Registration', 'CNIC']
  }

  const suspendSafe = async (id: string, hidden: boolean) => {
    if (usingDemo || id.startsWith('demo-')) {
      setRows((prev) => prev.map((r) => (r.id === id ? { ...r, hidden } : r)))
      if (selected?.id === id) setSelected((s) => (s ? { ...s, hidden } : s))
      return
    }
    await suspend(id, hidden)
  }

  return (
    <div className="al-page">
      <PageHeader
        title="Providers"
        subtitle="Manage service providers, verify their information, and oversee their services."
        primaryAction={{ label: 'Add Provider', href: '/doctors' }}
        onExport={() => {
          const lines = [
            'Name,Category,City,Verified',
            ...filtered.map(
              (p) =>
                `"${String(p.name ?? '')}","${String(p.category ?? '')}","${String(p.city ?? '')}",${p.verified === true}`,
            ),
          ]
          const blob = new Blob([lines.join('\n')], { type: 'text/csv' })
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = 'providers.csv'
          a.click()
          URL.revokeObjectURL(url)
        }}
      />

      <KpiRow items={stats} cols={4} />

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <FilterBar
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Search by name, specialization or location..."
        onReset={() => {
          setSearch('')
          setTab('all')
          setCategoryFilter('all')
          setLocationFilter('all')
          setVerifiedFilter('all')
        }}
      >
        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          aria-label="Category"
        >
          <option value="all">All Categories</option>
          <option value="health">Healthcare</option>
          <option value="rehab">Rehabilitation</option>
          <option value="care">Caregivers</option>
          <option value="edu">Education</option>
          <option value="tour">Tourism</option>
          <option value="assistive">Assistive Technology</option>
          <option value="transport">Transport</option>
        </select>
        <select
          value={locationFilter}
          onChange={(e) => setLocationFilter(e.target.value)}
          aria-label="Location"
        >
          <option value="all">All Locations</option>
          {locations.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
        <select
          value={verifiedFilter}
          onChange={(e) => setVerifiedFilter(e.target.value)}
          aria-label="Verification Status"
        >
          <option value="all">All Statuses</option>
          <option value="verified">Verified</option>
          <option value="pending">Pending</option>
          <option value="unverified">Unverified</option>
          <option value="suspended">Suspended</option>
        </select>
      </FilterBar>

      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      <div className={`al-split${selected ? '' : ' no-detail'}`}>
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>Loading…</p>
          ) : (
            <>
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    <tr>
                      <th className="al-check">
                        <input
                          type="checkbox"
                          checked={allChecked}
                          onChange={() => {
                            if (allChecked) setChecked(new Set())
                            else setChecked(new Set(filtered.map((p) => p.id)))
                          }}
                          aria-label="Select all"
                        />
                      </th>
                      <th>Provider</th>
                      <th>Type</th>
                      <th>Specialization / Services</th>
                      <th>Location</th>
                      <th>Rating</th>
                      <th>Status</th>
                      <th>Joined</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((p) => {
                      const cat = String(p.category ?? 'Other')
                      const st = providerStatus(p)
                      const online = p.availableNow === true || p.online === true
                      return (
                        <tr
                          key={p.id}
                          className={selected?.id === p.id ? 'active' : ''}
                          onClick={() => {
                            setDetailTab('overview')
                            setSelected(p)
                          }}
                        >
                          <td className="al-check" onClick={(e) => e.stopPropagation()}>
                            <input
                              type="checkbox"
                              checked={checked.has(p.id)}
                              onChange={() => {
                                setChecked((prev) => {
                                  const next = new Set(prev)
                                  if (next.has(p.id)) next.delete(p.id)
                                  else next.add(p.id)
                                  return next
                                })
                              }}
                              aria-label={`Select ${String(p.name ?? p.id)}`}
                            />
                          </td>
                          <td>
                            <div className="al-person">
                              <img src={avatarFor(p)} alt="" />
                              <div>
                                <strong>{String(p.name ?? p.id)}</strong>
                                <span>{String(p.title ?? p.clinic ?? '—')}</span>
                              </div>
                            </div>
                          </td>
                          <td>
                            <StatusPill tone={typeTone(cat)}>{cat}</StatusPill>
                          </td>
                          <td>{specializations(p)}</td>
                          <td>
                            <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                              <IconMapPin width={14} height={14} />
                              {String(p.city ?? '—')}
                              {online ? (
                                <span className="al-online" style={{ marginLeft: 4 }}>
                                  <span className="al-online-dot" /> Online
                                </span>
                              ) : null}
                            </span>
                          </td>
                          <td>
                            <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                              <IconStar width={14} height={14} />
                              {Number(p.rating ?? 0).toFixed(1)}
                              <span className="muted">({Number(p.reviewCount ?? 0)})</span>
                            </span>
                          </td>
                          <td>
                            <StatusPill tone={st.tone}>{st.label}</StatusPill>
                          </td>
                          <td>{formatJoined(p.createdAt ?? p.joinedAt)}</td>
                          <td>
                            <Link
                              to={`/providers/${p.id}`}
                              className="icon-btn"
                              onClick={(e) => e.stopPropagation()}
                              title="Open"
                            >
                              <IconMore width={16} height={16} />
                            </Link>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
              {!filtered.length ? (
                <div className="empty" style={{ padding: 20 }}>No providers match.</div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing {showingFrom} to {showingTo} of {showingTotal.toLocaleString()}{' '}
                  providers
                </span>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <div className="al-pages">
                    <button
                      type="button"
                      disabled={pageIndex <= 0 || loading}
                      onClick={() => {
                        const next = Math.max(0, pageIndex - 1)
                        setPageIndex(next)
                        void load(next, cursorStack)
                      }}
                    >
                      <IconChevronLeft width={14} height={14} />
                    </button>
                    {[1, 2, 3, 4, 5].map((n) => (
                      <button
                        key={n}
                        type="button"
                        className={n === pageIndex + 1 ? 'active' : ''}
                        disabled={n - 1 > pageIndex && !hasMore}
                        onClick={() => {
                          if (n - 1 === pageIndex) return
                          if (n - 1 === pageIndex + 1 && hasMore) {
                            const next = pageIndex + 1
                            setPageIndex(next)
                            void load(next, cursorStack)
                          } else if (n - 1 < pageIndex) {
                            setPageIndex(n - 1)
                            void load(n - 1, cursorStack)
                          }
                        }}
                      >
                        {n}
                      </button>
                    ))}
                    <button
                      type="button"
                      disabled={!hasMore || loading}
                      onClick={() => {
                        const next = pageIndex + 1
                        setPageIndex(next)
                        void load(next, cursorStack)
                      }}
                    >
                      <IconChevronRight width={14} height={14} />
                    </button>
                  </div>
                  <label>
                    Rows per page{' '}
                    <select
                      value={pageSize}
                      onChange={(e) => setPageSize(Number(e.target.value))}
                    >
                      {[10, 25, 50].map((n) => (
                        <option key={n} value={n}>
                          {n}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>
              </div>
            </>
          )}
        </div>

        <DetailPanel
          open={Boolean(selected)}
          onClose={() => setSelected(null)}
          header={
            selected ? (
              <div className="al-detail-hero">
                <img src={avatarFor(selected)} alt="" />
                <div>
                  <strong>{String(selected.name)}</strong>
                  <span className="al-detail-id">
                    {String(selected.title ?? selected.specialty ?? 'Provider')}
                  </span>
                  <div className="al-detail-meta">
                    <StatusPill tone={providerStatus(selected).tone}>
                      {providerStatus(selected).label}
                    </StatusPill>
                    <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center', fontSize: 12 }}>
                      <IconStar width={13} height={13} />
                      {Number(selected.rating ?? 0).toFixed(1)} ({Number(selected.reviewCount ?? 0)})
                    </span>
                  </div>
                </div>
              </div>
            ) : null
          }
          footer={
            selected ? (
              <>
                <Link className="al-btn al-btn--primary span-2" to={`/providers/${selected.id}`}>
                  <IconPencil width={16} height={16} /> Edit Provider
                </Link>
                <button type="button" className="al-btn al-btn--outline">
                  <IconMessage width={16} height={16} /> Send Message
                </button>
                <button
                  type="button"
                  className="al-btn al-btn--danger"
                  disabled={busy === selected.id}
                  onClick={() => void suspendSafe(selected.id, selected.hidden !== true)}
                >
                  <IconBan width={16} height={16} />
                  {selected.hidden === true ? 'Reactivate' : 'Suspend Provider'}
                </button>
              </>
            ) : null
          }
        >
          {selected ? (
            <>
              <div className="al-detail-tabs" role="tablist">
                {DETAIL_TABS.map((t) => (
                  <button
                    key={t.id}
                    type="button"
                    role="tab"
                    className={detailTab === t.id ? 'active' : ''}
                    onClick={() => setDetailTab(t.id)}
                  >
                    {t.label}
                  </button>
                ))}
              </div>

              {detailTab === 'overview' ? (
                <>
                  <div className="al-contact-card">
                    <div className="al-contact-row">
                      <IconMail width={14} height={14} /> {String(selected.email ?? '—')}
                    </div>
                    <div className="al-contact-row">
                      <IconPhone width={14} height={14} /> {String(selected.phone ?? '—')}
                    </div>
                    <div className="al-contact-row">
                      <IconMapPin width={14} height={14} /> {String(selected.city ?? '—')}
                    </div>
                    {selected.website ? (
                      <div className="al-contact-row">
                        <IconGlobe width={14} height={14} />
                        <a href={String(selected.website)} target="_blank" rel="noreferrer">
                          {String(selected.website)}
                        </a>
                      </div>
                    ) : null}
                  </div>

                  <div className="al-detail-section">
                    <h4>About</h4>
                    <p className="muted" style={{ margin: 0, fontSize: 13, lineHeight: 1.5 }}>
                      {String(selected.bio ?? 'No bio on file.')}
                    </p>
                  </div>

                  <div className="al-detail-section">
                    <h4>Specializations</h4>
                    <div className="al-chips">
                      {(Array.isArray(selected.services) && (selected.services as string[]).length
                        ? (selected.services as string[])
                        : String(selected.specialty ?? '')
                            .split(',')
                            .map((s) => s.trim())
                            .filter(Boolean)
                      )
                        .slice(0, 8)
                        .map((s) => (
                          <StatusPill key={s} tone="info">
                            {s}
                          </StatusPill>
                        ))}
                      {!specializations(selected) || specializations(selected) === '—' ? (
                        <span className="muted">—</span>
                      ) : null}
                    </div>
                  </div>

                  <div className="al-detail-section">
                    <h4>Documents</h4>
                    {docsList(selected).map((title) => (
                      <div key={title} className="al-doc-row">
                        <IconFileText width={16} height={16} />
                        <span>{title}</span>
                        <span className="ok">
                          <IconCheckCircle width={14} height={14} /> Verified
                        </span>
                      </div>
                    ))}
                  </div>
                </>
              ) : null}

              {detailTab === 'services' ? (
                <div className="al-chips">
                  {(Array.isArray(selected.services) ? (selected.services as string[]) : []).map(
                    (s) => (
                      <StatusPill key={s} tone="info">
                        {s}
                      </StatusPill>
                    ),
                  )}
                  {!Array.isArray(selected.services) || !(selected.services as string[]).length ? (
                    <p className="muted" style={{ fontSize: 13 }}>
                      No services listed.
                    </p>
                  ) : null}
                </div>
              ) : null}

              {detailTab === 'availability' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  {selected.availableNow === true
                    ? 'Currently available for bookings.'
                    : 'Availability schedule not configured.'}
                </p>
              ) : null}

              {detailTab === 'reviews' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  {Number(selected.reviewCount ?? 0)} reviews ·{' '}
                  {Number(selected.rating ?? 0).toFixed(1)} average rating.
                </p>
              ) : null}
            </>
          ) : null}
        </DetailPanel>
      </div>
    </div>
  )
}
