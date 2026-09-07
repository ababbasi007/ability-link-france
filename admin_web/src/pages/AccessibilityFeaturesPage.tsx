import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import {
  IconAudio,
  IconBraille,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconChevronsLeft,
  IconChevronsRight,
  IconDoor,
  IconDownload,
  IconEar,
  IconElevator,
  IconEyeOpen,
  IconFilter,
  IconGrid,
  IconMore,
  IconParking,
  IconPath,
  IconPause,
  IconPaw,
  IconPencil,
  IconPlus,
  IconPlusCircle,
  IconRamp,
  IconRestroom,
  IconSearch,
  IconStar,
  IconTactile,
  IconWheelchair,
} from '../components/icons'
import { useAuth } from '../lib/auth'
import {
  DEFAULT_ACCESSIBILITY_FEATURES,
  fetchPlaces,
  saveAccessibilityFeatures,
  type AccessibilityFeatureDef,
} from '../lib/data'

type FeatureStatus = 'active' | 'inactive'
type FeatureCategory = AccessibilityFeatureDef['category']
type IconKey =
  | 'wheelchair'
  | 'ramp'
  | 'elevator'
  | 'restroom'
  | 'parking'
  | 'door'
  | 'ear'
  | 'braille'
  | 'eye'
  | 'path'
  | 'audio'
  | 'paw'
  | 'tactile'

type FeatureRow = {
  id: string
  key: string
  name: string
  description: string
  category: FeatureCategory
  places: number
  status: FeatureStatus
  createdOn: string
  ago: string
  icon: IconKey
  tone: string
}

function iconForKey(key: string): { icon: IconKey; tone: string } {
  switch (key) {
    case 'stepFree':
      return { icon: 'door', tone: 'green' }
    case 'ramp':
      return { icon: 'ramp', tone: 'blue' }
    case 'elevator':
      return { icon: 'elevator', tone: 'purple' }
    case 'wideCorridors':
      return { icon: 'door', tone: 'teal' }
    case 'accessibleTransit':
      return { icon: 'path', tone: 'teal' }
    case 'toilet':
      return { icon: 'restroom', tone: 'teal' }
    case 'parking':
    case 'dropOff':
      return { icon: 'parking', tone: 'orange' }
    case 'hearing':
    case 'signLanguage':
      return { icon: 'ear', tone: 'purple' }
    case 'braille':
      return { icon: 'braille', tone: 'slate' }
    case 'captions':
    case 'lowVisionFriendly':
      return { icon: 'eye', tone: 'blue' }
    case 'quiet':
    case 'audioAnnouncements':
      return { icon: 'audio', tone: 'amber' }
    case 'serviceAnimal':
      return { icon: 'paw', tone: 'green' }
    default:
      return { icon: 'wheelchair', tone: 'green' }
  }
}

function toRows(
  features: AccessibilityFeatureDef[],
  usage: Record<string, number>,
): FeatureRow[] {
  return features.map((f) => {
    const { icon, tone } = iconForKey(f.key)
    return {
      id: f.key,
      key: f.key,
      name: f.label,
      description: f.description,
      category: f.category,
      places: usage[f.key] ?? 0,
      status: f.active ? 'active' : 'inactive',
      createdOn: 'Catalog',
      ago: f.active ? 'Active' : 'Inactive',
      icon,
      tone,
    }
  })
}

function iconNode(key: IconKey): ReactNode {
  const props = { width: 16, height: 16 }
  switch (key) {
    case 'wheelchair':
      return <IconWheelchair {...props} />
    case 'ramp':
      return <IconRamp {...props} />
    case 'elevator':
      return <IconElevator {...props} />
    case 'restroom':
      return <IconRestroom {...props} />
    case 'parking':
      return <IconParking {...props} />
    case 'door':
      return <IconDoor {...props} />
    case 'ear':
      return <IconEar {...props} />
    case 'braille':
      return <IconBraille {...props} />
    case 'eye':
      return <IconEyeOpen {...props} />
    case 'path':
      return <IconPath {...props} />
    case 'audio':
      return <IconAudio {...props} />
    case 'paw':
      return <IconPaw {...props} />
    case 'tactile':
      return <IconTactile {...props} />
  }
}

function categoryClass(cat: FeatureCategory) {
  switch (cat) {
    case 'Mobility':
      return 'mobility'
    case 'Facilities':
      return 'facilities'
    case 'Communication':
      return 'communication'
    case 'Sensory':
      return 'sensory'
    case 'Other':
    default:
      return 'facilities'
  }
}

export function AccessibilityFeaturesPage() {
  const { config, refreshConfig } = useAuth()
  const [features, setFeatures] = useState<AccessibilityFeatureDef[]>(
    () => config?.accessibilityFeatures ?? DEFAULT_ACCESSIBILITY_FEATURES,
  )
  const [usage, setUsage] = useState<Record<string, number>>({})
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [sortBy, setSortBy] = useState('newest')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [selected, setSelected] = useState<Set<string>>(new Set())
  const [menuId, setMenuId] = useState<string | null>(null)

  useEffect(() => {
    setFeatures(config?.accessibilityFeatures ?? DEFAULT_ACCESSIBILITY_FEATURES)
  }, [config?.accessibilityFeatures])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const places = await fetchPlaces(400)
        if (cancelled) return
        const counts: Record<string, number> = {}
        for (const p of places) {
          const feats = Array.isArray(p.features) ? (p.features as string[]) : []
          for (const key of feats) {
            counts[key] = (counts[key] ?? 0) + 1
          }
        }
        setUsage(counts)
        setError('')
      } catch (e) {
        if (!cancelled) {
          setUsage({})
          setError(e instanceof Error ? e.message : String(e))
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  const rows = useMemo(() => toRows(features, usage), [features, usage])

  const categories = useMemo(() => {
    return [...new Set(rows.map((r) => r.category))].sort()
  }, [rows])

  const stats = useMemo(() => {
    const active = features.filter((f) => f.active).length
    const inactive = features.length - active
    let mostUsed = '—'
    let mostUsedPlaces = 0
    for (const r of rows) {
      if (r.places > mostUsedPlaces) {
        mostUsedPlaces = r.places
        mostUsed = r.name
      }
    }
    return {
      total: features.length,
      active,
      inactive,
      mostUsed,
      mostUsedPlaces,
      recentlyAdded: features.length,
    }
  }, [features, rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    let list = rows.filter((r) => {
      if (statusFilter !== 'all' && r.status !== statusFilter) return false
      if (categoryFilter !== 'all' && r.category !== categoryFilter) return false
      if (!q) return true
      return (
        r.name.toLowerCase().includes(q) ||
        r.description.toLowerCase().includes(q) ||
        r.key.toLowerCase().includes(q)
      )
    })
    list = [...list].sort((a, b) => {
      if (sortBy === 'name') return a.name.localeCompare(b.name)
      if (sortBy === 'places') return b.places - a.places
      if (sortBy === 'oldest') return a.name.localeCompare(b.name)
      return a.name.localeCompare(b.name)
    })
    return list
  }, [rows, search, statusFilter, categoryFilter, sortBy])

  const displayTotal = filtered.length

  const pageCount = Math.max(1, Math.ceil(Math.max(filtered.length, 1) / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)
  const from = filtered.length === 0 ? 0 : (safePage - 1) * pageSize + 1
  const to = Math.min(safePage * pageSize, filtered.length)

  const allSelected =
    pageRows.length > 0 && pageRows.every((r) => selected.has(r.id))

  const persist = async (next: AccessibilityFeatureDef[]) => {
    setBusy(true)
    setError('')
    setFeatures(next)
    try {
      await saveAccessibilityFeatures(next)
      await refreshConfig()
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
      setFeatures(config?.accessibilityFeatures ?? DEFAULT_ACCESSIBILITY_FEATURES)
    } finally {
      setBusy(false)
    }
  }

  const setStatus = (row: FeatureRow, status: FeatureStatus) => {
    setMenuId(null)
    const next = features.map((f) =>
      f.key === row.key ? { ...f, active: status === 'active' } : f,
    )
    void persist(next)
  }

  const exportCsv = () => {
    const header = [
      'Feature',
      'Key',
      'Description',
      'Category',
      'Used In Places',
      'Status',
    ]
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [r.name, r.key, r.description, r.category, r.places, r.status]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-accessibility-features.csv'
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
    <div className="af-page">
      <header className="af-head">
        <div>
          <nav className="breadcrumbs">
            <Link to="/">Dashboard</Link>
            <span>/</span>
            <span className="current">Accessibility Features</span>
          </nav>
          <h1>Accessibility Features</h1>
          <p>Manage all accessibility features available for places and services.</p>
        </div>
        <div className="af-head-actions">
          <button type="button" className="af-btn ghost" onClick={exportCsv}>
            <IconDownload width={15} height={15} />
            Export
          </button>
          <button type="button" className="af-btn primary" disabled title="Catalog is managed via config">
            <IconPlus width={15} height={15} />
            Add New Feature
          </button>
        </div>
      </header>

      {error ? <div className="error">{error}</div> : null}

      <div className="af-stats">
        <article className="af-stat">
          <div className="af-stat-icon green">
            <IconGrid />
          </div>
          <div>
            <span>Total Features</span>
            <strong>{stats.total.toLocaleString()}</strong>
            <em>In catalog</em>
          </div>
        </article>
        <article className="af-stat">
          <div className="af-stat-icon blue">
            <IconCheckCircle />
          </div>
          <div>
            <span>Active Features</span>
            <strong>{stats.active.toLocaleString()}</strong>
            <em>Enabled for places</em>
          </div>
        </article>
        <article className="af-stat">
          <div className="af-stat-icon amber">
            <IconPause />
          </div>
          <div>
            <span>Inactive Features</span>
            <strong>{stats.inactive.toLocaleString()}</strong>
            <em>Hidden from catalog</em>
          </div>
        </article>
        <article className="af-stat">
          <div className="af-stat-icon purple">
            <IconStar />
          </div>
          <div>
            <span>Most Used</span>
            <strong className="af-stat-text">{stats.mostUsed}</strong>
            <em>Used in {stats.mostUsedPlaces.toLocaleString()} places</em>
          </div>
        </article>
        <article className="af-stat">
          <div className="af-stat-icon red">
            <IconPlusCircle />
          </div>
          <div>
            <span>Recently Added</span>
            <strong>{stats.recentlyAdded.toLocaleString()}</strong>
            <em>Catalog size</em>
          </div>
        </article>
      </div>

      <div className="af-filters">
        <div className="af-search">
          <IconSearch className="af-search-icon" />
          <input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Search features..."
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
          value={categoryFilter}
          onChange={(e) => {
            setCategoryFilter(e.target.value)
            setPage(1)
          }}
        >
          <option value="all">All Categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>
              {c}
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
          <option value="newest">Sort by: Name</option>
          <option value="oldest">Sort by: Name (A–Z)</option>
          <option value="name">Sort by: Name</option>
          <option value="places">Sort by: Most Used</option>
        </select>
        <button type="button" className="af-btn ghost">
          <IconFilter width={15} height={15} />
          Filters
        </button>
      </div>

      <div className="af-table-card">
        <div className="af-table-scroll">
          <table className="af-table">
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
                <th>Feature</th>
                <th>Category</th>
                <th>Used In Places</th>
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
                    <div className="af-feat">
                      <div className={`af-icon ${r.tone}`}>{iconNode(r.icon)}</div>
                      <div>
                        <strong>{r.name}</strong>
                        <span>{r.description}</span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <span className={`af-cat ${categoryClass(r.category)}`}>
                      {r.category}
                    </span>
                  </td>
                  <td className="af-places">{r.places.toLocaleString()}</td>
                  <td>
                    <span className={`af-pill ${r.status}`}>
                      {r.status === 'active' ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>
                    <div className="af-when">
                      <strong>{r.createdOn}</strong>
                      <span>{r.ago}</span>
                    </div>
                  </td>
                  <td>
                    <div className="af-actions">
                      <button type="button" title="Edit" disabled={busy}>
                        <IconPencil width={15} height={15} />
                      </button>
                      <div className="af-more-wrap">
                        <button
                          type="button"
                          title="More"
                          disabled={busy}
                          onClick={() => setMenuId((id) => (id === r.id ? null : r.id))}
                        >
                          <IconMore width={16} height={16} />
                        </button>
                        {menuId === r.id ? (
                          <div className="af-menu">
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
            {rows.length === 0
              ? 'No accessibility features in the catalog.'
              : 'No features match your filters.'}
          </div>
        ) : null}

        <div className="af-footer">
          <span>
            Showing {from} to {to} of {displayTotal.toLocaleString()} features
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
          <div className="af-pages">
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
