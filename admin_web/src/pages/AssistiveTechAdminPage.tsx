import { useEffect, useMemo, useState, type ChangeEvent, type ReactNode } from 'react'
import {
  fetchAssistiveCategories,
  fetchAssistiveProducts,
  setAssistiveProductStatus,
  uploadRehabAsset,
  upsertAssistiveCategory,
  upsertAssistiveProduct,
  type RehabContentStatus,
} from '../lib/data'
import {
  IconAccessibility,
  IconCloud,
  IconCode,
  IconEar,
  IconEyeOpen,
  IconGrid,
  IconHeadset,
  IconHeart,
  IconMessage,
  IconPlus,
  IconSearch,
  IconSettings,
  IconShieldCheck,
  IconShoppingBag,
  IconStarFill,
  IconTruck,
  IconUpload,
  IconUsers,
  IconUtensils,
  IconWheelchair,
  IconChevronRight,
} from '../components/icons'
import {
  DetailPanel,
  PageHeader,
  StatusPill,
} from '../components/PageChrome'

type Doc = Record<string, unknown> & { id: string }
type ViewKey = 'marketplace' | 'categories'

const STATUS_OPTIONS: RehabContentStatus[] = [
  'draft',
  'review',
  'published',
  'archived',
]

const AT_CATS = [
  { id: 'all', label: 'All', bg: '#dbeafe', color: '#2563eb', icon: 'grid' },
  { id: 'mobility', label: 'Mobility', bg: '#ccfbf1', color: '#0d9488', icon: 'wheelchair' },
  { id: 'prosthetics', label: 'Prosthetics & Orthotics', bg: '#fce7f3', color: '#db2777', icon: 'access' },
  { id: 'hearing', label: 'Hearing', bg: '#ffe4e6', color: '#e11d48', icon: 'ear' },
  { id: 'vision', label: 'Vision', bg: '#ede9fe', color: '#7c3aed', icon: 'eye' },
  { id: 'communication', label: 'Communication', bg: '#dcfce7', color: '#16a34a', icon: 'message' },
  { id: 'daily', label: 'Daily Living', bg: '#ffedd5', color: '#ea580c', icon: 'utensils' },
  { id: 'computer', label: 'Computer Access', bg: '#e0e7ff', color: '#4f46e5', icon: 'code' },
  { id: 'smart', label: 'Smart Home', bg: '#d1fae5', color: '#059669', icon: 'cloud' },
  { id: 'health', label: 'Health & Monitoring', bg: '#fce7f3', color: '#db2777', icon: 'heart' },
  { id: 'recreation', label: 'Recreation & Sports', bg: '#e0f2fe', color: '#0284c7', icon: 'users' },
] as const

const FILTER_CATS = [
  { id: 'mobility', label: 'Mobility', count: 124 },
  { id: 'prosthetics', label: 'Prosthetics & Orthotics', count: 86 },
  { id: 'hearing', label: 'Hearing', count: 67 },
  { id: 'vision', label: 'Vision', count: 72 },
  { id: 'communication', label: 'Communication', count: 54 },
  { id: 'daily', label: 'Daily Living', count: 98 },
  { id: 'computer', label: 'Computer Access', count: 45 },
  { id: 'smart', label: 'Smart Home', count: 38 },
  { id: 'health', label: 'Health & Monitoring', count: 60 },
  { id: 'recreation', label: 'Recreation & Sports', count: 49 },
]

const DEMO_PRODUCTS: Doc[] = [
  {
    id: 'demo-at1',
    title: 'Lightweight Wheelchair',
    categoryId: 'mobility',
    priceFrom: 499,
    currency: 'USD',
    rating: 4.8,
    reviewCount: 124,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=600&q=80',
  },
  {
    id: 'demo-at2',
    title: 'Prosthetic Leg (Carbon Fiber)',
    categoryId: 'prosthetics',
    priceFrom: 1200,
    currency: 'USD',
    rating: 4.7,
    reviewCount: 86,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1559757175-5700dde21947?w=600&q=80',
  },
  {
    id: 'demo-at3',
    title: 'Rechargeable Hearing Aids',
    categoryId: 'hearing',
    priceFrom: 799,
    currency: 'USD',
    rating: 4.9,
    reviewCount: 312,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1598301257982-0bfd18351b3b?w=600&q=80',
  },
  {
    id: 'demo-at4',
    title: 'AI Smart Glasses for Low Vision',
    categoryId: 'vision',
    priceFrom: 1499,
    currency: 'USD',
    rating: 4.6,
    reviewCount: 156,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=600&q=80',
  },
  {
    id: 'demo-at5',
    title: 'AAC Communication Tablet',
    categoryId: 'communication',
    priceFrom: 650,
    currency: 'USD',
    rating: 4.8,
    reviewCount: 87,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&q=80',
  },
  {
    id: 'demo-at6',
    title: 'Adaptive Keyboard',
    categoryId: 'computer',
    priceFrom: 120,
    currency: 'USD',
    rating: 4.5,
    reviewCount: 203,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600&q=80',
  },
  {
    id: 'demo-at7',
    title: 'Adjustable Care Bed',
    categoryId: 'daily',
    priceFrom: 1800,
    currency: 'USD',
    rating: 4.7,
    reviewCount: 142,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=600&q=80',
  },
  {
    id: 'demo-at8',
    title: 'Shower Chair',
    categoryId: 'daily',
    priceFrom: 250,
    currency: 'USD',
    rating: 4.4,
    reviewCount: 76,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=600&q=80',
  },
  {
    id: 'demo-at9',
    title: 'Smart Home Hub',
    categoryId: 'smart',
    priceFrom: 99,
    currency: 'USD',
    rating: 4.6,
    reviewCount: 389,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=600&q=80',
  },
  {
    id: 'demo-at10',
    title: 'Handcycle for Exercise',
    categoryId: 'recreation',
    priceFrom: 1100,
    currency: 'USD',
    rating: 4.9,
    reviewCount: 54,
    status: 'published',
    imageUrl: 'https://images.unsplash.com/photo-1517649763962-0c6230660277?w=600&q=80',
  },
]

const emptyProductForm = () => ({
  id: null as string | null,
  title: '',
  categoryId: '',
  subtype: '',
  priceFrom: '',
  currency: 'EUR',
  rating: '',
  reviewCount: '',
  imageUrl: '',
  featuresText: '',
  specsText: '',
  vendorName: '',
  buyUrl: '',
  status: 'draft' as RehabContentStatus,
  locale: 'en',
  sortOrder: '0',
})

const emptyCategoryForm = () => ({
  id: '',
  title: '',
  shortLabel: '',
  description: '',
  sortOrder: '0',
  filters: '',
  active: true,
})

function linesToList(value: string): string[] {
  return value
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
}

function parseSpecs(value: string): Record<string, string> {
  const out: Record<string, string> = {}
  for (const line of linesToList(value)) {
    const idx = line.indexOf(':')
    if (idx <= 0) continue
    const key = line.slice(0, idx).trim()
    const val = line.slice(idx + 1).trim()
    if (key) out[key] = val
  }
  return out
}

function specsToText(specs: unknown): string {
  if (!specs || typeof specs !== 'object' || Array.isArray(specs)) return ''
  return Object.entries(specs as Record<string, unknown>)
    .map(([k, v]) => `${k}: ${String(v)}`)
    .join('\n')
}

function productFromDoc(doc: Doc) {
  const status = String(doc.status ?? (doc.active === false ? 'archived' : 'draft'))
  const features = Array.isArray(doc.features)
    ? (doc.features as unknown[]).map((s) => String(s))
    : typeof doc.features === 'string'
      ? String(doc.features).split('\n')
      : []
  return {
    id: doc.id,
    title: String(doc.title ?? doc.name ?? ''),
    categoryId: String(doc.categoryId ?? ''),
    subtype: String(doc.subtype ?? ''),
    priceFrom: doc.priceFrom != null ? String(doc.priceFrom) : '',
    currency: String(doc.currency ?? 'EUR'),
    rating: doc.rating != null ? String(doc.rating) : '',
    reviewCount: doc.reviewCount != null ? String(doc.reviewCount) : '',
    imageUrl: String(doc.imageUrl ?? ''),
    featuresText: features.join('\n'),
    specsText: specsToText(doc.specs),
    vendorName: String(doc.vendorName ?? ''),
    buyUrl: String(doc.buyUrl ?? ''),
    status: (STATUS_OPTIONS.includes(status as RehabContentStatus)
      ? status
      : 'draft') as RehabContentStatus,
    locale: String(doc.locale ?? 'en'),
    sortOrder: String(doc.sortOrder ?? 0),
  }
}

function categoryFromDoc(doc: Doc) {
  const filters = Array.isArray(doc.filters)
    ? (doc.filters as unknown[]).map((s) => String(s)).join(', ')
    : String(doc.filters ?? '')
  return {
    id: doc.id,
    title: String(doc.title ?? doc.name ?? ''),
    shortLabel: String(doc.shortLabel ?? ''),
    description: String(doc.description ?? ''),
    sortOrder: String(doc.sortOrder ?? 0),
    filters,
    active: doc.active !== false,
  }
}

function catIcon(kind: string, color: string): ReactNode {
  const p = { width: 20, height: 20, style: { color } as const }
  switch (kind) {
    case 'wheelchair':
      return <IconWheelchair {...p} />
    case 'access':
      return <IconAccessibility {...p} />
    case 'ear':
      return <IconEar {...p} />
    case 'eye':
      return <IconEyeOpen {...p} />
    case 'message':
      return <IconMessage {...p} />
    case 'utensils':
      return <IconUtensils {...p} />
    case 'code':
      return <IconCode {...p} />
    case 'cloud':
      return <IconCloud {...p} />
    case 'heart':
      return <IconHeart {...p} />
    case 'users':
      return <IconUsers {...p} />
    default:
      return <IconGrid {...p} />
  }
}

function formatPrice(currency: string, price: unknown) {
  if (price == null || price === '') return 'Price on request'
  const n = Number(price)
  const sym = currency === 'USD' || currency === '$' ? '$' : currency === 'EUR' ? '€' : `${currency} `
  if (Number.isNaN(n)) return `${sym}${price}`
  return `${sym}${n.toLocaleString()}`
}

function tagClass(catId: string) {
  const id = catId.toLowerCase()
  if (id.includes('mobil')) return 'al-product-tag--teal'
  if (id.includes('prost')) return 'al-product-tag--pink'
  if (id.includes('hear')) return 'al-product-tag--rose'
  if (id.includes('vis')) return 'al-product-tag--blue'
  if (id.includes('comm')) return 'al-product-tag--green'
  if (id.includes('daily')) return 'al-product-tag--purple'
  if (id.includes('comp')) return 'al-product-tag--indigo'
  if (id.includes('smart')) return 'al-product-tag--rose'
  if (id.includes('health')) return 'al-product-tag--orange'
  if (id.includes('rec')) return 'al-product-tag--sky'
  return 'al-product-tag--blue'
}

function productTagLabel(catId: string, fullLabel: string) {
  if (catId.toLowerCase().includes('prost')) return 'Prosthetics'
  return fullLabel
}

export function AssistiveTechAdminPage() {
  const [view, setView] = useState<ViewKey>('marketplace')
  const [products, setProducts] = useState<Doc[]>([])
  const [categories, setCategories] = useState<Doc[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')
  const [q, setQ] = useState('')
  const [cat, setCat] = useState('all')
  const [busyId, setBusyId] = useState('')
  const [saving, setSaving] = useState(false)
  const [detailOpen, setDetailOpen] = useState(false)
  const [productForm, setProductForm] = useState(emptyProductForm)
  const [categoryForm, setCategoryForm] = useState(emptyCategoryForm)
  const [categoryIdLocked, setCategoryIdLocked] = useState(false)
  const [priceMax, setPriceMax] = useState(5000)

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      const [p, c] = await Promise.all([
        fetchAssistiveProducts(300),
        fetchAssistiveCategories(100),
      ])
      setProducts(p)
      setCategories(c)
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to load assistive tech data',
      )
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const displayProducts = products.length ? products : DEMO_PRODUCTS

  const filteredProducts = useMemo(() => {
    const needle = q.trim().toLowerCase()
    return displayProducts.filter((p) => {
      const categoryId = String(p.categoryId ?? '').toLowerCase()
      if (cat !== 'all' && !categoryId.includes(cat) && categoryId !== cat) {
        const label = categories.find((c) => c.id === p.categoryId)
        const title = String(label?.title ?? label?.name ?? '').toLowerCase()
        if (!title.includes(cat) && !categoryId.includes(cat.slice(0, 4))) return false
      }
      const price = Number(p.priceFrom ?? 0)
      if (price > priceMax) return false
      if (!needle) return true
      return (
        String(p.title ?? p.name ?? '').toLowerCase().includes(needle) ||
        categoryId.includes(needle) ||
        String(p.vendorName ?? '').toLowerCase().includes(needle) ||
        String(p.id).toLowerCase().includes(needle)
      )
    })
  }, [displayProducts, q, cat, priceMax, categories])

  const filteredCategories = useMemo(() => {
    const needle = q.trim().toLowerCase()
    if (!needle) return categories
    return categories.filter((c) => {
      return (
        String(c.title ?? c.name ?? '').toLowerCase().includes(needle) ||
        String(c.shortLabel ?? '').toLowerCase().includes(needle) ||
        String(c.id).toLowerCase().includes(needle)
      )
    })
  }, [categories, q])

  const saveProduct = async () => {
    if (!productForm.title.trim()) {
      setError('Product title is required')
      return
    }
    setSaving(true)
    setError('')
    setMsg('')
    try {
      const id = await upsertAssistiveProduct(productForm.id, {
        title: productForm.title.trim(),
        categoryId: productForm.categoryId.trim(),
        subtype: productForm.subtype.trim(),
        priceFrom: Number(productForm.priceFrom) || 0,
        currency: productForm.currency.trim() || 'EUR',
        rating: Number(productForm.rating) || 0,
        reviewCount: Number(productForm.reviewCount) || 0,
        imageUrl: productForm.imageUrl.trim(),
        features: linesToList(productForm.featuresText),
        specs: parseSpecs(productForm.specsText),
        vendorName: productForm.vendorName.trim(),
        buyUrl: productForm.buyUrl.trim(),
        status: productForm.status,
        locale: productForm.locale.trim() || 'en',
        sortOrder: Number(productForm.sortOrder) || 0,
      })
      setProductForm((s) => ({ ...s, id }))
      setMsg(productForm.id ? 'Product saved.' : 'Product created.')
      setDetailOpen(false)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save product')
    } finally {
      setSaving(false)
    }
  }

  const setProductStatus = async (id: string, status: RehabContentStatus) => {
    setBusyId(id)
    setError('')
    try {
      await setAssistiveProductStatus(id, status)
      setProductForm((s) => (s.id === id ? { ...s, status } : s))
      setProducts((prev) =>
        prev.map((p) => (p.id === id ? { ...p, status } : p)),
      )
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Status update failed')
    } finally {
      setBusyId('')
    }
  }

  const uploadImage = async (file: File) => {
    const id = productForm.id ?? `draft-${Date.now()}`
    setBusyId('upload')
    setError('')
    try {
      const url = await uploadRehabAsset(
        file,
        `assistive/products/${id}/main.jpg`,
      )
      setProductForm((s) => ({ ...s, imageUrl: url, id: s.id ?? id }))
      setMsg('Product image uploaded.')
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

  const saveCategory = async () => {
    const id = categoryForm.id.trim()
    if (!id || !categoryForm.title.trim()) {
      setError('Category id and title are required')
      return
    }
    setSaving(true)
    setError('')
    setMsg('')
    try {
      await upsertAssistiveCategory(id, {
        title: categoryForm.title.trim(),
        shortLabel: categoryForm.shortLabel.trim(),
        description: categoryForm.description.trim(),
        sortOrder: Number(categoryForm.sortOrder) || 0,
        filters: categoryForm.filters
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
        active: categoryForm.active,
      })
      setMsg('Category saved.')
      setCategoryForm(emptyCategoryForm())
      setCategoryIdLocked(false)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save category')
    } finally {
      setSaving(false)
    }
  }

  const gridStyle = {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
    gap: 10,
    marginBottom: 14,
  } as const

  const categoryLabel = (id: string) => {
    const known = AT_CATS.find((c) => c.id === id || id.includes(c.id))
    if (known && known.id !== 'all') return known.label
    const c = categories.find((x) => x.id === id)
    return c ? String(c.title ?? c.name ?? id) : id || 'General'
  }

  return (
    <div className="al-page al-at-page">
      <PageHeader
        title="Assistive Technology"
        subtitle="Discover, compare and access assistive devices and technologies for a more independent life."
        primaryAction={{
          label: 'Add Product',
          onClick: () => {
            setView('marketplace')
            setProductForm(emptyProductForm())
            setDetailOpen(true)
          },
        }}
        secondaryAction={
          <button
            type="button"
            className="al-btn al-btn--ghost"
            onClick={() => setView(view === 'categories' ? 'marketplace' : 'categories')}
          >
            {view === 'categories' ? '← Marketplace' : 'Manage Categories'}
          </button>
        }
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

      {view === 'marketplace' ? (
        <>
          <div className="al-cat-scroll">
            {AT_CATS.map((c) => (
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

          <div className="al-at-hero">
            <div className="al-at-hero-banner">
              <div className="al-at-hero-copy">
                <h2>Technology Empowers Ability</h2>
                <p>Explore innovative assistive solutions for a more inclusive world.</p>
                <button
                  type="button"
                  className="al-btn al-btn--primary al-at-hero-cta"
                  onClick={() => setCat('all')}
                >
                  Learn More <IconChevronRight width={16} height={16} />
                </button>
              </div>
              <p className="al-at-hero-quote">
                “More Independence
                <br />
                Brighter Tomorrow”
              </p>
            </div>
            <div className="al-at-hero-side">
              <div className="al-at-cta-card">
                <div className="al-at-cta-icon" aria-hidden>
                  <IconUsers width={18} height={18} />
                </div>
                <div className="al-at-cta-text">
                  <strong>Need Help Choosing?</strong>
                  <span>Get personalized recommendations from our experts.</span>
                </div>
                <a className="al-btn al-btn--outline al-at-cta-btn" href="/support">
                  Talk to an Expert
                </a>
              </div>
              <div className="al-at-cta-card">
                <div className="al-at-cta-icon" aria-hidden>
                  <IconSettings width={18} height={18} />
                </div>
                <div className="al-at-cta-text">
                  <strong>Request a Custom Solution</strong>
                  <span>Can&apos;t find what you need? Tell us your requirements.</span>
                </div>
                <button type="button" className="al-btn al-btn--outline al-at-cta-btn">
                  Submit Request
                </button>
              </div>
            </div>
          </div>

          <div className="al-at-market">
            <div className="al-at-market-main">
              <div className="al-at-toolbar">
                <div className="al-at-search">
                  <input
                    value={q}
                    onChange={(e) => setQ(e.target.value)}
                    placeholder="Search products, brands, or keywords..."
                  />
                  <IconSearch width={16} height={16} />
                </div>
                <select value={cat} onChange={(e) => setCat(e.target.value)} aria-label="Category">
                  <option value="all">All Categories</option>
                  {AT_CATS.filter((c) => c.id !== 'all').map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.label}
                    </option>
                  ))}
                </select>
                <select defaultValue="all" aria-label="User Type">
                  <option value="all">All Users</option>
                  <option value="pwd">Persons with Disabilities</option>
                  <option value="seniors">Senior Citizens</option>
                  <option value="caregivers">Caregivers</option>
                </select>
                <select
                  value={priceMax >= 5000 ? 'all' : String(priceMax)}
                  onChange={(e) =>
                    setPriceMax(e.target.value === 'all' ? 5000 : Number(e.target.value))
                  }
                  aria-label="Price Range"
                >
                  <option value="all">All Prices</option>
                  <option value="250">Under $250</option>
                  <option value="500">Under $500</option>
                  <option value="1000">Under $1,000</option>
                </select>
                <select defaultValue="all" aria-label="Availability">
                  <option value="all">All</option>
                  <option value="stock">In Stock</option>
                  <option value="preorder">Pre-order</option>
                  <option value="local">Available Locally</option>
                </select>
                <div className="al-at-sort">
                  <span>Sort By</span>
                  <select defaultValue="relevant" aria-label="Sort By">
                    <option value="relevant">Most Relevant</option>
                    <option value="price">Price: Low to High</option>
                    <option value="rating">Highest Rated</option>
                  </select>
                </div>
              </div>

              {loading ? (
                <p className="muted">Loading…</p>
              ) : filteredProducts.length === 0 ? (
                <div className="al-table-card" style={{ padding: 20 }}>
                  <p className="muted" style={{ margin: 0 }}>
                    No products found.
                  </p>
                </div>
              ) : (
                <div className="al-product-grid">
                  {filteredProducts.map((p) => {
                    const title = String(p.title ?? p.name ?? 'Untitled')
                    const currency = String(p.currency ?? 'USD')
                    const price = formatPrice(currency, p.priceFrom)
                    const img = String(p.imageUrl ?? '')
                    const catId = String(p.categoryId ?? '')
                    const catLabel = categoryLabel(catId)
                    const rating = Number(p.rating ?? 4.5) || 4.5
                    const reviews = Number(p.reviewCount ?? 0)
                    return (
                      <article
                        key={p.id}
                        className="al-product-card"
                        onClick={() => {
                          if (!String(p.id).startsWith('demo-')) {
                            setProductForm(productFromDoc(p))
                            setDetailOpen(true)
                          }
                        }}
                      >
                        <div className="al-product-media">
                          {img ? (
                            <img src={img} alt="" />
                          ) : (
                            <div className="al-product-placeholder">
                              <IconAccessibility width={28} height={28} />
                            </div>
                          )}
                          <button
                            type="button"
                            className="al-product-fav"
                            aria-label="Favorite"
                            onClick={(ev) => ev.stopPropagation()}
                          >
                            <IconHeart width={14} height={14} />
                          </button>
                        </div>
                        <div className="al-product-body">
                          <strong>{title}</strong>
                          <span className="al-product-rating">
                            <IconStarFill width={12} height={12} />
                            {rating.toFixed(1)}{' '}
                            <span>({reviews || 42} reviews)</span>
                          </span>
                          <div className="al-product-price">{price}</div>
                          <span className={`al-product-tag ${tagClass(catId)}`}>
                            {productTagLabel(catId, catLabel)}
                          </span>
                          <button
                            type="button"
                            className="al-product-cart"
                            onClick={(ev) => {
                              ev.stopPropagation()
                              if (!String(p.id).startsWith('demo-')) {
                                setProductForm(productFromDoc(p))
                                setDetailOpen(true)
                              }
                            }}
                          >
                            <IconShoppingBag width={14} height={14} /> Add to Cart
                          </button>
                        </div>
                      </article>
                    )
                  })}
                </div>
              )}

              <div className="al-trust-row">
                <div className="al-trust-item">
                  <div className="icon">
                    <IconTruck width={20} height={20} />
                  </div>
                  <div>
                    <strong>Worldwide Shipping</strong>
                    <span>Accessible products to your doorstep.</span>
                  </div>
                </div>
                <div className="al-trust-item">
                  <div className="icon">
                    <IconShieldCheck width={20} height={20} />
                  </div>
                  <div>
                    <strong>Verified Products</strong>
                    <span>Quality & safety assured.</span>
                  </div>
                </div>
                <div className="al-trust-item">
                  <div className="icon">
                    <IconHeadset width={20} height={20} />
                  </div>
                  <div>
                    <strong>Expert Support</strong>
                    <span>Get help from specialists.</span>
                  </div>
                </div>
                <div className="al-trust-item">
                  <div className="icon al-trust-icon--heart">
                    <IconHeart width={20} height={20} />
                  </div>
                  <div>
                    <strong>Inclusive Marketplace</strong>
                    <span>Built for a more independent world.</span>
                  </div>
                </div>
              </div>
            </div>

            <aside className="al-filter-panel" aria-label="Filter products">
              <div className="al-filter-panel-head">
                <h3>Filter Products</h3>
                <button
                  type="button"
                  className="al-filter-reset"
                  onClick={() => {
                    setCat('all')
                    setPriceMax(5000)
                    setQ('')
                  }}
                >
                  Reset
                </button>
              </div>
              <strong className="al-filter-label">Category</strong>
              <div className="al-filter-checks">
                {FILTER_CATS.map((c) => (
                  <label key={c.id}>
                    <span className="left">
                      <input
                        type="checkbox"
                        checked={cat === c.id}
                        onChange={() => setCat(cat === c.id ? 'all' : c.id)}
                      />
                      {c.label}
                    </span>
                    <span className="count">({c.count})</span>
                  </label>
                ))}
              </div>
              <strong className="al-filter-label">Price Range</strong>
              <div className="al-range-wrap">
                <input
                  type="range"
                  min={0}
                  max={5000}
                  step={50}
                  value={priceMax}
                  onChange={(e) => setPriceMax(Number(e.target.value))}
                />
                <div className="al-range-labels">
                  <span>$0</span>
                  <span>$5,000+</span>
                </div>
              </div>
              <strong className="al-filter-label">Availability</strong>
              <div className="al-filter-checks">
                <label>
                  <span className="left">
                    <input type="checkbox" defaultChecked /> In Stock
                  </span>
                  <span className="count">(342)</span>
                </label>
                <label>
                  <span className="left">
                    <input type="checkbox" /> Pre-order
                  </span>
                  <span className="count">(28)</span>
                </label>
                <label>
                  <span className="left">
                    <input type="checkbox" /> Available Locally
                  </span>
                  <span className="count">(76)</span>
                </label>
              </div>
              <strong className="al-filter-label">Brand</strong>
              <select defaultValue="all" className="al-filter-brand">
                <option value="all">All Brands</option>
                <option value="ability">AbilityTech</option>
                <option value="mobility">MobilityPro</option>
                <option value="hear">HearWell</option>
              </select>
              <button type="button" className="al-btn al-btn--primary al-filter-apply">
                Apply Filters
              </button>
            </aside>
          </div>
        </>
      ) : null}

      <DetailPanel
        open={detailOpen && view === 'marketplace'}
        onClose={() => setDetailOpen(false)}
        title={productForm.id ? 'Edit product' : 'Add product'}
        footer={
          <button
            type="button"
            className="al-btn al-btn--primary"
            style={{ width: '100%' }}
            disabled={saving}
            onClick={() => void saveProduct()}
          >
            <IconPlus width={14} height={14} />{' '}
            {productForm.id ? 'Save product' : 'Create product'}
          </button>
        }
      >
        <div style={{ display: 'grid', gap: 10 }}>
          <input
            placeholder="Title"
            value={productForm.title}
            onChange={(e) => setProductForm((s) => ({ ...s, title: e.target.value }))}
          />
          <label className="field">
            Category
            <select
              value={productForm.categoryId}
              onChange={(e) => setProductForm((s) => ({ ...s, categoryId: e.target.value }))}
            >
              <option value="">— Select —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {String(c.title ?? c.name ?? c.id)}
                </option>
              ))}
              {AT_CATS.filter((c) => c.id !== 'all').map((c) => (
                <option key={`fallback-${c.id}`} value={c.id}>
                  {c.label}
                </option>
              ))}
            </select>
          </label>
          <input
            placeholder="Subtype"
            value={productForm.subtype}
            onChange={(e) => setProductForm((s) => ({ ...s, subtype: e.target.value }))}
          />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <input
              placeholder="Price from"
              value={productForm.priceFrom}
              onChange={(e) => setProductForm((s) => ({ ...s, priceFrom: e.target.value }))}
            />
            <input
              placeholder="Currency"
              value={productForm.currency}
              onChange={(e) => setProductForm((s) => ({ ...s, currency: e.target.value }))}
            />
          </div>
          <input
            placeholder="Vendor name"
            value={productForm.vendorName}
            onChange={(e) => setProductForm((s) => ({ ...s, vendorName: e.target.value }))}
          />
          <input
            placeholder="Buy URL"
            value={productForm.buyUrl}
            onChange={(e) => setProductForm((s) => ({ ...s, buyUrl: e.target.value }))}
          />
          <label className="field">
            Status
            <select
              value={productForm.status}
              onChange={(e) =>
                setProductForm((s) => ({
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
          <textarea
            placeholder="Features (one per line)"
            value={productForm.featuresText}
            onChange={(e) => setProductForm((s) => ({ ...s, featuresText: e.target.value }))}
            style={{ minHeight: 72 }}
          />
          <textarea
            placeholder="Specs (key: value per line)"
            value={productForm.specsText}
            onChange={(e) => setProductForm((s) => ({ ...s, specsText: e.target.value }))}
            style={{ minHeight: 72 }}
          />
          <div>
            <label className="muted">Image URL</label>
            <input
              value={productForm.imageUrl}
              onChange={(e) => setProductForm((s) => ({ ...s, imageUrl: e.target.value }))}
              placeholder="https://…"
            />
            <label className="al-btn al-btn--outline" style={{ marginTop: 8, display: 'inline-flex' }}>
              <IconUpload width={14} height={14} /> Upload image
              <input
                type="file"
                accept="image/*"
                hidden
                disabled={busyId === 'upload'}
                onChange={onFile((f) => void uploadImage(f))}
              />
            </label>
          </div>
          {productForm.id ? (
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {STATUS_OPTIONS.map((s) => (
                <button
                  key={s}
                  type="button"
                  className="al-btn al-btn--outline"
                  disabled={busyId === productForm.id || productForm.status === s}
                  onClick={() => void setProductStatus(productForm.id!, s)}
                >
                  → {s}
                </button>
              ))}
            </div>
          ) : null}
        </div>
      </DetailPanel>

      {view === 'categories' ? (
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
              {categoryForm.id ? 'Edit category' : 'Add category'}
            </h3>
            {categoryForm.id || categoryIdLocked ? (
              <button
                type="button"
                className="btn"
                onClick={() => {
                  setCategoryForm(emptyCategoryForm())
                  setCategoryIdLocked(false)
                }}
              >
                New
              </button>
            ) : null}
          </div>

          <div style={gridStyle}>
            <input
              placeholder="Id (slug)"
              value={categoryForm.id}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, id: e.target.value }))
              }
              disabled={categoryIdLocked}
            />
            <input
              placeholder="Title"
              value={categoryForm.title}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, title: e.target.value }))
              }
            />
            <input
              placeholder="Short label"
              value={categoryForm.shortLabel}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, shortLabel: e.target.value }))
              }
            />
            <input
              placeholder="Sort order"
              value={categoryForm.sortOrder}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, sortOrder: e.target.value }))
              }
            />
            <input
              placeholder="Filters (comma-separated)"
              value={categoryForm.filters}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, filters: e.target.value }))
              }
              style={{ gridColumn: '1 / -1' }}
            />
            <textarea
              placeholder="Description"
              value={categoryForm.description}
              onChange={(e) =>
                setCategoryForm((s) => ({ ...s, description: e.target.value }))
              }
              style={{ gridColumn: '1 / -1', minHeight: 72 }}
            />
            <label
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 8,
              }}
            >
              <input
                type="checkbox"
                checked={categoryForm.active}
                onChange={(e) =>
                  setCategoryForm((s) => ({ ...s, active: e.target.checked }))
                }
              />
              Active
            </label>
          </div>

          <div style={{ marginBottom: 18 }}>
            <button
              type="button"
              className="btn primary"
              disabled={saving}
              onClick={() => void saveCategory()}
            >
              <IconPlus /> Save category
            </button>
          </div>

          <div
            className="search-wrap"
            style={{ margin: '8px 0 12px', maxWidth: 360 }}
          >
            <IconSearch />
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="Search categories…"
            />
          </div>

          {loading ? (
            <p className="muted">Loading…</p>
          ) : filteredCategories.length === 0 ? (
            <p className="muted">No categories found.</p>
          ) : (
            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Id</th>
                    <th>Title</th>
                    <th>Short label</th>
                    <th>Sort</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredCategories.map((c) => {
                    const active = c.active !== false
                    return (
                      <tr
                        key={c.id}
                        style={{ cursor: 'pointer' }}
                        onClick={() => {
                          setCategoryForm(categoryFromDoc(c))
                          setCategoryIdLocked(true)
                        }}
                      >
                        <td>
                          <code style={{ fontSize: 12 }}>{c.id}</code>
                        </td>
                        <td>{String(c.title ?? c.name ?? '—')}</td>
                        <td>{String(c.shortLabel ?? '—')}</td>
                        <td>{String(c.sortOrder ?? 0)}</td>
                        <td>
                          <StatusPill tone={active ? 'ok' : 'muted'}>
                            {active ? 'Active' : 'Inactive'}
                          </StatusPill>
                        </td>
                        <td onClick={(ev) => ev.stopPropagation()}>
                          <button
                            type="button"
                            className="btn"
                            onClick={() => {
                              setCategoryForm(categoryFromDoc(c))
                              setCategoryIdLocked(true)
                            }}
                          >
                            Edit
                          </button>
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
    </div>
  )
}
