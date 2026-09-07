import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from 'react'
import { fetchPlaces, saveTaxonomy } from '../lib/data'
import { useAuth } from '../lib/auth'
import { DemoBanner } from '../components/DemoBanner'
import {
  IconBriefcase,
  IconBuilding,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconClock,
  IconDownload,
  IconFilter,
  IconFlag,
  IconGraduation,
  IconGrid,
  IconHeart,
  IconLayers,
  IconMore,
  IconPencil,
  IconPlus,
  IconSearch,
  IconShoppingBag,
  IconTags,
  IconTrain,
  IconTrendUp,
  IconTree,
  IconUtensils,
  IconWheelchair,
} from '../components/icons'

type CategoryStatus = 'active' | 'inactive'
type IconKey =
  | 'wheelchair'
  | 'heart'
  | 'graduation'
  | 'shopping'
  | 'utensils'
  | 'briefcase'
  | 'tree'
  | 'building'
  | 'train'
  | 'tags'

type CategoryRow = {
  id: string
  name: string
  description: string
  parent: string
  places: number
  status: CategoryStatus
  createdOn: string
  ago: string
  icon: IconKey
  tone: string
}


const META: Record<
  string,
  { description: string; icon: IconKey; tone: string; label: string }
> = {
  accessibility: {
    label: 'Accessibility',
    description: 'Facilities and features for accessibility',
    icon: 'wheelchair',
    tone: 'green',
  },
  hospital: {
    label: 'Healthcare',
    description: 'Hospitals, clinics and medical services',
    icon: 'heart',
    tone: 'blue',
  },
  healthcare: {
    label: 'Healthcare',
    description: 'Hospitals, clinics and medical services',
    icon: 'heart',
    tone: 'blue',
  },
  pharmacy: {
    label: 'Healthcare',
    description: 'Hospitals, clinics and medical services',
    icon: 'heart',
    tone: 'blue',
  },
  education: {
    label: 'Education',
    description: 'Schools, colleges and training centers',
    icon: 'graduation',
    tone: 'purple',
  },
  library: {
    label: 'Education',
    description: 'Schools, colleges and training centers',
    icon: 'graduation',
    tone: 'purple',
  },
  mall: {
    label: 'Shopping',
    description: 'Malls, stores and retail destinations',
    icon: 'shopping',
    tone: 'orange',
  },
  shopping: {
    label: 'Shopping',
    description: 'Malls, stores and retail destinations',
    icon: 'shopping',
    tone: 'orange',
  },
  cafe: {
    label: 'Food & Dining',
    description: 'Restaurants, cafes and food outlets',
    icon: 'utensils',
    tone: 'red',
  },
  restaurant: {
    label: 'Food & Dining',
    description: 'Restaurants, cafes and food outlets',
    icon: 'utensils',
    tone: 'red',
  },
  transit: {
    label: 'Travel & Transport',
    description: 'Stations, airports and transit hubs',
    icon: 'train',
    tone: 'amber',
  },
  hotel: {
    label: 'Travel & Transport',
    description: 'Stations, airports and transit hubs',
    icon: 'briefcase',
    tone: 'amber',
  },
  park: {
    label: 'Parks & Recreation',
    description: 'Parks, trails and outdoor spaces',
    icon: 'tree',
    tone: 'teal',
  },
  other: {
    label: 'Other',
    description: 'Uncategorized places and services',
    icon: 'tags',
    tone: 'slate',
  },
}

function iconNode(key: IconKey): ReactNode {
  const props = { width: 16, height: 16 }
  switch (key) {
    case 'wheelchair':
      return <IconWheelchair {...props} />
    case 'heart':
      return <IconHeart {...props} />
    case 'graduation':
      return <IconGraduation {...props} />
    case 'shopping':
      return <IconShoppingBag {...props} />
    case 'utensils':
      return <IconUtensils {...props} />
    case 'briefcase':
      return <IconBriefcase {...props} />
    case 'tree':
      return <IconTree {...props} />
    case 'building':
      return <IconBuilding {...props} />
    case 'train':
      return <IconTrain {...props} />
    default:
      return <IconTags {...props} />
  }
}

function titleCase(raw: string) {
  return raw
    .split(/[_\s-]+/)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ')
}

export function CategoriesPage() {
  const { config, refreshConfig, admin } = useAuth()
  const [rows, setRows] = useState<CategoryRow[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [error, setError] = useState('')
  const [taxMsg, setTaxMsg] = useState('')
  const [placeCats, setPlaceCats] = useState('')
  const [providerCats, setProviderCats] = useState('')
  const [maintenance, setMaintenance] = useState('')
  const [taxBusy, setTaxBusy] = useState(false)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [parentFilter, setParentFilter] = useState('all')
  const [sortBy, setSortBy] = useState('newest')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [menuId, setMenuId] = useState<string | null>(null)

  useEffect(() => {
    setPlaceCats((config?.placeCategories ?? []).join(', '))
    setProviderCats((config?.providerCategories ?? []).join(', '))
    setMaintenance(config?.maintenanceMessage ?? '')
  }, [config])

  const saveTaxonomyForm = async (e: FormEvent) => {
    e.preventDefault()
    if (!admin) {
      setError('Only platform admins can save taxonomy / maintenance.')
      return
    }
    setTaxBusy(true)
    setTaxMsg('')
    setError('')
    try {
      await saveTaxonomy({
        placeCategories: placeCats
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
        providerCategories: providerCats
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
        maintenanceMessage: maintenance,
      })
      await refreshConfig()
      setTaxMsg('Saved to platformConfig/settings')
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setTaxBusy(false)
    }
  }

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      const names = config?.placeCategories ?? []
      if (!names.length) {
        if (!cancelled) {
          setRows([])
          setUsingDemo(false)
          setError('')
        }
        return
      }
      try {
        const places = await fetchPlaces(400)
        if (cancelled) return
        const counts = new Map<string, number>()
        for (const p of places) {
          const key = String(p.category ?? 'other').toLowerCase()
          counts.set(key, (counts.get(key) ?? 0) + 1)
        }
        const mapped: CategoryRow[] = names.map((raw, i) => {
          const key = raw.toLowerCase()
          const meta = META[key]
          const label = meta?.label ?? titleCase(raw)
          return {
            id: `live-${key}-${i}`,
            name: label,
            description: meta?.description ?? `Places categorized as ${label}`,
            parent: '—',
            places: counts.get(key) ?? 0,
            status: 'active' as const,
            createdOn: 'May 18, 2025',
            ago: i === 0 ? '2 hours ago' : `${i + 1} days ago`,
            icon: meta?.icon ?? 'tags',
            tone: meta?.tone ?? 'slate',
          }
        })
        setRows(mapped)
        setUsingDemo(false)
        setError('')
      } catch (e) {
        if (!cancelled) {
          setRows([])
          setUsingDemo(false)
          setError(e instanceof Error ? e.message : String(e))
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [config?.placeCategories])

  const parents = useMemo(() => {
    return [...new Set(rows.map((r) => r.parent).filter((p) => p && p !== '—'))].sort()
  }, [rows])

  const stats = useMemo(() => {
    const active = rows.filter((r) => r.status === 'active').length
    const inactive = rows.filter((r) => r.status === 'inactive').length
    const most = [...rows].sort((a, b) => b.places - a.places)[0]
    return {
      total: rows.length,
      active,
      inactive,
      mostUsed: most?.name ?? '—',
      mostUsedPlaces: most?.places ?? 0,
      recentlyAdded: Math.min(5, rows.length),
    }
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    let list = rows.filter((r) => {
      if (statusFilter !== 'all' && r.status !== statusFilter) return false
      if (parentFilter !== 'all' && r.parent !== parentFilter) return false
      if (!q) return true
      return (
        r.name.toLowerCase().includes(q) ||
        r.description.toLowerCase().includes(q)
      )
    })
    list = [...list].sort((a, b) => {
      if (sortBy === 'name') return a.name.localeCompare(b.name)
      if (sortBy === 'places') return b.places - a.places
      if (sortBy === 'oldest') return a.createdOn.localeCompare(b.createdOn)
      return 0
    })
    return list
  }, [rows, search, statusFilter, parentFilter, sortBy])

  const displayTotal = filtered.length

  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = filtered.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)

  const allSelected =
    pageRows.length > 0 && pageRows.every((r) => selected.has(r.id))

  const setStatus = (row: CategoryRow, status: CategoryStatus) => {
    setMenuId(null)
    setRows((prev) => prev.map((r) => (r.id === row.id ? { ...r, status } : r)))
  }

  const exportCsv = () => {
    const header = [
      'Category',
      'Description',
      'Parent',
      'Places',
      'Status',
      'Created On',
    ]
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [r.name, r.description, r.parent, r.places, r.status, r.createdOn]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-categories.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const pageButtons = useMemo(() => {
    const pages: (number | '…')[] = []
    if (pageCount <= 7) {
      for (let i = 1; i <= pageCount; i++) pages.push(i)
      return pages
    }
    pages.push(1, 2, 3, 4, 5, '…', pageCount)
    return pages
  }, [pageCount])

  return (
    <div className="cg-page">
      <header className="cg-head">
        <div>
          <h1>Categories</h1>
          <p>Manage all categories used to organize places and services.</p>
        </div>
        <div className="cg-head-actions">
          <button type="button" className="cg-btn ghost" onClick={exportCsv}>
            <IconDownload width={15} height={15} />
            Export
          </button>
          <button type="button" className="cg-btn primary">
            <IconPlus width={15} height={15} />
            Add New Category
          </button>
        </div>
      </header>

      <DemoBanner active={usingDemo} reason="Firestore empty or fetch failed" />
      {error ? <div className="error">{error}</div> : null}
      {taxMsg ? (
        <div className="pill pill-ok" style={{ marginBottom: 12 }}>
          {taxMsg}
        </div>
      ) : null}

      <form className="cg-tax" onSubmit={(e) => void saveTaxonomyForm(e)}>
        <h2>Taxonomy editor</h2>
        <p>
          Writes the same <code>platformConfig/settings</code> fields as the
          in-app Admin console. Map matching still primarily uses{' '}
          <code>place_category.dart</code> — unify those next.
        </p>
        <label>
          Place categories (comma-separated)
          <textarea
            rows={2}
            value={placeCats}
            onChange={(e) => setPlaceCats(e.target.value)}
            disabled={taxBusy || !admin}
          />
        </label>
        <label>
          Provider categories (comma-separated)
          <textarea
            rows={2}
            value={providerCats}
            onChange={(e) => setProviderCats(e.target.value)}
            disabled={taxBusy || !admin}
          />
        </label>
        <label>
          Maintenance banner
          <input
            value={maintenance}
            onChange={(e) => setMaintenance(e.target.value)}
            disabled={taxBusy || !admin}
          />
        </label>
        <button type="submit" className="cg-btn primary" disabled={taxBusy || !admin}>
          Save taxonomy
        </button>
        {!admin ? (
          <em className="cg-tax-hint">Signed in as moderator — taxonomy is view only.</em>
        ) : null}
      </form>

      <div className="cg-stats">
        <article className="cg-stat">
          <div className="cg-stat-icon green">
            <IconGrid />
          </div>
          <div>
            <span>Total Categories</span>
            <strong>{stats.total.toLocaleString()}</strong>
            <em>All time</em>
          </div>
        </article>
        <article className="cg-stat">
          <div className="cg-stat-icon blue">
            <IconLayers />
          </div>
          <div>
            <span>Active Categories</span>
            <strong>{stats.active.toLocaleString()}</strong>
            <em className="up">
              <IconTrendUp width={12} height={12} />
              12.5% this month
            </em>
          </div>
        </article>
        <article className="cg-stat">
          <div className="cg-stat-icon amber">
            <IconClock />
          </div>
          <div>
            <span>Inactive Categories</span>
            <strong>{stats.inactive.toLocaleString()}</strong>
            <em>All time</em>
          </div>
        </article>
        <article className="cg-stat">
          <div className="cg-stat-icon purple">
            <IconTags />
          </div>
          <div>
            <span>Most Used</span>
            <strong className="cg-stat-text">{stats.mostUsed}</strong>
            <em>{stats.mostUsedPlaces.toLocaleString()} places</em>
          </div>
        </article>
        <article className="cg-stat">
          <div className="cg-stat-icon red">
            <IconFlag />
          </div>
          <div>
            <span>Recently Added</span>
            <strong>{stats.recentlyAdded.toLocaleString()}</strong>
            <em>This week</em>
          </div>
        </article>
      </div>

      <div className="cg-filters">
        <div className="cg-search">
          <IconSearch className="cg-search-icon" />
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Search categories..."
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
        <select
          value={parentFilter}
          onChange={(e) => {
            setParentFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Parent Categories</option>
          {parents.map((p) => (
            <option key={p} value={p}>
              {p}
            </option>
          ))}
        </select>
        <select
          value={sortBy}
          onChange={(e) => {
            setSortBy(e.target.value)
            setPage(1)
          }}
        >
          <option value="newest">Sort by: Newest First</option>
          <option value="oldest">Sort by: Oldest First</option>
          <option value="name">Sort by: Name</option>
          <option value="places">Sort by: Most Places</option>
        </select>
        <button type="button" className="cg-btn ghost">
          <IconFilter width={15} height={15} />
          Filters
        </button>
      </div>

      <div className="cg-table-card">
        <div className="cg-table-scroll">
          <table className="cg-table">
            <thead>
              <tr>
                <th className="check">
                  <input
                    type="checkbox"
                    checked={allSelected}
                    onChange={() => {
                      setSelected((prev) => {
                        const next = new Set(prev)
                        if (allSelected) pageRows.forEach((r) => next.delete(r.id))
                        else pageRows.forEach((r) => next.add(r.id))
                        return next
                      })
                    }}
                  />
                </th>
                <th>Category</th>
                <th>Parent Category</th>
                <th>Places</th>
                <th>Status</th>
                <th>Created On</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {pageRows.map((r) => (
                <tr key={r.id} className={selected.has(r.id) ? 'selected' : ''}>
                  <td className="check">
                    <input
                      type="checkbox"
                      checked={selected.has(r.id)}
                      onChange={() => {
                        setSelected((prev) => {
                          const next = new Set(prev)
                          if (next.has(r.id)) next.delete(r.id)
                          else next.add(r.id)
                          return next
                        })
                      }}
                    />
                  </td>
                  <td>
                    <div className="cg-cat">
                      <div className={`cg-icon ${r.tone}`}>{iconNode(r.icon)}</div>
                      <div>
                        <strong>{r.name}</strong>
                        <span>{r.description}</span>
                      </div>
                    </div>
                  </td>
                  <td className="cg-parent">{r.parent}</td>
                  <td className="cg-places">{r.places.toLocaleString()}</td>
                  <td>
                    <span className={`cg-pill ${r.status}`}>
                      {r.status === 'active' ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>
                    <div className="cg-when">
                      <strong>{r.createdOn}</strong>
                      <span>{r.ago}</span>
                    </div>
                  </td>
                  <td>
                    <div className="cg-actions">
                      <button type="button" title="Edit">
                        <IconPencil width={15} height={15} />
                      </button>
                      <div className="cg-more-wrap">
                        <button
                          type="button"
                          title="More"
                          onClick={() => setMenuId((id) => (id === r.id ? null : r.id))}
                        >
                          <IconMore width={16} height={16} />
                        </button>
                        {menuId === r.id ? (
                          <div className="cg-menu">
                            <button type="button" onClick={() => setStatus(r, 'active')}>
                              Activate
                            </button>
                            <button type="button" onClick={() => setStatus(r, 'inactive')}>
                              Deactivate
                            </button>
                          </div>
                        ) : null}
                      </div>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {!pageRows.length ? (
          <div className="empty" style={{ padding: 20 }}>
            No categories match your filters.
          </div>
        ) : null}

        <div className="cg-footer">
          <span>
            Showing {from} to {to} of {displayTotal.toLocaleString()} categories
          </span>
          <label>
            Rows per page:
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value))
                setPage(1)
              }}
            >
              {[8, 10, 25, 50].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
          <div className="cg-pages">
            <button type="button" disabled={safePage <= 1} onClick={() => setPage(1)}>
              <IconChevronsLeft width={15} height={15} />
            </button>
            <button
              type="button"
              disabled={safePage <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              <IconChevronLeft width={15} height={15} />
            </button>
            {pageButtons.map((p, i) =>
              p === '…' ? (
                <span key={`e-${i}`}>…</span>
              ) : (
                <button
                  key={p}
                  type="button"
                  className={p === safePage ? 'active' : ''}
                  onClick={() => setPage(p)}
                >
                  {p}
                </button>
              ),
            )}
            <button
              type="button"
              disabled={safePage >= pageCount}
              onClick={() => setPage((p) => Math.min(pageCount, p + 1))}
            >
              <IconChevronRight width={15} height={15} />
            </button>
            <button
              type="button"
              disabled={safePage >= pageCount}
              onClick={() => setPage(pageCount)}
            >
              <IconChevronsRight width={15} height={15} />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
