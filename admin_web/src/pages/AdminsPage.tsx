import { useMemo, useState, type FormEvent } from 'react'
import { useAuth } from '../lib/auth'
import {
  ADMIN_ROLES,
  ADMIN_ROLE_LABELS,
  BOOTSTRAP_ADMIN_UID,
  rolesForUid,
  saveAccessLists,
  type AdminRole,
} from '../lib/data'
import { DemoBanner } from '../components/DemoBanner'
import {
  IconDownload,
  IconPlus,
  IconSearch,
  IconShieldCheck,
  IconUser,
  IconUsers,
} from '../components/icons'

type AccessRow = {
  uid: string
  roles: AdminRole[]
  isYou: boolean
  isBootstrap: boolean
}

function ensureBootstrapSuperAdmin(roles: Record<string, AdminRole[]>) {
  const next = { ...roles }
  const set = new Set(next[BOOTSTRAP_ADMIN_UID] ?? [])
  set.add('super_admin')
  next[BOOTSTRAP_ADMIN_UID] = [...set]
  return next
}

function listsFromRoles(roles: Record<string, AdminRole[]>) {
  const adminUids: string[] = []
  const moderatorUids: string[] = []
  for (const [uid, list] of Object.entries(roles)) {
    if (list.includes('super_admin')) adminUids.push(uid)
    if (list.includes('moderator')) moderatorUids.push(uid)
  }
  return { adminUids, moderatorUids, roles }
}

export function AdminsPage() {
  const { user, config, admin, refreshConfig } = useAuth()
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('all')
  const [newUid, setNewUid] = useState('')
  const [newRoles, setNewRoles] = useState<AdminRole[]>(['moderator'])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [msg, setMsg] = useState('')

  const rows = useMemo(() => {
    const admins = new Set(config?.adminUids ?? [])
    const mods = new Set(config?.moderatorUids ?? [])
    if (BOOTSTRAP_ADMIN_UID) admins.add(BOOTSTRAP_ADMIN_UID)
    const fromRoles = Object.keys(config?.roles ?? {})
    const uids = new Set([...admins, ...mods, ...fromRoles])
    const list: AccessRow[] = []
    for (const uid of uids) {
      const roles = rolesForUid(config, uid)
      if (!roles.length && uid !== BOOTSTRAP_ADMIN_UID) continue
      list.push({
        uid,
        roles: roles.length ? roles : (['super_admin'] as AdminRole[]),
        isYou: uid === user?.uid,
        isBootstrap: uid === BOOTSTRAP_ADMIN_UID,
      })
    }
    return list.sort((a, b) => {
      const aSuper = a.roles.includes('super_admin') ? 0 : 1
      const bSuper = b.roles.includes('super_admin') ? 0 : 1
      if (aSuper !== bSuper) return aSuper - bSuper
      return a.uid.localeCompare(b.uid)
    })
  }, [config, user?.uid])

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    return rows.filter((r) => {
      if (roleFilter !== 'all' && !r.roles.includes(roleFilter as AdminRole)) {
        return false
      }
      if (!q) return true
      return r.uid.toLowerCase().includes(q)
    })
  }, [rows, search, roleFilter])

  const stats = {
    total: rows.length,
    admins: rows.filter((r) => r.roles.includes('super_admin')).length,
    moderators: rows.filter((r) => r.roles.includes('moderator')).length,
  }

  const currentRolesMap = (): Record<string, AdminRole[]> => {
    const map: Record<string, AdminRole[]> = {}
    for (const r of rows) map[r.uid] = [...r.roles]
    return ensureBootstrapSuperAdmin(map)
  }

  const persist = async (rolesMap: Record<string, AdminRole[]>) => {
    if (!admin) {
      setError('Only platform admins can change access lists.')
      return
    }
    setBusy(true)
    setError('')
    setMsg('')
    try {
      const safe = ensureBootstrapSuperAdmin(rolesMap)
      const { adminUids, moderatorUids, roles } = listsFromRoles(safe)
      await saveAccessLists({ adminUids, moderatorUids, roles })
      await refreshConfig()
      setMsg('Access lists & roles saved to platformConfig/settings.')
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setBusy(false)
    }
  }

  const toggleNewRole = (role: AdminRole) => {
    setNewRoles((prev) =>
      prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role],
    )
  }

  const onAdd = async (e: FormEvent) => {
    e.preventDefault()
    const uid = newUid.trim()
    if (!uid) {
      setError('Enter a Firebase Auth UID.')
      return
    }
    if (!newRoles.length) {
      setError('Select at least one role.')
      return
    }
    if (rows.some((r) => r.uid === uid)) {
      setError('That UID is already in the access list.')
      return
    }
    const map = currentRolesMap()
    map[uid] = [...new Set(newRoles)]
    await persist(map)
    setNewUid('')
    setNewRoles(['moderator'])
  }

  const setUidRoles = async (uid: string, next: AdminRole[]) => {
    if (uid === BOOTSTRAP_ADMIN_UID && !next.includes('super_admin')) {
      setError('Bootstrap admin UID must keep super_admin.')
      return
    }
    const map = currentRolesMap()
    if (!next.length) {
      delete map[uid]
    } else {
      map[uid] = [...new Set(next)]
    }
    await persist(ensureBootstrapSuperAdmin(map))
  }

  const toggleRowRole = async (uid: string, role: AdminRole, checked: boolean) => {
    const row = rows.find((r) => r.uid === uid)
    if (!row) return
    let next = checked
      ? [...new Set([...row.roles, role])]
      : row.roles.filter((r) => r !== role)
    if (uid === BOOTSTRAP_ADMIN_UID && !next.includes('super_admin')) {
      next = [...next, 'super_admin']
      setError('Bootstrap admin UID must keep super_admin.')
    }
    await setUidRoles(uid, next)
  }

  const removeUid = async (uid: string) => {
    if (uid === BOOTSTRAP_ADMIN_UID) {
      setError('Cannot remove the bootstrap admin UID from this UI.')
      return
    }
    if (uid === user?.uid) {
      setError('Cannot remove your own UID while signed in.')
      return
    }
    const map = currentRolesMap()
    delete map[uid]
    await persist(map)
  }

  const exportCsv = () => {
    const lines = [
      'UID,Roles,Bootstrap,You',
      ...filtered.map(
        (r) =>
          `"${r.uid}","${r.roles.join('|')}","${r.isBootstrap}","${r.isYou}"`,
      ),
    ]
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'ability-link-admins.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  const usingDemo = !config

  return (
    <div className="adm-page">
      <header className="adm-head">
        <div>
          <h1>Admins</h1>
          <p>Manage platform administrators and their RBAC roles.</p>
        </div>
        <div className="adm-head-actions">
          <button type="button" className="adm-btn ghost" onClick={exportCsv}>
            <IconDownload width={15} height={15} />
            Export
          </button>
        </div>
      </header>

      <DemoBanner
        active={usingDemo}
        reason="platformConfig/settings not loaded yet"
      />
      {error ? <div className="error">{error}</div> : null}
      {msg ? (
        <div className="pill pill-ok" style={{ marginBottom: 12 }}>
          {msg}
        </div>
      ) : null}

      <div className="adm-stats">
        <article className="adm-stat">
          <div className="adm-stat-icon green">
            <IconUsers />
          </div>
          <div>
            <span>Total Access</span>
            <strong>{stats.total}</strong>
            <em>UIDs in config</em>
          </div>
        </article>
        <article className="adm-stat">
          <div className="adm-stat-icon blue">
            <IconShieldCheck />
          </div>
          <div>
            <span>Super Admins</span>
            <strong>{stats.admins}</strong>
            <em>super_admin</em>
          </div>
        </article>
        <article className="adm-stat">
          <div className="adm-stat-icon teal">
            <IconUser />
          </div>
          <div>
            <span>Moderators</span>
            <strong>{stats.moderators}</strong>
            <em>moderator role</em>
          </div>
        </article>
      </div>

      <form className="adm-add" onSubmit={(e) => void onAdd(e)}>
        <h2>Grant access</h2>
        <p>
          Writes to <code>platformConfig/settings</code> — adminUids, moderatorUids,
          and the roles map (REQ-10.1 / REQ-10.3).
        </p>
        <div className="adm-add-row" style={{ flexWrap: 'wrap' }}>
          <input
            value={newUid}
            onChange={(e) => setNewUid(e.target.value)}
            placeholder="Firebase Auth UID"
            disabled={busy || !admin}
            style={{ minWidth: 280 }}
          />
          <button
            type="submit"
            className="adm-btn primary"
            disabled={busy || !admin}
          >
            <IconPlus width={15} height={15} />
            Add UID
          </button>
        </div>
        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            gap: 12,
            marginTop: 12,
          }}
        >
          {ADMIN_ROLES.map((role) => (
            <label
              key={role}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
                fontSize: 13,
              }}
            >
              <input
                type="checkbox"
                checked={newRoles.includes(role)}
                disabled={busy || !admin}
                onChange={() => toggleNewRole(role)}
              />
              {ADMIN_ROLE_LABELS[role]}
            </label>
          ))}
        </div>
        {!admin ? (
          <em className="adm-hint">Signed in as non–super-admin — view only.</em>
        ) : null}
      </form>

      <div className="adm-filters">
        <div className="adm-search">
          <IconSearch className="adm-search-icon" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by UID..."
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
        >
          <option value="all">All Roles</option>
          {ADMIN_ROLES.map((role) => (
            <option key={role} value={role}>
              {ADMIN_ROLE_LABELS[role]}
            </option>
          ))}
        </select>
      </div>

      <div className="adm-table-card">
        <div className="adm-table-scroll">
          <table className="adm-table" style={{ minWidth: 960 }}>
            <thead>
              <tr>
                <th>UID</th>
                <th>Roles</th>
                <th>Flags</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r) => (
                <tr key={r.uid}>
                  <td>
                    <div className="adm-user">
                      <img
                        src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${encodeURIComponent(r.uid)}`}
                        alt=""
                      />
                      <div>
                        <strong>
                          <code style={{ fontSize: 12 }}>{r.uid}</code>
                          {r.isYou ? <span className="adm-you">You</span> : null}
                        </strong>
                        <span>
                          {r.isBootstrap
                            ? 'Bootstrap admin (hardcoded fallback)'
                            : 'From platformConfig'}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div
                      style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 4,
                      }}
                    >
                      {ADMIN_ROLES.map((role) => {
                        const locked =
                          r.isBootstrap && role === 'super_admin'
                        return (
                          <label
                            key={role}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: 6,
                              fontSize: 12,
                              whiteSpace: 'nowrap',
                            }}
                          >
                            <input
                              type="checkbox"
                              checked={r.roles.includes(role)}
                              disabled={busy || !admin || locked}
                              onChange={(e) =>
                                void toggleRowRole(
                                  r.uid,
                                  role,
                                  e.target.checked,
                                )
                              }
                            />
                            {ADMIN_ROLE_LABELS[role]}
                          </label>
                        )
                      })}
                    </div>
                  </td>
                  <td className="adm-date">
                    {r.isBootstrap ? 'Bootstrap' : '—'}
                  </td>
                  <td>
                    <div className="adm-actions" style={{ gap: 6 }}>
                      <button
                        type="button"
                        className="adm-btn ghost"
                        style={{ padding: '6px 10px' }}
                        disabled={busy || !admin || r.isBootstrap || r.isYou}
                        onClick={() => void removeUid(r.uid)}
                      >
                        Remove
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {!filtered.length ? (
          <div className="empty" style={{ padding: 20 }}>
            No access UIDs match your filters.
          </div>
        ) : null}
        <div className="adm-footer">
          <span>
            Showing {filtered.length} of {rows.length} access UIDs
          </span>
        </div>
      </div>
    </div>
  )
}
