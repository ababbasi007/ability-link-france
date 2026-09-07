import {
  sendPasswordResetEmail,
} from 'firebase/auth'
import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  type DocumentData,
} from 'firebase/firestore'
import { getDownloadURL, ref, uploadBytes } from 'firebase/storage'
import { auth, db, storage } from './firebase'
import { fetchCollectionPage, type PageCursor } from './pagination'

/** Firebase Auth UID for admin@abilitylink.app (demo admin). */
export const BOOTSTRAP_ADMIN_UID = 'yTbovm71yGQQgbexooWVwZDMMZ72'

export type AccessibilityFeatureDef = {
  key: string
  label: string
  description: string
  category: 'Mobility' | 'Facilities' | 'Communication' | 'Sensory' | 'Other'
  active: boolean
}

/** Home screen carousel slide. Empty imageUrl → app uses bundled asset. */
export type HomeHeroSlide = {
  id: string
  imageUrl: string
  aspectRatio: number
  ctaLabel: string
  /** Maps to in-app navigation (see Flutter HomeHero). */
  action: string
  active: boolean
  sortOrder: number
}

export const ADMIN_ROLES = [
  'super_admin',
  'moderator',
  'content_manager',
  'clinical_reviewer',
  'provider_manager',
  'finance_manager',
] as const

export type AdminRole = (typeof ADMIN_ROLES)[number]

export const ADMIN_ROLE_LABELS: Record<AdminRole, string> = {
  super_admin: 'Super Admin',
  moderator: 'Moderator',
  content_manager: 'Content Manager',
  clinical_reviewer: 'Clinical Reviewer',
  provider_manager: 'Provider Manager',
  finance_manager: 'Finance Manager',
}

export type PlatformConfig = {
  adminUids: string[]
  moderatorUids: string[]
  /** REQ-10.1 — additive RBAC map; legacy lists still authoritative for super_admin/moderator sync. */
  roles: Record<string, AdminRole[]>
  placeCategories: string[]
  providerCategories: string[]
  maintenanceMessage: string
  accessibilityFeatures: AccessibilityFeatureDef[]
  homeHeroSlides: HomeHeroSlide[]
  adminSettings: AdminSettings
}

export function normalizeRolesMap(
  raw: unknown,
  adminUids: string[] = [],
  moderatorUids: string[] = [],
): Record<string, AdminRole[]> {
  const out: Record<string, AdminRole[]> = {}
  if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
    for (const [uid, list] of Object.entries(raw as Record<string, unknown>)) {
      if (!uid.trim()) continue
      const roles = (Array.isArray(list) ? list : [])
        .map((r) => String(r))
        .filter((r): r is AdminRole =>
          (ADMIN_ROLES as readonly string[]).includes(r),
        )
      if (roles.length) out[uid] = [...new Set(roles)]
    }
  }
  for (const uid of adminUids) {
    const set = new Set(out[uid] ?? [])
    set.add('super_admin')
    out[uid] = [...set]
  }
  for (const uid of moderatorUids) {
    const set = new Set(out[uid] ?? [])
    set.add('moderator')
    out[uid] = [...set]
  }
  return out
}

/** Roles for a UID from roles map + legacy lists. */
export function rolesForUid(
  config: PlatformConfig | null,
  uid: string | null,
): AdminRole[] {
  if (!uid) return []
  if (uid === BOOTSTRAP_ADMIN_UID) return ['super_admin', 'moderator']
  if (!config) return []
  const fromMap = config.roles[uid] ?? []
  const legacy: AdminRole[] = []
  if (config.adminUids.includes(uid)) legacy.push('super_admin')
  if (config.moderatorUids.includes(uid)) legacy.push('moderator')
  return [...new Set([...fromMap, ...legacy])]
}

export function hasRole(
  config: PlatformConfig | null,
  uid: string | null,
  role: AdminRole | AdminRole[],
) {
  const have = rolesForUid(config, uid)
  const need = Array.isArray(role) ? role : [role]
  return need.some((r) => have.includes(r))
}

export function hasAnyRole(
  config: PlatformConfig | null,
  uid: string | null,
  roles: AdminRole[],
) {
  return hasRole(config, uid, roles)
}

/** Can sign into the admin panel (legacy lists or any RBAC role). */
export function canAccessPanel(
  config: PlatformConfig | null,
  uid: string | null,
) {
  if (!uid) return false
  if (uid === BOOTSTRAP_ADMIN_UID) return true
  if (!config) return false
  if (config.adminUids.includes(uid) || config.moderatorUids.includes(uid)) {
    return true
  }
  return rolesForUid(config, uid).length > 0
}

export type AdminSettings = {
  general: {
    platformName: string
    platformEmail: string
    timeZone: string
    dateFormat: string
    language: string
  }
  notifications: {
    email: boolean
    push: boolean
    inApp: boolean
    reports: boolean
    reviews: boolean
  }
  security: {
    twoFactorEnabled: boolean
    loginAlerts: boolean
    sessionTimeoutMinutes: number
    passwordExpiryDays: number
  }
  email: {
    smtpServer: string
    smtpPort: string
    fromEmail: string
    fromName: string
    templateCount: number
  }
  payments: {
    gatewaysActive: number
    currency: string
    subscriptionPlans: number
    transactionFee: string
  }
  platform: {
    maintenanceMode: boolean
    registrationOpen: boolean
    reviewModeration: string
    defaultMapView: string
  }
  backup: {
    lastBackupAt: string
    frequency: string
    retention: string
    storageUsedGb: number
    storageQuotaGb: number
  }
  advanced: {
    apiBaseUrl: string
    webhooksEnabled: boolean
    webhooksUrl: string
    integrationsNotes: string
    developerMode: boolean
  }
}

export const DEFAULT_ADMIN_SETTINGS: AdminSettings = {
  general: {
    platformName: 'Ability Link',
    platformEmail: 'support@abilitylink.com',
    timeZone: '(UTC+05:00) Asia/Karachi',
    dateFormat: 'MMM d, yyyy',
    language: 'English (US)',
  },
  notifications: {
    email: true,
    push: true,
    inApp: true,
    reports: true,
    reviews: false,
  },
  security: {
    twoFactorEnabled: false,
    loginAlerts: true,
    sessionTimeoutMinutes: 30,
    passwordExpiryDays: 90,
  },
  email: {
    smtpServer: 'smtp.abilitylink.com',
    smtpPort: '587',
    fromEmail: 'noreply@abilitylink.com',
    fromName: 'Ability Link',
    templateCount: 12,
  },
  payments: {
    gatewaysActive: 2,
    currency: 'USD ($)',
    subscriptionPlans: 3,
    transactionFee: '2.9% + $0.30',
  },
  platform: {
    maintenanceMode: false,
    registrationOpen: true,
    reviewModeration: 'Auto + Manual',
    defaultMapView: 'Standard',
  },
  backup: {
    lastBackupAt: '',
    frequency: 'Daily',
    retention: '1 Year',
    storageUsedGb: 0,
    storageQuotaGb: 100,
  },
  advanced: {
    apiBaseUrl: 'https://abilitylink-3ac64.web.app/api',
    webhooksEnabled: false,
    webhooksUrl: '',
    integrationsNotes: '',
    developerMode: false,
  },
}

function asBool(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback
}

function asNum(value: unknown, fallback: number) {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function asStr(value: unknown, fallback: string) {
  return typeof value === 'string' ? value : fallback
}

export function normalizeAdminSettings(raw: unknown, maintenanceMessage = ''): AdminSettings {
  const d = raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : {}
  const g = (d.general && typeof d.general === 'object' ? d.general : {}) as Record<string, unknown>
  const n = (d.notifications && typeof d.notifications === 'object' ? d.notifications : {}) as Record<
    string,
    unknown
  >
  const s = (d.security && typeof d.security === 'object' ? d.security : {}) as Record<string, unknown>
  const e = (d.email && typeof d.email === 'object' ? d.email : {}) as Record<string, unknown>
  const p = (d.payments && typeof d.payments === 'object' ? d.payments : {}) as Record<string, unknown>
  const pl = (d.platform && typeof d.platform === 'object' ? d.platform : {}) as Record<string, unknown>
  const b = (d.backup && typeof d.backup === 'object' ? d.backup : {}) as Record<string, unknown>
  const a = (d.advanced && typeof d.advanced === 'object' ? d.advanced : {}) as Record<string, unknown>
  const def = DEFAULT_ADMIN_SETTINGS
  return {
    general: {
      platformName: asStr(g.platformName, def.general.platformName),
      platformEmail: asStr(g.platformEmail, def.general.platformEmail),
      timeZone: asStr(g.timeZone, def.general.timeZone),
      dateFormat: asStr(g.dateFormat, def.general.dateFormat),
      language: asStr(g.language, def.general.language),
    },
    notifications: {
      email: asBool(n.email, def.notifications.email),
      push: asBool(n.push, def.notifications.push),
      inApp: asBool(n.inApp, def.notifications.inApp),
      reports: asBool(n.reports, def.notifications.reports),
      reviews: asBool(n.reviews, def.notifications.reviews),
    },
    security: {
      twoFactorEnabled: asBool(s.twoFactorEnabled, def.security.twoFactorEnabled),
      loginAlerts: asBool(s.loginAlerts, def.security.loginAlerts),
      sessionTimeoutMinutes: asNum(s.sessionTimeoutMinutes, def.security.sessionTimeoutMinutes),
      passwordExpiryDays: asNum(s.passwordExpiryDays, def.security.passwordExpiryDays),
    },
    email: {
      smtpServer: asStr(e.smtpServer, def.email.smtpServer),
      smtpPort: asStr(e.smtpPort, def.email.smtpPort),
      fromEmail: asStr(e.fromEmail, def.email.fromEmail),
      fromName: asStr(e.fromName, def.email.fromName),
      templateCount: asNum(e.templateCount, def.email.templateCount),
    },
    payments: {
      gatewaysActive: asNum(p.gatewaysActive, def.payments.gatewaysActive),
      currency: asStr(p.currency, def.payments.currency),
      subscriptionPlans: asNum(p.subscriptionPlans, def.payments.subscriptionPlans),
      transactionFee: asStr(p.transactionFee, def.payments.transactionFee),
    },
    platform: {
      maintenanceMode:
        typeof pl.maintenanceMode === 'boolean'
          ? pl.maintenanceMode
          : Boolean(maintenanceMessage.trim()),
      registrationOpen: asBool(pl.registrationOpen, def.platform.registrationOpen),
      reviewModeration: asStr(pl.reviewModeration, def.platform.reviewModeration),
      defaultMapView: asStr(pl.defaultMapView, def.platform.defaultMapView),
    },
    backup: {
      lastBackupAt: asStr(b.lastBackupAt, def.backup.lastBackupAt),
      frequency: asStr(b.frequency, def.backup.frequency),
      retention: asStr(b.retention, def.backup.retention),
      storageUsedGb: asNum(b.storageUsedGb, def.backup.storageUsedGb),
      storageQuotaGb: asNum(b.storageQuotaGb, def.backup.storageQuotaGb),
    },
    advanced: {
      apiBaseUrl: asStr(a.apiBaseUrl, def.advanced.apiBaseUrl),
      webhooksEnabled: asBool(a.webhooksEnabled, def.advanced.webhooksEnabled),
      webhooksUrl: asStr(a.webhooksUrl, def.advanced.webhooksUrl),
      integrationsNotes: asStr(a.integrationsNotes, def.advanced.integrationsNotes),
      developerMode: asBool(a.developerMode, def.advanced.developerMode),
    },
  }
}

export const DEFAULT_HOME_HERO_SLIDES: HomeHeroSlide[] = [
  {
    id: 'ability_map',
    imageUrl: '',
    aspectRatio: 1024 / 415,
    ctaLabel: 'Explore Ability Map',
    action: 'explore_map',
    active: true,
    sortOrder: 0,
  },
  {
    id: 'tele_rehab',
    imageUrl: '',
    aspectRatio: 1024 / 415,
    ctaLabel: 'Start Your Recovery Journey',
    action: 'tele_rehab',
    active: true,
    sortOrder: 1,
  },
  {
    id: 'tele_health',
    imageUrl: '',
    aspectRatio: 1024 / 415,
    ctaLabel: 'Your Health, Our Priority',
    action: 'tele_health',
    active: true,
    sortOrder: 2,
  },
  {
    id: 'tourism',
    imageUrl: '',
    aspectRatio: 1024 / 415,
    ctaLabel: 'Explore the World, Your Way',
    action: 'tourism',
    active: true,
    sortOrder: 3,
  },
  {
    id: 'assistive_tech',
    imageUrl: '',
    aspectRatio: 1024 / 426,
    ctaLabel: 'Explore Assistive Technology',
    action: 'assistive_tech',
    active: true,
    sortOrder: 4,
  },
  {
    id: 'caregiver',
    imageUrl: '',
    aspectRatio: 1024 / 415,
    ctaLabel: 'Find a Caregiver Today',
    action: 'caregiver',
    active: true,
    sortOrder: 5,
  },
]

export const HOME_HERO_ACTIONS: { value: string; label: string }[] = [
  { value: 'explore_map', label: 'Ability Map' },
  { value: 'tele_rehab', label: 'Tele Rehab' },
  { value: 'tele_health', label: 'Tele Health' },
  { value: 'tourism', label: 'Tourism' },
  { value: 'assistive_tech', label: 'Assistive Tech' },
  { value: 'caregiver', label: 'Caregiver' },
  { value: 'explore_services', label: 'Explore Services' },
  { value: 'join', label: 'Join / Messages' },
]

function normalizeHomeHeroSlides(raw: unknown): HomeHeroSlide[] {
  if (!Array.isArray(raw) || raw.length === 0) return DEFAULT_HOME_HERO_SLIDES
  const byId = new Map(
    DEFAULT_HOME_HERO_SLIDES.map((d) => [d.id, d] as const),
  )
  const parsed = raw
    .map((item, index) => {
      if (!item || typeof item !== 'object') return null
      const d = item as Record<string, unknown>
      const id = String(d.id ?? '').trim() || `slide_${index}`
      const fallback = byId.get(id)
      return {
        id,
        imageUrl: String(d.imageUrl ?? fallback?.imageUrl ?? '').trim(),
        aspectRatio:
          typeof d.aspectRatio === 'number' && d.aspectRatio > 0
            ? d.aspectRatio
            : (fallback?.aspectRatio ?? 1024 / 415),
        ctaLabel: String(d.ctaLabel ?? fallback?.ctaLabel ?? 'Learn more').trim(),
        action: String(d.action ?? fallback?.action ?? 'explore_map').trim(),
        active: d.active !== false,
        sortOrder:
          typeof d.sortOrder === 'number' ? d.sortOrder : (fallback?.sortOrder ?? index),
      } satisfies HomeHeroSlide
    })
    .filter((s): s is HomeHeroSlide => s != null)
  parsed.sort((a, b) => a.sortOrder - b.sortOrder)
  return parsed.length > 0 ? parsed : DEFAULT_HOME_HERO_SLIDES
}

/** Default amenity catalog aligned with Flutter PlaceAmenities. */
export const DEFAULT_ACCESSIBILITY_FEATURES: AccessibilityFeatureDef[] = [
  { key: 'stepFree', label: 'Step-Free Entrance', description: 'Ground-level or leveled entrance without steps', category: 'Mobility', active: true },
  { key: 'ramp', label: 'Ramps', description: 'Entry and transition ramps for mobility devices', category: 'Mobility', active: true },
  { key: 'elevator', label: 'Elevator', description: 'Accessible elevators to public floors', category: 'Mobility', active: true },
  { key: 'wideCorridors', label: 'Wide Doorways / Corridors', description: 'Wide indoor routes for wheelchairs', category: 'Mobility', active: true },
  { key: 'accessibleTransit', label: 'Accessible Pathways', description: 'Smooth indoor and outdoor routes', category: 'Mobility', active: true },
  { key: 'toilet', label: 'Accessible Restroom', description: 'Restrooms designed for wheelchair users', category: 'Facilities', active: true },
  { key: 'parking', label: 'Accessible Parking', description: 'Reserved accessible parking near entrances', category: 'Facilities', active: true },
  { key: 'dropOff', label: 'Accessible Drop-Off', description: 'Drop-off zone close to entrance', category: 'Facilities', active: true },
  { key: 'hearing', label: 'Hearing Assistance', description: 'Hearing loops and assisted listening', category: 'Communication', active: true },
  { key: 'signLanguage', label: 'Sign Language Support', description: 'Staff or services with sign language', category: 'Communication', active: true },
  { key: 'braille', label: 'Braille / Tactile', description: 'Braille labels and tactile wayfinding', category: 'Communication', active: true },
  { key: 'captions', label: 'Captioned Displays', description: 'Captioned screens and displays', category: 'Communication', active: true },
  { key: 'lowVisionFriendly', label: 'Low Vision Friendly', description: 'High-contrast signage and clear wayfinding', category: 'Sensory', active: true },
  { key: 'quiet', label: 'Quiet / Sensory-Friendly', description: 'Calm spaces with reduced sensory load', category: 'Sensory', active: true },
  { key: 'serviceAnimal', label: 'Service Animal Friendly', description: 'Service animals welcome', category: 'Other', active: true },
  { key: 'audioAnnouncements', label: 'Audio Assistance', description: 'Audio announcements and guidance', category: 'Sensory', active: true },
]

export function isModerator(config: PlatformConfig | null, uid: string | null) {
  if (!uid) return false
  if (uid === BOOTSTRAP_ADMIN_UID) return true
  if (!config) return false
  if (config.adminUids.includes(uid) || config.moderatorUids.includes(uid)) {
    return true
  }
  return hasRole(config, uid, ['super_admin', 'moderator'])
}

export function isAdmin(config: PlatformConfig | null, uid: string | null) {
  if (!uid) return false
  if (uid === BOOTSTRAP_ADMIN_UID) return true
  if (!config) return false
  return config.adminUids.includes(uid) || hasRole(config, uid, 'super_admin')
}

export async function loadPlatformConfig(): Promise<PlatformConfig | null> {
  if (!db) return null
  const snap = await getDoc(doc(db, 'platformConfig', 'settings'))
  if (!snap.exists()) return null
  const d = snap.data()
  const adminUids = (d.adminUids as string[]) ?? []
  const moderatorUids = (d.moderatorUids as string[]) ?? []
  return {
    adminUids,
    moderatorUids,
    roles: normalizeRolesMap(d.roles, adminUids, moderatorUids),
    placeCategories: (d.placeCategories as string[]) ?? [],
    providerCategories: (d.providerCategories as string[]) ?? [],
    maintenanceMessage: (d.maintenanceMessage as string) ?? '',
    accessibilityFeatures: Array.isArray(d.accessibilityFeatures)
      ? (d.accessibilityFeatures as AccessibilityFeatureDef[])
      : DEFAULT_ACCESSIBILITY_FEATURES,
    homeHeroSlides: normalizeHomeHeroSlides(d.homeHeroSlides),
    adminSettings: normalizeAdminSettings(
      d.adminSettings,
      (d.maintenanceMessage as string) ?? '',
    ),
  }
}

/** One-time create of platformConfig/settings when missing (requires rules deploy). */
export async function seedPlatformConfigIfMissing(uid: string): Promise<PlatformConfig | null> {
  if (!db || !uid) return null
  const existing = await loadPlatformConfig()
  if (existing) return existing
  const seeded: PlatformConfig = {
    adminUids: [uid],
    moderatorUids: [uid],
    roles: { [uid]: ['super_admin', 'moderator'] },
    placeCategories: [
      'hospital',
      'cafe',
      'library',
      'mall',
      'transit',
      'park',
      'restaurant',
      'pharmacy',
      'hotel',
      'other',
    ],
    providerCategories: ['healthcare', 'rehab', 'education', 'caregiving', 'other'],
    maintenanceMessage: '',
    accessibilityFeatures: DEFAULT_ACCESSIBILITY_FEATURES,
    homeHeroSlides: DEFAULT_HOME_HERO_SLIDES,
    adminSettings: DEFAULT_ADMIN_SETTINGS,
  }
  await setDoc(doc(db, 'platformConfig', 'settings'), seeded)
  return seeded
}

export async function saveTaxonomy(input: {
  placeCategories: string[]
  providerCategories: string[]
  maintenanceMessage: string
}) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'platformConfig', 'settings'), {
    placeCategories: input.placeCategories,
    providerCategories: input.providerCategories,
    maintenanceMessage: input.maintenanceMessage.trim(),
  })
}

/** Persist admin console settings (general, notifications, security, etc.). */
export async function saveAdminSettings(
  settings: AdminSettings,
  opts?: { maintenanceMessage?: string },
) {
  if (!db) throw new Error('Firebase not configured')
  const normalized = normalizeAdminSettings(settings)
  const maintenanceMessage =
    opts?.maintenanceMessage !== undefined
      ? opts.maintenanceMessage.trim()
      : normalized.platform.maintenanceMode
        ? 'Platform is under maintenance. Please try again later.'
        : ''
  await updateDoc(doc(db, 'platformConfig', 'settings'), {
    adminSettings: normalized,
    maintenanceMessage,
  })
  await writeActivityLog({
    level: 'info',
    module: 'System',
    event: 'Admin settings updated',
    details: normalized.platform.maintenanceMode ? 'Maintenance ON' : 'Settings saved',
  })
}

export async function updateAdminDisplayName(displayName: string) {
  if (!auth?.currentUser) throw new Error('Sign in required')
  const { updateProfile } = await import('firebase/auth')
  const name = displayName.trim()
  if (!name) throw new Error('Name is required')
  await updateProfile(auth.currentUser, { displayName: name })
  await auth.currentUser.reload()
  return auth.currentUser.displayName ?? name
}

export async function changeAdminPassword(input: {
  currentPassword: string
  newPassword: string
}) {
  if (!auth?.currentUser?.email) throw new Error('Sign in required')
  const { EmailAuthProvider, reauthenticateWithCredential, updatePassword } = await import(
    'firebase/auth'
  )
  if (input.newPassword.length < 8) {
    throw new Error('New password must be at least 8 characters')
  }
  const cred = EmailAuthProvider.credential(auth.currentUser.email, input.currentPassword)
  await reauthenticateWithCredential(auth.currentUser, cred)
  await updatePassword(auth.currentUser, input.newPassword)
}

/** Grant/revoke admin & moderator UIDs; syncs roles map (REQ-10.1). */
export async function saveAccessLists(input: {
  adminUids: string[]
  moderatorUids: string[]
  roles?: Record<string, AdminRole[]>
}) {
  if (!db) throw new Error('Firebase not configured')
  const admins = [...new Set(input.adminUids.map((u) => u.trim()).filter(Boolean))]
  const mods = [...new Set(input.moderatorUids.map((u) => u.trim()).filter(Boolean))]
  const roles = normalizeRolesMap(input.roles ?? {}, admins, mods)
  // Ensure every roles UID also appears in a legacy list when they only have
  // specialized roles — they still need panel access without being moderators.
  await updateDoc(doc(db, 'platformConfig', 'settings'), {
    adminUids: admins,
    moderatorUids: mods,
    roles,
  })
  await writeActivityLog({
    level: 'info',
    module: 'System',
    event: 'Access lists & roles updated',
    details: `${admins.length} admins, ${mods.length} moderators, ${Object.keys(roles).length} role entries`,
  })
}

/** Update roles for one UID; keeps adminUids/moderatorUids in sync. */
export async function saveUserRoles(uid: string, roles: AdminRole[]) {
  if (!db) throw new Error('Firebase not configured')
  const config = await loadPlatformConfig()
  if (!config) throw new Error('platformConfig/settings missing')
  const cleanUid = uid.trim()
  if (!cleanUid) throw new Error('UID required')
  const nextRoles = { ...config.roles }
  const unique = [...new Set(roles.filter((r) => (ADMIN_ROLES as readonly string[]).includes(r)))]
  if (unique.length === 0) delete nextRoles[cleanUid]
  else nextRoles[cleanUid] = unique

  let adminUids = [...config.adminUids]
  let moderatorUids = [...config.moderatorUids]
  adminUids = adminUids.filter((u) => u !== cleanUid)
  moderatorUids = moderatorUids.filter((u) => u !== cleanUid)
  if (unique.includes('super_admin')) adminUids.push(cleanUid)
  else if (unique.includes('moderator')) moderatorUids.push(cleanUid)
  // Specialized roles (content_manager etc.) alone: keep them out of legacy
  // lists but present in roles — canAccessPanel uses rolesForUid.

  await saveAccessLists({ adminUids, moderatorUids, roles: nextRoles })
}

function mapDocs(snap: Awaited<ReturnType<typeof getDocs>>) {
  return snap.docs.map((d) => {
    const data = d.data() as DocumentData
    return { id: d.id, ...data } as DocumentData & { id: string }
  })
}

export async function fetchPlaces(max = 200) {
  if (!db) return []
  const snap = await getDocs(query(collection(db, 'places'), limit(max)))
  return mapDocs(snap)
}

export type PlacesPageParams = {
  pageSize?: number
  cursor?: PageCursor
  verified?: boolean | null
  city?: string | null
}

export async function fetchPlacesPage(params: PlacesPageParams = {}) {
  const equality: Record<string, string | boolean> = {}
  if (params.verified != null) equality.verified = params.verified
  if (params.city) equality.city = params.city
  return fetchCollectionPage({
    collectionName: 'places',
    pageSize: params.pageSize ?? 25,
    cursor: params.cursor ?? null,
    orderField: 'createdAt',
    equality,
  })
}

export async function fetchPlaceSubmissions(max = 50) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(
        collection(db, 'placeSubmissions'),
        where('status', '==', 'pending'),
        limit(max),
      ),
    )
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, 'placeSubmissions'), limit(max)))
    return mapDocs(snap).filter((d) => (d.status as string) === 'pending')
  }
}

/** All place submissions (any status) for the verification console. */
export async function fetchAllPlaceSubmissions(max = 200) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(collection(db, 'placeSubmissions'), orderBy('createdAt', 'desc'), limit(max)),
    )
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, 'placeSubmissions'), limit(max)))
    return mapDocs(snap)
  }
}

export type SubmissionStatus =
  | 'pending'
  | 'inReview'
  | 'approved'
  | 'rejected'
  | 'needsInfo'
  | 'reported'

export async function setSubmissionStatus(
  id: string,
  status: SubmissionStatus | 'approved' | 'rejected',
  extras?: { reviewerNotes?: string },
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'placeSubmissions', id), {
    status,
    ...(extras?.reviewerNotes != null ? { reviewerNotes: extras.reviewerNotes } : {}),
    reviewedAt: serverTimestamp(),
  })
}

/** Approve a submission: mark verified on places if linked, else create a place. */
export async function approveSubmission(submission: DocumentData & { id: string }, notes = '') {
  if (!db) throw new Error('Firebase not configured')
  const name = String(submission.name ?? submission.placeName ?? 'Untitled place')
  const category = String(submission.category ?? 'other')
  const lat = Number(submission.lat)
  const lng = Number(submission.lng)
  const address = String(submission.address ?? '')
  const features = (submission.features as string[]) ?? []

  let placeId = String(submission.placeId ?? '')
  if (placeId) {
    await updateDoc(doc(db, 'places', placeId), {
      verified: true,
      hidden: false,
      reviewerNotes: notes,
      verifiedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    })
  } else if (Number.isFinite(lat) && Number.isFinite(lng)) {
    placeId = await createPlace({
      name,
      category,
      description: String(submission.notes ?? submission.description ?? ''),
      shortDescription: '',
      phone: String(submission.phone ?? ''),
      website: String(submission.website ?? ''),
      email: String(submission.email ?? ''),
      hours: String(submission.hours ?? ''),
      features,
      tags: [],
      active: true,
      lat,
      lng,
      address,
      city: String(submission.city ?? ''),
      country: String(submission.country ?? 'Pakistan'),
      verificationStatus: 'verified',
      reviewerNotes: notes,
      createdBy: String(submission.uid ?? ''),
    })
  } else {
    throw new Error(
      'Cannot approve: submission has no linked place and invalid or missing coordinates.',
    )
  }

  await setSubmissionStatus(submission.id, 'approved', { reviewerNotes: notes })
  await writeActivityLog({
    level: 'info',
    module: 'Places',
    event: 'Submission approved',
    details: `${name} → place ${placeId}`,
  })
  return placeId
}

export async function setPlaceFlags(
  id: string,
  flags: { verified?: boolean; hidden?: boolean; category?: string },
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'places', id), {
    ...flags,
    updatedAt: serverTimestamp(),
  })
}

export type PlaceVerificationStatus = 'verified' | 'community' | 'pending'

/** Set admin verification state on an existing place. */
export async function verifyPlace(
  id: string,
  opts: {
    verificationStatus: PlaceVerificationStatus
    reviewerNotes?: string
  },
) {
  if (!db) throw new Error('Firebase not configured')
  const verified = opts.verificationStatus === 'verified'
  const communityVerified = opts.verificationStatus === 'community'
  await updateDoc(doc(db, 'places', id), {
    verified,
    communityVerified,
    hidden: false,
    ...(opts.reviewerNotes != null ? { reviewerNotes: opts.reviewerNotes } : {}),
    verifiedAt:
      verified || communityVerified ? serverTimestamp() : deleteField(),
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Places',
    event: verified
      ? 'Place verified'
      : communityVerified
        ? 'Place community verified'
        : 'Place verification cleared',
    details: id,
  })
}

export type CreatePlaceInput = {
  name: string
  category: string
  description: string
  shortDescription: string
  phone: string
  website: string
  email: string
  hours: string
  features: string[]
  tags: string[]
  active: boolean
  lat: number
  lng: number
  address: string
  city: string
  country: string
  verificationStatus: 'pending' | 'verified' | 'community'
  reviewerNotes: string
  createdBy: string
}

export async function createPlace(input: CreatePlaceInput): Promise<string> {
  if (!db) throw new Error('Firebase not configured')
  const ref = doc(collection(db, 'places'))
  const verified = input.verificationStatus === 'verified'
  const communityVerified = input.verificationStatus === 'community'
  const score = Math.min(100, 40 + input.features.length * 4)
  await setDoc(ref, {
    id: ref.id,
    name: input.name.trim(),
    category: input.category,
    description: input.description.trim() || input.shortDescription.trim(),
    shortDescription: input.shortDescription.trim(),
    phone: input.phone.trim(),
    website: input.website.trim(),
    email: input.email.trim(),
    hours: input.hours,
    features: input.features,
    tags: input.tags,
    lat: input.lat,
    lng: input.lng,
    address: input.address.trim(),
    city: input.city.trim(),
    country: input.country.trim() || 'Pakistan',
    verified,
    communityVerified,
    hidden: !input.active,
    score,
    // No fabricated user rating — only real reviews should populate this.
    rating: 0,
    ratingCount: 0,
    reviewerNotes: input.reviewerNotes.trim(),
    verifiedAt: verified || communityVerified ? serverTimestamp() : null,
    createdBy: input.createdBy,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    photoUrls: [],
    imageUrl: '',
  })
  return ref.id
}

export async function fetchPlaceReports(max = 50) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(collection(db, 'placeReports'), orderBy('createdAt', 'desc'), limit(max)),
    )
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, 'placeReports'), limit(max)))
    return mapDocs(snap)
  }
}

export async function setReportStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  // Normalize admin UI statuses to Flutter place_report enums.
  const normalized =
    status === 'inReview' || status === 'in_review'
      ? 'in_review'
      : status === 'rejected' || status === 'denied'
        ? 'dismissed'
        : status === 'pending'
          ? 'open'
          : status
  await updateDoc(doc(db, 'placeReports', id), { status: normalized })
  await writeActivityLog({
    level: 'info',
    module: 'Reports',
    event: 'Report status updated',
    details: `${id} → ${normalized}`,
    targetId: id,
  })
}

export type ReportHubSource =
  | 'place'
  | 'review'
  | 'community'
  | 'job'
  | 'provider'

export type ReportHubItem = DocumentData & {
  id: string
  source: ReportHubSource
  title: string
  subtitle: string
  status: string
  createdAt: unknown
}

/** Unified moderation queue across report-like collections (Phase 3). */
export async function fetchReportsHub(input: {
  source: ReportHubSource | 'all'
  max?: number
}): Promise<ReportHubItem[]> {
  const max = input.max ?? 100
  const want = input.source

  const mapPlace = async (): Promise<ReportHubItem[]> => {
    const rows = await fetchPlaceReports(max)
    return rows.map((r) => ({
      ...r,
      source: 'place' as const,
      title: String(r.placeName ?? r.name ?? r.category ?? 'Place report'),
      subtitle: String(r.details ?? r.reason ?? r.description ?? ''),
      status: String(r.status ?? 'open'),
      createdAt: r.createdAt,
    }))
  }

  const mapReview = async (): Promise<ReportHubItem[]> => {
    const rows = await fetchReviews(max)
    return rows
      .filter((r) => {
        const flags = Number(r.flagCount ?? 0)
        const s = String(r.status ?? 'published').toLowerCase()
        return flags >= 1 || ['hidden', 'flagged', 'reported', 'inreview'].includes(s)
      })
      .map((r) => ({
        ...r,
        source: 'review' as const,
        title: String(r.placeName ?? r.targetName ?? 'Review'),
        subtitle: String(r.comment ?? r.text ?? r.body ?? '').slice(0, 160),
        status: String(r.status ?? 'flagged'),
        createdAt: r.createdAt,
      }))
  }

  const mapCommunity = async (): Promise<ReportHubItem[]> => {
    const rows = await fetchCommunityPosts(max)
    return rows
      .filter((r) => {
        const flags = Number(r.flagCount ?? 0)
        const s = String(r.status ?? 'published').toLowerCase()
        return flags >= 1 || ['flagged', 'hidden', 'removed'].includes(s)
      })
      .map((r) => ({
        ...r,
        source: 'community' as const,
        title: String(r.title ?? r.text ?? 'Community post').slice(0, 80),
        subtitle: String(r.text ?? r.body ?? '').slice(0, 160),
        status: String(r.status ?? 'flagged'),
        createdAt: r.createdAt,
      }))
  }

  const mapJob = async (): Promise<ReportHubItem[]> => {
    const rows = await fetchJobs(max)
    return rows
      .filter((r) => {
        const s = String(r.status ?? '').toLowerCase()
        return ['pending', 'rejected', 'flagged'].includes(s)
      })
      .map((r) => ({
        ...r,
        source: 'job' as const,
        title: String(r.title ?? r.role ?? 'Job listing'),
        subtitle: String(r.company ?? r.employerName ?? r.city ?? ''),
        status: String(r.status ?? 'pending'),
        createdAt: r.createdAt,
      }))
  }

  const mapProvider = async (): Promise<ReportHubItem[]> => {
    const rows = await fetchFraudReports(max)
    return rows
      .filter((r) => {
        const t = String(r.targetType ?? '').toLowerCase()
        return !t || t.includes('provider') || t.includes('doctor') || t.includes('therapist')
      })
      .map((r) => ({
        ...r,
        source: 'provider' as const,
        title: String(r.targetId ?? r.name ?? 'Provider fraud report'),
        subtitle: String(r.reason ?? r.details ?? ''),
        status: String(r.status ?? 'open'),
        createdAt: r.createdAt,
      }))
  }

  const loaders: Record<ReportHubSource, () => Promise<ReportHubItem[]>> = {
    place: mapPlace,
    review: mapReview,
    community: mapCommunity,
    job: mapJob,
    provider: mapProvider,
  }

  if (want !== 'all') return loaders[want]()

  const chunks = await Promise.all(Object.values(loaders).map((fn) => fn()))
  return chunks
    .flat()
    .sort((a, b) => {
      const ta = createdAtMs(a.createdAt)
      const tb = createdAtMs(b.createdAt)
      return tb - ta
    })
    .slice(0, max)
}

function createdAtMs(value: unknown): number {
  if (!value) return 0
  if (typeof value === 'object' && value !== null && 'toDate' in value) {
    return (value as { toDate: () => Date }).toDate().getTime()
  }
  if (typeof value === 'object' && value !== null && 'seconds' in value) {
    return (value as { seconds: number }).seconds * 1000
  }
  if (typeof value === 'string') {
    const t = Date.parse(value)
    return Number.isNaN(t) ? 0 : t
  }
  return 0
}

export async function resolveHubItem(
  source: ReportHubSource,
  id: string,
  status: string,
) {
  switch (source) {
    case 'place':
      await setReportStatus(id, status)
      break
    case 'review':
      await setReviewStatus(id, status)
      break
    case 'community':
      await setCommunityPostStatus(
        id,
        status as 'published' | 'hidden' | 'removed' | 'flagged',
      )
      break
    case 'job':
      await setJobStatus(
        id,
        status as 'pending' | 'approved' | 'rejected' | 'live' | 'paused',
      )
      break
    case 'provider':
      await setFraudReportStatus(id, status)
      break
  }
}

export async function fetchReviews(max = 50) {
  if (!db) return []
  const snap = await getDocs(query(collection(db, 'reviews'), limit(max)))
  return mapDocs(snap)
}

export async function setReviewStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'reviews', id), { status })
}

export async function fetchUsers(max = 100) {
  if (!db) return []
  const snap = await getDocs(query(collection(db, 'users'), limit(max)))
  return mapDocs(snap)
}

export type UsersPageParams = {
  pageSize?: number
  cursor?: PageCursor
  /** Firestore accountStatus equality when not searching. */
  accountStatus?: string | null
}

export async function fetchUsersPage(params: UsersPageParams = {}) {
  const equality: Record<string, string> = {}
  if (params.accountStatus) equality.accountStatus = params.accountStatus
  return fetchCollectionPage({
    collectionName: 'users',
    pageSize: params.pageSize ?? 25,
    cursor: params.cursor ?? null,
    orderField: 'createdAt',
    equality,
  })
}

export async function fetchUser(uid: string) {
  if (!db) return null
  const snap = await getDoc(doc(db, 'users', uid))
  if (!snap.exists()) return null
  return { id: snap.id, ...snap.data() } as DocumentData & { id: string }
}

export async function setUserStatus(uid: string, accountStatus: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'users', uid), { accountStatus })
  await writeActivityLog({
    level: 'info',
    module: 'Users',
    event: 'User status updated',
    details: `${uid} → ${accountStatus}`,
    targetId: uid,
  })
}

/** Admin-triggered password reset email (Firebase Auth client template). */
export async function requestUserPasswordReset(uid: string) {
  if (!auth) throw new Error('Firebase Auth not configured')
  const user = await fetchUser(uid)
  const email = String(
    user?.email ??
      (user?.contact as { email?: string } | undefined)?.email ??
      '',
  ).trim()
  if (!email) throw new Error('User has no email on file')
  await sendPasswordResetEmail(auth, email)
  await writeActivityLog({
    level: 'warning',
    module: 'Users',
    event: 'Password reset email sent',
    details: `${uid} → ${email}`,
    targetId: uid,
  })
}

/** Per-user activity from adminActivityLogs (targetId or details match). */
export async function fetchUserActivityLogs(uid: string, max = 100) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(
        collection(db, 'adminActivityLogs'),
        where('targetId', '==', uid),
        orderBy('createdAt', 'desc'),
        limit(max),
      ),
    )
    return mapDocs(snap)
  } catch {
    const all = await fetchActivityLogs(200)
    return all
      .filter(
        (r) =>
          String(r.targetId ?? '') === uid ||
          String(r.details ?? '').includes(uid) ||
          String(r.actorUid ?? '') === uid,
      )
      .slice(0, max)
  }
}

export async function fetchUserReviews(uid: string, max = 50) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(
        collection(db, 'reviews'),
        where('uid', '==', uid),
        limit(max),
      ),
    )
    return mapDocs(snap)
  } catch {
    const all = await fetchReviews(100)
    return all.filter(
      (r) =>
        String(r.uid ?? r.userId ?? r.authorId ?? '') === uid,
    )
  }
}

export async function fetchUserAppointments(uid: string, max = 50) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(
        collection(db, 'appointments'),
        where('patientUid', '==', uid),
        limit(max),
      ),
    )
    return mapDocs(snap)
  } catch {
    const all = await fetchAppointments(100)
    return all.filter((r) => {
      const ids = [
        r.patientUid,
        r.uid,
        r.userId,
        r.clientUid,
        r.providerUid,
      ].map((x) => String(x ?? ''))
      return ids.includes(uid)
    })
  }
}

export async function fetchUserReports(uid: string, max = 50) {
  if (!db) return []
  const [place, fraud] = await Promise.all([
    fetchPlaceReports(100),
    fetchCollection('fraudReports', 100, 'createdAt'),
  ])
  return [...place, ...fraud]
    .filter(
      (r) =>
        String(r.uid ?? r.userId ?? r.reporterUid ?? r.reportedBy ?? '') ===
        uid,
    )
    .slice(0, max)
}

export async function fetchProviders(max = 300) {
  if (!db) return []
  const snap = await getDocs(query(collection(db, 'providers'), limit(max)))
  return mapDocs(snap)
}

export type ProvidersPageParams = {
  pageSize?: number
  cursor?: PageCursor
  verified?: boolean | null
  category?: string | null
}

export async function fetchProvidersPage(params: ProvidersPageParams = {}) {
  const equality: Record<string, string | boolean> = {}
  if (params.verified != null) equality.verified = params.verified
  if (params.category) equality.category = params.category
  return fetchCollectionPage({
    collectionName: 'providers',
    pageSize: params.pageSize ?? 25,
    cursor: params.cursor ?? null,
    orderField: 'createdAt',
    equality,
  })
}

export async function fetchProvider(id: string) {
  if (!db) return null
  const snap = await getDoc(doc(db, 'providers', id))
  if (!snap.exists()) return null
  return { id: snap.id, ...snap.data() } as DocumentData & { id: string }
}

export async function setProviderFlags(
  id: string,
  flags: { verified?: boolean; hidden?: boolean; availableNow?: boolean },
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'providers', id), flags)
  await writeActivityLog({
    level: 'info',
    module: 'Providers',
    event: 'Provider flags updated',
    details: `${id} → ${JSON.stringify(flags)}`,
  })
}

export type ProviderDocumentType =
  | 'photo'
  | 'id_card'
  | 'education'
  | 'experience'
  | 'license'
  | 'other'

export type ProviderDocument = {
  id: string
  type: ProviderDocumentType
  title: string
  url: string
  fileName: string
  contentType: string
}

export const PROVIDER_DOCUMENT_TYPES: {
  value: ProviderDocumentType
  label: string
  accept: string
  imagesOnly?: boolean
  /** Allow selecting multiple files in one upload. */
  multiple?: boolean
}[] = [
  { value: 'photo', label: 'User Photo', accept: 'image/*', imagesOnly: true },
  { value: 'id_card', label: 'ID Card', accept: 'image/*,application/pdf' },
  {
    value: 'education',
    label: 'Educational Documents',
    accept: 'image/*,application/pdf',
    multiple: true,
  },
  {
    value: 'experience',
    label: 'Experience Documents',
    accept: 'image/*,application/pdf',
    multiple: true,
  },
  { value: 'license', label: 'License / Certification', accept: 'image/*,application/pdf', multiple: true },
  { value: 'other', label: 'Other Documents', accept: 'image/*,application/pdf', multiple: true },
]

export type CreateProviderInput = {
  name: string
  title: string
  category: string
  specialty: string
  bio: string
  city: string
  photoUrl: string
  priceFrom: number
  currency: string
  languages: string[]
  services: string[]
  skills: string[]
  accessibilityTags: string[]
  yearsExperience: number
  verified: boolean
  availableNow: boolean
  assistanceType: string
  availabilitySlots: string[]
  ownerUid: string
  documents?: ProviderDocument[]
}

function evidenceFromDocuments(documents: ProviderDocument[]) {
  return documents
    .filter((d) => d.type !== 'photo' && d.url)
    .map((d) => ({
      title: d.title || PROVIDER_DOCUMENT_TYPES.find((t) => t.value === d.type)?.label || 'Document',
      url: d.url,
    }))
}

export async function createProvider(input: CreateProviderInput): Promise<string> {
  if (!db) throw new Error('Firebase not configured')
  const name = input.name.trim()
  if (!name) throw new Error('Name is required')
  const specialty = input.specialty.trim()
  if (!specialty) throw new Error('Specialty is required')
  const category = input.category.trim()
  if (!category) throw new Error('Category is required')

  const documents = (input.documents ?? []).filter((d) => d.url.trim())
  const photoFromDocs = documents.find((d) => d.type === 'photo')?.url?.trim() ?? ''
  const photoUrl = input.photoUrl.trim() || photoFromDocs

  const ref = doc(collection(db, 'providers'))
  await setDoc(ref, {
    name,
    title: input.title.trim(),
    category,
    specialty,
    bio: input.bio.trim(),
    city: input.city.trim(),
    photoUrl,
    priceFrom: Math.max(0, Math.round(input.priceFrom) || 0),
    currency: input.currency.trim() || '$',
    languages: input.languages,
    services: input.services,
    skills: input.skills,
    accessibilityTags: input.accessibilityTags,
    yearsExperience: Math.max(0, Math.round(input.yearsExperience) || 0),
    verified: input.verified === true,
    availableNow: input.availableNow === true,
    hidden: false,
    assistanceType: input.assistanceType.trim(),
    availabilitySlots: input.availabilitySlots,
    ownerUid: input.ownerUid.trim(),
    rating: 0,
    reviewCount: 0,
    checklist: {},
    documents,
    evidence: evidenceFromDocuments(documents),
    createdAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Providers',
    event: 'Provider created',
    details: `${name} (${category}) → ${ref.id}`,
  })
  return ref.id
}

/** Upload a provider document (image or PDF). Use providerId when editing an existing profile. */
export async function uploadProviderDocument(input: {
  file: File
  type: ProviderDocumentType
  providerId?: string
}) {
  if (!storage) throw new Error('Firebase Storage not configured')
  if (!auth?.currentUser) throw new Error('Sign in required to upload')
  const file = input.file
  const ext =
    file.name.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '') || ''
  const inferredType =
    file.type ||
    (ext === 'pdf'
      ? 'application/pdf'
      : ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'heif'].includes(ext)
        ? ext === 'jpg' || ext === 'jpeg'
          ? 'image/jpeg'
          : `image/${ext === 'heif' ? 'heic' : ext}`
        : '')
  const isImage = inferredType.startsWith('image/')
  const isPdf = inferredType === 'application/pdf'
  if (!isImage && !isPdf) {
    throw new Error(`“${file.name}” must be an image or PDF`)
  }
  if (input.type === 'photo' && !isImage) throw new Error('User photo must be an image')
  if (file.size > 15 * 1024 * 1024) throw new Error('File must be under 15 MB')

  const safeType = input.type.replace(/[^a-z_]/g, '') || 'other'
  const stamp = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
  const fileName = `${safeType}_${stamp}.${ext || (isPdf ? 'pdf' : 'jpg')}`
  const path = input.providerId
    ? `providers/${input.providerId}/documents/${fileName}`
    : `providerDocs/${auth.currentUser.uid}/${fileName}`

  const contentType = inferredType || (isPdf ? 'application/pdf' : 'image/jpeg')
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, file, { contentType })
  const url = await getDownloadURL(storageRef)
  const label = PROVIDER_DOCUMENT_TYPES.find((t) => t.value === input.type)?.label ?? 'Document'
  return {
    id: `${safeType}_${stamp}`,
    type: input.type,
    title: label,
    url,
    fileName: file.name,
    contentType,
  } satisfies ProviderDocument
}

export async function saveProviderDocuments(input: {
  providerId: string
  documents: ProviderDocument[]
  photoUrl?: string
}) {
  if (!db) throw new Error('Firebase not configured')
  const documents = input.documents.filter((d) => d.url.trim())
  const photoFromDocs = documents.find((d) => d.type === 'photo')?.url?.trim()
  const patch: Record<string, unknown> = {
    documents,
    evidence: evidenceFromDocuments(documents),
  }
  if (input.photoUrl !== undefined) {
    patch.photoUrl = input.photoUrl.trim()
  } else if (photoFromDocs) {
    patch.photoUrl = photoFromDocs
  }
  await updateDoc(doc(db, 'providers', input.providerId), patch)
  await writeActivityLog({
    level: 'info',
    module: 'Providers',
    event: 'Provider documents updated',
    details: `${input.providerId} → ${documents.length} files`,
  })
}

export async function saveAccessibilityFeatures(features: AccessibilityFeatureDef[]) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'platformConfig', 'settings'), {
    accessibilityFeatures: features,
  })
  await writeActivityLog({
    level: 'info',
    module: 'System',
    event: 'Accessibility features catalog updated',
    details: `${features.length} features saved`,
  })
}

export async function saveHomeHeroSlides(slides: HomeHeroSlide[]) {
  if (!db) throw new Error('Firebase not configured')
  const normalized = slides
    .map((s, i) => ({
      id: s.id.trim() || `slide_${i}`,
      imageUrl: s.imageUrl.trim(),
      aspectRatio: s.aspectRatio > 0 ? s.aspectRatio : 1024 / 415,
      ctaLabel: s.ctaLabel.trim() || 'Learn more',
      action: s.action.trim() || 'explore_map',
      active: s.active !== false,
      sortOrder: typeof s.sortOrder === 'number' ? s.sortOrder : i,
    }))
    .sort((a, b) => a.sortOrder - b.sortOrder)
  await updateDoc(doc(db, 'platformConfig', 'settings'), {
    homeHeroSlides: normalized,
  })
  await writeActivityLog({
    level: 'info',
    module: 'System',
    event: 'Home hero slides updated',
    details: `${normalized.filter((s) => s.active).length} active of ${normalized.length}`,
  })
}

/** Upload a home hero image to Storage; returns a public download URL. */
export async function uploadHomeHeroImage(file: File, slideId: string) {
  if (!storage) throw new Error('Firebase Storage not configured')
  if (!file.type.startsWith('image/')) throw new Error('File must be an image')
  if (file.size > 8 * 1024 * 1024) throw new Error('Image must be under 8 MB')
  const safeId = slideId.replace(/[^a-zA-Z0-9_-]/g, '_') || 'slide'
  const ext = file.name.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '') || 'jpg'
  const path = `homeHero/${safeId}_${Date.now()}.${ext}`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, file, { contentType: file.type })
  return getDownloadURL(storageRef)
}

export type BroadcastStatus = 'draft' | 'scheduled' | 'sending' | 'sent' | 'failed'

export type BroadcastInput = {
  title: string
  body: string
  type: string
  audience: 'all' | 'active'
  channels: string[]
  status?: BroadcastStatus
}

export async function fetchBroadcasts(max = 100) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(collection(db, 'adminBroadcasts'), orderBy('createdAt', 'desc'), limit(max)),
    )
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, 'adminBroadcasts'), limit(max)))
    return mapDocs(snap)
  }
}

export async function createBroadcast(
  input: BroadcastInput,
  createdBy: string,
): Promise<string> {
  if (!db) throw new Error('Firebase not configured')
  const ref = doc(collection(db, 'adminBroadcasts'))
  await setDoc(ref, {
    id: ref.id,
    title: input.title.trim(),
    body: input.body.trim(),
    type: input.type || 'general',
    audience: input.audience,
    channels: input.channels,
    status: input.status ?? 'draft',
    recipientCount: 0,
    deliveredCount: 0,
    createdBy,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    sentAt: null,
  })
  await writeActivityLog({
    level: 'info',
    module: 'Notifications',
    event: 'Broadcast draft created',
    details: input.title.trim(),
    actorUid: createdBy,
  })
  return ref.id
}

/** Fan-out in-app notifications to users (capped) and mark broadcast sent. */
export async function sendBroadcast(broadcastId: string, createdBy: string) {
  if (!db) throw new Error('Firebase not configured')
  const bRef = doc(db, 'adminBroadcasts', broadcastId)
  const bSnap = await getDoc(bRef)
  if (!bSnap.exists()) throw new Error('Broadcast not found')
  const b = bSnap.data()
  await updateDoc(bRef, { status: 'sending', updatedAt: serverTimestamp() })

  const users = await fetchUsers(200)
  let delivered = 0
  const title = String(b.title ?? 'Ability Link')
  const body = String(b.body ?? '')
  const type = String(b.type ?? 'general')
  const channels = (b.channels as string[]) ?? ['inApp']

  for (const u of users) {
    try {
      const nRef = doc(collection(db, 'notifications'))
      await setDoc(nRef, {
        uid: u.id,
        createdBy,
        type,
        title,
        body,
        relatedId: broadcastId,
        read: false,
        channels,
        createdAt: serverTimestamp(),
      })
      delivered += 1
    } catch {
      /* skip individual failures */
    }
  }

  await updateDoc(bRef, {
    status: delivered > 0 ? 'sent' : 'failed',
    recipientCount: users.length,
    deliveredCount: delivered,
    sentAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: delivered > 0 ? 'info' : 'error',
    module: 'Notifications',
    event: delivered > 0 ? 'Broadcast sent' : 'Broadcast failed',
    details: `${title} → ${delivered}/${users.length} users`,
    actorUid: createdBy,
  })
  return { recipients: users.length, delivered }
}

export async function setBroadcastStatus(id: string, status: BroadcastStatus) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'adminBroadcasts', id), {
    status,
    updatedAt: serverTimestamp(),
  })
}

export type ActivityLogInput = {
  level: 'info' | 'warning' | 'error' | 'critical'
  module: string
  event: string
  details?: string
  actorUid?: string
  /** Entity the action targets (user/provider/exercise id). */
  targetId?: string
  ip?: string
}

export async function writeActivityLog(input: ActivityLogInput) {
  if (!db || !auth?.currentUser) return
  try {
    const actorUid = input.actorUid || auth.currentUser.uid
    const ref = doc(collection(db, 'adminActivityLogs'))
    await setDoc(ref, {
      id: ref.id,
      level: input.level,
      module: input.module,
      event: input.event,
      details: input.details ?? '',
      actorUid,
      targetId: input.targetId ?? '',
      user: auth.currentUser.email || actorUid,
      ip: input.ip ?? '—',
      createdAt: serverTimestamp(),
    })
  } catch {
    /* never block primary actions on logging */
  }
}

export async function fetchActivityLogs(max = 200) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(collection(db, 'adminActivityLogs'), orderBy('createdAt', 'desc'), limit(max)),
    )
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, 'adminActivityLogs'), limit(max)))
    return mapDocs(snap)
  }
}

export async function clearActivityLogs() {
  if (!db) throw new Error('Firebase not configured')
  // Client SDK has no bulk delete; mark-clear is not supported — fetch+delete limited batch.
  const rows = await fetchActivityLogs(100)
  await Promise.all(rows.map((r) => deleteDoc(doc(db!, 'adminActivityLogs', r.id))))
  await writeActivityLog({
    level: 'warning',
    module: 'System',
    event: 'Activity logs cleared',
    details: `Deleted up to ${rows.length} recent log entries`,
  })
}

// ─── Ops / gap-analysis collections ─────────────────────────────────────────

async function fetchCollection(name: string, max = 200, orderField?: string) {
  if (!db) return []
  try {
    const snap = orderField
      ? await getDocs(
          query(collection(db, name), orderBy(orderField, 'desc'), limit(max)),
        )
      : await getDocs(query(collection(db, name), limit(max)))
    return mapDocs(snap)
  } catch {
    const snap = await getDocs(query(collection(db, name), limit(max)))
    return mapDocs(snap)
  }
}

export async function fetchSosAlerts(max = 100) {
  return fetchCollection('sosAlerts', max, 'createdAt')
}

export async function setSosAlertStatus(
  id: string,
  status: 'open' | 'acknowledged' | 'resolved' | 'cancelled',
  note = '',
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'sosAlerts', id), {
    status,
    opsNote: note,
    reviewedBy: auth?.currentUser?.uid ?? '',
    reviewedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: status === 'resolved' ? 'info' : 'warning',
    module: 'Emergency',
    event: `SOS ${status}`,
    details: `${id}${note ? ` — ${note}` : ''}`,
  })
}

export async function fetchEmergencyResources(max = 200) {
  return fetchCollection('emergencyResources', max)
}

export async function upsertEmergencyResource(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'emergencyResources', id)
    : doc(collection(db, 'emergencyResources'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp() }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Emergency',
    event: id ? 'Resource updated' : 'Resource created',
    details: String(data.name ?? refDoc.id),
  })
  return refDoc.id
}

export async function fetchAppointments(max = 200) {
  return fetchCollection('appointments', max, 'createdAt')
}

export async function setAppointmentStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'appointments', id), {
    status,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Appointments',
    event: `Appointment ${status}`,
    details: id,
  })
}

export type VerificationStatus =
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'needsInfo'

export async function fetchVerificationRequests(max = 100) {
  return fetchCollection('verificationRequests', max, 'createdAt')
}

export async function setVerificationRequestStatus(
  id: string,
  status: VerificationStatus,
) {
  return reviewVerificationRequest({ id, status })
}

export async function reviewVerificationRequest(input: {
  id: string
  status: VerificationStatus
  adminNote?: string
  /** When approving/rejecting, flip providers.verified if targetId resolves. */
  syncProviderVerified?: boolean
}) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  const reqRef = doc(db, 'verificationRequests', input.id)
  const reqSnap = await getDoc(reqRef)
  if (!reqSnap.exists()) throw new Error('Verification request not found')
  const req = reqSnap.data()
  const targetId = String(req.targetId ?? '')
  const patch: Record<string, unknown> = {
    status: input.status,
    reviewedAt: serverTimestamp(),
    reviewedBy: actorUid,
    updatedAt: serverTimestamp(),
  }
  if (input.adminNote != null) patch.adminNote = input.adminNote.trim()

  await updateDoc(reqRef, patch)

  const sync =
    input.syncProviderVerified !== false &&
    targetId &&
    (input.status === 'approved' || input.status === 'rejected')
  if (sync) {
    try {
      await updateDoc(doc(db, 'providers', targetId), {
        verified: input.status === 'approved',
        verificationStatus: input.status,
        updatedAt: serverTimestamp(),
      })
    } catch {
      /* target may be doctors/staff — try common collections */
      for (const col of ['doctors', 'staff', 'therapists', 'caregivers'] as const) {
        try {
          await updateDoc(doc(db, col, targetId), {
            verified: input.status === 'approved',
            verificationStatus: input.status,
            updatedAt: serverTimestamp(),
          })
          break
        } catch {
          /* try next */
        }
      }
    }
  }

  await writeActivityLog({
    level: input.status === 'rejected' ? 'warning' : 'info',
    module: 'Verification',
    event: `Provider verification ${input.status}`,
    details: `${input.id}${input.adminNote ? ` — ${input.adminNote}` : ''}`,
    targetId: targetId || input.id,
  })
}

export async function fetchProviderVerificationHistory(
  providerId: string,
  max = 50,
) {
  if (!db) return []
  try {
    const snap = await getDocs(
      query(
        collection(db, 'verificationRequests'),
        where('targetId', '==', providerId),
        orderBy('createdAt', 'desc'),
        limit(max),
      ),
    )
    return mapDocs(snap)
  } catch {
    const all = await fetchVerificationRequests(100)
    return all.filter((r) => String(r.targetId ?? '') === providerId)
  }
}

export type RehabContentStatus = 'draft' | 'review' | 'published' | 'archived'

export type RehabProgramWeek = {
  label: string
  exerciseIds: string[]
}

export async function fetchRehabExercises(max = 200) {
  return fetchCollection('rehabExercises', max)
}

export async function fetchRehabPrograms(max = 100) {
  return fetchCollection('rehabPrograms', max)
}

export async function fetchRehabArticles(max = 100) {
  return fetchCollection('rehabArticles', max, 'updatedAt')
}

export async function fetchExerciseCategories(max = 100) {
  return fetchCollection('exerciseCategories', max, 'sortOrder')
}

export async function fetchBodyAreas(max = 100) {
  return fetchCollection('bodyAreas', max, 'sortOrder')
}

export async function fetchConditions(max = 200) {
  return fetchCollection('conditions', max, 'name')
}

export async function upsertTaxonomyDoc(
  collectionName:
    | 'exerciseCategories'
    | 'bodyAreas'
    | 'conditions',
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, collectionName, id)
    : doc(collection(db, collectionName))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp() }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Rehab CMS',
    event: `${collectionName} ${id ? 'updated' : 'created'}`,
    details: String(data.name ?? refDoc.id),
    targetId: refDoc.id,
  })
  return refDoc.id
}

/** Upload rehab media; returns download URL. Path under rehab/. */
export async function uploadRehabAsset(
  file: File,
  storagePath: string,
): Promise<string> {
  if (!storage) throw new Error('Firebase Storage not configured')
  const isImage = file.type.startsWith('image/')
  const isVideo = file.type.startsWith('video/')
  if (!isImage && !isVideo) throw new Error('File must be an image or video')
  const max = isVideo ? 80 * 1024 * 1024 : 8 * 1024 * 1024
  if (file.size > max) {
    throw new Error(isVideo ? 'Video must be under 80 MB' : 'Image must be under 8 MB')
  }
  const storageRef = ref(storage, storagePath.replace(/^\/+/, ''))
  await uploadBytes(storageRef, file, { contentType: file.type })
  return getDownloadURL(storageRef)
}

function normalizeRehabStatus(
  status: unknown,
  active?: unknown,
): RehabContentStatus {
  const s = String(status ?? '').toLowerCase()
  if (s === 'draft' || s === 'review' || s === 'published' || s === 'archived') {
    return s
  }
  if (active === false) return 'archived'
  if (active === true) return 'published'
  return 'draft'
}

export async function upsertRehabExercise(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const status = normalizeRehabStatus(data.status, data.active)
  const actorUid = auth?.currentUser?.uid ?? ''
  const refDoc = id
    ? doc(db, 'rehabExercises', id)
    : doc(collection(db, 'rehabExercises'))
  const payload: Record<string, unknown> = {
    ...data,
    status,
    // Mobile still reads `active` — keep in sync with publish gate.
    active: status === 'published',
    updatedAt: serverTimestamp(),
    ...(id ? {} : { createdAt: serverTimestamp(), authoredBy: actorUid }),
  }
  if (status === 'published' && !data.reviewedAt) {
    payload.reviewedAt = serverTimestamp()
    payload.reviewedBy = actorUid
  }
  await setDoc(refDoc, payload, { merge: true })
  await writeActivityLog({
    level: 'info',
    module: 'Tele-Rehab',
    event: id ? 'Exercise updated' : 'Exercise created',
    details: `${String(data.title ?? data.name ?? refDoc.id)} [${status}]`,
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function setRehabExerciseStatus(
  id: string,
  status: RehabContentStatus,
) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  const patch: Record<string, unknown> = {
    status,
    active: status === 'published',
    updatedAt: serverTimestamp(),
  }
  if (status === 'published' || status === 'review') {
    patch.reviewedAt = serverTimestamp()
    patch.reviewedBy = actorUid
  }
  await updateDoc(doc(db, 'rehabExercises', id), patch)
  await writeActivityLog({
    level: 'info',
    module: 'Tele-Rehab',
    event: `Exercise → ${status}`,
    details: id,
    targetId: id,
  })
}

export async function setRehabExerciseActive(id: string, active: boolean) {
  return setRehabExerciseStatus(id, active ? 'published' : 'archived')
}

export async function upsertRehabProgram(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const status = normalizeRehabStatus(data.status, data.active)
  const weeks = Array.isArray(data.weeks) ? (data.weeks as RehabProgramWeek[]) : null
  const flatIds =
    weeks != null
      ? weeks.flatMap((w) => w.exerciseIds ?? [])
      : Array.isArray(data.exerciseIds)
        ? (data.exerciseIds as string[])
        : []
  const weekCount =
    weeks != null
      ? weeks.length
      : typeof data.weekCount === 'number'
        ? data.weekCount
        : typeof data.weeks === 'number'
          ? data.weeks
          : 0
  const actorUid = auth?.currentUser?.uid ?? ''
  const refDoc = id
    ? doc(db, 'rehabPrograms', id)
    : doc(collection(db, 'rehabPrograms'))
  await setDoc(
    refDoc,
    {
      ...data,
      status,
      active: status === 'published',
      exerciseIds: flatIds,
      // Keep numeric weeks for mobile RehabProgram.weeks while also storing structured weeks[].
      ...(weeks != null
        ? { programWeeks: weeks, weeks: weekCount || weeks.length }
        : {}),
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), authoredBy: actorUid }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Tele-Rehab',
    event: id ? 'Program updated' : 'Program created',
    details: `${String(data.title ?? data.name ?? refDoc.id)} [${status}]`,
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function setRehabProgramStatus(
  id: string,
  status: RehabContentStatus,
) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  await updateDoc(doc(db, 'rehabPrograms', id), {
    status,
    active: status === 'published',
    reviewedAt: serverTimestamp(),
    reviewedBy: actorUid,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Tele-Rehab',
    event: `Program → ${status}`,
    details: id,
    targetId: id,
  })
}

export async function upsertRehabArticle(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const status = normalizeRehabStatus(data.status, data.active)
  const actorUid = auth?.currentUser?.uid ?? ''
  const refDoc = id
    ? doc(db, 'rehabArticles', id)
    : doc(collection(db, 'rehabArticles'))
  await setDoc(
    refDoc,
    {
      ...data,
      status,
      locale: data.locale ?? 'en',
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), authoredBy: actorUid }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Rehab CMS',
    event: id ? 'Article updated' : 'Article created',
    details: `${String(data.title ?? refDoc.id)} [${status}]`,
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function setRehabArticleStatus(
  id: string,
  status: RehabContentStatus,
) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  await updateDoc(doc(db, 'rehabArticles', id), {
    status,
    reviewedAt: serverTimestamp(),
    reviewedBy: actorUid,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Rehab CMS',
    event: `Article → ${status}`,
    details: id,
    targetId: id,
  })
}

export async function fetchCommunityPosts(max = 100) {
  return fetchCollection('communityPosts', max, 'createdAt')
}

export async function setCommunityPostStatus(
  id: string,
  status: 'published' | 'hidden' | 'removed' | 'flagged',
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'communityPosts', id), {
    status,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'warning',
    module: 'Community',
    event: `Post ${status}`,
    details: id,
  })
}

export async function fetchCommunityGroups(max = 100) {
  return fetchCollection('communityGroups', max)
}

export async function fetchCommunityEvents(max = 100) {
  return fetchCollection('communityEvents', max, 'createdAt')
}

export async function upsertCommunityGroup(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'communityGroups', id)
    : doc(collection(db, 'communityGroups'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id
        ? {}
        : {
            createdAt: serverTimestamp(),
            createdBy: auth?.currentUser?.uid ?? '',
            memberUids: [],
            memberCount: 0,
            official: true,
          }),
    },
    { merge: true },
  )
  return refDoc.id
}

export async function setCommunityGroupFeatured(id: string, featured: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'communityGroups', id), {
    featured,
    official: featured,
    updatedAt: serverTimestamp(),
  })
}

export async function upsertCommunityEvent(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'communityEvents', id)
    : doc(collection(db, 'communityEvents'))
  await setDoc(
    refDoc,
    {
      ...data,
      uid: auth?.currentUser?.uid ?? '',
      official: true,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), rsvpUids: [], rsvpCount: 0 }),
    },
    { merge: true },
  )
  return refDoc.id
}

export async function setCommunityEventFeatured(id: string, featured: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'communityEvents', id), {
    featured,
    official: featured,
    updatedAt: serverTimestamp(),
  })
}

export async function fetchTravelBookings(max = 150) {
  return fetchCollection('travelBookings', max, 'createdAt')
}

export async function fetchAssistanceBookings(max = 150) {
  return fetchCollection('assistanceBookings', max, 'createdAt')
}

export async function setTravelBookingStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'travelBookings', id), {
    status,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Travel',
    event: `Booking ${status}`,
    details: id,
  })
}

export async function setAssistanceBookingStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'assistanceBookings', id), {
    status,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Assistance',
    event: `Booking ${status}`,
    details: id,
  })
}

export async function fetchJobs(max = 150) {
  return fetchCollection('jobs', max, 'createdAt')
}

export async function fetchEmployers(max = 100) {
  return fetchCollection('employers', max)
}

export async function setJobStatus(
  id: string,
  status: 'pending' | 'approved' | 'rejected' | 'live' | 'paused',
) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'jobs', id), {
    status,
    reviewStatus: status,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Jobs',
    event: `Job ${status}`,
    details: id,
  })
}

export async function setEmployerVerified(id: string, verified: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'employers', id), {
    verified,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Jobs',
    event: verified ? 'Employer verified' : 'Employer unverified',
    details: id,
  })
}

export async function fetchBenefitSchemes(max = 150) {
  return fetchCollection('benefitSchemes', max)
}

export async function fetchBenefitApplications(max = 100) {
  return fetchCollection('benefitApplications', max, 'createdAt')
}

export async function upsertBenefitScheme(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'benefitSchemes', id)
    : doc(collection(db, 'benefitSchemes'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp() }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Benefits',
    event: id ? 'Scheme updated' : 'Scheme created',
    details: String(data.title ?? data.name ?? refDoc.id),
  })
  return refDoc.id
}

export async function setBenefitSchemeActive(id: string, active: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'benefitSchemes', id), {
    active,
    updatedAt: serverTimestamp(),
  })
}

// ── Rehab Education (Tele-Rehab Education hub + modules) ──

export async function fetchRehabEducationHubTopics(max = 50) {
  return fetchCollection('rehabEducationHubTopics', max)
}

export async function fetchRehabEducationHubRecommended(max = 50) {
  return fetchCollection('rehabEducationHubRecommended', max)
}

export async function fetchRehabEducationModules(max = 50) {
  return fetchCollection('rehabEducationModules', max)
}

export async function upsertRehabEducationHubTopic(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'rehabEducationHubTopics', id)
    : doc(collection(db, 'rehabEducationHubTopics'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), active: true }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Rehab-Education',
    event: id ? 'Hub topic updated' : 'Hub topic created',
    details: String(data.title ?? refDoc.id),
  })
  return refDoc.id
}

export async function setRehabEducationHubTopicActive(id: string, active: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'rehabEducationHubTopics', id), {
    active,
    updatedAt: serverTimestamp(),
  })
}

export async function upsertRehabEducationHubRecommended(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'rehabEducationHubRecommended', id)
    : doc(collection(db, 'rehabEducationHubRecommended'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), active: true }),
    },
    { merge: true },
  )
  return refDoc.id
}

export async function setRehabEducationHubRecommendedActive(id: string, active: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'rehabEducationHubRecommended', id), {
    active,
    updatedAt: serverTimestamp(),
  })
}

export async function upsertRehabEducationModule(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'rehabEducationModules', id)
    : doc(collection(db, 'rehabEducationModules'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), active: true }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Rehab-Education',
    event: id ? 'Module updated' : 'Module created',
    details: String(data.title ?? data.moduleKey ?? refDoc.id),
  })
  return refDoc.id
}

export async function setRehabEducationModuleActive(id: string, active: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'rehabEducationModules', id), {
    active,
    updatedAt: serverTimestamp(),
  })
}

// ── Education marketplace (schools, scholarships, courses) ──

export async function fetchEducationProgramsAdmin(max = 200) {
  return fetchCollection('educationPrograms', max)
}

export async function fetchEducationInstitutionsAdmin(max = 100) {
  return fetchCollection('educationInstitutions', max)
}

export async function upsertEducationProgramAdmin(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'educationPrograms', id)
    : doc(collection(db, 'educationPrograms'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp() }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Education',
    event: id ? 'Program updated' : 'Program created',
    details: String(data.name ?? data.title ?? refDoc.id),
  })
  return refDoc.id
}

export async function setEducationProgramVerified(id: string, verified: boolean) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'educationPrograms', id), {
    verified,
    updatedAt: serverTimestamp(),
  })
}

// ── Trust & Safety ──

export async function fetchFraudReports(max = 200) {
  return fetchCollection('fraudReports', max, 'createdAt')
}

export async function setFraudReportStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'fraudReports', id), { status, updatedAt: serverTimestamp() })
  await writeActivityLog({ level: 'warning', module: 'Trust', event: `Fraud report ${status}`, details: id })
}

export async function fetchBarrierAlerts(max = 200) {
  return fetchCollection('barrierAlerts', max, 'createdAt')
}

export async function setBarrierAlertStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'barrierAlerts', id), { status, updatedAt: serverTimestamp() })
  await writeActivityLog({ level: 'info', module: 'Trust', event: `Barrier alert ${status}`, details: id })
}

// ── AI oversight ──

export async function fetchAiOversight(max = 200) {
  return fetchCollection('aiOversight', max, 'createdAt')
}

export async function setAiOversightStatus(id: string, status: string, reviewerUid: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'aiOversight', id), {
    status,
    reviewerUid,
    reviewedAt: serverTimestamp(),
  })
  await writeActivityLog({ level: 'info', module: 'AI', event: `Oversight ${status}`, details: id })
}

export async function fetchAssistantReports(max = 200) {
  return fetchCollection('assistantReports', max, 'createdAt')
}

export async function setAssistantReportStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'assistantReports', id), { status, updatedAt: serverTimestamp() })
  await writeActivityLog({ level: 'warning', module: 'AI', event: `Assistant report ${status}`, details: id })
}

// ── Billing ──

export async function fetchBillingPlans(max = 50) {
  return fetchCollection('billingPlans', max)
}

export async function upsertBillingPlan(id: string | null, data: Record<string, unknown>) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id ? doc(db, 'billingPlans', id) : doc(collection(db, 'billingPlans'))
  await setDoc(refDoc, { ...data, updatedAt: serverTimestamp(), ...(id ? {} : { createdAt: serverTimestamp() }) }, { merge: true })
  return refDoc.id
}

export async function fetchSubscriptions(max = 200) {
  return fetchCollection('subscriptions', max, 'updatedAt')
}

export async function fetchInvoices(max = 200) {
  return fetchCollection('invoices', max, 'createdAt')
}

export async function setInvoiceStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  const patch: Record<string, unknown> = { status, updatedAt: serverTimestamp() }
  if (status === 'paid') patch.paidAt = serverTimestamp()
  if (status === 'refunded') patch.refundedAt = serverTimestamp()
  await updateDoc(doc(db, 'invoices', id), patch)
  await writeActivityLog({ level: 'info', module: 'Billing', event: `Invoice ${status}`, details: id })
}

// ── Tele-Rehab ops ──

export async function fetchRehabCareAccess(max = 200) {
  return fetchCollection('rehabCareAccess', max, 'updatedAt')
}

export async function setRehabCareAccessStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'rehabCareAccess', id), { status, updatedAt: serverTimestamp() })
}

export async function fetchSessionChats(max = 100) {
  return fetchCollection('sessionChats', max, 'updatedAt')
}

// ── Caregiver & consent ──

export async function fetchPassportShares(max = 200) {
  return fetchCollection('passportShares', max, 'createdAt')
}

export async function fetchPassportAccessLogs(max = 200) {
  return fetchCollection('passportAccessLogs', max, 'createdAt')
}

/** Admin force-revoke — never reads or returns snapshot PHI. */
export async function revokePassportShare(id: string, reason = '') {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'passportShares', id), {
    status: 'revoked',
    revokedByAdmin: true,
    revokeReason: reason.trim(),
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'warning',
    module: 'Passport',
    event: 'Share force-revoked',
    details: `${id}${reason ? ` — ${reason}` : ''}`,
    targetId: id,
  })
}

// ── Rights & Legal CMS ──

export async function fetchLegalArticles(max = 200) {
  return fetchCollection('legalArticles', max, 'updatedAt')
}

export async function upsertLegalArticle(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const status = normalizeRehabStatus(data.status, data.active)
  const actorUid = auth?.currentUser?.uid ?? ''
  const refDoc = id
    ? doc(db, 'legalArticles', id)
    : doc(collection(db, 'legalArticles'))
  await setDoc(
    refDoc,
    {
      ...data,
      status,
      locale: data.locale ?? 'en',
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), authoredBy: actorUid }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Rights & Legal',
    event: id ? 'Article updated' : 'Article created',
    details: `${String(data.title ?? refDoc.id)} [${status}]`,
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function setLegalArticleStatus(
  id: string,
  status: RehabContentStatus,
) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  await updateDoc(doc(db, 'legalArticles', id), {
    status,
    reviewedAt: serverTimestamp(),
    reviewedBy: actorUid,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Rights & Legal',
    event: `Article → ${status}`,
    details: id,
    targetId: id,
  })
}

// ── Assistive Technology marketplace ──

export async function fetchAssistiveProducts(max = 300) {
  return fetchCollection('assistiveProducts', max, 'updatedAt')
}

export async function fetchAssistiveCategories(max = 100) {
  return fetchCollection('assistiveCategories', max, 'sortOrder')
}

export async function upsertAssistiveProduct(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const status = normalizeRehabStatus(data.status, data.active)
  const actorUid = auth?.currentUser?.uid ?? ''
  const refDoc = id
    ? doc(db, 'assistiveProducts', id)
    : doc(collection(db, 'assistiveProducts'))
  await setDoc(
    refDoc,
    {
      ...data,
      status,
      active: status === 'published',
      currency: data.currency ?? 'EUR',
      locale: data.locale ?? 'en',
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp(), authoredBy: actorUid }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Assistive Tech',
    event: id ? 'Product updated' : 'Product created',
    details: `${String(data.title ?? refDoc.id)} [${status}]`,
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function setAssistiveProductStatus(
  id: string,
  status: RehabContentStatus,
) {
  if (!db) throw new Error('Firebase not configured')
  const actorUid = auth?.currentUser?.uid ?? ''
  await updateDoc(doc(db, 'assistiveProducts', id), {
    status,
    active: status === 'published',
    reviewedAt: serverTimestamp(),
    reviewedBy: actorUid,
    updatedAt: serverTimestamp(),
  })
  await writeActivityLog({
    level: 'info',
    module: 'Assistive Tech',
    event: `Product → ${status}`,
    details: id,
    targetId: id,
  })
}

export async function upsertAssistiveCategory(
  id: string | null,
  data: Record<string, unknown>,
) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id
    ? doc(db, 'assistiveCategories', id)
    : doc(collection(db, 'assistiveCategories'))
  await setDoc(
    refDoc,
    {
      ...data,
      updatedAt: serverTimestamp(),
      ...(id ? {} : { createdAt: serverTimestamp() }),
    },
    { merge: true },
  )
  await writeActivityLog({
    level: 'info',
    module: 'Assistive Tech',
    event: id ? 'Category updated' : 'Category created',
    details: String(data.title ?? data.name ?? refDoc.id),
    targetId: refDoc.id,
  })
  return refDoc.id
}

export async function fetchPatientConsents(max = 200) {
  return fetchCollection('patientConsents', max, 'createdAt')
}

export async function fetchLocationShares(max = 200) {
  return fetchCollection('locationShares', max, 'createdAt')
}

// ── Reference data ──

export async function fetchGovernmentOffices(max = 200) {
  return fetchCollection('governmentOffices', max)
}

export async function upsertGovernmentOffice(id: string | null, data: Record<string, unknown>) {
  if (!db) throw new Error('Firebase not configured')
  const refDoc = id ? doc(db, 'governmentOffices', id) : doc(collection(db, 'governmentOffices'))
  await setDoc(refDoc, { ...data, updatedAt: serverTimestamp(), ...(id ? {} : { createdAt: serverTimestamp() }) }, { merge: true })
  return refDoc.id
}

export async function fetchMarkets(max = 50) {
  return fetchCollection('markets', max)
}

export async function upsertMarket(id: string, data: Record<string, unknown>) {
  if (!db) throw new Error('Firebase not configured')
  await setDoc(doc(db, 'markets', id), { ...data, updatedAt: serverTimestamp() }, { merge: true })
  return id
}

export async function fetchHealthOrgs(max = 200) {
  return fetchCollection('healthOrgs', max, 'createdAt')
}

export async function fetchExpansionPartners(max = 200) {
  return fetchCollection('expansionPartners', max, 'createdAt')
}

export async function setExpansionPartnerStatus(id: string, status: string) {
  if (!db) throw new Error('Firebase not configured')
  await updateDoc(doc(db, 'expansionPartners', id), { status, updatedAt: serverTimestamp() })
}

export async function fetchOpenDataBundles(max = 20) {
  return fetchCollection('openData', max, 'updatedAt')
}

