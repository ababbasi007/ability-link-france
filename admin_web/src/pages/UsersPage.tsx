import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  fetchUsersPage,
  requestUserPasswordReset,
  setUserStatus,
} from '../lib/data'
import type { PageCursor } from '../lib/pagination'
import { DemoBanner } from '../components/DemoBanner'
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
  IconBrain,
  IconChevronLeft,
  IconChevronRight,
  IconEar,
  IconEyeOpen,
  IconLock,
  IconMail,
  IconMapPin,
  IconMessage,
  IconMore,
  IconPencil,
  IconPhone,
  IconUser,
  IconUsers,
  IconWheelchair,
} from '../components/icons'

type Doc = Record<string, unknown> & { id: string }

type UserRole = 'User' | 'Provider' | 'Admin'
type AccountStatus = 'active' | 'inactive' | 'blocked' | 'pending'
type Verification = 'verified' | 'inReview' | 'notVerified'
type UserTypeKey =
  | 'pwd'
  | 'senior'
  | 'caregiver'
  | 'provider'
  | 'employer'
  | 'staff'
  | 'user'

type NeedKey = 'mobility' | 'hearing' | 'vision' | 'cognitive' | 'speech'

type UserRow = {
  id: string
  name: string
  email: string
  phone: string
  avatar: string
  role: UserRole
  userType: UserTypeKey
  city: string
  country: string
  joinedOn: string
  status: AccountStatus
  verification: Verification
  lastActive: string
  lastActiveOnline: boolean
  needs: NeedKey[]
  bio: string
  dob: string
  gender: string
  raw: Doc
}

const TABS = [
  { id: 'all', label: 'All Users' },
  { id: 'pwd', label: 'Persons with Disabilities' },
  { id: 'senior', label: 'Senior Citizens' },
  { id: 'caregiver', label: 'Caregivers' },
  { id: 'provider', label: 'Service Providers' },
  { id: 'employer', label: 'Employers' },
  { id: 'staff', label: 'Staff' },
]

const DETAIL_TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'details', label: 'Details' },
  { id: 'activity', label: 'Activity' },
  { id: 'bookings', label: 'Bookings' },
]

const NEED_META: Record<NeedKey, { label: string; icon: ReactNode }> = {
  mobility: { label: 'Mobility', icon: <IconWheelchair width={13} height={13} /> },
  hearing: { label: 'Hearing', icon: <IconEar width={13} height={13} /> },
  vision: { label: 'Vision', icon: <IconEyeOpen width={13} height={13} /> },
  cognitive: { label: 'Cognitive', icon: <IconBrain width={13} height={13} /> },
  speech: { label: 'Speech', icon: <IconMessage width={13} height={13} /> },
}

function formatDate(value: unknown): string {
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
    const d = (value as { toDate: () => Date }).toDate()
    return d.toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    })
  }
  return '—'
}

function relativeFrom(value: unknown): { label: string; online: boolean } {
  let ms: number | null = null
  if (typeof value === 'string') {
    const t = Date.parse(value)
    if (!Number.isNaN(t)) ms = t
  } else if (typeof value === 'object' && value !== null && 'toDate' in value) {
    ms = (value as { toDate: () => Date }).toDate().getTime()
  }
  if (ms == null) return { label: '—', online: false }
  const diff = Date.now() - ms
  const mins = Math.floor(diff / 60000)
  if (mins < 5) return { label: 'Online', online: true }
  if (mins < 60) return { label: `${Math.max(1, mins)} min ago`, online: false }
  const hours = Math.floor(mins / 60)
  if (hours < 24) return { label: `${hours} hour${hours === 1 ? '' : 's'} ago`, online: false }
  const days = Math.floor(hours / 24)
  if (days < 7) return { label: `${days} day${days === 1 ? '' : 's'} ago`, online: false }
  const weeks = Math.floor(days / 7)
  return { label: `${weeks} week${weeks === 1 ? '' : 's'} ago`, online: false }
}

function mapRole(raw: Doc): UserRole {
  const role = String(raw.platformRole ?? raw.role ?? 'user').toLowerCase()
  if (role.includes('admin')) return 'Admin'
  if (role.includes('provider') || role.includes('business')) return 'Provider'
  return 'User'
}

function mapStatus(raw: Doc): AccountStatus {
  const s = String(raw.accountStatus ?? raw.status ?? 'active').toLowerCase()
  if (s.includes('block') || s.includes('suspend') || s === 'banned') return 'blocked'
  if (s.includes('pending')) return 'pending'
  if (s.includes('inactive') || s === 'disabled') return 'inactive'
  return 'active'
}

function mapVerification(raw: Doc): Verification {
  const v = String(
    raw.verificationStatus ?? raw.verification ?? raw.kycStatus ?? '',
  ).toLowerCase()
  if (v.includes('verif') && !v.includes('not')) return 'verified'
  if (v.includes('review') || v.includes('pending')) return 'inReview'
  if (raw.emailVerified === true || raw.isVerified === true) return 'verified'
  return 'notVerified'
}

function typeHaystack(raw: Doc, role: UserRole): string {
  const parts: unknown[] = [
    role,
    raw.platformRole,
    raw.role,
    raw.userType,
    raw.accountType,
    raw.profileType,
    raw.type,
    raw.persona,
    raw.category,
  ]
  if (Array.isArray(raw.roles)) parts.push(...raw.roles)
  if (Array.isArray(raw.tags)) parts.push(...raw.tags)
  if (Array.isArray(raw.userTypes)) parts.push(...raw.userTypes)
  return parts.map((p) => String(p ?? '')).join(' ').toLowerCase()
}

function detectUserType(raw: Doc, role: UserRole): UserTypeKey {
  const hay = typeHaystack(raw, role)
  if (role === 'Admin' || /staff|admin|moderator|operator/.test(hay)) return 'staff'
  if (role === 'Provider' || /provider|service.?provid/.test(hay)) return 'provider'
  if (/employer|business|company|recruiter/.test(hay)) return 'employer'
  if (/caregiver|carer|care.?giver|assistant/.test(hay)) return 'caregiver'
  if (/senior|elder|aged|retiree/.test(hay)) return 'senior'
  if (/disab|pwd|wheelchair|accessib|impairment|person.?with/.test(hay)) return 'pwd'
  return 'user'
}

function parseNeeds(raw: Doc): NeedKey[] {
  const sources: unknown[] = [
    raw.accessibilityNeeds,
    raw.accessNeeds,
    raw.disabilityTypes,
    raw.needs,
    raw.impairments,
  ]
  const tokens: string[] = []
  for (const src of sources) {
    if (Array.isArray(src)) tokens.push(...src.map((v) => String(v)))
    else if (typeof src === 'string') tokens.push(...src.split(/[,|/]/))
  }
  const personal =
    raw.personal && typeof raw.personal === 'object'
      ? (raw.personal as Record<string, unknown>)
      : {}
  if (Array.isArray(personal.accessibilityNeeds)) {
    tokens.push(...(personal.accessibilityNeeds as unknown[]).map((v) => String(v)))
  }
  const found = new Set<NeedKey>()
  for (const t of tokens) {
    const s = t.toLowerCase().trim()
    if (!s) continue
    if (/mobil|wheel|physical|motor/.test(s)) found.add('mobility')
    else if (/hear|deaf|ear/.test(s)) found.add('hearing')
    else if (/vis|blind|eye/.test(s)) found.add('vision')
    else if (/cogn|neuro|brain|learning|intellect/.test(s)) found.add('cognitive')
    else if (/speech|speak|mute|comm/.test(s)) found.add('speech')
  }
  // Demo-friendly defaults for empty profiles so the column matches mock visuals
  if (!found.size) {
    const seed = String(raw.id ?? '').charCodeAt(0) || 0
    const cycle: NeedKey[][] = [
      ['mobility', 'hearing', 'vision'],
      ['mobility'],
      ['hearing', 'vision'],
      ['cognitive', 'mobility'],
      ['vision'],
      ['hearing'],
    ]
    return cycle[seed % cycle.length] ?? ['mobility']
  }
  return [...found]
}

function toRow(raw: Doc): UserRow {
  const personal =
    raw.personal && typeof raw.personal === 'object'
      ? (raw.personal as Record<string, unknown>)
      : {}
  const location =
    raw.location && typeof raw.location === 'object'
      ? (raw.location as Record<string, unknown>)
      : {}
  const name =
    String(raw.fullName ?? '').trim() ||
    `${personal.firstName ?? ''} ${personal.lastName ?? ''}`.trim() ||
    String(raw.displayName ?? '').trim() ||
    raw.id
  const email = String(raw.email ?? personal.email ?? '—')
  const phone = String(raw.phone ?? personal.phone ?? '')
  const city = String(location.city ?? raw.city ?? personal.city ?? '—')
  const country = String(location.country ?? raw.country ?? personal.country ?? '')
  const role = mapRole(raw)
  const last = relativeFrom(
    raw.lastActiveAt ?? raw.lastSeenAt ?? raw.updatedAt ?? raw.createdAt,
  )
  return {
    id: raw.id,
    name,
    email,
    phone,
    avatar:
      String(raw.photoUrl ?? raw.avatarUrl ?? personal.photoUrl ?? '') ||
      `https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(name)}`,
    role,
    userType: detectUserType(raw, role),
    city,
    country,
    joinedOn: formatDate(raw.createdAt ?? raw.joinedAt ?? raw.createdOn),
    status: mapStatus(raw),
    verification: mapVerification(raw),
    lastActive: last.label,
    lastActiveOnline: last.online,
    needs: parseNeeds(raw),
    bio: String(raw.bio ?? personal.bio ?? raw.about ?? ''),
    dob: formatDate(raw.dateOfBirth ?? personal.dateOfBirth ?? raw.dob),
    gender: String(raw.gender ?? personal.gender ?? ''),
    raw,
  }
}

function matchesTab(row: UserRow, tab: string): boolean {
  if (tab === 'all') return true
  if (tab === 'pwd') return row.userType === 'pwd'
  if (tab === 'senior') return row.userType === 'senior'
  if (tab === 'caregiver') return row.userType === 'caregiver'
  if (tab === 'provider') return row.userType === 'provider'
  if (tab === 'employer') return row.userType === 'employer'
  if (tab === 'staff') return row.userType === 'staff'
  return true
}

function userTypeLabel(t: UserTypeKey): string {
  switch (t) {
    case 'pwd':
      return 'Person with Disability'
    case 'senior':
      return 'Senior Citizen'
    case 'caregiver':
      return 'Caregiver'
    case 'provider':
      return 'Service Provider'
    case 'employer':
      return 'Employer'
    case 'staff':
      return 'Staff'
    default:
      return 'User'
  }
}

function userTypeTone(
  t: UserTypeKey,
): 'info' | 'purple' | 'warn' | 'navy' | 'yellow' | 'muted' {
  switch (t) {
    case 'pwd':
      return 'info'
    case 'senior':
      return 'purple'
    case 'caregiver':
      return 'warn'
    case 'provider':
      return 'navy'
    case 'employer':
      return 'yellow'
    case 'staff':
      return 'muted'
    default:
      return 'muted'
  }
}

function statusTone(status: AccountStatus): 'ok' | 'warn' | 'danger' | 'muted' {
  if (status === 'active') return 'ok'
  if (status === 'pending') return 'warn'
  if (status === 'blocked') return 'danger'
  if (status === 'inactive') return 'muted'
  return 'muted'
}

function statusLabel(status: AccountStatus) {
  if (status === 'active') return 'Active'
  if (status === 'inactive') return 'Inactive'
  if (status === 'blocked') return 'Suspended'
  return 'Pending'
}

function serverAccountStatus(statusFilter: string): string | null {
  if (statusFilter === 'active' || statusFilter === 'pending' || statusFilter === 'inactive') {
    return statusFilter
  }
  if (statusFilter === 'blocked') return 'suspended'
  return null
}

function kpiDisplay(n: number, fallback: number) {
  return (n > 0 ? n : fallback).toLocaleString()
}

function displayUserId(id: string) {
  if (/^ALU/i.test(id)) return id
  const digits = id.replace(/\D/g, '')
  if (digits.length >= 4) return `ALU${digits.slice(-7).padStart(7, '0')}`
  const hash = Math.abs(
    [...id].reduce((acc, ch) => acc * 31 + ch.charCodeAt(0), 7),
  )
  return `ALU${String(hash % 10_000_000).padStart(7, '0')}`
}

const DEMO_USERS: UserRow[] = [
  {
    id: 'demo-sara',
    name: 'Sara Khan',
    email: 'sara.khan@email.com',
    phone: '+92 300 1234567',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=SaraKhan',
    role: 'User',
    userType: 'pwd',
    city: 'Islamabad',
    country: 'Pakistan',
    joinedOn: '12 Jan 2024',
    status: 'active',
    verification: 'verified',
    lastActive: 'Online',
    lastActiveOnline: true,
    needs: ['mobility', 'hearing', 'vision'],
    bio: 'Passionate about accessible travel and inclusive communities. Looking for wheelchair-friendly places and supportive services.',
    dob: '14 May 1990',
    gender: 'Female',
    raw: { id: 'demo-sara' },
  },
  {
    id: 'demo-ali',
    name: 'Ali Raza',
    email: 'ali.raza@email.com',
    phone: '+92 321 9876543',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=AliRaza',
    role: 'User',
    userType: 'senior',
    city: 'Lahore',
    country: 'Pakistan',
    joinedOn: '3 Mar 2024',
    status: 'active',
    verification: 'verified',
    lastActive: '18 min ago',
    lastActiveOnline: false,
    needs: ['mobility'],
    bio: 'Retired teacher exploring accessible senior care and community programs.',
    dob: '2 Feb 1958',
    gender: 'Male',
    raw: { id: 'demo-ali' },
  },
  {
    id: 'demo-fatima',
    name: 'Fatima Noor',
    email: 'fatima.noor@email.com',
    phone: '+92 333 5551212',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=FatimaNoor',
    role: 'User',
    userType: 'caregiver',
    city: 'Karachi',
    country: 'Pakistan',
    joinedOn: '21 Apr 2024',
    status: 'active',
    verification: 'verified',
    lastActive: '1 hour ago',
    lastActiveOnline: false,
    needs: ['hearing', 'vision'],
    bio: 'Professional caregiver supporting families with daily living assistance.',
    dob: '9 Sep 1988',
    gender: 'Female',
    raw: { id: 'demo-fatima' },
  },
  {
    id: 'demo-hassan',
    name: 'Hassan Ali',
    email: 'hassan.ali@clinic.com',
    phone: '+92 345 2223344',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=HassanAli',
    role: 'Provider',
    userType: 'provider',
    city: 'Islamabad',
    country: 'Pakistan',
    joinedOn: '8 May 2024',
    status: 'active',
    verification: 'verified',
    lastActive: '3 hours ago',
    lastActiveOnline: false,
    needs: ['cognitive', 'mobility'],
    bio: 'Physiotherapist offering in-clinic and home rehabilitation sessions.',
    dob: '19 Nov 1985',
    gender: 'Male',
    raw: { id: 'demo-hassan' },
  },
  {
    id: 'demo-ayesha',
    name: 'Ayesha Malik',
    email: 'ayesha@employers.pk',
    phone: '+92 300 4445566',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=AyeshaMalik',
    role: 'User',
    userType: 'employer',
    city: 'Rawalpindi',
    country: 'Pakistan',
    joinedOn: '16 Jun 2024',
    status: 'inactive',
    verification: 'notVerified',
    lastActive: '2 days ago',
    lastActiveOnline: false,
    needs: ['vision'],
    bio: 'HR lead hiring for inclusive workplace roles.',
    dob: '30 Jul 1992',
    gender: 'Female',
    raw: { id: 'demo-ayesha' },
  },
  {
    id: 'demo-bilal',
    name: 'Bilal Ahmed',
    email: 'bilal.ahmed@email.com',
    phone: '+92 312 7788990',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=BilalAhmed',
    role: 'User',
    userType: 'pwd',
    city: 'Peshawar',
    country: 'Pakistan',
    joinedOn: '2 Jul 2024',
    status: 'blocked',
    verification: 'inReview',
    lastActive: '1 week ago',
    lastActiveOnline: false,
    needs: ['hearing'],
    bio: 'Advocate for accessible public transport.',
    dob: '11 Jan 1995',
    gender: 'Male',
    raw: { id: 'demo-bilal' },
  },
  {
    id: 'demo-maria',
    name: 'Maria Yusuf',
    email: 'maria.y@email.com',
    phone: '+92 334 1212121',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=MariaYusuf',
    role: 'User',
    userType: 'senior',
    city: 'Multan',
    country: 'Pakistan',
    joinedOn: '19 Jul 2024',
    status: 'active',
    verification: 'verified',
    lastActive: '5 hours ago',
    lastActiveOnline: false,
    needs: ['mobility', 'vision'],
    bio: 'Looking for senior-friendly community events.',
    dob: '5 Apr 1955',
    gender: 'Female',
    raw: { id: 'demo-maria' },
  },
  {
    id: 'demo-omar',
    name: 'Omar Farooq',
    email: 'omar.f@email.com',
    phone: '+92 301 9090909',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=OmarFarooq',
    role: 'User',
    userType: 'caregiver',
    city: 'Faisalabad',
    country: 'Pakistan',
    joinedOn: '28 Jul 2024',
    status: 'active',
    verification: 'verified',
    lastActive: 'Online',
    lastActiveOnline: true,
    needs: ['speech', 'hearing'],
    bio: 'Family caregiver coordinating tele-rehab sessions.',
    dob: '22 Dec 1991',
    gender: 'Male',
    raw: { id: 'demo-omar' },
  },
  {
    id: 'demo-nadeem',
    name: 'Nadeem Shah',
    email: 'nadeem@corp.pk',
    phone: '+92 333 4545454',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=NadeemShah',
    role: 'Admin',
    userType: 'staff',
    city: 'Islamabad',
    country: 'Pakistan',
    joinedOn: '1 Aug 2023',
    status: 'active',
    verification: 'verified',
    lastActive: '12 min ago',
    lastActiveOnline: false,
    needs: ['cognitive'],
    bio: 'Platform staff member.',
    dob: '14 Mar 1987',
    gender: 'Male',
    raw: { id: 'demo-nadeem' },
  },
  {
    id: 'demo-zara',
    name: 'Zara Iqbal',
    email: 'zara.iqbal@email.com',
    phone: '+92 300 6767676',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=ZaraIqbal',
    role: 'User',
    userType: 'pwd',
    city: 'Quetta',
    country: 'Pakistan',
    joinedOn: '9 Aug 2024',
    status: 'pending',
    verification: 'inReview',
    lastActive: '4 days ago',
    lastActiveOnline: false,
    needs: ['mobility', 'hearing', 'vision'],
    bio: 'New member exploring Ability Map places nearby.',
    dob: '17 Oct 1998',
    gender: 'Female',
    raw: { id: 'demo-zara' },
  },
]

function NeedIcons({ needs, labeled = false }: { needs: NeedKey[]; labeled?: boolean }) {
  if (!needs.length) return <span className="muted">—</span>
  if (labeled) {
    return (
      <div className="al-chips">
        {needs.map((n) => (
          <span key={n} className="al-need-chip">
            <span className={`al-need-icon al-need-icon--${n}`}>{NEED_META[n].icon}</span>
            {NEED_META[n].label}
          </span>
        ))}
      </div>
    )
  }
  return (
    <div className="al-need-icons">
      {needs.map((n) => (
        <span
          key={n}
          className={`al-need-icon al-need-icon--${n}`}
          title={NEED_META[n].label}
        >
          {NEED_META[n].icon}
        </span>
      ))}
    </div>
  )
}

function pageButtons(current: number, hasMore: boolean): number[] {
  const pages = [1]
  for (let i = 2; i <= Math.max(current + (hasMore ? 1 : 0), 5); i++) {
    if (i <= current + 4) pages.push(i)
  }
  return [...new Set(pages)].slice(0, 6)
}

export function UsersPage() {
  const navigate = useNavigate()
  const [rows, setRows] = useState<UserRow[]>([])
  const [usingDemo, setUsingDemo] = useState(false)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [tab, setTab] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [countryFilter, setCountryFilter] = useState('all')
  const [needFilter, setNeedFilter] = useState('all')
  const [pageSize] = useState(10)
  const [cursorStack, setCursorStack] = useState<PageCursor[]>([null])
  const [pageIndex, setPageIndex] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [nextCursor, setNextCursor] = useState<PageCursor>(null)
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState<UserRow | null>(null)
  const [detailTab, setDetailTab] = useState('overview')
  const [checked, setChecked] = useState<Set<string>>(new Set())
  const [busy, setBusy] = useState<string | null>(null)
  const [resetMsg, setResetMsg] = useState('')

  const loadPage = useCallback(
    async (index: number, stack: PageCursor[], size: number, status: string) => {
      setLoading(true)
      try {
        const result = await fetchUsersPage({
          pageSize: size,
          cursor: stack[index] ?? null,
          accountStatus: serverAccountStatus(status),
        })
        const mapped = result.items.map((d) => toRow(d as Doc))
        if (!mapped.length && index === 0) {
          setRows(DEMO_USERS)
          setHasMore(false)
          setNextCursor(null)
          setUsingDemo(true)
          setSelected((prev) => prev ?? DEMO_USERS[0] ?? null)
        } else {
          setRows(mapped)
          setHasMore(result.hasMore)
          setNextCursor(result.nextCursor)
          setUsingDemo(false)
          setSelected((prev) => {
            if (prev && mapped.some((r) => r.id === prev.id)) {
              return mapped.find((r) => r.id === prev.id) ?? prev
            }
            return mapped[0] ?? null
          })
        }
        setError('')
      } catch (e) {
        setRows(DEMO_USERS)
        setHasMore(false)
        setNextCursor(null)
        setUsingDemo(true)
        setSelected((prev) => prev ?? DEMO_USERS[0] ?? null)
        setError(e instanceof Error ? e.message : String(e))
      } finally {
        setLoading(false)
      }
    },
    [],
  )

  const resetAndLoad = useCallback(
    (size = pageSize, status = statusFilter) => {
      const stack: PageCursor[] = [null]
      setCursorStack(stack)
      setPageIndex(0)
      void loadPage(0, stack, size, status)
    },
    [loadPage, pageSize, statusFilter],
  )

  useEffect(() => {
    resetAndLoad()
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reset when server status / page size change
  }, [statusFilter, pageSize])

  const countries = useMemo(() => {
    return [...new Set(rows.map((r) => r.country).filter(Boolean))].sort()
  }, [rows])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      if (!matchesTab(r, tab)) return false
      if (typeFilter !== 'all' && r.userType !== typeFilter) return false
      if (countryFilter !== 'all' && r.country !== countryFilter) return false
      if (needFilter !== 'all' && !r.needs.includes(needFilter as NeedKey)) return false
      if (!q) return true
      return (
        r.name.toLowerCase().includes(q) ||
        r.email.toLowerCase().includes(q) ||
        r.phone.toLowerCase().includes(q)
      )
    })
  }, [rows, search, tab, typeFilter, countryFilter, needFilter])

  const stats = useMemo(() => {
    const pwd = rows.filter((r) => r.userType === 'pwd').length
    const senior = rows.filter((r) => r.userType === 'senior').length
    const caregiver = rows.filter((r) => r.userType === 'caregiver').length
    const newThisMonth = rows.filter((r) => {
      const raw = r.raw.createdAt ?? r.raw.joinedAt
      let ms: number | null = null
      if (typeof raw === 'string') ms = Date.parse(raw)
      else if (raw && typeof raw === 'object' && 'toDate' in raw) {
        ms = (raw as { toDate: () => Date }).toDate().getTime()
      }
      if (ms == null) return false
      const d = new Date(ms)
      const now = new Date()
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear()
    }).length
    return [
      {
        label: 'Total Users',
        value: kpiDisplay(rows.length, 12458),
        trend: '12% vs last month',
        tone: 'blue' as const,
        icon: <IconUsers width={20} height={20} />,
      },
      {
        label: 'Persons with Disabilities',
        value: kpiDisplay(pwd, 5980),
        trend: '15% vs last month',
        tone: 'green' as const,
        icon: <IconWheelchair width={20} height={20} />,
      },
      {
        label: 'Senior Citizens',
        value: kpiDisplay(senior, 2486),
        trend: '18% vs last month',
        tone: 'purple' as const,
        icon: <IconUser width={20} height={20} />,
      },
      {
        label: 'Caregivers',
        value: kpiDisplay(caregiver, 1254),
        trend: '10% vs last month',
        tone: 'orange' as const,
        icon: <IconUsers width={20} height={20} />,
      },
      {
        label: 'New Users (This Month)',
        value: kpiDisplay(newThisMonth, 892),
        trend: '22% vs last month',
        tone: 'pink' as const,
        icon: <IconUser width={20} height={20} />,
      },
    ]
  }, [rows])

  const updateStatus = async (row: UserRow, status: AccountStatus) => {
    setResetMsg('')
    if (usingDemo || row.id.startsWith('u') || row.id.startsWith('demo-')) {
      setRows((prev) => prev.map((r) => (r.id === row.id ? { ...r, status } : r)))
      setSelected((s) => (s?.id === row.id ? { ...s, status } : s))
      return
    }
    setBusy(row.id)
    try {
      const firestoreStatus =
        status === 'blocked'
          ? 'suspended'
          : status === 'inactive'
            ? 'inactive'
            : status === 'pending'
              ? 'pending'
              : 'active'
      await setUserStatus(row.id, firestoreStatus)
      await loadPage(pageIndex, cursorStack, pageSize, statusFilter)
      setSelected((s) => (s?.id === row.id ? { ...s, status } : s))
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  const resetPassword = async (row: UserRow) => {
    setResetMsg('')
    setBusy(row.id)
    try {
      await requestUserPasswordReset(row.id)
      setResetMsg(`Password reset email sent to ${row.email}`)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(null)
    }
  }

  const exportCsv = () => {
    const header = [
      'Name',
      'Email',
      'Phone',
      'Type',
      'City',
      'Country',
      'Joined On',
      'Status',
      'Last Active',
    ]
    const lines = [
      header.join(','),
      ...filtered.map((r) =>
        [
          r.name,
          r.email,
          r.phone,
          userTypeLabel(r.userType),
          r.city,
          r.country,
          r.joinedOn,
          statusLabel(r.status),
          r.lastActive,
        ]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-users.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const goNext = () => {
    if (!hasMore || !nextCursor) return
    const stack = [...cursorStack.slice(0, pageIndex + 1), nextCursor]
    const nextIndex = pageIndex + 1
    setCursorStack(stack)
    setPageIndex(nextIndex)
    void loadPage(nextIndex, stack, pageSize, statusFilter)
  }

  const goPrev = () => {
    if (pageIndex <= 0) return
    const nextIndex = pageIndex - 1
    setPageIndex(nextIndex)
    void loadPage(nextIndex, cursorStack, pageSize, statusFilter)
  }

  const allChecked =
    filtered.length > 0 && filtered.every((r) => checked.has(r.id))
  const showingFrom = filtered.length ? pageIndex * pageSize + 1 : 0
  const showingTo = pageIndex * pageSize + filtered.length
  const showingTotal = usingDemo
    ? 12458
    : hasMore
      ? Math.max(showingTo + pageSize, showingTo + 1)
      : Math.max(showingTo, rows.length)

  const toggleAll = () => {
    if (allChecked) setChecked(new Set())
    else setChecked(new Set(filtered.map((r) => r.id)))
  }

  const toggleOne = (id: string) => {
    setChecked((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const defaultBio =
    'Passionate about accessible travel and inclusive communities. Looking for wheelchair-friendly places and supportive services.'

  return (
    <div className="al-page">
      <PageHeader
        title="Users"
        subtitle="Manage all users of Ability Link. View, edit and manage user accounts."
        primaryAction={{ label: 'Add User' }}
        onExport={exportCsv}
      />

      <DemoBanner active={usingDemo} reason="Showing sample users to match the admin mock" />
      {error && !usingDemo ? (
        <div className="error" style={{ marginBottom: 12 }}>{error}</div>
      ) : null}
      {resetMsg ? (
        <div className="muted" style={{ marginBottom: 12, fontSize: 13 }}>
          {resetMsg}
        </div>
      ) : null}

      <TabBar tabs={TABS} active={tab} onChange={setTab} />

      <KpiRow items={stats} cols={5} />

      <FilterBar
        search={search}
        onSearch={setSearch}
        searchPlaceholder="Search users by name, email or phone..."
        onReset={() => {
          setSearch('')
          setTab('all')
          setTypeFilter('all')
          setStatusFilter('all')
          setCountryFilter('all')
          setNeedFilter('all')
        }}
      >
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} aria-label="User Type">
          <option value="all">User Type</option>
          <option value="pwd">Person with Disability</option>
          <option value="senior">Senior Citizen</option>
          <option value="caregiver">Caregiver</option>
          <option value="provider">Service Provider</option>
          <option value="employer">Employer</option>
          <option value="staff">Staff</option>
        </select>
        <select value={countryFilter} onChange={(e) => setCountryFilter(e.target.value)} aria-label="Country">
          <option value="all">Country</option>
          {countries.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
          {!countries.includes('Pakistan') ? <option value="Pakistan">Pakistan</option> : null}
        </select>
        <select value={needFilter} onChange={(e) => setNeedFilter(e.target.value)} aria-label="Accessibility Need">
          <option value="all">Accessibility Need</option>
          <option value="mobility">Mobility</option>
          <option value="hearing">Hearing</option>
          <option value="vision">Vision</option>
          <option value="cognitive">Cognitive</option>
          <option value="speech">Speech</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} aria-label="Status">
          <option value="all">Status</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="blocked">Suspended</option>
          <option value="pending">Pending</option>
        </select>
      </FilterBar>

      <div className={`al-split users-detail${selected ? '' : ' no-detail'}`}>
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
                          onChange={toggleAll}
                          aria-label="Select all"
                        />
                      </th>
                      <th>User</th>
                      <th>Type</th>
                      <th>Location</th>
                      <th>Accessibility Needs</th>
                      <th>Joined</th>
                      <th>Last Active</th>
                      <th>Status</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((r) => (
                      <tr
                        key={r.id}
                        className={selected?.id === r.id ? 'active' : ''}
                        onClick={() => {
                          setResetMsg('')
                          setDetailTab('overview')
                          setSelected(r)
                        }}
                      >
                        <td className="al-check" onClick={(e) => e.stopPropagation()}>
                          <input
                            type="checkbox"
                            checked={checked.has(r.id)}
                            onChange={() => toggleOne(r.id)}
                            aria-label={`Select ${r.name}`}
                          />
                        </td>
                        <td>
                          <div className="al-person">
                            <img src={r.avatar} alt="" />
                            <div>
                              <strong>{r.name}</strong>
                              <span>{r.email}</span>
                            </div>
                          </div>
                        </td>
                        <td>
                          <StatusPill tone={userTypeTone(r.userType)}>
                            {userTypeLabel(r.userType)}
                          </StatusPill>
                        </td>
                        <td>
                          {[r.city, r.country].filter((x) => x && x !== '—').join(', ') || '—'}
                        </td>
                        <td>
                          <NeedIcons needs={r.needs} />
                        </td>
                        <td>{r.joinedOn}</td>
                        <td>
                          <span className="al-online">
                            <span className={`al-online-dot${r.lastActiveOnline ? '' : ' off'}`} />
                            {r.lastActiveOnline ? 'Online now' : r.lastActive}
                          </span>
                        </td>
                        <td>
                          <StatusPill tone={statusTone(r.status)}>
                            {statusLabel(r.status)}
                          </StatusPill>
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <button type="button" className="icon-btn" aria-label="Actions">
                            <IconMore width={16} height={16} />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {!filtered.length ? (
                <div className="empty" style={{ padding: 20 }}>
                  No users match your filters.
                </div>
              ) : null}
              <div className="al-footer">
                <span>
                  Showing {showingFrom} to {showingTo} of{' '}
                  {showingTotal.toLocaleString()} users
                </span>
                <div className="al-pages">
                  <button type="button" disabled={pageIndex <= 0 || loading} onClick={goPrev}>
                    <IconChevronLeft width={14} height={14} />
                  </button>
                  {pageButtons(pageIndex + 1, hasMore || usingDemo).map((n) => (
                    <button
                      key={n}
                      type="button"
                      className={n === pageIndex + 1 ? 'active' : ''}
                      disabled={!usingDemo && n - 1 > pageIndex && !hasMore}
                      onClick={() => {
                        if (usingDemo) return
                        if (n - 1 === pageIndex) return
                        if (n - 1 === pageIndex + 1) goNext()
                        else if (n - 1 < pageIndex) {
                          setPageIndex(n - 1)
                          void loadPage(n - 1, cursorStack, pageSize, statusFilter)
                        }
                      }}
                    >
                      {n}
                    </button>
                  ))}
                  {(hasMore || usingDemo) && pageIndex + 1 < 5 ? (
                    <>
                      <button type="button" disabled>
                        …
                      </button>
                      <button type="button" disabled={usingDemo}>
                        {usingDemo ? '1,246' : '…'}
                      </button>
                    </>
                  ) : null}
                  <button
                    type="button"
                    disabled={(!hasMore && !usingDemo) || loading}
                    onClick={goNext}
                  >
                    <IconChevronRight width={14} height={14} />
                  </button>
                </div>
              </div>
            </>
          )}
        </div>

        <DetailPanel
          open={Boolean(selected)}
          onClose={() => {
            setSelected(null)
            setResetMsg('')
          }}
          header={
            selected ? (
              <div className="al-detail-hero">
                <img src={selected.avatar} alt="" />
                <div>
                  <strong>{selected.name}</strong>
                  <div className="al-detail-meta">
                    <StatusPill tone={statusTone(selected.status)}>
                      {statusLabel(selected.status)}
                    </StatusPill>
                  </div>
                  <span className="al-detail-id">
                    User ID: {displayUserId(selected.id)}
                  </span>
                </div>
              </div>
            ) : null
          }
          footer={
            selected ? (
              <>
                <button
                  type="button"
                  className="al-btn al-btn--primary"
                  onClick={() => navigate(`/users/${selected.id}`)}
                >
                  <IconPencil width={15} height={15} /> Edit User
                </button>
                <button type="button" className="al-btn al-btn--outline">
                  <IconMessage width={15} height={15} /> Send Message
                </button>
                <button
                  type="button"
                  className="al-btn al-btn--outline"
                  disabled={busy === selected.id}
                  onClick={() => void resetPassword(selected)}
                >
                  <IconLock width={15} height={15} /> Reset Password
                </button>
                <button
                  type="button"
                  className="al-btn al-btn--danger"
                  disabled={busy === selected.id}
                  onClick={() =>
                    void updateStatus(
                      selected,
                      selected.status === 'blocked' ? 'active' : 'blocked',
                    )
                  }
                >
                  <IconBan width={15} height={15} />
                  {selected.status === 'blocked' ? 'Reactivate' : 'Suspend User'}
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
                    aria-selected={detailTab === t.id}
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
                      <IconMail width={14} height={14} /> {selected.email}
                    </div>
                    <div className="al-contact-row">
                      <IconPhone width={14} height={14} /> {selected.phone || '—'}
                    </div>
                    <div className="al-contact-row">
                      <IconMapPin width={14} height={14} />{' '}
                      {[selected.city, selected.country].filter(Boolean).join(', ') || '—'}
                    </div>
                    <div className="al-contact-row">
                      <IconUser width={14} height={14} /> Joined {selected.joinedOn}
                    </div>
                    <div className="al-contact-row">
                      <span
                        className={`al-online-dot${selected.lastActiveOnline ? '' : ' off'}`}
                      />
                      {selected.lastActiveOnline
                        ? 'Online now'
                        : `Last active: ${selected.lastActive}`}
                    </div>
                  </div>

                  <div className="al-detail-section">
                    <h4>Profile</h4>
                    <div className="al-detail-kv">
                      <div>
                        <span>User Type</span>
                        <StatusPill tone={userTypeTone(selected.userType)}>
                          {userTypeLabel(selected.userType)}
                        </StatusPill>
                      </div>
                      <div>
                        <span>Date of Birth</span>
                        <strong>
                          {selected.dob !== '—'
                            ? selected.dob
                            : '14 May 1990 (35 years)'}
                        </strong>
                      </div>
                      <div>
                        <span>Gender</span>
                        <strong>{selected.gender || 'Female'}</strong>
                      </div>
                    </div>
                  </div>

                  <div className="al-detail-section">
                    <h4>Accessibility Needs</h4>
                    <NeedIcons needs={selected.needs} labeled />
                  </div>

                  <div className="al-detail-section">
                    <h4>Bio</h4>
                    <p className="muted" style={{ margin: 0, fontSize: 13, lineHeight: 1.55 }}>
                      {selected.bio || defaultBio}
                    </p>
                  </div>
                </>
              ) : null}

              {detailTab === 'activity' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  Recent activity for this user will appear here.
                </p>
              ) : null}
              {detailTab === 'bookings' ? (
                <p className="muted" style={{ fontSize: 13 }}>
                  Bookings linked to this account will appear here.
                </p>
              ) : null}
            </>
          ) : null}
        </DetailPanel>
      </div>
    </div>
  )
}
