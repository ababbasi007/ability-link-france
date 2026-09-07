import { useEffect, useMemo, useState, type ReactNode } from 'react'
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
  IconBriefcase,
  IconCalendar,
  IconCheckCircle,
  IconChevronLeft,
  IconChevronRight,
  IconClock,
  IconDoor,
  IconEye,
  IconFileText,
  IconGlobe,
  IconHeart,
  IconLayers,
  IconMail,
  IconMapPin,
  IconMessage,
  IconMore,
  IconPencil,
  IconPhone,
  IconRestroom,
  IconShieldCheck,
  IconStar,
  IconUpload,
  IconUser,
  IconUsers,
  IconWheelchair,
  IconX,
} from '../components/icons'
import {
  createProvider,
  fetchProviders,
  PROVIDER_DOCUMENT_TYPES,
  saveProviderDocuments,
  setProviderFlags,
  uploadProviderDocument,
  type ProviderDocument,
  type ProviderDocumentType,
} from '../lib/data'

export type ProviderKind = 'doctors' | 'therapists' | 'caregivers'

type Doc = Record<string, unknown> & { id: string }

type ProfileRow = {
  id: string
  name: string
  title: string
  specialty: string
  bio: string
  city: string
  photoUrl: string
  rating: number
  reviewCount: number
  priceFrom: number
  currency: string
  languages: string[]
  services: string[]
  skills: string[]
  accessibilityTags: string[]
  yearsExperience: number
  verified: boolean
  availableNow: boolean
  hidden: boolean
  assistanceType: string
  availabilitySlots: string[]
  category: string
  ownerUid: string
  documents: ProviderDocument[]
  raw: Doc
}

const CAREGIVER_TABS = [
  { id: 'all', label: 'All Caregivers' },
  { id: 'professional', label: 'Professional Caregivers' },
  { id: 'family', label: 'Family Caregivers' },
  { id: 'support', label: 'Support Workers' },
  { id: 'location', label: 'By Location' },
  { id: 'availability', label: 'By Availability' },
]

const SERVICE_TABS = [
  { id: 'all', label: 'All Services' },
  { id: 'healthcare', label: 'Healthcare' },
  { id: 'rehab', label: 'Rehabilitation' },
  { id: 'homecare', label: 'Home Care' },
  { id: 'education', label: 'Education' },
  { id: 'transport', label: 'Transport' },
  { id: 'tourism', label: 'Tourism' },
  { id: 'assistive', label: 'Assistive Technology' },
  { id: 'legal', label: 'Legal & Financial' },
  { id: 'other', label: 'Other' },
]

const PROFILE_DETAIL_TABS_CAREGIVER = [
  { id: 'overview', label: 'Overview' },
  { id: 'documents', label: 'Documents' },
  { id: 'availability', label: 'Availability' },
  { id: 'reviews', label: 'Reviews' },
]

const PROFILE_DETAIL_TABS_SERVICE = [
  { id: 'overview', label: 'Overview' },
  { id: 'details', label: 'Details' },
  { id: 'reviews', label: 'Reviews' },
  { id: 'bookings', label: 'Bookings' },
]

function matchesCaregiverTab(row: ProfileRow, tab: string): boolean {
  if (tab === 'all' || tab === 'location') return true
  if (tab === 'availability') return row.availableNow && !row.hidden
  const hay = `${row.assistanceType} ${row.title} ${row.specialty} ${row.category} ${row.services.join(' ')} ${row.skills.join(' ')}`.toLowerCase()
  if (tab === 'professional') {
    return /personal_assistant|caregiver|mobility|professional|pca|rn|nurse/.test(hay)
  }
  if (tab === 'family') {
    return /family|companion|home.?care|relative/.test(hay)
  }
  if (tab === 'support') {
    return /visual_impairment|writer_scribe|sign_language|support|scribe|interpreter/.test(hay)
  }
  return true
}

function matchesServiceTab(row: ProfileRow, tab: string): boolean {
  if (tab === 'all') return true
  const hay = `${row.category} ${row.specialty} ${row.title} ${row.services.join(' ')}`.toLowerCase()
  const map: Record<string, RegExp> = {
    healthcare: /health|doctor|clinic|medical/,
    rehab: /rehab|therapy|physio/,
    homecare: /home.?care|caregiv|assistant/,
    education: /edu|school|learning/,
    transport: /transport|taxi|mobility/,
    tourism: /tour|travel/,
    assistive: /assistive|device|tech/,
    legal: /legal|financ|rights/,
  }
  if (tab === 'other') {
    return !Object.values(map).some((re) => re.test(hay))
  }
  return map[tab]?.test(hay) ?? true
}

function caregiverType(row: ProfileRow): { label: string; tone: 'info' | 'pink' | 'purple' } {
  const hay = `${row.assistanceType} ${row.title} ${row.specialty}`.toLowerCase()
  if (/family|companion|relative/.test(hay)) return { label: 'Family', tone: 'pink' }
  if (/visual_impairment|writer_scribe|sign_language|support|scribe|interpreter/.test(hay)) {
    return { label: 'Support Worker', tone: 'info' }
  }
  return { label: 'Professional', tone: 'info' }
}

function serviceCategoryTone(
  cat: string,
): 'purple' | 'info' | 'ok' | 'yellow' | 'danger' | 'navy' | 'pink' | 'muted' {
  const c = cat.toLowerCase()
  if (c.includes('rehab') || c.includes('therapy')) return 'purple'
  if (c.includes('transport')) return 'info'
  if (c.includes('tour')) return 'ok'
  if (c.includes('edu')) return 'yellow'
  if (c.includes('health')) return 'danger'
  if (c.includes('legal') || c.includes('financ')) return 'navy'
  if (c.includes('home') || c.includes('care')) return 'pink'
  return 'muted'
}

function serviceStatus(row: ProfileRow): { label: string; tone: 'ok' | 'warn' | 'danger' } {
  if (row.hidden) return { label: 'Rejected', tone: 'danger' }
  if (row.verified) return { label: 'Approved', tone: 'ok' }
  return { label: 'Pending', tone: 'warn' }
}

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

function serviceTypeLabel(row: ProfileRow): string {
  const hay = `${row.title} ${row.specialty} ${row.services.join(' ')}`.toLowerCase()
  if (/online|tele|remote|virtual/.test(hay) && /in.?person|clinic|home/.test(hay)) {
    return 'In-person & Online'
  }
  if (/online|tele|remote|virtual/.test(hay)) return 'Online'
  if (/on.?demand|product/.test(hay)) return 'On-demand'
  if (/product/.test(hay)) return 'Product'
  return 'In-person'
}

function avatarForProfile(r: ProfileRow) {
  return (
    r.photoUrl ||
    `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(r.id)}`
  )
}

const KIND_META: Record<
  ProviderKind,
  {
    title: string
    singular: string
    addLabel: string
    description: string
    categories: string[]
    defaultCategory: string
    defaultTitle: string
    specialtyPlaceholder: string
    icon: ReactNode
  }
> = {
  doctors: {
    title: 'Services',
    singular: 'service',
    addLabel: 'Add Service',
    description:
      'Manage all services listed on Ability Link. Approve, edit and ensure quality and accessibility.',
    categories: ['healthcare'],
    defaultCategory: 'healthcare',
    defaultTitle: 'MD',
    specialtyPlaceholder: 'e.g. Physiotherapy Session',
    icon: <IconLayers width={20} height={20} />,
  },
  therapists: {
    title: 'Therapists',
    singular: 'therapist',
    addLabel: 'Add New Therapist',
    description: 'Tele Rehab / rehabilitation providers listed in the app.',
    categories: ['rehab'],
    defaultCategory: 'rehab',
    defaultTitle: 'PT',
    specialtyPlaceholder: 'e.g. Physiotherapy',
    icon: <IconBriefcase width={20} height={20} />,
  },
  caregivers: {
    title: 'Caregivers',
    singular: 'caregiver',
    addLabel: 'Add Caregiver',
    description:
      'Manage caregiver profiles, verify credentials, and connect them with people who need support.',
    categories: ['assistance', 'caregiving'],
    defaultCategory: 'assistance',
    defaultTitle: '',
    specialtyPlaceholder: 'e.g. Personal care, Mobility support',
    icon: <IconHeart width={20} height={20} />,
  },
}

const ASSISTANCE_TYPES = [
  { value: 'personal_assistant', label: 'Personal Assistant' },
  { value: 'visual_impairment', label: 'Visual Impairment Support' },
  { value: 'writer_scribe', label: 'Writer / Scribe' },
  { value: 'sign_language', label: 'Sign Language Interpreter' },
  { value: 'mobility', label: 'Mobility Assistant' },
  { value: 'caregiver', label: 'Caregiver' },
]

function splitList(value: string): string[] {
  return value
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
}

type AddFormState = {
  name: string
  title: string
  specialty: string
  bio: string
  city: string
  photoUrl: string
  priceFrom: string
  currency: string
  yearsExperience: string
  languages: string
  services: string
  skills: string
  accessibilityTags: string
  availabilitySlots: string
  assistanceType: string
  ownerUid: string
  verified: boolean
  availableNow: boolean
  documents: ProviderDocument[]
}

function blankForm(kind: ProviderKind): AddFormState {
  const meta = KIND_META[kind]
  return {
    name: '',
    title: meta.defaultTitle,
    specialty: '',
    bio: '',
    city: '',
    photoUrl: '',
    priceFrom: '',
    currency: '$',
    yearsExperience: '',
    languages: 'English',
    services: '',
    skills: '',
    accessibilityTags: '',
    availabilitySlots: '',
    assistanceType: kind === 'caregivers' ? 'personal_assistant' : '',
    ownerUid: '',
    verified: true,
    availableNow: false,
    documents: [],
  }
}

function parseDocuments(raw: unknown): ProviderDocument[] {
  if (!Array.isArray(raw)) return []
  return raw
    .map((item, index) => {
      if (!item || typeof item !== 'object') return null
      const d = item as Record<string, unknown>
      const url = String(d.url ?? '').trim()
      if (!url) return null
      const type = String(d.type ?? 'other') as ProviderDocumentType
      return {
        id: String(d.id ?? `${type}_${index}`),
        type: PROVIDER_DOCUMENT_TYPES.some((t) => t.value === type) ? type : 'other',
        title: String(d.title ?? 'Document'),
        url,
        fileName: String(d.fileName ?? ''),
        contentType: String(d.contentType ?? ''),
      } satisfies ProviderDocument
    })
    .filter((d): d is ProviderDocument => d != null)
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  return value.map((v) => String(v)).filter(Boolean)
}

function matchesKind(
  category: string,
  assistanceType: string,
  title: string,
  kind: ProviderKind,
) {
  const cat = category.toLowerCase().trim()
  const t = title.toLowerCase().trim()
  const meta = KIND_META[kind]
  if (meta.categories.includes(cat)) return true
  if (kind === 'doctors' && (t.includes('doctor') || t.includes('md') || t.includes('physician'))) {
    return true
  }
  if (
    kind === 'therapists' &&
    (t.includes('therapist') || t.includes('physio') || t.includes('pt'))
  ) {
    return true
  }
  if (
    kind === 'caregivers' &&
    (assistanceType.trim() ||
      t.includes('caregiver') ||
      t.includes('carer') ||
      cat === 'caregiving')
  ) {
    return true
  }
  return false
}

function toRow(doc: Doc): ProfileRow {
  return {
    id: doc.id,
    name: String(doc.name ?? doc.id),
    title: String(doc.title ?? ''),
    specialty: String(doc.specialty ?? ''),
    bio: String(doc.bio ?? ''),
    city: String(doc.city ?? ''),
    photoUrl: String(doc.photoUrl ?? ''),
    rating: Number(doc.rating ?? 0),
    reviewCount: Number(doc.reviewCount ?? 0),
    priceFrom: Number(doc.priceFrom ?? 0),
    currency: String(doc.currency ?? '$'),
    languages: asStringList(doc.languages),
    services: asStringList(doc.services),
    skills: asStringList(doc.skills),
    accessibilityTags: asStringList(doc.accessibilityTags),
    yearsExperience: Number(doc.yearsExperience ?? 0),
    verified: doc.verified === true,
    availableNow: doc.availableNow === true,
    hidden: doc.hidden === true,
    assistanceType: String(doc.assistanceType ?? ''),
    availabilitySlots: asStringList(doc.availabilitySlots),
    category: String(doc.category ?? ''),
    ownerUid: String(doc.ownerUid ?? ''),
    documents: parseDocuments(doc.documents),
    raw: doc,
  }
}

export function ProviderProfilesPage({ kind }: { kind: ProviderKind }) {
  const meta = KIND_META[kind]
  const [rows, setRows] = useState<ProfileRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [tab, setTab] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [verifyFilter, setVerifyFilter] = useState('all')
  const [cityFilter, setCityFilter] = useState('all')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [selected, setSelected] = useState<ProfileRow | null>(null)
  const [detailTab, setDetailTab] = useState('overview')
  const [checked, setChecked] = useState<Set<string>>(new Set())
  const [busyId, setBusyId] = useState<string | null>(null)
  const [typeFilter, setTypeFilter] = useState('all')
  const [availabilityFilter, setAvailabilityFilter] = useState('all')
  const [showAdd, setShowAdd] = useState(false)
  const [form, setForm] = useState<AddFormState>(() => blankForm(kind))
  const [creating, setCreating] = useState(false)
  const [formError, setFormError] = useState('')
  const [uploadingDoc, setUploadingDoc] = useState<string | null>(null)
  const [docBusy, setDocBusy] = useState(false)

  useEffect(() => {
    setForm(blankForm(kind))
    setShowAdd(false)
    setFormError('')
    setSelected(null)
    setTab('all')
    setDetailTab('overview')
    setTypeFilter('all')
    setAvailabilityFilter('all')
    setChecked(new Set())
  }, [kind])

  const load = async (): Promise<ProfileRow[]> => {
    setLoading(true)
    setError('')
    try {
      const docs = await fetchProviders(400)
      const mapped = docs
        .map(toRow)
        .filter((r) => matchesKind(r.category, r.assistanceType, r.title, kind))
        .sort((a, b) => a.name.localeCompare(b.name))
      setRows(mapped)
      return mapped
    } catch (e) {
      setRows([])
      setError(e instanceof Error ? e.message : String(e))
      return []
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [kind])

  const cities = useMemo(() => {
    const set = new Set(rows.map((r) => r.city).filter(Boolean))
    return [...set].sort()
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      if (kind === 'caregivers' && !matchesCaregiverTab(r, tab)) return false
      if (kind === 'doctors' && !matchesServiceTab(r, tab)) return false
      if (statusFilter === 'visible' && r.hidden) return false
      if (statusFilter === 'hidden' && !r.hidden) return false
      if (statusFilter === 'available' && !r.availableNow) return false
      if (statusFilter === 'approved' && (!r.verified || r.hidden)) return false
      if (statusFilter === 'pending' && (r.verified || r.hidden)) return false
      if (statusFilter === 'rejected' && !r.hidden) return false
      if (verifyFilter === 'verified' && !r.verified) return false
      if (verifyFilter === 'unverified' && r.verified) return false
      if (cityFilter !== 'all' && r.city !== cityFilter) return false
      if (kind === 'caregivers' && typeFilter !== 'all') {
        const t = caregiverType(r).label.toLowerCase()
        if (typeFilter === 'professional' && !t.includes('professional')) return false
        if (typeFilter === 'family' && !t.includes('family')) return false
        if (typeFilter === 'support' && !t.includes('support')) return false
      }
      if (availabilityFilter === 'available' && !r.availableNow) return false
      if (availabilityFilter === 'busy' && (r.availableNow || r.hidden)) return false
      if (availabilityFilter === 'unavailable' && !r.hidden && r.availableNow) return false
      if (!q) return true
      return (
        r.name.toLowerCase().includes(q) ||
        r.specialty.toLowerCase().includes(q) ||
        r.city.toLowerCase().includes(q) ||
        r.title.toLowerCase().includes(q) ||
        r.services.some((s) => s.toLowerCase().includes(q)) ||
        r.skills.some((s) => s.toLowerCase().includes(q))
      )
    })
  }, [
    rows,
    search,
    tab,
    kind,
    statusFilter,
    verifyFilter,
    cityFilter,
    typeFilter,
    availabilityFilter,
  ])

  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize))
  const safePage = Math.min(page, pageCount)
  const pageRows = filtered.slice((safePage - 1) * pageSize, safePage * pageSize)

  const stats = useMemo(() => {
    if (kind === 'doctors') {
      const approved = rows.filter((r) => r.verified && !r.hidden).length
      const pending = rows.filter((r) => !r.verified && !r.hidden).length
      const rejected = rows.filter((r) => r.hidden).length
      return [
        {
          label: 'Total Services',
          value: kpiDisplay(rows.length, 2848),
          trend: '18% vs last month',
          tone: 'blue' as const,
          icon: <IconLayers width={20} height={20} />,
        },
        {
          label: 'Approved Services',
          value: kpiDisplay(approved, 2312),
          trend: '16% vs last month',
          tone: 'green' as const,
          icon: <IconShieldCheck width={20} height={20} />,
        },
        {
          label: 'Pending Approval',
          value: kpiDisplay(pending, 312),
          trend: '5% vs last month',
          trendDown: true,
          tone: 'orange' as const,
          icon: <IconClock width={20} height={20} />,
        },
        {
          label: 'Rejected Services',
          value: kpiDisplay(rejected, 96),
          trend: '2% vs last month',
          trendDown: true,
          tone: 'red' as const,
          icon: <IconBan width={20} height={20} />,
        },
      ]
    }
    if (kind === 'caregivers') {
      const verified = rows.filter((r) => r.verified && !r.hidden).length
      const pending = rows.filter((r) => !r.verified && !r.hidden).length
      const suspended = rows.filter((r) => r.hidden).length
      return [
        {
          label: 'Total Caregivers',
          value: kpiDisplay(rows.length, 1254),
          trend: '12% vs last month',
          tone: 'blue' as const,
          icon: <IconUsers width={20} height={20} />,
        },
        {
          label: 'Verified Caregivers',
          value: kpiDisplay(verified, 892),
          trend: '18% vs last month',
          tone: 'green' as const,
          icon: <IconShieldCheck width={20} height={20} />,
        },
        {
          label: 'Pending Verification',
          value: kpiDisplay(pending, 128),
          trend: '5% vs last month',
          trendDown: true,
          tone: 'orange' as const,
          icon: <IconClock width={20} height={20} />,
        },
        {
          label: 'Suspended Caregivers',
          value: kpiDisplay(suspended, 34),
          trend: '2% vs last month',
          trendDown: true,
          tone: 'red' as const,
          icon: <IconBan width={20} height={20} />,
        },
      ]
    }
    const verified = rows.filter((r) => r.verified).length
    const available = rows.filter((r) => r.availableNow && !r.hidden).length
    const hidden = rows.filter((r) => r.hidden).length
    return [
      {
        label: 'Total',
        value: rows.length,
        tone: 'blue' as const,
        icon: meta.icon,
      },
      {
        label: 'Verified',
        value: verified,
        tone: 'green' as const,
        icon: <IconShieldCheck width={20} height={20} />,
      },
      {
        label: 'Available now',
        value: available,
        tone: 'purple' as const,
        icon: <IconUsers width={20} height={20} />,
      },
      {
        label: 'Hidden',
        value: hidden,
        tone: 'orange' as const,
        icon: <IconBan width={20} height={20} />,
      },
    ]
  }, [rows, meta.icon, kind])

  const patchFlags = async (
    row: ProfileRow,
    flags: { verified?: boolean; hidden?: boolean; availableNow?: boolean },
  ) => {
    setBusyId(row.id)
    setError('')
    try {
      await setProviderFlags(row.id, flags)
      setRows((prev) =>
        prev.map((r) => (r.id === row.id ? { ...r, ...flags } : r)),
      )
      setSelected((cur) => (cur?.id === row.id ? { ...cur, ...flags } : cur))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusyId(null)
    }
  }

  const openAdd = () => {
    setForm(blankForm(kind))
    setFormError('')
    setShowAdd(true)
  }

  const setFormField = <K extends keyof AddFormState>(key: K, value: AddFormState[K]) => {
    setForm((prev) => ({ ...prev, [key]: value }))
    setFormError('')
  }

  const submitAdd = async () => {
    setCreating(true)
    setFormError('')
    try {
      const id = await createProvider({
        name: form.name,
        title: form.title,
        category: meta.defaultCategory,
        specialty: form.specialty,
        bio: form.bio,
        city: form.city,
        photoUrl: form.photoUrl,
        priceFrom: Number(form.priceFrom) || 0,
        currency: form.currency || '$',
        languages: splitList(form.languages),
        services: splitList(form.services),
        skills: splitList(form.skills),
        accessibilityTags: splitList(form.accessibilityTags),
        yearsExperience: Number(form.yearsExperience) || 0,
        verified: form.verified,
        availableNow: form.availableNow,
        assistanceType: kind === 'caregivers' ? form.assistanceType : '',
        availabilitySlots: splitList(form.availabilitySlots),
        ownerUid: form.ownerUid,
        documents: form.documents,
      })
      setShowAdd(false)
      setForm(blankForm(kind))
      const mapped = await load()
      setError('')
      const created = mapped.find((r) => r.id === id)
      if (created) setSelected(created)
    } catch (e) {
      setFormError(e instanceof Error ? e.message : String(e))
    } finally {
      setCreating(false)
    }
  }

  const uploadFormDocument = async (type: ProviderDocumentType, files: FileList | File[] | null | undefined) => {
    const list = files ? Array.from(files).filter(Boolean) : []
    if (!list.length) return
    setUploadingDoc(`form:${type}`)
    setFormError('')
    try {
      const uploaded: ProviderDocument[] = []
      for (const file of list) {
        uploaded.push(await uploadProviderDocument({ file, type }))
      }
      setForm((prev) => {
        const replaceTypes: ProviderDocumentType[] = ['photo', 'id_card']
        const without = replaceTypes.includes(type)
          ? prev.documents.filter((d) => d.type !== type)
          : prev.documents
        const nextDocs = [...without, ...uploaded]
        const photo = uploaded.find((d) => d.type === 'photo')
        return {
          ...prev,
          documents: nextDocs,
          photoUrl: photo ? photo.url : prev.photoUrl,
        }
      })
    } catch (e) {
      setFormError(e instanceof Error ? e.message : String(e))
    } finally {
      setUploadingDoc(null)
    }
  }

  const removeFormDocument = (id: string) => {
    setForm((prev) => {
      const removed = prev.documents.find((d) => d.id === id)
      const documents = prev.documents.filter((d) => d.id !== id)
      return {
        ...prev,
        documents,
        photoUrl:
          removed?.type === 'photo' && prev.photoUrl === removed.url ? '' : prev.photoUrl,
      }
    })
  }

  const uploadSelectedDocument = async (
    type: ProviderDocumentType,
    files: FileList | File[] | null | undefined,
  ) => {
    const list = files ? Array.from(files).filter(Boolean) : []
    if (!list.length || !selected) return
    setUploadingDoc(`detail:${type}`)
    setDocBusy(true)
    setError('')
    try {
      const uploaded: ProviderDocument[] = []
      for (const file of list) {
        uploaded.push(
          await uploadProviderDocument({
            file,
            type,
            providerId: selected.id,
          }),
        )
      }
      const replaceTypes: ProviderDocumentType[] = ['photo', 'id_card']
      const without = replaceTypes.includes(type)
        ? selected.documents.filter((d) => d.type !== type)
        : selected.documents
      const documents = [...without, ...uploaded]
      const photo = uploaded.find((d) => d.type === 'photo')
      const photoUrl = photo ? photo.url : selected.photoUrl
      await saveProviderDocuments({
        providerId: selected.id,
        documents,
        photoUrl,
      })
      const next = { ...selected, documents, photoUrl }
      setSelected(next)
      setRows((prev) => prev.map((r) => (r.id === next.id ? next : r)))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setUploadingDoc(null)
      setDocBusy(false)
    }
  }

  const removeSelectedDocument = async (docId: string) => {
    if (!selected) return
    setDocBusy(true)
    setError('')
    try {
      const removed = selected.documents.find((d) => d.id === docId)
      const documents = selected.documents.filter((d) => d.id !== docId)
      const photoUrl =
        removed?.type === 'photo' && selected.photoUrl === removed.url ? '' : selected.photoUrl
      await saveProviderDocuments({
        providerId: selected.id,
        documents,
        photoUrl,
      })
      const next = { ...selected, documents, photoUrl }
      setSelected(next)
      setRows((prev) => prev.map((r) => (r.id === next.id ? next : r)))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setDocBusy(false)
    }
  }

  const exportCsv = () => {
    const header = [
      'id',
      'name',
      'title',
      'specialty',
      'city',
      'verified',
      'availableNow',
      'hidden',
      'rating',
      'reviewCount',
      'priceFrom',
    ]
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [
          r.id,
          JSON.stringify(r.name),
          JSON.stringify(r.title),
          JSON.stringify(r.specialty),
          JSON.stringify(r.city),
          r.verified,
          r.availableNow,
          r.hidden,
          r.rating,
          r.reviewCount,
          r.priceFrom,
        ].join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `ability-link-${kind}.csv`
    a.click()
    URL.revokeObjectURL(a.href)
  }

  return (
    <div className="al-page">
      <PageHeader
        title={meta.title}
        subtitle={meta.description}
        primaryAction={{ label: meta.addLabel, onClick: openAdd }}
        onExport={exportCsv}
      />

      {showAdd ? (
        <div className="pp-modal-backdrop" role="presentation" onClick={() => !creating && setShowAdd(false)}>
          <div
            className="pp-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="pp-add-title"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="pp-modal-head">
              <h2 id="pp-add-title">{meta.addLabel}</h2>
              <button
                type="button"
                className="icon-btn"
                disabled={creating}
                onClick={() => setShowAdd(false)}
                aria-label="Close"
              >
                <IconX width={16} height={16} />
              </button>
            </div>
            <p className="pp-modal-lead">
              Creates a live profile in the app under{' '}
              <strong>{meta.defaultCategory}</strong>.
            </p>
            {formError ? <div className="error">{formError}</div> : null}
            <div className="pp-form-grid">
              <label className="pp-field">
                <span>Full name *</span>
                <input
                  value={form.name}
                  onChange={(e) => setFormField('name', e.target.value)}
                  placeholder={
                    kind === 'doctors'
                      ? 'Dr. Sara Ahmed'
                      : kind === 'therapists'
                        ? 'James Okonkwo'
                        : 'Priya Nair'
                  }
                />
              </label>
              <label className="pp-field">
                <span>Title / credential</span>
                <input
                  value={form.title}
                  onChange={(e) => setFormField('title', e.target.value)}
                  placeholder={meta.defaultTitle || 'e.g. RN, PCA'}
                />
              </label>
              <label className="pp-field">
                <span>Specialty *</span>
                <input
                  value={form.specialty}
                  onChange={(e) => setFormField('specialty', e.target.value)}
                  placeholder={meta.specialtyPlaceholder}
                />
              </label>
              <label className="pp-field">
                <span>City</span>
                <input
                  value={form.city}
                  onChange={(e) => setFormField('city', e.target.value)}
                  placeholder="City, Country"
                />
              </label>
              {kind === 'caregivers' ? (
                <label className="pp-field">
                  <span>Assistance type</span>
                  <select
                    value={form.assistanceType}
                    onChange={(e) => setFormField('assistanceType', e.target.value)}
                  >
                    {ASSISTANCE_TYPES.map((t) => (
                      <option key={t.value} value={t.value}>
                        {t.label}
                      </option>
                    ))}
                  </select>
                </label>
              ) : null}
              <label className="pp-field">
                <span>Years experience</span>
                <input
                  type="number"
                  min={0}
                  value={form.yearsExperience}
                  onChange={(e) => setFormField('yearsExperience', e.target.value)}
                />
              </label>
              <label className="pp-field">
                <span>Price from</span>
                <input
                  type="number"
                  min={0}
                  value={form.priceFrom}
                  onChange={(e) => setFormField('priceFrom', e.target.value)}
                  placeholder="35"
                />
              </label>
              <label className="pp-field">
                <span>Currency</span>
                <input
                  value={form.currency}
                  onChange={(e) => setFormField('currency', e.target.value)}
                  placeholder="$"
                />
              </label>
              <div className="pp-field pp-field-full">
                <span>Documents</span>
                <div className="pp-docs">
                  {PROVIDER_DOCUMENT_TYPES.map((slot) => {
                    const files = form.documents.filter((d) => d.type === slot.value)
                    const busy = uploadingDoc === `form:${slot.value}`
                    const inputId = `pp-form-doc-${slot.value}`
                    return (
                      <div key={slot.value} className="pp-doc-slot">
                        <div className="pp-doc-slot-head">
                          <strong>{slot.label}</strong>
                          <button
                            type="button"
                            className="al-btn al-btn--ghost pp-doc-upload"
                            disabled={busy || creating}
                            onClick={() => document.getElementById(inputId)?.click()}
                          >
                            <IconUpload width={14} height={14} />
                            {busy ? 'Uploading…' : slot.multiple ? 'Upload files' : 'Upload'}
                          </button>
                          <input
                            id={inputId}
                            type="file"
                            accept={slot.accept}
                            multiple={slot.multiple === true}
                            hidden
                            disabled={busy || creating}
                            onChange={(e) => {
                              const picked = e.target.files
                                ? Array.from(e.target.files)
                                : []
                              e.target.value = ''
                              void uploadFormDocument(slot.value, picked)
                            }}
                          />
                        </div>
                        {files.length ? (
                          <ul className="pp-doc-list">
                            {files.map((f) => (
                              <li key={f.id}>
                                {f.contentType.startsWith('image/') ? (
                                  <a href={f.url} target="_blank" rel="noreferrer">
                                    <img src={f.url} alt="" />
                                  </a>
                                ) : (
                                  <a href={f.url} target="_blank" rel="noreferrer">
                                    {f.fileName || f.title}
                                  </a>
                                )}
                                <button
                                  type="button"
                                  className="pp-doc-remove"
                                  onClick={() => removeFormDocument(f.id)}
                                >
                                  Remove
                                </button>
                              </li>
                            ))}
                          </ul>
                        ) : (
                          <span className="pp-doc-empty">No file uploaded</span>
                        )}
                      </div>
                    )
                  })}
                </div>
                <em className="pp-doc-hint">
                  Images or PDF, max 15 MB each. Educational, experience, license, and other
                  support multiple files. User Photo also becomes the profile picture.
                </em>
              </div>
              <label className="pp-field pp-field-full">
                <span>Photo URL (optional override)</span>
                <input
                  value={form.photoUrl}
                  onChange={(e) => setFormField('photoUrl', e.target.value)}
                  placeholder="Filled automatically when you upload User Photo"
                />
              </label>
              <label className="pp-field pp-field-full">
                <span>Bio</span>
                <textarea
                  rows={3}
                  value={form.bio}
                  onChange={(e) => setFormField('bio', e.target.value)}
                  placeholder="Short professional summary shown on the profile."
                />
              </label>
              <label className="pp-field pp-field-full">
                <span>Languages (comma-separated)</span>
                <input
                  value={form.languages}
                  onChange={(e) => setFormField('languages', e.target.value)}
                />
              </label>
              <label className="pp-field pp-field-full">
                <span>Services (comma-separated)</span>
                <input
                  value={form.services}
                  onChange={(e) => setFormField('services', e.target.value)}
                  placeholder={
                    kind === 'doctors'
                      ? 'Video consult, Follow-up plan'
                      : kind === 'therapists'
                        ? 'Assessment, Home exercise plan'
                        : 'Companionship, Errands'
                  }
                />
              </label>
              {kind === 'caregivers' ? (
                <>
                  <label className="pp-field pp-field-full">
                    <span>Skills (comma-separated)</span>
                    <input
                      value={form.skills}
                      onChange={(e) => setFormField('skills', e.target.value)}
                    />
                  </label>
                  <label className="pp-field pp-field-full">
                    <span>Availability slots (comma-separated)</span>
                    <input
                      value={form.availabilitySlots}
                      onChange={(e) => setFormField('availabilitySlots', e.target.value)}
                      placeholder="Mon–Fri 9am–1pm, Sat 10am–2pm"
                    />
                  </label>
                </>
              ) : null}
              <label className="pp-field pp-field-full">
                <span>Accessibility tags (comma-separated)</span>
                <input
                  value={form.accessibilityTags}
                  onChange={(e) => setFormField('accessibilityTags', e.target.value)}
                  placeholder="wheelchair, captions"
                />
              </label>
              <label className="pp-field pp-field-full">
                <span>Owner UID (optional — link to app account)</span>
                <input
                  value={form.ownerUid}
                  onChange={(e) => setFormField('ownerUid', e.target.value)}
                  placeholder="Firebase Auth UID"
                />
              </label>
              <label className="pp-check">
                <input
                  type="checkbox"
                  checked={form.verified}
                  onChange={(e) => setFormField('verified', e.target.checked)}
                />
                Verified
              </label>
              <label className="pp-check">
                <input
                  type="checkbox"
                  checked={form.availableNow}
                  onChange={(e) => setFormField('availableNow', e.target.checked)}
                />
                Available now
              </label>
            </div>
            <div className="pp-modal-actions">
              <button
                type="button"
                className="al-btn al-btn--ghost"
                disabled={creating}
                onClick={() => setShowAdd(false)}
              >
                Cancel
              </button>
              <button
                type="button"
                className="al-btn al-btn--primary"
                disabled={creating}
                onClick={() => void submitAdd()}
              >
                {creating ? 'Creating…' : meta.addLabel}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {error ? <div className="error" style={{ marginBottom: 12 }}>{error}</div> : null}

      <KpiRow items={stats} cols={4} />

      {kind === 'caregivers' ? (
        <TabBar
          tabs={CAREGIVER_TABS}
          active={tab}
          onChange={(id) => {
            setTab(id)
            setPage(1)
          }}
        />
      ) : null}
      {kind === 'doctors' ? (
        <TabBar
          tabs={SERVICE_TABS}
          active={tab}
          onChange={(id) => {
            setTab(id)
            setPage(1)
          }}
        />
      ) : null}

      <FilterBar
        search={search}
        onSearch={(v) => {
          setSearch(v)
          setPage(1)
        }}
        searchPlaceholder={
          kind === 'doctors'
            ? 'Search services by name, provider or keyword...'
            : kind === 'caregivers'
              ? 'Search caregivers by name, skills or location...'
              : `Search ${meta.title.toLowerCase()} by name, specialty, city…`
        }
        onReset={() => {
          setSearch('')
          setTab('all')
          setStatusFilter('all')
          setVerifyFilter('all')
          setCityFilter('all')
          setTypeFilter('all')
          setAvailabilityFilter('all')
          setPage(1)
        }}
      >
        {kind === 'caregivers' ? (
          <>
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Types</option>
              <option value="professional">Professional</option>
              <option value="family">Family</option>
              <option value="support">Support Worker</option>
            </select>
            <select
              value={cityFilter}
              onChange={(e) => {
                setCityFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Locations</option>
              {cities.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
            <select
              value={availabilityFilter}
              onChange={(e) => {
                setAvailabilityFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All</option>
              <option value="available">Available</option>
              <option value="busy">Busy</option>
              <option value="unavailable">Unavailable</option>
            </select>
            <select
              value={verifyFilter}
              onChange={(e) => {
                setVerifyFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All</option>
              <option value="verified">Verified</option>
              <option value="unverified">Pending</option>
            </select>
          </>
        ) : kind === 'doctors' ? (
          <>
            <select
              value={tab === 'all' ? 'all' : tab}
              onChange={(e) => {
                setTab(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Categories</option>
              <option value="healthcare">Healthcare</option>
              <option value="rehab">Rehabilitation</option>
              <option value="homecare">Home Care</option>
              <option value="education">Education</option>
              <option value="transport">Transport</option>
              <option value="tourism">Tourism</option>
              <option value="assistive">Assistive Technology</option>
              <option value="legal">Legal & Financial</option>
            </select>
            <select
              value={cityFilter}
              onChange={(e) => {
                setCityFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Locations</option>
              {cities.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
            <select
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Types</option>
              <option value="inperson">In-person</option>
              <option value="online">Online</option>
              <option value="ondemand">On-demand</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All Statuses</option>
              <option value="approved">Approved</option>
              <option value="pending">Pending</option>
              <option value="rejected">Rejected</option>
            </select>
          </>
        ) : (
          <>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All visibility</option>
              <option value="visible">Visible</option>
              <option value="hidden">Hidden</option>
              <option value="available">Available now</option>
            </select>
            <select
              value={verifyFilter}
              onChange={(e) => {
                setVerifyFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All verification</option>
              <option value="verified">Verified</option>
              <option value="unverified">Not verified</option>
            </select>
            <select
              value={cityFilter}
              onChange={(e) => {
                setCityFilter(e.target.value)
                setPage(1)
              }}
            >
              <option value="all">All cities</option>
              {cities.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </>
        )}
      </FilterBar>

      <div className={`al-split${selected ? '' : ' no-detail'}`}>
        <div className="al-table-card">
          {loading ? (
            <p className="muted" style={{ padding: 20 }}>
              Loading {meta.title.toLowerCase()}…
            </p>
          ) : (
            <>
              <div className="table-wrap">
                <table className="al-table">
                  <thead>
                    {kind === 'caregivers' ? (
                      <tr>
                        <th className="al-check">
                          <input
                            type="checkbox"
                            checked={
                              pageRows.length > 0 &&
                              pageRows.every((r) => checked.has(r.id))
                            }
                            onChange={() => {
                              if (pageRows.every((r) => checked.has(r.id))) {
                                setChecked(new Set())
                              } else {
                                setChecked(new Set(pageRows.map((r) => r.id)))
                              }
                            }}
                            aria-label="Select all"
                          />
                        </th>
                        <th>Caregiver</th>
                        <th>Type</th>
                        <th>Skills / Specialization</th>
                        <th>Location</th>
                        <th>Availability</th>
                        <th>Rating</th>
                        <th>Status</th>
                        <th>Joined</th>
                        <th />
                      </tr>
                    ) : kind === 'doctors' ? (
                      <tr>
                        <th className="al-check">
                          <input
                            type="checkbox"
                            checked={
                              pageRows.length > 0 &&
                              pageRows.every((r) => checked.has(r.id))
                            }
                            onChange={() => {
                              if (pageRows.every((r) => checked.has(r.id))) {
                                setChecked(new Set())
                              } else {
                                setChecked(new Set(pageRows.map((r) => r.id)))
                              }
                            }}
                            aria-label="Select all"
                          />
                        </th>
                        <th>Service</th>
                        <th>Category</th>
                        <th>Provider</th>
                        <th>Location</th>
                        <th>Type</th>
                        <th>Price</th>
                        <th>Status</th>
                        <th>Rating</th>
                        <th />
                      </tr>
                    ) : (
                      <tr>
                        <th>Profile</th>
                        <th>Specialty</th>
                        <th>Location</th>
                        <th>Rating</th>
                        <th>Price</th>
                        <th>Status</th>
                        <th />
                      </tr>
                    )}
                  </thead>
                  <tbody>
                    {pageRows.map((r) => {
                      const cgType = caregiverType(r)
                      const svcStatus = serviceStatus(r)
                      const catLabel = r.category || r.specialty || 'Other'
                      return (
                        <tr
                          key={r.id}
                          className={selected?.id === r.id ? 'active' : ''}
                          onClick={() => {
                            setDetailTab('overview')
                            setSelected(r)
                          }}
                        >
                          {kind === 'caregivers' || kind === 'doctors' ? (
                            <td className="al-check" onClick={(e) => e.stopPropagation()}>
                              <input
                                type="checkbox"
                                checked={checked.has(r.id)}
                                onChange={() => {
                                  setChecked((prev) => {
                                    const next = new Set(prev)
                                    if (next.has(r.id)) next.delete(r.id)
                                    else next.add(r.id)
                                    return next
                                  })
                                }}
                                aria-label={`Select ${r.name}`}
                              />
                            </td>
                          ) : null}

                          {kind === 'caregivers' ? (
                            <>
                              <td>
                                <div className="al-person">
                                  <img src={avatarForProfile(r)} alt="" />
                                  <div>
                                    <strong>{r.name}</strong>
                                    <span>{r.specialty || r.title || 'Caregiver'}</span>
                                  </div>
                                </div>
                              </td>
                              <td>
                                <StatusPill tone={cgType.tone}>{cgType.label}</StatusPill>
                              </td>
                              <td>
                                {(r.skills.length ? r.skills : r.services).slice(0, 3).join(', ') ||
                                  r.specialty ||
                                  '—'}
                              </td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconMapPin width={14} height={14} />
                                  {r.city || '—'}
                                </span>
                              </td>
                              <td>
                                {r.hidden ? (
                                  <StatusPill tone="danger">Unavailable</StatusPill>
                                ) : r.availableNow ? (
                                  <StatusPill tone="ok">Available</StatusPill>
                                ) : (
                                  <StatusPill tone="warn">Busy</StatusPill>
                                )}
                              </td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconStar width={14} height={14} />
                                  {r.rating > 0 ? r.rating.toFixed(1) : '—'}
                                  <span className="muted">({r.reviewCount})</span>
                                </span>
                              </td>
                              <td>
                                {r.hidden ? (
                                  <StatusPill tone="danger">Suspended</StatusPill>
                                ) : r.verified ? (
                                  <StatusPill tone="ok">Verified</StatusPill>
                                ) : (
                                  <StatusPill tone="warn">Pending</StatusPill>
                                )}
                              </td>
                              <td>—</td>
                            </>
                          ) : kind === 'doctors' ? (
                            <>
                              <td>
                                <div className="al-person">
                                  <img
                                    className="al-thumb"
                                    src={avatarForProfile(r)}
                                    alt=""
                                    style={{ borderRadius: 8 }}
                                  />
                                  <div>
                                    <strong>{r.name}</strong>
                                    <span>{r.specialty || r.title || 'Service'}</span>
                                  </div>
                                </div>
                              </td>
                              <td>
                                <StatusPill tone={serviceCategoryTone(catLabel)}>
                                  {catLabel}
                                </StatusPill>
                              </td>
                              <td>
                                <div className="al-person">
                                  <img
                                    src={avatarForProfile(r)}
                                    alt=""
                                    style={{ width: 28, height: 28 }}
                                  />
                                  <div>
                                    <strong style={{ fontSize: 12 }}>
                                      {r.title || r.name}
                                    </strong>
                                  </div>
                                </div>
                              </td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconMapPin width={14} height={14} />
                                  {r.city || '—'}
                                </span>
                              </td>
                              <td>{serviceTypeLabel(r)}</td>
                              <td>
                                {r.priceFrom > 0
                                  ? `${r.currency === '$' ? 'Rs ' : r.currency}${r.priceFrom.toLocaleString()}`
                                  : '—'}
                              </td>
                              <td>
                                <StatusPill tone={svcStatus.tone}>{svcStatus.label}</StatusPill>
                              </td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconStar width={14} height={14} />
                                  {r.rating > 0 ? r.rating.toFixed(1) : '—'}
                                  <span className="muted">({r.reviewCount})</span>
                                </span>
                              </td>
                            </>
                          ) : (
                            <>
                              <td>
                                <div className="al-person">
                                  <img src={avatarForProfile(r)} alt="" />
                                  <div>
                                    <strong>
                                      {r.name}
                                      {r.title ? ` · ${r.title}` : ''}
                                    </strong>
                                    <span>{r.id}</span>
                                  </div>
                                </div>
                              </td>
                              <td>{r.specialty || '—'}</td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconMapPin width={14} height={14} />
                                  {r.city || '—'}
                                </span>
                              </td>
                              <td>
                                <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center' }}>
                                  <IconStar width={14} height={14} />
                                  {r.rating > 0 ? r.rating.toFixed(1) : '—'}
                                  <span className="muted">({r.reviewCount})</span>
                                </span>
                              </td>
                              <td>
                                {r.priceFrom > 0 ? `${r.currency}${r.priceFrom}+` : '—'}
                              </td>
                              <td>
                                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                  {r.verified ? (
                                    <StatusPill tone="ok">Verified</StatusPill>
                                  ) : (
                                    <StatusPill tone="muted">Unverified</StatusPill>
                                  )}
                                  {r.hidden ? (
                                    <StatusPill tone="warn">Hidden</StatusPill>
                                  ) : r.availableNow ? (
                                    <StatusPill tone="info">Available</StatusPill>
                                  ) : (
                                    <StatusPill tone="muted">Listed</StatusPill>
                                  )}
                                </div>
                              </td>
                            </>
                          )}
                          <td>
                            <button
                              type="button"
                              className="icon-btn"
                              title="View"
                              onClick={(e) => {
                                e.stopPropagation()
                                setDetailTab('overview')
                                setSelected(r)
                              }}
                            >
                              <IconMore width={16} height={16} />
                            </button>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
              {!pageRows.length ? (
                <div className="empty" style={{ padding: 20 }}>
                  No {meta.title.toLowerCase()} match your filters.
                </div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing {(safePage - 1) * pageSize + (pageRows.length ? 1 : 0)} to{' '}
                  {(safePage - 1) * pageSize + pageRows.length} of{' '}
                  {filtered.length.toLocaleString()} {meta.title.toLowerCase()}
                </span>
                <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <div className="al-pages">
                    <button
                      type="button"
                      disabled={safePage <= 1}
                      onClick={() => setPage((p) => Math.max(1, p - 1))}
                    >
                      <IconChevronLeft width={14} height={14} />
                    </button>
                    {Array.from({ length: Math.min(pageCount, 5) }, (_, i) => i + 1).map((n) => (
                      <button
                        key={n}
                        type="button"
                        className={n === safePage ? 'active' : ''}
                        onClick={() => setPage(n)}
                      >
                        {n}
                      </button>
                    ))}
                    <button
                      type="button"
                      disabled={safePage >= pageCount}
                      onClick={() => setPage((p) => Math.min(pageCount, p + 1))}
                    >
                      <IconChevronRight width={14} height={14} />
                    </button>
                  </div>
                  <label>
                    Rows per page{' '}
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
                <img
                  src={avatarForProfile(selected)}
                  alt=""
                  className={kind === 'doctors' ? 'al-thumb-sq' : undefined}
                />
                <div>
                  <strong>{selected.name}</strong>
                  <span className="al-detail-id">
                    {kind === 'caregivers'
                      ? `${caregiverType(selected).label} Caregiver`
                      : kind === 'doctors'
                        ? selected.specialty || 'Service'
                        : selected.specialty || meta.singular}
                  </span>
                  <div className="al-detail-meta">
                    {kind === 'doctors' ? (
                      <StatusPill tone={serviceStatus(selected).tone}>
                        {serviceStatus(selected).label}
                      </StatusPill>
                    ) : selected.hidden ? (
                      <StatusPill tone="danger">Suspended</StatusPill>
                    ) : selected.verified ? (
                      <StatusPill tone="ok">Verified</StatusPill>
                    ) : (
                      <StatusPill tone="warn">Pending</StatusPill>
                    )}
                    <span style={{ display: 'inline-flex', gap: 4, alignItems: 'center', fontSize: 12 }}>
                      <IconStar width={13} height={13} />
                      {selected.rating > 0 ? selected.rating.toFixed(1) : '—'} (
                      {selected.reviewCount} reviews)
                    </span>
                  </div>
                </div>
              </div>
            ) : null
          }
          footer={
            selected ? (
              kind === 'doctors' ? (
                <>
                  <button
                    type="button"
                    className="al-btn al-btn--primary span-2"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { verified: !selected.verified })
                    }
                  >
                    <IconPencil width={16} height={16} /> Edit Service
                  </button>
                  <button type="button" className="al-btn al-btn--outline">
                    <IconUser width={16} height={16} /> View Provider
                  </button>
                  <button
                    type="button"
                    className="al-btn al-btn--danger"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { hidden: !selected.hidden })
                    }
                  >
                    <IconBan width={16} height={16} />
                    {selected.hidden ? 'Restore Service' : 'Reject Service'}
                  </button>
                </>
              ) : kind === 'caregivers' ? (
                <>
                  <button
                    type="button"
                    className="al-btn al-btn--primary span-2"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { verified: !selected.verified })
                    }
                  >
                    <IconPencil width={16} height={16} /> Edit Caregiver
                  </button>
                  <button type="button" className="al-btn al-btn--outline">
                    <IconMessage width={16} height={16} /> Send Message
                  </button>
                  <button
                    type="button"
                    className="al-btn al-btn--danger"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { hidden: !selected.hidden })
                    }
                  >
                    <IconBan width={16} height={16} />
                    {selected.hidden ? 'Reactivate' : 'Suspend Caregiver'}
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    className="al-btn al-btn--primary span-2"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { verified: !selected.verified })
                    }
                  >
                    <IconShieldCheck width={16} height={16} />
                    {selected.verified ? 'Unverify' : 'Verify profile'}
                  </button>
                  <button
                    type="button"
                    className="al-btn al-btn--outline"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, {
                        availableNow: !selected.availableNow,
                      })
                    }
                  >
                    <IconEye width={16} height={16} />
                    {selected.availableNow ? 'Mark unavailable' : 'Mark available'}
                  </button>
                  <button
                    type="button"
                    className="al-btn al-btn--danger"
                    disabled={busyId === selected.id}
                    onClick={() =>
                      void patchFlags(selected, { hidden: !selected.hidden })
                    }
                  >
                    <IconBan width={16} height={16} />
                    {selected.hidden ? 'Show in app' : 'Hide from app'}
                  </button>
                </>
              )
            ) : null
          }
        >
          {selected ? (
            <>
              <div className="al-detail-tabs" role="tablist">
                {(kind === 'doctors'
                  ? PROFILE_DETAIL_TABS_SERVICE
                  : kind === 'caregivers'
                    ? PROFILE_DETAIL_TABS_CAREGIVER
                    : PROFILE_DETAIL_TABS_CAREGIVER
                ).map((t) => (
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

              {detailTab === 'overview' || detailTab === 'details' ? (
                <>
                  <div className="al-contact-card">
                    <div className="al-contact-row">
                      <IconMail width={14} height={14} />{' '}
                      {String(selected.raw.email ?? '—')}
                    </div>
                    <div className="al-contact-row">
                      <IconPhone width={14} height={14} />{' '}
                      {String(selected.raw.phone ?? '—')}
                    </div>
                    <div className="al-contact-row">
                      <IconMapPin width={14} height={14} /> {selected.city || '—'}
                    </div>
                    {kind === 'caregivers' ? (
                      <div className="al-contact-row">
                        <IconGlobe width={14} height={14} /> Speaks:{' '}
                        {selected.languages.length
                          ? selected.languages.join(', ')
                          : '—'}
                      </div>
                    ) : null}
                    {kind === 'doctors' ? (
                      <>
                        <div className="al-contact-row">
                          <IconLayers width={14} height={14} />{' '}
                          {selected.category || '—'} · {serviceTypeLabel(selected)}
                        </div>
                        <div className="al-contact-row">
                          <IconStar width={14} height={14} />{' '}
                          {selected.priceFrom > 0
                            ? `${selected.currency === '$' ? 'Rs ' : selected.currency}${selected.priceFrom.toLocaleString()} per session`
                            : '—'}
                        </div>
                      </>
                    ) : null}
                  </div>

                  {selected.bio ? (
                    <div className="al-detail-section">
                      <h4>About</h4>
                      <p className="muted" style={{ margin: 0, fontSize: 13, lineHeight: 1.5 }}>
                        {selected.bio}
                      </p>
                    </div>
                  ) : null}

                  {kind === 'caregivers' ? (
                    <div className="al-detail-section">
                      <h4>Skills</h4>
                      <div className="al-chips">
                        {(selected.skills.length ? selected.skills : selected.services).map(
                          (s) => (
                            <StatusPill key={s} tone="info">
                              {s}
                            </StatusPill>
                          ),
                        )}
                      </div>
                    </div>
                  ) : null}

                  {kind === 'doctors' ? (
                    <div className="al-detail-section">
                      <h4>Accessibility Features</h4>
                      <div className="al-chips">
                        {(selected.accessibilityTags.length
                          ? selected.accessibilityTags
                          : [
                              'Wheelchair Accessible',
                              'Accessible Entrance',
                              'Accessible Toilet',
                              'Home Visit Available',
                            ]
                        ).map((tag) => (
                          <span key={tag} className="al-need-chip">
                            <span className="al-need-icon al-need-icon--mobility">
                              {/toilet|restroom/i.test(tag) ? (
                                <IconRestroom width={13} height={13} />
                              ) : /entrance|door/i.test(tag) ? (
                                <IconDoor width={13} height={13} />
                              ) : /home|visit/i.test(tag) ? (
                                <IconHeart width={13} height={13} />
                              ) : (
                                <IconWheelchair width={13} height={13} />
                              )}
                            </span>
                            {tag}
                          </span>
                        ))}
                      </div>
                    </div>
                  ) : null}

                  {kind === 'caregivers' ? (
                    <div className="al-detail-section">
                      <h4>Availability</h4>
                      <div className="al-contact-row">
                        <IconCalendar width={14} height={14} />
                        {selected.availabilitySlots.length
                          ? selected.availabilitySlots.join(' · ')
                          : 'Mon - Fri: 9:00 AM - 5:00 PM'}
                      </div>
                      {selected.availableNow ? (
                        <div style={{ marginTop: 8 }}>
                          <StatusPill tone="ok">Currently Available</StatusPill>
                        </div>
                      ) : null}
                    </div>
                  ) : null}
                </>
              ) : null}

              {detailTab === 'documents' ? (
                <div className="pp-docs">
                  {PROVIDER_DOCUMENT_TYPES.map((slot) => {
                    const files = selected.documents.filter((d) => d.type === slot.value)
                    const busy = uploadingDoc === `detail:${slot.value}` || docBusy
                    const inputId = `pp-detail-doc-${selected.id}-${slot.value}`
                    return (
                      <div key={slot.value} className="pp-doc-slot">
                        <div className="pp-doc-slot-head">
                          <strong>{slot.label}</strong>
                          <button
                            type="button"
                            className="al-btn al-btn--ghost pp-doc-upload"
                            disabled={busy}
                            onClick={() => document.getElementById(inputId)?.click()}
                          >
                            <IconUpload width={14} height={14} />
                            {busy && uploadingDoc === `detail:${slot.value}`
                              ? 'Uploading…'
                              : slot.multiple
                                ? 'Upload files'
                                : 'Upload'}
                          </button>
                          <input
                            id={inputId}
                            type="file"
                            accept={slot.accept}
                            multiple={slot.multiple === true}
                            hidden
                            disabled={busy}
                            onChange={(e) => {
                              const picked = e.target.files
                                ? Array.from(e.target.files)
                                : []
                              e.target.value = ''
                              void uploadSelectedDocument(slot.value, picked)
                            }}
                          />
                        </div>
                        {files.length ? (
                          <ul className="pp-doc-list">
                            {files.map((f) => (
                              <li key={f.id}>
                                {f.contentType.startsWith('image/') ? (
                                  <a href={f.url} target="_blank" rel="noreferrer">
                                    <img src={f.url} alt="" />
                                  </a>
                                ) : (
                                  <a href={f.url} target="_blank" rel="noreferrer">
                                    {f.fileName || f.title}
                                  </a>
                                )}
                                <button
                                  type="button"
                                  className="pp-doc-remove"
                                  disabled={docBusy}
                                  onClick={() => void removeSelectedDocument(f.id)}
                                >
                                  Remove
                                </button>
                              </li>
                            ))}
                          </ul>
                        ) : (
                          <div className="al-doc-row">
                            <IconFileText width={16} height={16} />
                            <span className="pp-doc-empty">No file uploaded</span>
                          </div>
                        )}
                        {files.length ? (
                          <div className="al-doc-row">
                            <span className="ok">
                              <IconCheckCircle width={14} height={14} /> Verified
                            </span>
                          </div>
                        ) : null}
                      </div>
                    )
                  })}
                </div>
              ) : null}

              {detailTab === 'availability' ? (
                <div className="al-detail-section">
                  <div className="al-contact-row">
                    <IconCalendar width={14} height={14} />
                    {selected.availabilitySlots.length
                      ? selected.availabilitySlots.join(' · ')
                      : 'Schedule not configured'}
                  </div>
                </div>
              ) : null}

              {detailTab === 'reviews' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  {selected.reviewCount} reviews ·{' '}
                  {selected.rating > 0 ? selected.rating.toFixed(1) : '—'} average.
                </p>
              ) : null}

              {detailTab === 'bookings' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  Bookings for this service will appear here.
                </p>
              ) : null}
            </>
          ) : null}
        </DetailPanel>
      </div>
    </div>
  )
}


export function DoctorsPage() {
  return <ProviderProfilesPage kind="doctors" />
}

export function TherapistsPage() {
  return <ProviderProfilesPage kind="therapists" />
}

export function CaregiversPage() {
  return <ProviderProfilesPage kind="caregivers" />
}
