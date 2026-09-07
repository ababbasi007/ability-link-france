import type { AdminRole } from './data'

/** Roles allowed for a path prefix. `any` = any panel user. super_admin always passes. */
export type RouteAccess = AdminRole[] | 'any'

/**
 * REQ-10 route matrix. First matching prefix wins (longest paths checked first
 * when resolving). Unlisted routes default to super_admin + moderator.
 */
export const ROUTE_ACCESS: { path: string; roles: RouteAccess }[] = [
  { path: '/admins', roles: ['super_admin'] },
  { path: '/settings', roles: ['super_admin'] },
  { path: '/logs', roles: ['super_admin', 'moderator'] },
  { path: '/legal-rights', roles: ['super_admin', 'content_manager', 'clinical_reviewer'] },
  { path: '/assistive-tech', roles: ['super_admin', 'content_manager', 'provider_manager'] },
  { path: '/passport-admin', roles: ['super_admin', 'moderator'] },
  { path: '/tele-rehab', roles: ['super_admin', 'content_manager', 'clinical_reviewer', 'moderator'] },
  { path: '/rehab-education', roles: ['super_admin', 'content_manager', 'clinical_reviewer', 'moderator'] },
  { path: '/billing', roles: ['super_admin', 'finance_manager'] },
  { path: '/provider-verifications', roles: ['super_admin', 'provider_manager', 'moderator'] },
  { path: '/providers', roles: ['super_admin', 'provider_manager', 'moderator'] },
  { path: '/doctors', roles: ['super_admin', 'provider_manager', 'moderator'] },
  { path: '/therapists', roles: ['super_admin', 'provider_manager', 'moderator'] },
  { path: '/caregivers', roles: ['super_admin', 'provider_manager', 'moderator'] },
  { path: '/reports', roles: ['super_admin', 'moderator'] },
  { path: '/reviews', roles: ['super_admin', 'moderator'] },
  { path: '/trust-safety', roles: ['super_admin', 'moderator'] },
  { path: '/community', roles: ['super_admin', 'moderator'] },
  { path: '/emergency', roles: ['super_admin', 'moderator'] },
  { path: '/analytics', roles: 'any' },
  { path: '/support', roles: 'any' },
  { path: '/', roles: 'any' },
]

const DEFAULT_ROLES: AdminRole[] = ['super_admin', 'moderator']

export function rolesForPath(pathname: string): RouteAccess {
  const sorted = [...ROUTE_ACCESS].sort((a, b) => b.path.length - a.path.length)
  for (const entry of sorted) {
    if (entry.path === '/') {
      if (pathname === '/') return entry.roles
      continue
    }
    if (pathname === entry.path || pathname.startsWith(`${entry.path}/`)) {
      return entry.roles
    }
  }
  return DEFAULT_ROLES
}

export function canAccessPath(
  pathname: string,
  userRoles: AdminRole[],
  isSuperAdmin: boolean,
): boolean {
  if (isSuperAdmin || userRoles.includes('super_admin')) return true
  const need = rolesForPath(pathname)
  if (need === 'any') return userRoles.length > 0
  return need.some((r) => userRoles.includes(r))
}
